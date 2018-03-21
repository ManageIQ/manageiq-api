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
          ems_cluster = FactoryGirl.create(:ems_cluster)
          vm = FactoryGirl.create(:vm_openstack, :name => "foo", :ems_cluster => ems_cluster)

          request = {
            "action" => "validate_vms",
            "import" => [
              {"name" => vm.name, "uid" => vm.uid_ems},
              {"name" => "bad name", "uid" => "bad uid"}
            ]
          }
          post(api_transformation_mapping_url(nil, transformation_mapping), :params => request)

          expected = {
            "valid_vms"    => [a_hash_including("name" => "foo")],
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
    end
  end
end
