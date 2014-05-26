require 'spec_helper'

describe Zucchini::Feature do
  let(:path)    { './spec/sample_setup/feature_one' }
  let(:feature) { Zucchini::Feature.new(path) }

  after(:all) { FileUtils.rm_rf Dir.glob("#{path}/run_data/feature.*") }

  describe "approve" do
    subject { lambda { feature.approve "reference" } }

    context "no previous run data" do
      before { feature.path = './spec/sample_setup/feature_three' }
      it { should raise_error "Directory ./spec/sample_setup/feature_three doesn't contain previous run data" }
    end

    context "copies screenshots to reference directory" do
      before do
        feature.path = './spec/sample_setup/feature_three'
        feature.device = {screen: 'retina_ios5'}

        # Copying some random image to run screenshots.
        @screenshot_path = "#{feature.path}/run_data/Run\ 1/01_screenshot.png"
        FileUtils.mkdir_p(File.dirname(@screenshot_path))
        FileUtils.copy_file("./spec/sample_setup/feature_one/reference/retina_ios5/01_sign up_spinner.png", @screenshot_path)
      end

      it "should copy screenshot to reference directory" do
        feature.approve "reference"
        (File.exists? "#{feature.path}/reference/retina_ios5/01_screenshot.png").should eq true
      end

      it "should copy screenshot to pending directory" do
        feature.approve "pending"
        (File.exists? "#{feature.path}/pending/retina_ios5/01_screenshot.png").should eq true
      end

      after do
        FileUtils.rm_rf("#{feature.path}/run_data")
        FileUtils.rm_rf("#{feature.path}/reference")
        FileUtils.rm_rf("#{feature.path}/pending")
      end
    end

    context "copy screenshots to mask directory" do
      before do
        feature.path = './spec/sample_setup/feature_three'
        feature.device = {screen: 'retina_ios5'}
      end
      
      it "should not create mask image to mask directory if there is no diff" do
        screenshot_path = "#{feature.path}/run_data/Run\ 1/01_screenshot.png"
        FileUtils.mkdir_p(File.dirname(screenshot_path))
        FileUtils.copy_file("./spec/sample_setup/feature_one/reference/retina_ios5/01_sign up_spinner.png", screenshot_path)
        
        reference_path = "#{feature.path}/reference/retina_ios5/01_screenshot.png"
        FileUtils.mkdir_p(File.dirname(reference_path))
        FileUtils.copy_file("./spec/sample_setup/feature_one/reference/retina_ios5/01_sign up_spinner.png", reference_path)

        feature.approve_tomask
        (File.exists? "#{feature.path}/masks/retina_ios5/01_screenshot.png").should eq false
      end

      it "should create mask image to mask directory if there is some diff and there is no original mask image" do
        screenshot_path = "#{feature.path}/run_data/Run\ 1/01_screenshot.png"
        FileUtils.mkdir_p(File.dirname(screenshot_path))
        FileUtils.copy_file("./spec/sample_setup/feature_one/reference/retina_ios5/01_sign up_spinner.png", screenshot_path)
        
        reference_path = "#{feature.path}/reference/retina_ios5/01_screenshot.png"
        FileUtils.mkdir_p(File.dirname(reference_path))
        FileUtils.copy_file("./spec/sample_setup/feature_one/reference/retina_ios5/01_sign up_spinner_error.png", reference_path)

        feature.approve_tomask
        (File.exists? "#{feature.path}/masks/retina_ios5/01_screenshot.png").should eq true
      end

      it "should merge original mask image and new mask image when there is a original mask image" do
        origin_initial_mask_ref_path = "./spec/sample_setup/feature_one/masks/retina_ios5/01_sign up_spinner.png"
        initial_mask_path = "#{feature.path}/masks/retina_ios5/01_screenshot.png"
        FileUtils.mkdir_p(File.dirname(initial_mask_path))
        FileUtils.copy_file(origin_initial_mask_ref_path, initial_mask_path)

        screenshot_path = "#{feature.path}/run_data/Run\ 1/01_screenshot.png"
        FileUtils.mkdir_p(File.dirname(screenshot_path))
        FileUtils.copy_file("./spec/sample_setup/feature_one/reference/retina_ios5/01_sign up_spinner.png", screenshot_path)
        
        reference_path = "#{feature.path}/reference/retina_ios5/01_screenshot.png"
        FileUtils.mkdir_p(File.dirname(reference_path))
        FileUtils.copy_file("./spec/sample_setup/feature_one/reference/retina_ios5/01_sign up_spinner_error.png", reference_path)

        feature.approve_tomask
        (File.exists? "#{feature.path}/masks/retina_ios5/01_screenshot.png").should eq true

        diff = compare_image(initial_mask_path, origin_initial_mask_ref_path, "#{feature.path}/01_screenshot.png");
        (diff[0]).should eq :failed
      end

      after do
        FileUtils.rm_rf("#{feature.path}/run_data")
        FileUtils.rm_rf("#{feature.path}/reference")
        FileUtils.rm_rf("#{feature.path}/masks")
      end
    end
  end
end
