#encoding: utf-8
require 'spec_helper'
require 'xero-min/client'

class MockResponse < Struct.new(:body, :response)
  def success?; response.nil?; end
end
class MockRequest < Struct.new(:response); end

def google
  'http://google.com'
end

def parse_authorization(header)
  header['Authorization'].split(',').map{|s| s.strip.gsub("\"", '').split('=')}.reduce({}) {|acc, (k,v)| acc[k]=v; acc}
end

describe "#request" do
  let(:client) {XeroMin::Client.new}
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
    r = client.tap{|c| c.body_proc = nil}.request google, body: xml
    r.body.should == xml
  end
  it "can use xml option to set body with urlencoded xml" do
    r = client.request google, body: xml
    r.body.should == '%3CName%3EV%C3%A9lo%3C%2FName%3E'
  end
end

describe "#request!" do
  let(:client) {XeroMin::Client.new}
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
    it "uses #{method} method" do
      r = client.send(method, google)
      r.method.should == method
    end
  end
end

[:get, :put, :post].each do |method|
  describe "#{method}!" do
    let(:client) {XeroMin::Client.new}
    it "executes a #{method} request!" do
      client.stubs("request!").with(google, {method: method}).returns(404)
      client.send("#{method}!", google).should == 404
    end
  end
end

describe "#body_proc" do
  let(:client) {XeroMin::Client.new}
  it "has default value has a url_encode function" do
    client.body_proc.should_not be_nil
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

describe ".diagnose" do
  it "reports oauth problem" do
    cypher = "oauth_problem=signature_method_rejected&oauth_problem_advice=No%20certificates%20have%20been%20registered%20for%20the%20consumer"
    diagnosis = XeroMin::Client.diagnose(cypher)
    assert {diagnosis == "oauth_problem=signature_method_rejected\noauth_problem_advice=No certificates have been registered for the consumer"}
  end
end


describe "signature options" do
  let(:cli) {XeroMin::Client.new}
  describe "default to public app behavior" do
    it "signature is HMAC-SHA1" do
      authorization = parse_authorization(cli.request(google).headers)
      assert {authorization['oauth_signature_method'] == 'HMAC-SHA1'}
    end
  end
  describe "#private! authorization" do
    let(:headers) {cli.private!.request(google).headers}
    let(:authorization) {parse_authorization(headers)}
    it "fluently changes signature to RSA-SHA1" do
      assert {authorization['oauth_signature_method'] == 'RSA-SHA1'}
    end
    it "gains a private_key_file option" do
      pending
    end
  end
  it "#private! resets headers if called after obtaining an access token" do
    cli.request(google)
    authorization = parse_authorization(cli.private!.request(google).headers)
    assert {authorization['oauth_signature_method'] == 'RSA-SHA1'}
  end
end
