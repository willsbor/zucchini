class Zucchini::Approver < Zucchini::Detector
  parameter "PATH", "a path to feature or a directory"

  option %W(-p --pending), :flag, "update pending screenshots instead"
  option "--tomask",       :flag, "transfer diff image to mask image"

  def run_command
    reference_type = pending? ? "pending" : "reference"
    features.each do |f|
      f.device = @device
      if tomask?
        f.approve_tomask
      else
        f.approve reference_type
      end
    end
    features.inject(true){ |result, feature| result &= feature.succeeded }
  end
end
