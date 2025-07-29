module Api
  class BaseController < ActionController::API
    after_action :skip_session_write

    def skip_session_write
      request.session_options[:skip] = true if %w[GET HEAD OPTIONS].include?(request.request_method)
    end

    TAG_NAMESPACE = "/managed".freeze

    #
    # Attributes used for identification
    #
    ID_ATTRS = %w(href id).freeze

    include Parameters
    include Parser
    include Manager
    include Action
    include Logger
    include Normalizer
    include Renderer
    include Results
    include Generic
    include Authentication
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::RequestForgeryProtection

    before_action :log_request_initiated
    before_action :clear_cached_current_user
    before_action :require_api_user_or_token, :except => [:options, :product_info]
    before_action :optional_api_user_or_token, :only => [:options]
    before_action :set_gettext_locale, :set_access_control_headers, :parse_api_request, :log_api_request
    before_action :validate_api_request, :except => [:product_info]
    before_action :validate_api_action, :except => [:product_info]
    before_action :validate_response_format, :except => [:destroy]
    before_action :ensure_pagination, :only => :index
    after_action :log_api_response

    # Order *Must* be from most generic to most specific
    rescue_from(StandardError)                  { |e| api_error(:internal_server_error, e) }
    rescue_from(NoMethodError)                  { |e| api_error(:internal_server_error, e) }
    rescue_from(ActiveRecord::RecordNotFound)   { |e| api_error(:not_found, e) }
    rescue_from(ActiveRecord::StatementInvalid) { |e| api_error(:bad_request, e) }
    rescue_from(ActiveRecord::RecordInvalid)    { |e| api_error(:bad_request, e) }
    rescue_from(JSON::ParserError)              { |e| api_error(:bad_request, e) }
    rescue_from(MultiJson::LoadError)           { |e| api_error(:bad_request, e) }
    rescue_from(ForbiddenError)                 { |e| api_error(:forbidden, e) }
    rescue_from(BadRequestError)                { |e| api_error(:bad_request, e) }
    rescue_from(NotFoundError)                  { |e| api_error(:not_found, e) }
    rescue_from(UnsupportedMediaTypeError)      { |e| api_error(:unsupported_media_type, e) }

    def index
      klass = collection_class(@req.subject)
      res, subquery_count = collection_search(@req.subcollection?, @req.subject, klass)
      res_count = (res.kind_of?(ActiveRecord::Relation) ? res.except(:select) : res).count

      search_conditions = respond_to?("#{@req.subject}_search_conditions") ? public_send("#{@req.subject}_search_conditions") : {}
      filtered_count = Rbac.filtered(klass.where(search_conditions), :user => User.current_user).count

      # Allow subclasses to modify the scope for includes before rendering
      res = public_send("#{@req.subject}_index_includes", res) if respond_to?("#{@req.subject}_index_includes")

      opts = {
        :name                  => @req.subject,
        :is_subcollection      => @req.subcollection?,
        :expand_actions        => true,
        :expand_custom_actions => false,
        :expand_resources      => @req.expand?(:resources),
        :counts                => Api::QueryCounts.new(filtered_count, res_count, subquery_count)
      }
      render_collection(@req.subject, res, opts)
    end

    def create
      if @req.resources.all?(&:blank?)
        raise BadRequestError, "No #{@req.subject} resources were specified for the create action"
      end

      results = @req.resources.collect do |r|
        next if r.blank?
        if parse_id(r, @req.subject.to_sym)
          raise BadRequestError, "Resource id or href should not be specified for creating a new #{@req.subject}"
        end

        if @req.subcollection?
          target = target_resource_method(@req.subject.to_sym, @req.action)
          send(target, parent_resource_obj, @req.subject.to_sym, nil, r)
        else
          create_resource(@req.subject.to_sym, nil, r)
        end
      end

      render_resource(@req.collection.to_sym, "results" => results)
    end

    def show
      opts  = {
        :name                  => @req.subject,
        :is_subcollection      => @req.subcollection?,
        :expand_actions        => true,
        :expand_custom_actions => true
      }
      render_resource(@req.subject, resource_search(@req.subject_id, @req.subject), opts)
    end

    def update
      render_resource(@req.collection.to_sym, update_collection(@req.subject.to_sym, @req.subject_id))
    end

    def destroy
      if @req.subcollection?
        delete_subcollection_resource @req.subcollection.to_sym, @req.subcollection_id
      else
        delete_resource(@req.collection.to_sym, @req.collection_id)
      end
      head :no_content
    end

    def options
      if params.key?(:subcollection)
        render :json => ""
      else
        render_options(@req.collection)
      end
    end

    private

    def current_user
      @current_user ||= User.current_user
    end

    def super_admin?
      current_user.super_admin_user?
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

    def api_resource_action_options
      []
    end

    def api_error(type, error)
      api_log_error("#{error.class.name}: #{error.message}")
      # We don't want to return the stack trace, but only log it in case of an internal error
      api_log_error("\n\n#{error.backtrace.join("\n")}") if type == :internal_server_error && !error.backtrace.empty?

      logger.fatal("Error caught: [#{error.class.name}] #{error.message}\n#{type == :internal_server_error ? error.backtrace.join("\n") : ""}")

      render :json => ErrorSerializer.new(type, error).serialize, :status => Rack::Utils.status_code(type)
      log_api_response
    end

    def ensure_pagination
      if params["limit"].to_i > Settings.api.max_results_per_page
        $api_log.warn("The limit specified (#{params["limit"]}) exceeded the maximum (#{Settings.api.max_results_per_page}). Applying the maximum limit instead.")
      end
      params["limit"] = [Settings.api.max_results_per_page, params["limit"]].compact.collect(&:to_i).min
      params["offset"] ||= 0
    end
  end
end
