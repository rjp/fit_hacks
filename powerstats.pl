#! /usr/bin/perl -s
use Data::Dumper;
use Garmin::FIT;

my $version = "0.01";

sub powerstats {
    my ($self, $desc, $v) = @_;
    my $h = $desc->{'_hashified'};
    my $avg_power = $h->{"avg_power"};
    my $normalized_power = $h->{"normalized_power"};
    my $max_power = $h->{"max_power"};
    my $st = $self->to_time($h->{start_time});
    my $vi = ($avg_power > 0) ? $normalized_power / $avg_power : 65535;
    my $dur = $h->{total_elapsed_time}/1000;
    my $dist = $h->{total_distance}/100;
    print "$st,$avg_power,$normalized_power,$vi,$max_power,$dur,$dist\n";
}

sub fetch_from {
  my $fn = shift;
  my $obj = new Garmin::FIT;
  $obj->auto_hashify(1);

  $obj->semicircles_to_degree($semicircles_to_deg);
  $obj->mps_to_kph($mps_to_kph);
  $obj->use_gmtime($use_gmtime);
  $obj->file($fn);
  $obj->data_message_callback_by_num(18, \&powerstats);

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

  # printf "File size: %lu, protocol version: %u.%02u, profile_verion: %u.%02u\n", $fsize, $proto_major, $proto_minor, $prof_major, $prof_minor;

  if (0 and $h_extra ne '') {
    print "Extra octets in file header";

    my ($i, $n);

    for ($i = 0, $n = length($h_extra) ; $i < $n ; ++$i) {
      print "\n  " if !($i % 16);
      print ' ' if !($i % 4);
      printf " %02x", ord(substr($h_extra, $i, 1));
    }

    print "\n";
  }

  if (defined $h_crc_calculated) {
      # printf "File header CRC: expected=0x%04X, calculated=0x%04X\n", $h_crc_expected, $h_crc_calculated;
  }

  1 while $obj->fetch;

  #print STDERR $obj->error, "\n" if !$obj->EOF;
  #printf "CRC: expected=0x%04X, calculated=0x%04X\n", $obj->crc_expected, $obj->crc;

  my $garbage_size = $obj->trailing_garbages;

  print "Trainling $garbage_size octets garbages skipped\n" if $garbage_size > 0;
  $obj->close;
}

do {
    &fetch_from(shift @ARGV);
} while (@ARGV);
