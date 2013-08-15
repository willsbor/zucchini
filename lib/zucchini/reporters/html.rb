require 'erb'
require 'zucchini/reporters/html/view'

module Zucchini::Reporter
  module HTML
    extend self

    def generate(features, output_path, ci)
      template_path = File.expand_path("#{File.dirname(__FILE__)}/html/template.erb.html")

      view = Zucchini::ReportView.new(features, ci)
      compiled = (ERB.new(File.open(template_path).read)).result(view.get_binding)

      File.open(output_path, 'w+') { |f| f.write(compiled) }
      "HTML report generated to #{output_path}"
    end
  end
end
