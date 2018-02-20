module Api
  class TransformationMappingsController < BaseController
    def create_resource(_type, _id, data = {})
      raise "Must specify transformation_mapping_items" unless data["transformation_mapping_items"]
      TransformationMapping.new(data.except("transformation_mapping_items")).tap do |mapping|
        mapping.transformation_mapping_items = create_mapping_items(data["transformation_mapping_items"])
        mapping.save!
      end
    rescue StandardError => err
      raise BadRequestError, "Could not create Transformation Mapping - #{err}"
    end

    private

    def create_mapping_items(items)
      items.collect do |item|
        raise "Must specify source and destination hrefs" unless item["source"] && item["destination"]
        TransformationMappingItem.new(:source => fetch_mapping_resource(item["source"]), :destination => fetch_mapping_resource(item["destination"]))
      end
    end

    def fetch_mapping_resource(href)
      resource_href = Api::Href.new(href)
      raise "Invalid source or destination type #{resource_href.subject}" unless collection_config.collection?(resource_href.subject)
      resource_search(resource_href.subject_id, resource_href.subject, collection_class(resource_href.subject.to_sym))
    end
  end
end
