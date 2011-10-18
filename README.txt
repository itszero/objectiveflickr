README for objectiveflickr
==========================

objectiveflickr is a minimalistic Flickr API library that uses REST-style
calls and receives JSON response blocks, resulting in very concise code.
Named so in order to echo another Flickr library of mine, under the same name,
developed for Objective-C.

This library is designed to be simple and easy to use. Simply create a
FlickrInvocation instance with your Flickr API key and "shared secret"
(if you need to make authenticated calls), and there you go.

Requires json.

Currently no uploading function is provided. FlickrInvocation and
FlickrResponse are all the classes there are. No other class is created
to encapsulate the myriad of Flickr response types. I find it unnecessary
now that we have JSON response block which can be converted into native
Ruby data structure so easily. So I'd rather let the developers rely on
Flickr's API documentation to extract the data they need. This makes
the library ultra lightweight and very flexible if Flickr decides to add
more items in any of their response block. No extra code is ever needed.

ObjectiveFlickr also comes in Objective-C flavor, which is hosteed at
Google Code: http://code.google.com/p/objectiveflickr/

The library is distributed under the New BSD License. Feel free to make
full use of it. Comments and feedback can be sent to lukhnos{at}gmail.com.

