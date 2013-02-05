# Garmin FIT bits and bobs

Random things messing about with FIT files.

# Requirements

My modified version of Garmin::FIT

# Hacks

## weight.pl

Report the user's weight in kg. Useful for ANT+ enabled scales (Tanita BC-1000, etc.)

    weight.pl {settings.fit}

## linker.pl

Match bikes with ANT+ sensors defined in the Settings FIT file to activities using those sensors.

    linker.pl {settings.fit} activity.fit[, activity.fit]

## powerstats.pl

Print out power summary stats (AvgW, NP, VI, MaxW)

    powerstats.pl activity.fit [activity.fit, ...]
