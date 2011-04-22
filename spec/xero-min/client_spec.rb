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

describe XeroMin::Client do
  let(:client) {XeroMin::Client.new}

  describe "#request" do
    it "yields request to block" do
      headers = nil
      request = client.request('https://api.xero.com/api.xro/2.0/Contacts') {|r| headers = r.headers}
      headers.should == request.headers
    end
  end

  describe "#queue" do
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


#     describe 'parse' do
#       it 'should extract error message when mail is not valid' do
#         xml = <<XML
# <ApiException>
#   <ErrorNumber>10</ErrorNumber>
#   <Type>ValidationException</Type>
#   <Message>A validation exception occurred</Message>
#   <Elements>
#     <DataContractBase xsi:type="Invoice">
#       <ValidationErrors>
#         <ValidationError>
#           <Message>Email address must be valid.</Message>
#         </ValidationError>
#       </ValidationErrors>
#       <Reference />
#       <Type>ACCREC</Type>
#       <Contact>
#         <ValidationErrors>
#           <ValidationError>
#             <Message>Email address must be valid.</Message>
#           </ValidationError>
#         </ValidationErrors>
#     </DataContractBase>
#   </Elements>
# </ApiException>
# XML
#         response = HttpDuck.new(400, xml)
#         message = 'A validation exception occurred, Email address must be valid.'
#         lambda { client.parse(response) }.should raise_error Xero::Problem, message
#       end
#
#       it 'should extract error code and message' do
#         xml = <<XML
# <ApiException>
#   <ErrorNumber>14</ErrorNumber>
#   <Type>PostDataInvalidException</Type>
#   <Message>The string '20100510' is not a valid AllXsd value.</Message>
# </ApiException>
# XML
#         response = HttpDuck.new(400, xml)
#         message = 'The string \'20100510\' is not a valid AllXsd value.'
#         lambda { client.parse(response) }.should raise_error Xero::Problem, message
#       end
#     end
end