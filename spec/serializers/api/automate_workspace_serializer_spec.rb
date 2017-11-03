RSpec.describe Api::AutomateWorkspaceSerializer do
  describe ".serialize" do
    it "masks passwords" do
      automate_workspace = FactoryGirl.create(
        :automate_workspace,
        :input => {
          "objects"           => {
            "root" => {
              "foo" => "password::v2:{BkTmRrehAeNfBdFKDPvIIA==}"
            }
          },
          "method_parameters" => {
            "bar" => "password::v2:{BkTmRrehAeNfBdFKDPvIIA==}"
          }
        }
      )

      actual = described_class.serialize(automate_workspace)

      expected = {
        "input" => a_hash_including(
          "objects"           => a_hash_including(
            "root" => a_hash_including(
              "foo" => "password::********"
            )
          ),
          "method_parameters" => a_hash_including(
            "bar" => "password::********"
          )
        )
      }
      expect(actual).to include(expected)
    end
  end
end
