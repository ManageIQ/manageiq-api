module Api
  class BaseController
    module Parser
      class RequestAdapter
        def initialize(req, params)
          @request = req
          @params = params
        end

        def to_hash
          [:method, :action, :fullpath, :url, :base,
           :path, :prefix, :version, :api_prefix,
           :collection, :c_suffix, :c_id, :subcollection, :s_id]
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

        #
        # c_path_parts returns: [collection, c_id, subcollection, s_id, ...]
        #
        def c_path_parts
          @c_path_parts ||= version_override? ? path.split('/')[3..-1] : path.split('/')[2..-1]
        end

        def subject
          href.subject
        end

        def subject_id
          href.subject_id
        end

        def collection
          href.collection
        end

        def c_suffix
          @params[:c_suffix]
        end

        def c_id
          href.collection_id
        end

        def subcollection
          href.subcollection
        end

        def s_id
          href.subcollection_id
        end

        def subcollection?
          href.subcollection?
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

        def path
          href.path
        end

        def version
          @version ||= if version_override?
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
          version_override? ? "#{prefix}/#{@params[:version]}" : prefix
        end

        private

        def href
          @href ||= Href.new(url)
        end

        def expand_requested
          @expand ||= @params['expand'].to_s.split(',')
        end

        def version_override?
          @params[:version] && @params[:version].match(Api::VERSION_REGEX) # v#.# version signature
        end

        def fullpath
          @request.original_fullpath # /api/...&param=value...
        end
      end
    end
  end
end
