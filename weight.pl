#! /usr/bin/perl -s

use Garmin::FIT;

# we need the Settings/*.FIT file
my $settings = shift @ARGV;

my $version = "0.01";

# All we're interested in is the user_profile block
sub user_profile {
    my ($self, $desc, $v) = @_;
    my $h = $desc->{'_hashified'};
    # "decigrams"? "decagrams"?
    print $h->{'weight'}/10;
    return 1;
}

# Read our FIT file and pass the user_profile to be decoded
&fetch_from($settings, { 3 => \&user_profile });

# Stock fetch_from, cargoculted from fitdump
# TODO trim this down and/or move it to Garmin::FIT itself
sub fetch_from {
  my $fn = shift;
  my $callback = shift || \&dump_it;
  my $obj = new Garmin::FIT;

  $obj->semicircles_to_degree($semicircles_to_deg);
  $obj->mps_to_kph($mps_to_kph);
  $obj->use_gmtime($use_gmtime);
  $obj->file($fn);
  $obj->auto_hashify(1);

  if (ref $callback eq 'HASH') {
      while (my ($k, $v) = each %{$callback}) {
        $obj->data_message_callback_by_num($k, $v);
    }
  }

  unless ($obj->open) {
    print STDERR $obj->error, "\n";
    return;
  }

  my ($fsize, $proto_ver, $prof_ver, $h_extra, $h_crc_expected, $h_crc_calculated) = $obj->fetch_header;

  unless (defined $fsize) {
    print STDERR $obj->error, "\n";
    $obj->close;
    return;
  }

  my ($proto_major, $proto_minor) = $obj->protocol_version_major($proto_ver);
  my ($prof_major, $prof_minor) = $obj->profile_version_major($prof_ver);

  1 while $obj->fetch;

  $obj->close;
}
