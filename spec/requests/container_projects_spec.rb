describe "Container Projects API" do
  include Spec::Support::SupportsHelper
  context 'GET /api/container_projects' do
    it 'forbids access to container projects without an appropriate role' do
      api_basic_authorize

      get(api_container_projects_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns container projects with an appropriate role' do
      container_project = FactoryBot.create(:container_project)
      api_basic_authorize(collection_action_identifier(:container_projects, :read, :get))

      get(api_container_projects_url)

      expected = {
        'resources' => [{'href' => api_container_project_url(nil, container_project)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'GET /api/container_projects' do
    let(:container_project) { FactoryBot.create(:container_project) }

    it 'forbids access to a container project without an appropriate role' do
      api_basic_authorize

      get(api_container_project_url(nil, container_project))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the container project with an appropriate role' do
      api_basic_authorize(action_identifier(:container_projects, :read, :resource_actions, :get))

      get(api_container_project_url(nil, container_project))

      expected = {
        'href' => api_container_project_url(nil, container_project)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
  
  context 'GET /api/container_projects/:id' do
    let(:container_project) { FactoryBot.create(:container_project) }

    it 'forbids access to a container project without an appropriate role' do
      api_basic_authorize

      get(api_container_project_url(nil, container_project))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the container project with an appropriate role' do
      api_basic_authorize(action_identifier(:container_projects, :read, :resource_actions, :get))

      get(api_container_project_url(nil, container_project))

      expected = {
        'href' => api_container_project_url(nil, container_project)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "create operations" do
    it "forbids creation of container projects without an appropriate role" do
      api_basic_authorize
      post(api_container_projects_url, :params => { :name => 'test-project' })

      expect(response).to have_http_status(:forbidden)
    end

    it "can create a container project" do
      zone = FactoryBot.create(:zone, :name => "api_zone")
      provider = FactoryBot.create(:ems_kubernetes, :zone => zone)

      api_basic_authorize collection_action_identifier(:container_projects, :create, :post)

      post(api_container_projects_url, :params => { :ems_id => provider.id, :name => 'test-project' })

      expected = {
        'results' => a_collection_containing_exactly(
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Creating Container Project')
          )
        )
      }

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  context "delete operations" do
    it "forbids delete request without appropriate role" do
      api_basic_authorize
      post(api_container_projects_url, :params => { :action => 'delete' })

      expect(response).to have_http_status(:forbidden)
    end

    it "deletes a single Container Project" do
      zone = FactoryBot.create(:zone, :name => "api_zone")
      k8s = FactoryBot.create(:ems_kubernetes, :zone => zone)
      container_project = FactoryBot.create(:container_project, :name => 'TestProject', :ext_management_system => k8s)

      api_basic_authorize('container_project_delete')
      stub_supports(ContainerProject, :delete)

      post(api_container_project_url(nil, container_project), :params => gen_request(:delete))

      expect_single_action_result(:success => true, :message => /Deleting Container Project id: #{container_project.id} name: '#{container_project.name}'/)
    end

    it "deletes multiple Container Projects" do
      zone = FactoryBot.create(:zone, :name => "api_zone")
      k8s = FactoryBot.create(:ems_kubernetes, :zone => zone)
      container_project1 = FactoryBot.create(:container_project, :name => 'TestProject1', :ext_management_system => k8s)
      container_project2 = FactoryBot.create(:container_project, :name => 'TestProject2', :ext_management_system => k8s)

      api_basic_authorize('container_project_delete')
      stub_supports(ContainerProject, :delete)

      post(api_container_projects_url, :params => gen_request(:delete, [{"href" => api_container_project_url(nil, container_project1)}, {"href" => api_container_project_url(nil, container_project2)}]))

      results = response.parsed_body["results"]
      expect(results[0]["message"]).to match(/Deleting Container Project id: #{container_project1.id} name: '#{container_project1.name}'/)
      expect(results[0]["success"]).to match(true)
      expect(results[1]["message"]).to match(/Deleting Container Project id: #{container_project2.id} name: '#{container_project2.name}'/)
      expect(results[1]["success"]).to match(true)
      expect(response).to have_http_status(:ok)
    end

    it "rejects delete request with DELETE as a resource action without appropriate role" do
      container_project = FactoryBot.create(:container_project)

      api_basic_authorize

      delete api_container_project_url(nil, container_project)

      expect(response).to have_http_status(:forbidden)
    end

    it 'DELETE will raise an error if the container project does not exist' do
      api_basic_authorize action_identifier(:container_projects, :delete, :resource_actions, :delete)
      delete(api_container_project_url(nil, 999_999))

      expect(response).to have_http_status(:not_found)
    end
  end

  context "create operations - supports/unsupported tests" do
    it "rejects creation when provider does not support create" do
      zone = FactoryBot.create(:zone, :name => "api_zone")
      provider = FactoryBot.create(:ems_kubernetes, :zone => zone)

      # Stub that create is NOT supported
      stub_supports_not(provider.class::ContainerProject, :create)

      api_basic_authorize collection_action_identifier(:container_projects, :create, :post)

      post(api_container_projects_url, :params => { :ems_id => provider.id, :name => 'test-project' })

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']['message']).to include('Feature not available/supported')
    end
  end

  context "delete operations - supports/unsupported tests" do
    it "rejects deletion when container project does not support delete" do
      zone = FactoryBot.create(:zone, :name => "api_zone")
      k8s = FactoryBot.create(:ems_kubernetes, :zone => zone)
      container_project = FactoryBot.create(:container_project, :name => 'TestProject', :ext_management_system => k8s)

      # Stub that delete is NOT supported
      stub_supports_not(ContainerProject, :delete)

      api_basic_authorize('container_project_delete')

      post(api_container_project_url(nil, container_project), :params => gen_request(:delete))

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']['message']).to include('Feature not available/supported')
    end

    it "rejects bulk deletion when container projects do not support delete" do
      zone = FactoryBot.create(:zone, :name => "api_zone")
      k8s = FactoryBot.create(:ems_kubernetes, :zone => zone)
      container_project1 = FactoryBot.create(:container_project, :name => 'TestProject1', :ext_management_system => k8s)
      container_project2 = FactoryBot.create(:container_project, :name => 'TestProject2', :ext_management_system => k8s)

      # Stub that delete is NOT supported
      stub_supports_not(ContainerProject, :delete)

      api_basic_authorize('container_project_delete')

      post(api_container_projects_url, :params => gen_request(:delete, [{"href" => api_container_project_url(nil, container_project1)}, {"href" => api_container_project_url(nil, container_project2)}]))

      results = response.parsed_body["results"]
      expect(results[0]["success"]).to be false
      expect(results[0]["message"]).to include('Feature not available/supported')
      expect(results[1]["success"]).to be false
      expect(results[1]["message"]).to include('Feature not available/supported')
      expect(response).to have_http_status(:ok)
    end
  end

  context "additional permission edge cases" do
    it "forbids creation with wrong permission type" do
      zone = FactoryBot.create(:zone, :name => "api_zone")
      provider = FactoryBot.create(:ems_kubernetes, :zone => zone)

      # Authorize with read permission instead of create
      api_basic_authorize(collection_action_identifier(:container_projects, :read, :get))

      post(api_container_projects_url, :params => { :ems_id => provider.id, :name => 'test-project' })

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids deletion with wrong permission type" do
      zone = FactoryBot.create(:zone, :name => "api_zone")
      k8s = FactoryBot.create(:ems_kubernetes, :zone => zone)
      container_project = FactoryBot.create(:container_project, :name => 'TestProject', :ext_management_system => k8s)

      # Authorize with read permission instead of delete
      api_basic_authorize(action_identifier(:container_projects, :read, :resource_actions, :get))

      post(api_container_project_url(nil, container_project), :params => gen_request(:delete))

      expect(response).to have_http_status(:forbidden)
    end
  end
end
