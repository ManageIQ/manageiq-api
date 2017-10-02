RSpec.describe Api::Href do
  describe ".new" do
    context "with a full url for the href" do
      let(:href) { "http://localhost:3000/api/collection/123" }

      it "can parse the resource and resource id" do
        expect(described_class.new(href)).to have_attributes(:subject => :collection, :subject_id => "123")
      end
    end

    context "with a full url for the href and a API version" do
      let(:href) { "http://localhost:3000/api/v1.2.3/collection/123" }

      it "can parse the resource and resource id" do
        expect(described_class.new(href)).to have_attributes(:subject => :collection, :subject_id => "123")
      end
    end

    context "with a partial URL that starts with '/api/...'" do
      let(:href) { "/api/collection/123" }

      it "can parse the resource and resource id" do
        expect(described_class.new(href)).to have_attributes(:subject => :collection, :subject_id => "123")
      end
    end

    context "with a partial URL that starts with '/api/v1.2.3/...'" do
      let(:href) { "/api/v1.2.3/collection/123" }

      it "can parse the resource and resource id" do
        expect(described_class.new(href)).to have_attributes(:subject => :collection, :subject_id => "123")
      end
    end

    context "with a partial URL that starts with 'api/...'" do
      let(:href) { "api/collection/123" }

      it "can parse the resource and resource id" do
        expect(described_class.new(href)).to have_attributes(:subject => :collection, :subject_id => "123")
      end
    end

    context "with a partial URL that starts with 'api/v1.2.3/...'" do
      let(:href) { "api/v1.2.3/collection/123" }

      it "can parse the resource and resource id" do
        expect(described_class.new(href)).to have_attributes(:subject => :collection, :subject_id => "123")
      end
    end

    context "with a partial URL without '/api/...'" do
      let(:href) { "collection/123" }

      it "can parse the resource and resource id" do
        expect(described_class.new(href)).to have_attributes(:subject => :collection, :subject_id => "123")
      end
    end

    context "with a partial URL without '/api/...' and a leading slash" do
      let(:href) { "/collection/123" }

      it "can parse the resource and resource id" do
        expect(described_class.new(href)).to have_attributes(:subject => :collection, :subject_id => "123")
      end
    end

    it "can parse entrypoint urls" do
      href = "http://localhost:3000/api"
      expect(described_class.new(href).subject).to be_nil
    end
  end
end
