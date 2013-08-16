class Zucchini::Runner < Zucchini::Detector
  parameter "PATH", "a path to feature or a directory"

  option %W(-c --collect), :flag, "only collect the screenshots from the device"
  option %W(-p --compare), :flag, "perform screenshots comparison based on the last collection"
  option %W(-s --silent),  :flag, "do not open the report"
  option "--ci",           :flag, "produce a CI version of the report after comparison"

  option %W(-r --reports-dir), "DIR", "specify the directory for generated reports" , :default => '/tmp'

  def run_command
    compare_threads = {}

    features.each do |f|
      f.device = @device

      if    collect? then f.collect
      elsif compare? then f.compare
      else  f.collect; compare_threads[f.name] = Thread.new { f.compare }
      end
    end

    compare_threads.each { |name, t| t.abort_on_exception = true; t.join }

    unless (collect? && !compare?)
      report = Zucchini::Report.new(features, ci?, reports_dir)
      report.open unless silent?
    end

    features.inject(true){ |result, feature| result &= feature.succeeded }
  end
end
