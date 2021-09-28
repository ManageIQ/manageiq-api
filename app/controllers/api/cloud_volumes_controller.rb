module Api
  class CloudVolumesController < BaseController
    include Subcollections::Tags

    def create_resource(type, _id = nil, data = {})
      assert_id_not_specified(data, type)
      create_resource_task_result(type, data['ems_id'], :name => data['name']) do |ems, klass|
        klass.create_volume_queue(User.current_userid, ems, data) # returns task_id
      end
    end

    def edit_resource(type, id, data = {})
      resource_task_result(type, id, :update) do |cloud_volume|
        cloud_volume.update_key_pair_queue(User.current_userid, data) # returns task_id
      end
    end

    def safe_delete_resource(type, id, _data = {})
      resource_task_result(type, id, :safe_delete) do |cloud_volume|
        cloud_volume.safe_delete_volume_queue(User.current_userid) # returns task_id
      end
    end

    def delete_resource(type, id, _data = {})
      resource_task_result(type, id, :delete) do |cloud_volume|
        cloud_volume.safe_delete_volume_queue(User.current_userid) # returns task_id
      end
    end

    def options
      if params[:id]
        cloud_volume = resource_search(params[:id], :cloud_volumes, CloudVolume)
        render_options(:cloud_volumes, :form_schema => cloud_volume.params_for_update)
      elsif params[:ems_id]
        ems = resource_search(params[:ems_id], :ext_management_systems, ExtManagementSystem)
        raise BadRequestError, "No CloudVolume support for - #{ems.class}" unless defined?(ems.class::CloudVolume)

        klass = ems.class::CloudVolume
        raise BadRequestError, klass.unsupported_reason(:create) unless klass.supports?(:create)

        render_options(:cloud_volumes, :form_schema => klass.params_for_create(ems))
      else
        super
      end
    end
  end
end
