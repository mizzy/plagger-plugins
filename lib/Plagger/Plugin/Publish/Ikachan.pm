package Plagger::Plugin::Publish::Ikachan;
use strict;
use warnings;
use base qw ( Plagger::Plugin );
use LWP::UserAgent;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => \&entry,
    );
}

sub entry {
    my($self, $context, $args) = @_;

    my $host     = $self->conf->{host};
    my $port     = $self->conf->{port};
    my $channels = $self->conf->{channels};

    my $ua = LWP::UserAgent->new;

    for my $channel ( @$channels ) {
        $ua->post("http://$host:$port/join", {
            channel => $channel,
        });

        # $ua->post("http://$host:$port/notice", {
        #     channel => $channel,
        #     message => $args->{entry}->title,
        # });

        $ua->post("http://$host:$port/notice", {
            channel => $channel,
            message => $args->{entry}->body_text,
        });

        $ua->post("http://$host:$port/notice", {
            channel => $channel,
            message => $args->{entry}->link,
        });
    }
}


1;
