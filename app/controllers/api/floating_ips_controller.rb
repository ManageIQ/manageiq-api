module Api
  class FloatingIpsController < BaseProviderController
    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, _klass|
        {:task_id => ems.create_floating_ip_queue(User.current_userid, data.deep_symbolize_keys)}
      end
    end

    def edit_resource(type, id, data)
      api_resource(type, id, "Updating", :supports => :update) do |floating_ip|
        {:task_id => floating_ip.update_floating_ip_queue(User.current_userid, data.deep_symbolize_keys)}
      end
    end

    def delete_resource_main_action(type, floating_ip, _data)
      ensure_supports(type, floating_ip, :delete)
      {:task_id => floating_ip.delete_floating_ip_queue(User.current_userid)}
    end
  end
end
