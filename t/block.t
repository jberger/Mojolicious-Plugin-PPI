#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 5;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'PPI';

get '/block' => 'block';

my $t = Test::Mojo->new;
$t->get_ok('/block')
  ->status_is(200)
  ->element_exists( 'div.code' )
  ->text_is('span.symbol' => '@world')
  ->element_exists('span.line_number');

__DATA__

@@ block.html.ep
% title 'Inline';
% layout 'basic';
Hello
%= ppi begin
  @world
%= end

@@ layouts/basic.html.ep
  <!doctype html><html>
    <head>
      <title><%= title %></title>
      %= javascript 'ppi.js'
      %= stylesheet 'ppi.css'
    </head>
    <body><%= content %></body>
  </html>
