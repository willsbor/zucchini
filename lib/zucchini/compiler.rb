module Zucchini
  module Compiler
    extend self

    def feature_coffee(file, cs_path)
      File.open(cs_path, "w+") do |f|
        feature_text = File.read(file).gsub(/\#.+[\z\n]?/,"").gsub(/\n/, "\\n")
        f.write "Zucchini.run('#{feature_text}')"
      end
      cs_path
    end

    def js(f)
      lib_path = File.expand_path(File.dirname(__FILE__))
      js_path  = "#{f.run_data_path}/feature.js"

      coffee_src_paths = [
        "#{lib_path}/uia",
        "#{f.path}/../support/screens",
        "#{f.path}/../support/lib",
        feature_coffee("#{f.path}/feature.zucchini", "#{f.run_data_path}/feature.coffee")
      ].select { |p| File.exists? p }.join ' '

      "coffee -o #{f.run_data_path} -j #{js_path} -c #{coffee_src_paths}".tap do |cmd|
        raise "Error compiling a feature file: #{cmd}" unless system(cmd)
      end

      concat(js_path, "#{lib_path}/uia/lib")
      js_path
    end

    def concat(js_path, lib_path)
      tmp_file = "/tmp/feature.js"

      js_src = Dir.glob("#{lib_path}/*.js").inject([]) do |libs, f|
        libs << File.read(f)
      end.join(";\n")

      File.open(tmp_file, 'w') do |f|
        f.puts(js_src)
        f.puts(File.read(js_path))
      end

      File.rename(tmp_file, js_path)
    end
  end
end
