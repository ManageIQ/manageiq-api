RSpec.describe "hosts API" do
  describe "editing a host's password" do
    context "with an appropriate role" do
      it "can edit the password on a host" do
        host = FactoryBot.create(:host_with_authentication)
        api_basic_authorize action_identifier(:hosts, :edit)
        options = {:credentials => {:authtype => "default", :password => "abc123"}}

        expect do
          post api_host_url(nil, host), :params => gen_request(:edit, options)
        end.to change { host.reload.authentication_password(:default) }.to("abc123")
        expect(response).to have_http_status(:ok)
      end

      it "will update the default authentication if no type is given" do
        host = FactoryBot.create(:host_with_authentication)
        api_basic_authorize action_identifier(:hosts, :edit)
        options = {:credentials => {:password => "abc123"}}

        expect do
          post api_host_url(nil, host), :params => gen_request(:edit, options)
        end.to change { host.reload.authentication_password(:default) }.to("abc123")
        expect(response).to have_http_status(:ok)
      end

      it "can edit the password on a host without creating duplicate keys" do
        host = FactoryBot.create(:host)
        api_basic_authorize action_identifier(:hosts, :edit)
        options = { :credentials => { 'userid' => "I'm", 'password' => 'abc123' } }

        expect do
          post api_host_url(nil, host), :params => gen_request(:edit, options)
        end.to change { host.reload.authentication_password(:default) }.to('abc123')
        expect(response).to have_http_status(:ok)
      end

      it "sending non-credentials attributes will result in a bad request error" do
        host = FactoryBot.create(:host_with_authentication)
        api_basic_authorize action_identifier(:hosts, :edit)
        options = {:name => "new name"}

        expect do
          post api_host_url(nil, host), :params => gen_request(:edit, options)
        end.not_to change { host.reload.name }
        expect(response).to have_http_status(:bad_request)
      end

      it "can update passwords on multiple hosts by href" do
        host1 = FactoryBot.create(:host_with_authentication)
        host2 = FactoryBot.create(:host_with_authentication)
        api_basic_authorize action_identifier(:hosts, :edit)
        options = [
          {:href => api_host_url(nil, host1), :credentials => {:password => "abc123"}},
          {:href => api_host_url(nil, host2), :credentials => {:password => "def456"}}
        ]

        post api_hosts_url, :params => gen_request(:edit, options)
        expect(response).to have_http_status(:ok)
        expect(host1.reload.authentication_password(:default)).to eq("abc123")
        expect(host2.reload.authentication_password(:default)).to eq("def456")
      end

      it "can update passwords on multiple hosts by id" do
        host1 = FactoryBot.create(:host_with_authentication)
        host2 = FactoryBot.create(:host_with_authentication)
        api_basic_authorize action_identifier(:hosts, :edit)
        options = [
          {:id => host1.id, :credentials => {:password => "abc123"}},
          {:id => host2.id, :credentials => {:password => "def456"}}
        ]

        post api_hosts_url, :params => gen_request(:edit, options)
        expect(response).to have_http_status(:ok)
        expect(host1.reload.authentication_password(:default)).to eq("abc123")
        expect(host2.reload.authentication_password(:default)).to eq("def456")
      end
    end

    context "without an appropriate role" do
      it "cannot edit the password on a host" do
        host = FactoryBot.create(:host_with_authentication)
        api_basic_authorize
        options = {:credentials => {:authtype => "default", :password => "abc123"}}

        expect do
          post api_host_url(nil, host), :params => gen_request(:edit, options)
        end.not_to change { host.reload.authentication_password(:default) }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'Lans subcollection' do
      let(:lan) { FactoryBot.create(:lan) }
      let(:switch) { FactoryBot.create(:switch, :lans => [lan]) }
      let(:host) { FactoryBot.create(:host, :switches => [switch]) }

      context 'GET /api/hosts/:id/lans' do
        it 'returns the lans with an appropriate role' do
          api_basic_authorize(collection_action_identifier(:hosts, :read, :get))

          expected = {
            'resources' => [{'href' => api_host_lan_url(nil, host, lan)}]
          }
          get(api_host_lans_url(nil, host))

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(expected)
        end

        it 'does not return the lans without an appropriate role' do
          api_basic_authorize

          get(api_host_lans_url(nil, host))

          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'GET /api/hosts/:id/lans/:s_id' do
        it 'returns the lan with an appropriate role' do
          api_basic_authorize action_identifier(:hosts, :read, :resource_actions, :get)

          get(api_host_lan_url(nil, host, lan))

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include('id' => lan.id.to_s)
        end

        it 'does not return the lans without an appropriate role' do
          api_basic_authorize

          get(api_host_lan_url(nil, host, lan))

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
