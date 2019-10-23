RSpec.describe "Schedules API" do
  let(:miq_report) { FactoryBot.create(:miq_report) }
  let(:miq_expression) { MiqExpression.new("=" => {"field" => "MiqReport-id", "value" => miq_report.id}) }
  let(:miq_widget) { FactoryBot.create(:miq_widget) }
  let(:miq_w_expression) { MiqExpression.new("=" => {"field" => "MiqWidget-id", "value" => miq_widget.id}) }
  let(:container_img) { FactoryBot.create(:container_image) }
  let(:cont_img_expression) { MiqExpression.new("=" => {"field" => "ContainerImage-name", "value" => container_img.name}) }
  let!(:sched) { FactoryBot.create(:miq_schedule, :filter => miq_expression) }
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
          'filter'        => miq_expression,
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
      before do
        api_basic_authorize collection_action_identifier(:schedules, :create)

        @sched_rec = {
          'name'          => "",
          'description'   => "test",
          'sched_action'  => {
            'method' => 'test',
          },
          'filter'        => miq_expression,
          'resource_type' => "MiqReport",
          'run_at'        => "",
          'enabled'       => true,
          'last_run_on'   => 'nil'
        }
      end

      def run_at
        @sched_rec['run_at'] = {
          'start_time' => Time.zone.now,
          'tz'         => 'UTC',
          'interval'   => {'unit' => 'once' }
        }
      end
      it 'can create MiqReport schedules' do
        @sched_rec['name'] = 'create 1'

        @sched_rec['sched_action'] = {
          'method'  => 'test',
          'options' => {
            'send_email'       => false,
            'email_url_prefix' => "/report/show_saved/",
            'miq_group_id'     => '2'
          },
        }

        run_at

        post(api_schedules_url, :params => @sched_rec)
        expect(response).to have_http_status(:ok)

        schedule = MiqSchedule.find(response.parsed_body['results'].first["id"])
        expect(schedule.name).to eq('create 1')
        expect(schedule.description).to eq('test')
        expect(schedule.resource_type).to eq('MiqReport')
      end

      it 'can creat MiqReport schedule wo given options' do
        @sched_rec['name'] = 'no options'
        run_at

        options = {
          'method'  => 'test',
          'options' => {
            'send_email'       => false,
            'email_url_prefix' => "/report/show_saved/",
            'miq_group_id'     => '2'
          }
        }

        post(api_schedules_url, :params => @sched_rec)
        expect(response).to have_http_status(:ok)
        schedule = MiqSchedule.find(response.parsed_body['results'].first["id"])
        expect(schedule.name).to eq('no options')
        expect(schedule.description).to eq('test')
        expect(schedule.sched_action).to eq(options)
        expect(schedule.resource_type).to eq('MiqReport')
      end

      it 'cannot create MiqReport schedule - missing run_at' do
        @sched_rec['name'] = 'fail'

        post(api_schedules_url, :params => @sched_rec)
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'can create MiqWidget schedules' do
        sched_rec = {
          'name'          => "create 2",
          'description'   => "test",
          'sched_action'  => {
            'method' => 'test'
          },
          'filter'        => miq_w_expression,
          'resource_type' => "MiqWidget",
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
        expect(schedule.name).to eq('create 2')
        expect(schedule.description).to eq('test')
        expect(schedule.sched_action).to eq("method"=>"test")
        expect(schedule.resource_type).to eq('MiqWidget')
      end

      it 'can create DatabaseBackup schedule' do
        sched_rec = {
          'name'          => "create 3",
          'description'   => "test",
          'sched_action'  => {
            'method' => 'test'
          },
          'filter'        => nil,
          'resource_type' => "DatabaseBackup",
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
        expect(schedule.name).to eq('create 3')
        expect(schedule.description).to eq('test')
        expect(schedule.sched_action).to eq("method"=>"test")
        expect(schedule.resource_type).to eq('DatabaseBackup')
      end

      it 'can create AutomationRequest schedule' do
        sched_rec = {
          'name'          => "create 4",
          'description'   => "test",
          'sched_action'  => {
            'method' => 'test'
          },
          'filter'        => {
            'uri_parts' => {
              'namespace' => "test",
              'instance'  => "Request",
              'message'   => "create"
            }
          },
          'resource_type' => "AutomationRequest",
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
        expect(schedule.name).to eq('create 4')
        expect(schedule.description).to eq('test')
        expect(schedule.sched_action).to eq("method"=>"test")
        expect(schedule.resource_type).to eq('AutomationRequest')
      end

      it 'can create ContainerImage schedule' do
        sched_rec = {
          'name'          => "create 5",
          'description'   => "test",
          'sched_action'  => {
            'method' => 'test'
          },
          'filter'        => cont_img_expression,
          'resource_type' => "ContainerImage",
          'run_at'        => "",
          'enabled'       => false,
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
        expect(schedule.name).to eq('create 5')
        expect(schedule.description).to eq('test')
        expect(schedule.sched_action).to eq("method"=>"test")
        expect(schedule.resource_type).to eq('ContainerImage')
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
