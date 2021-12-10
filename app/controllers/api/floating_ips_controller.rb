module Api
  class FloatingIpsController < BaseController
    def create_resource(_type, _id = nil, data = {})
      ems = ExtManagementSystem.find(data['ems_id'])
      klass = FloatingIp.class_by_ems(ems)
      raise BadRequestError, "Create floating ip for Provider #{ems.name}: #{klass.unsupported_reason(:create)}" unless klass.supports?(:create)

      task_id = ems.create_floating_ip_queue(session[:userid], data.deep_symbolize_keys)
      action_result(true, "Creating Floating Ip #{data['name']} for Provider: #{ems.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def edit_resource(type, id, data)
      floating_ip = resource_search(id, type, collection_class(:floating_ips))
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

    def options
      if (id = params["id"])
        render_update_resource_options(id)
      elsif (ems_id = params["ems_id"])
        render_create_resource_options(ems_id)
      else
        super
      end
    end

    private

    def floating_ip_ident(floating_ip)
      "Floating Ip id:#{floating_ip.id} name: '#{floating_ip.name}'"
    end
  end
end
