# objectiveflickr is a minimalistic Flickr API library that uses REST-style calls 
# and receives JSON response blocks, resulting in very concise code. Named so in 
# order to echo another Flickr library of mine, under the same name, developed 
# for Objective-C.
#
# Author:: Lukhnos D. Liu (mailto:lukhnos@gmail.com)
# Copyright:: Copyright (c) 2006 Lukhnos D. Liu
# License:: Distributed under the New BSD License

require 'rubygems'
require 'json'

# This class encapusulates Flickr's JSON response block. Error code
# and error messsage are read from the response block. This class
# is intended to be simple and minimalistic, since the data body
# can be extracted very easily.

class FlickrResponse
  attr_reader :data
  
  # Initializes the instance with reponse block data
  def initialize(response)
    @data = JSON.parse(response)
  end
    
  # Returns true if it's a valid Flickr response
  def ok?
    return @data["stat"] == "ok" ? true : false
  end

  # Returns true if there's something wrong with the method call
  def error?
    return !ok?
  end
  
  # Returns Flickr's error code, 0 if none
  def error_code
    @data["code"] || 0
  end

  # Returns Flickr error message, nil if none
  def error_message
    @data["message"]
  end
  
  # A quick accessor to the data block
  def [](x)
    @data[x]
  end
end
