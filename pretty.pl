#!/usr/bin/env perl
use 5.10.1;
use strict;
use warnings;
use JSON::MaybeXS;

local $/ = undef;
my $in = <STDIN>;
my $json = JSON::MaybeXS->new(utf8 => 0, pretty => 1, canonical => 1);
say $json->encode($json->decode($in));
