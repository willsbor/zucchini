require 'zucchini/reporters/tap'
require 'zucchini/reporters/html'

class Zucchini::Report
  def initialize(features, ci = false, paths = nil)
    @paths = paths || {
      :html => '/tmp/zucchini_report.html',
      :tap  => '/tmp/zucchini.t'
    }
    generate(features, ci, @paths)
  end

  def generate(features, ci, paths)
    log Zucchini::Reporter::TAP.generate  features, paths[:tap]
    log Zucchini::Reporter::HTML.generate features, paths[:html], ci
  end

  def open; system "open #{@paths[:html]}"; end

  def log(buf); puts buf; end
end
