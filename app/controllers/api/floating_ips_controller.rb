module Api
  class FloatingIpsController < BaseController
    def create_resource(_type, _id = nil, data = {})
      create_resource_task_result(type, data['ems_id'], :name => data['name']) do |ems|
        ems.create_floating_ip_queue(User.current_userid, data.deep_symbolize_keys) # returns task_id
      end
    end

    def edit_resource(type, id, data)
      floating_ip = resource_search(id, type, collection_class(:floating_ips))
      raise BadRequestError, "Update for #{floating_ip_ident(floating_ip)}: #{floating_ip.unsupported_reason(:update)}" unless floating_ip.supports?(:update)

      task_id = floating_ip.update_floating_ip_queue(session[:userid], data.deep_symbolize_keys)
      action_result(true, "Updating #{floating_ip_ident(floating_ip)}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource(type, id, _data = {})
      delete_action_handler do
        floating_ip = resource_search(id, type, collection_class(:floating_ips))
        raise BadRequestError, "Delete for #{floating_ip_ident(floating_ip)}: #{floating_ip.unsupported_reason(:delete)}" unless floating_ip.supports?(:delete)

        task_id = floating_ip.delete_floating_ip_queue(session[:userid])
        action_result(true, "Deleting #{floating_ip_ident(floating_ip)}", :task_id => task_id)
      end
    end

    private

    def floating_ip_ident(floating_ip)
      "Floating Ip id:#{floating_ip.id} name: '#{floating_ip.name}'"
    end
  end
end
