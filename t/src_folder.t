#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 5;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'PPI', 'src_folder' => 't';

get '/file'   => 'file';

my $t = Test::Mojo->new;
$t->get_ok('/file')->status_is(200)->content_like(qr'@world')->content_like(qr'span class="line_number"')->content_unlike(qr'onClick');

done_testing;

#print STDERR $t->tx->res->to_string;

__DATA__

@@ file.html.ep
% title 'Inline';
% layout 'basic';
Hello <%== ppi 'test.pl' %>

@@ layouts/basic.html.ep
  <!doctype html><html>
    <head>
      <title><%= title %></title>
      %= javascript begin 
        %== ppi_js
      %= end
      %= stylesheet begin
        %== ppi_css
      %= end
    </head>
    <body><%= content %></body>
  </html>
