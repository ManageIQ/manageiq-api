RSpec.describe 'PxeServers API' do
  let!(:pxe_server) { FactoryBot.create(:pxe_server) }
  let!(:pxe_image_1) { FactoryBot.create(:pxe_image, :pxe_server => pxe_server) }
  let!(:pxe_image_2) { FactoryBot.create(:pxe_image, :pxe_server => pxe_server) }
  let!(:pxe_menu_1) { FactoryBot.create(:pxe_menu, :pxe_server => pxe_server) }

  describe 'GET /api/pxe_servers' do
    let(:url) { api_pxe_servers_url }

    it 'lists all pxe servers with an appropriate role' do
      api_basic_authorize collection_action_identifier(:pxe_servers, :read, :get)
      get(url)
      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'pxe_servers',
        'resources' => [
          hash_including('href' => api_pxe_server_url(nil, pxe_server))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/pxe_servers/:id' do
    let(:url) { api_pxe_server_url(nil, pxe_server) }

    it 'will show a pxe server with an appropriate role' do
      api_basic_authorize action_identifier(:pxe_servers, :read, :resource_actions, :get)
      get(url)
      expect(response.parsed_body).to include('href' => api_pxe_server_url(nil, pxe_server))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/pxe_servers/:id/pxe_images' do
    let(:url) { "/api/pxe_servers/#{pxe_server.id}/pxe_images" }

    it 'lists all pxe images of a pxe server' do
      api_basic_authorize subcollection_action_identifier(:pxe_servers, :pxe_images, :read, :get)
      get(url)
      expect_result_resources_to_include_hrefs(
        "resources",
        [
          api_pxe_server_pxe_image_url(nil, pxe_server, pxe_image_1),
          api_pxe_server_pxe_image_url(nil, pxe_server, pxe_image_2),
        ]
      )
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/pxe_servers/:id/pxe_images/:id' do
    let(:url) { "/api/pxe_servers/#{pxe_server.id}/pxe_images/#{pxe_image_1.id}" }

    it "will show a single pxe image of a pxe server" do
      api_basic_authorize subcollection_action_identifier(:pxe_servers, :pxe_images, :read, :get)
      get(url)
      expect_result_to_match_hash(
        response.parsed_body,
        "href"          => api_pxe_server_pxe_image_url(nil, pxe_server, pxe_image_1),
        "id"            => pxe_image_1.id.to_s,
        "pxe_server_id" => pxe_server.id.to_s,
        "name"          => pxe_image_1.name
      )
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/pxe_servers/:id/pxe_menus' do
    let(:url) { "/api/pxe_servers/#{pxe_server.id}/pxe_menus" }

    it 'lists all pxe menus of a pxe server' do
      api_basic_authorize subcollection_action_identifier(:pxe_servers, :pxe_menus, :read, :get)
      get(url)
      expect_result_resources_to_include_hrefs(
        "resources",
        [
          api_pxe_server_pxe_menu_url(nil, pxe_server, pxe_menu_1)
        ]
      )
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/pxe_servers/:id/pxe_menus/:id' do
    let(:url) { "/api/pxe_servers/#{pxe_server.id}/pxe_menus/#{pxe_menu_1.id}" }

    it "will show a single pxe menu of a pxe server" do
      api_basic_authorize subcollection_action_identifier(:pxe_servers, :pxe_images, :read, :get)
      get(url)
      expect_result_to_match_hash(
        response.parsed_body,
        "href"          => api_pxe_server_pxe_menu_url(nil, pxe_server, pxe_menu_1),
        "id"            => pxe_menu_1.id.to_s,
        "pxe_server_id" => pxe_server.id.to_s,
        "file_name"     => pxe_menu_1.file_name
      )
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/pxe_servers/' do
    let(:url) { "/api/pxe_servers/" }

    it 'create new pxe server' do
      api_basic_authorize collection_action_identifier(:pxe_servers, :create, :post)
      post(url, :params => {:name => 'foo', :uri => 'bar/quax'})
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['results'].first['name']).to eq('foo')
      expect(response.parsed_body['results'].first['uri']).to eq('bar/quax')
    end

    it 'create new pxe server with pxe menu' do
      api_basic_authorize collection_action_identifier(:pxe_servers, :create, :post)
      post(url, :params => {:name => 'foo', :uri => 'bar/quax', :pxe_menus => [{:file_name => 'menu_1'}]})
      expect(response).to have_http_status(:ok)
      expect(PxeServer.find(response.parsed_body['results'].first['id']).pxe_menus.first[:file_name]).to eq('menu_1')
    end
  end

  describe 'patch /api/pxe_servers/:id' do
    let(:url) { "/api/pxe_servers/#{pxe_server.id}" }

    it 'update pxe server' do
      api_basic_authorize collection_action_identifier(:pxe_servers, :edit, :patch)
      patch(url, :params => {:name => 'updated name', :uri => 'updated/url', :pxe_menus => [{:file_name => 'updated menu'}]})
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['name']).to eq('updated name')
      expect(response.parsed_body['uri']).to eq('updated/url')
      expect(PxeServer.find(response.parsed_body['id']).pxe_menus.first[:file_name]).to eq('updated menu')
    end
  end

  describe 'delete /api/pxe_servers/:id' do
    let(:url) { "/api/pxe_servers/#{pxe_server.id}" }

    it 'delete pxe server' do
      api_basic_authorize collection_action_identifier(:pxe_servers, :delete, :delete)
      delete(url)
      expect(response).to have_http_status(:no_content)
      expect(PxeServer.exists?(pxe_server.id)).to be_falsey
    end
  end
end
