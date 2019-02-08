#!/usr/bin/perl
## Presence's Raspberry Pi Firewall Generator
## Use my abuseipdb API key and the general spamhaus shitlist to keep my RPi safer
## 20190208
##  notes:
##   list the ipset group in iptables:
## iptables --line-numbers --list PREROUTING -t raw
##   delete the ipset group:
## iptables -t raw -D PREROUTING 1
##   flush the ipset entirely:
## ipset x
use strict;
use warnings;
use POSIX qw/strftime/;

our $key;
require "/root/ipfw-firewall/api-key.pl"; # which is just:  our $key="asdf";

my $today = strftime('%Y%m%d',localtime);

my $list = `curl -s -G https://api.abuseipdb.com/api/v2/blacklist -d countMinimum=15 -d maxAgeInDays=60 -d confidenceMinimum=90 -d plaintext -H "Key: $key" -H "Accept: text/plain"`;
open(my $fh, '>', "/root/ipfw-firewall/firewall-blacklist-$today.txt");
my @lines = split /\n/, $list;
foreach my $line (@lines) {
	chomp $line;
	$line =~ s/;.*//;
	$line =~ s/^\s+|\s+$//g;
	next if (length($line) < 4);
	if ($line !~ m/\/\d/) {
		$line =~ s/$/\/32/;
	}
	print ($fh "$line\n");
}
close $fh;

$list = `curl -s http://www.spamhaus.org/drop/drop.lasso`;
open($fh, '>>', "/root/ipfw-firewall/firewall-blacklist-$today.txt");
@lines = split /\n/, $list;
foreach my $line (@lines) {
	chomp $line;
	$line =~ s/;.*//;
	$line =~ s/^\s+|\s+$//g;
	next if (length($line) < 4);
	if ($line !~ m/\/\d/) {
		$line =~ s/$/\/32/;
	}
	print ($fh "$line\n");
}
close $fh;

`ipset -exist -N badips hash:net`;
`ipset flush badips`;
open($fh, '<', "/root/ipfw-firewall/firewall-blacklist-$today.txt");
while (my $ip = <$fh>) {
	chomp $ip;
	if ($ip =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2})/) {
		`ipset -A badips "$ip"`;
	} else {
		print "Some weird stuff in the firewall list $today: $ip\n";
	}
}
close $fh;
`iptables -t raw -I PREROUTING -m set --match-set badips src,dst -j DROP`;

