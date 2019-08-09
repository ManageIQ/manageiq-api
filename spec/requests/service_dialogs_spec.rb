#
# REST API Request Tests - Service Dialogs specs
#
# - Refresh dialog fields       /api/service_dialogs/:id "refresh_dialog_fields"
#
describe "Service Dialogs API" do
  let(:dialog1)    { FactoryBot.create(:dialog, :label => "ServiceDialog1") }
  let(:dialog2)    { FactoryBot.create(:dialog, :label => "ServiceDialog2") }

  let(:ra1)        { FactoryBot.create(:resource_action, :dialog => dialog1) }
  let(:ra2)        { FactoryBot.create(:resource_action, :dialog => dialog2) }

  let(:template)   { FactoryBot.create(:service_template, :name => "ServiceTemplate") }
  let(:service)    { FactoryBot.create(:service, :name => "Service1") }

  context "Service Dialogs collection" do
    before { template.resource_actions = [ra1, ra2] }

    it "query only returns href" do
      api_basic_authorize collection_action_identifier(:service_dialogs, :read, :get)
      get api_service_dialogs_url

      expected = {
        "name"      => "service_dialogs",
        "count"     => Dialog.count,
        "subcount"  => Dialog.count,
        "resources" => Array.new(Dialog.count) { {"href" => anything} }
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "allows read of service dialogs with the service catalog provision role" do
      api_basic_authorize("svc_catalog_provision")

      get api_service_dialogs_url

      expect(response).to have_http_status(:ok)
    end

    it "allows read of a single service dialog with the service catalog provision role" do
      api_basic_authorize("svc_catalog_provision")

      get api_service_dialog_url(nil, dialog1)

      expect(response).to have_http_status(:ok)
    end

    it "query with expanded resources to include content" do
      api_basic_authorize collection_action_identifier(:service_dialogs, :read, :get)
      get api_service_dialogs_url, :params => { :expand => "resources" }

      expect_query_result(:service_dialogs, Dialog.count, Dialog.count)
      expect_result_resources_to_include_keys("resources", %w(id href label content))
    end

    it "query single dialog to include content" do
      api_basic_authorize action_identifier(:service_dialogs, :read, :resource_actions, :get)
      get api_service_dialog_url(nil, dialog1)

      expect_single_resource_query(
        "id"    => dialog1.id.to_s,
        "href"  => api_service_dialog_url(nil, dialog1),
        "label" => dialog1.label
      )
      expect_result_to_have_keys(%w(content))
    end

    it "query single dialog to include content with target and resource action specified" do
      api_basic_authorize action_identifier(:service_dialogs, :read, :resource_actions, :get)
      service_template = FactoryBot.create(:service_template)
      get(api_service_dialog_url(nil, dialog1), :params => { :resource_action_id => ra1.id, :target_id => service_template.id, :target_type => 'service_template' })

      expect_single_resource_query(
        "id"    => dialog1.id.to_s,
        "href"  => api_service_dialog_url(nil, dialog1),
        "label" => dialog1.label
      )
      expect_result_to_have_keys(%w(content))
    end

    it "requires all of target_id, target_type, and resource_action" do
      api_basic_authorize action_identifier(:service_dialogs, :read, :resource_actions, :get)

      get(api_service_dialog_url(nil, dialog1), :params => { :target_id => 'id' })

      expected = {
        'error' => a_hash_including('message' => a_string_including('Must specify all of'))
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it "query single dialog to exclude content when attributes are asked for" do
      api_basic_authorize action_identifier(:service_dialogs, :read, :resource_actions, :get)

      get api_service_dialog_url(nil, dialog1), :params => { :attributes => "id,label" }

      expect_result_to_have_only_keys(%w(href id label))
    end

    context 'Delete Service Dialogs' do
      it 'DELETE /api/service_dialogs/:id' do
        dialog = FactoryBot.create(:dialog)
        api_basic_authorize collection_action_identifier(:service_dialogs, :delete)

        expect do
          delete(api_service_dialog_url(nil, dialog))
        end.to change(Dialog, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it 'POST /api/service_dialogs/:id deletes a single service dialog' do
        dialog = FactoryBot.create(:dialog)
        api_basic_authorize collection_action_identifier(:service_dialogs, :delete)

        expect do
          post(api_service_dialog_url(nil, dialog), :params => { 'action' => 'delete' })
        end.to change(Dialog, :count).by(-1)
        expect(response).to have_http_status(:ok)
      end

      it 'POST /api/service_dialogs deletes a single service dialog' do
        dialog = FactoryBot.create(:dialog)
        api_basic_authorize collection_action_identifier(:service_dialogs, :delete)

        expect do
          post(api_service_dialogs_url, :params => { 'action' => 'delete', 'resources' => [{ 'id' => dialog.id }] })
        end.to change(Dialog, :count).by(-1)
        expect(response).to have_http_status(:ok)
      end

      it 'POST /api/service_dialogs deletes multiple service dialogs' do
        dialog_a, dialog_b = FactoryBot.create_list(:dialog, 2)
        api_basic_authorize collection_action_identifier(:service_dialogs, :delete)

        expect do
          post(
            api_service_dialogs_url,
            :params => {
              'action'    => 'delete',
              'resources' => [{'id' => dialog_a.id}, {'id' => dialog_b.id}]
            }
          )
        end.to change(Dialog, :count).by(-2)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'Edit Service Dialogs' do
      let(:dialog) { FactoryBot.create(:dialog_with_tab_and_group_and_field) }

      it 'POST /api/service_dialogs/:id rejects a request without appropriate role' do
        api_basic_authorize

        post(api_service_dialog_url(nil, dialog), :params => gen_request(:edit, :label => 'updated label'))

        expect(response).to have_http_status(:forbidden)
      end

      context 'using call with :content key' do
        it 'POST /api/service_dialogs/:id updates a service dialog' do
          api_basic_authorize collection_action_identifier(:service_dialogs, :edit)
          dialog_tab = dialog.dialog_tabs.first
          dialog_group = dialog_tab.dialog_groups.first
          dialog_field = dialog_group.dialog_fields.first

          updated_dialog = {
            'label'   => 'updated label',
            'content' => {
              'dialog_tabs' => [
                'id'            => dialog_tab.id.to_s,
                'label'         => 'updated tab label',
                'dialog_groups' => [
                  {
                    'id'            => dialog_group.id.to_s,
                    'dialog_fields' => [
                      { 'id' => dialog_field.id.to_s }
                    ]
                  }
                ]
              ]
            }
          }

          expected = {
            'href'        => a_string_including(api_service_dialog_url(nil, dialog)),
            'id'          => dialog.id.to_s,
            'label'       => 'updated label',
            'dialog_tabs' => a_collection_including(
              a_hash_including('label' => 'updated tab label')
            )
          }

          expect do
            post(api_service_dialog_url(nil, dialog), :params => gen_request(:edit, updated_dialog))
            dialog.reload
          end.to change(dialog, :content)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(expected)
        end
      end

      context 'using call without :content key' do
        it 'POST /api/service_dialogs/:id updates a service dialog' do
          api_basic_authorize collection_action_identifier(:service_dialogs, :edit)
          dialog_tab = dialog.dialog_tabs.first
          dialog_group = dialog_tab.dialog_groups.first
          dialog_field = dialog_group.dialog_fields.first

          updated_dialog = {
            'label'       => 'updated label',
            'dialog_tabs' => [
              'id'            => dialog_tab.id.to_s,
              'label'         => 'updated tab label',
              'dialog_groups' => [
                {
                  'id'            => dialog_group.id.to_s,
                  'dialog_fields' => [
                    { 'id' => dialog_field.id.to_s }
                  ]
                }
              ]
            ]
          }

          expected = {
            'href'        => a_string_including(api_service_dialog_url(nil, dialog)),
            'id'          => dialog.id.to_s,
            'label'       => 'updated label',
            'dialog_tabs' => a_collection_including(
              a_hash_including('label' => 'updated tab label')
            )
          }

          expect do
            post(api_service_dialog_url(nil, dialog), :params => gen_request(:edit, updated_dialog))
            dialog.reload
          end.to change(dialog, :content)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(expected)
        end
      end

      it 'POST /api/service_dialogs/:id can remove tabs or fields' do
        api_basic_authorize collection_action_identifier(:service_dialogs, :edit)
        dialog_tab = dialog.dialog_tabs.first
        dialog_group = dialog_tab.dialog_groups.first
        new_field = FactoryBot.create(:dialog_field)
        dialog_group.dialog_fields << new_field

        updated_dialog = {
          'content' => {
            'dialog_tabs' => [
              'id'            => dialog_tab.id.to_s,
              'dialog_groups' => [
                {
                  'id'            => dialog_group.id.to_s,
                  'dialog_fields' => [
                    { 'id' => new_field.id.to_s }
                  ]
                }
              ]
            ]
          }
        }
        post(api_service_dialog_url(nil, dialog), :params => gen_request(:edit, updated_dialog))

        expected = {
          'href'        => a_string_including(api_service_dialog_url(nil, dialog)),
          'id'          => dialog.id.to_s,
          'dialog_tabs' => a_collection_including(
            a_hash_including(
              'dialog_groups' => [
                a_hash_including('dialog_fields' => [a_hash_including('id' => new_field.id.to_s)])
              ]
            )
          )
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it 'POST /api/service_dialogs updates multiple service dialog' do
        dialog2 = FactoryBot.create(:dialog_with_tab_and_group_and_field)

        api_basic_authorize collection_action_identifier(:service_dialogs, :edit)

        post(
          api_service_dialogs_url,
          :params => {
            :action    => 'edit',
            :resources => [
              {:id => dialog.id, 'label' => 'foo bar'},
              {:id => dialog2.id, :label => 'bar'}
            ]
          }
        )

        expected = {
          'results' => a_collection_containing_exactly(
            a_hash_including(
              'id'    => dialog.id.to_s,
              'label' => 'foo bar'
            ),
            a_hash_including(
              'id'    => dialog2.id.to_s,
              'label' => 'bar'
            )
          )
        }

        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'Service Dialogs Copy' do
      it 'forbids blueprint copy without an appropriate role' do
        dialog = FactoryBot.create(:dialog_with_tab_and_group_and_field)
        api_basic_authorize

        post(api_service_dialog_url(nil, dialog), :params => { :action => 'copy' })

        expect(response).to have_http_status(:forbidden)
      end

      it 'Can copy multiple service dialogs' do
        dialog1 = FactoryBot.create(:dialog_with_tab_and_group_and_field, :label => 'foo')
        dialog2 = FactoryBot.create(:dialog_with_tab_and_group_and_field, :label => 'bar')
        api_basic_authorize collection_action_identifier(:service_dialogs, :copy)

        expected = {
          'results' => a_collection_containing_exactly(
            a_hash_including(
              'label' => "Copy of foo"
            ),
            a_hash_including(
              'label' => "Copy of bar"
            )
          )
        }

        expect do
          post(
            api_service_dialogs_url,
            :params => {
              :action    => 'copy',
              :resources => [
                {:id => dialog1.id},
                {:id => dialog2.id}
              ]
            }
          )
        end.to change(Dialog, :count).by(2)
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it 'Can copy a single service dialog' do
        dialog = FactoryBot.create(:dialog_with_tab_and_group_and_field, :label => 'foo')
        api_basic_authorize collection_action_identifier(:service_dialogs, :copy)

        expected = {
          'label' => "Copy of foo"
        }

        expect do
          post(api_service_dialog_url(nil, dialog), :params => { :action => 'copy' })
        end.to change(Dialog, :count).by(1)
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it 'Can copy a service dialog with a new label' do
        dialog = FactoryBot.create(:dialog_with_tab_and_group_and_field, :label => 'bar')
        api_basic_authorize collection_action_identifier(:service_dialogs, :copy)

        expected = {
          'label' => 'foo'
        }

        expect do
          post(api_service_dialog_url(nil, dialog), :params => { :action => 'copy', 'label' => 'foo' })
        end.to change(Dialog, :count).by(1)
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "Service Dialogs subcollection" do
    before do
      template.resource_actions = [ra1, ra2]
      api_basic_authorize
    end

    it "query all service dialogs of a Service Template" do
      get(api_service_template_service_dialogs_url(nil, template), :params => { :expand => "resources" })

      dialogs = template.dialogs
      expect_query_result(:service_dialogs, dialogs.count, dialogs.count)
      expect_result_resources_to_include_data("resources", "label" => dialogs.pluck(:label))
    end

    it "query all service dialogs of a Service" do
      service.update_attributes!(:service_template_id => template.id)

      get(api_service_service_dialogs_url(nil, service), :params => { :expand => "resources" })

      dialogs = service.dialogs
      expect_query_result(:service_dialogs, dialogs.count, dialogs.count)
      expect_result_resources_to_include_data("resources", "label" => dialogs.pluck(:label))
    end

    it "queries service dialogs content with the template and related resource action specified and returns IDs" do
      get(api_service_template_service_dialog_url(nil, template, dialog1), :params => { :attributes => "content" })
      expected = {
        'content' => a_collection_including(
          a_hash_including('id' => dialog1.id.to_s)
        )}

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Service Dialogs refresh dialog fields" do
    let(:dialog1) { FactoryBot.create(:dialog, :label => "Dialog1") }
    let(:tab1)    { FactoryBot.create(:dialog_tab, :label => "Tab1") }
    let(:group1)  { FactoryBot.create(:dialog_group, :label => "Group1") }
    let(:text1)   { FactoryBot.create(:dialog_field_text_box, :label => "TextBox1", :name => "text1") }

    let(:password1) { FactoryBot.create(:dialog_field_text_box, :label => "PasswordBox1", :name => "password1") }

    def init_dialog
      dialog1.dialog_tabs << tab1
      tab1.dialog_groups << group1
      group1.dialog_fields << text1
      group1.dialog_fields << password1
    end

    it "rejects refresh dialog fields requests without appropriate role" do
      api_basic_authorize

      post(api_service_dialog_url(nil, dialog1), :params => gen_request(:refresh_dialog_fields, "fields" => %w(test1)))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects refresh dialog fields with unspecified fields" do
      api_basic_authorize action_identifier(:service_dialogs, :refresh_dialog_fields)
      init_dialog

      post(api_service_dialog_url(nil, dialog1), :params => gen_request(:refresh_dialog_fields))

      expect_single_action_result(:success => false, :message => /must specify fields/i)
    end

    it "rejects refresh dialog fields of invalid fields" do
      api_basic_authorize action_identifier(:service_dialogs, :refresh_dialog_fields)
      init_dialog

      post(api_service_dialog_url(nil, dialog1), :params => gen_request(
        :refresh_dialog_fields,
        "fields"             => %w(bad_field),
        "resource_action_id" => ra1.id,
        "target_id"          => template.id,
        "target_type"        => "service_template"
      ))
      expect_single_action_result(:success => false, :message => /unknown dialog field bad_field/i)
    end

    it "requires all of resource_action_id, target_id, and target_type" do
      api_basic_authorize action_identifier(:service_dialogs, :refresh_dialog_fields)
      init_dialog

      post(api_service_dialog_url(nil, dialog1), :params => gen_request(
        :refresh_dialog_fields,
        "fields" => %w(text1)
      ))

      expect_single_action_result(:success => false, :message => a_string_including('Must specify all of'))
    end

    it "requires that the resource action returns the same dialog as the dialog that we are requesting refresh of" do
      api_basic_authorize action_identifier(:service_dialogs, :refresh_dialog_fields)
      init_dialog

      post(api_service_dialog_url(nil, dialog1), :params => gen_request(
        :refresh_dialog_fields,
        "fields"             => %w(text1),
        "resource_action_id" => ra2.id,
        "target_id"          => template.id,
        "target_type"        => "service_template"
      ))

      expect_single_action_result(:success => false, :message => a_string_including('must be the same dialog'))
    end

    it "supports refresh when passing in resource_action_id, target_id, and target_type" do
      api_basic_authorize action_identifier(:service_dialogs, :refresh_dialog_fields)
      init_dialog

      post(api_service_dialog_url(nil, dialog1), :params => gen_request(
        :refresh_dialog_fields,
        "fields"             => %w(text1),
        "resource_action_id" => ra1.id,
        "target_id"          => template.id,
        "target_type"        => "service_template"
      ))

      expect(response.parsed_body).to include(
        "success" => true,
        "message" => a_string_matching(/refreshing dialog fields/i),
        "href"    => api_service_dialog_url(nil, dialog1),
        "result"  => hash_including("text1")
      )
    end

    it "supports refresh of encrypted attributes" do
      api_basic_authorize action_identifier(:service_dialogs, :refresh_dialog_fields)
      init_dialog

      post(api_service_dialog_url(nil, dialog1), :params => gen_request(
        :refresh_dialog_fields,
        "fields"             => %w[text1 password1],
        "resource_action_id" => ra1.id,
        "target_id"          => template.id,
        "target_type"        => "service_template"
      ))

      expect(response.parsed_body).to include(
        "success" => true,
        "message" => a_string_matching(/refreshing dialog fields/i),
        "href"    => api_service_dialog_url(nil, dialog1),
        "result"  => a_hash_including(
          "text1"     => a_hash_including("name" => "text1"),
          "password1" => a_hash_including("name" => "password1", "default_value" => anything)
        )
      )
    end

    it "supports refresh when passing in a target_type that is not the name of an api collection type" do
      api_basic_authorize action_identifier(:service_dialogs, :refresh_dialog_fields)
      init_dialog

      post(api_service_dialog_url(nil, dialog1), :params => gen_request(
        :refresh_dialog_fields,
        "fields"             => %w(text1),
        "resource_action_id" => ra1.id,
        "target_id"          => template.id,
        "target_type"        => "service_template_ansible_tower"
      ))

      expect(response.parsed_body).to include(
        "success" => true,
        "message" => a_string_matching(/refreshing dialog fields/i),
        "href"    => api_service_dialog_url(nil, dialog1),
        "result"  => hash_including("text1")
      )
    end

    it "raises a bad request for invalid target_types" do
      api_basic_authorize action_identifier(:service_dialogs, :refresh_dialog_fields)

      post(api_service_dialog_url(nil, dialog1), :params => gen_request(
        :refresh_dialog_fields,
        "fields"             => %w(text1),
        "resource_action_id" => ra1.id,
        "target_id"          => template.id,
        "target_type"        => "bad_type"
      ))

      expect(response.parsed_body).to include("success" => false, "message" => "Invalid target_type bad_type")
    end

    it "supports refresh dialog fields of valid fields" do
      api_basic_authorize action_identifier(:service_dialogs, :refresh_dialog_fields)
      init_dialog

      post(api_service_dialog_url(nil, dialog1), :params => gen_request(
        :refresh_dialog_fields,
        "fields"             => %w(text1),
        "resource_action_id" => ra1.id,
        "target_id"          => template.id,
        "target_type"        => "service_template"
      ))

      expect(response.parsed_body).to include(
        "success" => true,
        "message" => a_string_matching(/refreshing dialog fields/i),
        "href"    => api_service_dialog_url(nil, dialog1),
        "result"  => hash_including("text1")
      )
    end

    it "creates a ResourceActionWorkflow by passing in a true refresh option" do
      allow(ResourceActionWorkflow).to receive(:new).and_call_original
      expect(ResourceActionWorkflow).to receive(:new).with(
        {}, instance_of(User), instance_of(ResourceAction), hash_including(:refresh => true)
      )

      api_basic_authorize action_identifier(:service_dialogs, :refresh_dialog_fields)
      init_dialog

      post(api_service_dialog_url(nil, dialog1), :params => gen_request(
        :refresh_dialog_fields,
        "fields"             => %w(text1),
        "resource_action_id" => ra1.id,
        "target_id"          => template.id,
        "target_type"        => "service_template"
      ))
    end
  end

  context 'Creates service dialogs' do
    let(:dialog_request) do
      {
        :description => 'Dialog',
        :label       => 'dialog_label',
        :dialog_tabs => [
          {
            :description   => 'Dialog tab',
            :position      => 0,
            :label         => 'dialog_tab_label',
            :dialog_groups => [
              {
                :description   => 'Dialog group',
                :label         => 'group_label',
                :dialog_fields => [
                  {
                    :name  => 'A dialog field',
                    :label => 'dialog_field_label'
                  }
                ]
              }
            ]
          }
        ]
      }
    end

    it 'rejects service dialog creation without appropriate role' do
      api_basic_authorize

      post(api_service_dialogs_url, :params => dialog_request)

      expect(response).to have_http_status(:forbidden)
    end

    it 'rejects service dialog creation with an href specified' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)

      post(api_service_dialogs_url, :params => dialog_request.merge!("href" => api_service_dialog_url(nil, 123)))
      expected = {
        "error" => a_hash_including(
          "kind"    => "bad_request",
          "message" => a_string_matching(/id or href should not be specified/)
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects service dialog creation with an id specified' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)

      post(api_service_dialogs_url, :params => dialog_request.merge!("id" => 123))
      expected = {
        "error" => a_hash_including(
          "kind"    => "bad_request",
          "message" => a_string_matching(/id or href should not be specified/)
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end

    it 'supports single service dialog creation' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)

      expected = {
        "results" => [
          a_hash_including(
            "description" => "Dialog",
            "label"       => "dialog_label",
            "dialog_tabs" => a_collection_including(a_hash_including("description" => "Dialog tab"))
          )
        ]
      }

      expect do
        post(api_service_dialogs_url, :params => dialog_request)
      end.to change(Dialog, :count).by(1)
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'supports multiple service dialog creation' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)
      dialog_request_2 = {
        :description => 'Dialog 2',
        :label       => 'dialog_2_label',
        :dialog_tabs => [
          {
            :description   => 'Dialog 2 tab',
            :position      => 0,
            :label         => 'dialog_2_label',
            :dialog_groups => [
              {
                :description   => 'a new dialog group',
                :label         => 'dialog_2_group_label',
                :dialog_fields => [
                  {
                    :name  => 'a new dialog field',
                    :label => 'dialog_field_label'
                  }
                ]
              }
            ]
          }
        ]
      }

      expected = {
        "results" => [
          a_hash_including(
            "description" => "Dialog",
            "label"       => "dialog_label"
          ),
          a_hash_including(
            "description" => "Dialog 2",
            "label"       => "dialog_2_label"
          )
        ]
      }

      expect do
        post(api_service_dialogs_url, :params => gen_request(:create, [dialog_request, dialog_request_2]))
      end.to change(Dialog, :count).by(2)
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'returns dialog import service errors' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)
      invalid_request = {
        'description' => 'Dialog',
        'label'       => 'a_dialog'
      }

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => a_string_including('Failed to create a new dialog'),
          'klass'   => 'Api::BadRequestError'
        )
      }

      expect do
        post(api_service_dialogs_url, :params => invalid_request)
      end.to change(Dialog, :count).by(0)
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'Create servide dialog from template' do
    let(:ot) do
      FactoryBot.create(:orchestration_template_amazon_in_json).tap do |template|
        allow(template).to receive(:parameter_groups).and_return(param_groups)
        allow(template).to receive(:tabs).and_return(tabs) if tabs.count > 0
      end
    end

    let(:cs) { FactoryBot.create(:ansible_configuration_script) }

    let(:param_groups) { [] }
    let(:tabs) do
      [
        {
          :title       => 'Tab 1',
          :stack_group => [
            OrchestrationTemplate::OrchestrationParameter.new(:label => 'Param 1', :name => SecureRandom.hex, :data_type => 'string'),
            OrchestrationTemplate::OrchestrationParameter.new(:label => 'Param 2', :name => SecureRandom.hex, :data_type => 'string')
          ]
        }
      ]
    end

    it 'should create service dialog from orchestration_template' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)

      orchestration_template_dialog_request = {
        :action   => 'template_service_dialog',
        :resource => {:label => 'Foo', :template_id => ot.id, :template_class => "OrchestrationTemplate", :dialog_class => "Dialog::OrchestrationTemplateServiceDialog"}
      }

      post(api_service_dialogs_url, :params => orchestration_template_dialog_request)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['results'][0]['label']).to eq('Foo')
      expect(response.parsed_body['results'][0]['buttons']).to eq('submit,cancel')
    end

    it 'should create service dialog from configuration_script' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)

      configuration_script_dialog_request = {
        :action   => 'template_service_dialog',
        :resource => {:label => 'Foo', :template_id => cs.id, :template_class => "ConfigurationScript", :dialog_class => "Dialog::AnsibleTowerJobTemplateDialogService"}
      }

      post(api_service_dialogs_url, :params => configuration_script_dialog_request)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['results'][0]['label']).to eq('Foo')
      expect(response.parsed_body['results'][0]['buttons']).to eq('submit,cancel')
    end

    it 'should fail when template_id is undefined' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)

      orchestration_template_dialog_request = {
        :action   => 'template_service_dialog',
        :resource => {:label => 'Foo', :template_class => "OrchestrationTemplate", :dialog_class => "Dialog::OrchestrationTemplateServiceDialog"}
      }

      post(api_service_dialogs_url, :params => orchestration_template_dialog_request)
      expect(response).to have_http_status(:bad_request)
    end

    it 'should fail when label is undefined' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)

      orchestration_template_dialog_request = {
        :action   => 'template_service_dialog',
        :resource => {:template_id => ot.id, :template_class => "OrchestrationTemplate", :dialog_class => "Dialog::OrchestrationTemplateServiceDialog"}
      }

      post(api_service_dialogs_url, :params => orchestration_template_dialog_request)
      expect(response).to have_http_status(:bad_request)
    end

    it 'should fail when label is undefined' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)

      orchestration_template_dialog_request = {
        :action   => 'template_service_dialog',
        :resource => {:template_id => ot.id, :template_class => "OrchestrationTemplate", :dialog_class => "Dialog::OrchestrationTemplateServiceDialog"}
      }

      post(api_service_dialogs_url, :params => orchestration_template_dialog_request)
      expect(response).to have_http_status(:bad_request)
    end

    it 'should fail when template_class is undefined' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)

      orchestration_template_dialog_request = {
        :action   => 'template_service_dialog',
        :resource => {:template_id => ot.id, :label => 'Foo', :dialog_class => "Dialog::OrchestrationTemplateServiceDialog"}
      }

      post(api_service_dialogs_url, :params => orchestration_template_dialog_request)
      expect(response).to have_http_status(:bad_request)
    end

    it 'should fail when dialog_class is undefined' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)

      orchestration_template_dialog_request = {
        :action   => 'template_service_dialog',
        :resource => {:template_id => ot.id, :label => 'Foo', :template_class => "OrchestrationTemplate"}
      }

      post(api_service_dialogs_url, :params => orchestration_template_dialog_request)
      expect(response).to have_http_status(:bad_request)
    end

    it 'should fail when dialog_class is not in whitelist' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)

      orchestration_template_dialog_request = {
        :action   => 'template_service_dialog',
        :resource => {:label => 'Foo', :template_id => ot.id, :template_class => "OrchestrationTemplate", :dialog_class => "Dialog::VeryEvilDialogService"}
      }

      post(api_service_dialogs_url, :params => orchestration_template_dialog_request)
      expect(response).to have_http_status(:bad_request)
    end

    it 'should fail when template_class is not in whitelist' do
      api_basic_authorize collection_action_identifier(:service_dialogs, :create)

      orchestration_template_dialog_request = {
        :action   => 'template_service_dialog',
        :resource => {:label => 'Foo', :template_id => ot.id, :template_class => "EvilTemplate", :dialog_class => "Dialog::OrchestrationTemplateServiceDialog"}
      }

      post(api_service_dialogs_url, :params => orchestration_template_dialog_request)
      expect(response).to have_http_status(:bad_request)
    end
  end
end
