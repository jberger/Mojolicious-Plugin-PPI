package Mojolicious::Plugin::PPI;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util;
use Mojo::ByteStream 'b';

use File::Basename ();
use File::Spec;
use File::ShareDir ();

use PPI::HTML;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

has 'id' => 1;
has 'line_numbers'  => 1;
has 'no_check_file' => 0;
has 'ppi_html_on'  => sub { PPI::HTML->new( line_numbers => 1 ) };
has 'ppi_html_off' => sub { PPI::HTML->new( line_numbers => 0 ) };
has 'src_folder';

has style => <<'END';
.ppi-code { 
  display: inline-block;
  min-width: 400px;
  background-color: #F8F8F8;
  border-radius: 10px;
  padding: 15px;
}

pre.ppi-code br {
  display: none;
}
END

has class_style => sub {{
  line_number_on   => { display => 'inline' },
  line_number_off  => { display => 'none'   },

  cast => '#339999',
  comment => '#008080',
  core => '#FF0000',
  double => '#999999',
  heredoc_content => '#FF0000',
  interpolate => '#999999',
  keyword => '#BD2E2A',
  line_number => '#666666',
  literal => '#999999',
  magic => '#0099FF',
  match => '#9900FF',
  number => '#990000',
  operator => '#DD7700',
  pod => '#008080',
  pragma => '#A33AF7',
  regex => '#9900FF',
  single => '#FF33FF',
  substitute => '#9900FF',
  symbol => '#389A7D',
  transliterate => '#9900FF',
  word => '#999999',
}};

sub register {
  my ($plugin, $app) = (shift, shift);
  $plugin->initialize($app, @_);

  push @{$app->static->classes},   __PACKAGE__;
  push @{$app->renderer->classes}, __PACKAGE__;

  $app->helper( ppi => sub {
    return $plugin if @_ == 1;
    return $plugin->convert(@_); 
  });
  $app->helper( ppi_css => sub { $_[0]->ppi->generate_css(@_) } );
}

sub initialize {
  my ($plugin, $app, $args) = @_;

  if ( my $src_folder = delete $args->{src_folder} ) {
    $plugin->src_folder( $src_folder );     
  }

  if ( keys %$args ) {
    warn "Unknown option(s): " . join(", ", keys %$args) . "\n";
  }
}

sub convert {
  my $plugin = shift;
  my $c = shift;

  my %opts = (
    inline => 0,
    line_numbers => $plugin->line_numbers,
  );

  %opts = ( %opts, $plugin->process_converter_opts(@_) );

  my $converter = 
    $opts{line_numbers}
    ? $plugin->ppi_html_on
    : $plugin->ppi_html_off;

  my $id = $plugin->generate_id($c);

  my @tag = (
    $opts{inline} ? 'code' : 'pre',
    id    => $id,
    class => 'ppi-code ' . ($opts{inline} ? 'ppi-inline' : 'ppi-block'),
  );

  if ($opts{line_numbers}) {
    push @tag, ondblclick => "ppi_toggleLineNumbers($id)";
    $c->stash('ppi.js.required' => 1);
  }

  my %render_opts = (
    partial    => 1,
    'ppi.code' => $converter->html( $opts{file} ? $opts{file} : \$opts{string} ),
    'ppi.tag'  => \@tag,
  );

  return $c->render('ppi_template', %render_opts);
}

sub generate_id {
  my ($plugin, $c) = @_;
  return 'ppi' . $c->stash->{'ppi.id'}++;
}

sub check_file {
  my ($self, $file) = @_;
  return undef if $self->no_check_file;

  if ( my $folder = $self->src_folder ) {
    die "Could not find folder $folder\n" unless -d $folder;
    $file = File::Spec->catfile( $folder, $file );
  }

  return -e $file ? $file : undef;
}

sub process_converter_opts {
  my $plugin = shift;

  my $string = do {
    no warnings 'uninitialized';
    if (ref $_[-1] eq 'CODE') {
      Mojo::Util::trim pop->();
    }
  };

  my %opts;
  if (ref $_[-1]) {
    %opts = %{ pop() };
  }

  if ( @_ % 2 ) { 
    die "Cannot specify both a string and a block\n" if $string;

    $string = shift;
    $opts{file} = $plugin->check_file($string);
    unless ( $opts{file} ) {
      $opts{inline} //= 1;                #/# fix highlight
    }

  }

  %opts = (%opts, @_) if @_;

  $opts{string} = $string unless defined $opts{file};

  return %opts;
}

sub generate_css {
  my ($plugin, $c) = @_;
  my $sheet = b($plugin->style."\n");
  my $cs = $plugin->class_style;
  foreach my $key (sort keys %$cs) {
    my $value = $cs->{$key};
    $value = { color => $value } unless ref $value;
    $$sheet .= ".ppi-code .$key { ";
    foreach my $prop ( sort keys %$value ) {
      $$sheet .= "$prop: $value->{$prop}; ";
    }
    $$sheet .= "}\n";
  }
  return $c->stylesheet(sub{$sheet});
}

1;

__DATA__

@@ ppi_template.html.ep

% if ( stash('ppi.js.required') and not stash('ppi.js.added') ) {
  %= javascript '/ppi_js.js'
  % stash('ppi.js.added' => 1);
% }

<%= tag @{stash('ppi.tag')} => begin =%>
  <%== stash('ppi.code') =%>
<% end %>

@@ ppi_js.js

function ppi_toggleLineNumbers(id) {
  var spans = document.getElementById(id).getElementsByTagName("span");
  for (i = 0; i < spans.length; i++){
    var span = spans[i];
    
    if ( span.className.indexOf('line_number') == -1 ) {
      continue;
    }

    var cl = span.className.split(' ');
    var index_on  = cl.indexOf('line_number_on');
    var index_off = cl.indexOf('line_number_off');

    if (index_on != -1) {
      cl.splice(index_on, 1);
    }
    if (index_off != -1) {
      cl.splice(index_off, 1);
    }

    if ( index_off == -1 ) {
      cl.push('line_number_off');
    } else {
      cl.push('line_number_on');
    }

    span.className = cl.join(' ');
  }
}


__END__

=head1 NAME

Mojolicious::Plugin::PPI - Mojolicious Plugin for Rendering Perl Code Using PPI

=head1 SYNOPSIS

 # Mojolicious
 $self->plugin('PPI');

 # Mojolicious::Lite
 plugin 'PPI';

 # In your template
 Perl is as simple as <%= ppi q{say "Hello World"} %>.

=head1 DESCRIPTION

L<Mojolicious::Plugin::PPI> is a L<Mojolicious> plugin which adds Perl syntax highlighting via L<PPI> and L<PPI::HTML>. Perl is notoriously hard to properly syntax highlight, but since L<PPI> is made especially for parsing Perl this plugin can help you show off your Perl scripts in your L<Mojolicious> webapp.

=head1 METHODS

L<Mojolicious::Plugin::PPI> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register plugin in L<Mojolicious> application. A register time, several options may be supplied:

=over

=item *

C<< toggle_button => [0/1] >> specifies whether a "Toggle Line Numbers" button (see below) will be created by default. Default is false.

=item *

C<< src_folder => 'directory' >> specifies a folder where input files will be found. When specified, if the directory is not found, a warning is issued, but not fatally. This functionality is not (currently) available for per-file alteration, so only use if all files will be in this folder (or subfolder). Remeber, if this option is not specified, a full or relative path may be passed to L</ppi>. 

=back

=head1 HELPERS

L<Mojolicous::Plugin::PPI> provides these helpers:

=head2 C<ppi>

  %== ppi 'my $code = "highlighted";'
  %== ppi 'file.pl'

Returns HTML form of Perl snippet or file. The behavior may be slightly different in each case. If the argument is the name of a file that exists, it will be loaded and used. If not the string will be interpreted as an inline snippet. In either form, the call to C<ppi> may take the additional option:

=over

=item *

C<< line_numbers => [0/1] >> specifies if line numbers should be generated

=back

In the case of a file, the contents are placed in a C<< <div> >> tag, and there are several additional options

=over

=item *

C<< id => 'string' >> specifies the C<id> to be given to the encompassing C<< <div> >> tag

=item *

C<< toggle_button => [0/1] >> specifies if a button should be created to toggle the line numbers. If given C<line_numbers> will be forced and if not specified an C<id> will be generated. The C<onClick> handler is C<toggleLineNumbers> from the C<ppi_js> javascript library. C<toggle_button> may also be specified at register time to set the default.

=back

=head2 C<ppi_plugin>

Holds the active instance of L<Mojolicious::Plugin::PPI>.

=head1 STATIC FILES

These bundled files are added to your static files paths.

=head2 C</ppi.js>

 %= javascript '/ppi.js'

Returns a Javascript snippet useful when using L<Mojolicious::Plugin::PPI>.

=head2 C</ppi.css>

 %= stylesheet '/ppi.css'

Returns a CSS snippet for coloring the L<PPI::HTML> generated HTML. Also provides a background for the code blocks.

=head1 SEE ALSO

L<Mojolicious>, L<PPI>, L<PPI::HTML>

L<PPI>, L<PPI::HTML>

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-PPI>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
