RSpec.shared_examples "perform rate assign/unassign action" do |rate_type, collection_name, collection, assignment_prefix|
  let(:is_custom_attribute) { collection == :custom_attributes }
  let(:is_tag) { collection == :tags }

  let(:chargeback_rate) { FactoryBot.create(:chargeback_rate, :rate_type => rate_type) }

  let(:chargeback_rate_parameters) { {:id => chargeback_rate.id} }

  let(:action) { "assign" }
  let(:rate_assign_parameters) do
    {:action => action, :assignments => rate_assignments}
  end

  let(:assignment_type) do
    return :label if is_custom_attribute
    return :tag if is_tag

    :object
  end

  let(:resource_1) do
    case assignment_type
    when :label then
      custom_attribute_1
    when :tag then
      category = FactoryBot.create(:classification, :description => "Environment", :name => "environment", :single_value => true, :show => true)
      FactoryBot.create(:classification, :name => "prod", :description => "Production", :parent_id => category.id)
    when :object then
      FactoryBot.create(collection_name)
    end
  end

  let(:resource_2) do
    case assignment_type
    when :label then
      custom_attribute_2
    when :tag then
      category = FactoryBot.create(:classification, :description => "Department", :name => "department", :single_value => true, :show => true)
      FactoryBot.create(:classification, :name => "test", :description => "Test", :parent_id => category.id)
    when :object then
      FactoryBot.create(collection_name)
    end
  end

  let(:custom_attribute_1) { FactoryBot.create(collection_name, :resource => container_image, :name => 'label_1', :value => 'docker_1') }
  let(:custom_attribute_2) { FactoryBot.create(collection_name, :resource => container_image, :name => 'label_2', :value => 'docker_2') }
  let(:container_image) { FactoryBot.create(:container_image) }
  let(:custom_attribute_url) { api_container_image_custom_attributes_url(nil, container_image) }
  let(:custom_attribute_result_key_1) do
    chargeback_rate.send(:build_label_tag_path, custom_attribute_1, 'container_image')
  end

  let(:custom_attribute_result_key_2) do
    chargeback_rate.send(:build_label_tag_path, custom_attribute_2, 'container_image')
  end

  let(:href_resource) do
    case assignment_type
    when :label then
      custom_attribute_url
    when :tag then
      "/api/#{collection}"
    when :object then
      "/api/#{collection}"
    end
  end

  let(:resource_id_1) { assignment_type == :tag ? resource_1.tag.id : resource_1.id }
  let(:resource_id_2) { assignment_type == :tag ? resource_2.tag.id : resource_2.id }

  let(:resource_params_1) do
    href_params = {:href => "#{href_resource}/#{resource_id_1}"}
    is_tag ? href_params.merge(:assignment_prefix => assignment_prefix) : href_params
  end

  let(:resource_params_2) do
    href_params = {:href => "#{href_resource}/#{resource_id_2}"}
    is_tag ? href_params.merge(:assignment_prefix => assignment_prefix) : href_params
  end

  let(:params_target_key) { is_tag ? :tag : :resource }

  let(:rate_assignment_1) { {:chargeback => chargeback_rate_parameters, params_target_key => resource_params_1} }
  let(:rate_assignment_2) { {:chargeback => chargeback_rate_parameters, params_target_key => resource_params_2} }
  let(:rate_assignments) { [rate_assignment_1, rate_assignment_2] }

  let(:result_key_1) do
    case assignment_type
    when :label then
      custom_attribute_result_key_1
    when :tag then
      chargeback_rate.send(:build_tag_tagging_path, resource_1, assignment_prefix)
    when :object then
      "#{collection_name}/id/#{resource_1.id}"
    end
  end

  let(:result_key_2) do
    case assignment_type
    when :label then
      custom_attribute_result_key_2
    when :tag then
      chargeback_rate.send(:build_tag_tagging_path, resource_2, assignment_prefix)
    when :object then
      "#{collection_name}/id/#{resource_2.id}"
    end
  end

  let(:expected_results) { {result_key_1 => [chargeback_rate], result_key_2 => [chargeback_rate]} }

  it "assigns #{rate_type} rate to selected #{collection} on collection for #{collection_name}" do
    api_basic_authorize collection_action_identifier(:chargebacks, :assign)

    post(api_chargebacks_url, :params => rate_assign_parameters)

    assignments = ChargebackRate.assignments
    expect(expected_results).to include(assignments)
    expect_hash_to_have_only_keys(expected_results, assignments.keys)
    expect(response).to have_http_status(:ok)
  end

  context "validation errors" do
    context "target type validation" do
      let(:resource_params_2) { {:href => "api/containers/#{resource_id_2}"} }
      it "assigns #{rate_type} rate to selected #{collection} on collection for #{collection_name}" do
        api_basic_authorize collection_action_identifier(:chargebacks, :assign)
        post(api_chargebacks_url, :params => rate_assign_parameters)
        expect(response.parsed_body['success']).to be_falsey
        message = response.parsed_body['message']

        if collection_name == :tag && rate_type == "Compute"
          expect(message).to a_string_matching(/'assignment_prefix' is missing for target record./)
        elsif collection_name == :tag && rate_type == "Storage"
          expect(message).to a_string_matching(/Unable to parse tag(.*)./)
        elsif collection_name == :custom_attribute
          expect(message).to a_string_matching(/More than one type of target resources are not expected./)
        else
          expect(message).to a_string_matching(/Cannot determine target resource for collection(.*)/)
        end
      end

      context "set resource_params_2 as ext_management_system #{collection_name}" do
        let(:ext_management_system) { FactoryBot.create(:ext_management_system) }
        let(:resource_params_2) { {:href => "api/#{collection == :providers ? 'vms' : 'providers'}/#{ext_management_system.id}"} }

        it "assigns #{rate_type} rate to selected #{collection} on collection for #{collection_name}" do
          api_basic_authorize collection_action_identifier(:chargebacks, :assign)

          post(api_chargebacks_url, :params => rate_assign_parameters)

          expect(response.parsed_body['success']).to be_falsey
          message = response.parsed_body['message']
          if collection_name == :tag && rate_type == "Compute"
            expect(message).to a_string_matching(/'assignment_prefix' is missing for target record./)
          elsif collection_name == :tag && rate_type == "Storage"
            expect(message).to a_string_matching(/Unable to parse tag(.*)./)
          elsif rate_type == "Storage" && %i[miq_enterprise tenant].include?(collection_name)
            expect(message).to a_string_matching(/Cannot determine target resource for collection(.*)/)
          elsif %i[miq_enterprise ems_cluster tenant].include?(collection_name)
            expect(message).to a_string_matching(/Input resources are not valid for resource rates./)
          elsif collection_name == :custom_attribute
            expect(message).to a_string_matching(/More than one type of target resources are not expected./)
          else
            expect(message).to a_string_matching(/Cannot determine target resource for collection(.*)/)
          end
        end
      end
    end
  end

  let(:target_resource_1) do
    case assignment_type
    when :label then
      [resource_1, "container_image"]
    when :tag then
      [resource_1, assignment_prefix]
    when :object then
      resource_1
    end
  end

  let(:target_resource_2) do
    case assignment_type
    when :label then
      [resource_2, "container_image"]
    when :tag then
      [resource_2, assignment_prefix]
    when :object then
      resource_2
    end
  end

  let(:assignment_paramaters_for_method) do
    [
      {:cb_rate => chargeback_rate, assignment_type => target_resource_1},
      {:cb_rate => chargeback_rate, assignment_type => target_resource_2}
    ]
  end

  context "unassign for #{collection_name}" do
    let(:action) { "unassign" }
    let(:rate_assignments) { [rate_assignment_1] }
    let(:expected_results) { {result_key_2 => [chargeback_rate]} }

    it "unassigns #{rate_type} rate from selected #{collection} on collection" do
      api_basic_authorize collection_action_identifier(:chargebacks, :unassign)
      ChargebackRate.set_assignments(rate_type, assignment_paramaters_for_method)

      post(api_chargebacks_url, :params => rate_assign_parameters)

      assignments = ChargebackRate.assignments
      expect(expected_results).to include(assignments)
      expect_hash_to_have_only_keys(expected_results, assignments.keys)
      expect(response).to have_http_status(:ok)
    end
  end

  context "on single #{rate_type} rate for #{collection_name}" do
    let(:rate_assignments) { [{params_target_key => resource_params_1}] }
    let(:expected_results) { {result_key_1 => [chargeback_rate]} }

    it "assigns #{rate_type} rate to selected #{collection} " do
      api_basic_authorize collection_action_identifier(:chargebacks, :assign)

      post(api_chargeback_url(nil, chargeback_rate), :params => rate_assign_parameters)

      assignments = ChargebackRate.assignments
      expect(expected_results).to include(assignments)
      expect_hash_to_have_only_keys(expected_results, assignments.keys)
      expect(response).to have_http_status(:ok)
    end

    context "unassign" do
      let(:action) { "unassign" }
      let(:rate_assignments) { [{params_target_key => resource_params_1}] }
      let(:expected_results) { {result_key_2 => [chargeback_rate]} }

      it "unassigns #{rate_type} rate from selected #{collection} on single resource" do
        api_basic_authorize collection_action_identifier(:chargebacks, :unassign)

        ChargebackRate.set_assignments(rate_type, assignment_paramaters_for_method)

        post(api_chargeback_url(nil, chargeback_rate), :params => rate_assign_parameters)
        assignments = ChargebackRate.assignments
        expect(expected_results).to include(assignments)
        expect_hash_to_have_only_keys(expected_results, assignments.keys)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
