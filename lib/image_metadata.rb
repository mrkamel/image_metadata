
require "image_metadata/version"
require "exiv2"
require "tempfile_for"

class ImageMetadata
  class KeyNotFoundError < StandardError; end
  class SaveError < StandardError; end

  Config = {
    jpegoptim: "/usr/bin/jpegoptim",
    exiv2: "/usr/bin/exiv2"
  }

  MAPPING = {
    caption: {
      iptc: { key: "Iptc.Application2.Caption", type: "String" },
      xmp: { key: "Xmp.dc.description", type: "LangAlt" }
    },
    writer: {
      iptc: { key: "Iptc.Application2.Writer", type: "String" },
      xmp: { key: "Xmp.photoshop.CaptionWriter", type: "XmpText" }
    },
    headline: {
      iptc: { key: "Iptc.Application2.Headline", type: "String" },
      xmp: { key: "Xmp.photoshop.Headline", type: "XmpText" }
    },
    instructions: {
      iptc: { key: "Iptc.Application2.SpecialInstructions", type: "String" },
      xmp: { key: "Xmp.photoshop.Instructions", type: "XmpText" }
    },
    creator: {
      iptc: { key: "Iptc.Application2.Byline", type: "String" },
      xmp: { key: "Xmp.dc.creator", type: "XmpSeq" }
    },
    creator_title: {
      iptc: { key: "Iptc.Application2.BylineTitle", type: "String" },
      xmp: { key: "Xmp.photoshop.AuthorsPosition", type: "XmpText" }
    },
    credit: {
      iptc: { key: "Iptc.Application2.Credit", type: "String" },
      xmp: { key: "Xmp.photoshop.Credit", type: "XmpText" }
    },
    source: {
      iptc: { key: "Iptc.Application2.Source", type: "String" },
      xmp: { key: "Xmp.photoshop.Source", type: "XmpText" }
    },
    title: {
      iptc: { key: "Iptc.Application2.ObjectName", type: "String" },
      xmp: { key: "Xmp.dc.title", type: "LangAlt" }
    },
    city: {
      iptc: { key: "Iptc.Application2.City", type: "String" },
      xmp: { key: "Xmp.photoshop.City", type: "XmpText" }
    },
    province: {
      iptc: { key: "Iptc.Application2.ProvinceState", type: "String" },
      xmp: { key: "Xmp.photoshop.State", type: "XmpText" }
    },
    country: {
      iptc: { key: "Iptc.Application2.CountryName", type: "String" },
      xmp: { key: "Xmp.photoshop.Country", type: "XmpText" }
    },
    transmission: {
      iptc: { key: "Iptc.Application2.TransmissionReference", type: "String" },
      xmp: { key: "Xmp.photoshop.TransmissionReference", type: "XmpText" }
    },
    keywords: {
      iptc: { key: "Iptc.Application2.Keywords", type: "String" },
      xmp: { key: "Xmp.dc.subject", type: "XmpBag" }
    },
    copyright: {
      iptc: { key: "Iptc.Application2.Copyright", type: "String" },
      xmp: { key: "Xmp.dc.rights", type: "LangAlt" }
    },
    reference: {
      iptc: { key: "Iptc.Application2.ReferenceNumber", type: "String" }
    },
    camera: {
      exif: { key: "Exif.Image.Model", type: "Ascii" }
    },
    manufacturer: {
      exif: { key: "Exif.Image.Make", type: "Ascii" }
    },
    latitude: {
      exif: { key: "Exif.GPSInfo.GPSLatitude", type: "XmpText" }
    },
    latitude_ref: {
      exif: { key: "Exif.GPSInfo.GPSLatitudeRef", type: "XmpText" },
    },
    longitude: {
      exif: { key: "Exif.GPSInfo.GPSLongitude", type: "XmpText" }
    },
    longitude_ref: {
      exif: { key: "Exif.GPSInfo.GPSLongitudeRef", type: "XmpText" },
    }
  }

  def initialize(path)
    @path = path
    @data = {}

    @image = Exiv2::ImageFactory.open(path)
    @image.read_metadata
  end

  def self.strip(path)
    raise(SaveError, "jpegoptim is missing") unless File.executable?(Config[:jpegoptim])

    `#{Config[:jpegoptim]} --strip-xmp --strip-com --strip-iptc --strip-exif #{path.shellescape}`

    $?.success?
  end

  def to_hash
    MAPPING.keys.each_with_object({}) { |key, hash| hash[key] = self[key] }
  end

  def update(hash)
    hash.each do |key, value|
      self[key] = value
    end
  end

  def []=(key, value)
    raise KeyNotFoundError unless MAPPING[key]

    @data[key] = value
  end

  def [](key)
    raise KeyNotFoundError unless MAPPING[key]

    return @data[key] if @data.key?(key)

    if iptc = MAPPING[key][:iptc]
      return @image.iptc_data[iptc[:key]]
    end

    if xmp = MAPPING[key][:xmp]
      return @image.xmp_data[xmp[:key]]
    end

    if exif = MAPPING[key][:exif]
      return @image.exif_data[exif[:key]]
    end

    nil
  end

  def save(iptc_encoding = Encoding::UTF_8)
    raise(SaveError, "exiv2 is missing") unless File.executable?(Config[:exiv2])

    Tempfile.for iptc_commands(iptc_encoding) do |tempfile|
      system "/usr/bin/exiv2", "-m", tempfile.path, @path

      return false unless $?.success?
    end

    Tempfile.for xmp_commands do |tempfile|
      system "/usr/bin/exiv2", "-m", tempfile.path, @path

      return false unless $?.success?
    end

    true
  end

  def save!(*args)
    raise(SaveError, "Unable to save metadata") unless save(*args)
  end

  private

  def iptc_commands(encoding)
    commands = data_for(:iptc).map { |key, value| command :iptc, key, value }
    commands.push("set Iptc.Envelope.CharacterSet String #{encoding}") unless commands.empty?

    commands.join("\n").encode(encoding, undef: :replace, invalid: :replace, replace: "")
  end

  def data_for(type)
    @data.select { |key, value| MAPPING[key][type] }
  end

  def xmp_commands
    data_for(:xmp).map { |key, value| command :xmp, key, value }.join("\n")
  end

  def exif_commands
    data_for(:exif).map { |key, value| command :exif, key, value }.join("\t")
  end

  def command(type, key, value)
    mapping = MAPPING[key][type]

    res = ["del #{mapping[:key]}"]

    if value.is_a?(Array)
      value.each do |element|
        res.push("#{type == :xmp || type == :exif ? "set" : "add"} #{mapping[:key]} #{mapping[:type]} #{element}") if element && element.to_s.length > 0
      end
    else
      res.push("set #{mapping[:key]} #{mapping[:type]} #{value}") if value && value.to_s.length > 0
    end

    res
  end
end

