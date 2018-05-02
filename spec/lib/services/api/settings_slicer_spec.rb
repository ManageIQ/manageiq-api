RSpec.describe Api::SettingsSlicer do
  describe ".slice" do
    it "will take a path and return a sub-set of the settings" do
      settings = {
        "product" => {"some" => "product settings"},
        "server"  => {"some" => "server settings"}
      }

      actual = described_class.slice(settings, "product")

      expect(actual).to eq("product" => {"some" => "product settings"})
    end

    example "paths can be deeply nested" do
      settings = {
        "product" => {"some" => "product settings"},
        "server"  => {
          "some"           => "server settings",
          "worker_monitor" => {"some" => "worker monitor settings"}
        }
      }

      actual = described_class.slice(settings, "server", "worker_monitor")

      expect(actual).to eq("server" => {"worker_monitor" => {"some" => "worker monitor settings"}})
    end

    example "paths can terminate in a non-object" do
      settings = {
        "product" => {"some" => "product settings"},
        "server"  => {
          "some" => "server settings",
          "role" => "database_operations"
        }
      }

      actual = described_class.slice(settings, "server", "role")

      expect(actual).to eq("server" => {"role" => "database_operations"})
    end

    it "returns an empty hash for invalid categories" do
      settings = {
        "product" => {"some" => "product settings"},
        "server"  => {"some" => "server settings"}
      }

      actual = described_class.slice(settings, "not a category")

      expect(actual).to eq({})
    end
  end
end
