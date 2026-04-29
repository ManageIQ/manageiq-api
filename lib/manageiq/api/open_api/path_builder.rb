module ManageIQ
  module Api
    module OpenApi
      module PathBuilder
        PARAMETERS_PATH = "/components/parameters".freeze

        def self.build_paths(collections)
          paths = {}

          collections.each do |collection_name, collection|
            # Skip collections without a model class
            next unless collection.klass

            model_schema_name = collection.klass.gsub("::", "_")

            # Handle primary collections (e.g., auth)
            if collection.options.include?(:primary)
              build_primary_collection_paths(paths, collection_name, collection, model_schema_name)
              next
            end

            # Handle regular collections
            if collection.options.include?(:collection)
              build_collection_paths(paths, collection_name, collection, model_schema_name)
            end

            # Handle subcollections
            if collection.options.include?(:subcollection)
              # Subcollections are handled when processing their parent collections
              next
            end
          end

          paths
        end

        def self.build_primary_collection_paths(paths, collection_name, collection, model_schema_name)
          base_path = "/api/{version}/#{collection_name}"

          path_item = {}

          # Add operations based on verbs
          collection.verbs.each do |verb|
            case verb
            when :get
              path_item["get"] = OperationBuilder.build_collection_index_operation(
                collection_name, collection, model_schema_name
              )
            when :post
              path_item["post"] = OperationBuilder.build_bulk_action_operation(
                collection_name, collection, model_schema_name
              )
            when :delete
              path_item["delete"] = {
                "summary"     => "Delete #{collection[:description] || collection_name}",
                "description" => "Deletes the #{collection[:description] || collection_name}",
                "operationId" => "delete_#{collection_name}",
                "tags"        => [collection[:description] || collection_name.to_s.titleize],
                "responses"   => {
                  "204" => SchemaBuilder.build_standard_responses["204"]
                }.merge(OperationBuilder.error_responses)
              }
            end
          end

          # Add OPTIONS
          path_item["options"] = build_options_operation(collection_name, collection)

          paths[base_path] = path_item unless path_item.empty?
        end

        def self.build_collection_paths(paths, collection_name, collection, model_schema_name)
          # Collection index path: /api/{version}/collection_name
          collection_path = "/api/{version}/#{collection_name}"

          # Resource path: /api/{version}/collection_name/{c_id}
          resource_path = "/api/{version}/#{collection_name}/{c_id}"

          collection_operations = {}
          resource_operations = {}

          # Build operations based on verbs
          collection.verbs.each do |verb|
            case verb
            when :get
              # GET collection (index)
              collection_operations["get"] = OperationBuilder.build_collection_index_operation(
                collection_name, collection, model_schema_name
              )

              # GET resource (show)
              resource_operations["get"] = OperationBuilder.build_resource_show_operation(
                collection_name, collection, model_schema_name
              )

            when :post
              # POST collection (create or bulk action)
              collection_operations["post"] = OperationBuilder.build_create_operation(
                collection_name, collection, model_schema_name
              )

              # POST resource (update or action)
              resource_operations["post"] = if collection.options.include?(:custom_actions)
                                              OperationBuilder.build_resource_action_operation(
                                                collection_name, collection, model_schema_name
                                              )
                                            else
                                              OperationBuilder.build_update_operation(
                                                collection_name, collection, model_schema_name
                                              )
                                            end

            when :put
              # PUT resource (update)
              resource_operations["put"] = OperationBuilder.build_update_operation(
                collection_name, collection, model_schema_name
              )

            when :patch
              # PATCH resource (update)
              resource_operations["patch"] = OperationBuilder.build_update_operation(
                collection_name, collection, model_schema_name
              )

            when :delete
              # DELETE resource
              resource_operations["delete"] = OperationBuilder.build_delete_operation(
                collection_name, collection
              )
            end
          end

          # Add OPTIONS
          collection_operations["options"] = build_options_operation(collection_name, collection)
          resource_operations["options"] = build_options_operation(collection_name, collection)

          paths[collection_path] = collection_operations unless collection_operations.empty?
          paths[resource_path] = resource_operations unless resource_operations.empty?

          # Build subcollection paths
          collection.subcollections&.each do |subcollection_name|
            build_subcollection_paths(
              paths,
              collection_name,
              subcollection_name,
              collection,
              ::Api::ApiConfig.collections[subcollection_name]
            )
          end
        end

        def self.build_subcollection_paths(paths, parent_collection_name, subcollection_name, parent_collection, subcollection)
          return unless subcollection&.klass

          model_schema_name = subcollection.klass.gsub("::", "_")

          # Special case: settings subcollection
          if subcollection_name == :settings
            settings_path = "/api/{version}/#{parent_collection_name}/{c_id}/settings"

            settings_operations = {
              "get"     => {
                "summary"     => "Get settings for #{parent_collection[:description]&.singularize || parent_collection_name.to_s.singularize}",
                "description" => "Returns settings for the specified resource",
                "operationId" => "get_#{parent_collection_name.to_s.singularize}_settings",
                "tags"        => [parent_collection[:description] || parent_collection_name.to_s.titleize],
                "parameters"  => [
                  {"$ref" => "#{PARAMETERS_PATH}/resourceId"}
                ],
                "responses"   => {
                  "200" => {
                    "description" => "Success",
                    "content"     => {
                      "application/json" => {
                        "schema" => {
                          "type"                 => "object",
                          "additionalProperties" => true
                        }
                      }
                    }
                  },
                  "404" => SchemaBuilder.build_standard_responses["404"]
                }.merge(OperationBuilder.error_responses)
              },
              "patch"   => {
                "summary"     => "Update settings for #{parent_collection[:description]&.singularize || parent_collection_name.to_s.singularize}",
                "description" => "Updates settings for the specified resource",
                "operationId" => "update_#{parent_collection_name.to_s.singularize}_settings",
                "tags"        => [parent_collection[:description] || parent_collection_name.to_s.titleize],
                "parameters"  => [
                  {"$ref" => "#{PARAMETERS_PATH}/resourceId"}
                ],
                "requestBody" => {
                  "required" => true,
                  "content"  => {
                    "application/json" => {
                      "schema" => {
                        "type"                 => "object",
                        "additionalProperties" => true
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
                          "type"                 => "object",
                          "additionalProperties" => true
                        }
                      }
                    }
                  },
                  "404" => SchemaBuilder.build_standard_responses["404"],
                  "422" => SchemaBuilder.build_standard_responses["422"]
                }.merge(OperationBuilder.error_responses)
              },
              "delete"  => {
                "summary"     => "Delete settings for #{parent_collection[:description]&.singularize || parent_collection_name.to_s.singularize}",
                "description" => "Deletes settings for the specified resource",
                "operationId" => "delete_#{parent_collection_name.to_s.singularize}_settings",
                "tags"        => [parent_collection[:description] || parent_collection_name.to_s.titleize],
                "parameters"  => [
                  {"$ref" => "#{PARAMETERS_PATH}/resourceId"}
                ],
                "responses"   => {
                  "204" => SchemaBuilder.build_standard_responses["204"],
                  "404" => SchemaBuilder.build_standard_responses["404"]
                }.merge(OperationBuilder.error_responses)
              },
              "options" => build_options_operation(subcollection_name, subcollection)
            }

            paths[settings_path] = settings_operations
            return
          end

          # Subcollection index path: /api/{version}/parent/{c_id}/subcollection
          subcollection_path = "/api/{version}/#{parent_collection_name}/{c_id}/#{subcollection_name}"

          # Subresource path: /api/{version}/parent/{c_id}/subcollection/{s_id}
          subresource_path = "/api/{version}/#{parent_collection_name}/{c_id}/#{subcollection_name}/{s_id}"

          subcollection_operations = {}
          subresource_operations = {}

          # Build operations based on verbs
          subcollection.verbs.each do |verb|
            case verb
            when :get
              # GET subcollection (index)
              subcollection_operations["get"] = {
                "summary"     => "List #{subcollection[:description] || subcollection_name} for #{parent_collection[:description]&.singularize || parent_collection_name.to_s.singularize}",
                "description" => "Returns a paginated list of #{subcollection[:description] || subcollection_name}",
                "operationId" => "list_#{parent_collection_name.to_s.singularize}_#{subcollection_name}",
                "tags"        => [parent_collection[:description] || parent_collection_name.to_s.titleize],
                "parameters"  => [
                  {"$ref" => "#{PARAMETERS_PATH}/resourceId"}
                ] + ParameterBuilder.collection_query_parameters,
                "responses"   => {
                  "200" => {
                    "description" => "Success",
                    "content"     => {
                      "application/json" => {
                        "schema" => SchemaBuilder.build_collection_response_schema(subcollection_name.to_s, model_schema_name)
                      }
                    }
                  },
                  "404" => SchemaBuilder.build_standard_responses["404"]
                }.merge(OperationBuilder.error_responses)
              }

              # GET subresource (show)
              subresource_operations["get"] = {
                "summary"     => "Get a #{subcollection[:description]&.singularize || subcollection_name.to_s.singularize}",
                "description" => "Returns a single #{subcollection[:description]&.singularize || subcollection_name.to_s.singularize} by ID",
                "operationId" => "get_#{parent_collection_name.to_s.singularize}_#{subcollection_name.to_s.singularize}",
                "tags"        => [parent_collection[:description] || parent_collection_name.to_s.titleize],
                "parameters"  => [
                  {"$ref" => "#{PARAMETERS_PATH}/resourceId"},
                  {"$ref" => "#{PARAMETERS_PATH}/subResourceId"}
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
                }.merge(OperationBuilder.error_responses)
              }

            when :post
              # POST subcollection (create)
              subcollection_operations["post"] = {
                "summary"     => "Create a #{subcollection[:description]&.singularize || subcollection_name.to_s.singularize}",
                "description" => "Creates a new #{subcollection[:description]&.singularize || subcollection_name.to_s.singularize}",
                "operationId" => "create_#{parent_collection_name.to_s.singularize}_#{subcollection_name.to_s.singularize}",
                "tags"        => [parent_collection[:description] || parent_collection_name.to_s.titleize],
                "parameters"  => [
                  {"$ref" => "#{PARAMETERS_PATH}/resourceId"}
                ],
                "requestBody" => {
                  "required" => true,
                  "content"  => {
                    "application/json" => {
                      "schema" => {
                        "$ref" => "#{SchemaBuilder::SCHEMAS_PATH}/#{model_schema_name}"
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
                  "404" => SchemaBuilder.build_standard_responses["404"],
                  "422" => SchemaBuilder.build_standard_responses["422"]
                }.merge(OperationBuilder.error_responses)
              }

              # POST subresource (update)
              subresource_operations["post"] = {
                "summary"     => "Update a #{subcollection[:description]&.singularize || subcollection_name.to_s.singularize}",
                "description" => "Updates an existing #{subcollection[:description]&.singularize || subcollection_name.to_s.singularize}",
                "operationId" => "update_#{parent_collection_name.to_s.singularize}_#{subcollection_name.to_s.singularize}",
                "tags"        => [parent_collection[:description] || parent_collection_name.to_s.titleize],
                "parameters"  => [
                  {"$ref" => "#{PARAMETERS_PATH}/resourceId"},
                  {"$ref" => "#{PARAMETERS_PATH}/subResourceId"}
                ],
                "requestBody" => {
                  "required" => true,
                  "content"  => {
                    "application/json" => {
                      "schema" => {
                        "$ref" => "#{SchemaBuilder::SCHEMAS_PATH}/#{model_schema_name}"
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
                }.merge(OperationBuilder.error_responses)
              }

            when :put
              # PUT subresource (update)
              subresource_operations["put"] = {
                "summary"     => "Update a #{subcollection[:description]&.singularize || subcollection_name.to_s.singularize}",
                "description" => "Updates an existing #{subcollection[:description]&.singularize || subcollection_name.to_s.singularize}",
                "operationId" => "put_#{parent_collection_name.to_s.singularize}_#{subcollection_name.to_s.singularize}",
                "tags"        => [parent_collection[:description] || parent_collection_name.to_s.titleize],
                "parameters"  => [
                  {"$ref" => "#{PARAMETERS_PATH}/resourceId"},
                  {"$ref" => "#{PARAMETERS_PATH}/subResourceId"}
                ],
                "requestBody" => {
                  "required" => true,
                  "content"  => {
                    "application/json" => {
                      "schema" => {
                        "$ref" => "#{SchemaBuilder::SCHEMAS_PATH}/#{model_schema_name}"
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
                }.merge(OperationBuilder.error_responses)
              }

            when :patch
              # PATCH subresource (update)
              subresource_operations["patch"] = {
                "summary"     => "Update a #{subcollection[:description]&.singularize || subcollection_name.to_s.singularize}",
                "description" => "Updates an existing #{subcollection[:description]&.singularize || subcollection_name.to_s.singularize}",
                "operationId" => "patch_#{parent_collection_name.to_s.singularize}_#{subcollection_name.to_s.singularize}",
                "tags"        => [parent_collection[:description] || parent_collection_name.to_s.titleize],
                "parameters"  => [
                  {"$ref" => "#{PARAMETERS_PATH}/resourceId"},
                  {"$ref" => "#{PARAMETERS_PATH}/subResourceId"}
                ],
                "requestBody" => {
                  "required" => true,
                  "content"  => {
                    "application/json" => {
                      "schema" => {
                        "$ref" => "#{SchemaBuilder::SCHEMAS_PATH}/#{model_schema_name}"
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
                }.merge(OperationBuilder.error_responses)
              }

            when :delete
              # DELETE subresource
              subresource_operations["delete"] = {
                "summary"     => "Delete a #{subcollection[:description]&.singularize || subcollection_name.to_s.singularize}",
                "description" => "Deletes an existing #{subcollection[:description]&.singularize || subcollection_name.to_s.singularize}",
                "operationId" => "delete_#{parent_collection_name.to_s.singularize}_#{subcollection_name.to_s.singularize}",
                "tags"        => [parent_collection[:description] || parent_collection_name.to_s.titleize],
                "parameters"  => [
                  {"$ref" => "#{PARAMETERS_PATH}/resourceId"},
                  {"$ref" => "#{PARAMETERS_PATH}/subResourceId"}
                ],
                "responses"   => {
                  "204" => SchemaBuilder.build_standard_responses["204"],
                  "404" => SchemaBuilder.build_standard_responses["404"]
                }.merge(OperationBuilder.error_responses)
              }
            end
          end

          # Add OPTIONS
          subcollection_operations["options"] = build_options_operation(subcollection_name, subcollection)
          subresource_operations["options"] = build_options_operation(subcollection_name, subcollection)

          paths[subcollection_path] = subcollection_operations unless subcollection_operations.empty?
          paths[subresource_path] = subresource_operations unless subresource_operations.empty?
        end

        def self.build_options_operation(collection_name, collection)
          {
            "summary"     => "Get options for #{collection[:description] || collection_name}",
            "description" => "Returns available HTTP methods and actions",
            "operationId" => "options_#{collection_name}",
            "tags"        => [collection[:description] || collection_name.to_s.titleize],
            "responses"   => {
              "200" => {
                "description" => "Success",
                "content"     => {
                  "application/json" => {
                    "schema" => {
                      "type"       => "object",
                      "properties" => {
                        "data" => {
                          "type"                 => "object",
                          "additionalProperties" => true
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        end
      end
    end
  end
end
