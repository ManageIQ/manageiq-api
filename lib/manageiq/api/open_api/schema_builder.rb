module ManageIQ
  module Api
    module OpenApi
      module SchemaBuilder
        SCHEMAS_PATH = "/components/schemas".freeze

        def self.build_common_schemas
          {
            "CollectionMetadata" => {
              "type"       => "object",
              "properties" => {
                "name"     => {
                  "type"        => "string",
                  "description" => "Collection name"
                },
                "count"    => {
                  "type"        => "integer",
                  "description" => "Total count of resources"
                },
                "subcount" => {
                  "type"        => "integer",
                  "description" => "Count of resources in current page"
                },
                "pages"    => {
                  "type"        => "integer",
                  "description" => "Total number of pages"
                }
              }
            },
            "CollectionLinks"    => {
              "type"       => "object",
              "properties" => {
                "self"     => {
                  "type"        => "string",
                  "format"      => "uri",
                  "description" => "Link to current page"
                },
                "first"    => {
                  "type"        => "string",
                  "format"      => "uri",
                  "description" => "Link to first page"
                },
                "last"     => {
                  "type"        => "string",
                  "format"      => "uri",
                  "description" => "Link to last page"
                },
                "next"     => {
                  "type"        => "string",
                  "format"      => "uri",
                  "description" => "Link to next page"
                },
                "previous" => {
                  "type"        => "string",
                  "format"      => "uri",
                  "description" => "Link to previous page"
                }
              }
            },
            "Action"             => {
              "type"       => "object",
              "properties" => {
                "name"   => {
                  "type"        => "string",
                  "description" => "Action name"
                },
                "method" => {
                  "type"        => "string",
                  "enum"        => ["post", "put", "patch", "delete"],
                  "description" => "HTTP method for the action"
                },
                "href"   => {
                  "type"        => "string",
                  "format"      => "uri",
                  "description" => "URL to perform the action"
                }
              }
            },
            "Error"              => {
              "type"       => "object",
              "properties" => {
                "error" => {
                  "type"       => "object",
                  "properties" => {
                    "kind"    => {
                      "type"        => "string",
                      "description" => "Error type"
                    },
                    "message" => {
                      "type"        => "string",
                      "description" => "Error message"
                    },
                    "klass"   => {
                      "type"        => "string",
                      "description" => "Error class"
                    }
                  },
                  "required"   => ["kind", "message"]
                }
              },
              "required"   => ["error"]
            },
            "ValidationError"    => {
              "type"       => "object",
              "properties" => {
                "error" => {
                  "type"       => "object",
                  "properties" => {
                    "kind"    => {
                      "type"        => "string",
                      "description" => "Error type",
                      "example"     => "bad_request"
                    },
                    "message" => {
                      "type"        => "string",
                      "description" => "Error message"
                    },
                    "errors"  => {
                      "type"                 => "object",
                      "description"          => "Field-specific validation errors",
                      "additionalProperties" => {
                        "type"  => "array",
                        "items" => {
                          "type" => "string"
                        }
                      }
                    }
                  },
                  "required"   => ["kind", "message"]
                }
              },
              "required"   => ["error"]
            }
          }
        end

        def self.build_collection_response_schema(collection_name, model_schema_name)
          {
            "type"       => "object",
            "properties" => {
              "name"      => {
                "type"    => "string",
                "example" => collection_name
              },
              "count"     => {
                "type" => "integer"
              },
              "subcount"  => {
                "type" => "integer"
              },
              "pages"     => {
                "type" => "integer"
              },
              "resources" => {
                "type"  => "array",
                "items" => {
                  "$ref" => "#{SCHEMAS_PATH}/#{model_schema_name}"
                }
              },
              "actions"   => {
                "type"  => "array",
                "items" => {
                  "$ref" => "#{SCHEMAS_PATH}/Action"
                }
              },
              "links"     => {
                "$ref" => "#{SCHEMAS_PATH}/CollectionLinks"
              }
            }
          }
        end

        def self.build_resource_response_schema(model_schema_name)
          {
            "allOf" => [
              {"$ref" => "#{SCHEMAS_PATH}/#{model_schema_name}"},
              {
                "type"       => "object",
                "properties" => {
                  "href"    => {
                    "type"        => "string",
                    "format"      => "uri",
                    "description" => "Resource URL"
                  },
                  "actions" => {
                    "type"        => "array",
                    "description" => "Available actions for this resource",
                    "items"       => {
                      "$ref" => "#{SCHEMAS_PATH}/Action"
                    }
                  }
                }
              }
            ]
          }
        end

        def self.build_standard_responses
          {
            "200" => {
              "description" => "Success"
            },
            "201" => {
              "description" => "Created"
            },
            "204" => {
              "description" => "No Content"
            },
            "400" => {
              "description" => "Bad Request",
              "content"     => {
                "application/json" => {
                  "schema" => {
                    "$ref" => "#{SCHEMAS_PATH}/Error"
                  }
                }
              }
            },
            "401" => {
              "description" => "Unauthorized",
              "content"     => {
                "application/json" => {
                  "schema" => {
                    "$ref" => "#{SCHEMAS_PATH}/Error"
                  }
                }
              }
            },
            "403" => {
              "description" => "Forbidden",
              "content"     => {
                "application/json" => {
                  "schema" => {
                    "$ref" => "#{SCHEMAS_PATH}/Error"
                  }
                }
              }
            },
            "404" => {
              "description" => "Not Found",
              "content"     => {
                "application/json" => {
                  "schema" => {
                    "$ref" => "#{SCHEMAS_PATH}/Error"
                  }
                }
              }
            },
            "422" => {
              "description" => "Unprocessable Entity",
              "content"     => {
                "application/json" => {
                  "schema" => {
                    "$ref" => "#{SCHEMAS_PATH}/ValidationError"
                  }
                }
              }
            },
            "500" => {
              "description" => "Internal Server Error",
              "content"     => {
                "application/json" => {
                  "schema" => {
                    "$ref" => "#{SCHEMAS_PATH}/Error"
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
