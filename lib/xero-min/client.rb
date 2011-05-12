require 'oauth'
require 'oauth/signature/rsa/sha1'
require 'oauth/request_proxy/typhoeus_request'
require 'typhoeus'
require 'nokogiri'
require 'escape_utils'

require 'xero-min/urls'

module XeroMin
  class Client
    include XeroMin::Urls

    @@signature = {
      signature_method: 'HMAC-SHA1'
    }
    @@options = {
      site: 'https://api.xero.com/api.xro/2.0',
      request_token_path: "/oauth/RequestToken",
      access_token_path: "/oauth/AccessToken",
      authorize_path: "/oauth/Authorize",
      'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8'
    }.merge(@@signature)

    # Public : body is transformed using body_proc if present
    # proc has one param
    # defaults to `lambda{|body| EscapeUtils.escape_url(body)}`, that is url encode body
    attr_accessor :body_proc

    def initialize(consumer_key=nil, secret_key=nil, options={})
      @options = @@options.merge(options)
      @consumer_key, @secret_key  = consumer_key , secret_key
      self.body_proc = lambda{|body| EscapeUtils.escape_url(body)}
    end

    # Public returns whether it has already requested an access token
    def token?
      !!@token
    end

    # Public : enables client to act as a private application
    # resets previous access token if any
    def private!(private_key_file='keys/xero.rsa')
      @token = nil if token?
      @options.merge!({signature_method: 'RSA-SHA1', private_key_file: private_key_file})
      self
    end

    # Public : creates a signed request
    # url of request is XeroMin::Urls.url_for sym_or_url, when sym_or_url is a symbol
    # available options are the one of a Typhoeus::Request
    # request is yielded to block if present
    # first request ask for access token
    def request(sym_or_url, options={}, &block)
      url = (sym_or_url.is_a?(Symbol) ? url_for(sym_or_url) : sym_or_url)
      options[:body] = body_proc.call(options[:body]) if (options[:body] and body_proc)
      req = Typhoeus::Request.new(url, @options.merge(options))
      helper = OAuth::Client::Helper.new(req, @options.merge(consumer: token.consumer, token: token, request_uri: url))
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
    def self.parse(body)
      Nokogiri::XML(body)
    end

    # try to doctorify failing body
    def self.diagnose(body)
      case body
      when %r(^oauth)
        EscapeUtils.unescape_url(body).gsub('&', "\n")
      else
        Nokogiri::XML(body).xpath('//Message').to_a.map{|e| e.content}.uniq.join("\n")
      end
    end

    # Public : parse response or die if response fails
    def parse!(response)
      response.success?? Client.parse(response.body) : raise(Problem, Client.diagnose(response.body))
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
    def options
      @options
    end
  end
  class Problem < StandardError
  end
end