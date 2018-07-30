Rails.application.routes.draw do
  # Enablement for the REST API

  namespace :api, :path => "api(/:version)", :version => Api::VERSION_CONSTRAINT, :defaults => {:format => "json"} do
    root :to => "api#index", :as => :entrypoint
    match "/", :to => "api#options", :via => :options

    get "/ping" => "ping#index"

    Api::ApiConfig.collections.each do |collection_name, collection|
      # OPTIONS action for each collection
      controller = collection.controller
      controller ||= collection_name

      match collection_name.to_s, :controller => controller, :action => :options, :via => :options, :as => nil

      collection_name_pluralized, resource_name = Api::Routing.inflections_for_named_route_helpers(collection_name.to_s)

      scope collection_name, :controller => controller do
        collection.verbs.each do |verb|
          if collection.options.include?(:primary)
            case verb
            when :get
              root :action => Api::Routing::VERBS_ACTIONS_MAP[verb], :as => collection_name
            else
              root :action => Api::Routing::VERBS_ACTIONS_MAP[verb], :via => verb
            end
          end

          next unless collection.options.include?(:collection)

          if collection.options.include?(:arbitrary_resource_path)
            case verb
            when :get
              root :action => :index, :as => collection_name_pluralized
              get "/*c_suffix", :action => :show, :as => resource_name
            else
              match "(/*c_suffix)", :action => Api::Routing::VERBS_ACTIONS_MAP[verb], :via => verb
            end
          else
            case verb
            when :get
              root :action => :index, :as => collection_name
              get "/:c_id", :action => :show, :as => resource_name
            when :put
              put "/:c_id", :action => :update
            when :patch
              patch "/:c_id", :action => :update
            when :delete
              delete "/:c_id", :action => :destroy
            when :post
              post "/", :action => :create, :constraints => Api::CreateConstraint.new
              post "(/:c_id)", :action => :update
            end
          end
        end

        Array(collection.subcollections).each do |subcollection_name|
          if subcollection_name == :settings
            match(
              "/:c_id/settings",
              :to  => "#{collection_name}#settings",
              :via => %w(get patch delete),
              :as  => "#{resource_name}_settings",
            )
          else
            subcollection_name_pluralized, subresource_name = Api::Routing.inflections_for_named_route_helpers(subcollection_name.to_s)

            Api::ApiConfig.collections[subcollection_name].verbs.each do |verb|
              case verb
              when :get
                get "/:c_id/#{subcollection_name}", :action => :index, :as => "#{resource_name}_#{subcollection_name_pluralized}"
                get "/:c_id/#{subcollection_name}/:s_id", :action => :show, :as => "#{resource_name}_#{subresource_name}"
              when :put
                put "/:c_id/#{subcollection_name}/:s_id", :action => :update
              when :patch
                patch "/:c_id/#{subcollection_name}/:s_id", :action => :update
              when :delete
                delete "/:c_id/#{subcollection_name}/:s_id", :action => :destroy
              when :post
                post "/:c_id/#{subcollection_name}", :action => :create, :constraints => Api::CreateConstraint.new
                post "/:c_id/#{subcollection_name}(/:s_id)", :action => :update
              end
            end
          end
        end
      end
    end
  end
end
