RSpec.describe Api::ActionsBuilder do
  let(:user) { instance_double('User') }
  let(:request) { instance_double('Api::RequestAdapter') }
  let(:config) { Api::CollectionConfig.new }
  let(:collection_config) do
    {
      :services => {
        :options                    => %i(collection),
        :verbs                      => %i(get put post patch delete),
        :klass                      => 'Service',
        :subcollections             => %i(tags vms),
        :collection_actions         => {
          :post => [
            {:name => 'create', :identifier => 'service_create'},
            {:name => 'edit', :identifier => 'service_edit'},
            {:name => 'delete', :identifier => 'service_delete'}
          ]
        },
        :resource_actions           => {
          :post   => [
            {:name => 'reconfigure', :identifier => 'service_reconfigure', :options => [:validate_action]},
            {:name => 'edit', :identifier => 'service_edit'}
          ],
          :delete => [
            {:name => 'delete', :identifier => 'service_delete'}
          ]
        },
        :tags_subcollection_actions => {
          :post => [
            {:name => 'assign', :identifier => 'service_tag'},
            {:name => 'unassign', :identifier => 'service_tag'}
          ]
        },
        :tags_subresource_actions   => {
          :post => [
            {:name => 'create', :identifier => 'tag_create'}
          ]
        }
      },
      :tags     => {
        :options => %i(subcollection),
        :verbs   => %i(get post delete)
      },
      :vms      => {
        :options               => %i(subcollection),
        :verbs                 => %i(post),
        :subcollection_actions => {
          :post => [
            {:name => 'restart', :identifier => 'vm_restart'}
          ]
        }
      }
    }
  end

  before do
    allow(Api::ApiConfig).to receive(:collections).and_return(collection_config)
  end

  describe '#actions' do
    context 'collections' do
      it 'returns the permitted collection actions' do
        allow(request).to receive(:subcollection).and_return(nil)
        allow(request).to receive(:collection).and_return('services')
        allow_user_roles('service_edit', 'service_create', 'service_delete')
        href = '/api/services'

        expected = [
          {'name' => 'create', 'method' => :post, 'href' => href},
          {'name' => 'edit', 'method' => :post, 'href' => href},
          {'name' => 'delete', 'method' => :post, 'href' => href}
        ]
        expect(described_class.new(request, href, :services, config, user).actions).to match(expected)
      end
    end

    context 'subcollections' do
      it 'returns the permitted subcollection actions defined under the collection' do
        allow(request).to receive(:subcollection).and_return('tags')
        allow(request).to receive(:collection).and_return('services')
        allow_user_roles('service_tag')
        href = '/api/services/:id/tags'

        expected = [
          {'name' => 'assign', 'method' => :post, 'href' => href},
          {'name' => 'unassign', 'method' => :post, 'href' => href}
        ]
        expect(described_class.new(request, href, :tags, config, user).actions).to match(expected)
      end

      it 'returns the permitted subcollection actions defined under the subcollection' do
        allow(request).to receive(:subcollection).and_return('vms')
        allow(request).to receive(:collection).and_return('services')
        allow_user_roles('vm_restart')
        href = '/api/services/:id/vms'

        expected = [
          {'name' => 'restart', 'method' => :post, 'href' => href}
        ]
        expect(described_class.new(request, href, :vms, config, user).actions).to match(expected)
      end
    end

    context 'resources' do
      let(:href) { '/api/services/:id' }
      let(:service) { instance_double(Service) }
      before do
        allow(request).to receive(:subcollection).and_return(nil)
        allow(request).to receive(:collection).and_return('services')
      end

      it 'returns the permitted resource actions' do
        allow(service).to receive(:validate_reconfigure).and_return(true)
        allow_user_roles('service_reconfigure', 'service_edit', 'service_delete')

        expected = [
          {'name' => 'reconfigure', 'method' => :post, 'href' => href},
          {'name' => 'edit', 'method' => :post, 'href' => href},
          {'name' => 'edit', 'method' => :patch, 'href' => href},
          {'name' => 'edit', 'method' => :put, 'href' => href},
          {'name' => 'delete', 'method' => :delete, 'href' => href}
        ]
        expect(described_class.new(request, href, :services, config, user, service).actions).to match(expected)
      end

      it 'only returns validated actions' do
        allow_user_roles('service_reconfigure', 'service_delete')
        action_builder = described_class.new(request, href, :services, config, user, service)

        allow(service).to receive(:validate_reconfigure).and_return(false)
        expect(action_builder.actions).to eq([{'name' => 'delete', 'method' => :delete, 'href' => href}])
      end

      it 'returns put and patch actions when specified' do
        allow_user_roles('service_edit')

        expected = [
          {'name' => 'edit', 'method' => :post, 'href' => href},
          {'name' => 'edit', 'method' => :patch, 'href' => href},
          {'name' => 'edit', 'method' => :put, 'href' => href}
        ]
        expect(described_class.new(request, href, :services, config, user, service).actions).to include(*expected)
      end
    end

    context 'subresources' do
      it 'returns the permitted subresource actions' do
        tag = instance_double('Tag')
        allow(request).to receive(:subcollection).and_return('tags')
        allow(request).to receive(:collection).and_return('services')
        allow_user_roles('tag_create')
        href = '/services/:id/tags/:id'

        expected = [
          {'name' => 'create', 'method' => :post, 'href' => href}
        ]
        expect(described_class.new(request, href, :tags, config, user, tag).actions).to match(expected)
      end
    end
  end

  def allow_user_roles(*identifiers)
    allow(user).to receive(:role_allows?) do |arg|
      identifiers.flatten.include?(arg[:identifier])
    end
  end
end
