module ManageIQ
  module Api
    module OpenApi
      module OperationBuilder
        SCHEMAS_PATH = "/components/schemas".freeze
        PARAMETERS_PATH = "/components/parameters".freeze

        def self.build_collection_index_operation(collection_name, collection, model_schema_name)
          {
            "summary"     => "List #{collection[:description] || collection_name}",
            "description" => "Returns a paginated list of #{collection[:description] || collection_name}",
            "operationId" => "list_#{collection_name}",
            "tags"        => [collection[:description] || collection_name.to_s.titleize],
            "parameters"  => ParameterBuilder.collection_query_parameters,
            "responses"   => {
              "200" => {
                "description" => "Success",
                "content"     => {
                  "application/json" => {
                    "schema" => SchemaBuilder.build_collection_response_schema(collection_name.to_s, model_schema_name)
                  }
                }
              }
            }.merge(error_responses)
          }
        end

        def self.build_resource_show_operation(collection_name, collection, model_schema_name)
          {
            "summary"     => "Get a #{collection[:description]&.singularize || collection_name.to_s.singularize}",
            "description" => "Returns a single #{collection[:description]&.singularize || collection_name.to_s.singularize} by ID",
            "operationId" => "get_#{collection_name.to_s.singularize}",
            "tags"        => [collection[:description] || collection_name.to_s.titleize],
            "parameters"  => [
              {
                "$ref" => File.join(PARAMETERS_PATH, "resourceId")
              }
            ] + ParameterBuilder.resource_query_parameters,
            "responses"   => {
              "200" => {
                "description" => "Success",
                "content"     => {
                  "application/json" => {
                    "schema" => SchemaBuilder.build_resource_response_schema(model_schema_name)
                  }
                }
              },
              "404" => SchemaBuilder.build_standard_responses["404"]
            }.merge(error_responses)
          }
        end

        def self.build_create_operation(collection_name, collection, model_schema_name)
          {
            "summary"     => "Create a #{collection[:description]&.singularize || collection_name.to_s.singularize}",
            "description" => "Creates a new #{collection[:description]&.singularize || collection_name.to_s.singularize}",
            "operationId" => "create_#{collection_name.to_s.singularize}",
            "tags"        => [collection[:description] || collection_name.to_s.titleize],
            "requestBody" => {
              "required" => true,
              "content"  => {
                "application/json" => {
                  "schema" => {
                    "$ref" => File.join(SCHEMAS_PATH, model_schema_name)
                  }
                }
              }
            },
            "responses"   => {
              "201" => {
                "description" => "Created",
                "content"     => {
                  "application/json" => {
                    "schema" => SchemaBuilder.build_resource_response_schema(model_schema_name)
                  }
                }
              },
              "400" => SchemaBuilder.build_standard_responses["400"],
              "422" => SchemaBuilder.build_standard_responses["422"]
            }.merge(error_responses)
          }
        end

        def self.build_update_operation(collection_name, collection, model_schema_name)
          {
            "summary"     => "Update a #{collection[:description]&.singularize || collection_name.to_s.singularize}",
            "description" => "Updates an existing #{collection[:description]&.singularize || collection_name.to_s.singularize}",
            "operationId" => "update_#{collection_name.to_s.singularize}",
            "tags"        => [collection[:description] || collection_name.to_s.titleize],
            "parameters"  => [
              {"$ref" => File.join(PARAMETERS_PATH, "resourceId")}
            ],
            "requestBody" => {
              "required" => true,
              "content"  => {
                "application/json" => {
                  "schema" => {
                    "$ref" => File.join(SCHEMAS_PATH, model_schema_name)
                  }
                }
              }
            },
            "responses"   => {
              "200" => {
                "description" => "Success",
                "content"     => {
                  "application/json" => {
                    "schema" => SchemaBuilder.build_resource_response_schema(model_schema_name)
                  }
                }
              },
              "404" => SchemaBuilder.build_standard_responses["404"],
              "422" => SchemaBuilder.build_standard_responses["422"]
            }.merge(error_responses)
          }
        end

        def self.build_delete_operation(collection_name, collection)
          {
            "summary"     => "Delete a #{collection[:description]&.singularize || collection_name.to_s.singularize}",
            "description" => "Deletes an existing #{collection[:description]&.singularize || collection_name.to_s.singularize}",
            "operationId" => "delete_#{collection_name.to_s.singularize}",
            "tags"        => [collection[:description] || collection_name.to_s.titleize],
            "parameters"  => [
              {"$ref" => File.join(PARAMETERS_PATH, "resourceId")}
            ],
            "responses"   => {
              "204" => SchemaBuilder.build_standard_responses["204"],
              "404" => SchemaBuilder.build_standard_responses["404"]
            }.merge(error_responses)
          }
        end

        def self.build_bulk_action_operation(collection_name, collection, model_schema_name)
          {
            "summary"     => "Perform bulk actions on #{collection[:description] || collection_name}",
            "description" => "Executes actions on multiple #{collection[:description] || collection_name} or performs queries",
            "operationId" => "bulk_action_#{collection_name}",
            "tags"        => [collection[:description] || collection_name.to_s.titleize],
            "requestBody" => {
              "required" => true,
              "content"  => {
                "application/json" => {
                  "schema" => {
                    "oneOf" => [
                      {
                        "type"       => "object",
                        "properties" => {
                          "action"    => {
                            "type"        => "string",
                            "description" => "Action to perform"
                          },
                          "resources" => {
                            "type"        => "array",
                            "description" => "Resources to perform action on",
                            "items"       => {
                              "type"       => "object",
                              "properties" => {
                                "href" => {
                                  "type"   => "string",
                                  "format" => "uri"
                                }
                              }
                            }
                          }
                        },
                        "required"   => ["action"]
                      },
                      {
                        "$ref" => File.join(SCHEMAS_PATH, model_schema_name)
                      }
                    ]
                  }
                }
              }
            },
            "responses"   => {
              "200" => {
                "description" => "Success",
                "content"     => {
                  "application/json" => {
                    "schema" => {
                      "type"       => "object",
                      "properties" => {
                        "results" => {
                          "type"  => "array",
                          "items" => {
                            "$ref" => File.join(SCHEMAS_PATH, model_schema_name)
                          }
                        }
                      }
                    }
                  }
                }
              },
              "400" => SchemaBuilder.build_standard_responses["400"],
              "422" => SchemaBuilder.build_standard_responses["422"]
            }.merge(error_responses)
          }
        end

        def self.build_resource_action_operation(collection_name, collection, model_schema_name)
          {
            "summary"     => "Perform action on a #{collection[:description]&.singularize || collection_name.to_s.singularize}",
            "description" => "Executes a custom action on a specific #{collection[:description]&.singularize || collection_name.to_s.singularize}",
            "operationId" => "action_#{collection_name.to_s.singularize}",
            "tags"        => [collection[:description] || collection_name.to_s.titleize],
            "parameters"  => [
              {"$ref" => File.join(PARAMETERS_PATH, "resourceId")}
            ],
            "requestBody" => {
              "required" => true,
              "content"  => {
                "application/json" => {
                  "schema" => {
                    "oneOf" => [
                      {
                        "type"       => "object",
                        "properties" => {
                          "action" => {
                            "type"        => "string",
                            "description" => "Action to perform"
                          }
                        },
                        "required"   => ["action"]
                      },
                      {
                        "$ref" => File.join(SCHEMAS_PATH, model_schema_name)
                      }
                    ]
                  }
                }
              }
            },
            "responses"   => {
              "200" => {
                "description" => "Success",
                "content"     => {
                  "application/json" => {
                    "schema" => SchemaBuilder.build_resource_response_schema(model_schema_name)
                  }
                }
              },
              "404" => SchemaBuilder.build_standard_responses["404"],
              "422" => SchemaBuilder.build_standard_responses["422"]
            }.merge(error_responses)
          }
        end

        def self.error_responses
          {
            "401" => SchemaBuilder.build_standard_responses["401"],
            "403" => SchemaBuilder.build_standard_responses["403"]
          }
        end
      end
    end
  end
end
