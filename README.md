# ImageMetadata

[![Build Status](https://secure.travis-ci.org/mrkamel/image_metadata.png?branch=master)](http://travis-ci.org/mrkamel/image_metadata)

Read and write iptc, exif and xmp with predefined mappings.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'image_metadata'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install image_metadata

## Usage

Read metadata:

```ruby
image_metadata = ImageMetadata.new("/path/to/image")
image_metadata[:caption] # => ...
image_metadata[:headline] # => ...
# ...
```

Write metadata:

```ruby
image_metadata = ImageMetadata.new("/path/to/image")
image_metadata[:caption] = "Caption"
image_metadata[:headline] = "Headline"
# ...
image_metadata.save!
```

Strip metadata:

```ruby
ImageMetadata.strip("/path/to/image")
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mrkamel/image_metadata.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
