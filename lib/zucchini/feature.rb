class Zucchini::Feature
  include Zucchini::Compiler
  include Zucchini::Device

  attr_accessor :path
  attr_accessor :device
  attr_accessor :stats
  attr_accessor :js_exception

  attr_reader :succeeded
  attr_reader :name

  def initialize(path)
    @path         = path
    @name         = File.basename(path)
    @device       = nil
    @succeeded    = false
    @js_exception = false
  end

  def run_data_path
     "#{@path}/run_data"
  end

  def unmatched_pending_screenshots
    Dir.glob("#{@path}/pending/#{@device[:screen]}/[^0-9]*.png").sort.map do |file|
      screenshot = Zucchini::Screenshot.new(file, nil, true)
      screenshot.test_path = File.expand_path(file)
      screenshot.diff = [:pending, "unmatched"]
      screenshot
    end
  end

  def screenshots(process = true)
    @screenshots ||= Dir.glob("#{run_data_path}/Run\ 1/*.png").sort.map do |file|
      screenshot = Zucchini::Screenshot.new(file, @device)
      if process
        screenshot.mask
        screenshot.compare
      end
      screenshot
    end + unmatched_pending_screenshots
  end

  def stats
    @stats ||= screenshots.inject({:passed => [], :failed => [], :pending => []}) do |stats, s|
      stats[s.diff[0]] << s
      stats
    end
  end

  def collect
    with_setup do
      `rm -rf #{run_data_path}/*`

      begin
        out = `instruments #{device_params(@device)} \
               -t "#{Zucchini::Config.template}" "#{Zucchini::Config.app}" \
               -e UIASCRIPT "#{compile_js(@device[:orientation])}" \
               -e UIARESULTSPATH "#{run_data_path}" 2>&1`
        puts out
        # Hack. Instruments don't issue error return codes when JS exceptions occur
        @js_exception = true if (out.match /JavaScript error/) || (out.match /Instruments\ .{0,5}\ Error\ :/ )
      ensure
        `rm -rf instrumentscli*.trace`
      end
    end
  end

  def compare
    `rm -rf #{run_data_path}/Diff/*`
    @succeeded = !@js_exception && (stats[:failed].length == 0)
  end

  def with_setup
    setup = "#{@path}/setup.rb"
    if File.exists?(setup)
      require setup
      begin
        Setup.before { yield }
      ensure
        Setup.after
      end
    else
      yield
    end
  end

  def approve(reference_type)
    raise "Directory #{path} doesn't contain previous run data" unless File.exists?("#{run_data_path}/Run\ 1")

    screenshots(false).each do |s|
      reference_file_path = "#{File.dirname(s.file_path)}/../../#{reference_type}/#{device[:screen]}/#{s.file_name}"
      FileUtils.mkdir_p File.dirname(reference_file_path)
      @succeeded = FileUtils.copy_file(s.file_path, reference_file_path)
    end
  end
end
