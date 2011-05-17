require 'spec_helper'
load 'xero-min/urls.rb'

describe XeroMin::Urls do
  include XeroMin::Urls
  {contact: 'Contact', contacts: 'Contacts'}.each do |k,v|
    specify {url_for(k).should == "https://api.xero.com/api.xro/2.0/#{v}"}
  end
  it "can take a hash and and id" do
    url_for(invoice: 'INV-001').should == "https://api.xero.com/api.xro/2.0/Invoices/INV-001"
  end
end