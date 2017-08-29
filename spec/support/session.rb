# rubocop:disable Style/HashSyntax
ActionDispatch::Integration::Session.instance_eval do
  prepend Module.new {
    def process(method, path, params: nil, headers: nil, env: nil, xhr: false, as: nil)
      super(method, path, params: params, headers: request_headers.merge(Hash(headers)), env: env, xhr: xhr, as: as)
    end

    def request_headers
      @request_headers ||= {}
    end
  }
end
