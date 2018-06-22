module Api
  module Subcollections
    module Vms
      def vms_query_resource(object)
        vms = object.try(:vms) || []
        vms = Rbac.filtered(vms)

        vm_attrs = attribute_selection_for("vms")
        return vms if vm_attrs.blank?

        vms.collect do |vm|
          attributes_hash = create_resource_attributes_hash(vm_attrs, vm)
          vm.as_json.merge(attributes_hash)
        end
      end
    end
  end
end
