RSpec.describe Api::Utils do
  describe ".build_href_slug" do
    it "builds the href slug" do
      actual = Api::Utils.build_href_slug(Vm, 1_000_000_000_123)
      expect(actual).to eq("vms/1000000000123")
    end

    it "returns nil if the collection can't be found" do
      actual = Api::Utils.build_href_slug(VmOrTemplate, 1_000_000_000_123)
      expect(actual).to be_nil
    end
  end

  describe ".resource_search_by_href_slug" do
    let(:aw_user) { FactoryBot.create(:user_with_group) }
    let(:aw) do
      FactoryBot.create(:automate_workspace,
                         :user   => aw_user,
                         :tenant => aw_user.current_tenant)
    end
    before { allow(User).to receive_messages(:server_timezone => "UTC") }

    it "returns nil when nil is specified" do
      actual = described_class.resource_search_by_href_slug(nil)

      expect(actual).to be_nil
    end

    it "raises an exception with missing id" do
      expect { described_class.resource_search_by_href_slug("vms/") }
        .to raise_error("Invalid href_slug vms/ specified")
    end

    it "raises an exception with missing collection" do
      expect { described_class.resource_search_by_href_slug("/10") }
        .to raise_error("Invalid href_slug /10 specified")
    end

    it "raises an exception with missing delimited" do
      expect { described_class.resource_search_by_href_slug("vms") }
        .to raise_error("Invalid href_slug vms specified")
    end

    it "raises an exception with a bogus href_slug" do
      expect { described_class.resource_search_by_href_slug("bogus/123") }
        .to raise_error("Invalid href_slug bogus/123 specified")
    end

    it "raises an exception with a non primary collection href_slug" do
      expect { described_class.resource_search_by_href_slug("auth/123") }
        .to raise_error("Invalid href_slug auth/123 specified")
    end

    it "raises an ActiveRecord::RecordNotFound with a non-existent href_slug" do
      owner_tenant = FactoryBot.create(:tenant)
      owner_group  = FactoryBot.create(:miq_group, :tenant => owner_tenant)
      owner        = FactoryBot.create(:user, :miq_groups => [owner_group])

      expect { described_class.resource_search_by_href_slug("vms/99999", owner) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an exception with an undefined user" do
      vm = FactoryBot.create(:vm_vmware)

      expect { described_class.resource_search_by_href_slug("vms/#{vm.id}") }
        .to raise_error("User must be defined")
    end

    it "returns the resource when Rbac succeeds for current_user" do
      owner_tenant = FactoryBot.create(:tenant)
      owner_group  = FactoryBot.create(:miq_group, :tenant => owner_tenant)

      vm = FactoryBot.create(:vm_vmware, :tenant => owner_tenant)
      User.current_user = FactoryBot.create(:user, :miq_groups => [owner_group])

      actual = described_class.resource_search_by_href_slug("vms/#{vm.id}")

      expect(actual).to eq(vm)
    end

    it "returns the resource when Rbac succeeds for specified user" do
      owner_tenant = FactoryBot.create(:tenant)
      owner_group  = FactoryBot.create(:miq_group, :tenant => owner_tenant)
      owner        = FactoryBot.create(:user, :miq_groups => [owner_group])

      vm = FactoryBot.create(:vm_vmware, :tenant => owner_tenant)

      actual = described_class.resource_search_by_href_slug("vms/#{vm.id}", owner)

      expect(actual).to eq(vm)
    end

    it "does not return the resource when Rbac fails for current_user" do
      owner_tenant  = FactoryBot.create(:tenant)

      unauth_tenant = FactoryBot.create(:tenant)
      unauth_group  = FactoryBot.create(:miq_group, :tenant => unauth_tenant)

      vm = FactoryBot.create(:vm_vmware, :tenant => owner_tenant)
      User.current_user = FactoryBot.create(:user, :miq_groups => [unauth_group])

      actual = described_class.resource_search_by_href_slug("vms/#{vm.id}")

      expect(actual).to eq(nil)
    end

    it "does not return the resource when Rbac fails for specified user" do
      owner_tenant  = FactoryBot.create(:tenant)

      unauth_tenant = FactoryBot.create(:tenant)
      unauth_group  = FactoryBot.create(:miq_group, :tenant => unauth_tenant)
      unauth_user   = FactoryBot.create(:user, :miq_groups => [unauth_group])

      vm = FactoryBot.create(:vm_vmware, :tenant => owner_tenant)

      actual = described_class.resource_search_by_href_slug("vms/#{vm.id}", unauth_user)

      expect(actual).to eq(nil)
    end

    it "fetch automate workspace based on guid in href_slug" do
      actual = described_class.resource_search_by_href_slug(aw.href_slug, aw_user)
      expect(actual).to eq(aw)
    end

    it "raises error for automate workspace with invalid href_slug" do
      expect do
        described_class.resource_search_by_href_slug("automate_workspaces/99999", aw_user)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
