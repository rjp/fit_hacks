# Garmin FIT bits and bobs

Random things messing about with FIT files.

# Requirements

My modified version of Garmin::FIT

# Hacks

## weight.pl

Report the user's weight in kg from the Settings/*.FIT file.

    perl weight.pl ~/Library/App*port/Garmin/Devices/*/Settings/*.FIT

## linker.pl

Match bikes with ANT+ sensors defined in the Settings FIT file to activities using those sensors.

    perl linker.pl {settings.fit} activity.fit[, activity.fit]
