RSpec.describe Api::PictureSerializer do
  describe ".serialize" do
    it "serializes the image_href and extension" do
      picture = FactoryGirl.create(:picture, :extension => "png")

      actual = described_class.serialize(picture)

      expected = {
        "extension"  => "png",
        "image_href" => picture.image_href
      }
      expect(actual).to include(expected)
    end
  end
end
