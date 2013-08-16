require 'zucchini/reporters/tap'
require 'zucchini/reporters/html'

class Zucchini::Report
  def initialize(features, ci = false, reports_dir)
    FileUtils.mkdir_p(reports_dir)

    @paths = {
      :html => "#{reports_dir}/zucchini_report.html",
      :tap  => "#{reports_dir}/zucchini.t"
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
