# $File: //depot/cpan/Module-Install/lib/Module/Install.pm $ $Author: autrijus $
# $Revision: #32 $ $Change: 1290 $ $DateTime: 2003/03/07 08:55:15 $ vim: expandtab shiftwidth=4

package Module::Install;
$VERSION = '0.20';

use strict 'vars';
use File::Find;

unshift @INC, 'inc';
@inc::Module::Install::ISA = 'Module::Install';

sub import {
    my $class = $_[0];
    my $self = $class->new(@_[1..$#_]);

    if (!-f $self->{file}) {
        $self->admin->init;
        goto &{"$self->{name}::import"};
    }

    *{caller(0) . "::AUTOLOAD"} = $self->autoload;
}

sub autoload {
    my $self = shift;
    my $auto_ref = \${caller(0) . "::AUTOLOAD"};
    sub {
        $$auto_ref =~ /([^:]+)$/ or die "Cannot load $$auto_ref";
        unshift @_, ($self, $1);
        goto &{$self->can('call')} unless uc($1) eq $1;
    };
}

sub new {
    my ($class, %args) = @_;

    $args{dispatch} ||= 'Admin';
    $args{prefix}   ||= 'inc';

    $class =~ s/^\Q$args{prefix}\E:://;
    $args{name}     ||= $class;
    $args{version}  ||= $class->VERSION,
    ($args{path}      = $args{name}) =~ s!::!/!g unless $args{path};
    $args{file}     ||= "$args{prefix}/$args{path}.pm";

    bless(\%args, $class);
}

sub admin {
    my $self = shift;
    eval { require "$self->{path}/$self->{dispatch}.pm"; 1 } or return;
    $self->{admin} ||= "$self->{name}::$self->{dispatch}"->new(_top => $self);
}

sub call {
    my ($self, $method) = (+shift, +shift);
    my $obj = $self->load($method) or return;

    unshift @_, $obj;
    goto &{$obj->can($method)};
}

sub load {
    my ($self, $method) = @_;

    $self->load_extensions(
        "$self->{prefix}/$self->{path}", $self
    ) unless $self->{extensions};

    foreach my $obj (@{$self->{extensions}}) {
        return $obj if $obj->can($method);
    }

    my $admin = $self->admin
        or die "Cannot load $self->{dispatch} for $self->{name}:\n$@";

    my $obj = $admin->load($method, 1);
    push @{$self->{extensions}}, $obj;

    $obj;
}

sub load_extensions {
    my ($self, $basepath, $top) = @_;

    foreach my $rv ($self->find_extensions($basepath)) {
        my ($pathname, $pkg) = @{$rv};
        next if $self->{pathnames}{$pkg};
        $self->{pathnames}{$pkg} = $pathname;

        do $pathname; if ($@) { warn $@; next }
        push @{$self->{extensions}}, $pkg->new( _top => $top );
    }
}

sub find_extensions {
    my ($self, $basepath) = @_;
    my @found;

    find(sub {
        my $name = $File::Find::name;
        return unless $name =~ m!^\Q$basepath\E/(.+)\.pm\Z!is;
        return if $1 eq $self->{dispatch};

        my $pkg = "$self->{name}::$1"; $pkg =~ s!/!::!g;
        push @found, [$name, $pkg];
    }, $basepath);

    @found;
}

1;

__END__

