RSpec.describe Api::Uncompressor do
  describe ".uncompress" do
    it "converts compressed ids into uncompressed ids" do
      actual = described_class.uncompress(:id => "1r1")
      expected = {:id => 1_000_000_000_001}
      expect(actual).to eq(expected)
    end

    it "will detect foreign key ids and uncompress them" do
      actual = described_class.uncompress(:vm_or_template_id => "1r1")
      expected = {:vm_or_template_id => 1_000_000_000_001}
      expect(actual).to eq(expected)
    end

    it "will uncompress ids nested in arrays" do
      actual = described_class.uncompress(:dialog_tabs => [{:id => "1r1"}])
      expected = {:dialog_tabs => [{:id => 1_000_000_000_001}]}
      expect(actual).to eq(expected)
    end

    it "will uncompress ids nested in hashes" do
      actual = described_class.uncompress(:content => {:dialog_tabs => [{:id => "1r1"}]})
      expected = {:content => {:dialog_tabs => [{:id => 1_000_000_000_001}]}}
      expect(actual).to eq(expected)
    end

    it "will leave non-id attributes as-is" do
      actual = described_class.uncompress(:foo => "bar")
      expected = {:foo => "bar"}
      expect(actual).to eq(expected)
    end

    it "will preserve the input" do
      body = {:id => "1r1"}
      expect { described_class.uncompress(body) }.not_to change { body }
    end

    it "can handle unexpected input" do
      actual = described_class.uncompress(true)
      expected = true
      expect(actual).to eq(expected)
    end
  end
end
