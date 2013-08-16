require 'time'
require 'erb'
require 'fileutils'
require 'pathname'

module Zucchini::Reporter
  class HTML
    def self.generate(features, report_path, ci)
      Zucchini::Reporter::HTML.new(features, ci).write(report_path)
      "HTML report generated to #{report_path}"
    end

    def initialize(features, ci)
      @features = features
      @device   = features[0].device
      @time     = Time.now.strftime("%T, %e %B %Y")
      @ci       = ci ? 'ci' : ''
    end

    def write(report_path)
      template_path  = "#{File.dirname(__FILE__)}/html/template.erb.html"
      gem_assets_dir = "#{File.dirname(__FILE__)}/html"

      files_path = report_path.chomp(File.extname report_path) + '_files'

      @assets_path = copy_assets(gem_assets_dir, "#{files_path}/assets", report_path)
      @features    = copy_images(@features,      "#{files_path}/images", report_path)

      File.open(report_path, 'w+') do |f|
        f.write ERB.new(File.read(template_path)).result(binding)
      end
    end

    private

    def recreate_dir(path)
      FileUtils.rm_rf   path
      FileUtils.mkdir_p path
    end

    def relative_path(dest_path, base_path)
      Pathname.new(dest_path).relative_path_from(Pathname.new(base_path).dirname)
    end

    def copy_assets(src_dir, dest_dir, report_path)
      recreate_dir(dest_dir)
      %W(js css).each { |t| FileUtils.cp_r("#{src_dir}/#{t}", dest_dir) }

      relative_path(dest_dir, report_path)
    end

    def copy_images(features, dest_dir, report_path)
      recreate_dir(dest_dir)

      features.each do |f|
        f.screenshots.each do |s|
          %W(actual expected difference).each do |type|
            src_path = s.result_images[type.to_sym]
            if src_path
              name      = File.basename(src_path)
              type_dir  = "#{dest_dir}/#{f.name}/#{type}"
              dest_path = "#{type_dir}/#{name}"

              FileUtils.mkdir_p(type_dir)
              FileUtils.cp(src_path, dest_path)

              s.result_images[type.to_sym] = relative_path(dest_path, report_path)
            end
          end
        end
      end
    end

  end
end
