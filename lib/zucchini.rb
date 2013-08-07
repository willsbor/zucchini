$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

module Zucchini
  require 'zucchini/config'
  require 'zucchini/screenshot'
  require 'zucchini/report'
  require 'zucchini/compiler'
  require 'zucchini/feature'
  require 'zucchini/detector'
  require 'zucchini/runner'
  require 'zucchini/generator'
  require 'zucchini/approver'
end
