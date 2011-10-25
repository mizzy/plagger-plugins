package Plagger::Plugin::CustomFeed::AmazonECS;

use strict;
use base qw( Plagger::Plugin );
use Net::Amazon::ECS;
use Net::Amazon::ECS::Request::Keyword;
use Encode;
use Plagger::Event;

sub register {
    my ( $self, $context ) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my ( $self, $context ) = @_;
    my $feed = Plagger::Feed->new;
    $feed->aggregator(sub { $self->aggregate(@_) });
    $context->subscription->add($feed);
}

sub aggregate {
    my ( $self, $context, $args ) = @_;

    my $feed = Plagger::Feed->new;
    $feed->type('AmazonWebService');

    my $title = $self->conf->{title} || 'Amazon Web Service';
    $feed->title($title);

    my $attr;
    $attr->{access_key_id}     = $self->conf->{access_key_id};
    $attr->{secret_access_key} = $self->conf->{secret_access_key};
    $attr->{locale}            = $self->conf->{locale} || 'jp';
    $attr->{associate_tag}     = $self->conf->{associate_tag};

    my $search_index = $self->conf->{search_index} || 'books';
    my $sort         = $self->conf->{sort} || 'daterank';

    for my $keyword (@{$self->conf->{keywords}}) {
        my $items = search_aws($context, $attr, $keyword, $search_index, $sort);
        next unless $items;

        for my $item ( @$items ) {
            my $entry = Plagger::Entry->new;
            $entry->title($item->title . ' - ' . $item->author);
            $entry->body($item->editorial_review->{content});
            $entry->link($item->url);
            $entry->icon({ url => $item->small_image_url });
            $entry->author($item->author);

            my $date = Plagger::Date->strptime('%Y-%m-%d', $item->publication_date);
            $date = Plagger::Date->strptime('%Y-%m', $item->publication_date) unless $date;
            unless($date){
                $context->log(error => 'Date format of ' . $item->title .' is invalid: ' . $item->publication_date);
                next;
            }
            $date->set_time_zone( $context->conf->{timezone} || 'local' );
            $entry->date($date);

            $feed->add_entry($entry);
        }
    }

    $context->update->add($feed);
}

sub search_aws {
    my ( $context, $attr, $keyword, $search_index, $sort ) = @_;

    my $ua = Net::Amazon::ECS->new(%$attr);

    my $req = Net::Amazon::ECS::Request::Keyword->new(
        keywords     => $keyword,
        search_index => $search_index,
        sort         => $sort,
    );

    my $response = $ua->request($req);

    if($response->is_error) {
        $context->log(error => $response->message . ": $keyword");
        return;
    }

    return $response->items;
}

*Net::Amazon::ECS::Item::Music::author = *Net::Amazon::ECS::Item::Music::artist;
*Net::Amazon::ECS::Item::DVD::author   = sub { };
*Net::Amazon::ECS::Item::Music::publication_date = *Net::Amazon::ECS::Item::Music::release_date;
*Net::Amazon::ECS::Item::DVD::publication_date = *Net::Amazon::ECS::Item::DVD::release_date;


1;
__END__

=head1 NAME

Plagger::Plugin::CustomFeed::AmazonWebService - Amazon Web Service Custom Feed

=head1 SYNOPSIS

  - module: CustomFeed::AmazonWebService
    config:
      developer_token: XXXXXXXXXXXXXXXXXXXX
      associate_id: xxxxxxxxxx-22
      keywords:
        - Tom Cruise
        - Jonny Depp
      mode: dvd
      sort: salesrank
      locale: jp

=head1 DESCRIPTION

This plugin makes custom feeds from Amazon Web Service.

=head1 CONFIG

=over 6

=item access_key_id

Your Amazo Web Service developer token.

=item associcate_tag

Your Amazon associate ID.

=item search_index

Set search mode.Default value is books.

=item sort

Set search results sort order.Default value is daterank.
See L<Net::Amazon::Request::Sort> for more details.

=item locale

Set the web service locale.Default value is jp.

=back

=head1 SEE ALSO

This plugin is originally made by id:wata_d .
See http://d.hatena.ne.jp/wata_d/20060821 .

L<Plagger>, L<Net::Amazon>

=head1 AUTHOR

Gosuke Miyashita

=cut
