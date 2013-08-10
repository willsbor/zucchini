class Zucchini::Detector < Clamp::Command
  attr_reader :features

  parameter "PATH", "a path to feature or a directory"

  def execute
    raise "Directory #{path} does not exist" unless File.exists?(path)

    @path = File.expand_path(path)
    Zucchini::Config.base_path = File.exists?("#{path}/feature.zucchini") ? File.dirname(path) : path

    @device = Zucchini::Config.device(ENV['ZUCCHINI_DEVICE'])

    exit run_command
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
      raise detection_error(path) if Dir["#{path}/*"].empty?

      Dir.glob("#{path}/*").each do |dir|
          unless dir.match /support/
          if File.exists?("#{dir}/feature.zucchini")
            features << Zucchini::Feature.new(dir)
          else
            raise detection_error(dir)
          end
        end
      end
    end
    features
  end

  def detection_error(path)
    "#{path} is not a feature directory"
  end
end
