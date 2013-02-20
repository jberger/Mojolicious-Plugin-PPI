use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

plugin 'PPI';

my $t = Test::Mojo->new;

$t->get_ok('/ppi.css')
  ->status_is(200)
  ->content_like( qr/Simple CSS Styling/ );

$t->get_ok('/ppi.js')
  ->status_is(200)
  ->content_like( qr/Simple Javascript helpers/ );


done_testing;


