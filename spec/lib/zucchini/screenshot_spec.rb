require 'spec_helper'
require 'digest/md5'
require 'tmpdir'

def md5(blob)
  Digest::MD5.hexdigest(blob)
end

describe Zucchini::Screenshot do
  let (:device)             { { :name => "iPhone 4S", :screen => "retina_ios5", :udid => "rspec987654" } }
  let (:device2)            { { :name => "iPhone 3G", :screen => "low_ios6", :udid => "rspec987655" } }
  let (:screen)             { "splash" }
  let (:base_path)          { "spec/sample_setup/feature_one" }
  let (:run_data_path)      { "#{base_path}/run_data/Run\ 1" }
  let (:screenshot1_path)   { "#{run_data_path}/01_sign\ up_spinner.png" }
  let (:screenshot2_path)   { "#{run_data_path}/02_LandscapeRight_sign\ up_spinner.png" }
  let (:screenshot3_path)   { "#{run_data_path}/03_LandscapeRight_sign\ up_spinner2.png" }
  let (:screenshot4_path)   { "#{run_data_path}/04_Portrait_sign\ up_spinner.png" }
  let (:log)                { Zucchini::Log.new(run_data_path) }

  describe "general" do
    before do
      @screenshot = Zucchini::Screenshot.new(screenshot1_path, device, log)
      @screenshot.masked_paths = {
        :global   => "#{base_path}/global_masked.png",
        :screen   => "#{base_path}/screen_masked.png",
        :specific => "#{base_path}/specific_masked.png"
      }
    end

    after do 
      FileUtils.mv(@screenshot.file_path, screenshot1_path) if File.exists?(@screenshot.file_path) && @screenshot.file_path != screenshot1_path
      
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
          @screenshot.stub!(:mask_reference)
          @screenshot.test_path = "#{base_path}/reference/#{device[:screen]}/01_sign\ up_spinner_error.png"
          @screenshot.mask
          @screenshot.compare
          @screenshot.diff.should eq [:failed, "188162"]
        end

        it "should have a failed indicator in the diff with no screen mask" do
          @screenshot.stub!(:mask_reference)
          @screenshot.test_path = "#{base_path}/reference/#{device[:screen]}/01_sign\ up_spinner_error.png"
          @screenshot.mask_paths[:screen] = nil
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
        md5(File.read(@screenshot.test_path)).should_not be_equal md5(File.read("#{base_path}/reference/#{device[:screen]}/01_sign\ up_spinner.png"))
      end
    end
  end

  describe 'mask paths' do
    let(:screenshot1)  {Zucchini::Screenshot.new(screenshot1_path, device, log)}
    let(:screenshot2)  {Zucchini::Screenshot.new(screenshot2_path, device, log)}
    let(:screenshot3)  {Zucchini::Screenshot.new(screenshot3_path, device2, log)}
    let(:screenshot4)  {Zucchini::Screenshot.new(screenshot4_path, device, log)}

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

    after do 
      FileUtils.mv(screenshot1.file_path, screenshot1_path) if File.exists?(screenshot1.file_path) && screenshot1.file_path != screenshot1_path
      FileUtils.mv(screenshot2.file_path, screenshot2_path) if File.exists?(screenshot2.file_path) && screenshot2.file_path != screenshot2_path
      FileUtils.mv(screenshot3.file_path, screenshot3_path) if File.exists?(screenshot3.file_path) && screenshot3.file_path != screenshot3_path
      FileUtils.mv(screenshot4.file_path, screenshot4_path) if File.exists?(screenshot4.file_path) && screenshot4.file_path != screenshot4_path
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
      screenshot = Zucchini::Screenshot.new(File.join(temp_dir,'01_LandscapeLeft_Screenshot.png'), nil, nil, true)
      File.exists?(File.join(temp_dir,'01_LandscapeLeft_Screenshot.png')).should be_false
      File.exists?(File.join(temp_dir,'01_Screenshot.png')).should be_true
     end

    it "should rotate the landscape-right screenshot" do
      screenshot = Zucchini::Screenshot.new(File.join(temp_dir,'02_LandscapeRight_Screenshot.png'), nil, nil, true)
      File.exists?(File.join(temp_dir,'02_LandscapeRight_Screenshot.png')).should be_false
      File.exists?(File.join(temp_dir,'02_Screenshot.png')).should be_true
    end

    it "should rotate the upside-down screenshot" do
      screenshot = Zucchini::Screenshot.new(File.join(temp_dir,'03_PortraitUpsideDown_Screenshot.png'), nil, nil, true)
      File.exists?(File.join(temp_dir,'02_PortraitUpsideDown_Screenshot.png')).should be_false
      File.exists?(File.join(temp_dir,'03_Screenshot.png')).should be_true
    end

    it "should choose correct masks" do
    end

    after do
      FileUtils.remove_entry temp_dir
    end
  end
end
