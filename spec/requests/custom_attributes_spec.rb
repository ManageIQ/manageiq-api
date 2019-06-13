RSpec.describe "Custom Attributes API" do
  describe "GET /api/<collection>/:cid/custom_attributes/:sid" do
    it "renders the actions available on custom attribute members" do
      vm = FactoryBot.create(:vm_vmware)
      custom_attribute = FactoryBot.create(:custom_attribute, :resource => vm)
      api_basic_authorize

      get(api_vm_custom_attribute_url(nil, vm, custom_attribute))

      expected = {
        "actions" => a_collection_including(
          a_hash_including("name" => "edit", "method" => "post"),
          a_hash_including("name" => "delete", "method" => "post"),
          a_hash_including("name" => "delete", "method" => "delete")
        )
      }
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "POST /api/<collection>/:cid/custom_attributes/:sid" do
    it "does not duplicate a custom attribute" do
      ems = FactoryBot.create(:ems_vmware)
      custom_attribute = FactoryBot.create(:custom_attribute, :name => "foo", :value => "bar", :section => "metadata", :resource => ems)
      api_basic_authorize(subcollection_action_identifier(:providers, :custom_attributes, :add, :post))

      post(api_provider_custom_attributes_url(nil, ems), :params => {
             :action    => "add",
             :resources => [
               { "name" => "foo", "value" => "bar" }
             ]
           })

      expected = {
        "results" => [a_hash_including("id" => custom_attribute.id.to_s, "name" => "foo", "value" => "bar")]
      }
      expect(response.parsed_body).to include(expected)
    end
  end

  it "can delete a custom attribute through its nested URI" do
    vm = FactoryBot.create(:vm_vmware)
    custom_attribute = FactoryBot.create(:custom_attribute, :resource => vm)
    api_basic_authorize

    expect do
      delete(api_vm_custom_attribute_url(nil, vm, custom_attribute))
    end.to change(CustomAttribute, :count).by(-1)

    expect(response).to have_http_status(:no_content)
  end

  it 'returns the correct href' do
    provider = FactoryBot.create(:ems_vmware)
    custom_attribute = FactoryBot.create(:custom_attribute, :resource => provider, :name => 'foo', :value => 'bar')
    api_basic_authorize subcollection_action_identifier(:providers, :custom_attributes, :edit, :post)

    post(api_provider_custom_attribute_url(nil, provider, custom_attribute), :params => { :action => :edit, :name => 'name1' })

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['href']).to include(api_provider_custom_attribute_url(nil, provider, custom_attribute))
  end

  it 'returns a bad_request for invalid values of section' do
    vm = FactoryBot.create(:vm_vmware)
    api_basic_authorize subcollection_action_identifier(:vms, :custom_attributes, :add, :post)

    post(api_vm_custom_attributes_url(nil, vm), :params => { :action => :add, :resources => [{:section => "bad_section", :name => "test01", :value => "val01"}] })

    expected = {
      'error' => a_hash_including(
        'kind'    => 'bad_request',
        'message' => a_string_including('Invalid attribute section specified')
      )
    }
    expect(response.parsed_body).to include(expected)
    expect(response).to have_http_status(:bad_request)
  end

  it 'does not allow editing of custom attributes with incorrect values' do
    vm = FactoryBot.create(:vm_vmware)
    custom_attribute = FactoryBot.create(:custom_attribute, :resource => vm, :name => 'foo', :value => 'bar')
    api_basic_authorize subcollection_action_identifier(:vms, :custom_attributes, :edit, :post)

    post(api_vm_custom_attribute_url(nil, vm, custom_attribute), :params => { :action => :edit, :section => "bad_section", :name => "foo", :value => "bar" })

    expected = {
      'error' => a_hash_including(
        'kind'    => 'bad_request',
        'message' => a_string_including('Invalid attribute section specified')
      )
    }
    expect(response.parsed_body).to include(expected)
    expect(response).to have_http_status(:bad_request)
  end
end
