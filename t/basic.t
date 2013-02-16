#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'PPI';

get '/inline' => 'inline';
get '/file'   => 'file';
get '/toggle' => 'toggle';

my $t = Test::Mojo->new;
$t->get_ok('/inline')
  ->status_is(200)
  ->element_exists( 'span.ppi-code' )
  ->text_is('span.symbol' => '@world')
  ->element_exists_not('span.line_number')
  ->element_exists(".ppi-code[id=ppi1]");

$t->get_ok('/file')
  ->status_is(200)
  ->element_exists( 'pre.ppi-code' )
  ->text_is('span.symbol' => '@world')
  ->element_exists('span.line_number')
  ->element_exists_not('input')
  ->element_exists(".ppi-code[id=ppi2]");

$t->get_ok('/toggle')
  ->status_is(200)
  ->element_exists( 'pre.ppi-code' )
  ->text_is('span.symbol' => '@world')
  ->element_exists('span.line_number')
  ->element_exists('input')
  ->element_exists(".ppi-code[id=ppi3]");

$t->get_ok('/toggle')
  ->status_is(200)
  ->element_exists( 'pre.ppi-code' )
  ->text_is('span.symbol' => '@world')
  ->element_exists('span.line_number')
  ->element_exists('input')
  ->element_exists(".ppi-code[id=ppi4]");

done_testing;

__DATA__

@@ inline.html.ep
% title 'Inline';
% layout 'basic';
Hello <%= ppi '@world' %>

@@ file.html.ep
% title 'Inline';
% layout 'basic';
Hello <%= ppi 't/test.pl' %>

@@ toggle.html.ep
% title 'Inline';
% layout 'basic';
Hello <%= ppi 't/test.pl', toggle_button => 1 %>

@@ layouts/basic.html.ep
  <!doctype html><html>
    <head>
      <title><%= title %></title>
      %= javascript 'ppi.js'
      %= stylesheet 'ppi.css'
    </head>
    <body><%= content %></body>
  </html>
