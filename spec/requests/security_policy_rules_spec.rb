RSpec.describe 'Security Policy Rules API' do
  include Spec::Support::SupportsHelper

  let(:ems) { FactoryBot.create(:ems_network) }

  describe "GET /api/providers/:id/security_policy_rules" do
    let!(:security_policy)      { FactoryBot.create(:security_policy, :ext_management_system => ems) }
    let!(:security_policy_rule) { FactoryBot.create(:security_policy_rule, :ext_management_system => ems, :security_policy => security_policy) }

    it "rejects request without appropriate role" do
      api_basic_authorize

      get api_provider_security_policy_rules_url(nil, ems)

      expect(response).to have_http_status(:forbidden)
    end

    it 'can list security policy rules' do
      api_basic_authorize collection_action_identifier(:security_policy_rules, :read, :get)

      get api_provider_security_policy_rules_url(nil, ems), :params => {:expand => "resources"}

      expect_query_result(:security_policy_rules, 1)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/providers/:id/security_policy_rules" do
    it "queues creation of the security policy" do
      api_basic_authorize subcollection_action_identifier(:providers, :security_policy_rules, :create)
      post api_provider_security_policy_rules_url(nil, ems), :params => {:name => "new security policy rule"}

      expected = {
        "results" => [
          a_hash_including(
            "success"   => true,
            "message"   => "Creating security policy rule",
            "task_id"   => anything,
            "task_href" => a_string_matching(api_tasks_url)
          )
        ]
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)

      queue_item = MiqQueue.find_by(:class_name => ems.class.name, :method_name => "create_security_policy_rule")
      expect(queue_item).to have_attributes(
        :zone       => ems.zone_name,
        :queue_name => ems.queue_name_for_ems_operations
      )
    end
  end
end
