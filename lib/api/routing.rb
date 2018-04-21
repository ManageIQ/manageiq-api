module Api
  module Routing
    VERBS_ACTIONS_MAP = {
      :get     => "show",
      :post    => "update",
      :put     => "update",
      :patch   => "update",
      :delete  => "destroy",
      :options => "options"
    }.freeze

    # Generates plural and singular variants of the default collection_name
    #
    # Plural inflection is used on the root routes. e.g.: route => /containers, :as => "containers"
    # Singular inflection is used on the resource routes. e.g.: route => /containers/:id, :as => "container"
    #
    # !IMPORTANT!
    # One special case happens when singular and plural are the same. The API would not allow two routes
    # with the same name. This method generates a singular variant with preffix "one_" when this happens.
    # e.g.:
    #   route => /physical_chassis,     :as => "physical_chassis"
    #   route => /physical_chassis/:id, :as => "one_physical_chassis"
    #
    # @param [String] name - Default collection_name
    #
    # @return [String, String] plural, singular - Values of Plural and Singular inflections
    def self.inflections_for_named_route_helpers(name)
      plural   = name.pluralize
      singular = name.singularize

      if singular == plural
        singular = "one_#{singular}"
      end
      return plural, singular
    end
  end
end
