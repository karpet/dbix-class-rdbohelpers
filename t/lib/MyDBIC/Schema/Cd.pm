package MyDBIC::Schema::Cd;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ RDBOHelpers Core /);
__PACKAGE__->table('cd');
__PACKAGE__->add_columns(qw/ cdid artist title /);
__PACKAGE__->set_primary_key('cdid');
__PACKAGE__->belongs_to( 'artist' => 'MyDBIC::Schema::Artist' );
__PACKAGE__->has_many(
    'cd_tracks' => 'MyDBIC::Schema::CdTrackJoin',
    'cdid'
);
__PACKAGE__->many_to_many(
    'tracks' => 'cd_tracks',
    'trackid'
);

1;
