RSpec.describe "Transformation Mappings", :v2v do
  let(:source_ems) { FactoryBot.create(:ems_vmware) }
  let(:source_clusters) { FactoryBot.create_list(:ems_cluster, 2, :ext_management_system => source_ems) }
  let(:source_hosts) { FactoryBot.create_list(:host_vmware, 1, :ems_cluster => source_clusters.first) }
  let(:source_storages) { FactoryBot.create_list(:storage, 2, :hosts => source_hosts) }
  let(:source_switches) { FactoryBot.create_list(:switch, 1, :hosts => source_hosts) }
  let(:source_lans) { FactoryBot.create_list(:lan, 2, :switch => source_switches.first) }

  let(:destination_ems) { FactoryBot.create(:ems_redhat) }
  let(:destination_clusters) { FactoryBot.create_list(:ems_cluster, 2, :ext_management_system => destination_ems) }
  let(:destination_hosts) { FactoryBot.create_list(:host_redhat, 1, :ems_cluster => destination_clusters.first) }
  let(:destination_storages) { FactoryBot.create_list(:storage, 2, :hosts => destination_hosts) }
  let(:destination_switches) { FactoryBot.create_list(:switch, 1, :hosts => destination_hosts) }
  let(:destination_lans) { FactoryBot.create_list(:lan, 2, :switch => destination_switches.first) }

  let(:transformation_mapping) { FactoryBot.create(:transformation_mapping) }

  let!(:transformation_mapping_item_cluster) do
    FactoryBot.create(
      :transformation_mapping_item,
      :source                 => source_clusters.first,
      :destination            => destination_clusters.first,
      :transformation_mapping => transformation_mapping
    )
  end

  let!(:transformation_mapping_item_storage) do
    FactoryBot.create(
      :transformation_mapping_item,
      :source                 => source_storages.first,
      :destination            => destination_storages.first,
      :transformation_mapping => transformation_mapping
    )
  end

  let!(:transformation_mapping_item_item) do
    FactoryBot.create(
      :transformation_mapping_item,
      :source                 => source_lans.first,
      :destination            => destination_lans.first,
      :transformation_mapping => transformation_mapping
    )
  end

  describe "GET /api/transformation_mappings" do
    context "with an appropriate role" do
      it "retrieves transformation mappings with an appropriate role" do
        api_basic_authorize(collection_action_identifier(:transformation_mappings, :read, :get))

        get(api_transformation_mappings_url)

        expect(response).to have_http_status(:ok)
      end
    end

    context "without an appropriate role" do
      it "is forbidden" do
        api_basic_authorize

        get(api_transformation_mappings_url)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /api/transformation_mappings/:id" do
    context "with an appropriate role" do
      it "returns the transformation mapping" do
        api_basic_authorize(action_identifier(:transformation_mappings, :read, :resource_actions, :get))

        get(api_transformation_mapping_url(nil, transformation_mapping))

        expect(response.parsed_body).to include('id' => transformation_mapping.id.to_s)
        expect(response).to have_http_status(:ok)
      end
    end

    context "without an appropriate role" do
      it "is forbidden" do
        api_basic_authorize
        get(api_transformation_mapping_url(nil, transformation_mapping))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/transformation_mappings/" do
    context "with an appropriate role" do
      def href_slug(obj)
        Api::Utils.build_href_slug(obj.class, obj.id)
      end

      it "can map vms to openstack flavors" do
        openstack = FactoryBot.create(:ems_openstack)
        _flavor1  = openstack.flavors.create!(:cpus => 1, :memory => 1.gigabytes)
        flavor2   = openstack.flavors.create!(:cpus => 2, :memory => 2.gigabytes)
        flavor3   = openstack.flavors.create!(:cpus => 4, :memory => 4.gigabytes)
        vm1       = FactoryBot.create(:vm_vmware, :hardware => FactoryBot.create(:hardware, :cpu1x2, :ram1GB))
        vm2       = FactoryBot.create(:vm_vmware, :hardware => FactoryBot.create(:hardware, :cpu2x2, :ram1GB))
        vm3       = FactoryBot.create(:vm_vmware, :hardware => FactoryBot.create(:hardware, :cpu4x2, :ram1GB))

        api_basic_authorize(action_identifier(:transformation_mappings, :vm_flavor_fit, :collection_actions))

        request = {
          "action"   => "vm_flavor_fit",
          "mappings" => [
            {"source_href_slug" => href_slug(vm1), "destination_href_slug" => href_slug(openstack)},
            {"source_href_slug" => href_slug(vm2), "destination_href_slug" => href_slug(openstack)},
            {"source_href_slug" => href_slug(vm3), "destination_href_slug" => href_slug(openstack)},
          ]
        }

        post(api_transformation_mappings_url, :params => request)

        expect(response.parsed_body["results"]).to match_array(
          [
            {"source_href_slug" => href_slug(vm1), "best_fit" => href_slug(flavor2), "all_fit" => [href_slug(flavor2), href_slug(flavor3)]},
            {"source_href_slug" => href_slug(vm2), "best_fit" => href_slug(flavor3), "all_fit" => [href_slug(flavor3)]},
            {"source_href_slug" => href_slug(vm3), "best_fit" => nil, "all_fit" => []},
          ]
        )
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /api/transformation_mappings" do
    context "with an appropriate role" do
      it "can create a new transformation mapping" do
        api_basic_authorize(collection_action_identifier(:transformation_mappings, :create))

        new_mapping = {"name"                         => "new transformation mapping",
                       "transformation_mapping_items" => [
                         { "source" => api_cluster_url(nil, source_clusters.first), "destination" => api_cluster_url(nil, destination_clusters.last) }
                       ]}
        post(api_transformation_mappings_url, :params => new_mapping)

        expected = {
          "results" => [a_hash_including("href" => a_string_including(api_transformation_mappings_url),
                                         "name" => "new transformation mapping")]
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will raise a bad request if mappings are not specified" do
        api_basic_authorize(collection_action_identifier(:transformation_mappings, :create))

        new_mapping = {"name" => "new transformation mapping"}
        post(api_transformation_mappings_url, :params => new_mapping)

        expected = {
          "error" => a_hash_including(
            "kind"    => "bad_request",
            "message" => /Must specify transformation_mapping_items/
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:bad_request)
      end

      it "will raise a bad request if source and destination are not specified for mappings" do
        api_basic_authorize(collection_action_identifier(:transformation_mappings, :create))

        new_mapping = {"name" => "new transformation mapping", "transformation_mapping_items" => [{}]}
        post(api_transformation_mappings_url, :params => new_mapping)

        expected = {
          "error" => a_hash_including(
            "kind"    => "bad_request",
            "message" => /Must specify source and destination hrefs/
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:bad_request)
      end

      it "will raise a bad request for a bad source or destination" do
        api_basic_authorize(collection_action_identifier(:transformation_mappings, :create))

        new_mapping = {"name" => "new transformation mapping", "transformation_mapping_items" => [{ "source" => "/api/bogus/:id", "destination" => api_cluster_url(nil, source_clusters.last) }]}
        post(api_transformation_mappings_url, :params => new_mapping)

        expected = {
          "error" => a_hash_including(
            "kind"    => "bad_request",
            "message" => /Invalid source or destination type bogus/
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:bad_request)
      end

      it "will raise a bad request for a nonexistent source or destination" do
        api_basic_authorize(collection_action_identifier(:transformation_mappings, :create))

        new_mapping = {"name" => "new transformation mapping", "transformation_mapping_items" => [{ "source" => api_cluster_url(nil, source_clusters.last), "destination" => api_cluster_url(nil, 999_999) }]}
        post(api_transformation_mappings_url, :params => new_mapping)

        expected = {
          "error" => a_hash_including(
            "kind"    => "bad_request",
            "message" => /Couldn't find EmsCluster with 'id'=999999/
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:bad_request)
      end

      it 'can delete a transformation mapping by id' do
        api_basic_authorize action_identifier(:transformation_mappings, :delete)

        post(api_transformation_mapping_url(nil, transformation_mapping), :params => { :action => 'delete' })

        expect(response).to have_http_status(:ok)
      end

      it 'can delete transformation mapping in bulk by id' do
        api_basic_authorize collection_action_identifier(:transformation_mappings, :delete)

        request = {
          'action'    => 'delete',
          'resources' => [
            { 'id' => transformation_mapping.id.to_s}
          ]
        }
        post(api_transformation_mappings_url, :params => request)

        expected = {
          'results' => a_collection_including(
            a_hash_including('success' => true, 'message' => "transformation_mappings id: #{transformation_mapping.id} deleting")
          )
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end

    context "without an appropriate role" do
      it "is forbidden" do
        api_basic_authorize

        get(api_transformation_mapping_url(nil, transformation_mapping))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "POST /api/transformation_mappings/:id" do
      context "with an appropriate role" do
        it "can validate vms with csv data specified" do
          api_basic_authorize(action_identifier(:transformation_mappings, :validate_vms, :resource_actions, :post))
          transformation_mapping = FactoryBot.create(:transformation_mapping)

          FactoryBot.create(
            :transformation_mapping_item,
            :source                 => source_clusters.first,
            :destination            => destination_clusters.first,
            :transformation_mapping => transformation_mapping
          )

          vm = FactoryBot.create(
            :vm_openstack,
            :name                  => "foo",
            :ems_cluster           => source_clusters.first,
            :ext_management_system => source_ems
          )

          request = {
            "action" => "validate_vms",
            "import" => [
              {"name" => vm.name, "uid" => vm.uid_ems},
              {"name" => "bad name", "uid" => "bad uid"}
            ]
          }
          post(api_transformation_mapping_url(nil, transformation_mapping), :params => request)

          expected = {
            "valid"      => [a_hash_including("name" => vm.name, "id" => vm.id.to_s, "status" => "ok", "reason" => "ok", "cluster" => source_clusters.first.name)],
            "invalid"    => [a_hash_including("name" => "bad name")],
            "conflicted" => []
          }
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(expected)
        end

        it "can validate vms without csv data" do
          api_basic_authorize(action_identifier(:transformation_mappings, :validate_vms, :resource_actions, :post))

          post(api_transformation_mapping_url(nil, transformation_mapping), :params => {"action" => "validate_vms"})

          expect(response).to have_http_status(:ok)
        end

        it "can update a transformation mapping" do
          api_basic_authorize(action_identifier(:transformation_mappings, :edit, :resource_actions))

          request = {
            'action'                       => "edit",
            "name"                         => "updated transformation mapping",
            "transformation_mapping_items" => [
              { "source" => api_cluster_url(nil, source_clusters.first), "destination" => api_cluster_url(nil, destination_clusters.first) },
              { "source" => api_cluster_url(nil, source_clusters.last), "destination" => api_cluster_url(nil, destination_clusters.last) },
              { "source" => api_data_store_url(nil, source_storages.first), "destination" => api_data_store_url(nil, destination_storages.first) },
              { "source" => api_data_store_url(nil, source_storages.last), "destination" => api_data_store_url(nil, destination_storages.last) },
              { "source" => api_lan_url(nil, source_lans.last), "destination" => api_lan_url(nil, destination_lans.first) }
            ]
          }

          post(api_transformation_mapping_url(nil, transformation_mapping), :params => request)

          updated_mapping_source = transformation_mapping.reload.transformation_mapping_items.pluck(:source_id)
          reference_source = TransformationMappingItem.all.pluck(:source_id)

          updated_mapping_destination = transformation_mapping.reload.transformation_mapping_items.pluck(:destination_id)
          reference_destination = TransformationMappingItem.all.pluck(:destination_id)

          expected = {"name" => "updated transformation mapping"}
          expect(response.parsed_body).to include(expected)
          expect(response).to have_http_status(:ok)
          expect(updated_mapping_source).to match_array(reference_source)
          expect(updated_mapping_destination).to match_array(reference_destination)
          expect(transformation_mapping.transformation_mapping_items.count).to eq(TransformationMappingItem.all.count)
        end

        context "can validate vms with csv data and service_template_id are specified" do
          it "vm belongs to the service_template record" do
            api_basic_authorize(action_identifier(:transformation_mappings, :validate_vms, :resource_actions, :post))

            transformation_mapping = FactoryBot.create(:transformation_mapping)

            FactoryBot.create(
              :transformation_mapping_item,
              :source                 => source_clusters.first,
              :destination            => destination_clusters.first,
              :transformation_mapping => transformation_mapping
            )

            vm = FactoryBot.create(:vm_vmware, :ems_cluster => source_clusters.first, :ext_management_system => source_ems)
            service_template = FactoryBot.create(:service_template_transformation_plan)

            FactoryBot.create(
              :service_resource,
              :resource         => vm,
              :service_template => service_template,
              :status           => "Active"
            )

            request = {
              "action"              => "validate_vms",
              "import"              => [
                {"name" => vm.name, "uid" => vm.uid_ems}
              ],
              "service_template_id" => service_template.id.to_s
            }
            post(api_transformation_mapping_url(nil, transformation_mapping), :params => request)

            expected = {
              "valid"      => [a_hash_including("name" => vm.name, "id" => vm.id.to_s, "status" => "ok", "reason" => "ok", "cluster" => source_clusters.first.name)],
              "invalid"    => [],
              "conflicted" => []
            }
            expect(response).to have_http_status(:ok)
            expect(response.parsed_body).to include(expected)
          end

          it "vm does not belong to the service_template record" do
            api_basic_authorize(action_identifier(:transformation_mappings, :validate_vms, :resource_actions, :post))
            transformation_mapping = FactoryBot.create(:transformation_mapping)

            FactoryBot.create(
              :transformation_mapping_item,
              :source                 => source_clusters.first,
              :destination            => destination_clusters.first,
              :transformation_mapping => transformation_mapping
            )

            vm = FactoryBot.create(:vm_vmware, :ems_cluster => source_clusters.first, :ext_management_system => source_ems)
            service_template = FactoryBot.create(:service_template_transformation_plan)
            service_template2 = FactoryBot.create(:service_template_transformation_plan)

            FactoryBot.create(
              :service_resource,
              :resource         => vm,
              :service_template => service_template,
              :status           => "Active"
            )

            request = {
              "action"              => "validate_vms",
              "import"              => [
                {"name" => vm.name, "uid" => vm.uid_ems}
              ],
              "service_template_id" => service_template2.id.to_s
            }
            post(api_transformation_mapping_url(nil, transformation_mapping), :params => request)

            expected = {
              "valid"      => [],
              "invalid"    => [a_hash_including("name" => vm.name, "reason" => "in_other_plan")],
              "conflicted" => []
            }
            expect(response).to have_http_status(:ok)
            expect(response.parsed_body).to include(expected)
          end
        end

        context "add_mapping_item" do
          it "can add transformation mapping item" do
            api_basic_authorize(action_identifier(:transformation_mappings, :add_mapping_item, :resource_actions, :post))
            transformation_mapping = FactoryBot.create(:transformation_mapping)
            request = {
              'action'   => 'add_mapping_item',
              'resource' => {'source' => api_cluster_url(nil, source_clusters.first), 'destination' => api_cluster_url(nil, destination_clusters.first)}
            }
            post(api_transformation_mapping_url(nil, transformation_mapping), :params => request)
            expect(response).to have_http_status(:ok)
            expect(transformation_mapping.transformation_mapping_items.length).to eq(1)
          end
        end
      end
    end

    context "without an appropriate role" do
      it "cannot validate vms" do
        api_basic_authorize

        post(api_transformation_mapping_url(nil, transformation_mapping), :params => {"action" => "validate_vms"})

        expect(response).to have_http_status(:forbidden)
      end

      it "cannot delete transformation mappings" do
        api_basic_authorize

        post(api_transformation_mapping_url(nil, transformation_mapping), :params => {"action" => "delete"})

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'DELETE /api/transformation_mappings/:id' do
      it 'can delete a transformation mapping by id' do
        api_basic_authorize action_identifier(:transformation_mappings, :delete, :resource_actions, :delete)

        delete(api_transformation_mapping_url(nil, transformation_mapping))

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
