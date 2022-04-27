module Api
  class FloatingIpsController < BaseProviderController
    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, _klass|
        {:task_id => ems.create_floating_ip_queue(User.current_userid, data.deep_symbolize_keys)}
      end
    end

    def edit_resource(type, id, data)
      floating_ip = resource_search(id, type)
      raise BadRequestError, "Update for #{floating_ip_ident(floating_ip)}: #{floating_ip.unsupported_reason(:update)}" unless floating_ip.supports?(:update)

      task_id = floating_ip.update_floating_ip_queue(session[:userid], data.deep_symbolize_keys)
      action_result(true, "Updating #{floating_ip_ident(floating_ip)}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource_main_action(type, floating_ip, _data)
      ensure_supports(type, floating_ip, :delete)
      {:task_id => floating_ip.delete_floating_ip_queue(User.current_userid)}
    end

    private

    def floating_ip_ident(floating_ip)
      "Floating Ip id:#{floating_ip.id} name: '#{floating_ip.name}'"
    end
  end
end
