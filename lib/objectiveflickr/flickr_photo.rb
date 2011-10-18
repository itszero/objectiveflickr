# objectiveflickr is a minimalistic Flickr API library that uses REST-style calls 
# and receives JSON response blocks, resulting in very concise code. Named so in 
# order to echo another Flickr library of mine, under the same name, developed 
# for Objective-C.
#
# Author:: Lukhnos D. Liu (mailto:lukhnos@gmail.com)
# Copyright:: Copyright (c) 2006 Lukhnos D. Liu
# License:: Distributed under the New BSD License

# This helper module provides a set of utility methods for Flickr photos.
# Methods such as unique_id_from_hash and url_from_unique_id are 
# helpful when you try to move the photo id data to and fro your web 
# apps. 

module FlickrPhoto
  @photo_url_base = 'static.flickr.com'
  @default_buddy_icon = 'http://www.flickr.com/images/buddyicon.jpg'
  
  # Helper that gets you the URL of the buddy icon of a given user
  def self.buddy_icon_url(nsid, icon_server=nil, icon_farm=nil)
    if !icon_server || icon_server.to_i == 0
      return @default_buddy_icon
    end
    
    "#{self.photo_url_base(icon_farm)}/#{icon_server}/buddyicons/#{nsid}.jpg"
  end

  # Set the default photo base URL, without the http:// part
  def self.default_photo_url_base(b)
    @photo_url_base = b
  end

  # This utility method returns the URL of a Flickr photo using
  # the keys :farm, :server, :id, :secret, :size and :format
  #
  # The :type key that is used in ObjectiveFlickr prior to 0.9.5 
  # is deprecated. It is still supported, but support will be removed
  # in 0.9.6.
  #
  # Since January 2007, Flickr requires API libraries to support
  # :originalsecret and :originalformat
  def self.url_from_hash(params)
    self.url_from_normalized_hash(self.normalize_parameter(params))
  end


  # This utility method combines the Flickr photo keys (from which
  # one gets the real URL of a photo) into a photo id that you can
  # use in a div
  def self.element_id_from_hash(params, prefix='photo')
    p = self.normalize_parameter(params)
    [prefix, p[:server], p[:id], p[:secret], p[:farm], p[:size], p[:format]].join("-")    
  end

  # This utility method breaks apart the photo id into Flickr photo
  # keys and returns the photo URL  
  def self.url_from_element_id(uid)
    self.url_from_normalized_hash(self.hash_from_element_id(uid))
  end

  # This utility method breaks apart the photo id into Flickr photo
  # keys and returns a hash of the photo information
  #
  # NOTE: No sanitation check here
  def self.hash_from_element_id(uid)      
    p = uid.split("-")
    {
      :server=>p[1], :id=>p[2], :secret=>p[3],
      :farm=>p[4], :size=>p[5], :format=>p[6],
    }
  end

  # DEPRECATED--Call element_id_from_hash instead
  def self.unique_id_from_hash(params, prefix='photo')
    self.element_id_from_hash(params, prefix)
  end

  # DEPRECATED--Call url_from_element_id instead
  def self.url_from_unique_id(uid)
    self.url_from_element_id(uid)
  end

  # DEPRECATED--Call hash_from_element_id instead
  def self.hash_from_unique_id(uid)
    self.hash_from_element_id(uid)
  end

  private
  def self.url_from_normalized_hash(p)
    if p[:size]=="o" && p[:originalformat] && p[:originalsecret]
      url = "#{photo_url_base(p[:farm])}/#{p[:server]}/#{p[:id]}_#{p[:originalsecret]}"
      url += "_o"
      url += ".#{p[:originalformat]}"      
    else
      url = "#{photo_url_base(p[:farm])}/#{p[:server]}/#{p[:id]}_#{p[:secret]}"
      url += "_#{p[:size]}" if p[:size].length > 0
      url += ".#{p[:format]}"
    end
  end

  private
  def self.normalize_parameter(params)
    h = {
      :farm => (params[:farm] || params["farm"] || "").to_s,
      :server => (params[:server] || params["server"] || "").to_s,
      :id => (params[:id] || params["id"] || "").to_s,
      :secret => (params[:secret] || params["secret"] || "").to_s,
      :size => (params[:size] || params["size"] || "").to_s,
      :format => (params[:format] || params["format"] || params[:type] || params["type"] || "jpg").to_s
    }
    
    os = params[:originalsecret] || params["originalsecret"]
    if os
      h[:originalsecret] = os.to_s
    end
    
    of = params[:originalformat] || params["originalformat"]
    if of
      h[:originalformat] = of.to_s
    end
    
    h
  end
  
  private
  def self.photo_url_base(farm_id=nil)
    urlbase = (farm_id && farm_id.to_s.length > 0) ? "http://farm#{farm_id}." : "http://"
    "#{urlbase}#{@photo_url_base}"
  end
end

