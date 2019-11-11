#
# REST API Request Tests - Automate classes
#
# Regions primary collections:
#   /api/automate_classes
#
# Tests for:
# GET /api/automate_classes/:id
#

RSpec.describe "Regions API", :automate_classes do
  let(:domain) do
    FactoryBot.create(:miq_ae_system_domain, :name => 'ns1', :priority => 10)
  end

  let(:automate_class) do
    FactoryBot.create(:miq_ae_class, :namespace_id => domain.id, :name => 'foo')
  end

  let(:automate_class2) do
    FactoryBot.create(:miq_ae_class, :namespace_id => domain.id, :name => 'bar')
  end

  let(:automate_classes) do
    [automate_class, automate_class2]
  end

  context "authorization", :authorization do
    it "forbids access to automate_classes without an appropriate role" do
      expect_forbidden_request { get(api_automate_classes_url) }
    end

    it "forbids access to a automate_class resource without an appropriate role" do
      expect_forbidden_request { get(api_automate_class_url(nil, automate_class)) }
    end
  end

  context "get", :get do
    it "allows GETs of a automate_class" do
      api_basic_authorize action_identifier(:automate_classes, :read, :resource_actions, :get)

      get(api_automate_class_url(nil, automate_class))

      expect_single_resource_query(
        "href" => api_automate_class_url(nil, automate_class),
        "id"   => automate_class.id.to_s
      )
    end
  end

  context "edit", :edit do
    it "can update a automate_class with POST" do
      api_basic_authorize action_identifier(:automate_classes, :edit)

      post api_automate_class_url(nil, automate_class), :params => gen_request(:edit, :description => 'New Class description')

      expect(response).to have_http_status(:ok)
      automate_class.reload
      expect(automate_class.description).to eq('New Class description')
    end

    it "will fail if you try to edit invalid fields" do
      api_basic_authorize action_identifier(:automate_classes, :edit)

      post api_automate_class_url(nil, automate_class), :params => gen_request(:edit, :created_at => Time.now.utc)
      expect_bad_request("Attribute(s) 'created_at' should not be specified for updating an automate class resource")

      post api_automate_class_url(nil, automate_class), :params => gen_request(:edit, :updated_at => Time.now.utc)
      expect_bad_request("Attribute(s) 'updated_at' should not be specified for updating an automate class resource")
    end

    it "can update multiple automate_classes with POST" do
      api_basic_authorize action_identifier(:automate_classes, :edit)

      options = [
        {"href" => api_automate_class_url(nil, automate_class), "description" => "Updated Test Class 1"},
        {"href" => api_automate_class_url(nil, automate_class2), "description" => "Updated Test Class 2"}
      ]

      post api_automate_classes_url, :params => gen_request(:edit, options)

      expect(response).to have_http_status(:ok)

      expect_results_to_match_hash(
        "results",
        [
          {"id" => automate_class.id.to_s, "description" => "Updated Test Class 1"},
          {"id" => automate_class2.id.to_s, "description" => "Updated Test Class 2"}
        ]
      )

      expect(automate_class.reload.description).to eq("Updated Test Class 1")
      expect(automate_class2.reload.description).to eq("Updated Test Class 2")
    end

    it "will fail to update multiple automate_classes if any invalid fields are edited" do
      api_basic_authorize action_identifier(:automate_classes, :edit)

      options = [
        {"href" => api_automate_class_url(nil, automate_class), "description" => "New description"},
        {"href" => api_automate_class_url(nil, automate_class2), "created_at" => Time.now.utc}
      ]

      post api_automate_classes_url, :params => gen_request(:edit, options)

      expect_bad_request("Attribute(s) 'created_at' should not be specified for updating an automate class resource")
    end

    it "forbids edit of a automate_class without an appropriate role" do
      expect_forbidden_request do
        post(api_automate_class_url(nil, automate_class), :params => gen_request(:edit, :description => "New Region description"))
      end
    end
  end

  context "delete", :delete do
    it "can delete a automate_class with POST" do
      api_basic_authorize action_identifier(:automate_classes, :delete)
      automate_class

      expect { post api_automate_class_url(nil, automate_class), :params => gen_request(:delete) }.to change(MiqAeClass, :count).by(-1)
      expect_single_action_result(:success => true, :message => /#{automate_class.id}/)
    end

    it "can delete a automate_class with DELETE" do
      api_basic_authorize action_identifier(:automate_classes, :delete)
      automate_class

      expect { delete api_automate_class_url(nil, automate_class) }.to change(MiqAeClass, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "can delete multiple automate_classes with POST" do
      api_basic_authorize action_identifier(:automate_classes, :delete)
      automate_classes

      options = [
        {"href" => api_automate_class_url(nil, automate_classes.first)},
        {"href" => api_automate_class_url(nil, automate_classes.last)}
      ]

      expect { post api_automate_classes_url, :params => gen_request(:delete, options) }.to change(MiqAeClass, :count).by(-2)
      expect_multiple_action_result(automate_classes.size)
    end

    it "forbids deletion of a automate_class without an appropriate role" do
      expect_forbidden_request do
        delete(api_automate_class_url(nil, automate_class))
      end
    end
  end
end
