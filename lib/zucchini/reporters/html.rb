require 'time'
require 'erb'
require 'fileutils'

module Zucchini::Reporter
  class HTML
    def self.generate(features, output_path, ci)
      template_path = File.expand_path("#{File.dirname(__FILE__)}/html/template.erb.html")
      Zucchini::Reporter::HTML.new(features, ci, template_path, output_path).write!

      "HTML report generated to #{output_path}"
    end

    def initialize(features, ci, template_path, output_path)
      files_path = output_path.chomp(File.extname(output_path))

      @features      = features
      @device        = features[0].device
      @time          = Time.now.strftime("%T, %e %B %Y")
      @assets_path   = "#{files_path}/assets"
      @images_path   = "#{files_path}/images"
      @output_path   = output_path
      @template_path = template_path
      @ci            = ci ? 'ci' : ''
    end

    def write!
      copy_assets(File.expand_path("#{File.dirname(__FILE__)}/html"), @assets_path)
      copy_result_images(@features, @images_path)

      File.open(@output_path, 'w+') do |f|
        f.write ERB.new(File.read(@template_path)).result(binding)
      end
    end

    private

    def recreate_dir(path)
      FileUtils.rm_rf   path
      FileUtils.mkdir_p path
    end

    def copy_assets(src_dir, dest_dir)
      recreate_dir(dest_dir)
      %W(js css).each do |type|
        FileUtils.cp_r("#{src_dir}/#{type}", dest_dir)
      end
    end

    def copy_result_images(features, dest_dir)
      recreate_dir(dest_dir)

      features.each do |f|
        f.screenshots.each do |s|
          %W(actual expected difference).each do |type|
            src_path  = s.result_images[type.to_sym]
            name      = File.basename(src_path)
            type_dir  = "#{dest_dir}/#{type}"
            dest_path = "#{type_dir}/#{name}"

            FileUtils.mkdir_p(type_dir)
            FileUtils.cp(src_path, dest_path)

            s.result_images[type.to_sym] = dest_path
          end
        end
      end
    end
  end
end
