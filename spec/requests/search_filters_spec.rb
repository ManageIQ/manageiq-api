describe 'Search Filters' do
  let(:filter) { FactoryGirl.create(:miq_search) }

  describe 'GET /api/search_filters/:id' do
    it 'cannot get a search filter without an appropriate role' do
      api_basic_authorize

      get(api_search_filter_url(nil, filter))

      expect(response).to have_http_status(:forbidden)
    end

    it 'can retrieve a search filter with an appropriate role' do
      api_basic_authorize(action_identifier(:search_filters, :read, :resource_actions, :get))

      get(api_search_filter_url(nil, filter))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => filter.id.to_s)
    end
  end

  describe 'POST /api/search_filters' do
    it 'cannot delete a filter without an appropriate role' do
      api_basic_authorize

      post(api_search_filters_url, :params => { :action => :delete, :resources => [{:description => filter.description}]})

      expect(response).to have_http_status(:forbidden)
    end

    it 'can delete a filter by description, id, or href with an appropriate role' do
      filter2, filter3 = FactoryGirl.create_list(:miq_search, 2)
      api_basic_authorize(collection_action_identifier(:search_filters, :delete, :post))

      post(api_search_filters_url, :params => {
             :action    => :delete,
             :resources => [
               {:description => filter.description},
               {:id => filter2.id},
               {:href => api_search_filter_url(nil, filter3)}
             ]
           })

      expected = {
        'results' => [
          a_hash_including('href' => api_search_filter_url(nil, filter)),
          a_hash_including('href' => api_search_filter_url(nil, filter2)),
          a_hash_including('href' => api_search_filter_url(nil, filter3))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/search_filters/:id' do
    it 'cannot delete a filter without an appropriate role' do
      api_basic_authorize

      post(api_search_filter_url(nil, filter), :params => {:action => 'delete'})

      expect(response).to have_http_status(:forbidden)
    end

    it 'can delete a filter by id with an appropriate role' do
      api_basic_authorize(action_identifier(:search_filters, :delete, :resource_actions, :post))

      post(api_search_filter_url(nil, filter), :params => {:action => 'delete'})

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE /api/search_filters/:id' do
    it 'can delete a filter by id with an appropriate role' do
      api_basic_authorize(action_identifier(:search_filters, :delete, :resource_actions, :delete))

      delete(api_search_filter_url(nil, filter))

      expect(response).to have_http_status(:no_content)
    end
  end
end
