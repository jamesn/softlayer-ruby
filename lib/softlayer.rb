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

require 'softlayer/baseclass'
require 'softlayer/util'


module SoftLayer

  DEFAULTBASE=SoftLayer::BaseClass

  # Declare SLAPI clases.  Args take class names in two forms:
  # +soap+:: Service names in SOAP format (example: SoftLayer_Account)
  # +ruby+:: Class names in Ruby format (example:  SoftLayer::Account)
  # +base+:: A substitute base class (otherwise SoftLayer::Base)
  # Creates the class, and retrieves and caches the endpoint WSDL.
  def SoftLayer::declareClasses(args)
    classes = args[:ruby]
    services = args[:soap]
    base = args[:base]

    classes = [] if classes.nil?
    unless (services.nil? || services.empty?)
      services.each do |s|
        c = s.gsub(/_/,'::')
        classes.push(c)
      end
    end

    classes.each do |cstr|
      k = SoftLayer::ClassFactory(:class => cstr, :base => base)
      k.cacheWSDL
    end
  end

  # Create a Ruby class to match an SLAPI WSDL endpoint.
  # Args:
  # +class+:: The name of the class to create in Ruby format.
  # +parent+:: The parent namespace to add the class to (this should be somewere in SoftLayer; optional).
  # +base+:: A substitute base class (otherwise SoftLayer::Base)
  # This recursively walks up +class+ creating them as needed, so SoftLayer::Dns::Domain will create
  # classes for Dns and Domain (even though the Dns class will never be used).
  def SoftLayer::ClassFactory(args)
    cname = args[:class]
    parent = args[:parent] unless args[:parent].nil?
    base = args[:base]
    base = DEFAULTBASE if base.nil?

    cary = cname.split('::')
    parent = const_get(cary.shift) if parent.nil? # This should always be SoftLayer, but maybe not...
    cur = cary.shift
    newclass = nil
    unless parent.const_defined?(cur)
      newclass = SoftLayer::makeSLAPIKlass(:class => cur, :parent => parent, :base => base)
    else
      newclass = parent.const_get(cur)
    end
    return newclass if cary.empty?

    left = cary.join('::')
    k = SoftLayer::ClassFactory(:class => left, :parent => newclass, :base => base) 
    return k
  end

  # This really creates the class.
  # +class+:: The name of the class to create in Ruby format.
  # +parent+:: The parent namespace to add the class to (this should be somewhere in SoftLayer, not optional).
  # +base+:: A substitute base class (otherwise SoftLayer::Base)
  def SoftLayer::makeSLAPIKlass(args)
    cname = args[:class]
    parent = args[:parent]
    base = args[:base]
    realKlassName = "#{cname}"
    klass = Class.new base do ; end
    parent.const_set realKlassName, klass
    return klass
  end
end