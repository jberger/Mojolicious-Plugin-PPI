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
% title 'A Mojolicious "Quine"';
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    %= javascript 'ppi.js'
    %= stylesheet 'ppi.css'
  </head>
  <body>
    <h2><%= title %></h2>
    %= ppi $file
  </body>
</html>
