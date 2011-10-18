require File.dirname(__FILE__) + '/test_helper.rb'
require 'yaml'

class ObjectiveFlickrTest < Test::Unit::TestCase

  TEST_API_KEY = 'bf67a649fffb210651334a09b92df02e'

  def setup
    @f = FlickrInvocation.new(TEST_API_KEY)
  end
  
  def test_truth
    assert true
  end
  
  # we use a unit test API key for this purpose
  def test_echo
    r = @f.call("flickr.test.echo")
    assert(r.ok?, "response should be ok")
    assert_equal(r["method"]["_content"], "flickr.test.echo", "method name should echo")
  end
  
  def test_echo_escaped_characters
    r = @f.call("flickr.test.echo", :text=>"漢字 @ < > & lorem ipsum")
    puts r.to_yaml
    assert(r.ok?, "response should be ok")
    assert_equal("漢字 @ < > & lorem ipsum", r["text"]["_content"], "CJKV, HTML entities and other characters should be properly URL-escaped")
  end
  
  
  def test_default_settings
    FlickrInvocation.default_api_key 'bf67a649fffb210651334a09b92df02e'
    f = FlickrInvocation.new

    r = f.call("flickr.test.echo")
    assert(r.ok?, "response should be ok")
    assert_equal(r["method"]["_content"], "flickr.test.echo", "method name should echo")
  end
  
  def test_corrupt_key
    # try a corrupt key
    FlickrInvocation.default_api_key 'bf67a649fffb210651334a09b92df02f'
    FlickrInvocation.default_options :raise_exception_on_error => true

    f = FlickrInvocation.new
    r = f.call("flickr.test.echo")

  rescue => e
    assert(e.message.error?, "response should be an error")
    assert_equal(e.message.error_message, "Invalid API Key (Key not found)", "error message should be 'invalid API key'")
  end
  
  def test_deprecated_photo_helpers    
    params = {:server=>1234, :id=>5678, :secret=>90, :farm=>321}
    assert_equal(@f.photo_url(params), "http://farm321.static.flickr.com/1234/5678_90.jpg", "URL helper failed")
    uid = @f.photo_div_id(params)
    assert_equal(uid, "photo-1234-5678-90-321--jpg", "UID failed")
  end
  
  def test_photo_helpers
    params = {:server=>"1234", :id=>"5678", :secret=>"90" }
        
    assert_equal(FlickrPhoto.url_from_hash(params), "http://static.flickr.com/1234/5678_90.jpg", "URL helper failed")
    params[:farm] = "321"
    assert_equal(FlickrPhoto.url_from_hash(params), "http://farm321.static.flickr.com/1234/5678_90.jpg", "URL helper failed")
    params[:farm] = nil
    
    uid = FlickrPhoto.element_id_from_hash(params, 'blah')
    assert_equal(uid, "blah-1234-5678-90---jpg", "UID failed")
    
    params[:farm] = "321"
    params[:size] = 'b'
    uid = FlickrPhoto.element_id_from_hash(params, 'blah')
    assert_equal(uid, "blah-1234-5678-90-321-b-jpg", "UID failed")

    
    assert_equal(FlickrPhoto.url_from_element_id(uid), "http://farm321.static.flickr.com/1234/5678_90_b.jpg", "URL helper failed")    
    
    # type is deprecated
    # params[:type] = 'jpg'
    
    params[:format] = 'jpg'
    h = FlickrPhoto.hash_from_element_id(uid)
    assert_equal(h, params, "hash_from_element_id failed")


    params[:originalformat] = 'png'
    params[:originalsecret] = '9999'
    params[:size] = 'o'
    assert_equal("http://farm321.static.flickr.com/1234/5678_9999_o.png", FlickrPhoto.url_from_hash(params), "URL helper failed")

  end 
  
  def test_buddy_icons
    assert_equal FlickrPhoto.buddy_icon_url("12345678@N1234"), "http://www.flickr.com/images/buddyicon.jpg"
    assert_equal FlickrPhoto.buddy_icon_url("12345678@N1234", "92"), "http://static.flickr.com/92/buddyicons/12345678@N1234.jpg"
    assert_equal FlickrPhoto.buddy_icon_url("12345678@N1234", "92", "1"), "http://farm1.static.flickr.com/92/buddyicons/12345678@N1234.jpg"
  end
end
