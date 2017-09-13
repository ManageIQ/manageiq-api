# frozen_string_literal: true

#
# REST API Request Tests - /api/container_images
#
describe "ContainerImages API" do
  let(:provider) { FactoryGirl.create(:ems_kubernetes) }
  let(:container_image) { FactoryGirl.create(:container_image, :ext_management_system => provider) }
  let(:conatiner_id) { container_image.id }
  let(:invalid_container_image) { container_image.id + 100 }
  let(:invalid_image_url) { api_provider_container_image_url(nil, provider, invalid_container_image) }

  context "ContainerImages show action" do
    it "read a Container Image" do
      api_basic_authorize(action_identifier(:container_images, :show, :subresource_actions, :get))
      get api_provider_container_image_url(nil, provider, container_image)

      expect(response).to have_http_status(:ok)
      expect_single_resource_query("id" => container_image.id.to_s)
    end
  end

  context "ContainerImages scan action" do
    it "responds with 404 Not Found for an invalid container image" do
      api_basic_authorize(action_identifier(:container_images, :scan, :subresource_actions, :post))

      post(invalid_image_url, :params => { :action => "scan" })

      expect(response).to have_http_status(:not_found)
    end

    it "scans a Container Image without appropriate role" do
      api_basic_authorize

      post(invalid_image_url, :params => { :action => "scan" })

      expect(response).to have_http_status(:forbidden)
    end

    it "scan a Container Image" do
      api_basic_authorize(action_identifier(:container_images, :scan, :subresource_actions, :post))
      url = api_provider_container_image_url(nil, provider, container_image)
      post url, :params => { :action => "scan" }

      expect_single_action_result(:success => true, :message => "ContainerImage id:#{container_image.id} name:'#{container_image.name}' scanning", :href => url, :task_id => true)
    end
  end
end
