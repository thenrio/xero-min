#encoding: utf-8
require 'spec_helper'
require 'xero-min/client'

class HttpDuck
  attr_accessor :code, :body, :response
  def initialize(code=200, body='')
    self.code = code
    self.body = body
  end
end

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
  it "yields request to block" do
    headers = nil
    request = client.request('https://api.xero.com/api.xro/2.0/Contacts') {|r| headers = r.headers}
    headers.should == request.headers
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
