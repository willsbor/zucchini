require 'spec_helper'
require 'digest/md5'
require 'tmpdir'

def md5(blob)
  Digest::MD5.hexdigest(blob)
end

describe Zucchini::Screenshot do
  let (:device)                       { { :name => "iPhone 4S", :screen => "retina_ios5", :udid => "rspec987654" } }
  let (:device2)                      { { :name => "iPhone 3G", :screen => "low_ios6", :udid => "rspec987655" } }
  let (:screen)                       { "splash" }
  let (:base_path)                    { "spec/sample_setup/feature_one" }
  let (:run_data_path)                { "#{base_path}/run_data/Run\ 1" }
  let (:reference_dir)                { "#{base_path}/reference/retina_ios5" }
  let (:temp_dir)                     { Dir.mktmpdir }
  let (:screenshot_names)             { [ "01_sign\ up_spinner.png",
                                          "02_sign\ up_spinner.png",
                                          "03_sign\ up_spinner.png",
                                          "04_sign\ up_spinner.png" ] }
  let (:screenshot_paths)             { screenshot_names.map{|name| File.join(run_data_path, name)} }
  let (:original_screenshot_paths)    { screenshot_names.map{|name| File.join(temp_dir, name)} }
  let (:reference_screenshot_paths)   { screenshot_names.map{|name| File.join(reference_dir, name)} }
  let (:log)                          { Zucchini::Log.new(run_data_path) }
  let (:original_screenshot_log_path) { File.join(temp_dir, 'screenshots.yml') }

  before(:each) do
    FileUtils.cp log.screenshot_log_path, original_screenshot_log_path
    screenshot_paths.each_with_index do |path, index|
      FileUtils.cp path, original_screenshot_paths[index]
    end
  end

  after(:each) do
    FileUtils.rm log.screenshot_log_path
    FileUtils.mv original_screenshot_log_path, log.screenshot_log_path

    screenshot_paths.each_with_index do |path, index|
      FileUtils.rm path
      FileUtils.mv original_screenshot_paths[index], path
    end

    FileUtils.remove_entry temp_dir
  end

  describe "general" do
    before(:each) do
      @screenshot = Zucchini::Screenshot.new(screenshot_paths[0], device, log)
      @screenshot.masked_paths = {
        :global   => "#{base_path}/global_masked.png",
        :screen   => "#{base_path}/screen_masked.png",
        :specific => "#{base_path}/specific_masked.png"
      }
    end

    after(:each) do 
      @screenshot.masked_paths.each do |k, path|
        FileUtils.rm(path) if File.exists?(path)
      end
      
      FileUtils.rm_rf("#{base_path}/run_data/Masked")
      FileUtils.rm_rf(@screenshot.diff_path)
    end
    
    describe "mask" do
      let (:checksums) {
        checksums = {}

        checksums[:original] = md5(File.read(@screenshot.file_path))

        if File.exists?(@screenshot.masked_paths[:global])
          checksums[:global_masked] = md5(File.read(@screenshot.masked_paths[:global]))
        end

        if File.exists?(@screenshot.masked_paths[:screen])
          checksums[:screen_masked] = md5(File.read(@screenshot.masked_paths[:screen]))
        end

        if File.exists?(@screenshot.masked_paths[:specific])
          checksums[:specific_masked] = md5(File.read(@screenshot.masked_paths[:specific]))
        end

        checksums
      }

      it "should apply a standard global mask based on the device" do
        @screenshot.mask
        File.exists?(@screenshot.masked_paths[:global]).should be_true
        checksums[:global_masked].should_not be_equal checksums[:original]
      end

      it "should apply a screen-specific mask if it exists" do
        @screenshot.mask
        File.exists?(@screenshot.masked_paths[:screen]).should be_true
        checksums[:screen_masked].should_not be_equal checksums[:original]
        checksums[:specific_masked].should_not be_equal checksums[:global_masked]
      end

      it "should not apply a screen mask if it does not exist" do
        @screenshot.mask_paths[:screen] = nil
        @screenshot.mask
        File.exists?(@screenshot.masked_paths[:screen]).should_not be_true
        checksums[:global_masked].should_not be_equal checksums[:original]
      end

      it "should not apply a specific mask if it does not exist" do
        @screenshot.mask_paths[:specific] = nil
        @screenshot.mask
        File.exists?(@screenshot.masked_paths[:specific]).should_not be_true
        checksums[:global_masked].should_not be_equal checksums[:original]
      end
      
      it "should apply a screenshot-specific mask if it exists" do
        @screenshot.mask
        File.exists?(@screenshot.masked_paths[:specific]).should be_true
        checksums[:specific_masked].should_not be_equal checksums[:original]
        checksums[:specific_masked].should_not be_equal checksums[:screen_masked]
        checksums[:specific_masked].should_not be_equal checksums[:global_masked]
      end
    end                                                     
    
    describe "compare" do
      context "images are identical" do
        it "should have a passed indicator in the diff" do
          @screenshot.mask
          @screenshot.compare
          @screenshot.diff.should eq [:passed, nil]
        end
      end
      
      context "images are different" do
        it "should have a failed indicator in the diff" do
          @screenshot.stub(:mask_reference)
          @screenshot.test_path = "#{base_path}/reference/#{device[:screen]}/01_sign\ up_spinner_error.png"
          @screenshot.mask
          @screenshot.compare
          @screenshot.diff.should eq [:failed, "46500"]
        end

        it "should have a failed indicator in the diff with no screen mask" do
          @screenshot.stub(:mask_reference)
          @screenshot.test_path = "#{base_path}/reference/#{device[:screen]}/01_sign\ up_spinner_error.png"
          @screenshot.mask_paths[:screen] = nil
          @screenshot.mask
          @screenshot.compare
          @screenshot.diff.should eq [:failed, "12966"]
        end
      end
    end
    
    describe "mask reference" do
      it "should create masked versions of reference screenshots" do
        @screenshot.mask
        @screenshot.mask_reference
        
        File.exists?(@screenshot.test_path).should be_true
        md5(File.read(@screenshot.test_path)).should_not be_equal md5(File.read("#{base_path}/reference/#{device[:screen]}/01_sign\ up_spinner.png"))
      end
    end
  end

  describe 'mask paths' do
    let(:screenshot1)  {Zucchini::Screenshot.new(screenshot_paths[0], device, log)}
    let(:screenshot2)  {Zucchini::Screenshot.new(screenshot_paths[1], device, log)}
    let(:screenshot3)  {Zucchini::Screenshot.new(screenshot_paths[2], device2, log)}
    let(:screenshot4)  {Zucchini::Screenshot.new(screenshot_paths[3], device, log)}

    it "should have correct global mask path with no orientation" do
      screenshot1.mask_paths[:global].should include 'retina_ios5'
    end

    it "should have correct screen mask path with no orientation" do
      screenshot1.mask_paths[:screen].should include 'splash'
    end

    it "should have correct specific mask path with no orientation" do
      screenshot1.mask_paths[:specific].should include 'spinner'
    end

    it "should have correct global mask path with landscape orientation and mask available" do
      screenshot2.mask_paths[:global].should include 'landscape'
    end

    it "should have correct screen mask path with landscape orientation and mask available" do
      screenshot2.mask_paths[:screen].should include 'landscape'
    end

    it "should have correct specific mask path with landscape orientation and mask available" do
      screenshot2.mask_paths[:specific].should include 'landscape'
    end

    it "should have correct global mask path with portrait orientation and mask available" do
      screenshot4.mask_paths[:global].should include 'portrait'
    end

    it "should have correct screen mask path with portrait orientation and mask available" do
      screenshot4.mask_paths[:screen].should include 'portrait'
    end

    it "should have correct specific mask path with portrait orientation and mask available" do
      screenshot4.mask_paths[:specific].should include 'portrait'
    end

    it "should have correct global mask path with landscape orientation and no mask available" do
      screenshot3.mask_paths[:global].should_not include 'landscape'
    end

    it "should have correct screen mask path with landscape orientation and no mask available" do
      screenshot3.mask_paths[:screen].should_not include 'landscape'
    end

    it "should have correct specific mask path with landscape orientation and no mask available" do
      screenshot3.mask_paths[:specific].should_not include 'landscape'
    end
  end

  describe "rotate" do
    def compare_rotated_screenshot(sequence_number)
      index = sequence_number - 1
      path = screenshot_paths[index]
      @screenshot = Zucchini::Screenshot.new(path, device, log)
      @screenshot.stub(:mask_reference)
      @screenshot.test_path = reference_screenshot_paths[index]
      @screenshot.masked_paths[:specific] = path
      @screenshot.compare
      FileUtils.rm_rf(@screenshot.diff_path)
      @screenshot.diff.should eq [:passed, nil]
    end

    it "should not rotate the portrait screenshot" do
      compare_rotated_screenshot 1
    end

    it "should rotate the landscape-left screenshot" do
       compare_rotated_screenshot 2
    end

    it "should rotate the landscape-right screenshot" do
       compare_rotated_screenshot 3
    end

    it "should rotate the upside-down screenshot" do
       compare_rotated_screenshot 4
    end

    it "should only rotate screenshot once" do
      sequence_number = 2
      compare_rotated_screenshot sequence_number
      Zucchini::Screenshot.new(screenshot_paths[sequence_number - 1], device, log)
      @screenshot.compare
      FileUtils.rm_rf(@screenshot.diff_path)
      @screenshot.diff.should eq [:passed, nil]
    end

    it "should mark screenshots as rotated" do
      sequence_number = 2
      Zucchini::Screenshot.new(screenshot_paths[sequence_number - 1], device, log)
      log.screenshot_metadata(sequence_number)[:rotated].should be_true
    end
  end
end
