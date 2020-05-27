RSpec.describe "results request downloads" do
  let(:columns_1) { %w[name size] }
  let(:result_set_1) do
    [
      {"name" => "VM2", "size" => 115_533},
      {"name" => "VM1", "size" => 332_233},
      {"name" => "VG1", "size" => 112_233}
    ]
  end

  let(:task_results_1_txt) do
    "------------------------+
|   VMware VM Summary   |
+-----------------------+
|  VM Name |  Size      |
+-----------------------+
| VM2      | 115_533    |
| VM1      | 332_233    |
| VG1      | 112_233    |
+-----------------------+"
  end

  let(:task_results_1_csv) do
    "\"VM Name\", \"Size\"
VM2,115_533
VM1,332_233
VG1,112_233"
  end

  let(:task_results_1_pdf) do
    "%PDF-1.5
PDF Report"
  end

  let(:col_formats_1) { Array.new(columns_1.count) }
  let(:result_1) { FactoryBot.create(:miq_report_result, :miq_group => @group) }
  let(:report_1) do
    report = MiqReport.create(
      :name          => "VMs based on Disk Type",
      :title         => "VMs using thin provisioned disks",
      :rpt_group     => "Custom",
      :rpt_type      => "Custom",
      :db            => "VmInfra",
      :cols          => ["name"],
      :col_order     => ["name"],
      :headers       => ["Name"],
      :order         => "Ascending",
      :template_type => "report"
    )
    report.generate_table(:userid => @user.userid)
    report
  end

  let(:task_1) { FactoryBot.create(:miq_task) }
  let(:result_1) { report_1.build_create_results({:userid => @user.userid}, task_1.id) }

  def task_results_url(task)
    "#{api_task_url(nil, task)}/task_results"
  end

  context "request downloads" do
    it "fail if not authorized" do
      result = FactoryBot.create(:miq_report_with_results, :miq_group => @group).miq_report_results.first

      api_basic_authorize

      post(api_result_url(nil, result), :params => gen_request(:request_download, :result_type => "txt"))
      expect(response).to have_http_status(:forbidden)
    end

    it "fail with unrelated authorization" do
      result = FactoryBot.create(:miq_report_with_results, :miq_group => @group).miq_report_results.first

      api_basic_authorize :some_unrelated_entitlement

      post(api_result_url(nil, result), :params => gen_request(:request_download, :result_type => "txt"))
      expect(response).to have_http_status(:forbidden)
    end

    it "fail if result_type is not specified" do
      result = FactoryBot.create(:miq_report_with_results, :miq_group => @group).miq_report_results.first

      api_basic_authorize action_identifier(:results, :request_download, :resource_actions, :post)

      post(api_result_url(nil, result), :params => gen_request(:request_download))
      expect_single_action_result(:success => false, :message => "Missing result_type")
    end

    it "fail if result_type is bogus and the PdfGenerator is not available" do
      expect(PdfGenerator.instance).to receive(:available?).and_return(false)

      result = FactoryBot.create(:miq_report_with_results, :miq_group => @group).miq_report_results.first

      api_basic_authorize action_identifier(:results, :request_download, :resource_actions, :post)

      post(api_result_url(nil, result), :params => gen_request(:request_download, :result_type => "bogus"))
      expect_single_action_result(:success => false, :message => "Unsupported result_type bogus specified, must be one of txt, csv.")
    end

    it "fail if result_type is bogus and the PdfGenerator is available" do
      expect(PdfGenerator.instance).to receive(:available?).and_return(true)

      result = FactoryBot.create(:miq_report_with_results, :miq_group => @group).miq_report_results.first

      api_basic_authorize action_identifier(:results, :request_download, :resource_actions, :post)

      post(api_result_url(nil, result), :params => gen_request(:request_download, :result_type => "bogus"))
      expect_single_action_result(:success => false, :message => "Unsupported result_type bogus specified, must be one of txt, csv, pdf.")
    end

    it "succeeds if result_type is txt" do
      api_basic_authorize action_identifier(:results, :request_download, :resource_actions, :post)

      post(api_result_url(nil, result_1), :params => gen_request(:request_download, :result_type => "txt"))

      expected = {
        "success"           => true,
        "message"           => "Requesting a download of a txt report for Result id:#{result_1.id} name:'#{result_1.name}'",
        "task_id"           => /\d+/,
        "task_href"         => a_string_matching(api_tasks_url),
        "task_results_href" => a_string_matching(api_tasks_url)
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "succeeds if result_type is csv" do
      api_basic_authorize action_identifier(:results, :request_download, :resource_actions, :post)

      post(api_result_url(nil, result_1), :params => gen_request(:request_download, :result_type => "csv"))

      expected = {
        "success"           => true,
        "message"           => "Requesting a download of a csv report for Result id:#{result_1.id} name:'#{result_1.name}'",
        "task_id"           => /\d+/,
        "task_href"         => a_string_matching(api_tasks_url),
        "task_results_href" => a_string_matching(api_tasks_url)
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "succeeds if result_type is txt and task references match" do
      api_basic_authorize action_identifier(:results, :request_download, :resource_actions, :post)

      post(api_result_url(nil, result_1), :params => gen_request(:request_download, :result_type => "txt"))

      expect(response).to have_http_status(:ok)
      expected = {
        "success" => true,
        "message" => "Requesting a download of a txt report for Result id:#{result_1.id} name:'#{result_1.name}'",
        "task_id" => /\d+/
      }
      expect(response.parsed_body).to include(expected)

      task_id  = response.parsed_body["task_id"]
      expected = {
        "task_href"         => a_string_matching(api_task_url(nil, task_id)),
        "task_results_href" => a_string_matching("#{api_task_url(nil, task_id)}/task_results")
      }
      expect(response.parsed_body).to include(expected)
    end

    it "succeeds and properly defines the task context data" do
      api_basic_authorize action_identifier(:results, :request_download, :resource_actions, :post)

      post(api_result_url(nil, result_1), :params => gen_request(:request_download, :result_type => "txt"))

      expect(response).to have_http_status(:ok)
      expected = {
        "success" => true,
        "message" => "Requesting a download of a txt report for Result id:#{result_1.id} name:'#{result_1.name}'",
        "task_id" => /\d+/
      }
      expect(response.parsed_body).to include(expected)

      task_id = response.parsed_body["task_id"]
      expect(MiqTask.exists?(task_id)).to be_truthy

      task = MiqTask.find(task_id)
      expect(task.context_data).to_not be_nil
      expect(task.context_data).to include(
        :result_id   => result_1.id,
        :result_type => "txt",
        :session_id  => a_string_matching(/[a-z0-9\-]*/)
      )
    end
  end

  context "fetching task results" do
    it "fail if not authorized" do
      api_basic_authorize

      get(task_results_url(task_1))

      expect(response).to have_http_status(:forbidden)
    end

    it "fail if authorized with an unrelated entitlement" do
      api_basic_authorize :some_unrelated_entitlement

      get(task_results_url(task_1))

      expect(response).to have_http_status(:forbidden)
    end

    it "succeeds with the proper authorization" do
      api_basic_authorize entity_action_identifier(:tasks, :task_results, :read, :get).first

      task_1.update_context(:result_id => result_1.id, :result_type => "txt", :session_id => "ab-cd")
      task_1.task_results = task_results_1_txt
      get(task_results_url(task_1))

      expect(response).to have_http_status(:ok)
    end

    it "fails for a report task with missing context_data" do
      api_basic_authorize entity_action_identifier(:tasks, :task_results, :read, :get).first

      task_1.context_data = nil
      task_1.task_results = task_results_1_txt
      get(task_results_url(task_1))

      expect_bad_request("Missing context_data in Task id:#{task_1.id} name:'#{task_1.name}'")
    end

    it "fails for a report task with a missing result_id" do
      api_basic_authorize entity_action_identifier(:tasks, :task_results, :read, :get).first

      task_1.update_context(:result_type => "txt", :session_id => "ab-cd")
      task_1.task_results = task_results_1_txt
      get(task_results_url(task_1))

      expect_bad_request("Missing result_id in Task id:#{task_1.id} name:'#{task_1.name}'")
    end

    it "fails for a report task with a missing result_type" do
      api_basic_authorize entity_action_identifier(:tasks, :task_results, :read, :get).first

      task_1.update_context(:result_id => result_1.id, :session_id => "ab-cd")
      task_1.task_results = task_results_1_txt
      get(task_results_url(task_1))

      expect_bad_request("Missing result_type in Task id:#{task_1.id} name:'#{task_1.name}'")
    end

    it "fails for a report task with a missing session_id" do
      api_basic_authorize entity_action_identifier(:tasks, :task_results, :read, :get).first

      task_1.update_context(:result_id => result_1.id, :result_type => "txt")
      task_1.task_results = task_results_1_txt
      get(task_results_url(task_1))

      expect_bad_request("Missing session_id in Task id:#{task_1.id} name:'#{task_1.name}'")
    end

    it "succeeds for a txt download" do
      api_basic_authorize entity_action_identifier(:tasks, :task_results, :read, :get).first

      task_1.update_context(:result_id => result_1.id, :result_type => "txt", :session_id => "ab-cd")
      task_1.task_results = task_results_1_txt
      get(task_results_url(task_1))

      expect(response).to have_http_status(:ok)
      expect(response.header["Content-Type"]).to eq("application/text")
      expect(response.header["Content-Disposition"]).to eq("attachment; filename=\"results_#{result_1.id}_report.txt\"")
      expect(response.body).to eq(task_results_1_txt)
    end

    it "succeeds for a csv download" do
      api_basic_authorize entity_action_identifier(:tasks, :task_results, :read, :get).first

      task_1.update_context(:result_id => result_1.id, :result_type => "csv", :session_id => "ab-cd")
      task_1.task_results = task_results_1_csv
      get(task_results_url(task_1))

      expect(response).to have_http_status(:ok)
      expect(response.header["Content-Type"]).to eq("application/csv")
      expect(response.header["Content-Disposition"]).to eq("attachment; filename=\"results_#{result_1.id}_report.csv\"")
      expect(response.body).to eq(task_results_1_csv)
    end

    it "fails for a pdf download if the PdfGenerator is not available" do
      expect(PdfGenerator.instance).to receive(:available?).and_return(false)
      api_basic_authorize entity_action_identifier(:tasks, :task_results, :read, :get).first

      task_1.update_context(:result_id => result_1.id, :result_type => "pdf", :session_id => "ab-cd")
      task_1.miq_report_result = result_1
      get(task_results_url(task_1))

      expect_bad_request("Unsupported result_type pdf specified, must be one of txt, csv.")
    end

    it "succeeds for a pdf download if the PdfGenerator is available" do
      expect(PdfGenerator.instance).to receive(:available?).and_return(true)
      allow_any_instance_of(MiqReportResult).to receive(:to_pdf).and_return(task_results_1_pdf)
      api_basic_authorize entity_action_identifier(:tasks, :task_results, :read, :get).first

      task_1.update_context(:result_id => result_1.id, :result_type => "pdf", :session_id => "ab-cd")
      task_1.miq_report_result = result_1
      get(task_results_url(task_1))

      expect(response).to have_http_status(:ok)
      expect(response.header["Content-Type"]).to eq("application/pdf")
      expect(response.header["Content-Disposition"]).to eq("attachment; filename=\"results_#{result_1.id}_report.pdf\"")
      expect(response.body).to eq(task_results_1_pdf)
    end
  end
end
