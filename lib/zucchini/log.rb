require 'plist'

class Zucchini::Log
  YAML_FILE = 'screenshots.yml'

  attr_reader :screenshot_log_path

  def initialize(path)
    @screenshot_log_path = Zucchini::Log.screenshot_log_path(path)
    raise "Screenshot log not found at #{@screenshot_log_path}" unless File.exists?(@screenshot_log_path)
    @screenshots = File.open(@screenshot_log_path, 'r') { |f| YAML.load(f) }
  end

  def screenshot_metadata(sequence_number)
    raise "Invalid screenshot sequence number #{sequence_number}" if sequence_number > @screenshots.size
    @screenshots[sequence_number - 1]
  end

  def mark_screenshot_as_rotated(sequence_number)
    screenshot_metadata(sequence_number)[:rotated] = true
  end

  def save
    File.open(@screenshot_log_path, 'w') {|f| f.write(@screenshots.to_yaml) }
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
        match = entry["Message"].match(/^Screenshot.*screen '(?<screen>[^']*)'.*orientation '(?<orientation>[^']*)'$/)
        
        if match
          metadata = {:screen => match[:screen], :orientation => match[:orientation] }
          screenshots << metadata
        end
      end

      screenshot_log_path ||= File.join(path, YAML_FILE)
      File.open(screenshot_log_path, 'w') {|f| f.write(screenshots.to_yaml) }
      true
    else
      false
    end
  end

  def self.exists?(path)
    File.exists?(screenshot_log_path(path))
  end

  def self.screenshot_log_path(path)
     File.join(path, YAML_FILE)
  end
end

     