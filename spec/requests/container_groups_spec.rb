describe "Container Groups API" do
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
    let(:container_group) { FactoryBot.create(:container_group) }

    it 'forbids access without an appropriate role' do
      api_basic_authorize

      post(api_container_group_url(nil, container_group), :params => {:action => "logs"})

      expect(response).to have_http_status(:forbidden)
    end

    it 'queues fetching the logs and returns a task id' do
      api_basic_authorize(action_identifier(:container_groups, :logs, :resource_actions, :post))
      expect_any_instance_of(ContainerGroup).to receive(:logs_queue).with(@user.userid, {"tail_lines" => 10}).and_return(123)

      post(api_container_group_url(nil, container_group), :params => {:action => "logs", :tail_lines => 10})

      expected = {"success" => true, "task_id" => "123", "message" => a_string_including("Fetching logs for Pod")}
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'returns a failure when logs are not supported' do
      api_basic_authorize(action_identifier(:container_groups, :logs, :resource_actions, :post))
      allow_any_instance_of(ContainerGroup).to receive(:logs_queue).and_raise(MiqException::Error, "logs unsupported")

      post(api_container_group_url(nil, container_group), :params => {:action => "logs"})

      expect(response.parsed_body).to include("success" => false, "message" => "logs unsupported")
    end
  end

  it_behaves_like "a check compliance action", "container_group", :container_group, "ContainerGroup"
end
