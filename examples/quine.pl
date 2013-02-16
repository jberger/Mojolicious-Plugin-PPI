#!/usr/bin/env perl

use Mojolicious::Lite;
use lib 'lib';

plugin 'PPI' => { toggle_button => 1 };
get '/' => sub {
  my $self = shift;
  $self->stash( file => __FILE__ );
  $self->render('quine');
};

app->start;

__DATA__

@@ quine.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>A Mojolicious Quine</title>
    %= javascript 'ppi.js'
    %= stylesheet 'ppi.css'
  </head>
  <body>
    <%= ppi $file %>
  </body>
</html>
