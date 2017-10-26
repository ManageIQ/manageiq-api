#
# REST API Request Tests - /api/automate_workspaces
#
describe "Automate Workspaces API" do
  let(:user) { FactoryGirl.create(:user_with_group, :userid => "admin") }
  let(:aw) do
    FactoryGirl.create(:automate_workspace, :user   => user,
                                            :tenant => user.current_tenant,
                                            :input  => input)
  end
  let(:password) { "secret" }
  let(:p45) { "Pneumonoultramicroscopicsilicovolcanoconiosis" }
  let(:encrypted) { MiqAePassword.encrypt(password) }
  let(:p45_encrypted) { MiqAePassword.encrypt(p45) }
  let(:var2v) { "password::#{encrypted}" }
  let(:var3v) { "password::#{p45_encrypted}" }
  let(:input) do
    { 'objects'           => {'root' => { 'var1' => '1', 'var2' => var2v, 'var3' => var3v}},
      'method_parameters' => {'arg1' => "password::#{encrypted}"} }
  end

  describe 'GET' do
    it 'should not return resources when fetching the collection' do
      api_basic_authorize collection_action_identifier(:automate_workspaces, :read, :get)
      aw
      get(api_automate_workspaces_url)

      expect(response.parsed_body).not_to include("resources")
      expect(response).to have_http_status(:ok)
    end

    it 'should not allow fetching using id' do
      api_basic_authorize action_identifier(:automate_workspaces, :read, :resource_actions, :get)
      get(api_automate_workspace_url(nil, aw.id))

      expect(response).to have_http_status(:not_found)
    end

    it 'should allow fetching using guid' do
      api_basic_authorize action_identifier(:automate_workspaces, :read, :resource_actions, :get)
      get(api_automate_workspace_url(nil, aw.guid))

      expect(response).to have_http_status(:ok)
    end

    it 'fetching by guid should return resources with guid based references' do
      api_basic_authorize action_identifier(:automate_workspaces, :read, :resource_actions, :get)
      get(api_automate_workspace_url(nil, aw.guid))

      expect(response.parsed_body).to include(
        "href"    => api_automate_workspace_url(nil, aw.guid),
        "id"      => aw.id.to_s,
        "guid"    => aw.guid,
        "actions" => a_collection_including(
          "name"   => "edit",
          "method" => "post",
          "href"   => api_automate_workspace_url(nil, aw.guid)
        )
      )
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST' do
    let(:output) { { 'objects' => { 'root' => { 'a' => '1'} }, 'state_vars' => {'b' => 2}} }

    let(:decrypt_params) do
      {:action   => 'decrypt',
       :resource => {'object' => 'root', 'attribute' => 'var2'}}
    end

    let(:decrypt_params_a) do
      {
        :action    => 'decrypt',
        :resources => [
          {'object' => 'root', 'attribute' => 'var2'},
          {'object' => 'root', 'attribute' => 'var3'},
          {'object' => 'root', 'attribute' => 'nada'}
        ]
      }
    end

    let(:encrypt_params) do
      {:action   => 'encrypt',
       :resource => {'object' => 'root', 'attribute' => 'var3', 'value' => password }}
    end

    it 'should allow updating the object with valid data' do
      api_basic_authorize action_identifier(:automate_workspaces, :edit)
      post(api_automate_workspace_url(nil, aw.guid), :params => {:action => 'edit', :resource => output})

      expect(response).to have_http_status(:ok)
    end

    it 'should send bad request with invalid data' do
      api_basic_authorize action_identifier(:automate_workspaces, :edit)

      post(api_automate_workspace_url(nil, aw.guid), :params => {:action => 'edit', :resource => {}})

      expect(response).to have_http_status(:bad_request)
    end

    it 'decrypt a password' do
      api_basic_authorize action_identifier(:automate_workspaces, :decrypt)

      post(api_automate_workspace_url(nil, aw.guid), :params => decrypt_params)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['value']).to eq(password)
    end

    it 'decrypt collection of passwords' do
      expected = {
        "results" => a_collection_containing_exactly(
          a_hash_including("value" => password),
          a_hash_including("value" => p45),
          a_hash_including("value" => "")
        )
      }
      api_basic_authorize action_identifier(:automate_workspaces, :decrypt)

      post(api_automate_workspace_url(nil, aw.guid), :params => decrypt_params_a)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'encrypt' do
      api_basic_authorize action_identifier(:automate_workspaces, :encrypt)

      post(api_automate_workspace_url(nil, aw.guid), :params => encrypt_params)

      aw.reload
      expect(response).to have_http_status(:ok)
      expect(aw.output.fetch_path('objects', 'root', 'var3')).to eq("password::#{encrypted}")
    end
  end
end
