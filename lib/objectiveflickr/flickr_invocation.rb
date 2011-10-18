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
require 'jcode'
require 'digest/md5'
require 'cgi'

$KCODE = 'UTF8'

# This class plays the major role of the package. Named "FlickrInvocation"
# to allude to the making of an RPC call.

class FlickrInvocation
  @@default_api_key = ''
  @@default_shared_secret = ''
  @@default_options = {}
  
  SHARED_SECRET = ''
  AUTH_ENDPOINT = 'http://flickr.com/services/auth/'
  REST_ENDPOINT = 'http://api.flickr.com/services/rest/'

  # Initializes the instance with the api_key (required) and an 
  # optional shared_secret (required only if you need to make 
  # authenticated call). Current available option is:
  # * :raise_exception_on_error: set this key to true if you want the
  #   call method to raise an error if Flickr returns one
  def initialize(api_key = nil, shared_secret = nil, options = nil)
    @api_key = api_key || @@default_api_key
    @shared_secret = shared_secret || @@default_shared_secret
    @options = options || @@default_options    
  end
    
  # Invoke a Flickr method, pass :auth=>true in the param hash
  # if you want the method call to be signed (required when you
  # make authenticaed calls, e.g. flickr.auth.getFrob or 
  # any method call that requires an auth token)
  #
  # NOTE: If you supply :auth_token in the params hash, your API
  # call will automatically be signed, and the call will be 
  # treated by Flickr as an authenticated call
  def call(method, params=nil)
    if params && params[:post]
      rsp = FlickrResponse.new Net::HTTP.post_form(URI.parse(REST_ENDPOINT), post_params(method, params)).body
    else
      url = method_url(method, params)
      rsp = FlickrResponse.new Net::HTTP.get(URI.parse(url))
    end
    
    if @options[:raise_exception_on_error] && rsp.error?
      raise RuntimeError, rsp
    end
    
    rsp
  end
  
  # Returns a login URL to which you can redirect user's browser
  # to complete the Flickr authentication process (Flickr then uses
  # the callback address you've set previously to pass the
  # authentication frob back to your web app)
  #
  # New in 0.9.5: frob parameter for desktop applications
  # http://www.flickr.com/services/api/auth.howto.desktop.html
  def login_url(permission, frob=nil)
    if frob
      sig = api_sig(:api_key => @api_key, :perms => permission.to_s, :frob=> frob)
      url = "#{AUTH_ENDPOINT}?api_key=#{@api_key}&perms=#{permission}&frob=#{frob}&api_sig=#{sig}"
    else
      sig = api_sig(:api_key => @api_key, :perms => permission.to_s)
      url = "#{AUTH_ENDPOINT}?api_key=#{@api_key}&perms=#{permission}&api_sig=#{sig}"
    end
    url
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
  def method_url(method, params=nil)
    url = "#{REST_ENDPOINT}?api_key=#{@api_key}&method=#{method}"
    p = params || {}
    sign_params(method, p)
    
    p.keys.each { |k| url += "&#{k.to_s}=#{CGI.escape(p[k].to_s)}" }
    url
  end

  def post_params(method, params)
    p = params ? params.clone : {}
    p.delete :post
    sign_params(method, p)
    
    # since we're using Net::HTTP.post_form to do the call,
    # CGI escape is already done for us, so, no escape here
    # p.keys.each { |k| p[k] = CGI.escape(p[k].to_s) }    
    p
  end
  
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
end