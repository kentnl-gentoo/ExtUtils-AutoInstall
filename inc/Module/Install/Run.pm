# $File: //depot/cpan/Module-Install/lib/Module/Install/Run.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1289 $ $DateTime: 2003/03/07 08:25:20 $ vim: expandtab shiftwidth=4

package Module::Install::Run;
use base 'Module::Install::Base';

$VERSION = '0.01';

# check if we can run some command
sub can_run {
    my ($self, $command) = @_;

    # absolute pathname?
    require ExtUtils::MakeMaker;
    return $command if (-x $command or $command = MM->maybe_command($command));

    require Config;
    return unless defined $Config::Config{path_sep};

    for my $dir (split /$Config::Config{path_sep}/, $ENV{PATH}) {
        my $abs = File::Spec->catfile($dir, $command);
        return $abs if (-x $abs or $abs = MM->maybe_command($abs));
    }

    return;
}

sub can_cc {
    my $self = shift;
    require Config;
    my $cc = $Config::Config{cc} or return;
    $self->can_run($cc);
}

1;
