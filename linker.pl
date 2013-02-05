#! /usr/bin/perl -s

use Garmin::FIT;

my $settings = shift @ARGV;

my $version = "0.01";

my $bikes = {};
my $ant_ids = {};

sub fs {
    my ($obj, $desc, $v, $key) = @_;
    return $obj->string_value($v, $desc->{"i_$key"}, $desc->{"c_$key"});
}

sub fit_bike_profile {
  my ($self, $desc, $v) = @_;
    my $h = $desc->{'_hashified'};

        my $name = fs($self, $desc, $v, 'name');
        foreach my $i (grep {/_ant_id$/} keys %{$h}) {
            (my $j = $i) =~ s/^.*_(.+)_ant_id/$1_enabled/;
            if ($h->{$j}) {
                $bikes->{$name}->{$i} = $h->{$i};
                $ant_ids->{$h->{$i}}->{$name} = 1;
            }
        }
        $bikes->{$name}->{name} = $name;

  return 1;
}

my $thisbike = {};

# Create our list of bikes and ANT+ sensors from Settings/*.FIT
&fetch_from($settings, { 6 => \&fit_bike_profile });

foreach my $activity (@ARGV) {
    $thisbike = {};

    # We only need device_info (23) blocks to match our sensors
    &fetch_from($activity, { 23 => \&fit_device_info });

    my @bikes = keys %{$thisbike};

    # Only one match => PERFECT
    if (scalar @bikes == 1) {
        print "M,$bikes[0],$activity\n";
    }
    # No matches => SAD FACE
    elsif (scalar @bikes == 0) {
        print "N,,$activity\n";
    }
    # Multiple matches => sensor probably moved from one bike to another
    # List them all and let the user sort it out
    else {
        print "A,",join('|',@bikes),",$activity\n";
    }
}

sub fit_device_info {
  my ($self, $desc, $v) = @_;
  my $h = $desc->{'_hashified'};

    # ANT ID seems to be the lower 16 bits of serial_number
    my $ant_id = $h->{serial_number} % 65536;
    # Is this ID linked to any bike?
    if (my $bike = $ant_ids->{$ant_id}) {
        foreach my $i (keys %{$bike}) {
            $thisbike->{$i} = 1;
        }
    }

    return 1;
}

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
