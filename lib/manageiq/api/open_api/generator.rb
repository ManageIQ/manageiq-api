module ManageIQ
  module Api
    module OpenApi
      class Generator
        require 'json'

        PARAMETERS_PATH = "/components/parameters".freeze
        SCHEMAS_PATH = "/components/schemas".freeze

        def generate!
          openapi_spec["paths"] = build_paths
          openapi_spec["components"]["schemas"] = build_schemas
          openapi_spec["components"]["parameters"] = build_parameters
          File.write(openapi_file, JSON.pretty_generate(openapi_spec) + "\n")
        end

        private

        def api_version
          ManageIQ::Api::VERSION
        end

        def server_base_path
          "/api(/:version)"
        end

        def build_paths
          ::Api::ApiConfig.collections.each_with_object({}) do |(collection_name, collection), paths|
            build_schema(collection.klass) if collection.klass

            sub_path = "/#{collection_name}"
            paths[sub_path] ||= {}
            collection.verbs.each do |verb|
              paths[sub_path][verb] = {}
            end
          end
        end

        def build_schema(klass_name)
          model = klass_name.constantize

          schemas[model.name] = {
            "type"                 => "object",
            "properties"           => build_schema_properties(model),
            "additionalProperties" => false
          }
        end

        def build_schema_properties(model)
          model.columns_hash.each_with_object({}) do |(key, value), properties|
            properties[key] = build_schema_properties_value(model, key, value)
          end
        end

        def build_schema_properties_value(model, key, value)
          if key == model.primary_key || key.ends_with?("_id")
            {"$ref" => "##{SCHEMAS_PATH}/ID"}
          else
            properties_value = {
              "type" => "string"
            }

            case value.sql_type_metadata.type
            when :datetime
              properties_value["format"] = "date-time"
            when :integer
              properties_value["type"] = "integer"
            when :float
              properties_value["type"] = "number"
            when :boolean
              properties_value["type"] = "boolean"
            when :jsonb
              properties_value["type"] = "object"
            end

            properties_value
          end
        end

        def build_schemas
          schemas
        end

        def schemas
          @schemas ||= {
            "ID" => {
              "type"        => "string",
              "description" => "ID of the resource",
              "pattern"     => "^\\d+$",
              "readOnly"    => true,
            }
          }
        end

        def build_parameters
          parameters.sort
        end

        def parameters
          @parameters ||= {}
        end

        def openapi_version
          "3.0.0".freeze
        end

        def openapi_file
          @openapi_file ||= manageiq_api_path.join("config", "openapi.json")
        end

        def openapi_spec
          @openapi_spec ||= skeletal_openapi_spec
        end

        def manageiq_api_path
          @manageiq_api_path ||= manageiq_api_engine.root
        end

        def manageiq_api_engine
          @manageiq_api_engine ||= Vmdb::Plugins.all.detect { |e| e.name == "ManageIQ::Api::Engine" }
        end

        def skeletal_openapi_spec
          {
            "openapi"    => openapi_version,
            "info"       => {},
            "secuirty"   => [],
            "paths"      => {},
            "servers"    => [],
            "components" => {
              "parameters" => {},
              "schemas"    => {}
            },
          }
        end
      end
    end
  end
end
