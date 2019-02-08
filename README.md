# Presence's Firewall Generator

Use my abuseipdb API key and the general spamhaus shitlist to keep my servers a little safer

FreeBSD & IPFW
Raspberry Pi, ipchains, and ipset

20190208

Crontab on FreeBSD: 

> 28 2,14 * * * /root/firewall/abuseipdb.pl

Crontab on Raspbian:

> 28 6 * * * /root/ipfw-firewall/abuseipdb-ipchains.pl
