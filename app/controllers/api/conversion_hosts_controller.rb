module Api
  class ConversionHostsController < BaseController
    include Subcollections::Tags

    # Interface for the polymorphic resource, which could be either a Vm or
    # a Host. Failure to provide a conversion host ID will raise an error.
    #
    # POST /api/conversion_hosts/1 {'action': 'resource'}
    #
    def resource_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for fetching a #{type}.resource" unless id
      conversion_host = resource_search(id, type, collection_class(type))
      conversion_host.resource
    rescue => err
      raise BadRequestError, "Invalid resource #{type}/#{id}: #{err}"
    end
  end
end
