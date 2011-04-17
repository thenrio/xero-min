require 'spec_helper'
require 'xero/erb'

describe Xero::Erb do
  describe "#template_dir" do
    it "is default ./templates from source file" do
      Xero::Erb.new.template_dir.should =~ %r(xero/templates$)
    end
  end
end