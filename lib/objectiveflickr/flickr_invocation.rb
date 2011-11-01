# objectiveflickr is a minimalistic Flickr API library that uses REST-style calls 
# and receives JSON response blocks, resulting in very concise code. Named so in 
# order to echo another Flickr library of mine, under the same name, developed 
# for Objective-C.
#
# Author:: Lukhnos D. Liu (mailto:lukhnos@gmail.com)
# Copyright:: Copyright (c) 2006 Lukhnos D. Liu
# License:: Distributed under the New BSD License

require 'rubygems'
require 'net/http'
require 'digest/md5'
require 'cgi'
require 'oauth'

# This class plays the major role of the package. Named "FlickrInvocation"
# to allude to the making of an RPC call.
class FlickrInvocation
  attr_accessor :access_token
  
  @@default_options = {}
  
  SHARED_SECRET  = ''
  AUTH_ENDPOINT  = 'http://flickr.com/services/auth/'
  OAUTH_ENDPOINT = 'http://www.flickr.com/services/oauth/'
  REST_ENDPOINT  = 'http://api.flickr.com/services/rest/'

  # Initializes the instance with the api_key (required) and an 
  # optional shared_secret (required only if you need to make 
  # authenticated call). Current available option is:
  # * :raise_exception_on_error: set this key to true if you want the
  #   call method to raise an error if Flickr returns one
  # * :rest_endpoint - custom REST API endpoint
  # * :auth_endpoint - custom Auth API endpoint
  # * :api_key - flickr API Key for old(deprecated) API
  # * :shared_secret - flickr API secret for old (deprecated)API
  # * :oauth_endpoint - custom OAuth API endpoint
  # * :oauth_consumer_key - OAuth consumer key (needed for OAuth)
  # * :oauth_consumer_secert - OAuth consumer secret (needed for OAuth)
  # * :oauth_access_token - OAuth access token (if you have it)
  # * :oauth_access_token_secret - OAuth access token secert (if you have it)
  def initialize(options = nil)
    @options = options || @@default_options
    @api_key = @options[:api_key] || @options[:oauth_consumer_key]
    @shared_secret = @options[:shared_secret]
    @rest_endpoint = @options[:rest_endpoint] || REST_ENDPOINT
    @auth_endpoint = @options[:auth_endpoint] || AUTH_ENDPOINT
    
    if @options[:oauth_access_token] && @options[:oauth_access_token_secret]
      @access_token = OAuth::AccessToken.new(oauth_customer, @options[:oauth_access_token], @options[:oauth_access_token_secret])
    end
  end
    
  # Invoke a Flickr method, pass :auth=>true in the param hash
  # if you want the method call to be signed (required when you
  # make authenticaed calls, e.g. flickr.auth.getFrob or 
  # any method call that requires an auth token)
  #
  # NOTE: If you supply :auth_token in the params hash, your API
  # call will automatically be signed, and the call will be 
  # treated by Flickr as an authenticated call
  #
  # NOTE_OAuth: Your call will be signed when:
  #  1. access_token existed, either by regular login or from saved
  #        credentials.
  #  2. params[:auth] = true
  def call(method, params={})
    if using_oauth? && params[:auth]
      params[:format] = 'json'
      params[:nojsoncallback] = '1'
      params.delete :auth
      
      if params[:post]
        params['method'] = method
        rsp = FlickrResponse.new @access_token.post(@rest_endpoint, params, {}).body
      else
        rsp = FlickrResponse.new @access_token.get(method_url(method, params, false)).body
      end
    else
      if params && params[:post]
        rsp = FlickrResponse.new Net::HTTP.post_form(URI.parse(@rest_endpoint), post_params(method, params)).body
      else
        url = method_url(method, params)
        rsp = FlickrResponse.new Net::HTTP.get(URI.parse(url))
      end
    end
    
    if @options[:raise_exception_on_error] && rsp.error?
      raise RuntimeError, rsp
    end
    
    rsp
  end

  # ---- Flickr REST API Authentication ----

  # DEPRECATED--Use new OAuth based login
  # Returns a login URL to which you can redirect user's browser
  # to complete the Flickr authentication process (Flickr then uses
  # the callback address you've set previously to pass the
  # authentication frob back to your web app)
  def login_url(permission, frob=nil)
    if frob
      sig = api_sig(:api_key => @api_key, :perms => permission.to_s, :frob=> frob)
      url = "#{@auth_endpoint}?api_key=#{@api_key}&perms=#{permission}&frob=#{frob}&api_sig=#{sig}"
    else
      sig = api_sig(:api_key => @api_key, :perms => permission.to_s)
      url = "#{@auth_endpoint}?api_key=#{@api_key}&perms=#{permission}&api_sig=#{sig}"
    end
    url
  end

  # ---- Flickr OAuth Authentication ----

  def fetch_request_token(callback_url)
    @request_token = oauth_customer.get_request_token({
      :oauth_callback => callback_url
    })
  end
  
  def authorize_url(perms)
    raise "Request token not available. Please call to 'request_token' first with your callback url." if @request_token.nil?
    raise "Please provide perms: read, write, delete" if perms.nil? || (not ['read', 'write', 'delete'].include? perms)
    
    @request_token.authorize_url(perms: perms)
  end
  
  def fetch_access_token(oauth_verifier)
    raise "Request token not available. Please call to 'request_token' first with your callback url." if @request_token.nil?
    @access_token = @request_token.get_access_token(:oauth_verifier => oauth_verifier)
  end

  # DEPRECATED--Use FlickrPhoto.url_from_hash(params)
  def photo_url(params)
    FlickrPhoto.url_from_hash(params)
  end

  # DEPRECATED--Use FlickrPhoto.unique_id_from_hash(params, prefix)
  def photo_div_id(params, prefix='photo')
    FlickrPhoto.unique_id_from_hash(params, prefix)
  end

  # DEPRECATED--Use FlickrPhoto.url_from_unique_id(uid)
  def photo_url_from_div_id(uid)
    FlickrPhoto.url_from_unique_id(uid)
  end

  # DEPRECATED--Use FlickrPhoto.hash_from_unique_id(uid)
  def photo_info_from_div_id(uid)
    FlickrPhoto.hash_from_unique_id(uid)
  end

  # set the default API key
  def self.default_api_key(k)
    @@default_api_key=k
  end
  
  # set the default shared secret
  def self.default_shared_secret(s)
    @@default_shared_secret=s
  end

  # set the default options, e.g. :raise_exception_on_error=>true  
  def self.default_options(o)
    @@default_options = o
  end
  
  private
  def method_url(method, params=nil, need_sign=true)
    url = "#{@rest_endpoint}?api_key=#{@api_key}&method=#{method}"
    p = params || {}
    sign_params(method, p) if need_sign
    
    p.keys.each { |k| url += "&#{k.to_s}=#{CGI.escape(p[k].to_s)}" }
    url
  end
  
  # DEPRECATED--Only used by old auth--BEGIN  
  def api_sig(params)
    sigstr = @shared_secret
    params.keys.sort { |x, y| x.to_s <=> y.to_s }.each do |k|
      sigstr += k.to_s
      sigstr += params[k].to_s
    end
    Digest::MD5.hexdigest(sigstr)
  end
  
  # we add json parameter here, telling Flickr we want json!
  def sign_params(method, p)
    p[:format] = 'json'
    p[:nojsoncallback] = 1
    
    if p[:auth] || p["auth"] || p[:auth_token] || p["auth_token"]
      p.delete(:auth)
      p.delete("auth")
      sigp = p
      sigp[:method] = method
      sigp[:api_key] = @api_key
      p["api_sig"] = api_sig(sigp)
    end
    
    p
  end
  # DEPRECATED--Only used by old auth-- END
  
  def post_params(method, params)
    p = params ? params.clone : {}
    p.delete :post
    sign_params(method, p)
    
    # since we're using Net::HTTP.post_form to do the call,
    # CGI escape is already done for us, so, no escape here
    # p.keys.each { |k| p[k] = CGI.escape(p[k].to_s) }    
    p
  end
  
  def oauth_customer
    @consumer ||= OAuth::Consumer.new(
      @options[:oauth_consumer_key],
      @options[:oauth_consumer_secret],
      {
        :site => 'http://flickr.com/',
        :request_token_path => '/services/oauth/request_token',
        :access_token_path => '/services/oauth/access_token',
        :authorize_path => '/services/oauth/authorize',
        :signature_method => 'HMAC-SHA1'
      }
    )
  end
  
  def using_oauth?
    not @access_token.nil?
  end
end
