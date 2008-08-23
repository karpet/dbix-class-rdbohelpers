package DBIx::Class::RDBOHelpers;

use warnings;
use strict;

use parent 'DBIx::Class';

use Carp;
use Data::Dump qw( dump );

__PACKAGE__->load_components(qw( IntrospectableM2M ));

our $VERSION = '0.01';

=head1 NAME

DBIx::Class::RDBOHelpers - DBIC compat with Rose::DBx::Object::MoreHelpers

=head1 SYNOPSIS

 # TODO
 
=cut

sub has_related {
    my $self = shift;
    my $rel  = shift;
    my $c    = $self->$rel->count;
    return $c;
}

sub has_related_pages {
    my $self   = shift;
    my $rel    = shift or croak "need Relationship name";
    my $pgsize = shift or croak "need page_size";
    if ( $pgsize =~ m/\D/ ) {
        croak "page_size must be an integer";
    }
    my $n = $self->has_related($rel);
    return 0 if !$n;
    if ( $n % $pgsize ) {
        return int( $n / $pgsize ) + 1;
    }
    else {
        return $n / $pgsize;
    }
}

sub primary_key_uri_escaped {
    my $self = shift;
    my $val  = $self->primary_key_value;
    my @vals = ref $val ? @$val : ($val);
    my @esc;
    for my $v (@vals) {
        $v = '' unless defined $v;
        $v =~ s/;/ sprintf( "%%%02X", ';' ) /eg;
        push @esc, $v;
    }
    if ( !grep { length($_) } @esc ) {
        return 0;
    }
    my $pk = join( ';;', @esc );
    return $pk;
}

=head2 primary_key_value

Returns the value of the primary key column(s). If the
value is comprised of multiple column values, the return
value will be an array ref of values, otherwise it will
be a simple scalar.

=cut

sub primary_key_value {
    my $self = shift;
    my @vals = map { $self->$_ } $self->primary_columns;
    return scalar(@vals) > 1 ? \@vals : $vals[0];
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbix-class-rdbohelpers at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-RDBOHelpers>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::RDBOHelpers

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-RDBOHelpers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-RDBOHelpers>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-RDBOHelpers>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-RDBOHelpers>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

