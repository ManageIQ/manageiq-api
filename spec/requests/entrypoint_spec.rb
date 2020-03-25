RSpec.describe "API entrypoint" do
  it "returns a :settings hash" do
    api_basic_authorize

    get api_entrypoint_url

    expect(response).to have_http_status(:ok)
    expect_result_to_have_keys(%w(settings))
    expect(response.parsed_body['settings']).to be_kind_of(Hash)
  end

  it "returns a locale" do
    api_basic_authorize

    get api_entrypoint_url

    expect(%w(en en_US)).to include(response.parsed_body['settings']['locale'])
  end

  it "returns users's settings" do
    api_basic_authorize

    test_settings = {:cartoons => {:saturday => {:tom_jerry => 'n', :bugs_bunny => 'y'}}}
    @user.update!(:settings => test_settings)

    get api_entrypoint_url

    expect(response.parsed_body).to include("settings" => a_hash_including(test_settings.deep_stringify_keys))
  end

  it "collection query is sorted" do
    api_basic_authorize

    get api_entrypoint_url

    collection_names = response.parsed_body['collections'].map { |c| c['name'] }
    expect(collection_names).to eq(collection_names.sort)
  end

  it "returns server_info" do
    api_basic_authorize

    Timecop.freeze(Time.utc(2018, 0o1, 0o1, 0o0, 0o0, 0o0)) do
      get api_entrypoint_url

      expect(response.parsed_body).to include(
        "server_info" => a_hash_including(
          "version"         => Vmdb::Appliance.VERSION,
          "build"           => Vmdb::Appliance.BUILD,
          "release"         => Vmdb::Appliance.RELEASE,
          "appliance"       => MiqServer.my_server.name,
          "time"            => "2018-01-01T00:00:00Z",
          "server_href"     => api_server_url(nil, MiqServer.my_server),
          "zone_href"       => api_zone_url(nil, MiqServer.my_server.zone),
          "region_href"     => api_region_url(nil, MiqRegion.my_region),
          "enterprise_href" => api_enterprise_url(nil, MiqEnterprise.my_enterprise)
        )
      )
    end
  end

  it "returns product_info" do
    api_basic_authorize

    get api_entrypoint_url

    expect(response.parsed_body).to include(
      "product_info" => a_hash_including(
        "name"                 => Vmdb::Appliance.PRODUCT_NAME,
        "name_full"            => I18n.t("product.name_full"),
        "copyright"            => I18n.t("product.copyright"),
        "support_website"      => ::Settings.docs.product_support_website,
        "support_website_text" => ::Settings.docs.product_support_website_text
      )
    )

    expect(response.parsed_body['product_info']['branding_info'].keys).to match_array(%w[brand favicon logo])
  end

  context 'UI is available' do
    it 'product_info contains branding_info' do
      api_basic_authorize

      expect(ActionController::Base.helpers).to receive(:image_path).at_least(2).times.and_return("foo")

      get api_entrypoint_url

      expect(response.parsed_body).to include(
        "product_info" => a_hash_including(
          "branding_info" => a_hash_including(
            "brand"      => "foo",
            "logo"       => "foo"
          )
        )
      )
    end
  end

  it "will squeeze consecutive slashes in the path portion of the URI" do
    api_basic_authorize

    get("http://www.example.com//api")

    expect(response).to have_http_status(:ok)
  end
end
