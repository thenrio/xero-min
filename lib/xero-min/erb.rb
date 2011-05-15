require 'erb'

module XeroMin
  class Erb
    # Public : dir where templates are looked for
    attr_accessor :template_dir
    # Public : post processing for raw erb
    # default compacts xml, removing \n and spaces
    attr_accessor :post_processing_proc

    def initialize(template_dir=nil)
      self.template_dir = template_dir || File.expand_path('../templates', __FILE__)
      self.post_processing_proc = lambda {|xml| xml.gsub(%r((\s*)<), '<')}
    end

    # Public : renders a single entity with an infered template
    # eg : render(contact: {first_name: 'me'}) will render #{template_dir}/contact.xml.erb with {first_name: 'me'} as lvar
    def render(locals={})
      erb = ERB.new(read_template(infered_template(locals.keys.first)))
      inject_locals(locals)
      post_processing_proc.call(self.instance_eval {erb.result binding})
    end

    def infered_template(sym)
      "#{sym}.xml.erb"
    end

    private
    def inject_locals(hash)
      hash.each_pair do |key, value|
        symbol = key.to_s
        class << self;self;end.module_eval("attr_accessor :#{symbol}")
        self.send "#{symbol}=", value
      end
      self
    end

    def read_template(template)
      File.read(File.join(template_dir, template))
    end
  end
end