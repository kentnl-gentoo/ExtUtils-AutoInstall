# $File: //depot/cpan/Module-Install/lib/Module/Install/Base.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 1263 $ $DateTime: 2003/03/06 02:37:29 $ vim: expandtab shiftwidth=4

package Module::Install::Base;

sub new {
    my ($class, %args) = @_;

    foreach my $method (qw(call load)) {
        *{"$class\::$method"} = sub {
            +shift->_top->$method(@_);
        } unless defined &{"$class\::$method"};
    }

    bless(\%args, $class);
}

sub initialized {
    my $self = shift;
    !($self->_top->admin) or $self->_top->admin->initialized;
}

sub AUTOLOAD {
    my $self = shift;
    goto &{$self->_top->autoload};
}

sub _top { $_[0]->{_top} }

sub admin {
    my $self = shift;
    return Module::Install::Base::FakeAdmin->new if $self->initialized;
    $self->_top->admin;
}

sub DESTROY {}

package Module::Install::Base::FakeAdmin;

my $Fake;
sub new { $Fake ||= bless(\@_, $_[0]) }
sub AUTOLOAD {}
sub DESTROY {}

1;
