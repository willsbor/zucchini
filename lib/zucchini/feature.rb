class Zucchini::Feature
  attr_accessor :path
  attr_accessor :device
  attr_accessor :template
  attr_accessor :stats

  attr_reader :succeeded
  attr_reader :name

  def initialize(path)
    @path      = path
    @device    = nil
    @succeeded = false
    @name      = File.basename(path)
  end

  def run_data_path
     "#{@path}/run_data"
  end

  def unmatched_pending_screenshots
    Dir.glob("#{@path}/pending/#{@device[:screen]}/[^0-9]*.png").map do |file|
      screenshot = Zucchini::Screenshot.new(file, nil, true)
      screenshot.test_path = File.expand_path(file)
      screenshot.diff = [:pending, "unmatched"]
      screenshot
    end
  end

  def screenshots(process = true)
    @screenshots ||= Dir.glob("#{run_data_path}/Run\ 1/*.png").map do |file|
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

  def compile_js(initial_orientation=0)
    zucchini_base_path = File.expand_path(File.dirname(__FILE__))

    feature_text = File.open("#{@path}/feature.zucchini").read.gsub(/\#.+[\z\n]?/,"").gsub(/\n/, "\\n")
    File.open("#{run_data_path}/feature.coffee", "w+") { |f| f.write("Zucchini.run('#{feature_text}', '#{initial_orientation.to_s}')") }

    cs_paths  = "#{zucchini_base_path}/uia #{@path}/../support/screens"
    cs_paths += " #{@path}/../support/lib" if File.exists?("#{@path}/../support/lib")
    cs_paths += " #{run_data_path}/feature.coffee"

    compile_cmd = "coffee -o #{run_data_path} -j #{run_data_path}/feature.js -c #{cs_paths}"
    system compile_cmd
    unless $?.exitstatus == 0
      raise "Error compiling a feature file: #{compile_cmd}"
    end
  end

  def collect
    with_setup do
      `rm -rf #{run_data_path}/*`
      
      if @device[:name] == "iOS Simulator" || @device[:simulator]
        device_params = ""
        set_simulator_device(@device[:simulator]) if @device[:simulator].is_a?(String)
        initial_orientation = @device[:orientation]
      else
        device_params = "-w #{@device[:udid]}"
      end 

      compile_js(initial_orientation)
      
      begin
        out = `instruments #{device_params} -t "#{@template}" "#{Zucchini::Config.app}" -e UIASCRIPT "#{run_data_path}/feature.js" -e UIARESULTSPATH "#{run_data_path}" 2>&1`
        puts out
        # Hack. Instruments don't issue error return codes when JS exceptions occur
        raise "Instruments run error" if (out.match /JavaScript error/) || (out.match /Instruments\ .{0,5}\ Error\ :/ )
      ensure
        `rm -rf instrumentscli*.trace`
      end
    end
  end

  def compare
    `rm -rf #{run_data_path}/Diff/*`
    @succeeded = (stats[:failed].length == 0)
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

  private
  def set_simulator_device(simulated_device)
    current_simulated_device = `defaults read com.apple.iphonesimulator "SimulateDevice"`.chomp

    if current_simulated_device != simulated_device
      simulator_pid = `ps ax|awk '/[i]Phone Simulator.app\\/Contents\\/MacOS\\/iPhone Simulator/{print $1}'`.chomp
      Process.kill('INT', simulator_pid.to_i) unless simulator_pid.empty?
      `defaults write com.apple.iphonesimulator "SimulateDevice" '"#{simulated_device}"'`
    end
  end
end
