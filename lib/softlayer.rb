#!/usr/bin/env ruby
# softlayer
#
# Copyright (c) 2009, James Nuckolls. All rights reserved.
# 
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
# 
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   * Neither "James Nuckolls" nor the names of any contributors may
#     be used to endorse or promote products derived from this software without
#     specific prior written permission.
# 
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
#
#= Description
#
#= ToDo
#

require 'rubygems' rescue LoadError
gem 'soap4r'
require 'soap/header/simplehandler'
require 'soap/wsdlDriver'


module SoftLayer

  # Declare SLAPI clases.  Args take class names in two forms:
  # +soap+:: Service names in SOAP format (example: SoftLayer_Account)
  # +ruby+:: Class names in Ruby format (example:  SoftLayer::Account)
  # Creates the class, and retrieves and caches the endpoint WSDL.
  def SoftLayer::declareClasses(args)
    classes = args[:ruby]
    services = args[:soap]

    unless (services.nil? || services.empty?)
      services.each do |s|
        c = s.gsub(/_/,'::')
        classes.push(c)
      end
    end

    classes.each do |cstr|
      k = SoftLayer::ClassFactory(:class => cstr)
      k.cacheWSDL
    end
  end

  # Create a Ruby class to match an SLAPI WSDL endpoint.
  # Args:
  # +class+:: The name of the class to create in Ruby format.
  # +parent+:: The parent namespace to add the class to (this should be somewere in SoftLayer; optional).
  # This recursively walks up +class+ creating them as needed, so SoftLayer::Dns::Domain will create
  # classes for Dns and Domain (even though the Dns class will never be used).
  def SoftLayer::ClassFactory(args)
    cname = args[:class]
    parent = args[:parent] unless args[:parent].nil?

    cary = cname.split('::')
    parent = const_get(cary.shift) if parent.nil? # This should always be SoftLayer, but maybe not...
    cur = cary.shift
    newclass = nil
    unless parent.const_defined?(cur)
      newclass = SoftLayer::makeSLAPIKlass(:class => cur, :parent => parent)
    else
      newclass = parent.const_get(cur)
    end
    return newclass if cary.empty?

    left = cary.join('::')
    k = SoftLayer::ClassFactory(:class => left, :parent => newclass) 
    return k
  end

  # This really creates the class.
  # +class+:: The name of the class to create in Ruby format.
  # +parent+:: The parent namespace to add the class to (this should be somewhere in SoftLayer, not optional).
  def SoftLayer::makeSLAPIKlass(args)
    cname = args[:class]
    parent = args[:parent]
    realKlassName = "#{cname}"
    klass = Class.new SoftLayer::BaseClass do 

    end
    parent.const_set realKlassName, klass
    return klass
  end

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

  # The Base class for our generated class.
  class BaseClass

    WSDLBASE='http://api.service.softlayer.com/soap/v3'
    WSDLPARAM='?wsdl'

    @@wsdl = { }
    @@apiUser = nil
    @@apiKey = nil

    # The initializer.
    # Arguments:
    # +user+::  The API User
    # +key+:: The API Key
    # +initParams+:: This object's initParam (just the key)
    # +debug+:: Enable debug after driver creation. (IO handler)
    #
    # +user+ and +key+ are optional.  The first time they're presented
    # they're saved to class variables and reused later as necessary.  Supplying
    # +user+ and +key+ later does not overwrite the class variables.  +initParams+ is
    # required where the api requires it.
    def initialize(args)
      @apiUser = args[:user] unless args[:user].nil?
      @apiKey = args[:key] unless args[:key].nil?
      @initParam = args[:initParam]

      @@apiUser = args[:user] unless (args[:user].nil? || !@@apiUser.nil?)
      @@apiKey = args[:key] unless (args[:key].nil? || !@@apiKey.nil?)
      @apiUser = @@apiUser unless (@@apiUser.nil? || !@apiUser.nil?)
      @apiKey = @@apiKey unless (@@apiKey.nil? || !@apiKey.nil?)
      @authHeader = Param.new('authenticate', {'username' => @apiUser, 'apiKey' => @apiKey})

      self.class.cacheWSDL
      @slapi = @@wsdl[self.soapClass].create_rpc_driver
      self.debug=args[:debug] unless args[:debug].nil?
    end

    # Return this object's matching SLAPI SOAP Class.
    def soapClass
      return self.class.to_s.gsub(/::/, '_')
    end

    # This returns key values from this Service's associated Type (retrieved using #getObject).
    def [](key)
      @slapiObject = self.getObject if @slapiobject.nil?
      return @slapiObject[key.to_s]
    end

    def setObject(obj)
      @slapiObject = obj
    end

    # Set the object mask which ia passed as a hash of optional hashes (otherwise the hash elements should have a nil value).
    # Using the example from the wiki:
    #  <SoftLayer_AccountObjectMask xsi:type="v3:SoftLayer_AccountObjectMask">
    #    <mask xsi:type="slt:SoftLayer_Account" xmlns:slt="http://api.service.softlayer.com/soap/v3/SLTypes/">
    #        <domains>
    #            <resourceRecords />
    #        </domains>
    #        <openTickets>
    #            <assignedUser />
    #            <attachedHardware />
    #            <updates />
    #        </openTickets>
    #        <userCount />
    #    </mask>
    #  </SoftLayer_AccountObjectMask>
    #
    #  { 'domains' => { 'resourceRecords' => nil }, 'openTicket' => { 'assignedUser' => nil, 'attachedHardware' => nil, 'updates' => nil },
    #   userCount => nil }
    # Changing this resets the cached object used by #[]
    def objectMask=(mask)
      if mask.class == ObjectMask
        @objectMask = mask
      else
        @objectMask = ObjectMask.new("#{self.soapClass}ObjectMask", mask)
      end
      @slapiObject = nil
    end

    def objectMask
      return @objectMask
    end

    # Set an object wide result set (or clear it)
    # arg can be one of three things:
    # * nil clears the resultLimit
    # * A Result Limit array of two elements range and offset.
    # * An existing ResultLimit object
    def resultLimit=(arg)
      case arg.class
      when NilClass
        @resultLimit = nil
      when Array
        @resultLimit = ResultLimit.new('resultLimit',arg)
      when ResultLimit
        @resultLimit = arg
      end
    end

    def resultLimit
      return @resultLimit
    end


    # Make a direct api call.  Paramaters are a hash where the key is passed to ParamHeader as the tag, and the value
    # is passed as the tag content, unless it's a magic paramater.
    # Magic Paramaters:
    # +initParam+:: Initialization paramater for this call (just the key), therwise @initParam is used.
    # +limit+:: A Result Limit array of two elements range and offset.  If @resultLimit is set it's used
    # if +limit+ is not and if neither is set, no limit is applied.
    # 
    # If a block is provided, the limit's range (or fewer) elements will yield to the block until the dataset
    # is exhausted.  If no limit is provided with the block a limit of [1,0] is assumed initially.
    # Aliased to #method_missing.
    def slapiCall(method, args = { }, &block)

      initParam = args[:initParam] unless args[:initParam].nil?
      args.delete(:initParam) unless args[:initParam].nil?
      initParam = Param.new("#{self.soapClass}InitParameters", { 'id' => initParam }) unless initParam.nil?
      initParam = @initParam if initParam.nil?
      resultLimit = ResultLimit.new('resultLimit', args[:limit]) unless args[:limit].nil?
      args.delete(:limit) unless args[:limit].nil?
      resultLimit = @resultLimit if resultLimit.nil?

      @slapi.headerhandler << @authHeader unless @slapi.headerhandler.include?(@authHeader)
      paramHeaders = []
      unless args.nil?
        args.each do |k,v|
          p = Param.new(k.to_s,v)
          paramHeaders.push(p)
          @slapi.headerhandler << p
        end
      end
      @slapi.headerhandler << initParam unless @slapi.headerhandler.include?(@authHeader)
      @slapi.headerhandler << @objectMask unless @objectMask.nil?
      @slapi.headerhandler << resultLimit unless resultLimit.nil?

      if block_given?
        go=true
        resultLimit = ResultLimit.new('resultLimit', [1,0]) if resultLimit.nil? # this is broken.
        @slapi.headerhandler << resultLimit unless @slapi.headerhandler.include?(resultLimit)
        while(go) do
          res = @slapi.call(method.to_s)
          yield(res) unless (res.nil? || (res.respond_to?(:empty) && res.empty?))
          go = false if res.nil?
          go = false if (res.respond_to?(:size) && (res.size < resultLimit.limit))
          resultLimit.offset=resultLimit.offset + resultLimit.limit
        end
        headerClean(resultLimit,paramHeaders)
        return true
      else
        res = @slapi.call(method.to_s)
        headerClean(resultLimit,paramHeaders)
        return res
      end
    end

    # Alias the above call method to #method_missing.
    alias_method  :method_missing, :slapiCall

    def call(method, args = { }, &block)
      return slapiCall(method, args, &block)
    end

    # Enable (or disable) debug. (paramater is the IO handler to write to)
    def debug=(dev)
      @slapi.wiredump_dev=(dev)
    end

    # Get the WSDL, parse it, and save it to a Class level hash.
    # Returns false of we couldn't parse the WSDL.
    def self.cacheWSDL
      return unless @@wsdl[self.soapClass].nil?

      begin
        # XXX: Silence a warning
        v = $VERBOSE
        $VERBOSE=nil
        @@wsdl[self.soapClass] = SOAP::WSDLDriverFactory.new(self.wsdlUrl)
        $VERBOSE = v
        return true
      rescue => e
        return false
      end 
    end

    # Return this Class's WSDL.
    def self.wsdl
      return @@wsdl[self.soapClass]
    end

    # Return this Class's WSDL URL.
    def self.wsdlUrl
      return URI.parse("#{WSDLBASE}/#{self.soapClass}#{WSDLPARAM}")
    end

    # Returns this Class's SOAP Class.
    def self.soapClass
      self.name.to_s.gsub(/::/, '_')
    end

    private

    # Clean the headers out of the driver.
    def headerClean(rl,ha)
      @slapi.headerhandler.delete(rl)
      ha.each { |h| @slapi.headerhandler.delete(h) }

    end

  end
end