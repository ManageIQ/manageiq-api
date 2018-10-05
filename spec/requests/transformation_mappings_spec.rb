describe "Transformation Mappings" do
  let(:source_cluster) { FactoryGirl.create(:ems_cluster) }
  let(:destination_cluster) { FactoryGirl.create(:ems_cluster) }

  let(:source_storage) { FactoryGirl.create(:storage) }
  let(:destination_storage) { FactoryGirl.create(:storage) }

  let(:source_lan) { FactoryGirl.create(:lan) }
  let(:destination_lan) { FactoryGirl.create(:lan) }

  let(:transformation_mapping) do
    FactoryGirl.create(
      :transformation_mapping,
      :transformation_mapping_items => [
        TransformationMappingItem.new(:source => source_cluster, :destination => destination_cluster),
        TransformationMappingItem.new(:source => source_storage, :destination => destination_storage),
        TransformationMappingItem.new(:source => source_lan, :destination => destination_lan)
      ]
    )
  end

  let(:source_cluster2) { FactoryGirl.create(:ems_cluster) }
  let(:destination_cluster2) { FactoryGirl.create(:ems_cluster) }

  let(:source_storage2) { FactoryGirl.create(:storage) }
  let(:destination_storage2) { FactoryGirl.create(:storage) }

  let(:source_lan2) { FactoryGirl.create(:lan) }
  let(:destination_lan2) { FactoryGirl.create(:lan) }

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
        openstack = FactoryGirl.create(:ems_openstack)
        _flavor1  = openstack.flavors.create!(:cpus => 1, :memory => 1.gigabytes)
        flavor2   = openstack.flavors.create!(:cpus => 2, :memory => 2.gigabytes)
        flavor3   = openstack.flavors.create!(:cpus => 4, :memory => 4.gigabytes)
        vm1       = FactoryGirl.create(:vm_vmware, :hardware => FactoryGirl.create(:hardware, :cpu1x2, :ram1GB))
        vm2       = FactoryGirl.create(:vm_vmware, :hardware => FactoryGirl.create(:hardware, :cpu2x2, :ram1GB))
        vm3       = FactoryGirl.create(:vm_vmware, :hardware => FactoryGirl.create(:hardware, :cpu4x2, :ram1GB))

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
    let(:cluster) { FactoryGirl.create(:ems_cluster) }
    let(:cluster2) { FactoryGirl.create(:ems_cluster) }

    context "with an appropriate role" do
      it "can create a new transformation mapping" do
        api_basic_authorize(collection_action_identifier(:transformation_mappings, :create))

        new_mapping = {"name"                         => "new transformation mapping",
                       "transformation_mapping_items" => [
                         { "source" => api_cluster_url(nil, cluster), "destination" => api_cluster_url(nil, cluster2) }
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

        new_mapping = {"name" => "new transformation mapping", "transformation_mapping_items" => [{ "source" => "/api/bogus/:id", "destination" => api_cluster_url(nil, cluster2) }]}
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

        new_mapping = {"name" => "new transformation mapping", "transformation_mapping_items" => [{ "source" => api_cluster_url(nil, cluster2), "destination" => api_cluster_url(nil, 999_999) }]}
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
          ems = FactoryGirl.create(:ext_management_system)
          source_ems = FactoryGirl.create(:ems_cluster)
          destination_ems = FactoryGirl.create(:ems_cluster)
          transformation_mapping =
            FactoryGirl.create(:transformation_mapping,
                               :transformation_mapping_items => [TransformationMappingItem.new(:source => source_ems, :destination => destination_ems)])
          vm = FactoryGirl.create(:vm_openstack, :name => "foo", :ems_cluster => source_ems, :ext_management_system => ems)

          request = {
            "action" => "validate_vms",
            "import" => [
              {"name" => vm.name, "uid" => vm.uid_ems},
              {"name" => "bad name", "uid" => "bad uid"}
            ]
          }
          post(api_transformation_mapping_url(nil, transformation_mapping), :params => request)

          expected = {
            "valid"      => [a_hash_including("name" => vm.name, "id" => vm.id.to_s, "status" => "ok", "reason" => "ok", "cluster" => source_ems.name)],
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
              { "source" => api_cluster_url(nil, source_cluster), "destination" => api_cluster_url(nil, destination_cluster2) },
              { "source" => api_cluster_url(nil, source_cluster2), "destination" => api_cluster_url(nil, destination_cluster2) },
              { "source" => api_data_store_url(nil, source_storage), "destination" => api_data_store_url(nil, destination_storage) },
              { "source" => api_data_store_url(nil, source_storage2), "destination" => api_data_store_url(nil, destination_storage) },
              { "source" => api_lan_url(nil, source_lan2), "destination" => api_lan_url(nil, destination_lan) }
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
            source_ems = FactoryGirl.create(:ems_cluster)
            destination_ems = FactoryGirl.create(:ems_cluster)
            transformation_mapping =
              FactoryGirl.create(:transformation_mapping,
                                 :transformation_mapping_items => [TransformationMappingItem.new(:source => source_ems, :destination => destination_ems)])
            vm = FactoryGirl.create(:vm_vmware, :name => 'test_vm', :ems_cluster => source_ems, :ext_management_system => FactoryGirl.create(:ext_management_system))
            service_template = FactoryGirl.create(:service_template_transformation_plan)

            FactoryGirl.create(
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
              "valid"      => [a_hash_including("name" => vm.name, "id" => vm.id.to_s, "status" => "ok", "reason" => "ok", "cluster" => source_ems.name)],
              "invalid"    => [],
              "conflicted" => []
            }
            expect(response).to have_http_status(:ok)
            expect(response.parsed_body).to include(expected)
          end

          it "vm does not belong to the service_template record" do
            api_basic_authorize(action_identifier(:transformation_mappings, :validate_vms, :resource_actions, :post))
            source_ems = FactoryGirl.create(:ems_cluster)
            destination_ems = FactoryGirl.create(:ems_cluster)
            transformation_mapping =
              FactoryGirl.create(:transformation_mapping,
                                 :transformation_mapping_items => [TransformationMappingItem.new(:source => source_ems, :destination => destination_ems)])
            vm = FactoryGirl.create(:vm_vmware, :name => 'test_vm', :ems_cluster => source_ems, :ext_management_system => FactoryGirl.create(:ext_management_system))
            service_template = FactoryGirl.create(:service_template_transformation_plan)
            service_template2 = FactoryGirl.create(:service_template_transformation_plan)

            FactoryGirl.create(
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
              "invalid"    => [a_hash_including("name" => "test_vm", "reason" => "in_other_plan")],
              "conflicted" => []
            }
            expect(response).to have_http_status(:ok)
            expect(response.parsed_body).to include(expected)
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
