module Api
  module Subcollections
    module Vms
      def vms_query_resource(object)
        vms = object.try(:vms) || []

        vm_attrs = attribute_selection_for("vms")
        return vms if vm_attrs.blank?

        vms.collect do |vm|
          attributes_hash = create_resource_attributes_hash(vm_attrs, vm)
          vm.as_json.merge(attributes_hash)
        end
      end

      private

      def create_vm_attributes_hash(vm_attrs, vm)
        vm_attrs.each_with_object({}) do |attr, hash|
          hash[attr] = vm.public_send(attr.to_sym) if vm.respond_to?(attr.to_sym)
        end.compact
      end
    end
  end
end
