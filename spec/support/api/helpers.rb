#
# For testing REST API via Rspec requests
#

module Spec
  module Support
    module Api
      module Helpers
        def init_api_spec_env
          @enterprise = FactoryBot.create(:miq_enterprise)
          @guid, @server, @zone = EvmSpecHelper.create_guid_miq_server_zone
          @region = FactoryBot.create(:miq_region, :region => ApplicationRecord.my_region_number)
          @role  = FactoryBot.create(:miq_user_role, :name => "Api User Role")
          @group = FactoryBot.create(:miq_group, :description => "Api User Group", :miq_user_role => @role)
          @user  = FactoryBot.create(:user,
                                      :name       => "API User",
                                      :userid     => "api_user_id",
                                      :password   => "api_user_password",
                                      :miq_groups => [@group])
        end

        def api_basic_authorize(*identifiers, user: @user.userid, password: @user.password)
          if identifiers.present?
            identifiers.flatten.collect do |identifier|
              @role.miq_product_features << MiqProductFeature.find_or_create_by(:identifier => identifier) if identifier
            end
            @role.save

            MiqProductFeature.seed_tenant_miq_product_features if identifiers & MiqProductFeature::TENANT_FEATURE_ROOT_IDENTIFIERS == identifiers
          end

          request_headers["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(user, password)
        end

        def stub_api_action_role(collection, action_type, method, action, identifier)
          new_action_role = Config::Options.new.merge!("name" => action.to_s, "identifier" => identifier)
          updated_method = ::Api::ApiConfig.collections[collection][action_type][method].collect do |method_action|
            method_action.name == action.to_s ? new_action_role : method_action
          end
          allow(::Api::ApiConfig.collections[collection][action_type]).to receive(method) { updated_method }
        end

        def collection_action_classed_identifier(type, action, method, klass)
          identifier_from_multiple_class_list(::Api::ApiConfig.collections[type][:collection_actions][method], action, klass)
        end

        def action_identifier(type, action, selection = :resource_actions, method = :post)
          ::Api::ApiConfig
            .collections[type][selection][method]
            .detect { |spec| spec[:name] == action.to_s }[:identifier]
        end

        def collection_action_identifier(type, action, method = :post)
          action_identifier(type, action, :collection_actions, method)
        end

        def resource_action_identifier(type, action, method = :post)
          action_identifier(type, action, :resource_actions, method)
        end

        def subcollection_action_identifier(type, subtype, action, method = :post)
          subtype_actions = "#{subtype}_subcollection_actions".to_sym
          if ::Api::ApiConfig.collections[type][subtype_actions]
            action_identifier(type, action, subtype_actions, method)
          else
            action_identifier(subtype, action, :subcollection_actions, method)
          end
        end

        def subcollection_action_classed_identifiers(type, subtype, action, klass, method = :post)
          subtype_actions = "#{subtype}_subcollection_actions".to_sym
          collection_type = ::Api::ApiConfig.collections[type]
          if ::Api::ApiConfig.collections[type][subtype_actions]
            identifier_from_multiple_class_list(collection_type[subtype_actions][method], action, klass)
          else
            identifier_from_multiple_class_list(collection_type[:subcollection_actions][method], action, klass)
          end
        end

        def subresource_action_identifier(type, subtype, action, method = :post)
          subresource_actions = "#{subtype}_subresource_actions".to_sym
          if ::Api::ApiConfig.collections[type][subresource_actions]
            action_identifier(type, action, subresource_actions, method)
          else
            action_identifier(subtype, action, :subresource_actions, method)
          end
        end

        def identifier_from_multiple_class_list(method_actions, action, klass)
          method_actions
            .detect { |spec| spec[:name] == action.to_s }[:identifiers]
            .detect { |spec| spec[:klass] == klass.to_s }[:identifier]
        end

        def gen_request(action, data = nil, *hrefs)
          request = {"action" => action.to_s}
          if hrefs.present?
            data ||= {}
            request["resources"] = hrefs.collect { |href| data.dup.merge("href" => href) }
          elsif data.present?
            request[data.kind_of?(Array) ? "resources" : "resource"] = data
          end
          request
        end

        def declare_actions(*names)
          include("actions" => a_collection_containing_exactly(*names.map { |name| a_hash_including("name" => name) }))
        end

        def include_actions(*names)
          include("actions" => a_collection_including(*names.map { |name| a_hash_including("name" => name) }))
        end

        def include_error_with_message(error_message)
          include("error" => hash_including("message" => a_string_matching(error_message)))
        end

        # Rest API Expects

        def expect_bad_request(error_message)
          expect(response.parsed_body).to include_error_with_message(error_message)
          expect(response).to have_http_status(:bad_request)
        end

        def expect_result_resources_to_include_data(collection, data)
          expect(response.parsed_body).to have_key(collection)
          data.each do |key, value_list|
            expect(response.parsed_body[collection].size).to eq(value_list.size)
            expect(response.parsed_body[collection].collect { |r| r[key] }).to match_array(value_list)
          end
        end

        def expect_result_resources_to_include_hrefs(collection, hrefs)
          expected = {
            collection => a_collection_containing_exactly(
              *hrefs.collect { |href| a_hash_including("href" => href) }
            )
          }
          expect(response.parsed_body).to include(expected)
        end

        def expect_result_to_have_keys(keys)
          expect(response.parsed_body).to include(*keys)
        end

        def expect_result_to_have_only_keys(keys)
          expect_hash_to_have_only_keys(response.parsed_body, keys)
        end

        def expect_hash_to_have_only_keys(hash, keys)
          expect(hash.keys).to match_array(keys)
        end

        def expect_result_to_match_hash(result, attr_hash)
          attr_hash.each do |key, value|
            attr_hash[key] = key == "href" || key.ends_with?("_href") ? a_string_matching(value) : value
          end
          expect(result).to include(attr_hash)
        end

        def expect_results_to_match_hash(collection, result_hash)
          expect(response.parsed_body).to have_key(collection)
          result_hash.zip(response.parsed_body[collection]) do |expected, actual|
            expect_result_to_match_hash(actual, expected)
          end
        end

        def expect_result_resources_to_match_hash(result_hash)
          expect_results_to_match_hash("resources", result_hash)
        end

        def expect_result_resources_to_include_keys(collection, keys)
          expect(response.parsed_body).to include(collection => all(a_hash_including(*keys)))
        end

        # Primary result construct methods

        def expect_empty_query_result(collection)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include("name" => collection.to_s, "resources" => [])
        end

        def expect_query_result(collection, subcount, count = nil)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include("name" => collection.to_s, "subcount" => subcount)
          expect(response.parsed_body["resources"].size).to eq(subcount)
          expect(response.parsed_body["count"]).to eq(count) if count.present?
        end

        def expect_single_resource_query(attr_hash)
          expect(response).to have_http_status(:ok)
          expect_result_to_match_hash(response.parsed_body, attr_hash)
        end

        def expect_single_action_result(options = {})
          expect(response).to have_http_status(:ok)
          expected = options.slice("href", "message", "success")
          expected["success"] = options[:success] if options.key?(:success)
          expected["message"] = a_string_matching(options[:message]) if options[:message]
          expected["href"] = a_string_matching(options[:href]) if options[:href]
          expected.merge!(expected_task_response) if options[:task]
          expect(response.parsed_body).to include(expected)
          expect(response.parsed_body).not_to include("actions")
        end

        def expect_multiple_action_result(count, options = {})
          expect(response).to have_http_status(:ok)
          expected_result = {"success" => true}
          expected_result.merge!(expected_task_response) if options[:task]
          expected = {"results" => Array.new(count) { a_hash_including(expected_result) }}
          expect(response.parsed_body).to include(expected)
        end

        def expected_task_response
          {"task_id" => anything, "task_href" => anything}
        end

        def expect_tagging_result(tag_results)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to have_key("results")
          results = response.parsed_body["results"]
          expect(results.size).to eq(tag_results.size)
          tag_results.zip(results) do |tag_result, result|
            expect(result).to include(
              "success"      => tag_result[:success],
              "href"         => a_string_matching(tag_result[:href]),
              "tag_category" => tag_result[:tag_category],
              "tag_name"     => tag_result[:tag_name]
            )
          end
        end

        def expect_options_results(type, data = {})
          klass = ::Api::ApiConfig.collections[type].klass.constantize
          attributes = select_attributes(klass.attribute_names - klass.virtual_attribute_names)
          reflections = (klass.reflections.keys | klass.virtual_reflections.keys.collect(&:to_s)).sort
          subcollections = Array(::Api::ApiConfig.collections[type].subcollections).collect(&:to_s).sort
          expected = {
            'attributes'         => attributes,
            'virtual_attributes' => select_attributes(klass.virtual_attribute_names),
            'relationships'      => reflections,
            'subcollections'     => subcollections,
            'data'               => data
          }
          expect(response.parsed_body).to eq(expected)
          expect(response.headers['Access-Control-Allow-Methods']).to include('OPTIONS')
        end

        def expect_forbidden_request
          api_basic_authorize
          yield
          expect(response).to have_http_status(:forbidden)
        end

        def select_attributes(attrlist)
          attrlist.sort.select { |attr| !::Api.encrypted_attribute?(attr) }
        end
      end
    end
  end
end
