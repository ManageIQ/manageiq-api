RSpec.describe "Schedules API" do
  context "authorization" do
    it "is forbidden for a user without appropriate role" do
      api_basic_authorize

      get api_schedules_url

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "GET /api/schedules" do
    it "returns all Schedules" do
      schedule = FactoryGirl.create(:miq_schedule)
      api_basic_authorize('schedule_list')

      get(api_schedules_url)

      expected = {
        "name"      => "schedules",
        "resources" => [{"href" => api_schedule_url(nil, schedule)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/schedules/:id" do
    it "returns a single Schedule" do
      schedule = FactoryGirl.create(:miq_schedule)
      api_basic_authorize('schedule_show')

      get(api_schedule_url(nil, schedule))

      expected = {
        "name" => schedule.name,
        "href" => api_schedule_url(nil, schedule)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
