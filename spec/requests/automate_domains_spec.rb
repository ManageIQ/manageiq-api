#
# REST API Request Tests - /api/automate_domains
#
describe "Automate Domains API" do
  describe 'GET /api/automate_domains' do
    it 'returns the correct href_slug' do
      git_domain = FactoryBot.create(:miq_ae_git_domain)
      api_basic_authorize collection_action_identifier(:automate_domains, :read, :get)

      get(api_automate_domains_url, :params => { :expand => 'resources', :attributes => 'href_slug' })

      expected = {
        'resources' => [
          a_hash_including('href_slug' => "automate_domains/#{git_domain.id}")
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'delete action' do
    let(:automate_domain) { FactoryBot.create(:miq_ae_domain) }
    let(:automate_domain_locked) { FactoryBot.create(:miq_ae_domain_user_locked, :enabled => true) }
    let(:automate_domain_system) { FactoryBot.create(:miq_ae_system_domain_enabled) }

    it 'forbids access for users without proper permissions' do
      api_basic_authorize

      post(api_automate_domain_url(nil, automate_domain), :params => gen_request(:delete))

      expect(response).to have_http_status(:forbidden)
    end

    it 'does not delete locked domains' do
      api_basic_authorize action_identifier(:automate_domains, :delete)

      post(api_automate_domain_url(nil, automate_domain_locked), :params => gen_request(:delete))

      expect_bad_request(/Not deleting.*locked/)
    end

    it 'does not delete system domains' do
      api_basic_authorize action_identifier(:automate_domains, :delete)

      post(api_automate_domain_url(nil, automate_domain_system), :params => gen_request(:delete))

      expect_bad_request(/Not deleting.*locked/)
    end

    it 'deletes domains' do
      api_basic_authorize action_identifier(:automate_domains, :delete)

      post(api_automate_domain_url(nil, automate_domain), :params => gen_request(:delete))
      expect_single_action_result(
        :success => true,
        :message => /Deleting Automate Domain/,
        :href    => api_automate_domain_url(nil, automate_domain)
      )
    end
  end

  describe 'create_from_git action' do
    let(:git_domain) { FactoryBot.create(:miq_ae_git_domain) }
    let(:action) { FactoryBot.create(:miq_action) }
    let(:event) { FactoryBot.create(:miq_event_definition) }
    let(:miq_automate_domains_contents) do
      {"automate_domains" => [{'event_id' => event.id,
                               "actions"  => [{"action_id" => action.id, "opts" => { :qualifier => "failure" }}] }]}
    end

    let(:sample_params) do
      {
        "git_url"  => "git url",
        "ref_name" => "ref name",
        "ref_type" => "ref type"
      }
    end

    it 'forbids create_from_git for users without proper permissions' do
      api_basic_authorize

      post(api_automate_domain_url(nil, git_domain), :params => gen_request(:create_from_git))
      expect(response).to have_http_status(:forbidden)
    end

    context 'with proper git_owner role' do
      before do
        allow(GitBasedDomainImportService).to receive(:available?).and_return(true)
      end

      it 'should not create a new automate domain from git when missing params' do
        api_basic_authorize collection_action_identifier(:automate_domains, :create_from_git)

        post(api_automate_domain_url(nil, git_domain), :params => gen_request(:create_from_git, "git_url" => "url"))
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]["message"]).to include(miq_automate_domains_contents.keys.join(", "))
      end

      it 'should not create new automate domain from git with incorrect ref_type param' do
        api_basic_authorize collection_action_identifier(:automate_domains, :create_from_git)

        post(api_automate_domain_url(nil, git_domain), :params => gen_request(:create_from_git, sample_params))
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]["message"]).to include("ref_type must be")
      end

      it 'create domain from a git repository' do
        api_basic_authorize collection_action_identifier(:automate_domains, :create_from_git)
        expect_any_instance_of(GitBasedDomainImportService).to receive(:queue_refresh_and_import)
        sample_params["ref_type"] = "tag"

        post(api_automate_domain_url(nil, git_domain), :params => gen_request(:create_from_git, sample_params))
        expect_single_action_result(
          :success => true,
          :message => "Creating Automate Domain from #{sample_params["git_url"]}/#{sample_params["ref_name"]}",
          :zhref   => api_automate_domain_url(nil, git_domain)
        )
      end
    end
  end

  describe 'refresh_from_source action' do
    let(:git_domain) { FactoryBot.create(:miq_ae_git_domain) }
    it 'forbids access for users without proper permissions' do
      api_basic_authorize

      post(api_automate_domain_url(nil, git_domain), :params => gen_request(:refresh_from_source))

      expect(response).to have_http_status(:forbidden)
    end

    it 'fails to refresh git when the region misses git_owner role' do
      api_basic_authorize action_identifier(:automate_domains, :refresh_from_source)
      expect(GitBasedDomainImportService).to receive(:available?).and_return(false)

      post(api_automate_domain_url(nil, git_domain), :params => gen_request(:refresh_from_source))
      expect_bad_request('Git owner role is not enabled to be able to import git repositories')
    end

    context 'with proper git_owner role' do
      let(:non_git_domain) { FactoryBot.create(:miq_ae_domain) }
      before do
        expect(GitBasedDomainImportService).to receive(:available?).and_return(true)
      end

      it 'fails to refresh when domain did not originate from git' do
        api_basic_authorize action_identifier(:automate_domains, :refresh_from_source)

        post(api_automate_domain_url(nil, non_git_domain), :params => gen_request(:refresh_from_source))
        expect_bad_request(/Automate Domain .* did not originate from git repository/)
      end

      it 'refreshes domain from git_repository' do
        api_basic_authorize action_identifier(:automate_domains, :refresh_from_source)

        expect_any_instance_of(GitBasedDomainImportService).to receive(:queue_refresh_and_import)
        post(api_automate_domain_url(nil, git_domain), :params => gen_request(:refresh_from_source))
        expect_single_action_result(
          :success => true,
          :message => /Refreshing Automate Domain .* from git repository/,
          :href    => api_automate_domain_url(nil, git_domain)
        )
      end

      it 'refreshes domain from git_repository by domain name' do
        api_basic_authorize action_identifier(:automate_domains, :refresh_from_source)

        expect_any_instance_of(GitBasedDomainImportService).to receive(:queue_refresh_and_import)
        post(api_automate_domain_url(nil, git_domain.name), :params => gen_request(:refresh_from_source))
        expect_single_action_result(
          :success => true,
          :message => /Refreshing Automate Domain .* from git repository/,
          :href    => api_automate_domain_url(nil, git_domain.name)
        )
      end
    end
  end
end
