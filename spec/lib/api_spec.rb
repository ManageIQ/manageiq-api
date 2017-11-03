RSpec.describe Api do
  describe "::VERSION_REGEX" do
    it "detects the major version" do
      expect("v1").to be_a_valid_version
    end

    it "detects the minor version" do
      expect("v1.2").to be_a_valid_version
    end

    it "detects the patch version" do
      expect("v1.2.3").to be_a_valid_version
    end

    it "detects the prerelease version" do
      expect("v1.2.3-pre").to be_a_valid_version
      expect("v1.2.3-pre1").to be_a_valid_version
      expect("v1.2.3-pre-1").to be_a_valid_version
      expect("v1.2.3-pre.four").to be_a_valid_version
      expect("v1.2.3-alpha").to be_a_valid_version
      expect("v1.2.3-beta").to be_a_valid_version
      expect("v1.2.3-alpha.45").to be_a_valid_version
      expect("v1.2.3 pre").not_to be_a_valid_version
    end

    specify "versions must be prefixed with a 'v'" do
      expect("1.2.3").not_to be_a_valid_version
      expect("abcv1.2.3").not_to be_a_valid_version
    end

    def be_a_valid_version
      match(Api::VERSION_REGEX)
    end
  end

  describe ".serialize" do
    it "serializes the model" do
      Timecop.freeze("2017-01-01 00:00:00 UTC") do
        user = FactoryGirl.create(:user, :name => "Alice")

        actual = Api.serialize(user)

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

      actual = Api.serialize(vm, :extra => ["vendor_display"])

      expect(actual).to include("vendor_display" => "VMware")
    end

    specify "only whitelisted attributes can be requested" do
      vm = FactoryGirl.create(:vm)

      actual = Api.serialize(vm, :extra => ["destroy"])

      expect(actual).not_to include("destroy")
      expect { vm.reload }.not_to raise_error
    end

    it "can serialize only the requested attributes" do
      user = FactoryGirl.create(:user, :name => "Alice")

      actual = Api.serialize(user, :only => ["name"])

      expect(actual).to eq("name" => "Alice")
    end

    specify "only whitelisted attributes can be used with :only" do
      user = FactoryGirl.create(:user)

      actual = Api.serialize(user, :only => ["destroy"])

      expect(actual).not_to include("destroy")
      expect { user.reload }.not_to raise_error
    end
  end
end
