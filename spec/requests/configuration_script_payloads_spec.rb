RSpec.describe 'Configuration Script Payloads API' do
  describe 'GET /api/configuration_script_payloads' do
    it 'lists all the configuration script payloads with an appropriate role' do
      script_payload = FactoryBot.create(:configuration_script_payload)
      api_basic_authorize collection_action_identifier(:configuration_script_payloads, :read, :get)

      get(api_configuration_script_payloads_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'configuration_script_payloads',
        'resources' => [
          hash_including('href' => api_configuration_script_payload_url(nil, script_payload))
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to configuration script payloads without an appropriate role' do
      api_basic_authorize

      get(api_configuration_script_payloads_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/configuration_script_payloads/:id' do
    it 'will show an ansible script_payload with an appropriate role' do
      script_payload = FactoryBot.create(:configuration_script_payload)
      api_basic_authorize action_identifier(:configuration_script_payloads, :read, :resource_actions, :get)

      get(api_configuration_script_payload_url(nil, script_payload))

      expect(response.parsed_body)
        .to include('href' => api_configuration_script_payload_url(nil, script_payload))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to an ansible script_payload without an appropriate role' do
      script_payload = FactoryBot.create(:configuration_script_payload)
      api_basic_authorize

      get(api_configuration_script_payload_url(nil, script_payload))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/configuration_script_payloads' do
    let(:manager)        { FactoryBot.create(:ext_management_system) }
    let(:script_payload) { FactoryBot.create(:configuration_script_payload, :manager => manager) }

    context "edit" do
      it 'forbids edit of a configuration_script_payload without an appropriate role' do
        api_basic_authorize

        post(api_configuration_script_payloads_url, :params => {:action => 'edit', :name => 'foo'})
        expect(response).to have_http_status(:forbidden)
      end

      it 'can edit a configuration_script_payload' do
        api_basic_authorize collection_action_identifier(:configuration_script_payloads, :edit, :post)

        post(api_configuration_script_payloads_url, :params => {:action => 'edit', :resources => [{:id => script_payload.id, :name => 'foo', :credentials => {"my-cred" => "credential123"}}]})

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('results' => [a_hash_including('name' => 'foo')])
        expect(script_payload.reload.name).to eq('foo')
        expect(script_payload.credentials).to include("my-cred" => "credential123")
      end

      it "fails if the credential can't be found" do
        api_basic_authorize collection_action_identifier(:configuration_script_payloads, :edit, :post)

        post(api_configuration_script_payloads_url, :params => {:action => 'edit', :resources => [{:id => script_payload.id, :name => 'foo', :credentials => {"my-cred" => {"credential_ref" => "my-credential", "credential_field" => "userid"}}}]})
        expect(response).to have_http_status(:bad_request)
      end

      context "with an authentication reference in credentials" do
        let!(:authentication) { FactoryBot.create(:authentication, :ems_ref => "my-credential", :resource => manager) }

        context "owned by another tenant" do
          let(:tenant_1)        { FactoryBot.create(:tenant) }
          let(:tenant_2)        { FactoryBot.create(:tenant) }
          let(:group_1)         { FactoryBot.create(:miq_group, :tenant => tenant_1, :miq_user_role => @role) }
          let(:group_2)         { FactoryBot.create(:miq_group, :tenant => tenant_2) }
          let(:user_2)          { FactoryBot.create(:user, :miq_groups => [group_2]) }
          let!(:authentication) { FactoryBot.create(:authentication, :ems_ref => "my-credential", :resource => manager, :evm_owner => user_2, :miq_group => group_2) }

          before do
            @user.miq_groups << group_1
            @user.update!(:current_group => group_1)
          end

          it "fails if the credential is owned by another tenant" do
            api_basic_authorize(collection_action_identifier(:configuration_script_payloads, :edit, :post))
            post(api_configuration_script_payloads_url, :params => {:action => 'edit', :resources => [{:id => script_payload.id, :name => 'foo', :credentials => {"my-cred" => {"credential_ref" => "my-credential", "credential_field" => "userid"}}}]})
            expect(response).to have_http_status(:bad_request)
          end
        end

        it "adds the authentication to the configuration_script_payload.authentications" do
          api_basic_authorize collection_action_identifier(:configuration_script_payloads, :edit, :post)

          post(api_configuration_script_payloads_url, :params => {:action => 'edit', :resources => [{:id => script_payload.id, :name => 'foo', :credentials => {"my-cred" => {"credential_ref" => "my-credential", "credential_field" => "userid"}}}]})
          expect(script_payload.reload.authentications).to include(authentication)
        end

        context "with an existing associated authentication record" do
          before { script_payload.authentications << authentication }

          it "doesn't duplicate records" do
            api_basic_authorize collection_action_identifier(:configuration_script_payloads, :edit, :post)

            post(api_configuration_script_payloads_url, :params => {:action => 'edit', :resources => [{:id => script_payload.id, :name => 'foo', :credentials => {"my-cred" => {"credential_ref" => "my-credential", "credential_field" => "userid"}}}]})
            expect(script_payload.reload.authentications.count).to eq(1)
          end

          it "removes associated authentications" do
            api_basic_authorize collection_action_identifier(:configuration_script_payloads, :edit, :post)

            post(api_configuration_script_payloads_url, :params => {:action => 'edit', :resources => [{:id => script_payload.id, :name => 'foo', :credentials => {}}]})
            expect(script_payload.reload.authentications.count).to be_zero
          end
        end
      end

      context "with a configuration_script_source" do
        let(:script_source)  { FactoryBot.create(:configuration_script_source) }
        let(:script_payload) { FactoryBot.create(:configuration_script_payload, :configuration_script_source => script_source) }

        it "cannot modify the name, payload, payload_type" do
          api_basic_authorize collection_action_identifier(:configuration_script_payloads, :edit, :post)

          post(api_configuration_script_payloads_url, :params => {:action => 'edit', :resources => [{:id => script_payload.id, :name => "foo", :payload => "---\n", :payload_type => "yaml"}]})

          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body["error"]).to include("message" => "Invalid parameters: name, payload, payload_type")
        end
      end
    end
  end

  describe 'PUT /api/configuration_script_payloads/:id' do
    let(:script_payload) { FactoryBot.create(:configuration_script_payload) }

    it 'forbids put on a configuration_script_payload without an appropriate role' do
      api_basic_authorize

      put(api_configuration_script_payload_url(nil, script_payload), :params => {:name => 'foo'})

      expect(response).to have_http_status(:forbidden)
    end

    it 'can update a configuration_script_payload' do
      api_basic_authorize action_identifier(:configuration_script_payloads, :edit)

      put(api_configuration_script_payload_url(nil, script_payload), :params => {:name => 'foo'})

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('name' => 'foo')
      expect(script_payload.reload.name).to eq('foo')
    end
  end

  describe 'PATCH /api/configuration_script_payloads/:id' do
    let(:script_payload) { FactoryBot.create(:configuration_script_payload) }

    it 'forbids put on a configuration_script_payload without an appropriate role' do
      api_basic_authorize

      patch(api_configuration_script_payload_url(nil, script_payload), :params => {:name => 'foo'})

      expect(response).to have_http_status(:forbidden)
    end

    it 'can update a configuration_script_payload' do
      api_basic_authorize action_identifier(:configuration_script_payloads, :edit)

      patch(api_configuration_script_payload_url(nil, script_payload), :params => {:name => 'foo'})

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('name' => 'foo')
      expect(script_payload.reload.name).to eq('foo')
    end
  end

  describe 'GET /api/configuration_script_payloads/:id/authentications' do
    it 'returns the configuration script payloads authentications' do
      authentication = FactoryBot.create(:authentication)
      playbook = FactoryBot.create(:configuration_script_payload, :authentications => [authentication])
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :read, :get)

      get(api_configuration_script_payload_authentications_url(nil, playbook), :params => { :expand => 'resources' })

      expected = {
        'resources' => [
          a_hash_including('id' => authentication.id.to_s)
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/configuration_script_payloads/:id/authentications' do
    let(:provider) { FactoryBot.create(:provider_ansible_tower, :with_authentication) }
    let(:manager) { provider.managers.first }
    let(:playbook) { FactoryBot.create(:configuration_script_payload, :manager => manager) }
    let(:params) do
      {
        :action      => 'create',
        :description => "Description",
        :name        => "A Credential",
        :related     => {},
        :type        => 'ManageIQ::Providers::AnsibleTower::AutomationManager::Credential'
      }
    end

    it 'requires that the type support create_in_provider_queue' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :create)

      post(api_configuration_script_payload_authentications_url(nil, playbook), :params => { :type => 'Authentication' })

      expected = {
        'results' => [
          { 'success' => false, 'message' => 'type not currently supported' }
        ]
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'creates a new authentication with an appropriate role' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :create)

      post(api_configuration_script_payload_authentications_url(nil, playbook), :params => params)

      expected = {
        'results' => [a_hash_including(
          'success' => true,
          'message' => 'Creating Authentication',
          'task_id' => a_kind_of(String)
        )]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can create multiple authentications with an appropriate role' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :create)

      post(api_configuration_script_payload_authentications_url(nil, playbook), :params => { :resources => [params, params] })

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => 'Creating Authentication',
            'task_id' => a_kind_of(String)
          ),
          a_hash_including(
            'success' => true,
            'message' => 'Creating Authentication',
            'task_id' => a_kind_of(String)
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'cannot create an authentication without appropriate role' do
      api_basic_authorize

      post(api_configuration_script_payload_authentications_url(nil, playbook), :params => { :resources => [params] })

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/configuration_script_payloads/:id/authentications/:id' do
    it 'returns a specific authentication' do
      authentication = FactoryBot.create(:authentication)
      playbook = FactoryBot.create(:configuration_script_payload, :authentications => [authentication])
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :read, :get)

      get(api_configuration_script_payload_authentication_url(nil, playbook, authentication))

      expected = {
        'id' => authentication.id.to_s
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
