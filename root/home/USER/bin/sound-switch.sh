#! /bin/bash


# Set these to the sinks specific to your system

# This the "main" sound device
hdmiSinkName="alsa_output.pci-0000_01_00.1.hdmi-surround"

# On my system, this is present too but we never want it to make any noise! I
# think it's the Intel onboard audio.
stereoSinkName="alsa_output.pci-0000_00_1b.0.iec958-stereo"

headphoneSinkName="bluez_sink.D0_8A_55_A9_58_12.a2dp_sink"


basename=$(basename "$0")

function usage {
  cat <<USAGE
$basename - Control the sound device

usage:
  $basename [OPTIONS] PROFILE

options:
  -h, --help  This help information

Valid PROFILE values are: headphones | soundbar

v1.0  2020-03-22  Dino Morelli <dino@ui3.info>

USAGE
}


# arg parsing

getoptResults=$(getopt -o h --long help -n "$basename" -- "$@") \
  || { usage; exit 1; }

# Note the quotes around "$getoptResults": they are essential!
eval set -- "$getoptResults"

optHelp=false

while true ; do
  case "$1" in
    -h|--help) optHelp=true; shift;;
    --) shift; break;;
  esac
done

# echo "detail of arguments"
# echo "optHelp: $optHelp"
# echo "muteValue: $muteValue"
# echo "number of remaining parameters: $#"
# echo "remaining parameters: $*"
# echo
# exit 0  # FIXME

$optHelp && { usage; exit 0; }

if [ $# -lt 1 ]
then
  echo "PROFILE is required"
  usage
  exit 1
fi

sleep 1

muteValue="$1"

case "$muteValue" in
   headphones)
      pactl set-sink-mute "$hdmiSinkName" 1
      pactl set-sink-mute "$stereoSinkName" 1
      pactl set-default-sink "$headphoneSinkName"
      ;;
   soundbar)
      pactl set-sink-mute "$hdmiSinkName" 0
      pactl set-sink-mute "$stereoSinkName" 1
      pactl set-default-sink "$hdmiSinkName"
      ;;
   *)
      echo "PROFILE unrecognized"
      usage
      exit 1
esac
