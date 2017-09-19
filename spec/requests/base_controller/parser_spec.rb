describe Api::BaseController do
  describe "Parser" do
    describe "#parse_href" do
      context "with a full url for the href" do
        let(:href) { "http://localhost:3000/api/collection/123" }

        it "returns ['collection', 123]" do
          expect(subject.parse_href(href)).to eq([:collection, 123])
        end
      end

      context "with a full url for the href and a API version" do
        let(:href) { "http://localhost:3000/api/v1.2.3/collection/123" }

        it "returns ['collection', 123]" do
          expect(subject.parse_href(href)).to eq([:collection, 123])
        end
      end

      context "with a partial URL that starts with '/api/...'" do
        let(:href) { "/api/collection/123" }

        it "returns ['collection', 123]" do
          expect(subject.parse_href(href)).to eq([:collection, 123])
        end
      end

      context "with a partial URL that starts with '/api/v1.2.3/...'" do
        let(:href) { "/api/v1.2.3/collection/123" }

        it "returns ['collection', 123]" do
          expect(subject.parse_href(href)).to eq([:collection, 123])
        end
      end

      context "with a partial URL without '/api/...'" do
        let(:href) { "collection/123" }

        it "returns ['collection', 123]" do
          expect(subject.parse_href(href)).to eq([:collection, 123])
        end
      end
    end
  end
end
