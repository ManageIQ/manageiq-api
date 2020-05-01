RSpec.describe 'Container Nodes API' do
  describe 'GET /api/container_nodes' do
    it 'will not list container nodes without an appropriate role' do
      api_basic_authorize

      get(api_container_nodes_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'lists all container nodes with an appropriate role' do
      node1, node2 = FactoryBot.create_list(:container_node, 2)
      api_basic_authorize collection_action_identifier(:container_nodes, :read, :get)

      get(api_container_nodes_url)

      expected = {
        'count'     => 2,
        'name'      => 'container_nodes',
        'resources' => a_collection_including(
          {'href' => api_container_node_url(nil, node1)}, {'href' => api_container_node_url(nil, node2)}
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'GET /api/container_nodes/:id' do
    it 'will not show a container node without an appropriate role' do
      api_basic_authorize
      node = FactoryBot.create(:container_node)

      get(api_container_node_url(nil, node))

      expect(response).to have_http_status(:forbidden)
    end

    it 'will show a container node with an appropriate role' do
      node = FactoryBot.create(:container_node)
      api_basic_authorize action_identifier(:container_nodes, :read, :resource_actions, :get)

      get(api_container_node_url(nil, node))

      expect(response.parsed_body).to include('id' => node.id.to_s, 'href' => api_container_node_url(nil, node))
      expect(response).to have_http_status(:ok)
    end
  end

  it_behaves_like "a check compliance action", "container_node", :container_node, "ContainerNode"
end
