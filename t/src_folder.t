#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'PPI', 'src_folder' => 't';

get '/file'   => 'file';

my $t = Test::Mojo->new;
$t->get_ok('/file')
  ->status_is(200)
  ->text_is('span.symbol' => '@world')
  ->element_exists('span.line_number');

done_testing;

__DATA__

@@ file.html.ep
% title 'Inline';
% layout 'basic';
Hello <%= ppi 'test.pl' %>

@@ layouts/basic.html.ep
  <!doctype html><html>
    <head>
      <title><%= title %></title>
    </head>
    <body><%= content %></body>
  </html>
