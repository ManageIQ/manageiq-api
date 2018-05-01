RSpec.describe Api::SettingsFilterer do
  describe "#fetch" do
    context "given an admin user" do
      let(:user) { instance_double("User", :super_admin_user? => true) }

      example "an admin can see all the settings" do
        settings = {
          "product" => {"some" => "product settings"},
          "server"  => {"some" => "server settings"},
        }
        whitelist = %w(product)

        actual = described_class.new(user, settings, whitelist).fetch

        expect(actual).to eq(settings)
      end
    end

    context "given a non-admin user" do
      let(:user) { instance_double("User", :super_admin_user? => false) }

      example "a non-admin will see only the whitelisted settings" do
        settings = {
          "product" => {"some" => "product settings"},
          "server"  => {"some" => "server settings"},
        }
        whitelist = %w(product)

        actual = described_class.new(user, settings, whitelist).fetch

        expected = {"product" => {"some" => "product settings"}}
        expect(actual).to eq(expected)
      end

      it "supports multiple categories" do
        settings = {
          "product" => {"some" => "product settings"},
          "server"  => {"some" => "server settings"},
          "authentication" => {"some" => "authentication settings"}
        }
        whitelist = %w(product server)

        actual = described_class.new(user, settings, whitelist).fetch

        expected = {
          "product" => {"some" => "product settings"},
          "server"  => {"some" => "server settings"}
        }
        expect(actual).to eq(expected)
      end

      it "supports partial categories" do
        settings = {
          "server" => {
            "some" => "server settings",
            "role" => "database_operations"
          },
        }
        whitelist = %w(server/role)

        actual = described_class.new(user, settings, whitelist).fetch

        expected = {"server" => {"role" => "database_operations"}}
        expect(actual).to eq(expected)
      end

      it "supports second level partial categories" do
        settings = {
          "server" => {
            "some"           => "server settings",
            "worker_monitor" => {
              "some"          => "worker monitor settings",
              "sync_interval" => "30.minutes"
            }
          }
        }
        whitelist = %w(server/worker_monitor/sync_interval)

        actual = described_class.new(user, settings, whitelist).fetch

        expected = {"server" => {"worker_monitor" => {"sync_interval" => "30.minutes"}}}
        expect(actual).to eq(expected)
      end

      it "supports multiple and partial categories" do
        settings = {
          "authentication" => {"some" => "authentication settings"},
          "product"        => {"some" => "product settings"},
          "server"         => {
            "some"           => "server settings",
            "role"           => "database_operations",
            "worker_monitor" => {
              "some"          => "worker monitor settings",
              "sync_interval" => "30.minutes"
            }
          }
        }
        whitelist = %w(product server/role server/worker_monitor/sync_interval)

        actual = described_class.new(user, settings, whitelist).fetch

        expected = {
          "product" => {"some" => "product settings"},
          "server"  => {
            "role"           => "database_operations",
            "worker_monitor" => {"sync_interval" => "30.minutes"}
          }
        }
        expect(actual).to eq(expected)
      end
    end
  end
end
