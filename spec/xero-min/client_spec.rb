#encoding: utf-8
require 'spec_helper'
require 'xero-min/client'

class MockResponse < Struct.new(:body, :response)
  def success?; response.nil?; end
end
class MockRequest < Struct.new(:response); end

describe '#token' do
  let(:key) {'key'}
  let(:secret) {'secret'}
  let(:consumer) {Object.new}
  let(:token) {Object.new}

  it 'should lazily initialize token with appropriate parameters' do
    OAuth::Consumer.stubs(:new).with(key, secret, anything).returns(consumer)
    OAuth::AccessToken.stubs(:new).with(consumer, key, secret).returns(token)

    XeroMin::Client.new(key, secret).token.should == token
  end

  it 'should reuse existing token' do
    client = XeroMin::Client.new.tap{|client| client.token = token}
    client.token.should be token
  end
end

describe "#request" do
  let(:client) {XeroMin::Client.new}
  let(:google) {'http://google.com'}
  it "yields request to block" do
    headers = nil
    request = client.request('https://api.xero.com/api.xro/2.0/Contacts') {|r| headers = r.headers}
    headers.should == request.headers
  end
  context "with a string as url" do
    it "use it" do
      client.request(google).url.should == google
    end
  end
  context "with a symbol as url" do
    it "pipes url to XeroMin::Urls" do
      client.stubs(:url_for).with(:google).returns(google)
      client.request(:google).url.should == google
    end
  end
end

describe "#get" do
  let(:client) {XeroMin::Client.new}
  include XeroMin::Urls

  context "with a symbol" do
    it "creates and run a get request with url infered when given symbol" do
      options = {}
      client.stubs(:request).with(:contact, options).returns(MockRequest.new(MockResponse.new))
      client.expects(:run)

      client.get(:contact, options)
    end
  end
end

describe "#put" do
  let(:client) {XeroMin::Client.new}
  let(:google) {'http://google.com'}
  it "set put method in headers" do
    r = client.put(google)
    r.method.should == :put
  end
end


describe "#queue" do
  let(:client) {XeroMin::Client.new}
  let(:request) {Object.new}
  before do
    client.send(:hydra).expects(:queue).with(request)
  end
  it "queues request" do
    client.queue(request)
  end
  it "returns self" do
    client.queue(request).should be client
  end
end
