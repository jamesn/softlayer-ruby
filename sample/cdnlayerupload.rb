#!/usr/bin/env ruby
# cdnlayerupload
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
#  Retrieves the current Account's BillingItems using an objectMask and outputs a report of the
#  current (not-canceled) items.
#= ToDo
#

require 'rubygems' rescue LoadError
require 'ftools'
require 'pp'
require 'softlayer'

AUTH_USER = ARGV[0]
AUTH_KEY = ARGV[4]
ACCT_ID = ARGV[1]
CDN_ACCT = ARGV[2]
INFILE = ARGV[3]

SLAPICLASSES = [ 'SoftLayer::Account', 'SoftLayer::Network::ContentDelivery::Account' ]
SoftLayer::declareClasses(:ruby => SLAPICLASSES)
account = SoftLayer::Account.new(:user => AUTH_USER, :key => AUTH_KEY, :initParam => ACCT_ID)
account.objectMask={'cdnAccountName' => nil}

# Get the accout number by matching the name that was in ARGV[2]
cdnacct = nil
account.getCdnAccounts.each do |c|
  # pp c
  cdnacct = SoftLayer::Network::ContentDelivery::Account.new(:initParam => c['id']) if c['cdnAccountName'] == CDN_ACCT
end

fname = File.basename(INFILE)
# base64 encode the file
b64 = [IO.read(INFILE)].pack("m")
# cdnacct.debug=STDOUT
ret = cdnacct.uploadStream(:source => { 'data' => b64, 'filename' => fname}, :target => "/media/http/test")
pp ret


