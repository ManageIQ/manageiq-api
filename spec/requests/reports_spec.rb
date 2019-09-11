RSpec.describe "reports API" do
  it "can fetch all the reports" do
    report_1 = FactoryBot.create(:miq_report_with_results)
    report_2 = FactoryBot.create(:miq_report_with_results)

    api_basic_authorize collection_action_identifier(:reports, :read, :get)
    get api_reports_url

    expect_result_resources_to_include_hrefs(
      "resources",
      [
        api_report_url(nil, report_1),
        api_report_url(nil, report_2)
      ]
    )
    expect_result_to_match_hash(response.parsed_body, "count" => 2, "name" => "reports")
    expect(response).to have_http_status(:ok)
  end

  it 'returns only the requested attributes' do
    FactoryBot.create(:miq_report_with_results)
    api_basic_authorize collection_action_identifier(:reports, :read, :get)

    get api_reports_url, :params => { :expand => 'resources', :attributes => 'template_type' }

    expect(response).to have_http_status(:ok)
    response.parsed_body['resources'].each { |res| expect_hash_to_have_only_keys(res, %w(href id template_type)) }
  end

  it "can fetch a report" do
    report = FactoryBot.create(:miq_report_with_results)

    api_basic_authorize action_identifier(:reports, :read, :resource_actions, :get)
    get api_report_url(nil, report)

    expect_result_to_match_hash(
      response.parsed_body,
      "href"  => api_report_url(nil, report),
      "id"    => report.id.to_s,
      "name"  => report.name,
      "title" => report.title
    )
    expect(response).to have_http_status(:ok)
  end

  context 'authorized to see its own report results' do
    let(:group) { FactoryBot.create(:miq_group) }
    let(:user) do
      @user.current_group ||= group
      @user
    end
    let(:report) { FactoryBot.create(:miq_report_with_results, :miq_group => user.current_group) }

    it "can fetch a report's results" do
      report_result = report.miq_report_results.first

      api_basic_authorize
      get(api_report_results_url(nil, report))

      expect_result_resources_to_include_hrefs(
        "resources",
        [
          api_report_result_url(nil, report, report_result)
        ]
      )
      expect(response.parsed_body["resources"]).not_to be_any { |resource| resource.key?("result_set") }
      expect(response).to have_http_status(:ok)
    end

    it "can fetch a report's result" do
      report_result = report.miq_report_results.first
      table = Ruport::Data::Table.new(
        :column_names => %w(foo),
        :data         => [%w(bar), %w(baz)]
      )
      allow(report).to receive(:table).and_return(table)
      allow_any_instance_of(MiqReportResult).to receive(:report_results).and_return(report)

      api_basic_authorize
      get(api_report_result_url(nil, report, report_result))

      expect_result_to_match_hash(response.parsed_body, "result_set" => [{"foo" => "bar"}, {"foo" => "baz"}])
      expect(response).to have_http_status(:ok)
    end

    it "can fetch all the results" do
      result = report.miq_report_results.first
      api_basic_authorize collection_action_identifier(:results, :read, :get)
      get api_results_url
      expect_result_resources_to_include_hrefs(
        "resources",
        [
          api_result_url(nil, result).to_s
        ]
      )
      expect(response).to have_http_status(:ok)
    end

    context "pagination and sorting with report result's result_set" do
      let(:columns) { %w[name size] }
      let(:result_set) do
        [{"name" => "VM2", "size" => 115_533},
         {"name" => "VM1", "size" => 332_233},
         {"name" => "VG1", "size" => 112_233}]
      end

      let(:col_formats) { Array.new(columns.count) }
      let(:report_result) { FactoryBot.create(:miq_report_result, :miq_group => user.current_group) }
      let(:report) do
        FactoryBot.create(:miq_report, :miq_group          => user.current_group,
                                       :miq_report_results => [report_result],
                                       :col_order          => columns,
                                       :col_formats        => col_formats)
      end

      let(:params) { { :hash_attribute => "result_set" } }

      before do
        report_result.update(:report => report)
        allow_any_instance_of(MiqReportResult).to receive(:result_set).and_return(result_set)

        api_basic_authorize action_identifier(:results, :read, :resource_actions, :get)
      end

      let(:result_set_sorted_by_name) do
        [
          {"name" => "VG1",
           "size" => "109.6 KB"},
          {"name" => "VM1",
           "size" => "324.4 KB"},
          {"name" => "VM2",
           "size" => "112.8 KB"}
        ]
      end

      it "returns sorted result_set according to string column and default formatting" do
        params[:sort_by] = 'name'
        get api_result_url(nil, report_result), :params => params
        expect_result_to_match_hash(response.parsed_body, "result_set" => result_set_sorted_by_name)
        expect(response).to have_http_status(:ok)
      end

      it "returns sorted result_set according to string column and default formatting, sort_order=descending" do
        params[:sort_by] = 'name'
        params[:sort_order] = 'desc'
        get api_result_url(nil, report_result), :params => params
        expect_result_to_match_hash(response.parsed_body, "result_set" => result_set_sorted_by_name.reverse)
        expect(response).to have_http_status(:ok)
      end

      let(:result_set_sorted_by_size) do
        [
          {"name" => "VG1",
           "size" => "109.6 KB"},
          {"name" => "VM2",
           "size" => "112.8 KB"},
          {"name" => "VM1",
           "size" => "324.4 KB"}
        ]
      end

      it "returns sorted result_set according to integer column and default formatting" do
        params[:sort_by] = 'size'
        get api_result_url(nil, report_result), :params => params
        expect_result_to_match_hash(response.parsed_body, "result_set" => result_set_sorted_by_size)
        expect(response).to have_http_status(:ok)
      end

      it "returns sorted result_set according to integer column and default formatting, sort_order=descending" do
        params[:sort_by] = 'size'
        params[:sort_order] = 'desc'
        get api_result_url(nil, report_result), :params => params
        expect_result_to_match_hash(response.parsed_body, "result_set" => result_set_sorted_by_size.reverse)
        expect(response).to have_http_status(:ok)
      end

      let(:result_set_custom_formatting_for_size) do
        [
          {"name" => "VM1",
           "size" => "332,233"},
          {"name" => "VM2",
           "size" => "115,533"},
          {"name" => "VG1",
           "size" => "112,233"}
        ]
      end

      context "with custom formatting" do
        let(:col_formats) { [nil, :general_number_precision_0] }

        it "returns sorted result_set according to integer column and custom formatting for size, sort_order=descending" do
          params[:sort_by] = 'size'
          params[:sort_order] = 'desc'
          get api_result_url(nil, report_result), :params => params
          expect_result_to_match_hash(response.parsed_body, "result_set" => result_set_custom_formatting_for_size)
          expect_result_to_match_hash(response.parsed_body, "count" => 3)
          expect_result_to_match_hash(response.parsed_body, "subcount" => 3)
          expect_result_to_match_hash(response.parsed_body, "pages" => 1)
          expect(response).to have_http_status(:ok)
        end

        it "returns first page of result_set, with limit=2" do
          params[:sort_by] = 'size'
          params[:sort_order] = 'desc'
          params[:limit] = 2
          get api_result_url(nil, report_result), :params => params

          expect_result_to_match_hash(response.parsed_body, "result_set" => result_set_custom_formatting_for_size[0..1])
          expect_result_to_match_hash(response.parsed_body, "count" => 3)
          expect_result_to_match_hash(response.parsed_body, "subcount" => 2)
          expect_result_to_match_hash(response.parsed_body, "pages" => 2)
          expect(response).to have_http_status(:ok)
        end

        it "returns first page of result_set, with limit=2 and offset=1" do
          params[:sort_by] = 'size'
          params[:sort_order] = 'desc'
          params[:limit] = 2
          params[:offset] = 1
          get api_result_url(nil, report_result), :params => params

          expect_result_to_match_hash(response.parsed_body, "result_set" => result_set_custom_formatting_for_size[1..2])
          expect_result_to_match_hash(response.parsed_body, "count" => 3)
          expect_result_to_match_hash(response.parsed_body, "subcount" => 2)
          expect_result_to_match_hash(response.parsed_body, "pages" => 2)
          expect(response).to have_http_status(:ok)
        end

        it "returns first page of result_set, with limit=2 and offset=2" do
          params[:sort_by] = 'size'
          params[:sort_order] = 'desc'
          params[:limit] = 2
          params[:offset] = 2
          get api_result_url(nil, report_result), :params => params

          expect_result_to_match_hash(response.parsed_body, "result_set" => result_set_custom_formatting_for_size[2..2])
          expect_result_to_match_hash(response.parsed_body, "count" => 3)
          expect_result_to_match_hash(response.parsed_body, "subcount" => 1)
          expect_result_to_match_hash(response.parsed_body, "pages" => 2)
          expect(response).to have_http_status(:ok)
        end
      end

      context "with filtering" do
        let(:filtered_result_set) do
          [{"name" => "VM1", "size" => "324.4 KB"},
           {"name" => "VM3", "size" => "220.2 KB"},
           {"name" => "VM2", "size" => "112.8 KB"}]
        end

        let(:result_set) do
          [{"id" => 1, "name" => "VM2", "size" => 115_533},
           {"id" => 2, "name" => "VM1", "size" => 332_233},
           {"id" => 3, "name" => "VM3", "size" => 225_533},
           {"id" => 4, "name" => "VG1", "size" => 112_233_444_1}]
        end

        it "returns filtered and sorted result_set according to integer column and default formatting, sort_order=descending" do
          params[:sort_by] = 'size'
          params[:sort_order] = 'desc'
          params[:filter_column] = 'name'
          params[:filter_string] = 'VM'
          get api_result_url(nil, report_result), :params => params
          expect_result_to_match_hash(response.parsed_body, "result_set" => filtered_result_set)
          expect(response).to have_http_status(:ok)
        end

        it "returns filtered and sorted result_set by integer column, default formatting, sort_order=descending and pagination" do
          params[:sort_by] = 'size'
          params[:sort_order] = 'desc'
          params[:filter_column] = 'name'
          params[:filter_string] = 'VM'
          params[:limit] = 2
          params[:offset] = 1
          get api_result_url(nil, report_result), :params => params
          expect_result_to_match_hash(response.parsed_body, "result_set" => filtered_result_set[1..2]) # second page
          expect_result_to_match_hash(response.parsed_body, "count" => 3)
          expect_result_to_match_hash(response.parsed_body, "subcount" => 2)
          expect_result_to_match_hash(response.parsed_body, "pages" => 2)
          expect(response).to have_http_status(:ok)
        end

        let(:filtered_result_set_ascending) do
          [{"name" => "VM2", "size" => "112.8 KB"},
           {"name" => "VM3", "size" => "220.2 KB"},
           {"name" => "VM1", "size" => "324.4 KB"}]
        end

        it "returns filtered and sorted result_set according to integer column and default formatting, sort_order=ascending" do
          params[:sort_by] = 'size'
          params[:sort_order] = 'asc'
          params[:filter_column] = 'name'
          params[:filter_string] = 'VM'
          get api_result_url(nil, report_result), :params => params
          expect_result_to_match_hash(response.parsed_body, "result_set" => filtered_result_set_ascending)
          expect(response).to have_http_status(:ok)
        end

        it "returns filtered(in formatted output) and sorted result_set according to integer column and default formatting, sort_order=ascending" do
          params[:sort_by] = 'size'
          params[:sort_order] = 'asc'
          params[:filter_column] = 'size'
          params[:filter_string] = 'GB'
          get api_result_url(nil, report_result), :params => params
          expect_result_to_match_hash(response.parsed_body, "result_set" => [{"name" => "VG1", "size" => "1 GB"}])
          expect(response).to have_http_status(:ok)
        end
      end
    end

    it "can fetch a specific result as a primary collection" do
      report_result = report.miq_report_results.first
      table = Ruport::Data::Table.new(
        :column_names => %w(foo),
        :data         => [%w(bar), %w(baz)]
      )
      allow(report).to receive(:table).and_return(table)
      allow_any_instance_of(MiqReportResult).to receive(:report_results).and_return(report)

      api_basic_authorize action_identifier(:results, :read, :resource_actions, :get)
      get api_result_url(nil, report_result)

      expect_result_to_match_hash(response.parsed_body, "result_set" => [{"foo" => "bar"}, {"foo" => "baz"}])
      expect(response).to have_http_status(:ok)
    end

    it "returns an empty result set if none has been run" do
      report_result = report.miq_report_results.first

      api_basic_authorize
      get(api_report_result_url(nil, report, report_result))

      expect_result_to_match_hash(response.parsed_body, "result_set" => [])
      expect(response).to have_http_status(:ok)
    end

    it "returns an empty result set if none has been run" do
      report = FactoryBot.create(:miq_report_with_results, :miq_group => user.current_group)
      report_result = report.miq_report_results.first

      api_basic_authorize
      get api_report_result_url(nil, report, report_result)

      expect_result_to_match_hash(response.parsed_body, "result_set" => [])
      expect(response).to have_http_status(:ok)
    end
  end

  it "can fetch all the schedule" do
    report = FactoryBot.create(:miq_report)

    exp = {}
    exp["="] = {"field" => "MiqReport-id", "value" => report.id}
    exp = MiqExpression.new(exp)

    schedule_1 = FactoryBot.create(:miq_schedule, :filter => exp)
    schedule_2 = FactoryBot.create(:miq_schedule, :filter => exp)

    api_basic_authorize subcollection_action_identifier(:reports, :schedules, :read, :get)
    get api_report_schedules_url(nil, report)

    expect_result_resources_to_include_hrefs(
      "resources",
      [
        api_report_schedule_url(nil, report, schedule_1),
        api_report_schedule_url(nil, report, schedule_2),
      ]
    )
    expect(response).to have_http_status(:ok)
  end

  it "will not show the schedules without the appropriate role" do
    report = FactoryBot.create(:miq_report)
    exp = MiqExpression.new("=" => {"field" => "MiqReport-id", "value" => report.id})
    FactoryBot.create(:miq_schedule, :filter => exp)
    api_basic_authorize

    get(api_report_schedules_url(nil, report))

    expect(response).to have_http_status(:forbidden)
  end

  it "can show a single schedule" do
    report = FactoryBot.create(:miq_report)

    exp = {}
    exp["="] = {"field" => "MiqReport-id", "value" => report.id}
    exp = MiqExpression.new(exp)

    schedule = FactoryBot.create(:miq_schedule, :name => 'unit_test', :filter => exp)

    api_basic_authorize subcollection_action_identifier(:reports, :schedules, :read, :get)
    get(api_report_schedule_url(nil, report, schedule))

    expect_result_to_match_hash(
      response.parsed_body,
      "href" => api_report_schedule_url(nil, report, schedule),
      "id"   => schedule.id.to_s,
      "name" => 'unit_test'
    )
    expect(response).to have_http_status(:ok)
  end

  it "will not show a schedule without the appropriate role" do
    report = FactoryBot.create(:miq_report)
    exp = MiqExpression.new("=" => {"field" => "MiqReport-id", "value" => report.id})
    schedule = FactoryBot.create(:miq_schedule, :filter => exp)
    api_basic_authorize

    get(api_report_schedule_url(nil, report, schedule))

    expect(response).to have_http_status(:forbidden)
  end

  context "with an appropriate role" do
    # Setup in a similar was to the reproduction steps in this BZ:
    #
    #   https://bugzilla.redhat.com/show_bug.cgi?id=1650531
    #
    it "can fetch all the reports" do
      report_1 = FactoryBot.create(:miq_report_with_results)
      report_2 = FactoryBot.create(:miq_report_with_results)

      # Includes roles "API" and "Overview"
      MiqProductFeature.seed
      api_basic_authorize :dashboard, :miq_report, :chargeback, :timeline, :rss, :api_exclusive
      get api_reports_url

      expect_result_resources_to_include_hrefs(
        "resources",
        [
          api_report_url(nil, report_1),
          api_report_url(nil, report_2)
        ]
      )
      expect_result_to_match_hash(response.parsed_body, "count" => 2, "name" => "reports")
      expect(response).to have_http_status(:ok)
    end

    it "can run a report" do
      report = FactoryBot.create(:miq_report)

      expect do
        api_basic_authorize action_identifier(:reports, :run)
        post api_report_url(nil, report).to_s, :params => { :action => "run" }
      end.to change(MiqReportResult, :count).by(1)
      expect_single_action_result(
        :href    => api_report_url(nil, report),
        :success => true,
        :message => "running report #{report.id}"
      )
      actual = MiqReportResult.find(response.parsed_body["result_id"])
      expect(actual.userid).to eq("api_user_id")
    end

    it "can schedule a run" do
      report = FactoryBot.create(:miq_report)

      expect do
        api_basic_authorize action_identifier(:reports, :schedule)
        post(
          api_report_url(nil, report),
          :params => {
            :action      => 'schedule',
            :name        => 'schedule_name',
            :enabled     => true,
            :description => 'unit test',
            :start_date  => '05/05/2016',
            :interval    => {:unit => 'daily', :value => '110'},
            :time_zone   => 'UTC'
          }
        )
      end.to change(MiqSchedule, :count).by(1)
      expect_single_action_result(
        :href    => api_report_url(nil, report),
        :success => true,
        :message => "scheduling of report #{report.id}"
      )
    end

    it "can import a report" do
      serialized_report = {
        :menu_name => "Test Report",
        :col_order => %w(foo bar baz),
        :cols      => %w(foo bar baz),
        :rpt_type  => "Custom",
        :title     => "Test Report",
        :db        => "My::Db",
        :rpt_group => "Custom"
      }
      options = {:save => true}

      api_basic_authorize collection_action_identifier(:reports, :import)

      expect do
        post api_reports_url, :params => gen_request(:import, :report => serialized_report, :options => options)
      end.to change(MiqReport, :count).by(1)
      expect_result_to_match_hash(
        response.parsed_body["results"].first["result"],
        "name"      => "Test Report",
        "title"     => "Test Report",
        "rpt_group" => "Custom",
        "rpt_type"  => "Custom",
        "db"        => "My::Db",
        "cols"      => %w(foo bar baz),
        "col_order" => %w(foo bar baz),
      )
      expect_result_to_match_hash(
        response.parsed_body["results"].first,
        "message" => "Imported Report: [Test Report]",
        "success" => true
      )
      expect(response).to have_http_status(:ok)
    end

    it "can import multiple reports in a single call" do
      serialized_report = {
        :menu_name => "Test Report",
        :col_order => %w(foo bar baz),
        :cols      => %w(foo bar baz),
        :rpt_type  => "Custom",
        :title     => "Test Report",
        :db        => "My::Db",
        :rpt_group => "Custom"
      }
      serialized_report2 = {
        :menu_name => "Test Report 2",
        :col_order => %w(qux quux corge),
        :cols      => %w(qux quux corge),
        :rpt_type  => "Custom",
        :title     => "Test Report 2",
        :db        => "My::Db",
        :rpt_group => "Custom"
      }
      options = {:save => true}

      api_basic_authorize collection_action_identifier(:reports, :import)

      expect do
        post(
          api_reports_url,
          :params => gen_request(
            :import,
            [{:report => serialized_report, :options => options},
             {:report => serialized_report2, :options => options}]
          )
        )
      end.to change(MiqReport, :count).by(2)
    end
  end

  context "without an appropriate role" do
    it "cannot run a report" do
      report = FactoryBot.create(:miq_report)

      expect do
        api_basic_authorize
        post api_report_url(nil, report).to_s, :params => { :action => "run" }
      end.not_to change(MiqReportResult, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it "cannot import a report" do
      serialized_report = {
        :menu_name => "Test Report",
        :col_order => %w(foo bar baz),
        :cols      => %w(foo bar baz),
        :rpt_type  => "Custom",
        :title     => "Test Report",
        :db        => "My::Db",
        :rpt_group => "Custom"
      }
      options = {:save => true}

      api_basic_authorize

      expect do
        post api_reports_url, :params => gen_request(:import, :report => serialized_report, :options => options)
      end.not_to change(MiqReport, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
