#!/usr/bin/env ruby
# billingreport
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
require 'pp'
require 'softlayer'

AUTH_USER = ARGV[0]
AUTH_KEY = ARGV[2]
ACCT_ID = ARGV[1]

SLAPICLASSES = [ 'SoftLayer::Account' ]
SoftLayer::declareClasses(:ruby => SLAPICLASSES)

account = SoftLayer::Account.new(:user => AUTH_USER, :key => AUTH_KEY, :initParam => ACCT_ID)
account.objectMask={ 'allBillingItems' => nil }
  
rtotal = rtax = 0
ottotal = ottax = 0
lftotal = lftax = 0
sftotal = sftax = 0
account['allBillingItems'].each do |b|
  if b['cancellationDate'].nil?
    rtotal = rtotal + rf = b['recurringFee'].to_f
    ottotal = ottotal + ot = b['oneTimeFee'].to_f
    lftotal = lftotal + lf = b['laborFee'].to_f
    sftotal = sftotal + sf = b['setupFee'].to_f
    rt = rf * rtr = b['recurringFeeTaxRate'].to_f
    ott = ot * otr = b['oneTimeFeeTaxRate'].to_f
    lft = lf * lfr = b['laborFeeTaxRate'].to_f
    sft = sf * sfr = b['setupFeeTaxRate'].to_f
    rtax = rtax + rt
    ottax = ottax + ott
    lftax = lftax + lft
    sftax = sftax + sft

    puts "Item Id #{b['id']}"
    puts "Description #{b['description']}"
    puts "Recurring Fee #{"$%.2f" % rf}"
    puts "Recurring Tax #{"$%.2f" % rt} (#{rtr * 100}%)"
    puts "One Time Fee #{"$%.2f" % ot}" unless ot == 0
    puts "One Time Tax #{"$%.2f" % ott} (#{otr * 100}%)" unless ot == 0
    puts "Labor Fee #{"$%.2f" % lf}" unless lf == 0
    puts "Labor Fee Tax #{"$%.2f" % lft} (#{lfr * 100}%)" unless lf == 0
    puts "Setup Fee #{"$%.2f" % sf}" unless sf == 0
    puts "Setup Fee Tax #{"$%.2f" % sft} (#{sfr * 100}%)" unless sf == 0
    puts "Recurring Months #{b['recurringMonths']}"
    puts "Last Bill Date #{b['lastBillDate'].strftime("%b %d, %Y %X")}"
    puts "Next Bill Date #{b['nextBillDate'].strftime("%b %d, %Y %X")}"
    puts "Modify Date #{b['modifyDate'].strftime("%b %d, %Y %X")}"
    puts "Create Date #{b['createDate'].strftime("%b %d, %Y %X")}"
    puts "Associated Billing Item Id #{b['associatedBillingItemId']}"  unless b['associatedBillingItemId'].nil?
    puts "=================================="
    # pp b
  end
end
puts ""
puts "Totals:"
puts "\tRecurring: #{"$%.2f" % rtotal} Tax: #{"$%.2f" % rtax} == #{"$%.2f" % (rtotal + rtax)}"
puts "\tOne Time : #{"$%.2f" % ottotal} Tax: #{"$%.2f" % ottax} == #{"$%.2f" % (ottotal + ottax)}" unless ottotal == 0
puts "\tLabor    : #{"$%.2f" % lftotal} Tax: #{"$%.2f" % lftax} == #{"$%.2f" % (lftotal + lftax)}" unless lftotal == 0
puts "\tSetup    : #{"$%.2f" % sftotal} Tax: #{"$%.2f" % sftax} == #{"$%.2f" % (sftotal + sftax)}" unless sftotal == 0
