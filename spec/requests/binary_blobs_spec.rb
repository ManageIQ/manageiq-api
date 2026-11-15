describe "Binary Blobs API" do
  let(:blob_path) { "payloads/ansible.zip" }
  let(:blob_data) { "binary payload data" }
  let(:blob) do
    BinaryBlob.new(:path => blob_path, :content_type => "application/zip").tap do |b|
      b.binary = blob_data.dup
    end
  end

  def presigned_url(method, expires_in: 300)
    Api::Presigner.presign(
      :method     => method,
      :path       => blob_path,
      :expires_in => expires_in,
      :base_url   => "http://www.example.com"
    )
  end

  def query_params_for(method, expires_in: 300)
    URI.decode_www_form(URI.parse(presigned_url(method, :expires_in => expires_in)).query).to_h
  end

  before do
    MiqDatabase.seed
  end

  describe "GET /api/binary_blobs/*blob_path" do
    context "with a valid pre-signed URL" do
      it "returns the object body with correct content-type" do
        blob.save!
        get presigned_url("GET")

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(blob_data)
        expect(response.headers["Content-Type"]).to include("application/zip")
      end
    end

    context "when the blob does not exist" do
      it "returns a 404 JSON error" do
        get presigned_url("GET")

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body.dig("error", "kind")).to eq("not_found")
      end
    end

    context "with an expired pre-signed URL" do
      it "returns a 401 JSON error" do
        blob.save!
        get presigned_url("GET", :expires_in => -1)

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body.dig("error", "message")).to include("expired")
      end
    end

    context "with a tampered signature" do
      it "returns a 401 JSON error" do
        blob.save!
        params = query_params_for("GET")
        params[Api::Presigner::PARAM_SIGNATURE] = "invalidsignature"
        get "/api/binary_blobs/#{blob_path}?#{URI.encode_www_form(params)}"

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body.dig("error", "kind")).to eq("unauthorized")
      end
    end

    context "with missing pre-signed URL parameters" do
      it "returns a 401 JSON error" do
        get "/api/binary_blobs/#{blob_path}"

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body.dig("error", "kind")).to eq("unauthorized")
      end
    end

    context "with a signature for the wrong method" do
      it "returns a 401 JSON error" do
        blob.save!
        get presigned_url("DELETE")

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body.dig("error", "kind")).to eq("unauthorized")
      end
    end
  end

  describe "PUT /api/binary_blobs/*blob_path" do
    let(:put_url) { presigned_url("PUT") }

    context "with a valid pre-signed URL" do
      it "creates a new blob and returns 200" do
        put put_url, :env => {"RAW_POST_DATA" => blob_data, "CONTENT_TYPE" => "application/zip"}

        expect(response).to have_http_status(:ok)
        stored = BinaryBlob.find_by(:path => blob_path)
        expect(stored).not_to be_nil
        expect(stored.binary).to eq(blob_data)
        expect(stored.content_type).to eq("application/zip")
      end

      it "overwrites an existing blob" do
        blob.save!
        new_data = "updated payload"
        put put_url, :env => {"RAW_POST_DATA" => new_data, "CONTENT_TYPE" => "application/zip"}

        expect(response).to have_http_status(:ok)
        expect(BinaryBlob.where(:path => blob_path).count).to eq(1)
        expect(BinaryBlob.find_by(:path => blob_path).binary).to eq(new_data)
      end
    end

    context "when the payload exceeds the upload limit" do
      it "returns a 400 JSON error" do
        stub_const("Api::BinaryBlobsController::MAX_UPLOAD_SIZE", 10)
        oversized = "x" * 11
        put put_url, :env => {"RAW_POST_DATA" => oversized, "CONTENT_TYPE" => "application/zip"}

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body.dig("error", "message")).to include("Payload exceeds")
      end
    end

    context "with an invalid signature" do
      it "returns a 401 JSON error" do
        put "/api/binary_blobs/#{blob_path}?#{Api::Presigner::PARAM_SIGNATURE}=bad",
            :env => {"RAW_POST_DATA" => blob_data, "CONTENT_TYPE" => "application/zip"}

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body.dig("error", "kind")).to eq("unauthorized")
      end
    end
  end

  describe "DELETE /api/binary_blobs/*blob_path" do
    context "with a valid pre-signed URL" do
      it "deletes the blob and returns 204" do
        blob.save!
        delete presigned_url("DELETE")

        expect(response).to have_http_status(:no_content)
        expect(BinaryBlob.find_by(:path => blob_path)).to be_nil
      end
    end

    context "when the blob does not exist" do
      it "returns a 404 JSON error" do
        delete presigned_url("DELETE")

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body.dig("error", "kind")).to eq("not_found")
      end
    end

    context "with an invalid signature" do
      it "returns a 401 JSON error" do
        blob.save!
        delete "/api/binary_blobs/#{blob_path}"

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body.dig("error", "kind")).to eq("unauthorized")
      end
    end
  end
end
