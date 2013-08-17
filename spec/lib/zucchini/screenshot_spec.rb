require 'spec_helper'
require 'digest/md5'
require 'tmpdir'

def md5(blob)
  Digest::MD5.hexdigest(blob)
end

describe Zucchini::Screenshot do
  let (:device1)                      { { :name => "iPhone 4S", :screen => "retina_ios5", :udid => "rspec987654" } }
  let (:device2)                      { { :name => "iPhone 3G", :screen => "low_ios6", :udid => "rspec987655" } }
  let (:screen)                       { "splash" }
  let (:base_path)                    { File.expand_path("spec/sample_setup") }
  let (:feature_path)                 { "#{base_path}/feature_one" }
  let (:support_path)                 { "#{base_path}/support" }
  let (:run_data_path)                { "#{feature_path}/run_data" }
  let (:run_path)                     { "#{run_data_path}/Run\ 1" }
  let (:reference_dir)                { "#{feature_path}/reference/retina_ios5" }
  let (:temp_dir)                     { Dir.mktmpdir }
  let (:screenshot_names)             { [ "01_sign\ up_spinner.png",
                                          "02_sign\ up_spinner.png",
                                          "03_sign\ up_spinner.png",
                                          "04_sign\ up_spinner.png" ] }
  let (:screenshot_paths)             { screenshot_names.map{|name| File.join(run_path, name)} }
  let (:original_screenshot_paths)    { screenshot_names.map{|name| File.join(temp_dir, name)} }
  let (:reference_screenshot_paths)   { screenshot_names.map{|name| File.join(reference_dir, name)} }
  let (:log)                          { Zucchini::Log.new(run_path) }
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
      @screenshot = Zucchini::Screenshot.new(screenshot_paths[0], device1, log)
      @screenshot.masked_paths = {
        :global   => "#{feature_path}/global_masked.png",
        :screen   => "#{feature_path}/screen_masked.png",
        :specific => "#{feature_path}/specific_masked.png"
      }
    end

    after(:each) do 
      @screenshot.masked_paths.each do |k, path|
        FileUtils.rm(path) if File.exists?(path)
      end
      
      FileUtils.rm_rf("#{run_data_path}/Masked")
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
          @screenshot.test_path = "#{feature_path}/reference/#{device1[:screen]}/01_sign\ up_spinner_error.png"
          @screenshot.mask
          @screenshot.compare
          @screenshot.diff.should eq [:failed, "46500"]
        end

        it "should have a failed indicator in the diff with no screen mask" do
          @screenshot.stub(:mask_reference)
          @screenshot.test_path = "#{feature_path}/reference/#{device1[:screen]}/01_sign\ up_spinner_error.png"
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
        md5(File.read(@screenshot.test_path)).should_not be_equal md5(File.read("#{feature_path}/reference/#{device1[:screen]}/01_sign\ up_spinner.png"))
      end
    end
  end

  describe 'mask paths' do
    def test_mask_path(device, screen_name, sequence_number, expected_mask_suffix)
      screenshot_path = screenshot_paths[sequence_number - 1]
      screenshot_name = screenshot_names[sequence_number - 1].sub('.png', '')

      case mask_type
      when :global
        mask_base_path = "#{support_path}/masks"
        mask_base_name = device[:screen]
      when :screen
        mask_base_path = "#{support_path}/screens/masks/#{device[:screen]}"
        mask_base_name = screen_name
      when :specific
        mask_base_path = "#{feature_path}/masks/#{device[:screen]}"
        mask_base_name = screenshot_name
      end

      if expected_mask_suffix
        mask_name = "#{mask_base_name}_#{expected_mask_suffix}.png"
      else
        mask_name = "#{mask_base_name}.png"
      end

      test_log = double(
        :screenshot_metadata => { :screen => screen_name, :orientation => orientation},
        :mark_screenshot_as_rotated => nil,
        :save => nil
      )

      screenshot = Zucchini::Screenshot.new(screenshot_path, device, test_log)
      screenshot.mask_paths[mask_type].should == File.join(mask_base_path, mask_name)
    end

    def self.context_for_mask_type(mask_type)
      context "#{mask_type} mask" do
        let(:mask_type) { mask_type }

        context "portrait" do
          let(:orientation) {"Portrait"}

          it "should be correct with portrait mask available" do
            test_mask_path device1, "splash", 4, "portrait"
          end

          it "should be correct with generic mask available" do
            test_mask_path device2, "splash2", 1, nil
          end
        end

        context "portrait-upside-down" do
          let(:orientation) {"PortraitUpsideDown"}

          it "should be correct with portrait mask available" do
            test_mask_path device1, "splash", 4, "portrait"
          end

          it "should be correct with generic mask available" do
            test_mask_path device2, "splash2", 1, nil
          end
        end

        context "landscape-left" do
          let(:orientation) {"LandscapeLeft"}

          it "should be correct with landscape mask available" do
            test_mask_path device1, "splash", 2, "landscape"
          end

          it "should be correct with generic mask available" do
            test_mask_path device2, "splash2", 1, nil
          end
        end

        context "landscape-right" do
          let(:orientation) {"LandscapeRight"}

          it "should be correct with landscape mask available" do
            test_mask_path device1, "splash", 2, "landscape"
          end

          it "should be correct with generic mask available" do
            test_mask_path device2, "splash2", 1, nil
          end
        end
      end
    end

    [:global, :screen, :specific].each {|mask_type| context_for_mask_type mask_type }
  end

  describe "rotate" do
    def compare_rotated_screenshot(sequence_number)
      index = sequence_number - 1
      path = screenshot_paths[index]
      @screenshot = Zucchini::Screenshot.new(path, device1, log)
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
      Zucchini::Screenshot.new(screenshot_paths[sequence_number - 1], device1, log)
      @screenshot.compare
      FileUtils.rm_rf(@screenshot.diff_path)
      @screenshot.diff.should eq [:passed, nil]
    end

    it "should mark screenshots as rotated" do
      sequence_number = 2
      Zucchini::Screenshot.new(screenshot_paths[sequence_number - 1], device1, log)
      log.screenshot_metadata(sequence_number)[:rotated].should be_true
    end
  end
end
