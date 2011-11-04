#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 10;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'PPI', 'toggle_button' => 1;

get '/file'   => 'file';
get '/toggle' => 'toggle';

my $t = Test::Mojo->new;
$t->get_ok('/file')->status_is(200)->content_like(qr'@world')->content_like(qr'span class="line_number"')->content_unlike(qr'onClick');
$t->get_ok('/toggle')->status_is(200)->content_like(qr'@world')->content_like(qr'span class="line_number"')->content_like(qr'onClick');

#print STDERR $t->tx->res->to_string;

__DATA__

@@ file.html.ep
% title 'Inline';
% layout 'basic';
Hello <%== ppi 't/test.pl', toggle_button => 0 %>

@@ toggle.html.ep
% title 'Inline';
% layout 'basic';
Hello <%== ppi 't/test.pl' %>

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
