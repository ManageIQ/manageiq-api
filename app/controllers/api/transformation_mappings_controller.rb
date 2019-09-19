module Api
  class TransformationMappingsController < BaseController
    def create_resource(_type, _id, data = {})
      raise "Must specify transformation_mapping_items" unless data["transformation_mapping_items"]
      TransformationMapping.create(data.except("transformation_mapping_items")).tap do |mapping|
        mapping.transformation_mapping_items = create_mapping_items(data["transformation_mapping_items"], mapping)
        mapping.save!
      end
    rescue StandardError => err
      raise BadRequestError, "Could not create Transformation Mapping - #{err}"
    end

    def edit_resource(type, id, data)
      raise "Must specify transformation_mapping_items" unless data["transformation_mapping_items"]
      transformation_mapping = resource_search(id, type, collection_class(type))
      updated_data = data.except("transformation_mapping_items")
      transformation_mapping.update!(updated_data) if updated_data.present?
      transformation_mapping.transformation_mapping_items = create_mapping_items(data["transformation_mapping_items"], transformation_mapping)
      transformation_mapping.save!
      transformation_mapping
    rescue StandardError => err
      raise BadRequestError, "Failed to update Transformation Mapping - #{err}"
    end

    def validate_vms_resource(type, id, data = {})
      transformation_mapping = resource_search(id, type, collection_class(type))
      (transformation_mapping.search_vms_and_validate(data["import"], data["service_template_id"]) || {}).tap do |res|
        %w(valid_vms invalid_vms conflict_vms).each do |key|
          next unless res.key?(key)
          res[key].each do |entry|
            entry["href"] = normalize_href(:vms, entry["id"]) if entry["href"].blank? && entry["id"].present?
          end
        end
      end
    end

    def vm_flavor_fit_resource(_type, _id, data)
      data["mappings"].collect do |mapping|
        source      = Api::Utils.resource_search_by_href_slug(mapping["source_href_slug"])
        destination = Api::Utils.resource_search_by_href_slug(mapping["destination_href_slug"])
        fit         = TransformationMapping::CloudBestFit.new(source, destination)
        {
          :source_href_slug => mapping["source_href_slug"],
          :best_fit         => Api::Utils.build_href_slug(Flavor, fit.best_fit_flavor.try(:id)),
          :all_fit          => fit.available_fit_flavors.collect { |f| Api::Utils.build_href_slug(Flavor, f.id) }
        }
      end
    end

    def add_mapping_item_resource(type, id, data)
      resource_search(id, type, collection_class(type)).tap do |mapping|
        mapping.transformation_mapping_items.append(create_mapping_items([data], mapping))
        mapping.save!
      end
    rescue StandardError => err
      raise BadRequestError, "Failed to update Transformation Mapping - #{err}"
    end

    private

    def create_mapping_items(items, mapping)
      items.collect do |item|
        raise "Must specify source and destination hrefs" unless item["source"] && item["destination"]
        TransformationMappingItem.new(
          :transformation_mapping => mapping,
          :source                 => fetch_mapping_resource(item["source"]),
          :destination            => fetch_mapping_resource(item["destination"])
        )
      end
    end

    def fetch_mapping_resource(href)
      resource_href = Api::Href.new(href)
      raise "Invalid source or destination type #{resource_href.subject}" unless collection_config.collection?(resource_href.subject)
      resource_search(resource_href.subject_id, resource_href.subject, collection_class(resource_href.subject.to_sym))
    end
  end
end
