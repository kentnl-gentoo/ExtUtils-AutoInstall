# $File: //depot/cpan/Module-Install/lib/Module/Install/Metadata.pm $ $Author: autrijus $
# $Revision: #11 $ $Change: 1291 $ $DateTime: 2003/03/07 08:56:07 $ vim: expandtab shiftwidth=4

package Module::Install::Metadata;
use base 'Module::Install::Base';

$VERSION = '0.01';

use strict 'vars';
use vars qw($VERSION);

sub Meta { shift }

foreach my $key (qw(name version abstract author license)) {
    *$key = sub {
        my $self = shift;
        return $self->{values}{$key} unless @_;
        $self->{values}{$key} = shift;
        return $self;
    };
}

foreach my $key (qw(build_requires requires recommends)) {
    *$key = sub {
        my ($self, $module, $version) = (@_, 0, 0);
        return $self->{values}{$key} unless $module;
        my $rv = [$module, $version];
        push @{$self->{values}{$key}}, $rv;
        return $rv;
    };
}

sub features {
    my $self = shift;
    while (my ($name, $mods) = splice(@_, 0, 2)) {
        push @{$self->{values}{features}}, ($name => [map { ref($_) ? @$_ : $_ } @$mods] );
    }
    return @{$self->{values}{features}};
}

sub _dump {
    my $self = shift;
    my $package = ref($self->_top);
    my $version = $self->_top->VERSION;
    return <<"END";
name: $self->{values}{name}
version: $self->{values}{version}
abstract: $self->{values}{abstract}
author: $self->{values}{author}
license: $self->{values}{license}
build_requires: ${\ join '', map "\n  $_->[0]: $_->[1]", @{$self->{values}{build_requires}}}
requires: ${\ join '', map "\n  $_->[0]: $_->[1]", @{$self->{values}{requires}}}
recommends: ${\ join '', map "\n  $_->[0]: $_->[1]", @{$self->{values}{recommends}}}
generated_by: $package version $version
END
}

sub write {
    my $self = shift;
    return $self
      if $self->initialized;
    return if -f "META.yml";
    warn "Creating META.yml\n";
    open META, "> META.yml" or die $!;
    print META $self->_dump;
    close META;
    return $self;
}

sub version_from {
    my ($self, $version_from) = @_;
    require ExtUtils::MM_Unix;
    $self->version(ExtUtils::MM_Unix->parse_version($version_from));
}

1;
