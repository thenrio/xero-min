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

    def initialize(consumer_key=nil, secret_key=nil, options={})
      @options = @@options.merge(options)
      @consumer_key, @secret_key  = consumer_key || 'YZJMNTAXYTBJMTYZNGFMMZK0ODGZMW', secret_key || 'WLIHEJM3AJSNFL12M5LXZVB9S9XYX9'
    end

    # Public : creates a signed request
    # url of request is XeroMin::Urls.url_for sym_or_url, when sym_or_url is a symbol
    # available options are the one of a Typhoeus::Request
    # request is yieled to block when present
    def request(sym_or_url, options={}, &block)
      url = (sym_or_url.is_a?(Symbol) ? url_for(sym_or_url) : sym_or_url)
      req = Typhoeus::Request.new(url, options)
      helper = OAuth::Client::Helper.new(req, @@signature.merge(consumer: token.consumer, token: token, request_uri: url))
      req.headers.merge!({'Authorization' => helper.header})
      yield req if block_given?
      req
    end

    # Public : runs a request
    def run(request=nil)
      queue(request) if request
      hydra.run
    end

    # Public : creates and runs a request and parse! its body
    def request!(sym_or_url, options={}, &block)
      parse!(request(sym_or_url, options, &block).tap{|r| run(r)}.response)
    end

    # Public: returns response body parsed as a nokogiri node
    def parse(response)
      Nokogiri::XML(response.body)
    end

    # Public : parse response or die unless response is success
    def parse!(response)
      node = parse(response)
      response.success?? node : raise(Problem, node.xpath('//Message').to_a.map{|e| e.content}.uniq.join(', '))
    end

    # Public : get, put, and post are shortcut for a request using this verb (question mark available)
    [:get, :put, :post].each do |method|
      module_eval <<-EOS, __FILE__, __LINE__ + 1
        def #{method}(sym_or_url, options={}, &block)
          request(sym_or_url, {method: :#{method}}.merge(options), &block)
        end
        def #{method}!(sym_or_url, options={}, &block)
          request!(sym_or_url, {method: :#{method}}.merge(options), &block)
        end
      EOS
    end

    private
    def hydra
      @hydra ||= Typhoeus::Hydra.new
    end
    def queue(request)
      hydra.queue(request)
      self
    end
    def token
      @token ||= OAuth::AccessToken.new(OAuth::Consumer.new(@consumer_key, @secret_key, @options),
        @consumer_key, @secret_key)
    end
  end
  class Problem < StandardError
  end
end