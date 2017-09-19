RSpec.describe Api do
  describe ".compressed_id?" do
    it "returns true for a compressed id" do
      expect(Api.compressed_id?("1r1")).to be(true)
    end

    it "returns false for an uncompressed id" do
      expect(Api.compressed_id?(1_000_000_000_001)).to be(false)
      expect(Api.compressed_id?("1000000000001")).to be(false)
    end

    it "returns false for nil" do
      expect(Api.compressed_id?(nil)).to be(false)
    end
  end
end
