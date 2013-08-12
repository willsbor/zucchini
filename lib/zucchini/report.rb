require 'erb'
require 'zucchini/report/view'

class Zucchini::Report

  def initialize(features, ci = false, html_path = '/tmp/zucchini_report.html', tap_path = '/tmp/zucchini.t')
    @features, @ci, @html_path, @tap_path = [features, ci, html_path, tap_path]
    generate!
  end

  def tap(report_path)
    File.open(report_path, 'w+') do |io|
      io.puts "1..#{@features.length}"
      @features.each_with_index do |f, i|
        io.puts (f.succeeded ? "ok" : "not ok") + " #{i + 1} - #{f.name}"
        io.puts "    1..#{f.screenshots.length}"
        f.screenshots.each_with_index do |s, j|
          failed  = s.diff[0] == :failed
          pending = s.diff[0] == :pending

          out = "    "
          out += failed ? "not ok" : "ok"
          out += " #{j + 1} - #{s.file_name}"
          out += failed  ? " does not match (#{s.diff[1]})" : ''
          out += pending ? " # pending" : ''

          io.puts(out)
        end
      end
      io.close
    end
    File.read(report_path)
  end

  def html(report_path)
    @html ||= begin
      template_path = File.expand_path("#{File.dirname(__FILE__)}/report/template.erb.html")

      view = Zucchini::ReportView.new(@features, @ci)
      compiled = (ERB.new(File.open(template_path).read)).result(view.get_binding)

      File.open(report_path, 'w+') { |f| f.write(compiled) }
      compiled
    end
  end

  def generate!
    log tap(@tap_path)
    html(@html_path)
  end

  def open; system "open #{@html_path}"; end

  def log(buf); puts buf; end
end
