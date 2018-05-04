#!/bin/bash
###################################################
# DISCLAIMER
# Use this script at your own risk
# You, as a user, have no right to support even if implied
# Carefully read the script and then interpret, modify, correct, fork, disdain, whatever
###################################################
#Copyright (c) <2018> <test666v2>
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
###################################################
# This script:
# 1 - crudely blocks all Facebook's IPs obtained from it's known Autonomous System Numbers (ASN) - https://en.wikipedia.org/wiki/Autonomous_system_(Internet)
# 2 - must be run with root privileges
# 3 - needs bgpview.io and riswhois.ripe.net to be online and providing the required information
# 4 - needs curl installed, everything else is probably installed by default, please install if something is missing (whois, perhaps ?)
# 5 - will add iptables rules, blocking Facebook IPs obtained from "public" Facebook's ASNs
# 6 - "should" be run from crontab on every boot; crontab has PATH somewhat limited, so PATH is defined
# 7 - in my use case, runs from crontab with "@reboot /full/path/to/block_facebook.sh", so that it always gets fresh Facebook's IPs; check Google for editing crontab
###################################################
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
if [ `id -u` -ne 0 ]; then # test if we are running as root; if not, exit
   echo "not running as root"
	exit
fi
ping_this="8.8.8.8" # this is Google's DNS server, put an IP, domain or hostname that is on the "internet"
while [[ -z $test ]] # wait until beeing online
   do
      test=$(ping -c 1 -W 1 $ping_this | grep "64 bytes")
      sleep 1
   done 
echo "online" # not needed if running from crontab
#echo "************************" > /dev/shm/.block_facebook.txt
for facebook_asn in $(curl -s https://bgpview.io/search/facebook | grep "https://bgpview.io/asn/" | sed 's: ::g' | cut -c 36-40  | cut -f1 -d"\"") # very crude, depends on the HTML code, adapt if something changes
   do
#   echo "************************" >> /dev/shm/.block_facebook.txt
#   echo "AS$facebook_asn" >> /dev/shm/.block_facebook.txt
      for facebook_ip_range in $(whois -H -h riswhois.ripe.net -- -F -K -i $facebook_asn | grep -v "^$" | grep -v "^%" | awk '{ print $2 }' | grep -v "::")
         do
            iptables -w -I INPUT 1 -s $facebook_ip_range -j REJECT # block for incoming
            iptables -w -I OUTPUT 1 -s $facebook_ip_range -j REJECT # block for outgoing
#            echo "$facebook_ip_range" >> /dev/shm/.block_facebook.txt
         done
   done
echo "iptables rules for blocking Facebook IP ranges now added" # not needed if running from crontab
exit 0
