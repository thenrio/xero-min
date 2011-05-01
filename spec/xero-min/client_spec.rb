#encoding: utf-8
require 'spec_helper'
require 'xero-min/client'

class MockResponse < Struct.new(:body, :response)
  def success?; response.nil?; end
end
class MockRequest < Struct.new(:response); end

describe "#request" do
  let(:client) {XeroMin::Client.new}
  let(:google) {'http://google.com'}
  let(:xml) {'<Name>Vélo</Name>'}
  it "yields request to block" do
    headers = nil
    request = client.request('https://api.xero.com/api.xro/2.0/Contacts') {|r| headers = r.headers}
    headers.should == request.headers
  end
  it "can use plain url" do
    client.request(google).url.should == google
  end
  it "can use a symbol for an url, using transformation XeroMin::Urls" do
    client.stubs(:url_for).with(:google).returns(google)
    client.request(:google).url.should == google
  end
  it "can initialize body" do
    r = client.request google, body: xml
    r.body.should == xml
  end
  it "can use xml option to set body with urlencoded xml" do
    r = client.request google, xml: xml
    r.body.should == '%3CName%3EV%C3%A9lo%3C%2FName%3E'
  end
end

describe "#request!" do
  let(:client) {XeroMin::Client.new}
  let(:google) {'http://google.com'}
  it "runs request and parse it" do
    request = MockRequest.new(MockResponse.new)
    client.stubs(:request).with(google, {}).returns(request)
    client.expects(:run).with(request)
    client.expects(:parse!).with(request.response)
    client.request!(google)
  end
end

[:get, :put, :post].each do |method|
  describe "#{method}" do
    let(:client) {XeroMin::Client.new}
    let(:google) {'http://google.com'}
    it "uses #{method} method" do
      r = client.send(method, google)
      r.method.should == method
    end
  end
end

[:get, :put, :post].each do |method|
  describe "#{method}!" do
    let(:client) {XeroMin::Client.new}
    let(:google) {'http://google.com'}
    it "executes a #{method} request!" do
      client.stubs("request!").with(google, {method: method}).returns(404)
      client.send("#{method}!", google).should == 404
    end
  end
end

describe 'private #token' do
  let(:key) {'key'}
  let(:secret) {'secret'}
  let(:consumer) {Object.new}
  let(:token) {Object.new}

  it 'lazily initialize token with appropriate parameters' do
    OAuth::Consumer.stubs(:new).with(key, secret, anything).returns(consumer)
    OAuth::AccessToken.stubs(:new).with(consumer, key, secret).returns(token)

    XeroMin::Client.new(key, secret).send(:token).should == token
  end

  it 'reuse existing token' do
    cli = XeroMin::Client.new
    cli.send(:token).should be cli.send(:token)
  end
end
