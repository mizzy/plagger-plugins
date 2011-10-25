package Plagger::Rule::Ahead;
use strict;
use base qw( Plagger::Rule );

sub init {
    my $self = shift;

    my $duration = $self->{duration} || 1440; # minutes

    if ($duration =~ /^\d+$/) {
        # if it's all digit, the unit is minutes
        $self->{duration} =  $duration * 60;
    }
    else {
        eval { require Time::Duration::Parse };
        if ($@) {
            Plagger->context->error("You need to install Time::Duration::Parse to use human readable timespec");
        }

        $self->{duration} = Time::Duration::Parse::parse_duration($self->{duration});
    }

    $self->{now}  = DateTime->now( time_zone => Plagger->context->conf->{timezone} || 'local' );
    $self->{then} = $self->{now}->clone->add( seconds => $self->{duration} );
}

sub id {
    my $self = shift;
    return 'ahead';
}

sub dispatch {
    my($self, $args) = @_;

    my $date;
    if ( my $entry = $args->{entry} ) {
        $date = $entry->date;
    }
    #elsif ($args->{feed}) {
    #    $date = $args->{feed}->updated;
    #}
    else {
        Plagger->context->error("No entry nor feed object in this plugin phase");
    }

    $date ? ( $self->{now} < $date and $date < $self->{then} ) : 1;
}

1;

__END__

=head1 NAME

Plagger::Rule::Ahead - Rule to find entries which events will occur within specified minutes ahead.

=head1 SYNOPSIS

  # entries which events will occur within a day.
  - module: Filter::Rule
    rule:
      module: Ahead
      duration: 1440

=head1 DESCRIPTION

This rule finds etnries which events will occur within specified duration, which means event dtstart or
updated date is newer than now and within C<duration> minutes ahead. It defaults to a day, but you'd better
configure the value with your cronjob interval.

=head1 CONFIG

=over 1

=item C<duration>

  duration: 5

This rule matches with events that will occur within 5 minutes.

If entries don't have events, check entry->date instead of entry->event->dtstart.

If the supplied value contains only digit, it's parsed as minutes. You
can write in a human readable format like:

  duration: 4 hours

and this module DWIMs. It defaults to I<1440>, which means a day.

=back

=head1 AUTHOR

Gosuke Miyashita

=head1 SEE ALSO

L<Plagger>, L<Time::Duration>

=cut
