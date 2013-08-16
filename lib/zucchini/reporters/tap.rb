module Zucchini::Reporter
  module TAP
    extend self

    def generate(features, report_path)
      File.open(report_path, 'w+') do |io|
        io.puts "1..#{features.length}"
        features.each_with_index do |f, i|
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
          io.puts '    Bail out! Instruments run error' if f.js_exception
        end
        io.close
      end
      File.read(report_path) + "\nTAP report generated to #{report_path}"
    end
  end
end
