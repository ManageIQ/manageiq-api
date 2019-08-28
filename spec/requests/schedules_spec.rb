RSpec.describe "Schedules API" do
  let!(:sched) { FactoryBot.create(:miq_schedule) }
  describe 'GET /api/schedules' do
    context 'without an appropriate role' do
      it 'does not list Schedules' do
        api_basic_authorize
        get(api_schedules_url)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with an appropriate role' do
      before { api_basic_authorize collection_action_identifier(:schedules, :read, :get) }

      it 'lists schedules' do
        get(api_schedules_url)

        expected = {
          'count'     => 1,
          'subcount'  => 1,
          'pages'     => 1,
          'name'      => 'schedules',
          'resources' => [
            "href" => api_schedule_url(nil, sched)
          ]
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end

  describe 'GET /api/schedules/:id' do
    context 'without an appropriate role' do
      it 'does not list Schedule' do
        api_basic_authorize
        get(api_schedule_url(nil, sched))
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with an appropriate role' do
      before { api_basic_authorize action_identifier(:schedules, :read, :resource_actions, :get) }

      it 'show Schedule' do
        get(api_schedule_url(nil, sched))

        expected = {
          'id'            => sched.id.to_s,
          'resource_type' => "MiqReport"
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end

  describe 'POST /api/schedules' do
    context 'without an appropriate role' do
      it 'cannot create schedule' do
        api_basic_authorize

        sched_rec = {
          'name'          => "create 1",
          'description'   => "test",
          'sched_action'  => {'method' => 'test'},
          'filter'        => 'nil',
          'resource_type' => "MiqReport",
          'run_at'        => "",
          'enabled'       => true,
          'last_run_on'   => 'nil'
        }

        sched_rec['run_at'] = {
          :start_time => Time.zone.now,
          :tz         => 'UTC',
          :interval   => {:unit => 'once' }
        }

        post(api_schedules_url, :params => gen_request(:create, sched_rec))
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with an appropriate role' do
      before { api_basic_authorize collection_action_identifier(:schedules, :create) }

      it 'can create schedules' do
        sched_rec = {
          'name'          => "create 1",
          'description'   => "test",
          'sched_action'  => {'method' => 'test'},
          'filter'        => 'nil',
          'resource_type' => "MiqReport",
          'run_at'        => "",
          'enabled'       => true,
          'last_run_on'   => 'nil'
        }

        sched_rec['run_at'] = {
          'start_time' => Time.zone.now,
          'tz'         => 'UTC',
          'interval'   => {'unit' => 'once' }
        }

        post(api_schedules_url, :params => sched_rec)
        expect(response).to have_http_status(:ok)

        schedule = MiqSchedule.find(response.parsed_body['results'].first["id"])
        expect(schedule.name).to eq('create 1')
        expect(schedule.description).to eq('test')
        expect(schedule.sched_action).to eq("method"=>"test")
        expect(schedule.resource_type).to eq('MiqReport')
      end
    end
  end

  describe 'PUT /api/schedules/:id' do
    context 'without an appropriate role' do
      it 'cannot edit schedule' do
        api_basic_authorize
        put(api_schedule_url(nil, sched), :params => {'name' => 'edit 1'})
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with an appropriate role' do
      before { api_basic_authorize collection_action_identifier(:schedules, :edit) }

      it 'can edit schedule by id' do
        expect(sched.name).not_to eq('edit 1')
        put(api_schedule_url(nil, sched), :params => {'name' => 'edit 1'})
        expect(response).to have_http_status(:ok)
        expect(sched.reload.name).to eq('edit 1')
      end
    end
  end

  describe 'DELETE /api/schedules/:id' do
    context 'without an appropriate role' do
      it 'cannot delete a schedule' do
        api_basic_authorize
        delete(api_schedule_url(nil, sched))
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with an appropriate role' do
      before { api_basic_authorize action_identifier(:schedules, :delete, :resource_actions, :delete) }

      it 'can delete a schedule by id' do
        delete(api_schedule_url(nil, sched))
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
