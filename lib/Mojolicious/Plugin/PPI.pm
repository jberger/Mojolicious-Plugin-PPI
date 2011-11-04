package Mojolicious::Plugin::PPI;
use Mojo::Base 'Mojolicious::Plugin';

use Time::HiRes 'gettimeofday';
use File::Spec::Functions 'catfile';

use PPI::HTML;

our $VERSION = '0.02';

my $ppi = PPI::HTML->new( line_numbers => 1 );

sub register {
  my ($self, $app, $args) = @_;

  my $default_toggle_button = $args->{toggle_button} || 0;

  my $src_folder = $args->{src_folder} || '';
  if ( $src_folder ) {
    warn "Could not find folder $src_folder\n" unless (-d $src_folder);
  }

  $app->helper( 
    ppi => sub {
      my $c = shift;
      my $input = shift;
      my %opts = ref $_[0] ? %{ $_[0] } : @_;

      my $filename = $src_folder ? catfile( $src_folder, $input ) : $input;

      my $return;
      if ( -e $filename ) {
        ## if the input is the filename of an existing file

        $opts{toggle_button} //= $default_toggle_button;               #/# highlight fix

        if ( $opts{toggle_button} ) {
          ## a hide button will require a div id, so make one if not specified
          $opts{id} //= 'ppi' . join('', gettimeofday());              #/# highlight fix
          ## override if toggle_button is to be used
          $opts{line_numbers} = 1;
        }

        $ppi->{line_numbers} = $opts{line_numbers} // 1;               #/# highlight fix
        $return .= '<div class="code"' . (defined $opts{id} ? " id=\"$opts{id}\"" : '') . '>' ;
        $return .= $ppi->html( $filename );
        if ($opts{toggle_button}) {
          $return .= qq[\n<br><input type="submit" value="Toggle Line Numbers" onClick="toggleLineNumbers('$opts{id}')" />];
        }
        $return .= '</div>';

      } else {
        ## if not, then treat as an inline snippet
        ## do not use line numbers on inline snippets
        $ppi->{line_numbers} = $opts{line_numbers} // 0;               #/# highlight fix
        $return = $ppi->html( \$input );
      }

      return $return;
    }
  );

  $app->helper( ppi_js => sub { return <<'JS'; } );
function toggleLineNumbers(id) {
  var spans = document.getElementById(id).getElementsByTagName("span");
  var span;
  for (i = 0; i < spans.length; i++){
    span = spans[i];
    if(span.className=='line_number'){
      if (span.style.display!="none") {
        span.style.display = "none";
      } else {
        span.style.display = "inline";
      }
    }
  }
}
JS

  $app->helper( ppi_css => sub { return <<'CSS' } );
.code { 
  display: inline-block;
  min-width: 400px;
  background-color: #F8F8F8;
  border-radius: 10px;
  padding: 15px;
}

.cast { color: #339999 ;}
.comment { color: #008080 ;}
.core { color: #FF0000 ;}
.double { color: #999999 ;}
.heredoc_content { color: #FF0000 ;}
.interpolate { color: #999999 ;}
.keyword { color: #BD2E2A ;}
.line_number { color: #666666 ;}
.literal { color: #999999 ;}
.magic { color: #0099FF ;}
.match { color: #9900FF ;}
.number { color: #990000 ;}
.operator { color: #DD7700 ;}
.pod { color: #008080 ;}
.pragma { color: #A33AF7 ;}
.regex { color: #9900FF ;}
.single { color: #999999 ;}
.substitute { color: #9900FF ;}
.symbol { color: #389A7D ;}
.transliterate { color: #9900FF ;}
.word { color: #999999 ;}
CSS

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
