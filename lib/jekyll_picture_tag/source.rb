# Generates a string value to serve as the srcset attribute for a given
# <source> or <img> tag.
class Source < SingleTag
  attr_reader :name

  def initialize(instructions, source_name)
    @instructions = instructions
    @name = source_name
    @files = build_files

    super 'source', attributes: @instructions.attributes[:source]
  end

  def build_files
    files = []
    pixel_ratios.each do |p|
      files << GeneratedImage.new(
        source_image: source_image,
        output_dir: @instructions.dest_dir,
        size: size(p),
        format: source_preset['format']
      )
    end
  end

  def source_preset
    @instructions.preset['sources'][name]
  end

  def size(pixel_ratio)
    unless source_preset['width'] || source_preset['height']
      raise "#{@instructions.preset_name}:"\
        " #{name} must include either a width or a height."
    end

    {
      width: source_preset['width'],
      height: source_preset['height'],
      pixel_ratio: pixel_ratio
    }
  end

  def source_image
    file_array = [@instructions.source_dir, @instructions.source_images[name]]
    filename = File.join(*file_array)
    return file_array if File.exist?(filename)

    raise "Could not find #{filename}"
  end

  def pixel_ratios
    if @instructions.preset['pixel_ratios']
      @instructions.preset['pixel_ratios'].map(&:to_i)
    else
      [1]
    end
  end

  def srcset
    set = files.collect do |f|
      url = Pathname.join(@instructions.url_prefix, f.name)

      "#{url} #{f.pixel_ratio}x"
    end

    set.join ', '
  end

  def to_s
    rewrite_attributes srcset: srcset, media: source_preset['media']
    super
  end
end