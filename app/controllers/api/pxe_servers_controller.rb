module Api
  class PxeServersController < BaseController
    include Subcollections::PxeImages
    include Subcollections::PxeMenus
    INVALID_ATTRIBUTES = {
      "PxeServer" => %w[id href], # Cannot update or create these
    }.freeze
    PXE_ATTRIBUTES = {
      "PxeServer"      => %w[name uri],
      "PxeMenu"        => %w[file_name],
      "Authentication" => %w[userid password]
    }.freeze

    def create_resource(_type, _id, data = {})
      authentication = data.delete('authentication')
      menus = data.delete('pxe_menus')
      validate_data_for('PxeServer', data)

      PxeServer.transaction do
        server = collection_class(:pxe_servers).new(data)
        # generates uir_prefix which checks if server needs authentication or not
        server.verify_uri_prefix_before_save

        if server.requires_credentials? && server.missing_credentials?
          validate_data_for('Authentication', authentication || {})
          server.update_authentication({:default => authentication.compact}, {:save => true})
        end

        server.pxe_menus = create_pxe_menus(menus) if menus

        if server.invalid?
          raise BadRequestError, "Failed to add a pxe server - #{server.errors.full_messages.join(', ')}"
        end

        server.save
        server
      end
    end

    def delete_resource(_type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for deleting a pxe server" unless id

      super
    end

    def edit_resource(type, id, data)
      server = resource_search(id, type, collection_class(:pxe_servers))
      menus = data.delete('pxe_menus')
      authentication = data.delete('authentication')
      PxeServer.transaction do
        if menus
          server.pxe_menus.destroy_all
          data['pxe_menus'] = create_pxe_menus(menus)
        end
        server.update!(data)
        server.update_authentication({:default => authentication.transform_keys(&:to_sym)}, {:save => true}) if authentication && server.requires_credentials?
        server
      end
    end

    private

    def create_pxe_menus(menus)
      menus.each do |menu|
        validate_data_for('PxeMenu', menu)
      end
      menus.map do |menu|
        collection_class(:pxe_menus).create(menu)
      end
    end

    def validate_data_for(klass, data)
      bad_attrs = []
      PXE_ATTRIBUTES[klass].each { |attr| bad_attrs << attr if data[attr].blank? }
      raise BadRequestError, "Missing attribute(s) #{bad_attrs.join(', ')} for creating a #{klass}" if bad_attrs.present?
    end
  end
end
