describe Api::Presigner do
  let(:path)       { "payloads/ansible.zip" }
  let(:expires_in) { 300 }
  let(:base_url)   { "https://example.com" }

  before do
    MiqDatabase.seed
  end

  describe ".presign" do
    it "returns a URL containing the expected query parameters" do
      url    = described_class.presign(:method => "GET", :path => path, :expires_in => expires_in, :base_url => base_url)
      uri    = URI.parse(url)
      params = URI.decode_www_form(uri.query).to_h

      expect(uri.path).to eq("/api/binary_blobs/#{path}")
      expect(params[described_class::PARAM_ALGORITHM]).to eq(described_class::ALGORITHM)
      expect(params[described_class::PARAM_EXPIRES].to_i).to be_within(5).of(Time.now.utc.to_i + expires_in)
      expect(params[described_class::PARAM_SIGNATURE]).to be_present
    end
  end

  describe ".verify!" do
    it "passes for a valid token" do
      url    = described_class.presign(:method => "GET", :path => path, :expires_in => expires_in, :base_url => base_url)
      params = URI.decode_www_form(URI.parse(url).query).to_h

      expect { described_class.verify!(:method => "GET", :path => path, :params => params) }.not_to raise_error
    end

    it "raises AuthenticationError when expired" do
      url    = described_class.presign(:method => "GET", :path => path, :expires_in => -1, :base_url => base_url)
      params = URI.decode_www_form(URI.parse(url).query).to_h

      expect { described_class.verify!(:method => "GET", :path => path, :params => params) }
        .to raise_error(Api::BaseController::Authentication::AuthenticationError, /expired/)
    end

    it "raises AuthenticationError for wrong method" do
      url    = described_class.presign(:method => "PUT", :path => path, :expires_in => expires_in, :base_url => base_url)
      params = URI.decode_www_form(URI.parse(url).query).to_h

      expect { described_class.verify!(:method => "GET", :path => path, :params => params) }
        .to raise_error(Api::BaseController::Authentication::AuthenticationError, /Invalid/)
    end

    it "raises AuthenticationError for tampered signature" do
      url    = described_class.presign(:method => "GET", :path => path, :expires_in => expires_in, :base_url => base_url)
      params = URI.decode_www_form(URI.parse(url).query).to_h
      params[described_class::PARAM_SIGNATURE] = "tampered"

      expect { described_class.verify!(:method => "GET", :path => path, :params => params) }
        .to raise_error(Api::BaseController::Authentication::AuthenticationError, /Invalid/)
    end

    it "raises AuthenticationError when parameters are missing" do
      expect { described_class.verify!(:method => "GET", :path => path, :params => {}) }
        .to raise_error(Api::BaseController::Authentication::AuthenticationError, /Missing/)
    end
  end
end
