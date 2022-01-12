#
# Rest API Request Tests - Tenant Groups specs
#
describe "Tenant Groups API" do
  let(:tenant_group) { FactoryBot.create(:miq_group, :tenant_type, :description => 'lofasz') }
  let(:group) { FactoryBot.create(:miq_group, :description => 'picsa') }

  before do
    @user.miq_groups << group
    @user.miq_groups << tenant_group
    api_basic_authorize collection_action_identifier('groups', :read, :get)
  end

  describe 'GET /tenant_groups' do
    it 'displays the tenant group only' do
      get(api_tenant_groups_url)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["subcount"]).to eq(1)
      expect(response.parsed_body["resources"].first["href"]).to end_with(tenant_group.id.to_s)
    end
  end

  describe 'GET /tenant_groups/:id' do
    it 'returns with the tenant group' do
      get(api_tenant_group_url(nil, tenant_group.id))
      expect(response).to have_http_status(:ok)
    end

    context 'with a non-tenant group' do
      it 'returns with not found' do
        get(api_tenant_group_url(nil, group.id))
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
