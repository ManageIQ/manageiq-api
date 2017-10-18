module Api
  class BaseController < ActionController::API
    TAG_NAMESPACE = "/managed".freeze

    #
    # Attributes used for identification
    #
    ID_ATTRS = %w(href id).freeze

    include_concern 'Parameters'
    include_concern 'Parser'
    include_concern 'Manager'
    include_concern 'Action'
    include_concern 'Logger'
    include_concern 'Normalizer'
    include_concern 'Renderer'
    include_concern 'Results'
    include_concern 'Generic'
    include_concern 'Authentication'
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    before_action :log_request_initiated
    before_action :require_api_user_or_token, :except => [:options]
    before_action :set_gettext_locale, :set_access_control_headers, :parse_api_request, :log_api_request,
                  :validate_api_request
    before_action :validate_api_action, :except => [:options]
    before_action :validate_response_format, :except => [:destroy]
    before_action :redirect_on_compressed_path
    before_action :ensure_pagination, :only => :index
    after_action :log_api_response

    respond_to :json

    # Order *Must* be from most generic to most specific
    rescue_from(StandardError)                  { |e| api_error(:internal_server_error, e) }
    rescue_from(NoMethodError)                  { |e| api_error(:internal_server_error, e) }
    rescue_from(ActiveRecord::RecordNotFound)   { |e| api_error(:not_found, e) }
    rescue_from(ActiveRecord::StatementInvalid) { |e| api_error(:bad_request, e) }
    rescue_from(JSON::ParserError)              { |e| api_error(:bad_request, e) }
    rescue_from(MultiJson::LoadError)           { |e| api_error(:bad_request, e) }
    rescue_from(MiqException::MiqEVMLoginError) { |e| api_error(:unauthorized, e) }
    rescue_from(AuthenticationError)            { |e| api_error(:unauthorized, e) }
    rescue_from(ForbiddenError)                 { |e| api_error(:forbidden, e) }
    rescue_from(BadRequestError)                { |e| api_error(:bad_request, e) }
    rescue_from(NotFoundError)                  { |e| api_error(:not_found, e) }
    rescue_from(UnsupportedMediaTypeError)      { |e| api_error(:unsupported_media_type, e) }
    rescue_from(ArgumentError)                  { |e| api_error(:bad_request, e) }

    def index
      klass = collection_class(@req.subject)
      res, subquery_count = collection_search(@req.subcollection?, @req.subject, klass)
      opts = {
        :name             => @req.subject,
        :is_subcollection => @req.subcollection?,
        :expand_actions   => true,
        :expand_resources => @req.expand?(:resources),
        :counts           => Api::QueryCounts.new(klass.count, res.count, subquery_count)
      }
      render_collection(@req.subject, res, opts)
    end

    def show
      klass = collection_class(@req.subject)
      opts  = {:name => @req.subject, :is_subcollection => @req.subcollection?, :expand_actions => true}
      render_resource(@req.subject, resource_search(@req.subject_id, @req.subject, klass), opts)
    end

    def update
      render_normal_update @req.collection.to_sym, update_collection(@req.subject.to_sym, @req.subject_id)
    end

    def destroy
      if @req.subcollection?
        delete_subcollection_resource @req.subcollection.to_sym, @req.subcollection_id
      else
        delete_resource(@req.collection.to_sym, @req.collection_id)
      end
      render_normal_destroy
    end

    def options
      render_options(@req.collection)
    end

    private

    def redirect_on_compressed_path
      return unless [params[:c_id], params[:s_id]].any? { |id| Api.compressed_id?(id) }
      url = request.original_url.sub(params[:c_id], Api.uncompress_id(params[:c_id]).to_s)
      url.sub!(params[:s_id], Api.uncompress_id(params[:s_id]).to_s) if params[:s_id]
      redirect_to(url, :status => :moved_permanently)
    end

    def set_gettext_locale
      FastGettext.set_locale(LocaleResolver.resolve(User.current_user, headers))
    end

    def validate_response_format
      accept = request.headers["Accept"]
      return if accept.blank? || accept.include?("json") || accept.include?("*/*")
      raise UnsupportedMediaTypeError, "Invalid Response Format #{accept} requested"
    end

    def set_access_control_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Headers'] = 'origin, content-type, authorization, x-auth-token'
      headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, PATCH, OPTIONS'
    end

    def collection_config
      @collection_config ||= CollectionConfig.new
    end

    def api_error(type, error)
      api_log_error("#{error.class.name}: #{error.message}")
      # We don't want to return the stack trace, but only log it in case of an internal error
      api_log_error("\n\n#{error.backtrace.join("\n")}") if type == :internal_server_error && !error.backtrace.empty?

      render :json => ErrorSerializer.new(type, error).serialize, :status => Rack::Utils.status_code(type)
      log_api_response
    end

    def ensure_pagination
      params["limit"] = [Settings.api.max_results_per_page, params["limit"]].compact.collect(&:to_i).min
      params["offset"] ||= 0
    end
  end
end
