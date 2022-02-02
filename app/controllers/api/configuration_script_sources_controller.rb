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

    def create_resource(type, _id, data)
      manager_id = parse_id(data.delete('manager_resource'), :providers) || data['ems_id']

      # Since we are passing a custom hash to create_ems_resource (instead of data variable)
      # we need to manually remove it from data.
      data.delete('id')
      create_ems_resource(type, {'ems_id' => manager_id, 'name' => data['name']}, :supports => true) do |_manager, klass|
        {:task_id => klass.create_in_provider_queue(manager_id, data.deep_symbolize_keys)}
      end
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
  end
end
