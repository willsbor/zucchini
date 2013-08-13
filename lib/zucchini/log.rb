require 'plist'

class Zucchini::Log
  YAML_FILE = 'screenshots.yml'

  def initialize(path)
    screenshot_log_path = File.join(path, YAML_FILE)
    raise "Screenshot log not found at #{screenshot_log_path}" unless File.exists?(screenshot_log_path)
    @screenshots = File.open(screenshot_log_path, 'r') { |f| YAML.load(f) }
  end

  def exists?
    @screenshots != nil
  end

  def screenshot_metadata(sequence_number)
    return {} unless @screenshots
    raise "Invalid screenshot sequence number #{sequence_number}" if sequence_number > @screenshots.size
    @screenshots[sequence_number - 1]
  end

  def self.parse_automation_log(path, screenshot_log_path = nil)
    automation_log_path = File.join(path, 'Automation Results.plist')

    if File.exists?(automation_log_path)
      log = Plist::parse_xml(automation_log_path)
      raise "Automation log at #{log_path} could not be parsed" unless log
      entries = log["All Samples"]
      screenshots = []

      entries.each do |entry|
        next unless entry['LogType'] == 'Default'
        match = entry["Message"].match(/Screenshot of screen '(?<screen>[^']*)' taken with orientation '(?<orientation>[^']*)'/)
        
        if match
          metadata = {:screen => match[:screen], :orientation => match[:orientation] }
          screenshots << metadata
        end
      end

      screenshot_log_path ||= File.join(path, YAML_FILE)
      File.open(screenshot_log_path, 'w') {|f| f.write(screenshots.to_yaml) }
    else
      puts "Warning: automation log not found at #{automation_log_path}"
    end
  end
end

     