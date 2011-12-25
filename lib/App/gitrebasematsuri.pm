package App::gitrebasematsuri;
use 5.008009;
use strict;
use warnings;
use Getopt::Long qw/GetOptions :config bundling/;
#use Getopt::Long;
use File::Temp qw/tempdir tempfile/;
use Log::Minimal;
use Pod::Usage;

our $VERSION = '0.02';

sub new {
    my ($class) = @_;
    my $self = bless +{
        _NO_LOG => 0,
    }, $class;

    $self->{_TEMPDIR}     = tempdir( CLEANUP => 1 );
    $self->{_FILE_STDERR} = ( tempfile( DIR => $self->{_TEMPDIR} ) )[1];

    return $self;
}

sub run {
    my ($self, @args) = @_;
    local @ARGV = @args;
    GetOptions (
        'git=s'     => \$self->{_GIT},
        'c|conf=s'  => \$self->{conf_file},
        'doit'      => \$self->{doit},
        'V|version' => \$self->{show_version},
    );
    $self->{_GIT} ||= '/usr/bin/env git';

    # adjust output of Log::Minimal
    local $Log::Minimal::PRINT = sub {
        my ( $time, $type, $message, $trace ) = @_;
        for my $m ( split /\\n/, $message ) {
            my $line = "$time [$type] $m";
            $line .= " $trace"  if $type =~ /^(ERROR|CRITICAL)$/;
            $line .= "\n";
            print $line;
        }
    };

    # show version
    if ( $self->{show_version} ) {
        $self->show_version();
        return 0;
    }

    $self->{conf_file} or $self->show_help();

    # config
    my $conf = $self->parse_config( $self->_slurp( $self->{conf_file} ) );

    # only "--doit" option is specified
    if ( $self->{doit} ) {
        # store current branch/commit
        my $current_branch = $self->current_branch();
        infof 'current branch/commit: %s', $current_branch  unless $self->{_NO_LOG};

        for my $r ( @{ $conf->{rebase_rules} || [] } ) {
            $self->exec_rebase( $r->{from}, $r->{onto} );
        }

        # back to $current_branch
        {
            my ($stdout, $stderr) = $self->_exec_cmd( "$self->{_GIT} checkout $current_branch" );
            infof $stdout  if $stdout  &&  ! $self->{_NO_LOG};
            warnf $stderr  if $stderr  &&  ! $self->{_NO_LOG};
        };
    }
    else {
        warnf 'Do you really rebase? specify "--doit" option.'  unless $self->{_NO_LOG};;
    }

    return 0;

}

sub show_version {
    printf "git-rebase-matsuri (App::gitrebasematsuri) $VERSION\n";
}

sub show_help {
    pod2usage();
}

sub parse_config {
    my $self = shift;
    chomp( my $text = shift || '' );
    my $conf = +{};

    my @rebase_rules;
    my $prev_rebased;

    for my $l ( split /\n/, $text ) {
        next  if $l =~ /^\s*$/;
        next  if $l =~ /^\s*\#/;

        my ($from, $onto) = split /[\-\=]>/, $l;
        unless ( defined $from  &&  defined $onto ) {
            croakf 'invalid format: %s', $l;
        }
        $from =~ s/(^\s*|\s*$)//g;  # trim
        $onto =~ s/(^\s*|\s*$)//g;  # trim

        if ( $onto eq '^' ) {
            defined $prev_rebased  or  croakf( 'invalid "^" usage. previous rule is required: %s', $l );
            $onto = $prev_rebased;
        }

        push @rebase_rules, +{ from => $from, onto => $onto };
        infof 'rebase rule has been added: %s -> %s', $from, $onto  unless $self->{_NO_LOG};

        $prev_rebased = $from;
    }
    $conf->{rebase_rules} = \@rebase_rules;

    return $conf;
}

sub parse_config_file {
    my ($self, $f) = @_;
    my $conf = +{};
    infof( 'config file: %s', $f );
    croakf( 'config file does not exist: %s', $! )  unless -f $f;

    my @rebase_rules;
    my $prev_rebased;

    open my $fh, '<', $f  or  croakf( 'could not open config file: %s', $! );
    while ( my $l = <$fh> ) {
        chomp $l;

        next  if $l =~ /^\s*$/;
        next  if $l =~ /^\s*\#/;

        my ($from, $onto) = split /[\-\=]>/, $l;
        unless ( defined $from  &&  defined $onto ) {
            close $fh;
            croakf 'invalid format: %s', $l;
        }
        $from =~ s/(^\s*|\s*$)//g;  # trim
        $onto =~ s/(^\s*|\s*$)//g;  # trim

        if ( $onto eq '^' ) {
            defined $prev_rebased  or  croakf( 'invalid "^" usage. previous rule is required: %s', $l );
            $onto = $prev_rebased;
        }

        push @rebase_rules, +{ from => $from, onto => $onto };
        infof 'rebase rule has been added: %s -> %s', $from, $onto;

        $prev_rebased = $from;
    }
    close $fh;

    $conf->{rebase_rules} = \@rebase_rules;

    return $conf;
}

sub current_branch {
    my ($self) = @_;
    my $ret;
    my $GIT = $self->{_GIT};
    my $stdout = $self->_exec_cmd( "$GIT status -sb | head -n 1" );
    ($ret) = $stdout =~ /\#\# +(.+)$/;

    if ( $ret eq 'HEAD (no branch)' ) {
        $stdout = $self->_exec_cmd( "$GIT show --pretty=oneline HEAD | head -n 1" );
        ($ret) = $stdout =~ /^(\S{40})/;
    }

    return $ret;
}

sub exec_rebase {
    my ($self, $from, $onto) = @_;
    my ($stdout, $stderr);
    my $GIT = $self->{_GIT};

    ($stdout, $stderr) = $self->_exec_cmd( "$GIT checkout $from" );
    infof $stdout  if $stdout  &&  ! $self->{_NO_LOG};
    warnf $stderr  if $stderr  &&  ! $self->{_NO_LOG};;

    ($stdout, $stderr) = $self->_exec_cmd( "$GIT rebase $onto" );
    infof $stdout  if $stdout  &&  ! $self->{_NO_LOG};;
    warnf $stderr  if $stderr  &&  ! $self->{_NO_LOG};;
}

sub _slurp {
    my ($self, $f) = @_;
    open my $fh, '<', $f  or  die "$f: $!";
    do { local $/; <$fh> };
}

sub _exec_cmd {
    my ($self, $cmd) = @_;
    my ($stdout, $stderr);
    chomp( $stdout = `$cmd 2> $self->{_FILE_STDERR}` );
    chomp( $stderr = $self->_slurp( $self->{_FILE_STDERR} ) );
    return wantarray ? ($stdout, $stderr) : $stdout;
}


1;
__END__

=head1 NAME

App::gitrebasematsuri -

=head1 SYNOPSIS

  use App::gitrebasematsuri;

=head1 DESCRIPTION

App::gitrebasematsuri is

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
