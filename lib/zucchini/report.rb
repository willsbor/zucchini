require 'erb'
require 'zucchini/report/view'

class Zucchini::Report

  def initialize(features, ci = false, paths = nil)
    @paths = paths || {
      :html => '/tmp/zucchini_report.html',
      :tap  => '/tmp/zucchini.t'
    }
    @features, @ci = [features, ci]
    generate(@paths)
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
    File.read(report_path) + "\nTAP report generated to #{report_path}"
  end

  def html(report_path)
    template_path = File.expand_path("#{File.dirname(__FILE__)}/report/template.erb.html")

    view = Zucchini::ReportView.new(@features, @ci)
    compiled = (ERB.new(File.open(template_path).read)).result(view.get_binding)

    File.open(report_path, 'w+') { |f| f.write(compiled) }

    "HTML report generated to #{report_path}"
  end

  def generate(paths)
    log tap  paths[:tap]
    log html paths[:html]
  end

  def open; system "open #{@paths[:html]}"; end

  def log(buf); puts buf; end
end
