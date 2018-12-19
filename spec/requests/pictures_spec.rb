#
# Rest API Request Tests - Picture specs
#
# - Query picture and image_href of service_templates  /api/service_templates/:id?attributes=picture,picture.image_href
# - Query picture and image_href of services           /api/services/:id?attributes=picture,picture.image_href
# - Query picture and image_href of service_requests   /api/service_requests/:id?attributes=picture,picture.image_href
#
describe "Pictures" do
  # Valid base64 image
  let(:content) do
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABGdBTUEAALGP"\
      "C/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3Cc"\
      "ulE8AAAACXBIWXMAAAsTAAALEwEAmpwYAAABWWlUWHRYTUw6Y29tLmFkb2Jl"\
      "LnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIg"\
      "eDp4bXB0az0iWE1QIENvcmUgNS40LjAiPgogICA8cmRmOlJERiB4bWxuczpy"\
      "ZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1u"\
      "cyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAg"\
      "ICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYv"\
      "MS4wLyI+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3Jp"\
      "ZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpS"\
      "REY+CjwveDp4bXBtZXRhPgpMwidZAAAADUlEQVQIHWNgYGCwBQAAQgA+3N0+"\
      "xQAAAABJRU5ErkJggg=="
  end

  before do
    @picture = Picture.create_from_base64(:extension => "jpg", :content => content)
  end

  context "As an attribute" do
    let(:dialog1)  { FactoryBot.create(:dialog, :label => "ServiceDialog1") }
    let(:ra1)      { FactoryBot.create(:resource_action, :action => "Provision", :dialog => dialog1) }
    let(:template) do
      FactoryBot.create(:service_template,
                         :name             => "ServiceTemplate",
                         :resource_actions => [ra1],
                         :picture          => @picture)
    end
    let(:service) { FactoryBot.create(:service, :service_template_id => template.id) }
    let(:service_request) do
      FactoryBot.create(:service_template_provision_request,
                         :description => 'Service Request',
                         :requester   => @user,
                         :source_id   => template.id)
    end

    def expect_result_to_include_picture_href(source_id)
      expect_result_to_match_hash(response.parsed_body, "id" => source_id)
      expect_result_to_have_keys(%w(id href picture))
      expect_result_to_match_hash(response.parsed_body["picture"],
                                  "id"          => @picture.id.to_s,
                                  "resource_id" => template.id.to_s,
                                  "image_href"  => /^http:.*#{@picture.image_href}$/)
    end

    describe "Queries of Service Templates" do
      it "allows queries of the related picture and image_href" do
        api_basic_authorize action_identifier(:service_templates, :read, :resource_actions, :get)

        get api_service_template_url(nil, template), :params => { :attributes => "picture,picture.image_href" }

        expect_result_to_include_picture_href(template.id.to_s)
      end
    end

    describe "Queries of Services" do
      it "allows queries of the related picture and image_href" do
        api_basic_authorize action_identifier(:services, :read, :resource_actions, :get)

        get api_service_url(nil, service), :params => { :attributes => "picture,picture.image_href" }

        expect_result_to_include_picture_href(service.id.to_s)
      end
    end

    describe "Queries of Service Requests" do
      it "allows queries of the related picture and image_href" do
        api_basic_authorize action_identifier(:service_requests, :read, :resource_actions, :get)

        get api_service_request_url(nil, service_request), :params => { :attributes => "picture,picture.image_href" }

        expect_result_to_include_picture_href(service_request.id.to_s)
      end
    end
  end

  context 'As a collection' do
    describe 'GET /api/pictures' do
      it 'returns image_href, extension when resources are expanded' do
        api_basic_authorize

        expected = {
          'resources' => [
            a_hash_including('image_href' => a_string_including(@picture.image_href), 'extension' => @picture.extension)
          ]
        }
        get(api_pictures_url, :params => { :expand => 'resources' })

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it 'allows specifying of additional attributes' do
        api_basic_authorize

        expected = {
          'resources' => [
            a_hash_including('href_slug'     => @picture.href_slug,
                             'region_number' => @picture.region_number)
          ]
        }
        get(api_pictures_url, :params => { :expand => 'resources', :attributes => 'href_slug,region_number'})

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it 'only allows specifying of valid attributes' do
        api_basic_authorize

        get(api_pictures_url, :params => { :expand => 'resources', :attributes => 'bad_attr'})

        expect(response).to have_http_status(:bad_request)
      end
    end

    describe 'GET /api/pictures/:id' do
      it 'returns image_href, extension by default' do
        api_basic_authorize

        get(api_picture_url(nil, @picture))

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('image_href' => a_string_including(@picture.image_href), 'extension' => @picture.extension)
      end

      it 'allows specifying of additional attributes' do
        api_basic_authorize

        get(api_picture_url(nil, @picture), :params => { :attributes => 'href_slug,region_number' })

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('href_slug'     => @picture.href_slug,
                                                'region_number' => @picture.region_number)
      end

      it 'will return only the requested physical attribute with the set additional attributes' do
        api_basic_authorize

        get(api_picture_url(nil, @picture), :params => { :attributes => 'md5' })

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.keys).to match_array(%w(md5 href id extension image_href))
      end
    end

    describe 'POST /api/pictures' do
      it 'rejects create without an appropriate role' do
        api_basic_authorize

        post api_pictures_url, :params => { :extension => 'png', :content => content }

        expect(response).to have_http_status(:forbidden)
      end

      it 'creates a new picture' do
        api_basic_authorize collection_action_identifier(:pictures, :create)

        expected = {
          'results' => [a_hash_including('id', 'image_href')]
        }

        expect do
          post api_pictures_url, :params => { :extension => 'png', :content => content }
        end.to change(Picture, :count).by(1)
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it 'creates multiple pictures' do
        api_basic_authorize collection_action_identifier(:pictures, :create)

        expected = {
          'results' => [a_hash_including('id'), a_hash_including('id')]
        }

        expect do
          post(api_pictures_url, :params => gen_request(:create, [{:extension => 'png', :content => content},
                                                                  {:extension => 'jpg', :content => content}]))
        end.to change(Picture, :count).by(2)
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it 'requires an extension' do
        api_basic_authorize collection_action_identifier(:pictures, :create)

        post api_pictures_url, :params => { :content => content }

        expected = {
          'error' => a_hash_including(
            'message' => a_string_including("Extension can't be blank")
          )
        }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to include(expected)
      end

      it 'requires content' do
        api_basic_authorize collection_action_identifier(:pictures, :create)

        post api_pictures_url, :params => { :extension => 'png' }

        expected = {
          'error' => a_hash_including(
            'message' => a_string_including("Content can't be blank")
          )
        }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to include(expected)
      end

      it 'requires content with valid base64' do
        api_basic_authorize collection_action_identifier(:pictures, :create)

        post api_pictures_url, :params => { :content => 'not base64', :extension => 'png' }

        expected = {
          'error' => a_hash_including(
            'message' => a_string_including('invalid base64')
          )
        }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to include(expected)
      end
    end
  end
end
