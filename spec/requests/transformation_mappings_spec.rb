describe "Transformation Mappings" do
  let(:transformation_mapping) { FactoryGirl.create(:transformation_mapping) }

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
            "valid_vms"    => [a_hash_including("name" => vm.name, "id" => vm.id.to_s, "href" => a_string_including(api_vm_url(nil, vm)))],
            "invalid_vms"  => [a_hash_including("name" => "bad name")],
            "conflict_vms" => []
          }
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(expected)
        end

        it "can validate vms without csv data" do
          api_basic_authorize(action_identifier(:transformation_mappings, :validate_vms, :resource_actions, :post))

          post(api_transformation_mapping_url(nil, transformation_mapping), :params => {"action" => "validate_vms"})

          expect(response).to have_http_status(:ok)
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
