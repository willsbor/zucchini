require 'spec_helper'
require 'digest/md5'
require 'tmpdir'

def md5(blob)
  Digest::MD5.hexdigest(blob)
end

describe Zucchini::Screenshot do
  describe "general" do
    let (:device)             { { :name => "iPhone 4S", :screen => "retina_ios5", :udid => "rspec987654" } }
    let (:screen)             { "splash" }
    let (:base_path)          { "spec/sample_setup/feature_one" }
    let (:original_path)      { "#{base_path}/run_data/Run\ 1/06_splash-screen_sign\ up_spinner.png" }
    
    before do
      @screenshot = Zucchini::Screenshot.new(original_path, device)
      @screenshot.masked_paths = {
        :global   => "#{base_path}/global_masked.png",
        :screen   => "#{base_path}/screen_masked.png",
        :specific => "#{base_path}/specific_masked.png"
      }
    end

    after do 
      FileUtils.mv(@screenshot.file_path, original_path) if File.exists?(@screenshot.file_path)
      
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
        File.exists?(@screenshot.masked_paths[:global]).should be true
        checksums[:global_masked].should_not be_equal checksums[:original]
      end

      it "should apply a screen-specific mask if it exists" do
        @screenshot.mask
        File.exists?(@screenshot.masked_paths[:screen]).should be true
        checksums[:screen_masked].should_not be_equal checksums[:original]
        checksums[:specific_masked].should_not be_equal checksums[:global_masked]
      end

      it "should not apply a screen mask if it does not exist" do
        @screenshot.masks_paths[:screen] = nil
        @screenshot.mask
        File.exists?(@screenshot.masked_paths[:screen]).should_not be true
        checksums[:global_masked].should_not be_equal checksums[:original]
      end

      it "should not apply a specific mask if it does not exist" do
        @screenshot.masks_paths[:specific] = nil
        @screenshot.mask
        File.exists?(@screenshot.masked_paths[:specific]).should_not be true
        checksums[:global_masked].should_not be_equal checksums[:original]
      end
      
      it "should apply a screenshot-specific mask if it exists" do
        @screenshot.mask
        File.exists?(@screenshot.masked_paths[:specific]).should be true
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
          @screenshot.stub!(:mask_reference)
          @screenshot.test_path = "#{base_path}/reference/#{device[:screen]}/06_sign\ up_spinner_error.png"
          @screenshot.mask
          @screenshot.compare
          @screenshot.diff.should eq [:failed, "188162"]
        end

        it "should have a failed indicator in the diff with no screen mask" do
          @screenshot.stub!(:mask_reference)
          @screenshot.test_path = "#{base_path}/reference/#{device[:screen]}/06_sign\ up_spinner_error.png"
          @screenshot.masks_paths[:screen] = nil
          @screenshot.mask
          @screenshot.compare
          @screenshot.diff.should eq [:failed, "3017"]
        end
      end
    end
    
    describe "mask reference" do
      it "should create masked versions of reference screenshots" do
        @screenshot.mask
        @screenshot.mask_reference
        
        File.exists?(@screenshot.test_path).should be_true
        md5(File.read(@screenshot.test_path)).should_not be_equal md5(File.read("#{base_path}/reference/#{device[:screen]}/06_sign\ up_spinner.png"))
      end
    end
  end

  describe "rotate" do
    let (:sample_screenshots_path) { "spec/sample_screenshots" }
    let (:reference_screenshot_path) { File.join(sample_screenshots_path, "rotated/01_Screenshot.png") }
    let (:reference_md5) { md5(File.read(reference_screenshot_path)) }
    let (:temp_dir) { Dir.mktmpdir }
    before do
      `cp #{File.join(sample_screenshots_path, "*")} #{temp_dir}`
    end

    it "should rotate the landscape-left screenshot" do
      screenshot = Zucchini::Screenshot.new(File.join(temp_dir,'01_LandscapeLeft_Screenshot.png'), nil, true)
      File.exists?(File.join(temp_dir,'01_LandscapeLeft_Screenshot.png')).should be_false
      File.exists?(File.join(temp_dir,'01_Screenshot.png')).should be_true
    end

    it "should rotate the landscape-right screenshot" do
      screenshot = Zucchini::Screenshot.new(File.join(temp_dir,'02_LandscapeRight_Screenshot.png'), nil, true)
      File.exists?(File.join(temp_dir,'02_LandscapeRight_Screenshot.png')).should be_false
      File.exists?(File.join(temp_dir,'02_Screenshot.png')).should be_true
    end

    it "should rotate the upside-down screenshot" do
      screenshot = Zucchini::Screenshot.new(File.join(temp_dir,'03_PortraitUpsideDown_Screenshot.png'), nil, true)
      File.exists?(File.join(temp_dir,'02_PortraitUpsideDown_Screenshot.png')).should be_false
      File.exists?(File.join(temp_dir,'03_Screenshot.png')).should be_true
    end

    after do
      FileUtils.remove_entry temp_dir
    end
  end
end
