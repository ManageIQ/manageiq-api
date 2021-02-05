RSpec.describe Api::SettingsFilterer do
  describe ".filter_for" do
    context "with opt[:settings]" do
      it "filters on the custom settings that are passed" do
        user     = instance_double("User", :super_admin_user? => true)
        settings = { "api" => {"authentication" => "1337.minutes"} }
        actual   = described_class.filter_for(user, :settings => settings)

        expect(actual["api"]).to eq(settings["api"])
      end
    end

    context "with opt[:whitelist]" do
      it "uses the custom whitelist to filter settings" do
        # whitelist only used on non-super-admin users
        user   = instance_double("User", :super_admin_user? => false)
        actual = described_class.filter_for(user, :whitelist => %w[api])

        expect(actual.keys).to eq(%w[api])
      end
    end
  end

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

      context "and a subtree to filter on" do
        it "returns the subtree" do
          settings = {
            "product" => {"some" => "product settings"},
            "server"  => {"some" => "server settings"},
          }
          whitelist = %w(product)

          actual = described_class.new(user, settings, whitelist).fetch(:subtree => "server")

          expect(actual).to eq("server" => {"some" => "server settings"})
        end

        it "returns an empty hash" do
          settings = {
            "product" => {"some" => "product settings"},
            "server"  => {"some" => "server settings"},
          }
          whitelist = %w(product)

          actual = described_class.new(user, settings, whitelist).fetch(:subtree => "not a category/not a subcategory")

          expect(actual).to eq({})
        end
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
          "product"        => {"some" => "product settings"},
          "server"         => {"some" => "server settings"},
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

      context "and a subtree to filter on" do
        it "returns the subtree" do
          settings = {
            "product" => {"some" => "product settings"},
            "server"  => {"some" => "server settings"},
          }
          whitelist = %w(product server)

          actual = described_class.new(user, settings, whitelist).fetch(:subtree => "server")

          expect(actual).to eq("server" => {"some" => "server settings"})
        end

        it "returns an empty hash" do
          settings = {
            "product" => {"some" => "product settings"},
            "server"  => {"some" => "server settings"},
          }
          whitelist = %w(product server)

          actual = described_class.new(user, settings, whitelist).fetch(:subtree => "not a category/not a subcategory")

          expect(actual).to eq({})
        end
      end
    end
  end
end
