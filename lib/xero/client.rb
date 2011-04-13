require 'oauth'
require 'oauth/signature/rsa/sha1'

module Xero
  class Client
    attr_writer :access_token
    attr_accessor :date, :settlement

    def initialize(consumer_key=nil, secret_key=nil, options={})
      @consumer_key = consumer_key
      @secret_key = secret_key
      @options = options
      self.date = Date.today
      self.settlement = 15
    end

    def access_token
      return @access_token if @access_token
      consumer = OAuth::Consumer.new(@consumer_key, @secret_key, @options)
      @access_token = OAuth::AccessToken.new(consumer, @consumer_key, @secret_key)
    end

    def send(uri, xml, verb=:put)
      access_token.request(verb, uri, xml)
    end

    # at this time oauth-4.0.0, and xero api-v2
    # post(uri, xml) get 401 whereas put(uri, xml) get 200
    # so use verb :put, even if it should be a :post
    def post_invoice(invoice)
      uri = 'https://api.xero.com/api.xro/2.0/Invoice'
      response = send(uri, create_invoice(invoice))

      parse_response(response) do |r|
        invoice.invoicing_system_id = extract_invoice_id(r)
      end
      invoice
    end

    # at this time oauth-4.0.0, and xero api-v2
    # post(uri, xml) get 401 whereas put(uri, xml) get 200
    # so use verb :put, even if it should be a :post
    def post_contact(company)
      uri = 'https://api.xero.com/api.xro/2.0/Contact'
      response = send(uri, create_contact(company))

      c = company.clone
      parse_response(response) do |r|
        c.invoicing_system_id = extract_contact_id(r)
      end
      c
    end

    # at this time, does not know how to get on name, email criteria
    # and post fails when duplicate name
    def get_contacts
      uri = 'https://api.xero.com/api.xro/2.0/Contacts'
      response = send(uri, '', :get)

      companies = []
      extract_contacts(parse_response(response)).each do |contact|
        companies << create_company_from_node(contact)
      end
      companies
    end

    # parse response and return xpath content for /Response/Invoices/Invoice/InvoiceNumber
    def parse_response(response)
      case Integer(response.code)
        when 200 then
          return yield(response) if block_given?
        else
          fail!(response)
      end
      response
    end

    def extract_invoice_id(response)
      doc = Nokogiri::XML(response.body)
      result = doc.xpath('/Response/Invoices/Invoice/InvoiceNumber').first
      result.content if result
    end

    def extract_contact_id(response)
      doc = Nokogiri::XML(response.body)
      doc.xpath('/Response/Contacts/Contact/ContactID').first.content
    end

    def extract_contacts(response)
      doc = Nokogiri::XML(response.body)
      doc.xpath('/Response/Contacts/Contact')
    end

    def fail!(response)
      doc = Nokogiri::XML(response.body)
      messages = doc.xpath('//Message').to_a.map { |element| element.content }.uniq
      raise Problem, messages.join(', ')
    end

    def create_invoice(invoice)
      @renderer.render('xero/invoice.xml.haml', :invoice => invoice)
    end

    def create_contact(company)
      @renderer.render('xero/contact.xml.haml', :company => company)
    end

    def extract_from_node(node, path)
      begin
        node.xpath(path).first.content
      rescue Exception => bang
        logger.warn("no such #{path} in #{node.to_xml}")
      end
    end
    private :extract_from_node

    def create_company_from_node(node)
      company = Company.new
      company.invoicing_system_id = extract_from_node(node, 'ContactID')
      company.name = extract_from_node(node, 'Name')
      company.email = extract_from_node(node, 'EmailAddress')
      company
    end

    class Problem < StandardError
    end
  end
end