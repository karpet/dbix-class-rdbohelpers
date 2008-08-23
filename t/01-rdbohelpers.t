use strict;
use Test::More tests => 22;
use lib 't/lib';
use Data::Dump qw( dump );
use DBICx::TestDatabase;

use_ok('MyDBIC::Schema');

ok( my $cd = MyDBIC::Schema->class('Cd'), "Cd class" );
ok( my $m2m_tracks = $cd->relationship_info('cd_tracks'),
    "get m2m info for cd_tracks" );
ok( exists $m2m_tracks->{m2m}, "cd_tracks is a m2m" );
is_deeply(
    $m2m_tracks,
    {   attrs => {
            accessor       => "multi",
            cascade_copy   => 1,
            cascade_delete => 1,
            join_type      => "LEFT",
        },
        class => "MyDBIC::Schema::CdTrackJoin",
        cond  => { "foreign.cdid" => "self.cdid" },
        m2m   => {
            foreign_class => "MyDBIC::Schema::Track",
            map_class     => "MyDBIC::Schema::CdTrackJoin",
            map_from      => "cdid",
            map_to        => "trackid",
            method_name   => "tracks",
            rel_name      => "cd_tracks",
        },
        source => "MyDBIC::Schema::CdTrackJoin",
    },
    "cd_tracks deep hash structure"
);

ok( my $track = MyDBIC::Schema->class('Track'), "Track class" );
ok( my $m2m_cds = $track->relationship_info('track_cds'), "track_cds" );
ok( exists $m2m_cds->{m2m}, "track_cds is a m2m" );
is_deeply(
    $m2m_cds,
    {   attrs => {
            accessor       => "multi",
            cascade_copy   => 1,
            cascade_delete => 1,
            join_type      => "LEFT",
        },
        class => "MyDBIC::Schema::CdTrackJoin",
        cond  => { "foreign.trackid" => "self.trackid" },
        m2m   => {
            foreign_class => "MyDBIC::Schema::Cd",
            map_class     => "MyDBIC::Schema::CdTrackJoin",
            map_from      => "trackid",
            map_to        => "cdid",
            method_name   => "cds",
            rel_name      => "track_cds",
        },
        source => "MyDBIC::Schema::CdTrackJoin",
    },
    "track_cds deep hash structure"
);

# test some data

ok( my $schema = DBICx::TestDatabase->new('MyDBIC::Schema'),
    "create temp db" );

ok( $schema->resultset('Artist')
        ->create( { artistid => 1, name => "bruce cockburn" } ),
    "create artist 1"
);

ok( $schema->resultset('Cd')
        ->create( { cdid => 1, artist => 1, title => 'best of' } ),
    "create cd 1"
);

ok( $schema->resultset('Cd')
        ->create( { cdid => 2, artist => 1, title => 'sunwheel dance' } ),
    "create cd 2"
);

ok( $schema->resultset('Track')->create(
        {   trackid => 1,
            title   => 'dialogue with the devil'
        }
    ),
    "create track 1"
);

ok( $schema->resultset('Track')->create(
        {   trackid => 2,
            title   => 'goin down slow'
        }
    ),
    "create track 2"
);

ok( $schema->resultset('CdTrackJoin')->create( { cdid => 1, trackid => 2 } ),
    "going down slow on best of"
);
ok( $schema->resultset('CdTrackJoin')->create( { cdid => 2, trackid => 2 } ),
    "going down slow on sunwheel dance"
);
ok( $schema->resultset('CdTrackJoin')->create( { cdid => 2, trackid => 1 } ),
    "dialogue on sunwheel dance"
);

ok( my $cd1 = $schema->resultset('Cd')->find( { cdid => 1 } ), "fetch cd 1" );
is( $cd1->has_related('tracks'), 1, $cd1->title . " has 1 tracks" );
ok( my $cd2 = $schema->resultset('Cd')->find( { cdid => 2 } ), "fetch cd 2" );
is( $cd2->has_related('tracks'), 2, $cd2->title . " has 2 tracks" );
