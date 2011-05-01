#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use lib qw(lib blib/lib blib/arch);
use ToyBox::XS::PCA;

my $pca = ToyBox::XS::PCA->new();

$pca->add_instance(attributes => {a => 32, b => 26, c => 51, d => 12});
$pca->add_instance(attributes => {a => 17, b => 13, c => 34, d => 35});
$pca->add_instance(attributes => {a => 10, b => 94, c => 83, d => 45});
$pca->add_instance(attributes => {a => 3,  b => 72, c => 72, d => 67});
$pca->add_instance(attributes => {a => 10, b => 63, c => 35, d => 34});

$pca->pca();

my $eigen = $pca->get_eigen();
print Dumper($eigen);

my $result = $pca->transform(attributes => {a => 32, b => 26, c => 51, d => 12});
print Dumper($result);

$result = $pca->transform(attributes => {a => 17, b => 13, c => 34, d => 35});
print Dumper($result);
