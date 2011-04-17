require 'oauth'
require 'oauth/signature/rsa/sha1'
require 'nokogiri'

module Xero
  class Client
    @@options = {
      site: 'https://api.xero.com/api.xro/2.0',
      request_token_path: "/oauth/RequestToken",
      access_token_path: "/oauth/AccessToken",
      authorize_path: "/oauth/Authorize",
      signature_method: 'RSA-SHA1',
      private_key_file: '/Users/thenrio/src/ruby/agile-france-program-selection/keys/xero.rsa'
    }

    attr_writer :access_token

    def initialize(consumer_key=nil, secret_key=nil, options={})
      @options = @@options.merge(options)
      @consumer_key, @secret_key  = consumer_key || 'YZJMNTAXYTBJMTYZNGFMMZK0ODGZMW', secret_key || 'WLIHEJM3AJSNFL12M5LXZVB9S9XYX9'
    end

    def access_token
      @access_token ||= OAuth::AccessToken.new(OAuth::Consumer.new(@consumer_key, @secret_key, @options),
        @consumer_key, @secret_key)
    end

    def request(verb, uri, xml=nil)
      access_token.request(verb, uri, xml)
    end

    # Public :
    # post_invoice(xml) {|response| ...}
    def post_invoice(xml, &block)
      response = request(:put, 'https://api.xero.com/api.xro/2.0/Invoice', xml)
      parse(response, &block)
    end
    # Public :
    # post_contact(xml) {|response| ...}
    def post_contact(xml, &block)
      parse(request(:put, 'https://api.xero.com/api.xro/2.0/Contact', xml), &block)
    end

    # at this time, does not know how to get on name, email criteria
    # and post fails when duplicate name
    def get_contacts
      uri = 'https://api.xero.com/api.xro/2.0/Contacts'
      response = request(get, uri)
    end

    # parse response and return or yield response
    def parse(response, &block)
      case response.code.to_i
        when 200 then
          return yield(response) unless block.nil?
        else
          fail!(response)
      end
      response
    end

    def fail!(response)
      doc = Nokogiri::XML(response.body)
      messages = doc.xpath('//Message').to_a.map { |element| element.content }.uniq
      raise Problem, messages.join(', ')
    end
  end

  class Problem < StandardError
  end
end