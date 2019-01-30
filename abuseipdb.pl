#!/usr/local/bin/perl
## Presence's iRev Firewall Generator
## Use my abuseipdb API key and the general spamhaus shitlist to keep iRev Seattle safer
## 20190130
use strict;
use warnings;
use POSIX qw/strftime/;

our $key;
require "/root/firewall/api-key.pl"; # which is just:  our $key="asdf";

my $today = strftime('%Y%m%d',localtime);

my $list = `curl -s -G https://api.abuseipdb.com/api/v2/blacklist -d countMinimum=15 -d maxAgeInDays=60 -d confidenceMinimum=90 -d plaintext -H "Key: $key" -H "Accept: text/plain"`;
open(my $fh, '>', "/root/firewall/firewall-blacklist-$today.txt");
my @lines = split /\n/, $list;
foreach my $line (@lines) {
	chomp $line;
	$line =~ s/;.*//;
	next if (length($line) < 4);
	if ($line !~ m/\/\d/) {
		$line =~ s/$/\/32/;
	}
	print ($fh "$line\n");
}
close $fh;

$list = `curl -s http://www.spamhaus.org/drop/drop.lasso`;
open($fh, '>>', "/root/firewall/firewall-blacklist-$today.txt");
@lines = split /\n/, $list;
foreach my $line (@lines) {
	chomp $line;
	$line =~ s/;.*//;
	next if (length($line) < 4);
	if ($line !~ m/\/\d/) {
		$line =~ s/$/\/32/;
	}
	print ($fh "$line\n");
}
close $fh;

`ipfw table 2 flush`;
open($fh, '<', "/root/firewall/firewall-blacklist-$today.txt");
while (my $ip = <$fh>) {
	chomp $ip;
	if ($ip =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2})/) {
		`ipfw table 2 add $ip`;
	} else {
		print "Some weird stuff in the firewall list $today: $ip\n";
	}
}
close $fh;
