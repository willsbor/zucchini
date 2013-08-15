require 'zucchini/reporters/html/view'

module Zucchini::Reporter
  module HTML
    extend self

    def generate(features, output_path, ci)
      template_path = File.expand_path("#{File.dirname(__FILE__)}/html/template.erb.html")
      Zucchini::ReportView.new(features, ci, template_path, output_path).write!

      "HTML report generated to #{output_path}"
    end
  end
end
