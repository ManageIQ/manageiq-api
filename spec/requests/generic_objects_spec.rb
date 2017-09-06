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

  end

  describe 'GET /api/generic_objects/:id' do
    before do
      object.widget = 'a widget string'
      object.is_something = true
      object.save!
    end

    it 'returns a generic object with property_attributes' do
      api_basic_authorize action_identifier(:generic_objects, :read, :resource_actions, :get)

      run_get(generic_objects_url(object.compressed_id))

      expected = {
        'name' => 'object 1',
        'property_attributes' => { 'widget' => 'a widget string', 'is_something' => true }
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/generic_objects' do
    it 'does not allow creation of a generic object without appropriate role' do
      api_basic_authorize

      run_post(generic_objects_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'can create a new generic object' do
      api_basic_authorize collection_action_identifier(:generic_objects, :create)

      generic_object = {
        'generic_object_definition' => { 'href' => generic_object_definitions_url(object_definition.compressed_id) },
        'name'                      => 'go_name1',
        'uid'                       => 'optional_uid',
        'property_attributes'       => {
          'widget'       => 'widget value',
          'is_something' => false
        },
        'associations'              => {
          'vms'      => [
            { 'href' => vms_url(vm.compressed_id) },
            { 'href' => vms_url(vm2.compressed_id) }
          ],
          'services' => [
            { 'href' => services_url(service.compressed_id) }
          ]
        }
      }
      run_post(generic_objects_url, generic_object)

      expected = {
        'results' => [
          a_hash_including('name'                         => 'go_name1',
                           'uid'                          => 'optional_uid',
                           'generic_object_definition_id' => object_definition.compressed_id)
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
