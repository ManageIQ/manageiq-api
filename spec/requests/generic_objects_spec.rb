RSpec.describe 'GenericObjects API' do
  let(:object_definition) { FactoryGirl.create(:generic_object_definition, :name => 'object def') }
  let(:vm) { FactoryGirl.create(:vm_amazon) }
  let(:vm2) { FactoryGirl.create(:vm_amazon) }
  let(:service) { FactoryGirl.create(:service) }
  let(:object) { FactoryGirl.create(:generic_object, :name => 'object 1', :generic_object_definition => object_definition) }

  before do
    object_definition.add_property_attribute('widget', 'string')
    object_definition.add_property_attribute('is_something', 'boolean')

    object_definition.add_property_association('services', 'Service')
    object_definition.add_property_association('vms', 'Vm')

    object_definition.add_property_method('method_a')
    object_definition.add_property_method('method_b')
  end

  describe 'GET /api/generic_objects' do
    it 'will return all generic objects' do
      object = FactoryGirl.create(:generic_object, :generic_object_definition => object_definition)
      api_basic_authorize collection_action_identifier(:generic_objects, :read, :get)

      get(api_generic_objects_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'generic_objects',
        'resources' => [
          a_hash_including('href' => api_generic_object_url(nil, object))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'allows specifying attributes' do
      object = FactoryGirl.create(:generic_object, :generic_object_definition => object_definition)
      object.add_to_property_association('vms', [vm, vm2])
      object.add_to_property_association('services', service)
      api_basic_authorize collection_action_identifier(:generic_objects, :read, :get)

      get(api_generic_objects_url, :params => {:expand => 'resources', :associations => 'vms,services'})

      expected = {
        'resources' => [
          a_hash_including(
            'id'                  => object.id.to_s,
            'property_attributes' => {},
            'vms'                 => a_collection_including(a_hash_including('id' => vm.id.to_s), a_hash_including('id' => vm2.id.to_s)),
            'services'            => [a_hash_including('id' => service.id.to_s)]
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'GET /api/generic_objects/:id' do
    before do
      object.widget = 'a widget string'
      object.is_something = true
      object.save!

      object.add_to_property_association('vms', [vm, vm2])
      object.add_to_property_association('services', service)
    end

    it 'returns a generic object with property_attributes and custom method actions' do
      api_basic_authorize action_identifier(:generic_objects, :read, :resource_actions, :get),
                          action_identifier(:generic_objects, :delete, :resource_actions, :delete)

      get(api_generic_object_url(nil, object))

      expected = {
        'name'                => 'object 1',
        'property_attributes' => { 'widget' => 'a widget string', 'is_something' => true },
        'actions'             => a_collection_including(
          { 'name' => 'delete', 'method' => 'post', 'href' => api_generic_object_url(nil, object)},
          { 'name' => 'method_a', 'method' => 'post', 'href' => api_generic_object_url(nil, object)},
          { 'name' => 'method_b', 'method' => 'post', 'href' => api_generic_object_url(nil, object) }
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'allows specification of property_associations and returns them accordingly' do
      api_basic_authorize action_identifier(:generic_objects, :read, :resource_actions, :get)

      get(api_generic_object_url(nil, object), :params => {:associations => 'vms,services'})

      expected = {
        'name'                => 'object 1',
        'property_attributes' => { 'widget' => 'a widget string', 'is_something' => true },
        'services'            => a_collection_containing_exactly(a_hash_including('href' => api_service_url(nil, service), 'id' => service.id.to_s)),
        'vms'                 => a_collection_containing_exactly(
          a_hash_including('href' => api_instance_url(nil, vm), 'id' => vm.id.to_s),
          a_hash_including('href' => api_instance_url(nil, vm2), 'id' => vm2.id.to_s)
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "includes the hrefs for custom buttons and button groups" do
      generic_no_group = FactoryGirl.create(:custom_button, :name => "generic_no_group", :applies_to_class => "GenericObject")
      generic_group = FactoryGirl.create(:custom_button, :name => "generic_group", :applies_to_class => "GenericObject")
      generic_group_set = FactoryBot.create(:custom_button_set, :name => "generic_group_set", :set_data => {:applies_to_class => "GenericObject", :button_order => [generic_group.id]})
      assigned_no_group = FactoryGirl.create(
        :custom_button,
        :name             => "assigned_no_group",
        :applies_to_class => "GenericObjectDefinition",
        :applies_to_id    => object_definition.id
      )
      assigned_group = FactoryGirl.create(
        :custom_button,
        :name             => "assigned_group",
        :applies_to_class => "GenericObjectDefinition",
        :applies_to_id    => object_definition.id
      )
      assigned_group_set = FactoryBot.create(:custom_button_set, :name => "assigned_group_set", :set_data => {:applies_to_class => "GenericObject", :button_order => [assigned_group.id]})
      object_definition.update(:custom_button_sets => [assigned_group_set])
      api_basic_authorize action_identifier(:generic_objects, :read, :resource_actions, :get)

      get(api_generic_object_url(nil, object), :params => {:attributes => "custom_actions"})

      expected = {
        "custom_actions" => a_hash_including(
          "buttons"       => a_collection_containing_exactly(
            a_hash_including("href" => api_custom_button_url(nil, assigned_no_group)),
            a_hash_including("href" => api_custom_button_url(nil, generic_no_group))
          ),
          "button_groups" => a_collection_containing_exactly(
            a_hash_including(
              "href"    => api_custom_button_set_url(nil, generic_group_set),
              "buttons" => a_collection_containing_exactly(
                a_hash_including("href" => api_custom_button_url(nil, generic_group))
              )
            ),
            a_hash_including(
              "href"    => api_custom_button_set_url(nil, assigned_group_set),
              "buttons" => a_collection_containing_exactly(
                a_hash_including("href" => api_custom_button_url(nil, assigned_group))
              )
            )
          )
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/generic_objects' do
    it 'does not allow creation of a generic object without appropriate role' do
      api_basic_authorize

      post(api_generic_objects_url, :params => {})

      expect(response).to have_http_status(:forbidden)
    end

    it 'can create a new generic object' do
      api_basic_authorize collection_action_identifier(:generic_objects, :create)

      generic_object = {
        'generic_object_definition' => { 'href' => api_generic_object_definition_url(nil, object_definition) },
        'name'                      => 'go_name1',
        'uid'                       => 'optional_uid',
        'property_attributes'       => {
          'widget'       => 'widget value',
          'is_something' => false
        },
        'associations'              => {
          'vms'      => [
            { 'href' => api_vm_url(nil, vm) },
            { 'href' => api_vm_url(nil, vm2) }
          ],
          'services' => [
            { 'href' => api_service_url(nil, service) }
          ]
        }
      }
      post(api_generic_objects_url, :params => generic_object)

      expected = {
        'results' => [
          a_hash_including('name'                         => 'go_name1',
                           'uid'                          => 'optional_uid',
                           'generic_object_definition_id' => object_definition.id.to_s)
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will raise an error if invalid associations are specified on create' do
      api_basic_authorize collection_action_identifier(:generic_objects, :create)

      generic_object = {
        'generic_object_definition' => { 'href' => api_generic_object_definition_url(nil, object_definition) },
        'name'                      => 'go_name1',
        'uid'                       => 'optional_uid',
        'property_attributes'       => {
          'widget'       => 'widget value',
          'is_something' => false
        },
        'associations'              => {
          'not_an_association' => [
            { 'href' => api_vm_url(nil, vm) },
            { 'href' => api_vm_url(nil, vm2) }
          ],
          'services'           => [
            { 'href' => api_service_url(nil, service) }
          ]
        }
      }
      expect do
        post(api_generic_objects_url, :params => generic_object)
      end.to_not change(GenericObject, :count)

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => a_string_including('Invalid associations not_an_association')
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'can edit a generic object' do
      api_basic_authorize collection_action_identifier(:generic_objects, :edit)

      request = {
        'action'    => 'edit',
        'resources' => [
          { 'href' => api_generic_object_url(nil, object), 'name' => 'updated name', 'property_attributes' => {'widget' => 'updated widget'} }
        ]
      }
      post(api_generic_objects_url, :params => request)

      expected = {
        'results' => [
          a_hash_including('id' => object.id.to_s, 'name' => 'updated name')
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will raise an error if invalid associations are specified on edit' do
      api_basic_authorize collection_action_identifier(:generic_objects, :edit)

      request = {
        'action'    => 'edit',
        'resources' => [
          { 'href' => api_generic_object_url(nil, object), 'associations' => { 'not_an_association' => {}} }
        ]
      }
      post(api_generic_objects_url, :params => request)

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => a_string_including('Invalid associations not_an_association')
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'can delete a generic object' do
      api_basic_authorize collection_action_identifier(:generic_objects, :delete)

      request = {
        'action'    => 'delete',
        'resources' => [
          { 'href' => api_generic_object_url(nil, object) }
        ]
      }
      post(api_generic_objects_url, :params => request)

      expected = {
        'results' => [a_hash_including('success' => true, 'message' => a_string_including('deleting'))]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/generic_objects/:id' do
    it 'edits a generic object' do
      vm3 = FactoryGirl.create(:vm_amazon)
      api_basic_authorize action_identifier(:generic_objects, :edit)

      request = {
        'action'   => 'edit',
        'resource' => {
          'name'                => 'updated object',
          'property_attributes' => {
            'widget'       => 'updated widget val',
            'is_something' => false
          },
          'associations'        => {
            'vms'      => [{'href' => api_vm_url(nil, vm3)}],
            'services' => []
          }
        }
      }
      post(api_generic_object_url(nil, object), :params => request)

      expected = {
        'name'                => 'updated object',
        'property_attributes' => {
          'widget'       => 'updated widget val',
          'is_something' => false
        }
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
      expect(object.reload.services).to be_empty
      expect(object.vms).to eq([vm3])
    end

    it 'deletes a generic object' do
      api_basic_authorize action_identifier(:generic_objects, :delete)

      post(api_generic_object_url(nil, object), :params => { :action => 'delete' })

      expected = {
        'success' => true,
        'message' => a_string_including("generic_objects id: #{object.id} deleting")
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can call a custom action on a generic object' do
      api_basic_authorize

      post(api_generic_object_url(nil, object), :params => { :action => 'method_a' })

      expected = {
        'success'   => true,
        'message'   => "Invoked method #{object.generic_object_definition.name}#method_a for Generic Object id: #{object.id} name: #{object.name}",
        'task_href' => a_string_including(api_tasks_url)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'DELETE /api/generic_objects/:id' do
    it 'can delete a generic object' do
      api_basic_authorize action_identifier(:generic_objects, :delete, :resource_actions, :delete)

      delete(api_generic_object_url(nil, object))

      expect(response).to have_http_status(:no_content)
    end
  end
end
