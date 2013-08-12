class Zucchini::Screenshot
  FILE_NAME_PATTERN = /^\d\d_((?<orientation>Unknown|Portrait|PortraitUpsideDown|LandscapeLeft|LandscapeRight|FaceUp|FaceDown)_)?((?<screen>.*)-screen_)?.*$/

  attr_reader   :file_path, :original_file_path, :file_name
  attr_accessor :diff, :masks_paths, :masked_paths, :test_path, :diff_path

  def initialize(file_path, device, unmatched_pending = false)
    @original_file_path = file_path
    @file_path = file_path.dup

    @device = device

    match = FILE_NAME_PATTERN.match(File.basename(@file_path))

    if match
      @orientation = match[:orientation]
      @screen      = match[:screen]
      @file_path.gsub!("_#{@screen}-screen", '') if @screen
      @file_path.gsub!("_#{@orientation}", '')   if @orientation
    end

    @file_name = File.basename(@file_path)

    unless unmatched_pending
      file_base_path = File.dirname(@file_path)

      support_masks_path = "#{file_base_path}/../../../support/masks"

      @masks_paths = {
        :global   => "#{support_masks_path}/#{@device[:screen]}.png",
        :screen   => "#{support_masks_path}/#{@screen.to_s.underscore}.png",
        :specific => "#{file_base_path}/../../masks/#{@device[:screen]}/#{@file_name}"
      }

      masked_path   = "#{file_base_path}/../Masked/actual/#{@file_name}"
      @masked_paths = { :global => masked_path, :screen => masked_path, :specific => masked_path }

      @diff_path = "#{file_base_path}/../Diff/#{@file_name}"
    end

    preprocess
  end

  def preprocess
    return if @original_file_path == @file_path

    if @orientation
      rotate
    else
      FileUtils.rm @file_path if File.exists?(@file_path)
      FileUtils.mv @original_file_path, @file_path
    end
  end

  def mask
    create_masked_paths_dirs
    masked_path = apply_mask(@file_path, :global)

    if mask?(:screen)
      masked_path = apply_mask(masked_path, :screen)
    end

    if mask?(:specific)
      apply_mask(masked_path, :specific)
    end
  end

  def compare
    mask_reference

    if @test_path
      FileUtils.mkdir_p(File.dirname(@diff_path))

      compare_command = "compare -metric AE -fuzz 2% -dissimilarity-threshold 1 -subimage-search"
      out = `#{compare_command} \"#{@masked_paths[:specific]}\" \"#{@test_path}\" \"#{@diff_path}\" 2>&1`
      out.chomp!
      @diff = (out == '0') ? [:passed, nil] : [:failed, out]
      @diff = [:pending, @diff[1]] if @pending
    else
      @diff = [:failed, "no reference or pending screenshot for #{@device[:screen]}\n"]
    end
  end

  def result_images
    @result_images ||= {
      :actual     => @masked_paths && File.exists?(@masked_paths[:specific]) ? @masked_paths[:specific] : nil,
      :expected   => @test_path    && File.exists?(@test_path) ? @test_path : nil,
      :difference => @diff_path    && File.exists?(@diff_path) ? @diff_path : nil
    }
  end

  def mask_reference
    file_base_path = File.dirname(@file_path)
    %W(reference pending).each do |reference_type|
      reference_file_path = "#{file_base_path}/../../#{reference_type}/#{@device[:screen]}/#{@file_name}"
      output_path         = "#{file_base_path}/../Masked/#{reference_type}/#{@file_name}"

      if File.exists?(reference_file_path)
        @test_path = output_path
        @pending   = (reference_type == "pending")
        FileUtils.mkdir_p(File.dirname(output_path))

        reference = Zucchini::Screenshot.new(reference_file_path, @device)
        reference.masks_paths  = @masks_paths
        reference.masked_paths = { :global => output_path, :screen => output_path, :specific => output_path }
        reference.mask
      end
    end
  end

  private
  def mask?(mask)
    @masks_paths[mask] && File.exists?(@masks_paths[mask])
  end

  def create_masked_paths_dirs
    @masked_paths.each { |name, path| FileUtils.mkdir_p(File.dirname(path)) }
  end

  def apply_mask(src_path, mask)
    mask_path   = @masks_paths[mask]
    dest_path   = @masked_paths[mask]
    `convert -page +0+0 \"#{src_path}\" -page +0+0 \"#{mask_path}\" -flatten \"#{dest_path}\"`
    return dest_path
  end

  def rotate
    degrees = case @orientation
    when 'LandscapeRight' then 90
    when 'LandscapeLeft' then 270
    when 'PortraitUpsideDown' then 180
    else
      0
    end
    `convert \"#{@original_file_path}\" -rotate \"#{degrees}\" \"#{@file_path}\"`
    FileUtils.rm @original_file_path
  end
end

class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end
