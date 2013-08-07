require 'coveralls'
require 'simplecov'

if ENV['COVERAGE'] == 'coveralls'
  Coveralls.wear!
else
  SimpleCov.start do
    add_filter "/spec/"
  end
end

require 'clamp'
require 'fileutils'

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '..'))
require 'lib/zucchini'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = :doc
end
