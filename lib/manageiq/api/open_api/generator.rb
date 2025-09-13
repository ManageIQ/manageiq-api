module ManageIQ
  module Api
    module OpenApi
      class Generator
        require 'json'

        OPENAPI_VERSION = "3.0.0".freeze
        PARAMETERS_PATH = "/components/parameters".freeze
        SCHEMAS_PATH    = "/components/schemas".freeze

        attr_reader :manageiq_api_path, :openapi_path, :openapi_spec

        def initialize
          manageiq_api_engine = Vmdb::Plugins.all.detect { |e| e.name == "ManageIQ::Api::Engine" }

          @manageiq_api_path = manageiq_api_engine.root
          @openapi_path      = manageiq_api_path.join("config", "openapi.json")
          @openapi_spec      = skeletal_openapi_spec
        end

        def generate!
          openapi_spec["components"]["schemas"] = build_schemas
          openapi_spec["components"]["parameters"] = build_common_parameters
          openapi_spec["paths"] = build_paths
          openapi_path.write("#{JSON.pretty_generate(openapi_spec)}\n")
        end

        # Helper method to safely get model class from klass (string or class)
        def get_model_class(klass)
          case klass
          when String
            begin
              klass.constantize
            rescue NameError => e
              puts "Warning: Could not constantize #{klass}: #{e.message}"
              nil
            end
          when Class
            klass
          else
            nil
          end
        end

        # Helper method to get schema name from model class
        def get_schema_name(model_class)
          model_class.name.gsub("::", "_")
        end

        private

        def api_version
          ManageIQ::Api::VERSION
        end

        def server_base_path
          "/api(/:version)"
        end
     
        # Build comprehensive paths with full CRUD operations
        def build_paths
          paths = {}
          
          ::Api::ApiConfig.collections.each do |collection_name, collection|
            next unless collection.klass
            
            # Skip if we can't get a valid model class
            model_class = get_model_class(collection.klass)
            next unless model_class
            
            schema_name = get_schema_name(model_class)
            
            # Collection endpoints (e.g., /api/vms)
            collection_path = "/api/#{collection_name}"
            paths[collection_path] = build_collection_operations(collection_name, collection, model_class, schema_name)
            
            # Resource endpoints (e.g., /api/vms/{id})
            resource_path = "/api/#{collection_name}/{id}"
            paths[resource_path] = build_resource_operations(collection_name, collection, model_class, schema_name)
            
            # Add subcollection paths if they exist
            if collection.respond_to?(:subcollections) && collection.subcollections&.any?
              build_subcollection_paths(paths, collection_name, collection.subcollections)
            end
          end
          
          # Add authentication endpoints
          paths.merge!(build_auth_paths)
          
          paths
        end

        # Build collection-level operations (GET /api/vms, POST /api/vms)
        def build_collection_operations(collection_name, collection, model_class, schema_name)
          operations = {}
          
          # GET collection - always available
          operations["get"] = {
            "summary" => "List #{collection_name}",
            "description" => "Retrieve a list of #{collection_name} with optional filtering, sorting, and pagination",
            "parameters" => [
              {"$ref" => "##{PARAMETERS_PATH}/expand"},
              {"$ref" => "##{PARAMETERS_PATH}/attributes"},
              {"$ref" => "##{PARAMETERS_PATH}/filter"},
              {"$ref" => "##{PARAMETERS_PATH}/sort_by"},
              {"$ref" => "##{PARAMETERS_PATH}/sort_order"},
              {"$ref" => "##{PARAMETERS_PATH}/offset"},
              {"$ref" => "##{PARAMETERS_PATH}/limit"}
            ],
            "responses" => {
              "200" => {
                "description" => "Successful response",
                "content" => {
                  "application/json" => {
                    "schema" => {
                      "type" => "object",
                      "properties" => {
                        "name" => {"type" => "string", "example" => collection_name},
                        "count" => {"type" => "integer", "description" => "Total number of resources"},
                        "subcount" => {"type" => "integer", "description" => "Number of resources returned"},
                        "pages" => {"type" => "integer", "description" => "Total number of pages"},
                        "resources" => {
                          "type" => "array",
                          "items" => {"$ref" => "##{SCHEMAS_PATH}/#{schema_name}"}
                        }
                      }
                    }
                  }
                }
              },
              "400" => {"description" => "Bad Request"},
              "401" => {"description" => "Unauthorized"},
              "403" => {"description" => "Forbidden"}
            },
            "tags" => [collection_name.to_s.titleize]
          }
          
          # POST collection - if creation is supported
          if supports_collection_action?(collection, :post)
            operations["post"] = {
              "summary" => "Create #{collection_name.to_s.singularize}",
              "description" => "Create a new #{collection_name.to_s.singularize}",
              "requestBody" => {
                "required" => true,
                "content" => {
                  "application/json" => {
                    "schema" => build_create_schema(model_class, schema_name)
                  }
                }
              },
              "responses" => {
                "201" => {
                  "description" => "Resource created successfully",
                  "content" => {
                    "application/json" => {
                      "schema" => {"$ref" => "##{SCHEMAS_PATH}/#{schema_name}"}
                    }
                  }
                },
                "400" => {"description" => "Bad Request - Invalid input"},
                "401" => {"description" => "Unauthorized"},
                "403" => {"description" => "Forbidden"},
                "422" => {"description" => "Unprocessable Entity - Validation errors"}
              },
              "tags" => [collection_name.to_s.titleize]
            }
          end
          
          operations
        end

        # Build resource-level operations (GET /api/vms/{id}, PATCH /api/vms/{id}, DELETE /api/vms/{id})
        def build_resource_operations(collection_name, collection, model_class, schema_name)
          operations = {}
          
          # GET resource - always available
          operations["get"] = {
            "summary" => "Get #{collection_name.to_s.singularize}",
            "description" => "Retrieve a specific #{collection_name.to_s.singularize} by ID",
            "parameters" => [
              {"$ref" => "##{PARAMETERS_PATH}/id"},
              {"$ref" => "##{PARAMETERS_PATH}/expand"},
              {"$ref" => "##{PARAMETERS_PATH}/attributes"}
            ],
            "responses" => {
              "200" => {
                "description" => "Successful response",
                "content" => {
                  "application/json" => {
                    "schema" => {"$ref" => "##{SCHEMAS_PATH}/#{schema_name}"}
                  }
                }
              },
              "404" => {"description" => "Resource not found"},
              "401" => {"description" => "Unauthorized"},
              "403" => {"description" => "Forbidden"}
            },
            "tags" => [collection_name.to_s.titleize]
          }
          
          # PATCH resource - if editing is supported
          if supports_resource_action?(collection, :edit) || supports_resource_action?(collection, :patch)
            operations["patch"] = {
              "summary" => "Update #{collection_name.to_s.singularize}",
              "description" => "Update a specific #{collection_name.to_s.singularize}",
              "parameters" => [{"$ref" => "##{PARAMETERS_PATH}/id"}],
              "requestBody" => {
                "required" => true,
                "content" => {
                  "application/json" => {
                    "schema" => build_update_schema(model_class, schema_name)
                  }
                }
              },
              "responses" => {
                "200" => {
                  "description" => "Resource updated successfully",
                  "content" => {
                    "application/json" => {
                      "schema" => {"$ref" => "##{SCHEMAS_PATH}/#{schema_name}"}
                    }
                  }
                },
                "400" => {"description" => "Bad Request - Invalid input"},
                "404" => {"description" => "Resource not found"},
                "401" => {"description" => "Unauthorized"},
                "403" => {"description" => "Forbidden"},
                "422" => {"description" => "Unprocessable Entity - Validation errors"}
              },
              "tags" => [collection_name.to_s.titleize]
            }
          end
          
          # DELETE resource - if deletion is supported  
          if supports_resource_action?(collection, :delete)
            operations["delete"] = {
              "summary" => "Delete #{collection_name.to_s.singularize}",
              "description" => "Delete a specific #{collection_name.to_s.singularize}",
              "parameters" => [{"$ref" => "##{PARAMETERS_PATH}/id"}],
              "responses" => {
                "204" => {"description" => "Resource deleted successfully"},
                "404" => {"description" => "Resource not found"},
                "401" => {"description" => "Unauthorized"},
                "403" => {"description" => "Forbidden"},
                "409" => {"description" => "Conflict - Resource cannot be deleted"}
              },
              "tags" => [collection_name.to_s.titleize]
            }
          end
          
          # POST for actions - if resource actions exist
          resource_actions = get_resource_actions(collection)
          if resource_actions.any?
            operations["post"] = build_resource_action_operation(collection_name, resource_actions)
          end
          
          operations
        end

        # Build subcollection paths
        def build_subcollection_paths(paths, collection_name, subcollections)
          subcollections.each do |subcoll_name, subcollection|
            # Subcollection list endpoint
            subcoll_path = "/api/#{collection_name}/{id}/#{subcoll_name}"
            paths[subcoll_path] = {
              "get" => {
                "summary" => "List #{subcoll_name} for #{collection_name.to_s.singularize}",
                "description" => "Retrieve #{subcoll_name} associated with a specific #{collection_name.to_s.singularize}",
                "parameters" => [
                  {"$ref" => "##{PARAMETERS_PATH}/id"},
                  {"$ref" => "##{PARAMETERS_PATH}/expand"},
                  {"$ref" => "##{PARAMETERS_PATH}/attributes"}
                ],
                "responses" => {
                  "200" => {"description" => "Successful response"},
                  "404" => {"description" => "Parent resource not found"}
                },
                "tags" => [collection_name.to_s.titleize]
              }
            }
            
            # Individual subcollection resource endpoint
            subcoll_resource_path = "/api/#{collection_name}/{id}/#{subcoll_name}/{subcoll_id}"
            paths[subcoll_resource_path] = {
              "get" => {
                "summary" => "Get #{subcoll_name.to_s.singularize} for #{collection_name.to_s.singularize}",
                "description" => "Retrieve a specific #{subcoll_name.to_s.singularize} for a #{collection_name.to_s.singularize}",
                "parameters" => [
                  {"$ref" => "##{PARAMETERS_PATH}/id"},
                  {"$ref" => "##{PARAMETERS_PATH}/subcoll_id"},
                  {"$ref" => "##{PARAMETERS_PATH}/expand"},
                  {"$ref" => "##{PARAMETERS_PATH}/attributes"}
                ],
                "responses" => {
                  "200" => {"description" => "Successful response"},
                  "404" => {"description" => "Resource not found"}
                },
                "tags" => [collection_name.to_s.titleize]
              }
            }
          end
        end

        # Build resource action operation (POST /api/vms/{id} with action)
        def build_resource_action_operation(collection_name, resource_actions)
          action_examples = resource_actions.first(3).map { |action| {"action" => action.to_s} }
          
          {
            "summary" => "Perform action on #{collection_name.to_s.singularize}",
            "description" => "Perform various actions on a specific #{collection_name.to_s.singularize}. Available actions: #{resource_actions.join(', ')}",
            "parameters" => [{"$ref" => "##{PARAMETERS_PATH}/id"}],
            "requestBody" => {
              "required" => true,
              "content" => {
                "application/json" => {
                  "schema" => {
                    "type" => "object",
                    "required" => ["action"],
                    "properties" => {
                      "action" => {
                        "type" => "string", 
                        "enum" => resource_actions.map(&:to_s),
                        "description" => "The action to perform"
                      }
                    }
                  },
                  "examples" => action_examples.each_with_index.to_h { |example, i| ["example_#{i + 1}", {"value" => example}] }
                }
              }
            },
            "responses" => {
              "200" => {"description" => "Action performed successfully"},
              "400" => {"description" => "Bad Request - Invalid action or parameters"},
              "404" => {"description" => "Resource not found"},
              "401" => {"description" => "Unauthorized"},
              "403" => {"description" => "Forbidden"},
              "422" => {"description" => "Action cannot be performed"}
            },
            "tags" => [collection_name.to_s.titleize]
          }
        end

        # Build authentication paths
        def build_auth_paths
          {
            "/api/auth" => {
              "get" => {
                "summary" => "Get authentication info",
                "description" => "Retrieve current authentication information and user details",
                "responses" => {
                  "200" => {
                    "description" => "Authentication info",
                    "content" => {
                      "application/json" => {
                        "schema" => {
                          "type" => "object",
                          "properties" => {
                            "identity" => {"type" => "object"},
                            "user_href" => {"type" => "string"},
                            "token_ttl" => {"type" => "integer"}
                          }
                        }
                      }
                    }
                  }
                },
                "tags" => ["Authentication"]
              },
              "post" => {
                "summary" => "Authenticate user",
                "description" => "Authenticate user with credentials",
                "requestBody" => {
                  "required" => true,
                  "content" => {
                    "application/json" => {
                      "schema" => {
                        "type" => "object",
                        "required" => ["user", "password"],
                        "properties" => {
                          "user" => {"type" => "string", "example" => "admin"},
                          "password" => {"type" => "string", "example" => "password"}
                        }
                      }
                    }
                  }
                },
                "responses" => {
                  "200" => {"description" => "Authentication successful"},
                  "401" => {"description" => "Authentication failed"}
                },
                "security" => [],
                "tags" => ["Authentication"]
              },
              "delete" => {
                "summary" => "Logout",
                "description" => "Logout current user and invalidate session",
                "responses" => {
                  "204" => {"description" => "Logout successful"}
                },
                "tags" => ["Authentication"]
              }
            }
          }
        end

        # Helper methods for checking collection/resource capabilities
        def supports_collection_action?(collection, action)
          collection.respond_to?(:collection_actions) && 
          collection.collection_actions&.key?(action)
        end

        def supports_resource_action?(collection, action)
          collection.respond_to?(:resource_actions) && 
          collection.resource_actions&.key?(action)
        end

        def get_resource_actions(collection)
          if collection.respond_to?(:resource_actions) && collection.resource_actions
            collection.resource_actions.keys
          else
            []
          end
        end

        # Build schema for create operations (excludes read-only fields)
        def build_create_schema(model_class, schema_name)
          {
            "type" => "object",
            "properties" => build_writable_properties(model_class),
            "additionalProperties" => false
          }
        end

        # Build schema for update operations (all fields optional, excludes read-only)
        def build_update_schema(model_class, schema_name)
          properties = build_writable_properties(model_class)
          # Make all properties optional for PATCH
          properties.each { |_, prop| prop.delete("required") if prop.is_a?(Hash) }
          
          {
            "type" => "object",
            "properties" => properties,
            "additionalProperties" => false
          }
        end

        # Get writable properties (exclude read-only fields like id, timestamps)
        def build_writable_properties(model_class)
          read_only_fields = %w[id created_at updated_at created_on updated_on]
          
          model_class.columns_hash.each_with_object({}) do |(key, value), properties|
            next if read_only_fields.include?(key)
            next if key.ends_with?('_id') && key != model_class.primary_key
            
            properties[key] = build_schema_properties_value(model_class, key, value)
          end
        end

        # Build comprehensive common parameters
        def build_common_parameters
          {
            "id" => {
              "name" => "id",
              "in" => "path",
              "description" => "ID of the resource",
              "required" => true,
              "schema" => {"$ref" => "##{SCHEMAS_PATH}/ID"},
              "example" => "123"
            },
            "subcoll_id" => {
              "name" => "subcoll_id",
              "in" => "path",
              "description" => "ID of the subcollection resource",
              "required" => true,
              "schema" => {"type" => "string"},
              "example" => "456"
            },
            "expand" => {
              "name" => "expand",
              "in" => "query",
              "description" => "Comma-separated list of objects to expand in the response",
              "required" => false,
              "schema" => {"type" => "string"},
              "example" => "resources,subcounts"
            },
            "attributes" => {
              "name" => "attributes",
              "in" => "query", 
              "description" => "Comma-separated list of attributes to return",
              "required" => false,
              "schema" => {"type" => "string"},
              "example" => "id,name,description"
            },
            "filter" => {
              "name" => "filter[]",
              "in" => "query",
              "description" => "Filter criteria in the format 'attribute=value'",
              "required" => false,
              "style" => "form",
              "explode" => true,
              "schema" => {"type" => "array", "items" => {"type" => "string"}},
              "example" => ["name=test", "state=active"]
            },
            "sort_by" => {
              "name" => "sort_by",
              "in" => "query",
              "description" => "Attribute to sort by",
              "required" => false,
              "schema" => {"type" => "string"},
              "example" => "name"
            },
            "sort_order" => {
              "name" => "sort_order",
              "in" => "query",
              "description" => "Sort order (ascending or descending)",
              "required" => false,
              "schema" => {"type" => "string", "enum" => ["asc", "desc"], "default" => "asc"},
              "example" => "asc"
            },
            "offset" => {
              "name" => "offset",
              "in" => "query",
              "description" => "Number of resources to skip (for pagination)",
              "required" => false,
              "schema" => {"type" => "integer", "minimum" => 0, "default" => 0},
              "example" => 0
            },
            "limit" => {
              "name" => "limit",
              "in" => "query",
              "description" => "Maximum number of resources to return (for pagination)",
              "required" => false,
              "schema" => {"type" => "integer", "minimum" => 1, "maximum" => 1000, "default" => 100},
              "example" => 100
            }
          }
        end

        # Build schemas with comprehensive error handling
        def build_schemas
          schemas = {
            "ID" => {
              "type"        => "string",
              "description" => "ID of the resource",
              "pattern"     => "^\\d+$",
              "readOnly"    => true,
              "example"     => "123"
            },
            "Error" => {
              "type" => "object",
              "properties" => {
                "error" => {
                  "type" => "object",
                  "properties" => {
                    "kind" => {"type" => "string"},
                    "message" => {"type" => "string"},
                    "klass" => {"type" => "string"}
                  }
                }
              }
            }
          }
  
          models = ::Api::ApiConfig.collections.each_with_object({}) do |(_collection_name, collection), s|
            next unless collection.klass
            
            model_class = get_model_class(collection.klass)
            next unless model_class
            
            schema_name = get_schema_name(model_class)
            s[schema_name] = {
              "type"                 => "object",
              "properties"           => build_schema_properties(model_class),
              "additionalProperties" => false
            }
          end
  
          schemas.merge(models.sort.to_h)
        end

        def build_schema_properties(model)
          model.columns_hash.each_with_object({}) do |(key, value), properties|
            properties[key] = build_schema_properties_value(model, key, value)
          end
        end

        def build_schema_properties_value(model, key, value)
          properties_value = {}
  
          case value.sql_type_metadata.type
          when :datetime
            properties_value["type"]   = "string"
            properties_value["format"] = "date-time"
            properties_value["example"] = "2023-01-01T00:00:00Z"
          when :date
            properties_value["type"]   = "string"
            properties_value["format"] = "date"
            properties_value["example"] = "2023-01-01"
          when :integer
            if key == model.primary_key || key.ends_with?("_id")
              properties_value["$ref"] = "##{SCHEMAS_PATH}/ID"
            else
              properties_value["type"] = "integer"
              properties_value["example"] = 42
            end
          when :float, :decimal
            properties_value["type"] = "number"
            properties_value["example"] = 3.14
          when :boolean
            properties_value["type"] = "boolean"
            properties_value["example"] = true
          when :jsonb, :json
            properties_value["type"] = "object"
            properties_value["example"] = {"key" => "value"}
          when :text
            properties_value["type"] = "string"
            properties_value["example"] = "Long text content..."
          else
            properties_value["type"] = "string"
            properties_value["example"] = "sample text"
          end
          
          # Mark read-only fields
          read_only_fields = %w[id created_at updated_at created_on updated_on]
          if read_only_fields.include?(key)
            properties_value["readOnly"] = true
          end
          
          # Add description from column comment
          if value.comment.present?
            if properties_value.key?("$ref")
              properties_value = {"allOf" => [properties_value, {"description" => value.comment}]}
            else
              properties_value["description"] = value.comment
            end
          end

          properties_value
        end

        def skeletal_openapi_spec
          {
            "openapi"    => OPENAPI_VERSION,
            "info"       => {
              "version"     => api_version,
              "title"       => ::Api::ApiConfig.base.name,
              "description" => "#{::Api::ApiConfig.base.description}\n\n" +
                               "This API supports full CRUD operations with filtering, sorting, pagination, and resource expansion."
            },
            "servers"    => [
              {
                "url" => server_base_path,
                "description" => "ManageIQ API Server"
              }
            ],
            "paths"      => {},
            "components" => {
              "parameters" => {},
              "schemas"    => {},
              "securitySchemes" => {
                "basicAuth" => {
                  "type" => "http",
                  "scheme" => "basic",
                  "description" => "HTTP Basic Authentication"
                },
                "bearerAuth" => {
                  "type" => "http",
                  "scheme" => "bearer",
                  "description" => "Bearer token authentication"
                }
              }
            },
            "security" => [
              {"basicAuth" => []},
              {"bearerAuth" => []}
            ]
          }
        end
      end
    end
  end
end
