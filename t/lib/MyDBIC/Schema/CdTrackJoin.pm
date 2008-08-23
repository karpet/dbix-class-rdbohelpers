package MyDBIC::Schema::CdTrackJoin;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ RDBOHelpers Core /);
__PACKAGE__->table('cd_track_join');
__PACKAGE__->add_columns(qw/ trackid cdid /);
__PACKAGE__->set_primary_key(qw/trackid cdid/);
__PACKAGE__->belongs_to( 'cdid'    => 'MyDBIC::Schema::Cd' );
__PACKAGE__->belongs_to( 'trackid' => 'MyDBIC::Schema::Track' );

1;
