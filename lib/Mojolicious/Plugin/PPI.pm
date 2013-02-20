package Mojolicious::Plugin::PPI;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util;

use File::Basename ();
use File::Spec;
use File::ShareDir ();

use PPI::HTML;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

has 'id' => 1;
has 'line_numbers'  => 1;
has 'no_check_file' => 0;
has 'ppi_html' => sub { PPI::HTML->new( line_numbers => 1 ) };
has 'src_folder';

has 'static_path' => sub {
  my $local = File::Spec->catdir(File::Basename::dirname(__FILE__), 'PPI', 'public');
  return $local if -d $local;

  my $share = File::ShareDir::dist_dir('Mojolicious-Plugin-PPI');
  return $share if -d $share;

  warn "Cannot find static content for Mojolicious::Plugin::PPI, (checked $local and $share). The bundled javascript and css files will not work correctly.\n";
};

has 'template' => <<'TEMPLATE';
% my @tag = $opts->{inline} ? 'span' : 'pre';
% push @tag, class => 'ppi-code';
% push @tag, id => $opts->{id} if $opts->{id};
%= tag @tag, begin
%== $pod
% end
  % if ( $opts->{toggle_button} ) {
    <br>
    %= submit_button 'Toggle Line Numbers', class => 'ppi-toggle', onClick => "toggleLineNumbers('$opts->{id}')"
  % }
TEMPLATE

has 'toggle_button' => 0;

sub register {
  my ($plugin, $app) = (shift, shift);
  $plugin->initialize($app, @_);

  push @{$app->static->paths}, $plugin->static_path;

  $app->helper( ppi_plugin => sub { $plugin } );
  $app->helper( ppi => sub { $_[0]->ppi_plugin->ppi(@_) } );
}

sub initialize {
  my ($plugin, $app, $args) = @_;

  if (exists $args->{toggle_button}) {
    $plugin->toggle_button( delete $args->{toggle_button} );
  }

  if ( my $src_folder = delete $args->{src_folder} ) {
    $plugin->src_folder( $src_folder );     
  }

  if ( keys %$args ) {
    warn "Unknown option(s): " . join(", ", keys %$args) . "\n";
  }
}

sub ppi {
  my $plugin = shift;
  my $c = shift;

  my %opts = (
    id => $plugin->_generate_id,
    inline => 0,
    line_numbers => $plugin->line_numbers,
    toggle_button => $plugin->toggle_button,
  );

  %opts = ( %opts, $plugin->_process_helper_opts(@_) );

  if ( $opts{inline} ) {
    $opts{line_numbers}  = 0;
    $opts{toggle_button} = 0;
  }

  $opts{line_numbers} = 1 if $opts{toggle_button};

  $plugin->ppi_html->{line_numbers} = $opts{line_numbers};
  my $pod = $plugin->ppi_html->html( $opts{file} ? $opts{file} : \$opts{string} );

  my $return = $c->render( 
    partial => 1, 
    inline  => $plugin->template,
    opts    => \%opts,
    pod     => $pod,
  );

  return $return;
}

sub _check_file {
  my ($self, $file) = @_;
  return undef if $self->no_check_file;

  if ( my $folder = $self->src_folder ) {
    die "Could not find folder $folder\n" unless -d $folder;
    $file = File::Spec->catfile( $folder, $file );
  }

  return -e $file ? $file : undef;
}

sub _generate_id {
  my $plugin = shift;
  my $id = $plugin->id;
  $plugin->id( ($id + 1) % 10000 );
  return "ppi$id";
}

sub _process_helper_opts {
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
    $opts{file} = $plugin->_check_file($string);
    unless ( $opts{file} ) {
      $opts{inline} //= 1;                #/# fix highlight
    }

  }

  %opts = (%opts, @_) if @_;

  $opts{string} = $string unless defined $opts{file};

  return %opts;
}

1;

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
