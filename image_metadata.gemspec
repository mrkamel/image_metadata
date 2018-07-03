
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "image_metadata/version"

Gem::Specification.new do |spec|
  spec.name          = "image_metadata"
  spec.version       = ImageMetadata::VERSION
  spec.authors       = ["Benjamin Vetter"]
  spec.email         = ["vetter@plainpicture.de"]

  spec.summary       = %q{Read and write iptc, exif and xmp with predefined mappings}
  spec.description   = %q{Read and write iptc, exif and xmp with predefined mappings}
  spec.homepage      = "https://github.com/mrkamel/image_metadata"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "exiv2"
  spec.add_dependency "tempfile_for"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end