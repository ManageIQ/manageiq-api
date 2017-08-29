#
# REST API Request Tests - /api/automate_workspaces
#
describe "Automate Workspaces API" do
  describe 'GET' do
    let(:aw) { FactoryGirl.create(:automate_workspace) }
    it 'should not allow fetching using id' do
      api_basic_authorize action_identifier(:automate_workspaces, :read, :resource_actions, :get)

      run_get(automate_workspaces_url(aw.id))

      expect(response).to have_http_status(:not_found)
    end

    it 'should allow fetching using guid' do
      api_basic_authorize action_identifier(:automate_workspaces, :read, :resource_actions, :get)

      run_get(automate_workspaces_url(aw.guid))

      expect(response).to have_http_status(:ok)
    end

    it "forbids listing of all automate workspaces" do
      api_basic_authorize action_identifier(:automate_workspaces, :read, :resource_actions, :get)

      run_get(automate_workspaces_url)

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'POST' do
    let(:aw) { FactoryGirl.create(:automate_workspace) }
    let(:output) { { 'workspace' => { 'root' => { 'a' => '1'} }, 'state_var' => {'b' => 2}} }

    it 'should allow updating the object with valid data' do
      api_basic_authorize action_identifier(:automate_workspaces, :edit)

      run_post(automate_workspaces_url(aw.guid), :action => 'edit', :resource => output)

      expect(response).to have_http_status(:ok)
    end

    it 'should send bad request with invalid data' do
      api_basic_authorize action_identifier(:automate_workspaces, :edit)

      run_post(automate_workspaces_url(aw.guid), :action => 'edit', :resource => {})

      expect(response).to have_http_status(:bad_request)
    end
  end
end
