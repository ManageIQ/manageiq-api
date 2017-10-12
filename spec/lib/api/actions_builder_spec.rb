RSpec.describe Api::ActionsBuilder do
  let(:role) { FactoryGirl.create(:miq_user_role) }
  let(:group) { FactoryGirl.create(:miq_group, :miq_user_role => role) }
  let(:user) { FactoryGirl.create(:user, :miq_groups => [group]) }
  let(:request) { instance_double(Api::BaseController::Parser::RequestAdapter) }

  before do
    User.current_user = user
  end

  describe '#collection_actions' do
    context 'collections' do
      it 'returns the permitted collection actions' do
        allow(request).to receive(:subcollection).and_return(nil)
        allow(request).to receive(:collection).and_return('services')
        update_user_roles('service_edit', 'service_create', 'service_delete', 'service_view')
        href = '/api/services'

        expected = [
          {'name' => 'query', 'method' => :post, 'href' => href},
          {'name' => 'create', 'method' => :post, 'href' => href},
          {'name' => 'edit', 'method' => :post, 'href' => href},
          {'name' => 'delete', 'method' => :post, 'href' => href},
          {'name' => 'add_resource', 'method' => :post, 'href' => href},
          {'name' => 'remove_all_resources', 'method' => :post, 'href' => href},
          {'name' => 'remove_resource', 'method' => :post, 'href' => href},
          {'name' => 'add_provider_vms', 'method' => :post, 'href' => href}
        ]
        expect(described_class.new(request, href, :services).actions).to match(expected)
      end
    end

    context 'subcollections' do
      it 'returns the permitted subcollection actions' do
        allow(request).to receive(:subcollection).and_return('tags')
        allow(request).to receive(:collection).and_return('services')
        update_user_roles('service_tag')
        href = '/api/services/:id/tags'

        expected = [
          {'name' => 'assign', 'method' => :post, 'href' => href},
          {'name' => 'unassign', 'method' => :post, 'href' => href}
        ]
        expect(described_class.new(request, href, :tags).actions).to match(expected)
      end
    end
  end

  describe '#resource_actions' do
    context 'resources' do
      let(:href) { '/api/services/:id' }
      let(:service) { instance_double(Service) }
      before do
        allow(request).to receive(:subcollection).and_return(nil)
        allow(request).to receive(:collection).and_return('services')
      end

      it 'returns the permitted resource actions' do
        update_user_roles('service_retire', 'service_admin')

        expected = [
          {'name' => 'retire', 'method' => :post, 'href' => href},
          {'name' => 'start', 'method' => :post, 'href' => href},
          {'name' => 'stop', 'method' => :post, 'href' => href},
          {'name' => 'suspend', 'method' => :post, 'href' => href}
        ]
        expect(described_class.new(request, href, :services, service).actions).to match(expected)
      end

      it 'only returns validated actions' do
        update_user_roles('service_reconfigure')
        action_builder = described_class.new(request, href, :services, service)

        allow(service).to receive(:validate_reconfigure).and_return(false)
        expect(action_builder.actions).to be_empty

        allow(service).to receive(:validate_reconfigure).and_return(true)
        expect(action_builder.actions).to eq([{'name' => 'reconfigure', 'method' => :post, 'href' => href }])
      end

      it 'returns put and patch actions when specified' do
        update_user_roles('service_edit')

        expected = [
          {'name' => 'edit', 'method' => :post, 'href' => href},
          {'name' => 'edit', 'method' => :patch, 'href' => href},
          {'name' => 'edit', 'method' => :put, 'href' => href}
        ]
        described_class.new(request, href, :services, service).actions
        expect(described_class.new(request, href, :services, service).actions).to include(*expected)
      end
    end

    context 'subresources' do
      it 'returns the permitted subresource actions' do
        snapshot = instance_double(Snapshot)
        allow(request).to receive(:subcollection).and_return('snapshots')
        allow(request).to receive(:collection).and_return('vms')
        update_user_roles('vm_snapshot_revert', 'vm_snapshot_delete')
        href = '/vms/:id/snapshots/:id'

        expected = [
          {'name' => 'revert', 'method' => :post, 'href' => href},
          {'name' => 'delete', 'method' => :post, 'href' => href},
          {'name' => 'delete', 'method' => :delete, 'href' => href}
        ]
        expect(described_class.new(request, href, :snapshots, snapshot).actions).to match(expected)
      end
    end
  end

  def update_user_roles(*identifiers)
    product_features = identifiers.flatten.collect do |identifier|
      MiqProductFeature.find_or_create_by(:identifier => identifier)
    end
    role.update_attributes!(:miq_product_features => product_features)
  end
end
