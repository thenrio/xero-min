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
      headers: {
        'Accept' => 'text/xml',
        'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8'
      }
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
    # url of request is XeroMin::Urls.url_for sym_or_url, when string_or_url_for is not a String
    # available options are the one of a Typhoeus::Request
    # request is yielded to block if present
    # first request ask for access token
    def request(string_or_url_for, options={}, &block)
      url = (string_or_url_for.is_a?(String) ? string_or_url_for : url_for(string_or_url_for))
      options[:body] = body_proc.call(options[:body]) if (options[:body] and body_proc)
      accept_option = options.delete(:accept)
      if accept_option
        options[:headers] ||= {}
        options[:headers].merge! 'Accept' => accept_option
      end
      req = Typhoeus::Request.new(url, @options.merge(options))

      # sign request with oauth
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
    def request!(string_or_url_for, options={}, &block)
      parse!(request(string_or_url_for, options, &block).tap{|r| run(r)}.response)
    end

    # Public: returns response body if Content-Type is application/pdf or a nokogiri node
    def self.parse(response)
      case content_type = response.headers_hash['Content-Type']
      when 'application/pdf'
        response.body
      when %r(^text/xml)
        Nokogiri::XML(response.body)
      else
        raise Problem, "Unsupported Content-Type : #{content_type}"
      end
    end

    # try to doctorify failing response
    def self.diagnose(response)
      diagnosis = case response.code
      when 400
        Nokogiri::XML(response.body).xpath('//Message').to_a.map{|e| e.content}.uniq.join("\n")
      when 401
        EscapeUtils.unescape_url(response.body).gsub('&', "\n")
      else
        response.body
      end
      "code=#{response.code}\n#{diagnosis}\nbody=\n#{response.body}"
    end

    # Public : parse response or die if response fails
    def parse!(response)
      response.success?? Client.parse(response) : raise(Problem, Client.diagnose(response))
    end

    # Public : get, put, and post are shortcut for a request using this verb (question mark available)
    [:get, :put, :post].each do |method|
      module_eval <<-EOS, __FILE__, __LINE__ + 1
        def #{method}(string_or_url_for, options={}, &block)
          request(string_or_url_for, {method: :#{method}}.merge(options), &block)
        end
        def #{method}!(string_or_url_for, options={}, &block)
          request!(string_or_url_for, {method: :#{method}}.merge(options), &block)
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