module Api
  class Presigner
    ALGORITHM       = "MIQ-HMAC-SHA256".freeze
    PARAM_ALGORITHM = "X-Miq-Algorithm".freeze
    PARAM_EXPIRES   = "X-Miq-Expires".freeze
    PARAM_SIGNATURE = "X-Miq-Signature".freeze

    # Generate a pre-signed URL for the given HTTP method and path.
    #
    # @param method     [String]  HTTP verb — "GET", "PUT", or "DELETE"
    # @param path       [String]  URL path to sign (may contain slashes)
    # @param expires_in [Integer] seconds until the URL expires
    # @param base_url   [String]  e.g. "https://manageiq.example.com"
    # @return [String] the full pre-signed URL
    def self.presign(method:, path:, expires_in:, base_url:)
      expires_at = Time.now.utc.to_i + expires_in.to_i
      sig        = sign(method.upcase, path, expires_at)

      query = URI.encode_www_form(
        PARAM_ALGORITHM => ALGORITHM,
        PARAM_EXPIRES   => expires_at,
        PARAM_SIGNATURE => sig
      )

      "#{base_url}/api/binary_blobs/#{path}?#{query}"
    end

    # Verify a pre-signed URL's query parameters.  Raises SignatureError on any
    # validation failure so callers can render an appropriate HTTP error.
    #
    # @param method [String] HTTP verb from the incoming request
    # @param path   [String] URL path from the request
    # @param params [Hash]   query parameters from the request
    def self.verify!(method:, path:, params:)
      algorithm = params[PARAM_ALGORITHM]
      expires   = params[PARAM_EXPIRES].to_i
      signature = params[PARAM_SIGNATURE]

      raise Api::BaseController::Authentication::AuthenticationError, "Missing pre-signed URL parameters" unless algorithm && expires.positive? && signature

      raise Api::BaseController::Authentication::AuthenticationError, "Unknown signing algorithm: #{algorithm}" unless algorithm == ALGORITHM

      raise Api::BaseController::Authentication::AuthenticationError, "Pre-signed URL has expired" if Time.now.utc.to_i > expires

      expected = sign(method.upcase, path, expires)
      raise Api::BaseController::Authentication::AuthenticationError, "Invalid pre-signed URL signature" unless ActiveSupport::SecurityUtils.secure_compare(expected, signature)
    end

    def self.signing_secret
      MiqDatabase.in_my_region.first.signing_secret_token
    end

    private_class_method def self.sign(method, path, expires_at)
      canonical = "#{method}\n#{path}\n#{expires_at}"
      OpenSSL::HMAC.hexdigest("SHA256", signing_secret, canonical)
    end
  end
end
