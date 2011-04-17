require 'erb'

module Xero
  class Erb
    attr_accessor :template_dir

    def initialize(template_dir=nil)
      self.template_dir = template_dir || File.expand_path('../templates', __FILE__)
    end

    def render(locals={})
      erb = ERB.new(read_template(infered_template(locals.keys.first)))
      inject_locals(locals)
      erb.result get_binding
    end

    def infered_template(sym)
      "#{sym}.xml.erb"
    end

    private
    def inject_locals(hash)
      hash.each_pair do |key, value|
        symbol = key.to_s
        class << self;self;end.module_eval("attr_accessor :#{symbol}")
        self.send :instance_variable_set, "@#{symbol}", value
      end
      self
    end

    def get_binding
      binding
    end

    def read_template(template)
      File.read(File.join(template_dir, template))
    end
  end
end