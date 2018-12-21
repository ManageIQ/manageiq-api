RSpec.describe 'Lans API' do
  describe 'GET /api/lans' do
    it 'returns all lans with an appropriate role' do
      lan = FactoryBot.create(:lan)
      api_basic_authorize collection_action_identifier(:lans, :read, :get)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'lans',
        'resources' => [
          hash_including('href' => api_lan_url(nil, lan))
        ]
      }
      get(api_lans_url)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids access to lans without an appropriate role' do
      api_basic_authorize

      get(api_lans_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/lans/:id' do
    let(:lan) { FactoryBot.create(:lan) }

    it 'will show a lan with an appropriate role' do
      api_basic_authorize action_identifier(:lans, :read, :resource_actions, :get)

      get(api_lan_url(nil, lan))

      expect(response.parsed_body).to include('href' => api_lan_url(nil, lan))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to a lan without an appropriate role' do
      api_basic_authorize

      get(api_lan_url(nil, lan))

      expect(response).to have_http_status(:forbidden)
    end
  end
end
