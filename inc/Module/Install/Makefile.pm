# $File: //depot/cpan/Module-Install/lib/Module/Install/Makefile.pm $ $Author: autrijus $
# $Revision: #35 $ $Change: 1344 $ $DateTime: 2003/03/10 00:10:02 $ vim: expandtab shiftwidth=4

package Module::Install::Makefile;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

$VERSION = '0.01';

use strict 'vars';
use vars '$VERSION';

use ExtUtils::MakeMaker ();

sub Makefile { $_[0] }

sub prompt { 
    shift;
    goto &ExtUtils::MakeMaker::prompt;
}

sub makemaker_args {
    my $self = shift;
    my $args = ($self->{makemaker_args} ||= {});
    %$args = ( %$args, @_ ) if @_;
    $args;
}

sub clean_files {
    my $self = shift;
    $self->makemaker_args( clean => { FILES => "@_ " } );
}

sub write {
    my $self = shift;
    die "&Makefile->write() takes no arguments\n" if @_;

    my $args = $self->makemaker_args;

    $args->{NAME} = $self->name || $self->determine_NAME($args);
    $args->{VERSION} = $self->version;

    if ($] >= 5.005) {
	$args->{ABSTRACT} = $self->abstract;
	$args->{AUTHOR} = $self->author;
    }

    # merge both kinds of requires into prereq_pm
    my $prereq = ($args->{PREREQ_PM} ||= {});
    %$prereq = ( %$prereq, map @$_, @{$self->$_} )
        for grep $self->$_, qw(requires build_requires);

    # merge both kinds of requires into prereq_pm
    my $dir = ($args->{DIR} ||= []);
    push @$dir, map "$self->{prefix}/$self->{bundle}/$_->[1]", @{$self->bundles}
        if $self->bundles;

    $self->admin->update_manifest;

    my %args = map {($_ => $args->{$_})} grep {defined($args->{$_})} keys %$args;
    ExtUtils::MakeMaker::WriteMakefile(%args);

    $self->fix_up_makefile();
}

sub fix_up_makefile {
    my $self = shift;
    my $top_class = ref($self->_top);
    my $top_version = $self->_top->VERSION;

    local *MAKEFILE;

    if ($self->preamble) {
        open MAKEFILE, '< Makefile' or die $!;
        my $makefile = do { local $/; <MAKEFILE> };
        close MAKEFILE;
        open MAKEFILE, '> Makefile' or die $!;
        print MAKEFILE "# Preamble by $top_class $top_version\n", $self->preamble;
        print MAKEFILE $makefile;
        close MAKEFILE;
    }

    open MAKEFILE, '>> Makefile' or die $!;
    print MAKEFILE "# Postamble by $top_class $top_version\n", $self->postamble;
    close MAKEFILE;
}

sub preamble {
    my ($self, $text) = @_;
    $self->{preamble} = $text . $self->{preamble} if defined $text;
    $self->{preamble};
}

sub postamble {
    my ($self, $text) = @_;
    my $class = ref($self);
    my $top_class = ref($self->_top);
    my $admin_class = join('::', @{$self->_top}{qw(name dispatch)});

    $self->{postamble} ||= << "END";
# --- $class section:

realclean purge ::
\t\$(RM_F) \$(DISTVNAME).tar\$(SUFFIX)

reset :: purge
\t\$(RM_RF) inc
\t\$(PERL) -M$admin_class -e \"reset_manifest()\"
\t\$(PERL) -M$admin_class -e \"remove_meta()\"

upload :: test dist
\tcpan-upload -verbose \$(DISTVNAME).tar\$(SUFFIX)

grok ::
\tperldoc $top_class

distsign ::
\tcpansign -s

END
    $self->{postamble} .= $text if defined $text;
    $self->{postamble};
}

1;

__END__

