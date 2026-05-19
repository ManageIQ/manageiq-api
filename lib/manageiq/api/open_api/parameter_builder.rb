module ManageIQ
  module Api
    module OpenApi
      module ParameterBuilder
        PARAMETERS_PATH = "#/components/parameters".freeze

        def self.build_common_parameters
          {
            "version"       => {
              "name"        => "version",
              "in"          => "path",
              "required"    => false,
              "schema"      => {
                "type"    => "string",
                "pattern" => "^v\\d+(\\.\\d+)*$"
              },
              "description" => "API version (optional)"
            },
            "resourceId"    => {
              "name"        => "c_id",
              "in"          => "path",
              "required"    => true,
              "schema"      => {
                "type"    => "string",
                "pattern" => "^\\d+$"
              },
              "description" => "Resource ID"
            },
            "subResourceId" => {
              "name"        => "s_id",
              "in"          => "path",
              "required"    => true,
              "schema"      => {
                "type"    => "string",
                "pattern" => "^\\d+$"
              },
              "description" => "Sub-resource ID"
            },
            "expand"        => {
              "name"        => "expand",
              "in"          => "query",
              "required"    => false,
              "schema"      => {
                "type" => "string"
              },
              "description" => "Comma-separated list of resources to expand",
              "example"     => "resources,tags"
            },
            "attributes"    => {
              "name"        => "attributes",
              "in"          => "query",
              "required"    => false,
              "schema"      => {
                "type" => "string"
              },
              "description" => "Comma-separated list of attributes to return",
              "example"     => "id,name,created_at"
            },
            "filter"        => {
              "name"        => "filter[]",
              "in"          => "query",
              "required"    => false,
              "schema"      => {
                "type"  => "array",
                "items" => {
                  "type" => "string"
                }
              },
              "description" => "Filter expressions (e.g., filter[]=name='test')",
              "style"       => "form",
              "explode"     => true
            },
            "sortBy"        => {
              "name"        => "sort_by",
              "in"          => "query",
              "required"    => false,
              "schema"      => {
                "type" => "string"
              },
              "description" => "Attribute to sort by",
              "example"     => "name"
            },
            "sortOrder"     => {
              "name"        => "sort_order",
              "in"          => "query",
              "required"    => false,
              "schema"      => {
                "type" => "string",
                "enum" => ["asc", "desc"]
              },
              "description" => "Sort order (ascending or descending)",
              "example"     => "asc"
            },
            "offset"        => {
              "name"        => "offset",
              "in"          => "query",
              "required"    => false,
              "schema"      => {
                "type"    => "integer",
                "minimum" => 0,
                "default" => 0
              },
              "description" => "Number of resources to skip for pagination"
            },
            "limit"         => {
              "name"        => "limit",
              "in"          => "query",
              "required"    => false,
              "schema"      => {
                "type"    => "integer",
                "minimum" => 1,
                "maximum" => 1000,
                "default" => 100
              },
              "description" => "Maximum number of resources to return"
            }
          }
        end

        def self.collection_query_parameters
          [
            {"$ref" => "#{PARAMETERS_PATH}/expand"},
            {"$ref" => "#{PARAMETERS_PATH}/attributes"},
            {"$ref" => "#{PARAMETERS_PATH}/filter"},
            {"$ref" => "#{PARAMETERS_PATH}/sortBy"},
            {"$ref" => "#{PARAMETERS_PATH}/sortOrder"},
            {"$ref" => "#{PARAMETERS_PATH}/offset"},
            {"$ref" => "#{PARAMETERS_PATH}/limit"}
          ]
        end

        def self.resource_query_parameters
          [
            {"$ref" => "#{PARAMETERS_PATH}/expand"},
            {"$ref" => "#{PARAMETERS_PATH}/attributes"}
          ]
        end
      end
    end
  end
end
