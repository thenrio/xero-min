#encoding: utf-8
require 'spec_helper'
require 'xero/client'

describe Xero::Client do
  before do
    @options = {}
    @consumer = 'consumer'
    @secret = 'secret'

    @connector = Xero::Client.new(@consumer, @secret, @options)
  end

  class HttpDuck
    attr_accessor :code, :body

    def initialize(code=200, body='')
      self.code = code
      self.body = body
    end
  end


  describe '#access_token' do
    # will have to go and see this code once again
    # there is smell in creating a new 'irritating' dependency on a method
    # though, value expected is COC
    #
    # use plain object 'token' rather than mock!
    # hence can not make it a fixture for any more functionality
    #
    # following fails with rr-0.10.11
    #
    #describe 'rr' do
    #  it 'shouldn't mock! equals self ?' do
    #    o = mock!
    #    o.should == o
    #  end
    #end
    #
    # is it important ?
    # no
    it 'should initialize token with appropriate parameters' do
      consumer, @token = 'hello', 'there'
      mock(OAuth::Consumer).new(@consumer, @secret, @options) { consumer }
      mock(OAuth::AccessToken).new(consumer, @consumer, @secret) { @token }
      @connector.access_token.should == @token
    end

    it 'should reuse existing token' do
      token = Object.new
      @connector.access_token = token
      @connector.access_token.should equal token
    end
  end

  describe 'with invoice,' do
    before do
      git = Company.create(:name => 'git', :firstname => 'john',
                           :lastname => 'doe', :email => 'john@doe.com',
                           :invoicing_system_id => 'sha1')
      junio = Attendee.create(:firstname => 'junio', :lastname => 'hamano', :company => git)
      date = Date.parse('10/05/2010')
      @invoiceable = Invoiceable.new(:attendee => junio)
      @invoice = Invoice.new(:company => git, :invoiceables => [@invoiceable], :date => date)
    end

    describe 'post_invoice' do
      before do
        @access_token = mock!
        @connector.access_token = @access_token

        stub(@connector).create_invoice(@invoice) { 'invoice' }
        stub(@connector).extract_invoice_id(anything) { '123' }
      end

      it 'should tell connector to post' do
        mock(@access_token).request(:put, 'https://api.xero.com/api.xro/2.0/Invoice', 'invoice') { HttpDuck.new(200) }
        invoice = @connector.post_invoice(@invoice)
        invoice.invoicing_system_id.should == '123'
      end
    end

    describe 'create_invoice' do
      it 'should build minimal xml' do
        xml = @connector.create_invoice(@invoice)
        doc = Nokogiri::XML(xml)
        doc.xpath('/Invoice/Type').first.content.should == 'ACCREC'
        doc.xpath('/Invoice/Contact/ContactID').first.content.should == 'sha1'
        doc.xpath('/Invoice/Date').first.content.should == '2010-05-10'
        doc.xpath('/Invoice/DueDate').first.content.should == '2010-05-20'
        foo = doc.xpath('/Invoice/LineItems/LineItem')[0]
        foo.xpath('Description').first.content.should == @invoiceable.description
        foo.xpath('Quantity').first.content.should == '1'
        foo.xpath('UnitAmount').first.content.should == '270'
        foo.xpath('AccountCode').first.content.should == '20010AGFI'
      end
    end
  end


  describe 'with a company,' do
    before do
      @company = Company.new(:name => 'no name', :firstname => 'john', :lastname => 'doe', :email => 'john@doe.com')
      @company.id = 123
    end

    describe 'create_company' do
      it 'should tell connector to post company as proper xml' do
        xml = @connector.create_contact(@company)
        doc = Nokogiri::XML(xml)
        doc.xpath('/Contact/Name').first.content.should == 'no name'
        doc.xpath('/Contact/FirstName').first.content.should == 'john'
        doc.xpath('/Contact/LastName').first.content.should == 'doe'
        doc.xpath('/Contact/EmailAddress').first.content.should == 'john@doe.com'
      end
    end

    # alas, post does not work as documented (create/update)
    # post receives 401 !!!
    # post does create, and does it
    # poor api
    describe 'post_company' do
      before do
        @access_token = mock!
        @connector.access_token = @access_token

        stub(@connector).create_contact(@company) { 'contact' }
        stub(@connector).extract_contact_id(anything) { '123' }
      end

      it 'should post' do
        mock(@access_token).request(:put, 'https://api.xero.com/api.xro/2.0/Contact', 'contact') {
          HttpDuck.new(200)
        }
        company = @connector.post_contact(@company)
        company.invoicing_system_id.should == '123'
      end
    end
  end

  describe 'extract_invoice_id' do
    it 'should extract InvoiceNumber from happy xml, under xpath' do
      xml = <<XML
<Response>
  <Invoices>
    <Invoice>
      <InvoiceNumber>INV-0011</InvoiceNumber>
    </Invoice>
  </Invoices>
</Response>
XML
      response = HttpDuck.new(200, xml)
      @connector.extract_invoice_id(response).should == 'INV-0011'
    end
  end

  describe 'parse_response' do
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
      lambda { @connector.parse_response(response) }.should raise_error Connector::Xero::Problem, message
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
      lambda { @connector.parse_response(response) }.should raise_error Connector::Xero::Problem, message
    end
  end


  describe 'get_contacts' do
    it 'should get Contacts and make them available as Companies' do
      xml = <<XML
<Response>
  <Id>67c64458-0fe1-4577-9e39-e2695416f5e3</Id>
  <Status>OK</Status>
  <ProviderName>spike-on-xero</ProviderName>
  <DateTimeUTC>2010-05-13T12:16:47.9988769Z</DateTimeUTC>
  <Contacts>
    <Contact>
      <ContactID>4ced6122-1f86-428d-8118-4030fc765ba6</ContactID>
      <ContactStatus>ACTIVE</ContactStatus>
      <Name>37signals</Name>
      <FirstName>D</FirstName>
      <LastName>HH</LastName>
      <EmailAddress>john@doe.com</EmailAddress>
    </Contact>
    <Contact>
      <ContactID>3bb604a6-f395-4869-a8db-8c99a89fd848</ContactID>
      <ContactStatus>ACTIVE</ContactStatus>
      <Name>38signals</Name>
      <FirstName>D</FirstName>
      <LastName>HHH</LastName>
      <EmailAddress>dhh@37signals.com</EmailAddress>
    </Contact>
  </Contacts>
</Response>
XML
      mock(@connector.access_token).request(:get, 'https://api.xero.com/api.xro/2.0/Contacts', '') {
        HttpDuck.new(200, xml)
      }
      signals37 = Company.new(:name => '37signals', :email => 'john@doe.com',
                              :invoicing_system_id => '4ced6122-1f86-428d-8118-4030fc765ba6')
      signals38 = Company.new(:name => '38signals', :email => 'dhh@37signals.com',
                              :invoicing_system_id => '3bb604a6-f395-4869-a8db-8c99a89fd848')
      @connector.get_contacts.should == [signals37, signals38]
    end
  end
end