module Api
  class ConfigurationScriptSourcesController < BaseController
    include Subcollections::ConfigurationScriptPayloads

    def edit_resource(type, id, data)
      config_script_src = resource_search(id, type)
      raise "Update not supported for #{config_script_src_ident(config_script_src)}" unless config_script_src.respond_to?(:update_in_provider_queue)
      task_id = config_script_src.update_in_provider_queue(data.deep_symbolize_keys)
      action_result(true, "Updating #{config_script_src_ident(config_script_src)}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource_main_action(type, config_script_src, _data)
      ensure_respond_to(type, config_script_src, :delete, :delete_in_provider_queue)
      {:task_id => config_script_src.delete_in_provider_queue}
    end

    def create_resource(_type, _id, data)
      validate_attrs(data)
      manager_id = parse_id(data['manager_resource'], :providers)
      raise 'Must specify a valid manager_resource href or id' unless manager_id
      manager = resource_search(manager_id, :providers)

      type = "#{manager.type}::ConfigurationScriptSource"
      klass = ConfigurationScriptSource.descendant_get(type)
      raise "ConfigurationScriptSource cannot be added to #{manager_ident(manager)}" unless klass.respond_to?(:create_in_provider_queue)

      task_id = klass.create_in_provider_queue(manager.id, data.except('manager_resource').deep_symbolize_keys)
      action_result(true, "Creating ConfigurationScriptSource for #{manager_ident(manager)}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def refresh_resource(type, id, _data)
      api_resource(type, id, "Refreshing") do |config_script_src|
        {:task_ids => EmsRefresh.queue_refresh_task(config_script_src)}
      end
    end

    private

    def config_script_src_ident(config_script_src)
      "ConfigurationScriptSource id:#{config_script_src.id} name: '#{config_script_src.name}'"
    end

    def validate_attrs(data)
      raise 'Must supply a manager resource' unless data['manager_resource']
    end

    def manager_ident(manager)
      "Manager id:#{manager.id} name: '#{manager.name}'"
    end
  end
end
