Rails.application.routes.draw do
  # Enablement for the REST API

  namespace :api, :path => "api(/:version)", :version => Api::VERSION_CONSTRAINT, :defaults => {:format => "json"} do
    root :to => "api#index", :as => :entrypoint
    match "/", :to => "api#options", :via => :options

    get "/ping" => "ping#index"

    # /accounts
    match 'accounts', :controller => 'accounts', :action => :options, :via => :options, :as => nil

    # /actions
    match 'actions', :controller => 'actions', :action => :options, :via => :options, :as => nil
    scope 'actions', :controller => 'actions' do
      root :action => :index, :as => 'actions'
      get '/:c_id', :action => :show, :as => 'action'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /alert_actions
    match 'alert_actions', :controller => 'alert_actions', :action => :options, :via => :options, :as => nil

    # /alert_definition_profiles
    match 'alert_definition_profiles', :controller => 'alert_definition_profiles', :action => :options, :via => :options, :as => nil
    scope 'alert_definition_profiles', :controller => 'alert_definition_profiles' do
      root :action => :index, :as => 'alert_definition_profiles'
      get '/:c_id', :action => :show, :as => 'alert_definition_profile'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/alert_definitions', :action => :index, :as => 'alert_definition_profile_alert_definitions'
      get '/:c_id/alert_definitions/:s_id', :action => :show, :as => 'alert_definition_profile_alert_definition'
      post '/:c_id/alert_definitions', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/alert_definitions(/:s_id)', :action => :update
      delete '/:c_id/alert_definitions/:s_id', :action => :destroy
    end

    # /alert_definitions
    match 'alert_definitions', :controller => 'alert_definitions', :action => :options, :via => :options, :as => nil
    scope 'alert_definitions', :controller => 'alert_definitions' do
      root :action => :index, :as => 'alert_definitions'
      get '/:c_id', :action => :show, :as => 'alert_definition'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /alerts
    match 'alerts', :controller => 'alerts', :action => :options, :via => :options, :as => nil
    scope 'alerts', :controller => 'alerts' do
      root :action => :index, :as => 'alerts'
      get '/:c_id', :action => :show, :as => 'alert'

      get '/:c_id/alert_actions', :action => :index, :as => 'alert_alert_actions'
      get '/:c_id/alert_actions/:s_id', :action => :show, :as => 'alert_alert_action'
      post '/:c_id/alert_actions', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/alert_actions(/:s_id)', :action => :update
    end

    # /auth
    match 'auth', :controller => 'auth', :action => :options, :via => :options, :as => nil
    scope 'auth', :controller => 'auth' do
      root :action => 'show', :as => 'auth'
      root :action => 'destroy', :via => 'delete'
    end

    # /authentications
    match 'authentications', :controller => 'authentications', :action => :options, :via => :options, :as => nil
    scope 'authentications', :controller => 'authentications' do
      root :action => :index, :as => 'authentications'
      get '/:c_id', :action => :show, :as => 'authentication'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /automate
    match 'automate', :controller => 'automate', :action => :options, :via => :options, :as => nil
    scope 'automate', :controller => 'automate' do
      root :action => :index, :as => 'automates'
      get '/*c_suffix', :action => :show, :as => 'automate'
    end

    # /automate_domains
    match 'automate_domains', :controller => 'automate_domains', :action => :options, :via => :options, :as => nil
    scope 'automate_domains', :controller => 'automate_domains' do
      root :action => :index, :as => 'automate_domains'
      get '/:c_id', :action => :show, :as => 'automate_domain'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /automate_workspaces
    match 'automate_workspaces', :controller => 'automate_workspaces', :action => :options, :via => :options, :as => nil
    scope 'automate_workspaces', :controller => 'automate_workspaces' do
      root :action => :index, :as => 'automate_workspaces'
      get '/:c_id', :action => :show, :as => 'automate_workspace'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /automation_requests
    match 'automation_requests', :controller => 'automation_requests', :action => :options, :via => :options, :as => nil
    scope 'automation_requests', :controller => 'automation_requests' do
      root :action => :index, :as => 'automation_requests'
      get '/:c_id', :action => :show, :as => 'automation_request'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update

      get '/:c_id/request_tasks', :action => :index, :as => 'automation_request_request_tasks'
      get '/:c_id/request_tasks/:s_id', :action => :show, :as => 'automation_request_request_task'
      post '/:c_id/request_tasks', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/request_tasks(/:s_id)', :action => :update
    end

    # /availability_zones
    match 'availability_zones', :controller => 'availability_zones', :action => :options, :via => :options, :as => nil
    scope 'availability_zones', :controller => 'availability_zones' do
      root :action => :index, :as => 'availability_zones'
      get '/:c_id', :action => :show, :as => 'availability_zone'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /categories
    match 'categories', :controller => 'categories', :action => :options, :via => :options, :as => nil
    scope 'categories', :controller => 'categories' do
      root :action => :index, :as => 'categories'
      get '/:c_id', :action => :show, :as => 'category'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/tags', :action => :index, :as => 'category_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'category_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy
    end

    # /chargebacks
    match 'chargebacks', :controller => 'chargebacks', :action => :options, :via => :options, :as => nil
    scope 'chargebacks', :controller => 'chargebacks' do
      root :action => :index, :as => 'chargebacks'
      get '/:c_id', :action => :show, :as => 'chargeback'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/rates', :action => :index, :as => 'chargeback_rates'
      get '/:c_id/rates/:s_id', :action => :show, :as => 'chargeback_rate'
      put '/:c_id/rates/:s_id', :action => :update
      post '/:c_id/rates', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/rates(/:s_id)', :action => :update
      patch '/:c_id/rates/:s_id', :action => :update
      delete '/:c_id/rates/:s_id', :action => :destroy
    end

    # /cloud_networks
    match 'cloud_networks', :controller => 'cloud_networks', :action => :options, :via => :options, :as => nil
    scope 'cloud_networks', :controller => 'cloud_networks' do
      root :action => :index, :as => 'cloud_networks'
      get '/:c_id', :action => :show, :as => 'cloud_network'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /cloud_subnets
    match 'cloud_subnets', :controller => 'cloud_subnets', :action => :options, :via => :options, :as => nil
    scope 'cloud_subnets', :controller => 'cloud_subnets' do
      root :action => :index, :as => 'cloud_subnets'
      get '/:c_id', :action => :show, :as => 'cloud_subnet'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /cloud_templates
    match 'cloud_templates', :controller => 'cloud_templates', :action => :options, :via => :options, :as => nil
    scope 'cloud_templates', :controller => 'cloud_templates' do
      root :action => :index, :as => 'cloud_templates'
      get '/:c_id', :action => :show, :as => 'cloud_template'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /cloud_tenants
    match 'cloud_tenants', :controller => 'cloud_tenants', :action => :options, :via => :options, :as => nil
    scope 'cloud_tenants', :controller => 'cloud_tenants' do
      root :action => :index, :as => 'cloud_tenants'
      get '/:c_id', :action => :show, :as => 'cloud_tenant'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update

      get '/:c_id/security_groups', :action => :index, :as => 'cloud_tenant_security_groups'
      get '/:c_id/security_groups/:s_id', :action => :show, :as => 'cloud_tenant_security_group'
      post '/:c_id/security_groups', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/security_groups(/:s_id)', :action => :update
    end

    # /cloud_volumes
    match 'cloud_volumes', :controller => 'cloud_volumes', :action => :options, :via => :options, :as => nil
    scope 'cloud_volumes', :controller => 'cloud_volumes' do
      root :action => :index, :as => 'cloud_volumes'
      get '/:c_id', :action => :show, :as => 'cloud_volume'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /clusters
    match 'clusters', :controller => 'clusters', :action => :options, :via => :options, :as => nil
    scope 'clusters', :controller => 'clusters' do
      root :action => :index, :as => 'clusters'
      get '/:c_id', :action => :show, :as => 'cluster'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update

      get '/:c_id/tags', :action => :index, :as => 'cluster_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'cluster_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy

      get '/:c_id/policies', :action => :index, :as => 'cluster_policies'
      get '/:c_id/policies/:s_id', :action => :show, :as => 'cluster_policy'
      post '/:c_id/policies', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policies(/:s_id)', :action => :update
      delete '/:c_id/policies/:s_id', :action => :destroy

      get '/:c_id/policy_profiles', :action => :index, :as => 'cluster_policy_profiles'
      get '/:c_id/policy_profiles/:s_id', :action => :show, :as => 'cluster_policy_profile'
      post '/:c_id/policy_profiles', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policy_profiles(/:s_id)', :action => :update
    end

    # /conditions
    match 'conditions', :controller => 'conditions', :action => :options, :via => :options, :as => nil
    scope 'conditions', :controller => 'conditions' do
      root :action => :index, :as => 'conditions'
      get '/:c_id', :action => :show, :as => 'condition'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /configuration_script_payloads
    match 'configuration_script_payloads', :controller => 'configuration_script_payloads', :action => :options, :via => :options, :as => nil
    scope 'configuration_script_payloads', :controller => 'configuration_script_payloads' do
      root :action => :index, :as => 'configuration_script_payloads'
      get '/:c_id', :action => :show, :as => 'configuration_script_payload'

      get '/:c_id/authentications', :action => :index, :as => 'configuration_script_payload_authentications'
      get '/:c_id/authentications/:s_id', :action => :show, :as => 'configuration_script_payload_authentication'
      put '/:c_id/authentications/:s_id', :action => :update
      post '/:c_id/authentications', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/authentications(/:s_id)', :action => :update
      patch '/:c_id/authentications/:s_id', :action => :update
      delete '/:c_id/authentications/:s_id', :action => :destroy
    end

    # /configuration_script_sources
    match 'configuration_script_sources', :controller => 'configuration_script_sources', :action => :options, :via => :options, :as => nil
    scope 'configuration_script_sources', :controller => 'configuration_script_sources' do
      root :action => :index, :as => 'configuration_script_sources'
      get '/:c_id', :action => :show, :as => 'configuration_script_source'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/configuration_script_payloads', :action => :index, :as => 'configuration_script_source_configuration_script_payloads'
      get '/:c_id/configuration_script_payloads/:s_id', :action => :show, :as => 'configuration_script_source_configuration_script_payload'
    end

    # /container_deployments
    match 'container_deployments', :controller => 'container_deployments', :action => :options, :via => :options, :as => nil
    scope 'container_deployments', :controller => 'container_deployments' do
      root :action => :index, :as => 'container_deployments'
      get '/:c_id', :action => :show, :as => 'container_deployment'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /container_nodes
    match 'container_nodes', :controller => 'container_nodes', :action => :options, :via => :options, :as => nil
    scope 'container_nodes', :controller => 'container_nodes' do
      root :action => :index, :as => 'container_nodes'
      get '/:c_id', :action => :show, :as => 'container_node'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /currencies
    match 'currencies', :controller => 'currencies', :action => :options, :via => :options, :as => nil
    scope 'currencies', :controller => 'currencies' do
      root :action => :index, :as => 'currencies'
      get '/:c_id', :action => :show, :as => 'currency'
    end

    # /custom_attributes
    match 'custom_attributes', :controller => 'custom_attributes', :action => :options, :via => :options, :as => nil

    # /custom_button_sets
    match 'custom_button_sets', :controller => 'custom_button_sets', :action => :options, :via => :options, :as => nil
    scope 'custom_button_sets', :controller => 'custom_button_sets' do
      root :action => :index, :as => 'custom_button_sets'
      get '/:c_id', :action => :show, :as => 'custom_button_set'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /custom_buttons
    match 'custom_buttons', :controller => 'custom_buttons', :action => :options, :via => :options, :as => nil
    scope 'custom_buttons', :controller => 'custom_buttons' do
      root :action => :index, :as => 'custom_buttons'
      get '/:c_id', :action => :show, :as => 'custom_button'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /data_stores
    match 'data_stores', :controller => 'data_stores', :action => :options, :via => :options, :as => nil
    scope 'data_stores', :controller => 'data_stores' do
      root :action => :index, :as => 'data_stores'
      get '/:c_id', :action => :show, :as => 'data_store'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update

      get '/:c_id/tags', :action => :index, :as => 'data_store_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'data_store_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy
    end

    # /event_streams
    match 'event_streams', :controller => 'event_streams', :action => :options, :via => :options, :as => nil
    scope 'event_streams', :controller => 'event_streams' do
      root :action => :index, :as => 'event_streams'
      get '/:c_id', :action => :show, :as => 'event_stream'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /events
    match 'events', :controller => 'events', :action => :options, :via => :options, :as => nil
    scope 'events', :controller => 'events' do
      root :action => :index, :as => 'events'
      get '/:c_id', :action => :show, :as => 'event'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /features
    match 'features', :controller => 'features', :action => :options, :via => :options, :as => nil
    scope 'features', :controller => 'features' do
      root :action => :index, :as => 'features'
      get '/:c_id', :action => :show, :as => 'feature'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /firmwares
    match 'firmwares', :controller => 'firmwares', :action => :options, :via => :options, :as => nil
    scope 'firmwares', :controller => 'firmwares' do
      root :action => :index, :as => 'firmwares'
      get '/:c_id', :action => :show, :as => 'firmware'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /flavors
    match 'flavors', :controller => 'flavors', :action => :options, :via => :options, :as => nil
    scope 'flavors', :controller => 'flavors' do
      root :action => :index, :as => 'flavors'
      get '/:c_id', :action => :show, :as => 'flavor'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /floating_ips
    match 'floating_ips', :controller => 'floating_ips', :action => :options, :via => :options, :as => nil
    scope 'floating_ips', :controller => 'floating_ips' do
      root :action => :index, :as => 'floating_ips'
      get '/:c_id', :action => :show, :as => 'floating_ip'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /generic_object_definitions
    match 'generic_object_definitions', :controller => 'generic_object_definitions', :action => :options, :via => :options, :as => nil
    scope 'generic_object_definitions', :controller => 'generic_object_definitions' do
      root :action => :index, :as => 'generic_object_definitions'
      get '/:c_id', :action => :show, :as => 'generic_object_definition'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/generic_objects', :action => :index, :as => 'generic_object_definition_generic_objects'
      get '/:c_id/generic_objects/:s_id', :action => :show, :as => 'generic_object_definition_generic_object'
      post '/:c_id/generic_objects', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/generic_objects(/:s_id)', :action => :update
      delete '/:c_id/generic_objects/:s_id', :action => :destroy
    end

    # /generic_objects
    match 'generic_objects', :controller => 'generic_objects', :action => :options, :via => :options, :as => nil
    scope 'generic_objects', :controller => 'generic_objects' do
      root :action => :index, :as => 'generic_objects'
      get '/:c_id', :action => :show, :as => 'generic_object'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/tags', :action => :index, :as => 'generic_object_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'generic_object_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy
    end

    # /groups
    match 'groups', :controller => 'groups', :action => :options, :via => :options, :as => nil
    scope 'groups', :controller => 'groups' do
      root :action => :index, :as => 'groups'
      get '/:c_id', :action => :show, :as => 'group'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/tags', :action => :index, :as => 'group_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'group_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy
    end

    # /guest_devices
    match 'guest_devices', :controller => 'guest_devices', :action => :options, :via => :options, :as => nil
    scope 'guest_devices', :controller => 'guest_devices' do
      root :action => :index, :as => 'guest_devices'
      get '/:c_id', :action => :show, :as => 'guest_device'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /hosts
    match 'hosts', :controller => 'hosts', :action => :options, :via => :options, :as => nil
    scope 'hosts', :controller => 'hosts' do
      root :action => :index, :as => 'hosts'
      get '/:c_id', :action => :show, :as => 'host'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update

      get '/:c_id/tags', :action => :index, :as => 'host_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'host_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy

      get '/:c_id/policies', :action => :index, :as => 'host_policies'
      get '/:c_id/policies/:s_id', :action => :show, :as => 'host_policy'
      post '/:c_id/policies', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policies(/:s_id)', :action => :update
      delete '/:c_id/policies/:s_id', :action => :destroy

      get '/:c_id/policy_profiles', :action => :index, :as => 'host_policy_profiles'
      get '/:c_id/policy_profiles/:s_id', :action => :show, :as => 'host_policy_profile'
      post '/:c_id/policy_profiles', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policy_profiles(/:s_id)', :action => :update
    end

    # /instances
    match 'instances', :controller => 'instances', :action => :options, :via => :options, :as => nil
    scope 'instances', :controller => 'instances' do
      root :action => :index, :as => 'instances'
      get '/:c_id', :action => :show, :as => 'instance'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update

      get '/:c_id/custom_attributes', :action => :index, :as => 'instance_custom_attributes'
      get '/:c_id/custom_attributes/:s_id', :action => :show, :as => 'instance_custom_attribute'
      post '/:c_id/custom_attributes', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/custom_attributes(/:s_id)', :action => :update
      delete '/:c_id/custom_attributes/:s_id', :action => :destroy

      get '/:c_id/load_balancers', :action => :index, :as => 'instance_load_balancers'
      get '/:c_id/load_balancers/:s_id', :action => :show, :as => 'instance_load_balancer'
      post '/:c_id/load_balancers', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/load_balancers(/:s_id)', :action => :update

      get '/:c_id/security_groups', :action => :index, :as => 'instance_security_groups'
      get '/:c_id/security_groups/:s_id', :action => :show, :as => 'instance_security_group'
      post '/:c_id/security_groups', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/security_groups(/:s_id)', :action => :update

      get '/:c_id/snapshots', :action => :index, :as => 'instance_snapshots'
      get '/:c_id/snapshots/:s_id', :action => :show, :as => 'instance_snapshot'
      post '/:c_id/snapshots', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/snapshots(/:s_id)', :action => :update
      delete '/:c_id/snapshots/:s_id', :action => :destroy
    end

    # /load_balancers
    match 'load_balancers', :controller => 'load_balancers', :action => :options, :via => :options, :as => nil
    scope 'load_balancers', :controller => 'load_balancers' do
      root :action => :index, :as => 'load_balancers'
      get '/:c_id', :action => :show, :as => 'load_balancer'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /measures
    match 'measures', :controller => 'measures', :action => :options, :via => :options, :as => nil
    scope 'measures', :controller => 'measures' do
      root :action => :index, :as => 'measures'
      get '/:c_id', :action => :show, :as => 'measure'
    end

    # /metric_rollups
    match 'metric_rollups', :controller => 'metric_rollups', :action => :options, :via => :options, :as => nil
    scope 'metric_rollups', :controller => 'metric_rollups' do
      root :action => :index, :as => 'metric_rollups'
      get '/:c_id', :action => :show, :as => 'metric_rollup'
    end

    # /middleware_datasources
    match 'middleware_datasources', :controller => 'middleware_datasources', :action => :options, :via => :options, :as => nil
    scope 'middleware_datasources', :controller => 'middleware_datasources' do
      root :action => :index, :as => 'middleware_datasources'
      get '/:c_id', :action => :show, :as => 'middleware_datasource'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /middleware_deployments
    match 'middleware_deployments', :controller => 'middleware_deployments', :action => :options, :via => :options, :as => nil
    scope 'middleware_deployments', :controller => 'middleware_deployments' do
      root :action => :index, :as => 'middleware_deployments'
      get '/:c_id', :action => :show, :as => 'middleware_deployment'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /middleware_domains
    match 'middleware_domains', :controller => 'middleware_domains', :action => :options, :via => :options, :as => nil
    scope 'middleware_domains', :controller => 'middleware_domains' do
      root :action => :index, :as => 'middleware_domains'
      get '/:c_id', :action => :show, :as => 'middleware_domain'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /middleware_messagings
    match 'middleware_messagings', :controller => 'middleware_messagings', :action => :options, :via => :options, :as => nil
    scope 'middleware_messagings', :controller => 'middleware_messagings' do
      root :action => :index, :as => 'middleware_messagings'
      get '/:c_id', :action => :show, :as => 'middleware_messaging'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /middleware_servers
    match 'middleware_servers', :controller => 'middleware_servers', :action => :options, :via => :options, :as => nil
    scope 'middleware_servers', :controller => 'middleware_servers' do
      root :action => :index, :as => 'middleware_servers'
      get '/:c_id', :action => :show, :as => 'middleware_server'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /network_routers
    match 'network_routers', :controller => 'network_routers', :action => :options, :via => :options, :as => nil
    scope 'network_routers', :controller => 'network_routers' do
      root :action => :index, :as => 'network_routers'
      get '/:c_id', :action => :show, :as => 'network_router'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /notifications
    match 'notifications', :controller => 'notifications', :action => :options, :via => :options, :as => nil
    scope 'notifications', :controller => 'notifications' do
      root :action => :index, :as => 'notifications'
      get '/:c_id', :action => :show, :as => 'notification'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /orchestration_stacks
    match 'orchestration_stacks', :controller => 'orchestration_stacks', :action => :options, :via => :options, :as => nil

    # /orchestration_templates
    match 'orchestration_templates', :controller => 'orchestration_templates', :action => :options, :via => :options, :as => nil
    scope 'orchestration_templates', :controller => 'orchestration_templates' do
      root :action => :index, :as => 'orchestration_templates'
      get '/:c_id', :action => :show, :as => 'orchestration_template'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /physical_servers
    match 'physical_servers', :controller => 'physical_servers', :action => :options, :via => :options, :as => nil
    scope 'physical_servers', :controller => 'physical_servers' do
      root :action => :index, :as => 'physical_servers'
      get '/:c_id', :action => :show, :as => 'physical_server'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /pictures
    match 'pictures', :controller => 'pictures', :action => :options, :via => :options, :as => nil
    scope 'pictures', :controller => 'pictures' do
      root :action => :index, :as => 'pictures'
      get '/:c_id', :action => :show, :as => 'picture'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /policies
    match 'policies', :controller => 'policies', :action => :options, :via => :options, :as => nil
    scope 'policies', :controller => 'policies' do
      root :action => :index, :as => 'policies'
      get '/:c_id', :action => :show, :as => 'policy'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/conditions', :action => :index, :as => 'policy_conditions'
      get '/:c_id/conditions/:s_id', :action => :show, :as => 'policy_condition'
      post '/:c_id/conditions', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/conditions(/:s_id)', :action => :update
      delete '/:c_id/conditions/:s_id', :action => :destroy

      get '/:c_id/policy_actions', :action => :index, :as => 'policy_policy_actions'
      get '/:c_id/policy_actions/:s_id', :action => :show, :as => 'policy_policy_action'
      post '/:c_id/policy_actions', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policy_actions(/:s_id)', :action => :update

      get '/:c_id/events', :action => :index, :as => 'policy_events'
      get '/:c_id/events/:s_id', :action => :show, :as => 'policy_event'
      post '/:c_id/events', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/events(/:s_id)', :action => :update
    end

    # /policy_actions
    match 'policy_actions', :controller => 'policy_actions', :action => :options, :via => :options, :as => nil
    scope 'policy_actions', :controller => 'policy_actions' do
      root :action => :index, :as => 'policy_actions'
      get '/:c_id', :action => :show, :as => 'policy_action'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /policy_profiles
    match 'policy_profiles', :controller => 'policy_profiles', :action => :options, :via => :options, :as => nil
    scope 'policy_profiles', :controller => 'policy_profiles' do
      root :action => :index, :as => 'policy_profiles'
      get '/:c_id', :action => :show, :as => 'policy_profile'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update

      get '/:c_id/policies', :action => :index, :as => 'policy_profile_policies'
      get '/:c_id/policies/:s_id', :action => :show, :as => 'policy_profile_policy'
      post '/:c_id/policies', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policies(/:s_id)', :action => :update
      delete '/:c_id/policies/:s_id', :action => :destroy
    end

    # /providers
    match 'providers', :controller => 'providers', :action => :options, :via => :options, :as => nil
    scope 'providers', :controller => 'providers' do
      root :action => :index, :as => 'providers'
      get '/:c_id', :action => :show, :as => 'provider'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/tags', :action => :index, :as => 'provider_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'provider_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy

      get '/:c_id/policies', :action => :index, :as => 'provider_policies'
      get '/:c_id/policies/:s_id', :action => :show, :as => 'provider_policy'
      post '/:c_id/policies', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policies(/:s_id)', :action => :update
      delete '/:c_id/policies/:s_id', :action => :destroy

      get '/:c_id/policy_profiles', :action => :index, :as => 'provider_policy_profiles'
      get '/:c_id/policy_profiles/:s_id', :action => :show, :as => 'provider_policy_profile'
      post '/:c_id/policy_profiles', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policy_profiles(/:s_id)', :action => :update

      get '/:c_id/cloud_networks', :action => :index, :as => 'provider_cloud_networks'
      get '/:c_id/cloud_networks/:s_id', :action => :show, :as => 'provider_cloud_network'
      post '/:c_id/cloud_networks', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/cloud_networks(/:s_id)', :action => :update

      get '/:c_id/cloud_subnets', :action => :index, :as => 'provider_cloud_subnets'
      get '/:c_id/cloud_subnets/:s_id', :action => :show, :as => 'provider_cloud_subnet'
      post '/:c_id/cloud_subnets', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/cloud_subnets(/:s_id)', :action => :update

      get '/:c_id/cloud_tenants', :action => :index, :as => 'provider_cloud_tenants'
      get '/:c_id/cloud_tenants/:s_id', :action => :show, :as => 'provider_cloud_tenant'
      post '/:c_id/cloud_tenants', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/cloud_tenants(/:s_id)', :action => :update

      get '/:c_id/custom_attributes', :action => :index, :as => 'provider_custom_attributes'
      get '/:c_id/custom_attributes/:s_id', :action => :show, :as => 'provider_custom_attribute'
      post '/:c_id/custom_attributes', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/custom_attributes(/:s_id)', :action => :update
      delete '/:c_id/custom_attributes/:s_id', :action => :destroy

      get '/:c_id/load_balancers', :action => :index, :as => 'provider_load_balancers'
      get '/:c_id/load_balancers/:s_id', :action => :show, :as => 'provider_load_balancer'
      post '/:c_id/load_balancers', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/load_balancers(/:s_id)', :action => :update

      get '/:c_id/security_groups', :action => :index, :as => 'provider_security_groups'
      get '/:c_id/security_groups/:s_id', :action => :show, :as => 'provider_security_group'
      post '/:c_id/security_groups', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/security_groups(/:s_id)', :action => :update

      get '/:c_id/vms', :action => :index, :as => 'provider_vms'
      get '/:c_id/vms/:s_id', :action => :show, :as => 'provider_vm'
      post '/:c_id/vms', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/vms(/:s_id)', :action => :update
      delete '/:c_id/vms/:s_id', :action => :destroy

      get '/:c_id/flavors', :action => :index, :as => 'provider_flavors'
      get '/:c_id/flavors/:s_id', :action => :show, :as => 'provider_flavor'
      post '/:c_id/flavors', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/flavors(/:s_id)', :action => :update
      delete '/:c_id/flavors/:s_id', :action => :destroy

      get '/:c_id/cloud_templates', :action => :index, :as => 'provider_cloud_templates'
      get '/:c_id/cloud_templates/:s_id', :action => :show, :as => 'provider_cloud_template'
      post '/:c_id/cloud_templates', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/cloud_templates(/:s_id)', :action => :update
    end

    # /provision_dialogs
    match 'provision_dialogs', :controller => 'provision_dialogs', :action => :options, :via => :options, :as => nil
    scope 'provision_dialogs', :controller => 'provision_dialogs' do
      root :action => :index, :as => 'provision_dialogs'
      get '/:c_id', :action => :show, :as => 'provision_dialog'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /provision_requests
    match 'provision_requests', :controller => 'provision_requests', :action => :options, :via => :options, :as => nil
    scope 'provision_requests', :controller => 'provision_requests' do
      root :action => :index, :as => 'provision_requests'
      get '/:c_id', :action => :show, :as => 'provision_request'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update

      get '/:c_id/request_tasks', :action => :index, :as => 'provision_request_request_tasks'
      get '/:c_id/request_tasks/:s_id', :action => :show, :as => 'provision_request_request_task'
      post '/:c_id/request_tasks', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/request_tasks(/:s_id)', :action => :update
    end

    # /quotas
    match 'quotas', :controller => 'quotas', :action => :options, :via => :options, :as => nil

    # /rates
    match 'rates', :controller => 'rates', :action => :options, :via => :options, :as => nil
    scope 'rates', :controller => 'rates' do
      root :action => :index, :as => 'rates'
      get '/:c_id', :action => :show, :as => 'rate'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /regions
    match 'regions', :controller => 'regions', :action => :options, :via => :options, :as => nil
    scope 'regions', :controller => 'regions' do
      root :action => :index, :as => 'regions'
      get '/:c_id', :action => :show, :as => 'region'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /reports
    match 'reports', :controller => 'reports', :action => :options, :via => :options, :as => nil
    scope 'reports', :controller => 'reports' do
      root :action => :index, :as => 'reports'
      get '/:c_id', :action => :show, :as => 'report'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update

      get '/:c_id/results', :action => :index, :as => 'report_results'
      get '/:c_id/results/:s_id', :action => :show, :as => 'report_result'
      post '/:c_id/results', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/results(/:s_id)', :action => :update

      get '/:c_id/schedules', :action => :index, :as => 'report_schedules'
      get '/:c_id/schedules/:s_id', :action => :show, :as => 'report_schedule'
      post '/:c_id/schedules', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/schedules(/:s_id)', :action => :update
    end

    # /request_tasks
    match 'request_tasks', :controller => 'request_tasks', :action => :options, :via => :options, :as => nil
    scope 'request_tasks', :controller => 'request_tasks' do
      root :action => :index, :as => 'request_tasks'
      get '/:c_id', :action => :show, :as => 'request_task'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /requests
    match 'requests', :controller => 'requests', :action => :options, :via => :options, :as => nil
    scope 'requests', :controller => 'requests' do
      root :action => :index, :as => 'requests'
      get '/:c_id', :action => :show, :as => 'request'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update

      get '/:c_id/request_tasks', :action => :index, :as => 'request_request_tasks'
      get '/:c_id/request_tasks/:s_id', :action => :show, :as => 'request_request_task'
      post '/:c_id/request_tasks', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/request_tasks(/:s_id)', :action => :update
    end

    # /resource_actions
    match 'resource_actions', :controller => 'resource_actions', :action => :options, :via => :options, :as => nil

    # /resource_pools
    match 'resource_pools', :controller => 'resource_pools', :action => :options, :via => :options, :as => nil
    scope 'resource_pools', :controller => 'resource_pools' do
      root :action => :index, :as => 'resource_pools'
      get '/:c_id', :action => :show, :as => 'resource_pool'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update

      get '/:c_id/tags', :action => :index, :as => 'resource_pool_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'resource_pool_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy

      get '/:c_id/policies', :action => :index, :as => 'resource_pool_policies'
      get '/:c_id/policies/:s_id', :action => :show, :as => 'resource_pool_policy'
      post '/:c_id/policies', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policies(/:s_id)', :action => :update
      delete '/:c_id/policies/:s_id', :action => :destroy

      get '/:c_id/policy_profiles', :action => :index, :as => 'resource_pool_policy_profiles'
      get '/:c_id/policy_profiles/:s_id', :action => :show, :as => 'resource_pool_policy_profile'
      post '/:c_id/policy_profiles', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policy_profiles(/:s_id)', :action => :update
    end

    # /results
    match 'results', :controller => 'results', :action => :options, :via => :options, :as => nil
    scope 'results', :controller => 'results' do
      root :action => :index, :as => 'results'
      get '/:c_id', :action => :show, :as => 'result'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /roles
    match 'roles', :controller => 'roles', :action => :options, :via => :options, :as => nil
    scope 'roles', :controller => 'roles' do
      root :action => :index, :as => 'roles'
      get '/:c_id', :action => :show, :as => 'role'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/features', :action => :index, :as => 'role_features'
      get '/:c_id/features/:s_id', :action => :show, :as => 'role_feature'
      post '/:c_id/features', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/features(/:s_id)', :action => :update
    end

    # /schedules
    match 'schedules', :controller => 'schedules', :action => :options, :via => :options, :as => nil

    # /security_groups
    match 'security_groups', :controller => 'security_groups', :action => :options, :via => :options, :as => nil
    scope 'security_groups', :controller => 'security_groups' do
      root :action => :index, :as => 'security_groups'
      get '/:c_id', :action => :show, :as => 'security_group'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /servers
    match 'servers', :controller => 'servers', :action => :options, :via => :options, :as => nil
    scope 'servers', :controller => 'servers' do
      root :action => :index, :as => 'servers'
      get '/:c_id', :action => :show, :as => 'server'
    end

    # /service_catalogs
    match 'service_catalogs', :controller => 'service_catalogs', :action => :options, :via => :options, :as => nil
    scope 'service_catalogs', :controller => 'service_catalogs' do
      root :action => :index, :as => 'service_catalogs'
      get '/:c_id', :action => :show, :as => 'service_catalog'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/service_templates', :action => :index, :as => 'service_catalog_service_templates'
      get '/:c_id/service_templates/:s_id', :action => :show, :as => 'service_catalog_service_template'
      put '/:c_id/service_templates/:s_id', :action => :update
      post '/:c_id/service_templates', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/service_templates(/:s_id)', :action => :update
      patch '/:c_id/service_templates/:s_id', :action => :update
      delete '/:c_id/service_templates/:s_id', :action => :destroy
    end

    # /service_dialogs
    match 'service_dialogs', :controller => 'service_dialogs', :action => :options, :via => :options, :as => nil
    scope 'service_dialogs', :controller => 'service_dialogs' do
      root :action => :index, :as => 'service_dialogs'
      get '/:c_id', :action => :show, :as => 'service_dialog'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /service_orders
    match 'service_orders', :controller => 'service_orders', :action => :options, :via => :options, :as => nil
    scope 'service_orders', :controller => 'service_orders' do
      root :action => :index, :as => 'service_orders'
      get '/:c_id', :action => :show, :as => 'service_order'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/service_requests', :action => :index, :as => 'service_order_service_requests'
      get '/:c_id/service_requests/:s_id', :action => :show, :as => 'service_order_service_request'
      post '/:c_id/service_requests', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/service_requests(/:s_id)', :action => :update
      delete '/:c_id/service_requests/:s_id', :action => :destroy
    end

    # /service_requests
    match 'service_requests', :controller => 'service_requests', :action => :options, :via => :options, :as => nil
    scope 'service_requests', :controller => 'service_requests' do
      root :action => :index, :as => 'service_requests'
      get '/:c_id', :action => :show, :as => 'service_request'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/request_tasks', :action => :index, :as => 'service_request_request_tasks'
      get '/:c_id/request_tasks/:s_id', :action => :show, :as => 'service_request_request_task'
      post '/:c_id/request_tasks', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/request_tasks(/:s_id)', :action => :update
    end

    # /service_templates
    match 'service_templates', :controller => 'service_templates', :action => :options, :via => :options, :as => nil
    scope 'service_templates', :controller => 'service_templates' do
      root :action => :index, :as => 'service_templates'
      get '/:c_id', :action => :show, :as => 'service_template'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/resource_actions', :action => :index, :as => 'service_template_resource_actions'
      get '/:c_id/resource_actions/:s_id', :action => :show, :as => 'service_template_resource_action'

      get '/:c_id/tags', :action => :index, :as => 'service_template_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'service_template_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy

      get '/:c_id/service_requests', :action => :index, :as => 'service_template_service_requests'
      get '/:c_id/service_requests/:s_id', :action => :show, :as => 'service_template_service_request'
      post '/:c_id/service_requests', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/service_requests(/:s_id)', :action => :update
      delete '/:c_id/service_requests/:s_id', :action => :destroy

      get '/:c_id/service_dialogs', :action => :index, :as => 'service_template_service_dialogs'
      get '/:c_id/service_dialogs/:s_id', :action => :show, :as => 'service_template_service_dialog'
      post '/:c_id/service_dialogs', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/service_dialogs(/:s_id)', :action => :update
      delete '/:c_id/service_dialogs/:s_id', :action => :destroy
    end

    # /services
    match 'services', :controller => 'services', :action => :options, :via => :options, :as => nil
    scope 'services', :controller => 'services' do
      root :action => :index, :as => 'services'
      get '/:c_id', :action => :show, :as => 'service'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/tags', :action => :index, :as => 'service_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'service_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy

      get '/:c_id/service_dialogs', :action => :index, :as => 'service_service_dialogs'
      get '/:c_id/service_dialogs/:s_id', :action => :show, :as => 'service_service_dialog'
      post '/:c_id/service_dialogs', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/service_dialogs(/:s_id)', :action => :update
      delete '/:c_id/service_dialogs/:s_id', :action => :destroy

      get '/:c_id/vms', :action => :index, :as => 'service_vms'
      get '/:c_id/vms/:s_id', :action => :show, :as => 'service_vm'
      post '/:c_id/vms', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/vms(/:s_id)', :action => :update
      delete '/:c_id/vms/:s_id', :action => :destroy

      get '/:c_id/orchestration_stacks', :action => :index, :as => 'service_orchestration_stacks'
      get '/:c_id/orchestration_stacks/:s_id', :action => :show, :as => 'service_orchestration_stack'

      get '/:c_id/metric_rollups', :action => :index, :as => 'service_metric_rollups'
      get '/:c_id/metric_rollups/:s_id', :action => :show, :as => 'service_metric_rollup'

      get '/:c_id/generic_objects', :action => :index, :as => 'service_generic_objects'
      get '/:c_id/generic_objects/:s_id', :action => :show, :as => 'service_generic_object'
      post '/:c_id/generic_objects', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/generic_objects(/:s_id)', :action => :update
      delete '/:c_id/generic_objects/:s_id', :action => :destroy

      get '/:c_id/custom_attributes', :action => :index, :as => 'service_custom_attributes'
      get '/:c_id/custom_attributes/:s_id', :action => :show, :as => 'service_custom_attribute'
      post '/:c_id/custom_attributes', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/custom_attributes(/:s_id)', :action => :update
      delete '/:c_id/custom_attributes/:s_id', :action => :destroy
    end

    # /settings
    match 'settings', :controller => 'settings', :action => :options, :via => :options, :as => nil
    scope 'settings', :controller => 'settings' do
      root :action => :index, :as => 'settings'
      get '/*c_suffix', :action => :show, :as => 'setting'
    end

    # /snapshots
    match 'snapshots', :controller => 'snapshots', :action => :options, :via => :options, :as => nil

    # /software
    match 'software', :controller => 'software', :action => :options, :via => :options, :as => nil

    # /tags
    match 'tags', :controller => 'tags', :action => :options, :via => :options, :as => nil
    scope 'tags', :controller => 'tags' do
      root :action => :index, :as => 'tags'
      get '/:c_id', :action => :show, :as => 'tag'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy
    end

    # /tasks
    match 'tasks', :controller => 'tasks', :action => :options, :via => :options, :as => nil
    scope 'tasks', :controller => 'tasks' do
      root :action => :index, :as => 'tasks'
      get '/:c_id', :action => :show, :as => 'task'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end

    # /templates
    match 'templates', :controller => 'templates', :action => :options, :via => :options, :as => nil
    scope 'templates', :controller => 'templates' do
      root :action => :index, :as => 'templates'
      get '/:c_id', :action => :show, :as => 'template'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/tags', :action => :index, :as => 'template_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'template_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy

      get '/:c_id/policies', :action => :index, :as => 'template_policies'
      get '/:c_id/policies/:s_id', :action => :show, :as => 'template_policy'
      post '/:c_id/policies', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policies(/:s_id)', :action => :update
      delete '/:c_id/policies/:s_id', :action => :destroy

      get '/:c_id/policy_profiles', :action => :index, :as => 'template_policy_profiles'
      get '/:c_id/policy_profiles/:s_id', :action => :show, :as => 'template_policy_profile'
      post '/:c_id/policy_profiles', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policy_profiles(/:s_id)', :action => :update
    end

    # /tenants
    match 'tenants', :controller => 'tenants', :action => :options, :via => :options, :as => nil
    scope 'tenants', :controller => 'tenants' do
      root :action => :index, :as => 'tenants'
      get '/:c_id', :action => :show, :as => 'tenant'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/tags', :action => :index, :as => 'tenant_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'tenant_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy

      get '/:c_id/quotas', :action => :index, :as => 'tenant_quotas'
      get '/:c_id/quotas/:s_id', :action => :show, :as => 'tenant_quota'
      put '/:c_id/quotas/:s_id', :action => :update
      post '/:c_id/quotas', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/quotas(/:s_id)', :action => :update
      patch '/:c_id/quotas/:s_id', :action => :update
      delete '/:c_id/quotas/:s_id', :action => :destroy
    end

    # /users
    match 'users', :controller => 'users', :action => :options, :via => :options, :as => nil
    scope 'users', :controller => 'users' do
      root :action => :index, :as => 'users'
      get '/:c_id', :action => :show, :as => 'user'
      put '/:c_id', :action => :update
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      patch '/:c_id', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/tags', :action => :index, :as => 'user_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'user_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy
    end

    # /vms
    match 'vms', :controller => 'vms', :action => :options, :via => :options, :as => nil
    scope 'vms', :controller => 'vms' do
      root :action => :index, :as => 'vms'
      get '/:c_id', :action => :show, :as => 'vm'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
      delete '/:c_id', :action => :destroy

      get '/:c_id/tags', :action => :index, :as => 'vm_tags'
      get '/:c_id/tags/:s_id', :action => :show, :as => 'vm_tag'
      post '/:c_id/tags', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/tags(/:s_id)', :action => :update
      delete '/:c_id/tags/:s_id', :action => :destroy

      get '/:c_id/policies', :action => :index, :as => 'vm_policies'
      get '/:c_id/policies/:s_id', :action => :show, :as => 'vm_policy'
      post '/:c_id/policies', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policies(/:s_id)', :action => :update
      delete '/:c_id/policies/:s_id', :action => :destroy

      get '/:c_id/policy_profiles', :action => :index, :as => 'vm_policy_profiles'
      get '/:c_id/policy_profiles/:s_id', :action => :show, :as => 'vm_policy_profile'
      post '/:c_id/policy_profiles', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/policy_profiles(/:s_id)', :action => :update

      get '/:c_id/accounts', :action => :index, :as => 'vm_accounts'
      get '/:c_id/accounts/:s_id', :action => :show, :as => 'vm_account'

      get '/:c_id/custom_attributes', :action => :index, :as => 'vm_custom_attributes'
      get '/:c_id/custom_attributes/:s_id', :action => :show, :as => 'vm_custom_attribute'
      post '/:c_id/custom_attributes', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/custom_attributes(/:s_id)', :action => :update
      delete '/:c_id/custom_attributes/:s_id', :action => :destroy

      get '/:c_id/security_groups', :action => :index, :as => 'vm_security_groups'
      get '/:c_id/security_groups/:s_id', :action => :show, :as => 'vm_security_group'
      post '/:c_id/security_groups', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/security_groups(/:s_id)', :action => :update

      get '/:c_id/software', :action => :index, :as => 'vm_softwares'
      get '/:c_id/software/:s_id', :action => :show, :as => 'vm_software'

      get '/:c_id/snapshots', :action => :index, :as => 'vm_snapshots'
      get '/:c_id/snapshots/:s_id', :action => :show, :as => 'vm_snapshot'
      post '/:c_id/snapshots', :action => :create, :constraints => Api::CreateConstraint.new
      post '/:c_id/snapshots(/:s_id)', :action => :update
      delete '/:c_id/snapshots/:s_id', :action => :destroy

      get '/:c_id/metric_rollups', :action => :index, :as => 'vm_metric_rollups'
      get '/:c_id/metric_rollups/:s_id', :action => :show, :as => 'vm_metric_rollup'
    end

    # /zones
    match 'zones', :controller => 'zones', :action => :options, :via => :options, :as => nil
    scope 'zones', :controller => 'zones' do
      root :action => :index, :as => 'zones'
      get '/:c_id', :action => :show, :as => 'zone'
      post '/', :action => :create, :constraints => Api::CreateConstraint.new
      post '(/:c_id)', :action => :update
    end
  end
end
