#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 14;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'PPI';

get '/inline' => 'inline';
get '/file'   => 'file';
get '/toggle' => 'toggle';

my $t = Test::Mojo->new;
$t->get_ok('/inline')->status_is(200)->content_like(qr'@world')->content_unlike(qr'span class="line_number"');
$t->get_ok('/file')->status_is(200)->content_like(qr'@world')->content_like(qr'span class="line_number"')->content_unlike(qr'onClick');
$t->get_ok('/toggle')->status_is(200)->content_like(qr'@world')->content_like(qr'span class="line_number"')->content_like(qr'onClick');

#print STDERR $t->tx->res->to_string;

__DATA__

@@ inline.html.ep
% title 'Inline';
% layout 'basic';
Hello <%== ppi '@world' %>

@@ file.html.ep
% title 'Inline';
% layout 'basic';
Hello <%== ppi 't/test.pl' %>

@@ toggle.html.ep
% title 'Inline';
% layout 'basic';
Hello <%== ppi 't/test.pl', toggle_button => 1 %>

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
