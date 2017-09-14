# rubocop:disable Style/HashSyntax
module Spec
  module Support
    module Api
      module RequestHelpers
        def get(path, **args)
          process(:get, path, **args)
        end

        def post(path, **args)
          process(:post, path, **args)
        end

        def patch(path, **args)
          process(:patch, path, **args)
        end

        def put(path, **args)
          process(:put, path, **args)
        end

        def delete(path, **args)
          process(:delete, path, **args)
        end

        def options(path, **args)
          process(:options, path, **args)
        end

        def process(method, path, params: nil, headers: nil, env: nil, xhr: false, as: nil)
          headers = request_headers.merge(Hash(headers))
          as ||= :json if [:post, :put, :patch].include?(method)
          super(method, path, params: params, headers: headers, env: env, xhr: xhr, as: as)
        end

        def request_headers
          @request_headers ||= {}
        end
      end
    end
  end
end
