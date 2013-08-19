class Zucchini::Screenshot
  FILE_NAME_PATTERN = /^(?<sequence_number>\d\d)_(?<screenshot_name>[^\.]*)\.png$/

  attr_reader   :file_path, :original_file_path, :file_name
  attr_accessor :diff, :mask_paths, :masked_paths, :test_path, :diff_path

  def initialize(file_path, device, log, unmatched_pending = false)
    @file_path = file_path
    @log = log
    @device = device
    
    @file_name = File.basename(@file_path)
    match = FILE_NAME_PATTERN.match(@file_name)
    raise "Illegal screenshot name #{file_path}" unless match

    @screenshot_name      = match[:screenshot_name]
    @sequence_number      = match[:sequence_number].to_i

    @file_name = File.basename(@file_path)

    unless unmatched_pending
      run_data_path      = File.dirname(@file_path)
      support_path       = File.join(run_data_path, '../../../support')

      if @log
        metadata     = @log.screenshot_metadata(@sequence_number)
        @orientation = metadata[:orientation]
        @screen      = metadata[:screen]
        @rotated     = metadata[:rotated]
      end

      if @orientation && !@rotated
        rotate
        @log.mark_screenshot_as_rotated(@sequence_number)
        @log.save
      end

      @mask_paths = {
        :global   => mask_path(File.join(support_path,  'masks',         @device[:screen])),
        :specific => mask_path(File.join(run_data_path, '../../masks',   @device[:screen], @file_name.sub('.png', ''))),
        :screen   => mask_path(File.join(support_path,  'screens/masks', @device[:screen], @screen.to_s.underscore))
      }

      masked_path   = File.join(run_data_path, "../Masked/actual/#{@file_name}")
      @masked_paths = { :global => masked_path, :screen => masked_path, :specific => masked_path }

      @diff_path = "#{run_data_path}/../Diff/#{@file_name}"
    end
  end

  def mask
    create_masked_paths_dirs
    masked_path = apply_mask(@file_path, :global)

    if mask_present?(:screen)
      masked_path = apply_mask(masked_path, :screen)
    end

    if mask_present?(:specific)
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
      @diff = [:failed, "no reference or pending screenshot for #{@device[:screen]}"]
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
    run_data_path = File.dirname(@file_path)
    %W(reference pending).each do |reference_type|
      reference_file_path = "#{run_data_path}/../../#{reference_type}/#{@device[:screen]}/#{@file_name}"
      output_path         = "#{run_data_path}/../Masked/#{reference_type}/#{@file_name}"

      if File.exists?(reference_file_path)
        @test_path = output_path
        @pending   = (reference_type == "pending")
        FileUtils.mkdir_p(File.dirname(output_path))

        reference = Zucchini::Screenshot.new(reference_file_path, @device, @log)
        reference.mask_paths  = @mask_paths
        reference.masked_paths = { :global => output_path, :screen => output_path, :specific => output_path }
        reference.mask
      end
    end
  end

  def self.valid?(file_path)
    FILE_NAME_PATTERN =~ File.basename(file_path)
  end

  private
  def mask_path(path)
    suffix = case @orientation
    when 'LandscapeRight', 'LandscapeLeft' then '_landscape'
    when 'Portrait', 'PortraitUpsideDown'  then '_portrait'
    else
      ''
    end
    
    file_path = path + suffix + '.png'
    file_path = path + '.png' unless File.exists?(file_path)

    File.expand_path(file_path)
  end

  def mask_present?(mask)
    @mask_paths[mask] && File.exists?(@mask_paths[mask])
  end

  def create_masked_paths_dirs
    @masked_paths.each { |name, path| FileUtils.mkdir_p(File.dirname(path)) }
  end

  def apply_mask(src_path, mask)
    mask_path = @mask_paths[mask]
    dest_path = @masked_paths[mask]
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
    
    `mogrify -rotate \"#{degrees}\" \"#{@file_path}\"` if degrees > 0
    @rotated = true
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
