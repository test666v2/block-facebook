 DISCLAIMER<br/>
 Use this script at your own risk<br/>
 You, as a user, have no right to support even if implied<br/>
 Carefully read the script and then interpret, modify, correct, fork, disdain, whatever<br/>
<br/>
 This script:<br/>
 1 - crudely blocks all Facebook's IPs obtained from it's known Autonomous System Numbers (ASN) - https://en.wikipedia.org/wiki/Autonomous_system_(Internet)<br/>
 2 - must be run with root privileges<br/>
 3 - needs bgpview.io and riswhois.ripe.net to be online and providing the required information<br/>
 4 - needs curl installed, everything else is probably installed by default, please install if something is missing (whois, perhaps ?)<br/>
 5 - will add iptables rules, blocking Facebook IPs obtained from "public" Facebook's ASNs<br/>
 6 - "should" be run from crontab on every boot; crontab has PATH somewhat limited, so PATH is defined<br/>
 7 - (in my use case) it runs from crontab with "@reboot /full/path/to/block_facebook.sh", so that it always gets fresh Facebook's Ips; check Google for editing crontab<br/>
<br/>
Facebook's ASNs (AFAIK), dated 2018-04-17, obtained from https://bgpview.io/search/facebook<br/>
32934<br/>
54115<br/>
63293
