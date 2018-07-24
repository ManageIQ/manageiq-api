RSpec.describe 'Configuration Scripts API' do
  describe 'GET /api/configuration_scripts' do
    it 'lists all the configuration scripts with an appropriate role' do
      script = FactoryGirl.create(:configuration_script)
      api_basic_authorize collection_action_identifier(:configuration_scripts, :read, :get)

      get(api_configuration_scripts_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'configuration_scripts',
        'resources' => [
          hash_including('href' => api_configuration_script_url(nil, script))
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to configuration scripts without an appropriate role' do
      api_basic_authorize

      get(api_configuration_scripts_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/configuration_scripts/:id' do
    it 'will show an ansible script with an appropriate role' do
      script = FactoryGirl.create(:configuration_script)
      api_basic_authorize action_identifier(:configuration_scripts, :read, :resource_actions, :get)

      get(api_configuration_script_url(nil, script))

      expect(response.parsed_body)
        .to include('href' => api_configuration_script_url(nil, script))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to an ansible script without an appropriate role' do
      script = FactoryGirl.create(:configuration_script)
      api_basic_authorize

      get(api_configuration_script_url(nil, script))

      expect(response).to have_http_status(:forbidden)
    end
  end
end
