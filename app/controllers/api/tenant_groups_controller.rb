module Api
  class TenantGroupsController < BaseController
    def tenant_groups_search_conditions
      ["group_type = ?", MiqGroup::TENANT_GROUP]
    end

    def find_tenant_groups(id)
      MiqGroup.tenant_groups.find(id)
    end
  end
end
