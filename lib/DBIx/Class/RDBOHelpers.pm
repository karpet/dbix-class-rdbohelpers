package DBIx::Class::RDBOHelpers;

use warnings;
use strict;
use parent 'DBIx::Class';
use Carp;

#use Data::Dump qw( dump );

our $VERSION = '0.01';

=head1 NAME

DBIx::Class::RDBOHelpers - DBIC compat with Rose::DBx::Object::MoreHelpers

=head1 SYNOPSIS

 package MyDB::Schema::Foo;
 use strict;
 
 use base 'DBIx::Class';
 
 __PACKAGE__->load_components(qw( RDBOHelpers Core ));
 # ... rest of schema setup here
 

=head1 DESCRIPTION

DBIx::Class::RDBOHelpers implements several methods with the same names
as those in Rose::DBx::Object::MoreHelpers. This class helps ease
compatability issues when using packages that expect these methods
to exist, like Rose::HTMLx::Form::Related and CatalystX::CRUD::YUI.
Most of these are convenience wrappers rather than implementing any
new features.

=head1 METHODS
 
=cut

=head2 has_related( I<rel_method_name> )

Returns the number of related objects defined by the I<rel_method_name>
accessor. B<NOTE:> If the relationship is a many-to-many, this must
be the B<many-to-many method name>, not the relationship name.

Just a wrapper around the B<count> method.

Example:

 if (my $group_count = $user->has_related('groups')) {
     printf("user %s has %d related groups\n", 
        $user->name, $group_count);
 }
 else {
     printf("User %s has no related groups\n", 
        $user->name);
 }

=cut

sub has_related {
    my $self = shift;
    my $rel  = shift;
    my $c    = $self->$rel->count;
    return $c;
}

=head2 has_related_pages( I<relationship_name>, I<page_size> )

Returns the number of "pages" given I<page_size> for the count of related
object for I<relationship_name>. Useful for creating pagers.

=cut

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

=head2 primary_key_uri_escaped

Returns the primary key value, URI-escaped. If there are multiple
columns comprising the primary key, they are joined into a single
string.

If there are no values set for any of the column(s) comprising
the primary key, returns 0.

Otherwise, returns all column values joined with C<;;> as per
CatalystX::CRUD::Controller API.

=cut

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

__PACKAGE__->mk_classdata( ___my_m2m_metadata => {} );

=head2 many_to_many( I<accessor_name>, <link_rel_name>, I<foreign_rel_name> [, I<attr>] )

Overrides the base Relationship::ManyToMany method of the same name,
in order to cache the name of the m2m method. Call it
just like you would many_to_many() as documented in DBIx::Class::Relationship.

=cut

sub many_to_many {
    my $class = shift;
    my ( $meth_name, $rel_name, $map_to ) = @_;
    my $store = $class->___my_m2m_metadata;
    croak("many_to_many metadata for $meth_name already exists")
        if exists $store->{$meth_name};

    my $attrs = {
        method_name => $meth_name,
        rel_name    => $rel_name,    # the o2m relationship name
        map_to      => $map_to,      # i.e., foreign class method name
        ( @_ > 3 ? ( attrs => $_[3] ) : () ),    # only store if exists
    };

    # inheritable data workaround
    $class->___my_m2m_metadata( { $rel_name => $attrs, %$store } );

    $class->next::method(@_);
}

=head2 relationship_info( I<rel_name> )

Overrides base method of the same name. Returns hash ref of information
about I<rel_name>, with the addition of a C<m2m> key if I<rel_name>
represents a many-to-many relationship.

=cut

sub relationship_info {
    my $class    = shift;
    my $rel_name = shift;
    my $info     = $class->next::method($rel_name);

    # if this is a m2m relname, construct hash ref of
    # m2m + foreign_relation info
    if ( exists $class->___my_m2m_metadata->{$rel_name} ) {

        # return if we've already set it up.
        return $info if exists $info->{m2m};

        # set up
        my %m2m = %{ $class->___my_m2m_metadata->{$rel_name} };
        $m2m{map_class} = $info->{class};

        # find the missing map_from value
        for my $foreign_rel ( $m2m{map_class}->relationships ) {
            my $foreign_rel_info
                = $m2m{map_class}->relationship_info($foreign_rel);

            if ( $foreign_rel_info->{class} eq $class ) {
                my ( $foreign, $local ) = each %{ $foreign_rel_info->{cond} };
                $foreign =~ s/^foreign\.//;
                $m2m{map_from} = $foreign;
            }
            else {
                $m2m{foreign_class} = $foreign_rel_info->{class};
            }
        }

        # stash it away
        $info->{m2m} = \%m2m;

    }

    return $info;

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

The many_to_many() code is based on DBIx::Class::IntrospectableM2M.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

