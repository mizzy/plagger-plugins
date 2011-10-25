package Plagger::Event;

use strict;

use base qw( Plagger::Thing );
__PACKAGE__->mk_accessors(qw( dtstart dtend summary description location organizer ));

1;
