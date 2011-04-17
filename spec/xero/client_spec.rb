#encoding: utf-8
require 'spec_helper'
require 'xero/client'

class HttpDuck
  attr_accessor :code, :body

  def initialize(code=200, body='')
    self.code = code
    self.body = body
  end
end

describe Xero::Client do
  describe '#access_token' do
    let(:key) {'key'}
    let(:secret) {'secret'}
    let(:consumer) {Object.new}
    let(:token) {Object.new}

    it 'should lazily initialize token with appropriate parameters' do
      OAuth::Consumer.stubs(:new).with(key, secret, anything).returns(consumer)
      OAuth::AccessToken.stubs(:new).with(consumer, key, secret).returns(token)

      Xero::Client.new(key, secret).access_token.should == token
    end

    it 'should reuse existing token' do
      client = Xero::Client.new.tap{|client| client.access_token = token}
      client.access_token.should be token
    end
  end

  context "with a valid access token" do
    let(:token) {Object.new}
    let(:client) {Xero::Client.new.tap{|client| client.access_token = token}}

    describe '#post_invoice' do
      let(:invoice) {'invoice'}
      let(:client) {Xero::Client.new}
      it 'should tell self to request invoice url, with payload and using PUT' do
        client.stubs(:request).with(:put, 'https://api.xero.com/api.xro/2.0/Invoice', invoice).returns(HttpDuck.new(200))
        client.post_invoice(invoice)
      end
    end
    # describe '#post_company' do
    #   it 'should post' do
    #     mock(@access_token).request(:put, 'https://api.xero.com/api.xro/2.0/Contact', 'contact') {
    #       HttpDuck.new(200)
    #     }
    #     company = @connector.post_contact(@company)
    #     company.invoicing_system_id.should == '123'
    #   end
    # end

    describe 'parse' do
      it 'should extract error message when mail is not valid' do
        xml = <<XML
<ApiException>
  <ErrorNumber>10</ErrorNumber>
  <Type>ValidationException</Type>
  <Message>A validation exception occurred</Message>
  <Elements>
    <DataContractBase xsi:type="Invoice">
      <ValidationErrors>
        <ValidationError>
          <Message>Email address must be valid.</Message>
        </ValidationError>
      </ValidationErrors>
      <Reference />
      <Type>ACCREC</Type>
      <Contact>
        <ValidationErrors>
          <ValidationError>
            <Message>Email address must be valid.</Message>
          </ValidationError>
        </ValidationErrors>
    </DataContractBase>
  </Elements>
</ApiException>
XML
        response = HttpDuck.new(400, xml)
        message = 'A validation exception occurred, Email address must be valid.'
        lambda { client.parse(response) }.should raise_error Xero::Problem, message
      end

      it 'should extract error code and message' do
        xml = <<XML
<ApiException>
  <ErrorNumber>14</ErrorNumber>
  <Type>PostDataInvalidException</Type>
  <Message>The string '20100510' is not a valid AllXsd value.</Message>
</ApiException>
XML
        response = HttpDuck.new(400, xml)
        message = 'The string \'20100510\' is not a valid AllXsd value.'
        lambda { client.parse(response) }.should raise_error Xero::Problem, message
      end
    end
  end
end