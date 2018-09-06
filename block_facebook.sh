#!/bin/bash

# DISCLAIMER
# Use this script at your own risk
# You, as a user, have no right to support even if implied
# Carefully read the script and then interpret, modify, correct, fork, disdain, whatever

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

# This script:
# 1 - crudely blocks all Facebook's IPs obtained from it's known Autonomous System Numbers (ASN) - https://en.wikipedia.org/wiki/Autonomous_system_(Internet)
# 2 - must be run with root privileges
# 3 - needs the following sites to be online: 1, riswhois.ripe.net; 2, mxtoolbox.com and www.ultratools.com for redundancy
# 4 - needs wget and phantomjs installed, everything else is probably installed by default, please install if something is missing (whois, perhaps ?)
# 5 - will add iptables rules, blocking Facebook IPs obtained from "public" Facebook's ASNs
# 6 - "should" be run from crontab on every boot; crontab has PATH somewhat limited, so PATH is defined
# 7 - (in my use case) it runs from crontab with "@reboot /full/path/to/block_facebook.sh", so that it always gets fresh Facebook's IPs; check Google for editing crontab

PATH=/bin:/sbin:/usr/bin:/usr/games:/usr/local/bin:/usr/local/bin:/usr/local/games:/usr/local/sbin:/usr/sbin

is_it_online () # check if needed site is online
{
   ! [ -f $temp_dirblock_facebook_failing.txt ] || rm $temp_dirblock_facebook_failing.txt # remove possible previous errors reports
   fail=-1
   while [ $fail != 0 ]
      do
         wget -o /dev/null -q --spider --timeout=15 "$1"
         fail=$?
         [ $fail == 0 ] || ((printf "$1 is offline (error $fail)  ";date +%Y-%m-%d\_%H:%M:%S) | cat >> $temp_dirblock_facebook_failing.txt;sleep 1m)
      done
   echo ""$0": $1 is online" # not needed if running from crontab
   ! [ -f $temp_dirblock_facebook_failing.txt ] || rm $temp_dirblock_facebook_failing.txt # clean at the end
}

# main

if [ `id -u` -ne 0 ]; then # test if we are running as root; if not, exit
   echo "not running as root"
   exit
fi

temp_dir=$(dirname $(mktemp -u))
temp_dir+="/"

logger "$0 started"

! [ -f $temp_dir.iptables_facebook.txt ] || rm $temp_dir.iptables_facebook.txt
! [ -f $temp_dir.facebook_ip_list.txt ] || rm $temp_dir.facebook_ip_list.txt

ping_this="8.8.8.8" # this is Google's DNS server, put an IP, domain or hostname that is on the "internet"
while [[ -z $test ]] # wait until beeing online
   do
      test=$(ping -c 1 -W 1 $ping_this | grep "64 bytes")
      sleep 1
   done
echo ""$0" is now online"

is_it_online "https://mxtoolbox.com"
javascript_parser="\
var system = require('system');
var page = require('webpage').create();
page.open(system.args[1], function()
{
   console.log(page.content);
   phantom.exit();
});"
phantomjs <(cat <<< "$javascript_parser") "https://mxtoolbox.com/SuperTool.aspx?action=asn%3Afacebook&run=networktools" | lynx --dump --stdin  | grep -v "file://\|^$" | grep -i facebook | grep -i monitor | awk '{print $4}' | grep -v '[a-Z]' > $temp_dir.facebook_ip_list.txt # slow because of javascript parser

is_it_online "https://www.ultratools.com"
for facebook_asn in $(wget -o /dev/null -O - https://www.ultratools.com/tools/asnInfoResult?domainName=facebook 2>&1 | html2text | grep AS | grep -Eo '[0-9]{4,}' | grep -v '^$' | uniq)
   do
       whois -H -h riswhois.ripe.net -- -F -K -i $facebook_asn | grep -v "^$" | grep -v "^%" | awk '{ print $2 }' | grep -v "::" >> $temp_dir.facebook_ip_list.txt
   done
   
echo "*filter" > $temp_dir.iptables_facebook.txt

for facebook_ip_range in $(cat $temp_dir.facebook_ip_list.txt | sort -n -t . -k 1 -k 2 -k 3 -k 4 | uniq | aggregate -q)
   do
      string="\
-I OUTPUT -s $facebook_ip_range -m comment --comment \"Block facebook source\" -j DROP
-I OUTPUT -d $facebook_ip_range -m comment --comment \"Block facebook destination\" -j DROP"
      echo -e "$string" >> $temp_dir.iptables_facebook.txt
   done
echo "COMMIT" >> $temp_dir.iptables_facebook.txt
iptables-restore -wn < $temp_dir.iptables_facebook.txt

rm $temp_dir.iptables_facebook.txt
rm $temp_dir.facebook_ip_list.txt


echo "$0 iptables rules for blocking Facebook IP ranges now added" # not needed if running from crontab
echo "$0 exiting"

logger "$0 exited"

exit 0
