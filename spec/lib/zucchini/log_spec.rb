require 'spec_helper'
require 'tmpdir'

describe Zucchini::Log do
  let(:base_path)                     { './spec/sample_setup/feature_one' }
  let (:run_data_path)                { "#{base_path}/run_data/Run\ 1" }
  let (:expected_screenshot_log)      { "#{run_data_path}/screenshots.yml" }
  let (:actual_screenshot_log)        { File.join(Dir.mktmpdir, 'screenshots.yml') }

  it "should parse automation log" do
    Zucchini::Log.parse_automation_log(run_data_path, actual_screenshot_log)
    File.read(actual_screenshot_log).should == File.read(expected_screenshot_log)
  end
end
