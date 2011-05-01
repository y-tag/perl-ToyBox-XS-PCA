package ToyBox::XS::PCA;

use 5.0080;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('ToyBox::XS::PCA', $VERSION);

sub add_instance {
    my ($self, %params) = @_;

    die "No params: attributes" unless defined($params{attributes});
    my $attributes = $params{attributes};
    die "attributes is not hash ref"   unless ref($attributes) eq 'HASH';
    die "attributes is empty hash ref" unless keys %$attributes;

    my %copy_attr = %$attributes;

    $self->xs_add_instance(\%copy_attr);
    1;
}

sub pca{
    my ($self, %params) = @_;

    $self->xs_pca();
    1;
}

sub transform {
    my ($self, %params) = @_;

    die "No params: attributes" unless defined($params{attributes});
    my $attributes = $params{attributes};
    die "attributes is not hash ref"   unless ref($attributes) eq 'HASH';
    die "attributes is empty hash ref" unless keys %$attributes;

    my $result = $self->xs_transform($attributes);

    $result;
}

sub get_eigen_values {
    my ($self, %params) = @_;
    my $values = $self->xs_get_eigen_values();
    $values;
}

sub get_eigen_vectors {
    my ($self, %params) = @_;
    my $vectors = $self->xs_get_eigen_vectors();
    $vectors;
}

sub get_eigen {
    my ($self, %params) = @_;
    my $values = $self->xs_get_eigen_values();
    my $vectors = $self->xs_get_eigen_vectors();

    my $sum = 0;
    for my $value (@$values) {
        $sum += $value;
    }

    my $eigen = [];
    for (my $i = 0; $i < @$values; $i++) {
        my $tmp = {};
        $tmp->{value} = $values->[$i];
        $tmp->{vector} = $vectors->[$i];
        $tmp->{ratio} = $values->[$i] / $sum;
        push @$eigen, $tmp;
    }
    
    $eigen;
}


1;
__END__
=head1 NAME

ToyBox::XS::PCA - Simple Principal Component Analysis using GSL

=head1 SYNOPSIS

  use ToyBox::XS::PCA;

  my $pca = ToyBox::XS::PCA->new();
  
  $pca->add_instance(attributes => {a => 32, b => 26, c => 51, d => 12});
  $pca->add_instance(attributes => {a => 17, b => 13, c => 34, d => 35});
  $pca->add_instance(attributes => {a => 10, b => 94, c => 83, d => 45});
  $pca->add_instance(attributes => {a => 3,  b => 72, c => 72, d => 67});
  $pca->add_instance(attributes => {a => 10, b => 63, c => 35, d => 34});
  
  $pca->pca();
  
  my $eigen = $pca->get_eigen();
  my $result = $pca->transform(attributes => {a => 32, b => 26, c => 51, d => 12});

=head1 DESCRIPTION

This module implements a simple Principal Component Analysis using Gnu Scientific Library. Because of naive implementation, it might work for only small data set.

=head1 AUTHOR

TAGAMI Yukihiro <tagami.yukihiro@gmail.com>

=head1 LICENSE

This software is distributed under the term of the GNU General Public License.

L<http://opensource.org/licenses/gpl-license.php>
