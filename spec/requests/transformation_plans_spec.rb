describe "Transformation Plans" do
  let(:transformation_plan) { FactoryGirl.create(:transformation_plan) }

  describe "GET /api/transformation_plans" do
    context "with an appropriate role" do
      it "retrieves transformation plans with an appropriate role" do
        api_basic_authorize(collection_action_identifier(:transformation_plans, :read, :get))

        get(api_transformation_plans_url)

        expect(response).to have_http_status(:ok)
      end

      context "without an appropriate role" do
        it "is forbidden" do
          api_basic_authorize

          get(api_transformation_plans_url)

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe "GET /api/transformation_plans/:id" do
    context "with an appropriate role" do
      it "returns the transformation plan" do
        api_basic_authorize(action_identifier(:transformation_plans, :read, :resource_actions, :get))

        get(api_transformation_plan_url(nil, transformation_plan))

        expect(response.parsed_body).to include('id' => transformation_plan.id.to_s)
        expect(response).to have_http_status(:ok)
      end

      context "without an appropriate role" do
        it "is forbidden" do
          api_basic_authorize

          get(api_transformation_plan_url(nil, transformation_plan))

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe "POST /api/transformation_plans" do
    context "with an appropriate role" do
      it "can create a new transformation plan" do
        api_basic_authorize(collection_action_identifier(:transformation_plans, :create))

        new_plan = {
          'name'        => 'new transformation plan',
          'description' => 'This is a transofrmation plan'
        }
        post(api_transformation_plans_url, :params => new_plan)

        expected = {
          'results' => [a_hash_including('name' => 'new transformation plan', 'href' => a_string_including(api_transformation_plans_url))]
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end

    context "without an appropriate role" do
      it "is forbidden" do
        api_basic_authorize

        new_plan = {
          'name'        => 'new transformation plan',
          'description' => 'This is a transofrmation plan'
        }
        post(api_transformation_plans_url, :params => new_plan)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
