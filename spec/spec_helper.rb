require 'coveralls'
require 'simplecov'

SimpleCov.start do
  add_filter "/spec/"
end
Coveralls.wear! if ENV['COVERAGE'] == 'coveralls'

require 'clamp'
require 'fileutils'

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '..'))
require 'lib/zucchini'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = :doc
end

def compare_image(file1_path, file2_path, diff_path)
  compare_version_string = `compare --version`.strip.split[2].slice(/\d+\.\d+\.\d+/)

  if Gem::Version.new(compare_version_string) < Gem::Version.new('6.8.8')
    compare_command = "compare -metric AE -fuzz 2% -dissimilarity-threshold 1 -subimage-search"
  else
    compare_command = "compare -metric AE -fuzz 2% -dissimilarity-threshold 1"
  end

  out = `#{compare_command} \"#{file1_path}\" \"#{file2_path}\" \"#{diff_path}\" 2>&1`
  out.chomp!
  out = out.split("\n")[0]

  if Gem::Version.new(compare_version_string) < Gem::Version.new('6.8.8')
    @diff = (out == '0') ? [:passed, nil] : [:failed, out]
  else
    @diff = ($?.exitstatus == 0) ? [:passed, nil] : [:failed, out]
  end

end