
require File.expand_path("../spec_helper", __FILE__)

RSpec.describe ImageMetadata do
  let(:fixture) { File.expand_path("../fixtures/image.jpg", __FILE__) }

  it "should read metadata, build a hash from it and store the updated data" do
    data = Tempfile.for(File.binread(fixture)) do |tempfile|
      image_metadata = ImageMetadata.new(tempfile.path)
      image_metadata.update(caption: "Caption", creator: "Creator", city: "City", country: "Country")
      image_metadata.save!
    end

    hash = {}

    Tempfile.for(data) do |tempfile|
      hash = ImageMetadata.new(tempfile.path).to_hash.delete_if { |k, v| v.nil? }
    end

    expect(hash).to eq(caption: "Caption", creator: "Creator", city: "City", country: "Country")
  end
end

