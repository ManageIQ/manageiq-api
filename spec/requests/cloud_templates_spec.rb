RSpec.describe "Cloud Templates API" do
  describe "as a subcollection of providers" do
    it "can list images of a provider" do
      api_basic_authorize(action_identifier(:cloud_templates, :read, :subcollection_actions, :get))
      ems = FactoryBot.create(:ems_openstack)
      image = FactoryBot.create(:template_cloud, :ext_management_system => ems)

      get(api_provider_cloud_templates_url(nil, ems))

      expected = {
        "count"     => 1,
        "name"      => "cloud_templates",
        "resources" => [
          {"href" => api_provider_cloud_template_url(nil, ems, image)}
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "will not list images unless authorized" do
      api_basic_authorize
      ems = FactoryBot.create(:ems_openstack)
      FactoryBot.create(:template_cloud, :ext_management_system => ems)

      get(api_provider_cloud_templates_url(nil, ems))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/providers/:c_id/cloud_templates/:id" do
    it "can show a provider's image" do
      api_basic_authorize(action_identifier(:cloud_templates, :read, :subresource_actions, :get))
      ems = FactoryBot.create(:ems_openstack)
      image = FactoryBot.create(:template_cloud, :ext_management_system => ems)

      get(api_provider_cloud_template_url(nil, ems, image))

      expected = {
        "href" => api_provider_cloud_template_url(nil, ems, image),
        "id"   => image.id.to_s
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "will not show an image unless authorized" do
      api_basic_authorize
      ems = FactoryBot.create(:ems_openstack)
      image = FactoryBot.create(:template_cloud, :ext_management_system => ems)

      get(api_provider_cloud_template_url(nil, ems, image))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/providers/:c_id/cloud_templates" do
    it "can queue the creation of an images" do
      api_basic_authorize(action_identifier(:cloud_templates, :create, :subcollection_actions))
      ems = FactoryBot.create(:ems_cloud)

      post(api_provider_cloud_templates_url(nil, ems), :params => { :name => "test-image", :vendor => "test-cloud", :location => "test-location" })

      expected = {
        "results" => [
          a_hash_including(
            "success"   => true,
            "message"   => "Creating Image",
            "task_id"   => anything,
            "task_href" => a_string_matching(api_tasks_url)
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "will not create an image unless authorized" do
      api_basic_authorize
      ems = FactoryBot.create(:ems_cloud)

      post(api_provider_cloud_templates_url(nil, ems), :params => { :name => "test-image" })

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/providers/:c_id/cloud_templates/:id" do
    it "can queue the updating of an image" do
      ems = FactoryBot.create(:ems_cloud)
      image = FactoryBot.create(:template_cloud, :ext_management_system => ems)

      api_basic_authorize(action_identifier(:cloud_templates, :edit, :subresource_actions, :post))
      edited_name = "test-image"

      post(api_provider_cloud_template_url(nil, ems, image), :params => {:action => 'edit', :name => edited_name})

      expected = {
        'success' => true,
        'message' => a_string_including('Updating Image')
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can't queue the updating of an image unless authorized" do
      ems = FactoryBot.create(:ems_cloud)
      image = FactoryBot.create(:template_cloud, :ext_management_system => ems)

      api_basic_authorize
      edited_name = "test-image"

      post(api_provider_cloud_template_url(nil, ems, image), :params => gen_request(:edit, edited_name))
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/providers/:c_id/cloud_templates/:id" do
    it "can delete an image" do
      api_basic_authorize(action_identifier(:cloud_templates, :delete, :subresource_actions, :delete))
      ems = FactoryBot.create(:ems_openstack)
      image = FactoryBot.create(:template_cloud, :ext_management_system => ems)

      delete(api_provider_cloud_template_url(nil, ems, image))

      expect(response).to have_http_status(:no_content)
    end

    it "will not delete image unless authorized" do
      api_basic_authorize
      ems = FactoryBot.create(:ems_openstack)
      image = FactoryBot.create(:template_cloud, :ext_management_system => ems)

      delete(api_provider_cloud_template_url(nil, ems, image))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/providers/:c_id/cloud_templates/:id with delete action" do
    it "can delete an image" do
      ems = FactoryBot.create(:ems_openstack)
      image = FactoryBot.create(:template_openstack, :ext_management_system => ems)
      api_basic_authorize(action_identifier(:cloud_templates, :delete, :subresource_actions, :delete))

      post(api_provider_cloud_template_url(nil, ems, image), :params => gen_request(:delete))

      expected = {
        'success' => true,
        'message' => a_string_including('Deleting Image')
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "will not delete an image unless authorized" do
      ems = FactoryBot.create(:ems_openstack)
      image = FactoryBot.create(:template_openstack, :ext_management_system => ems)
      api_basic_authorize

      post(api_provider_cloud_template_url(nil, ems, image), :params => gen_request(:delete))

      expect(response).to have_http_status(:forbidden)
    end

    it "can delete multiple images" do
      ems = FactoryBot.create(:ems_openstack)
      image1, image2 = FactoryBot.create_list(:template_openstack, 2, :ext_management_system => ems)
      api_basic_authorize(action_identifier(:cloud_templates, :delete, :subresource_actions))

      post(
        api_provider_cloud_templates_url(nil, ems),
        :params => {
          :action    => "delete",
          :resources => [
            {:href => api_provider_cloud_template_url(nil, ems, image1)},
            {:href => api_provider_cloud_template_url(nil, ems, image2)}
          ]
        }
      )

      expect(response).to have_http_status(:ok)
    end

    it "will not delete multiple images unless authorized" do
      ems = FactoryBot.create(:ems_openstack)
      image1, image2 = FactoryBot.create_list(:template_openstack, 2, :ext_management_system => ems)
      api_basic_authorize

      post(
        api_provider_cloud_templates_url(nil, ems),
        :params => {
          :action    => "delete",
          :resources => [
            {:href => api_provider_cloud_template_url(nil, ems, image1)},
            {:href => api_provider_cloud_template_url(nil, ems, image2)}
          ]
        }
      )

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/cloud_templates with import action" do
    it "fails as user has no import action permissions" do
      api_basic_authorize

      src   = FactoryBot.create(:ems_cloud)
      dst   = FactoryBot.create(:ems_cloud)
      image = FactoryBot.create(:template, :ext_management_system => src)

      post(
        api_cloud_template_url(nil, ''),
        :params => {
          :action          => "import",
          :src_provider_id => src.id,
          :dst_provider_id => dst.id,
          :src_image_id    => image.id,
        }
      )

      expect(response).to have_http_status(:forbidden)
    end

    it "fails without src_provider_id" do
      api_basic_authorize(action_identifier(:cloud_templates, :import, :collection_actions))

      dst   = FactoryBot.create(:ems_cloud)
      image = FactoryBot.create(:template)

      post(
        api_cloud_template_url(nil, ''),
        :params => {
          :action          => "import",
          :dst_provider_id => dst.id,
          :src_image_id    => image.id,
        }
      )

      expect(response).to have_http_status(:bad_request)
    end

    it "fails without dst_provider_id" do
      api_basic_authorize(action_identifier(:cloud_templates, :import, :collection_actions))

      src   = FactoryBot.create(:ems_cloud)
      image = FactoryBot.create(:template)

      post(
        api_cloud_template_url(nil, ''),
        :params => {
          :action          => "import",
          :src_provider_id => src.id,
          :src_image_id    => image.id,
        }
      )

      expect(response).to have_http_status(:bad_request)
    end

    it "fails without src_image_id" do
      api_basic_authorize(action_identifier(:cloud_templates, :import, :collection_actions))

      src   = FactoryBot.create(:ems_cloud)
      dst   = FactoryBot.create(:ems_cloud)

      post(
        api_cloud_template_url(nil, ''),
        :params => {
          :action          => "import",
          :src_provider_id => src.id,
          :dst_provider_id => dst.id,
        }
      )

      expect(response).to have_http_status(:bad_request)
    end

    it "fails with not found src_provider_id" do
      api_basic_authorize(action_identifier(:cloud_templates, :import, :collection_actions))

      dst    = FactoryBot.create(:ems_cloud)
      image  = FactoryBot.create(:template)

      post(
        api_cloud_template_url(nil, ''),
        :params => {
          :action          => "import",
          :src_provider_id => -1,
          :dst_provider_id => dst.id,
          :src_image_id    => image.id,
        }
      )

      expect(response).to have_http_status(:bad_request)
    end

    it "fails with not found dst_provider_id" do
      api_basic_authorize(action_identifier(:cloud_templates, :import, :collection_actions))

      src   = FactoryBot.create(:ems_cloud)
      image = FactoryBot.create(:template)

      post(
        api_cloud_template_url(nil, ''),
        :params => {
          :action          => "import",
          :src_provider_id => src.id,
          :dst_provider_id => -1,
          :src_image_id    => image.id,
        }
      )

      expect(response).to have_http_status(:bad_request)
    end

    it "fails with not found src_image_id" do
      api_basic_authorize(action_identifier(:cloud_templates, :import, :collection_actions))

      src   = FactoryBot.create(:ems_cloud)
      dst   = FactoryBot.create(:ems_cloud)

      post(
        api_cloud_template_url(nil, ''),
        :params => {
          :action          => "import",
          :src_provider_id => src.id,
          :dst_provider_id => dst.id,
          :src_image_id    => -1,
        }
      )

      expect(response).to have_http_status(:bad_request)
    end

    it "fails as the image doesn't belong to the source manager" do
      api_basic_authorize(action_identifier(:cloud_templates, :import, :collection_actions))

      src   = FactoryBot.create(:ems_cloud)
      dst   = FactoryBot.create(:ems_cloud)
      image = FactoryBot.create(:template, :ext_management_system => dst)

      post(
        api_cloud_template_url(nil, ''),
        :params => {
          :action          => "import",
          :src_provider_id => src.id,
          :dst_provider_id => dst.id,
          :src_image_id    => image.id,
        }
      )

      expect(response).to have_http_status(:bad_request)
    end

    it "succeeds as required parameters present, resources exist and image belongs to source provider" do
      api_basic_authorize(action_identifier(:cloud_templates, :import, :collection_actions))

      src   = FactoryBot.create(:ems_cloud)
      dst   = FactoryBot.create(:ems_cloud)
      image = FactoryBot.create(:template, :ext_management_system => src)

      post(
        api_cloud_template_url(nil, ''),
        :params => {
          :action          => "import",
          :src_provider_id => src.id,
          :dst_provider_id => dst.id,
          :src_image_id    => image.id,
        }
      )

      expect(response).to have_http_status(:ok)
    end
  end

  it_behaves_like "a check compliance action", "cloud_template", :template_cloud, "Vm"
end
