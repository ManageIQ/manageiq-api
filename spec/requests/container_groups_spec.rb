describe "Container Groups API" do
  include Spec::Support::SupportsHelper

  context 'GET /api/container_groups' do
    it 'forbids access to container groups without an appropriate role' do
      api_basic_authorize

      get(api_container_groups_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns container groups with an appropriate role' do
      container_groups = FactoryBot.create(:container_group)
      api_basic_authorize(collection_action_identifier(:container_groups, :read, :get))

      get(api_container_groups_url)

      expected = {
        'resources' => [{'href' => api_container_group_url(nil, container_groups)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'GET /api/container_groups' do
    let(:container_group) { FactoryBot.create(:container_group) }

    it 'forbids access to a container group without an appropriate role' do
      api_basic_authorize

      get(api_container_group_url(nil, container_group))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the container group with an appropriate role' do
      api_basic_authorize(action_identifier(:container_groups, :read, :resource_actions, :get))

      get(api_container_group_url(nil, container_group))

      expected = {
        'href' => api_container_group_url(nil, container_group)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'POST /api/container_groups/:id with action logs' do
    let(:ems) { FactoryBot.create(:ems_kubernetes) }
    let(:project) { FactoryBot.create(:container_project, :ext_management_system => ems) }
    let(:container_group) do
      FactoryBot.create(:kubernetes_container_group, :name => "test-pod", :ext_management_system => ems, :container_project => project)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize

      post(api_container_group_url(nil, container_group), :params => {:action => "logs"})

      expect(response).to have_http_status(:forbidden)
    end

    it 'queues fetching the logs and returns a task id' do
      api_basic_authorize(action_identifier(:container_groups, :logs, :resource_actions, :post))
      stub_supports(container_group, :logs)

      post(api_container_group_url(nil, container_group), :params => {:action => "logs", :tail_lines => 10})

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("success" => true, "message" => a_string_including("Fetching logs for Container Group"))

      task = MiqTask.find(response.parsed_body["task_id"])
      expect(task.userid).to eq(@user.userid)

      queue_item = MiqQueue.find_by(:miq_task_id => task.id)
      expect(queue_item).to have_attributes(
        :class_name  => container_group.class.name,
        :instance_id => container_group.id,
        :method_name => "logs"
      )
      expect(queue_item.args.first).to include("tail_lines" => 10)
    end

    it 'returns a failure when logs are not supported' do
      api_basic_authorize(action_identifier(:container_groups, :logs, :resource_actions, :post))
      stub_supports_not(container_group, :logs, "logs unsupported")

      post(api_container_group_url(nil, container_group), :params => {:action => "logs"})

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body.dig("error", "message")).to match(/logs unsupported/)
      expect(MiqQueue.where(:method_name => "logs")).to be_empty
    end
  end

  it_behaves_like "a check compliance action", "container_group", :container_group, "ContainerGroup"
end
