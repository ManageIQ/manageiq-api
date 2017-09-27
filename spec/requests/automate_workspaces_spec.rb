#
# REST API Request Tests - /api/automate_workspaces
#
describe "Automate Workspaces API" do
  describe 'GET' do
    let(:user) { FactoryGirl.create(:user_with_group, :userid => "admin") }
    let(:aw) { FactoryGirl.create(:automate_workspace, :user => user, :tenant => user.current_tenant) }

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
  end

  describe 'POST' do
    let(:user) { FactoryGirl.create(:user_with_group, :userid => "admin") }
    let(:aw) { FactoryGirl.create(:automate_workspace, :user => user, :tenant => user.current_tenant) }
    let(:output) { { 'objects' => { 'root' => { 'a' => '1'} }, 'state_vars' => {'b' => 2}} }

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
  end
end
