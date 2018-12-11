module Api
  class ConversionHostsController < BaseController
    include Subcollections::Tags

    # Interface for the polymorphic resource, which could be either a Vm or
    # a Host. Failure to provide a conversion host ID will raise an error.
    #
    # POST /api/conversion_hosts/1 {'action': 'resource'}
    #
    def resource_resource(type, id, _data = nil)
      conversion_host = resource_search(id, type, collection_class(type))
      conversion_host.resource
    rescue => err
      raise BadRequestError, "Invalid resource #{type}/#{id}: #{err}"
    end
  end
end
