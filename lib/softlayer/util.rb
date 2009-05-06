#!/usr/bin/env ruby
# util
#
# Author:: James Nuckolls
# Copyright:: Copyright (c) 2009 SoftLayer. All rights reserved.
#
#= Description
#
#= ToDo
#

require 'rubygems' rescue LoadError
gem 'soap4r'
require 'soap/header/simplehandler'


module SoftLayer
  # A class to old Paramaters.
  class Param < SOAP::Header::SimpleHandler
    def initialize(tag, out)
      @out = out
      super(XSD::QName.new(nil, tag))
    end

    def on_simple_outbound
      @out
    end

    def [](k)
      return @out[k]
    end

    def []=(k,v)
      @out[k]=v
    end
  end

  # A class to hold the object mask.
  class ObjectMask < SOAP::Header::SimpleHandler

    def initialize(tag, out)
      @out = out
      super(XSD::QName.new(nil, tag))
    end

    def on_simple_outbound
      { 'mask' => @out }
    end

    def [](k)
      @out[k]
    end

    def []=(k,v)
      @out[k]=v
    end
  end

  class ResultLimit < SOAP::Header::SimpleHandler
    attr_accessor :limit, :offset

    # limit should be an array of two elements; limit and offset.
    def initialize(tag, limit)
      @limit = limit[0]
      @offset = limit[1]
      super(XSD::QName.new(nil, tag))
    end

    def on_simple_outbound
      { 'limit' => @limit, 'offset' => @offset }
    end
  end


  # An Exception proxy class
  # Not every exception soap4r returns decends from RuntimeError.
  class Exception < RuntimeError
    attr_reader :name

    def initialize(args)
      e = args[:exception]
      message = args[:message] unless args[:message].nil?
      message = e.message unless e.nil?
      super(message)

      @name = e.faultcode.to_s unless e.nil?
      @name = self.name.to_s unless @name.nil?
      @realException = e unless e.nil?
      @realException = self if @realException.nil?
    end
    
    # Take a soap exception and generate a new Exception class.
    def Exception.factory(s)
      ek = SoftLayer::ClassFactory(:class => s.faultcode.to_s.gsub(/_/,'::'), :base => self)
      return ek.new(:exception => s)
    end
  end
end