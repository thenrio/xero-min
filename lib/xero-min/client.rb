require 'oauth'
require 'oauth/signature/rsa/sha1'
require 'oauth/request_proxy/typhoeus_request'
require 'typhoeus'
require 'nokogiri'

require 'xero-min/urls'

module XeroMin
  class Client
    include XeroMin::Urls
    # all requests return hash or array, as would parsed json
    #
    # xero api does not support to return json content in POST | PUT !!!
    #
    # hence, activesupport to parse xml as a hash ...
    # terrible
    #
    @@signature = {
      signature_method: 'RSA-SHA1',
      private_key_file: '/Users/thenrio/src/ruby/agile-france-program-selection/keys/xero.rsa'
    }
    @@options = {
      site: 'https://api.xero.com/api.xro/2.0',
      request_token_path: "/oauth/RequestToken",
      access_token_path: "/oauth/AccessToken",
      authorize_path: "/oauth/Authorize",
    }.merge(@@signature)

    attr_writer :token
    attr_accessor :verbose

    def initialize(consumer_key=nil, secret_key=nil, options={})
      self.verbose = true
      @options = @@options.merge(options)
      @consumer_key, @secret_key  = consumer_key || 'YZJMNTAXYTBJMTYZNGFMMZK0ODGZMW', secret_key || 'WLIHEJM3AJSNFL12M5LXZVB9S9XYX9'
    end

    def token
      @token ||= OAuth::AccessToken.new(OAuth::Consumer.new(@consumer_key, @secret_key, @options),
        @consumer_key, @secret_key)
    end

    # Public : post given xml to invoices url
    # default method is put
    # yields request to block if present
    # returns parsed jsoned
    def post_invoice(xml, options={}, &block)
      r = request('https://api.xero.com/api.xro/2.0/Invoice', {method: :put}.merge(options), &block)
      run(r)
      parse! r.response
    end

    # Public : post given xml to contacts url
    # default method is put
    # yields request to block if present
    def post_contact(xml, options={}, &block)
      r = request('https://api.xero.com/api.xro/2.0/Contact', {method: :put}.merge(options), &block)
      run(r)
      parse! r.response
    end

    # get contacts
    def get_contacts(options={}, &block)
      r = request('https://api.xero.com/api.xro/2.0/Contacts', options, &block)
      run(r)
      parse! r.response
    end

    def get(sym_or_url, options={}, &block)
      request(sym_or_url, options, &block)
    end

    def get!(sym_or_url, options={}, &block)
      r = get(sym_or_url, options, &block)
      run(r)
      parse! r.response
    end

    def put(sym_or_url, options={}, &block)
      request(sym_or_url, {method: :put}.merge(options), &block)
    end

    def post(sym_or_url, options={}, &block)
      request(sym_or_url, {method: :post}.merge(options), &block)
    end

    def request(sym_or_url, options={}, &block)
      url = (sym_or_url.is_a?(Symbol) ? url_for(sym_or_url) : sym_or_url)
      req = Typhoeus::Request.new(url, options)
      helper = OAuth::Client::Helper.new(req, @@signature.merge(consumer: token.consumer, token: token, request_uri: url))
      req.headers.merge!({'Authorization' => helper.header})
      yield req if block_given?
      req
    end

    # return nokogiri node
    def parse(response)
      Nokogiri::XML(response.body)
    end

    # parse response or die unless code is success
    def parse!(response)
      node = parse(response)
      response.success?? node : raise(Problem, node.xpath('//Message').to_a.map{|e| e.content}.uniq.join(', '))
    end

    def queue(request)
      hydra.queue(request)
      self
    end

    def run(request=nil)
      (request ? queue(request) : self).hydra.run
    end

    protected
    def hydra
      @hydra ||= Typhoeus::Hydra.new
    end
  end
  class Problem < StandardError
  end
end