module Api
  class PxeServersController < BaseController
    INVALID_PXE_SERVER_ATTRS = %w(id href).freeze # Cannot update or create these

    include Subcollections::PxeImages
    include Subcollections::PxeMenus

    def create_resource(_type, _id, data = {})
      validate_pxe_server_create_data(data)
      menus = data.delete('pxe_menus')

      server = collection_class(:pxe_servers).create(data)
      if server.invalid?
        raise BadRequestError, "Failed to add a pxe server - #{server.errors.full_messages.join(', ')}"
      end
      server.pxe_menus = create_pxe_menus(menus) if menus
      server
    end

    def delete_resource(_type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for deleting a pxe server" unless id
      super
    end


    def edit_resource(type, id, data)
      server = resource_search(id, type, collection_class(:pxe_servers))
      

      menus = data.delete('pxe_menus')
      if menus
        server.pxe_menus.clear
        data.merge!('pxe_menus' => create_pxe_menus(menus))
      end
      server.update_attributes!(data)
      server
    end

    private

    def create_pxe_menus(menus)
      menus.map do | menu |
        collection_class(:pxe_menus).create(menu)
      end
    end

    def validate_pxe_server_data(data)
      bad_attrs = data.keys.select { |k| INVALID_PXE_SERVER_ATTRS.include?(k) }.compact.join(", ")
      raise BadRequestError, "Invalid attribute(s) #{bad_attrs} specified for a pxe server" if bad_attrs.present?
    end

    def validate_pxe_server_create_data(data)
      validate_pxe_server_data(data)
      req_attrs = %w(name uri)
      bad_attrs = []
      req_attrs.each { |attr| bad_attrs << attr if data[attr].blank? }
      raise BadRequestError, "Missing attribute(s) #{bad_attrs.join(', ')} for creating a pxe server" if bad_attrs.present?
    end
  end
end
