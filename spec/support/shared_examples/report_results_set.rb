RSpec.shared_examples "paginated and sorted list" do |collection_route|
  class_eval do
    def report_result_api_url_for(route, report, report_result)
      if route == :report
        api_result_url(nil, report_result)
      elsif route == :report_result
        api_report_result_url(nil, report, report_result)
      else
        raise NotImplementedError, "Can't find url helper for #{route}."
      end
    end
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

    get report_result_api_url_for(collection_route, report, report_result), :params => params
    expect_result_to_match_hash(response.parsed_body, "result_set" => result_set_sorted_by_name)
    expect(response).to have_http_status(:ok)
  end

  it "returns sorted result_set according to string column and default formatting, sort_order=descending" do
    params[:sort_by] = 'name'
    params[:sort_order] = 'desc'
    get report_result_api_url_for(collection_route, report, report_result), :params => params
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
    get report_result_api_url_for(collection_route, report, report_result), :params => params
    expect_result_to_match_hash(response.parsed_body, "result_set" => result_set_sorted_by_size)
    expect(response).to have_http_status(:ok)
  end

  it "returns sorted result_set according to integer column and default formatting, sort_order=descending" do
    params[:sort_by] = 'size'
    params[:sort_order] = 'desc'
    get report_result_api_url_for(collection_route, report, report_result), :params => params
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
      get report_result_api_url_for(collection_route, report, report_result), :params => params
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
      get report_result_api_url_for(collection_route, report, report_result), :params => params

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
      get report_result_api_url_for(collection_route, report, report_result), :params => params

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
      get report_result_api_url_for(collection_route, report, report_result), :params => params
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
      get report_result_api_url_for(collection_route, report, report_result), :params => params
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
      get report_result_api_url_for(collection_route, report, report_result), :params => params
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
      get report_result_api_url_for(collection_route, report, report_result), :params => params
      expect_result_to_match_hash(response.parsed_body, "result_set" => filtered_result_set_ascending)
      expect(response).to have_http_status(:ok)
    end

    it "returns filtered(in formatted output) and sorted result_set according to integer column and default formatting, sort_order=ascending" do
      params[:sort_by] = 'size'
      params[:sort_order] = 'asc'
      params[:filter_column] = 'size'
      params[:filter_string] = 'GB'
      get report_result_api_url_for(collection_route, report, report_result), :params => params
      expect_result_to_match_hash(response.parsed_body, "result_set" => [{"name" => "VG1", "size" => "1 GB"}])
      expect(response).to have_http_status(:ok)
    end
  end
end
