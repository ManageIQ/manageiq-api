RSpec.describe 'Orchestration Template API' do
  let(:ems) { FactoryBot.create(:ext_management_system) }

  context 'orchestration_template index' do
    it 'can list the orchestration_template' do
      FactoryBot.create(:orchestration_template_amazon_in_json)
      FactoryBot.create(:orchestration_template_openstack_in_yaml)
      FactoryBot.create(:vnfd_template_openstack_in_yaml)

      api_basic_authorize collection_action_identifier(:orchestration_templates, :read, :get)
      get(api_orchestration_templates_url)
      expect_query_result(:orchestration_templates, 3, 3)
    end
  end

  context 'orchestration_template create' do
    let :request_body_hot do
      {:name      => "OrchestrationTemplateHot1",
       :type      => "ManageIQ::Providers::Openstack::CloudManager::OrchestrationTemplate",
       :orderable => true,
       :content   => ""}
    end

    let :request_body_hot_deprecated do
      {:name      => "OrchestrationTemplateHot1",
       :type      => "OrchestrationTemplateHot",
       :orderable => true,
       :content   => ""}
    end

    let :request_body_cfn do
      {:name      => "OrchestrationTemplateCfn1",
       :type      => "ManageIQ::Providers::Amazon::CloudManager::OrchestrationTemplate",
       :orderable => true,
       :content   => ""}
    end

    let :request_body_vnfd do
      {:name      => "OrchestrationTemplateVnfd1",
       :type      => "ManageIQ::Providers::Openstack::CloudManager::VnfdTemplate",
       :ems_id    => ems.id,
       :orderable => true,
       :content   => ""}
    end

    it 'rejects creation without appropriate role' do
      api_basic_authorize

      post(api_orchestration_templates_url, :params => request_body_hot)

      expect(response).to have_http_status(:forbidden)
    end

    it 'supports single HOT orchestration_template creation' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :create)

      expect do
        post(api_orchestration_templates_url, :params => request_body_hot)
      end.to change(ManageIQ::Providers::Openstack::CloudManager::OrchestrationTemplate, :count).by(1)
    end

    it 'supports orchestration_template creation with a deprecated type' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :create)

      expect do
        post(api_orchestration_templates_url, :params => request_body_hot_deprecated)
      end.to change(ManageIQ::Providers::Openstack::CloudManager::OrchestrationTemplate, :count).by(1)
    end

    it 'supports single CFN orchestration_template creation' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :create)

      expect do
        post(api_orchestration_templates_url, :params => request_body_cfn)
      end.to change(ManageIQ::Providers::Amazon::CloudManager::OrchestrationTemplate, :count).by(1)
    end

    it 'supports single VNFd orchestration_template creation' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :create)

      expect do
        post(api_orchestration_templates_url, :params => request_body_vnfd)
      end.to change(ManageIQ::Providers::Openstack::CloudManager::VnfdTemplate, :count).by(1)
    end

    it 'supports orchestration_template creation via action' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :create)

      expect do
        post(api_orchestration_templates_url, :params => gen_request(:create, request_body_hot))
      end.to change(ManageIQ::Providers::Openstack::CloudManager::OrchestrationTemplate, :count).by(1)
    end

    it 'rejects a request with an id' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :create)

      post(api_orchestration_templates_url, :params => request_body_hot.merge(:id => 1))

      expect_bad_request(/Resource id or href should not be specified/)
    end

    it 'fails gracefully with invalid type specified' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :create)

      post(api_orchestration_templates_url, :params => { :type => 'OrchestrationTemplateUnknown' })

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => a_string_including('Invalid type OrchestrationTemplateUnknown specified')
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'orchestration_template edit' do
    it 'supports single orchestration_template edit' do
      hot = FactoryBot.create(:orchestration_template_openstack_in_yaml, :name => "New Hot Template")

      api_basic_authorize collection_action_identifier(:orchestration_templates, :edit)

      edited_name = "Edited Hot Template"
      post(api_orchestration_template_url(nil, hot), :params => gen_request(:edit, :name => edited_name))

      expect(hot.reload.name).to eq(edited_name)
    end
  end

  context 'orchestration_template delete' do
    it 'supports single orchestration_template delete' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :delete)

      cfn = FactoryBot.create(:orchestration_template_amazon_in_json)

      api_basic_authorize collection_action_identifier(:orchestration_templates, :delete)

      delete(api_orchestration_template_url(nil, cfn))

      expect(response).to have_http_status(:no_content)
      expect(OrchestrationTemplate.exists?(cfn.id)).to be_falsey
    end

    it 'runs callback before_destroy on the model' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :delete)

      cfn = FactoryBot.create(:vnfd_template_openstack_in_yaml)
      api_basic_authorize collection_action_identifier(:orchestration_templates, :delete)
      expect_any_instance_of(ManageIQ::Providers::Openstack::CloudManager::VnfdTemplate).to receive(:raw_destroy).with(no_args) # callback on the model
      delete(api_orchestration_template_url(nil, cfn))

      expect(response).to have_http_status(:no_content)
      expect(OrchestrationTemplate.exists?(cfn.id)).to be_falsey
    end

    it 'supports multiple orchestration_template delete' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :delete)

      cfn = FactoryBot.create(:orchestration_template_amazon_in_json)
      hot = FactoryBot.create(:orchestration_template_openstack_in_yaml)

      post(
        api_orchestration_templates_url,
        :params => gen_request(:delete, [{'id' => cfn.id}, {'id' => hot.id}])
      )

      expect_multiple_action_result(2, :success => true, :message => /Deleting Orchestration Template/)
      expect(OrchestrationTemplate.exists?(cfn.id)).to be_falsey
      expect(OrchestrationTemplate.exists?(hot.id)).to be_falsey
    end
  end

  context 'orchestration template copy' do
    it 'forbids orchestration template copy without an appropriate role' do
      api_basic_authorize

      orchestration_template = FactoryBot.create(:orchestration_template_amazon)
      new_content            = "{ 'Description': 'Test content 1' }\n"

      post(
        api_orchestration_template_url(nil, orchestration_template),
        :params => gen_request(:copy, :content => new_content)
      )

      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids orchestration template copy with no content specified' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :copy)

      orchestration_template = FactoryBot.create(:orchestration_template_amazon)

      post(api_orchestration_template_url(nil, orchestration_template), :params => gen_request(:copy))

      expect(response).to have_http_status(:bad_request)
    end

    it 'can copy single orchestration template with a different content' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :copy)

      orchestration_template = FactoryBot.create(:orchestration_template_amazon)
      new_content            = "{ 'Description': 'Test content 1' }\n"

      expected = {
        'content'     => new_content,
        'name'        => orchestration_template.name,
        'description' => orchestration_template.description,
        'draft'       => orchestration_template.draft,
        'orderable'   => orchestration_template.orderable
      }

      expect do
        post(
          api_orchestration_template_url(nil, orchestration_template),
          :params => gen_request(:copy, :content => new_content)
        )
      end.to change(ManageIQ::Providers::Amazon::CloudManager::OrchestrationTemplate, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
      expect(response.parsed_body['id']).to_not equal(orchestration_template.id)
    end

    it 'can copy multiple orchestration templates with a different content' do
      api_basic_authorize collection_action_identifier(:orchestration_templates, :copy)

      orchestration_template   = FactoryBot.create(:orchestration_template_amazon)
      new_content              = "{ 'Description': 'Test content 1' }\n"
      orchestration_template_2 = FactoryBot.create(:orchestration_template_amazon)
      new_content_2            = "{ 'Description': 'Test content 2' }\n"

      expected = {
        'results' => a_collection_containing_exactly(
          a_hash_including('content' => new_content),
          a_hash_including('content' => new_content_2)
        )
      }

      expect do
        post(
          api_orchestration_templates_url,
          :params => gen_request(
            :copy,
            [
              {:id => orchestration_template.id, :content => new_content},
              {:id => orchestration_template_2.id, :content => new_content_2}
            ]
          )
        )
      end.to change(ManageIQ::Providers::Amazon::CloudManager::OrchestrationTemplate, :count).by(2)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
