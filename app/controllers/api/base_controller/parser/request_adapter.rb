module Api
  class BaseController
    module Parser
      class RequestAdapter
        delegate :subject, :subject_id, :collection, :collection_id, :subcollection, :subcollection_id, :subcollection?, :path, :version?, :to => :href

        def initialize(req, params)
          @request = req
          @params = params
        end

        def to_hash
          [:method, :action, :fullpath, :url, :base,
           :path, :prefix, :version, :api_prefix,
           :collection, :c_suffix, :collection_id, :subcollection, :subcollection_id]
            .each_with_object({}) { |attr, hash| hash[attr] = send(attr) }
        end

        def action
          # for basic HTTP POST, default action is "create" with data being the POST body
          @action ||= case method
                      when :get         then 'read'
                      when :put, :patch then 'edit'
                      when :delete      then 'delete'
                      when :options     then 'options'
                      else json_body['action'] || 'create'
                      end
        end

        def api_prefix
          @api_prefix ||= "#{base}#{prefix}"
        end

        def api_suffix
          @api_suffix ||= "?provider_class=#{@params['provider_class']}" if @params['provider_class']
        end

        def attributes
          @attributes ||= @params['attributes'].to_s.split(',')
        end

        def base
          url.partition(fullpath)[0] # http://target
        end

        def c_suffix
          @params[:c_suffix]
        end

        def expand?(what)
          expand_requested.include?(what.to_s)
        end

        def hide?(thing)
          @hide ||= @params["hide"].to_s.split(",")
          @hide.include?(thing)
        end

        def json_body
          @json_body ||= begin
                           body = @request.body.read if @request.body
                           body.blank? ? {} : JSON.parse(body)
                         end
        end

        def method
          @method ||= @request.request_method.downcase.to_sym # :get, :patch, ...
        end

        def version
          @version ||= if version?
                         @params[:version][1..-1] # Switching API Version
                       else
                         ApiConfig.base[:version] # Default API Version
                       end
        end

        def url
          @request.original_url # http://target/api/...
        end

        def prefix(version = true)
          prefix = "/#{path.split('/')[1]}" # /api
          return prefix unless version
          version? ? "#{prefix}/#{@params[:version]}" : prefix
        end

        def href
          @href ||= Href.new(url)
        end

        private

        def expand_requested
          @expand ||= @params['expand'].to_s.split(',')
        end

        def fullpath
          @request.original_fullpath # /api/...&param=value...
        end
      end
    end
  end
end
