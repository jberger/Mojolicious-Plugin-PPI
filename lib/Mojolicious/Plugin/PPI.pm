package Mojolicious::Plugin::PPI;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream;
use Mojo::Util qw/trim/;

use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;

use PPI::HTML;

our $VERSION = '0.02';

has 'ppi' => sub { PPI::HTML->new( line_numbers => 1 ) };
has 'toggle_button' => 0;
has 'src_folder' => '';
has 'id' => 1;

sub register {
  my ($plugin, $app, $args) = @_;
  $plugin->_process_init_opts($app, $args);

  push @{$app->static->paths}, catdir(dirname(__FILE__), 'PPI', 'public');

  $app->helper( 
    ppi => sub {
      my $c = shift;
      my %opts = $plugin->_process_helper_opts(@_);

      $opts{inline} ||= 0;
      my $outer_type = $opts{inline} ? 'span' : 'div';

      $opts{toggle_button} //= $plugin->toggle_button;               #/# highlight fix
      if ( $opts{inline} ) {
        $opts{toggle_button} = 0;
      }

      if ( $opts{toggle_button} ) {
        ## a hide button will require a div id, so make one if not specified
        $opts{id} //= $plugin->_generate_id;              #/# highlight fix
        ## override if toggle_button is to be used
        $opts{line_numbers} = 1;
      }

      $plugin->ppi->{line_numbers} = $opts{line_numbers} //= ! $opts{inline};     #/# highlight fix

      my $return = qq[<$outer_type class="code"] . (defined $opts{id} ? " id=\"$opts{id}\"" : '') . '>' ;

      if ( $opts{file} ) {
        $return .= $plugin->ppi->html( $opts{file} );
      } else {             
        $return .= $plugin->ppi->html( \$opts{string} );
      }

      if ($opts{toggle_button}) {
        $return .= 
          qq[\n<br><input type="submit" value="Toggle Line Numbers" onClick="toggleLineNumbers('$opts{id}')" />];
      }
      $return .= "</$outer_type>";

      return Mojo::ByteStream->new($return);
    }
  );
}

sub _process_init_opts {
  my ($plugin, $app, $args) = @_;

  if (exists $args->{toggle_button}) {
    $plugin->toggle_button( delete $args->{toggle_button} );
  }

  if ( my $src_folder = delete $args->{src_folder} ) {
    warn "Could not find folder $src_folder\n" unless (-d $src_folder);
    $plugin->src_folder( $src_folder );     
  }

  if ( keys %$args ) {
    warn "Unknown option(s): " . join(", ", keys %$args) . "\n";
  }
}

sub _process_helper_opts {
  my $plugin = shift;

  my $string;
  {
    no warnings 'uninitialized';
    if (ref $_[-1] eq 'CODE') {
      $string = trim pop->();
    }
  }

  my %opts;
  if (ref $_[-1]) {
    %opts = %{ pop() };
  }

  if ( @_ % 2 ) { 
    if ( $string ) {
      warn "Both a string and a block were provided, using the block\n";
    } else {
      $string = shift;
      my $filename = $plugin->src_folder ? catfile( $plugin->src_folder, $string ) : $string;
      if ( -e $filename ) {
        $opts{file} = $filename;
      } else {
        $opts{inline} //= 1;                #/# fix highlight
      }
    }
  }

  if ( @_ ) {
    %opts = (%opts, @_);
  }

  $opts{string} = $string unless defined $opts{file};

  return %opts;
}

sub _generate_id {
  my $plugin = shift;
  my $id = $plugin->id;

  #create the next id, roll over at 10000
  $plugin->id( ($id + 1) % 10000 );
  return "ppi$id";
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

=head1 DESCRIPTION

L<Mojolicious::Plugin::PPI> is a L<Mojolicious> plugin.

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

C<< src_folder => 'directory' >> specifies a folder where input files will be found. When specified, if the directory is not found, a warning is issued, but not fatally. This functionality is not (currently) available for per-file alteration, so only use if all files will be in this folder (or subfolder). Remeber, if this option is not specified, a full or relative path may be passed to C<ppi>. 

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

=head2 C<ppi_js>

Returns a Javascript snippet useful when using L<Mojolicious::Plugin::PPI>.

=head2 C<ppi_css>

Returns a CSS snippet for coloring the L<PPI::HTML> generated HTML. Also provides a background for the code blocks.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

L<PPI>, L<PPI::HTML>

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-PPI>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
