class Zucchini::Detector < Clamp::Command
  attr_reader :features

  parameter "PATH", "a path to feature or a directory"

  def execute
    raise "Directory #{path} does not exist" unless File.exists?(path)

    @path = File.expand_path(path)
    
    base_path = File.exists?("#{path}/support") ? path : base_path(path)
    raise "No support directory found in parent folders from path #{path}" unless !base_path.nil?
    
    Zucchini::Config.base_path = base_path

    @device = Zucchini::Config.device(ENV['ZUCCHINI_DEVICE'])

    exit run_command
  end

  def base_path(leaf_path)
    base_path = nil
    current_folder = File.dirname(leaf_path)
    while current_folder != "/"
      
      if  File.exists?("#{current_folder}/support")
        base_path = current_folder
        break
      end

      current_folder = File.dirname(current_folder)
    end

    base_path
  end

  def run_command; end

  def features
    @features ||= detect_features(@path)
  end

  def detect_features(path)
    features = []
    if File.exists?("#{path}/feature.zucchini")
      features << Zucchini::Feature.new(path)
    else
      feature_files = Dir.glob("#{path}/**/feature.zucchini")
      raise detection_error(path) if feature_files.empty?

      feature_files.each do |feature_file|
        features << Zucchini::Feature.new(File.dirname(feature_file))
      end
    end
    features
  end

  def detection_error(path)
    "#{path} does not contain any features"
  end
end
