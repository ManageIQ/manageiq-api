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

    it "cannot find report to fetch report's result" do
      report_result = report.miq_report_results.first
      table = Ruport::Data::Table.new(
          :column_names => %w(foo),
          :data         => [%w(bar), %w(baz)]
      )
      allow(report).to receive(:table).and_return(table)
      allow_any_instance_of(MiqReportResult).to receive(:report_results).and_return(report)

      api_basic_authorize

      other_report = FactoryBot.create(:miq_report_with_results)
      get(api_report_result_url(nil, other_report, report_result))

      expect(response).to have_http_status(:not_found)
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

    context "report result's result_set" do
      let(:columns) { %w[name size] }
      let(:result_set) do
        [{"name" => "VM2", "size" => 115_533},
         {"name" => "VM1", "size" => 332_233},
         {"name" => "VG1", "size" => 112_233}]
      end

      let(:col_formats) { Array.new(columns.count) }
      let(:report_result) { FactoryBot.create(:miq_report_result, :miq_group => user.current_group) }
      let(:report) do
        FactoryBot.create(:miq_report,
                          :miq_group          => user.current_group,
                          :miq_report_results => [report_result],
                          :col_order          => columns,
                          :col_formats        => col_formats)
      end

      before do
        report_result.update(:report => report)
        allow_any_instance_of(MiqReportResult).to receive(:result_set).and_return(result_set)

        api_basic_authorize action_identifier(:results, :read, :resource_actions, :get)
      end

      let(:params) { {:hash_attribute => "result_set"} }

      it_behaves_like "paginated and sorted list", :report
      it_behaves_like "paginated and sorted list", :report_result
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

  context "report results" do
    let(:report)       { FactoryBot.create(:miq_report_with_results, :number_of_results => 2, :miq_group => report_group) }
    let(:report_group) { @user.current_group }
    let(:results)      { report.miq_report_results }

    describe "POST /api/reports/:c_id/results/:s_id with delete action" do
      it "can delete a report results" do
        api_basic_authorize(action_identifier(:reports, :delete, :results_subresource_actions, :post))
        result = results.first

        post(api_report_result_url(nil, report, result), :params => {:action => "delete"})

        expected = {
          "href"    => "http://www.example.com/api/results/#{result.id}",
          "message" => "results id: #{result.id} deleting",
          "success" => true,
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not delete a report result unless authorized" do
        api_basic_authorize
        result = results.first

        post(api_report_result_url(nil, report, result), :params => {:action => "delete"})

        expect(response).to have_http_status(:forbidden)
      end

      context "with an unauthorized user group" do
        let(:report_group) { nil }

        it "raises a 404 with a message that the resource isn't found" do
          api_basic_authorize(action_identifier(:reports, :delete, :results_subresource_actions, :post))
          result = results.first

          post(api_report_result_url(nil, report, result), :params => {:action => "delete"})

          expected = {
            "error" => a_hash_including(
              "kind"  => "not_found",
              "klass" => "ActiveRecord::RecordNotFound"
            )
          }
          expect(response.parsed_body).to include(expected)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "POST /api/reports/:c_id/results with delete action" do
      it "can queue multiple snapshots for deletion" do
        api_basic_authorize(action_identifier(:reports, :delete, :results_subresource_actions, :post))

        post(
          api_report_results_url(nil, report),
          :params => {
            :action    => "delete",
            :resources => [
              {:href => api_report_result_url(nil, report, results.first)},
              {:href => api_report_result_url(nil, report, results.last)}
            ]
          }
        )

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(
              "success" => true,
              "message" => "results id: #{results.first.id} deleting",
              "href"    => api_result_url(nil, results.first)
            ),
            a_hash_including(
              "success" => true,
              "message" => "results id: #{results.last.id} deleting",
              "href"    => api_result_url(nil, results.last)
            )
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "raises a 404 with proper message if a resource isn't found" do
        api_basic_authorize(action_identifier(:reports, :delete, :results_subresource_actions, :post))
        fake_id = results.last.id + 1

        post(
          api_report_results_url(nil, report),
          :params => {
            :action    => "delete",
            :resources => [{:href => api_report_result_url(nil, report, fake_id)}]
          }
        )

        expected = {
          "results" => [{
            "message" => a_string_starting_with("Couldn't find MiqReportResult with 'id'=#{fake_id}"),
            "success" => false
          }]
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(200)
      end
    end

    describe "DELETE /api/vms/:c_id/snapshots/:s_id" do
      it "can delete a report results" do
        api_basic_authorize(action_identifier(:reports, :delete, :results_subresource_actions, :delete))
        result = results.first

        delete(api_report_result_url(nil, report, result))

        expect(response).to have_http_status(:no_content)
        expect(report.reload.miq_report_results.count).to eq(1)
      end

      it "will not delete a report result unless authorized" do
        api_basic_authorize
        result = results.first

        post(api_report_result_url(nil, report, result), :params => {:action => "delete"})

        expect(response).to have_http_status(:forbidden)
      end

      context "with an unauthorized user group" do
        let(:report_group) { nil }

        it "raises a 404 with a message that the resource isn't found" do
          api_basic_authorize(action_identifier(:reports, :delete, :results_subresource_actions, :post))
          result = results.first

          post(api_report_result_url(nil, report, result), :params => {:action => "delete"})

          expected = {
            "error" => a_hash_including(
              "kind"  => "not_found",
              "klass" => "ActiveRecord::RecordNotFound"
            )
          }
          expect(response.parsed_body).to include(expected)
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
