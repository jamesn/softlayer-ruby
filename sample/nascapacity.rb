#!/usr/bin/env ruby
# nascapacity
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
# Prints a list of all StorageLater objects and their capacity.
#= ToDo
#

require 'rubygems' rescue LoadError
require 'pp'
require 'softlayer'

require 'soap/header/simplehandler'
require 'soap/wsdlDriver'

AUTH_USER = ARGV[0]
AUTH_KEY = ARGV[2]
ACCT_ID = ARGV[1]

SLAPICLASSES = [ 'SoftLayer::Account', 'SoftLayer::Network::Storage' ]
SoftLayer::declareClasses(:ruby => SLAPICLASSES)

account = SoftLayer::Account.new(:user => AUTH_USER, :key => AUTH_KEY, :initParam => ACCT_ID)
account.objectMask={ 'networkStorage' => { 'serviceResource' => nil } }

nas = account['networkStorage'].each do |nas|
  # pp nas
  type = nas['nasType']
  puts "//#{nas['serviceResource']['backendIpAddress']}/#{nas['username']} -- #{nas['capacityGb']}G" if (type == 'NAS' || type == 'LOCKBOX')
  puts "#{nas['username']}@#{nas['serviceResource']['backendIpAddress']} -- #{nas['capacityGb']}G" if (type == 'EVAULT' || type == 'ISCSI')
  puts "CloudLayer: #{nas['username']} -- #{nas['capacityGb']}G" if (type == 'HUB')
end

