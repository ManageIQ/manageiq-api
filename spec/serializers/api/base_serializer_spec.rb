RSpec.describe Api::BaseSerializer do
  describe ".serialize" do
    it "serializes the model" do
      Timecop.freeze("2017-01-01 00:00:00 UTC") do
        user = FactoryGirl.create(:user, :name => "Alice")

        actual = Api::UserSerializer.serialize(user)

        expected = {
          "id"         => user.id.to_s,
          "name"       => "Alice",
          "created_on" => "2017-01-01T00:00:00Z",
          "updated_on" => "2017-01-01T00:00:00Z"
        }
        expect(actual).to include(expected)
        expect(actual).not_to include("password_digest")
      end
    end

    specify "additional attributes can be requested" do
      vm = FactoryGirl.create(:vm, :vendor => "vmware")

      actual = Api::VmSerializer.serialize(vm, :extra => ["vendor_display"])

      expect(actual).to include("vendor_display" => "VMware")
    end

    specify "only whitelisted attributes can be requested" do
      vm = FactoryGirl.create(:vm)

      actual = Api::VmSerializer.serialize(vm, :extra => ["destroy"])

      expect(actual).not_to include("destroy")
      expect { vm.reload }.not_to raise_error
    end

    it "can serialize only the requested attributes" do
      user = FactoryGirl.create(:user, :name => "Alice")

      actual = Api::UserSerializer.serialize(user, :only => ["name"])

      expect(actual).to eq("name" => "Alice")
    end

    specify "only whitelisted attributes can be used with :only" do
      user = FactoryGirl.create(:user)

      actual = Api::UserSerializer.serialize(user, :only => ["destroy"])

      expect(actual).not_to include("destroy")
      expect { user.reload }.not_to raise_error
    end
  end
end
