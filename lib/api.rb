module Api
  SUPPORTED_VERSIONS = [ManageIQ::Api::VERSION].freeze
  VERSION_CONSTRAINT = /v\d+(\.[\da-zA-Z]+)*(\-[\da-zA-Z\-\.]+)?/
  VERSION_REGEX = /\A#{VERSION_CONSTRAINT}\z/

  ApiError = Class.new(StandardError)
  AuthenticationError = Class.new(ApiError)
  ForbiddenError = Class.new(ApiError)
  BadRequestError = Class.new(ApiError)
  NotFoundError = Class.new(ApiError)
  UnsupportedMediaTypeError = Class.new(ApiError)

  def self.encrypted_attribute?(attr)
    !Environment.encrypted_attributes_whitelist.include?(attr.to_s) &&
      Environment.encrypted_attributes.any? { |a| attr.to_s.include?(a.to_s) }
  end

  def self.time_attribute?(attr)
    Environment.time_attributes.include?(attr.to_s)
  end

  def self.url_attribute?(attr)
    Environment.url_attributes.include?(attr.to_s)
  end

  def self.resource_attribute?(attr)
    Environment.resource_attributes.include?(attr.to_s)
  end
end
