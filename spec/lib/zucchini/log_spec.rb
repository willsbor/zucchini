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

  it "should get screenshot metadata" do
    metadata = Zucchini::Log.new(run_data_path).screenshot_metadata(1)
    metadata[:orientation].should == 'Portrait'
    metadata[:screen].should == 'splash'
    metadata[:rotated].should_not be_true
  end

  it "should mark a screenshot as rotated" do
    FileUtils.cp expected_screenshot_log, actual_screenshot_log
    log = Zucchini::Log.new(File.dirname(actual_screenshot_log))
    log.mark_screenshot_as_rotated(1)
    log.save
    log = Zucchini::Log.new(File.dirname(actual_screenshot_log))
    log.screenshot_metadata(1)[:rotated].should be_true
  end
end
