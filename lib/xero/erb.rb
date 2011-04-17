require 'erb'

module Xero
  class Erb
    attr_accessor :template_dir

    def initialize(template_dir=nil)
      self.template_dir = template_dir || File.expand_path('../templates', __FILE__)
    end

    def do_render(template, locals={})
      erb = ERB.new(read_template(template))
      inject_locals(locals)
      erb.result get_binding
    end

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
  end
end