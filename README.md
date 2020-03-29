# custom-udev-pa


## Synopsis

Custom set-up for automatically switching to a bluetooth headphone


## Description

I wanted to configure a system to automatically switch to only the bluetooth
headphones when they connect and to switch back to the normal (HDMI, in this
case) sound output when the headphones disconnect. The default behavior in
Ubuntu 18.x's pulseaudio config was not doing this correctly.

The files in this project may be very Ubuntu-, or Debian-specific. I do know I
don't see the same `default.pa` file on Arch Linux.

This project contains notes, files and scripts that are the result of this
work.


## Installation

FIXME `bin` scripts somewhere on the path, preferably `<USER>/bin`

FIXME `.config/pulse/default.pa`

FIXME Write an installation script? Pretty non-destructive, only adds one
"risky" file to `/etc/udev/rules.d`

### Creating udev rules

keywords: udev rules

This info is specifically about trying to figure out a bluetooth headphone's
add/remove events as it's connected and disconnected.

Use `udevadm` to figure out what your devices is

    # udevadm monitor -p
    # udevadm monitor -p -s bluetooth  # Limit to bluetooth subsystem, may be desireable?

Connect your device and look for paths starting with `/devices/...` like this

    /devices/pci0000:00/0000:00:14.0/usb3/3-5/3-5:1.0/bluetooth/hci0/hci0:256

You can then use that path to query info about that hardware if needed

    # udevadm info --path "/devices/pci0000:00/0000:00:14.0/usb3/3-5/3-5:1.0/bluetooth/hci0/hci0:256"

    P: /devices/pci0000:00/0000:00:14.0/usb3/3-5/3-5:1.0/bluetooth/hci0/hci0:256
    E: DEVPATH=/devices/pci0000:00/0000:00:14.0/usb3/3-5/3-5:1.0/bluetooth/hci0/hci0:256
    E: DEVTYPE=link
    E: SUBSYSTEM=bluetooth
    E: SYSTEMD_ALIAS=/sys/subsystem/bluetooth/devices/hci0:256
    E: SYSTEMD_WANTS=bluetooth.target
    E: TAGS=:systemd:
    E: USEC_INITIALIZED=442328156407

FIXME This files exists in this project:

To create rules, make a file like `/etc/udev/rules.d/99-my-device.rules`. It's
usually good to use a high number so other rules will get a crack first.

    99-my-device.rules
    ---
    ACTION=="add", ENV{DEVPATH}=="/devices/pci0000:00/0000:00:14.0/usb3/3-5/3-5:1.0/bluetooth/hci0/hci0:256", RUN+="/bin/su <SOMEUSER> -c '/home/<SOMEUSER>/bin/<SOMESCRIPT> <ARG1>...'"
    ACTION=="remove", ENV{DEVPATH}=="/devices/pci0000:00/0000:00:14.0/usb3/3-5/3-5:1.0/bluetooth/hci0/hci0:256", RUN+="/bin/su <SOMEUSER> -c '/home/<SOMEUSER>/bin/<SOMESCRIPT> <ARG1>...'"
    ---

Should be no need to restart the udev service but this may be necessary after
any changes:

    # udevadm control --reload-rules

I had notes showing `# udevadm trigger` too after the `control --reload-rules`
but I'm not sure this was useful

Once you have added or made changes to the `.rules` file, test to see if your
script is being run

    # udevadm test "/devices/pci0000:00/0000:00:14.0/usb3/3-5/3-5:1.0/bluetooth/hci0/hci0:256"

And look for lines starting with `run: ` which should show your script being
invoked if there are matches.

### pulse audio

keywords: sound pulse audio pulseaudio pa

We'll need to get the device "Name" values for the sinks that pulseaudio has
for your user. These will be used to script things with `pactl`

    $ pactl list sinks | grep -e "Sink " -e "Name" -e "Mute"

This output could be monitored for connection and mute status with watch

    $ watch 'pactl list sinks | grep -e "Sink " -e "Name" -e "Mute"'

To get the default settings for pulseaudio to stop fighting me wrt default
sinks and volume settings, I made a copy of the `defaults.pa` file

    $ cd  # Current user's HOME
    $ mkdir .config/pulse  # Probably already exists
    $ cp /etc/pulse/default.pa .config/pulse

FIXME Can we modify an existing `defaults.pa` file from the local system? Without ansible?

And then made these changes `$ diff .config/pulse/default.pa
/etc/pulse/default.pa`. Note that the `set-default-sink` name is one that we
discovered above with `pactl`.

    25c25
    < # load-module module-stream-restore
    ---
    > load-module module-stream-restore
    33c33
    < # load-module module-switch-on-port-available
    ---
    > load-module module-switch-on-port-available
    36,38c36,38
    < # .ifexists module-switch-on-connect.so
    < # load-module module-switch-on-connect
    < # .endif
    ---
    > .ifexists module-switch-on-connect.so
    > load-module module-switch-on-connect
    > .endif
    146d145
    < set-default-sink alsa_output.pci-0000_01_00.1.hdmi-surround

Commands can then be issued with `pactl` to mute/unmute and set default

    $ # values are: 1 (muted) | 0 | toggle
    $ pactl set-sink-mute alsa_output.pci-0000_01_00.1.hdmi-surround 1
    $ pactl set-sink-mute alsa_output.pci-0000_01_00.1.hdmi-surround 0

    $ # values are: +N% | -N% | N% (absolute)
    $ pactl set-sink-volume alsa_output.pci-0000_01_00.1.hdmi-surround 50%
    $ pactl set-sink-volume alsa_output.pci-0000_01_00.1.hdmi-surround 100%

    $ pactl set-default-sink "bluez_sink.D0_8A_55_A9_58_12.a2dp_sink"

Commands like these can be used in scripts and can be used to respond to udev
hardware events as well.


## Development

Browse [on Github](https://github.com/dino-/custom-udev-pa)


## Contact

### Authors

Dino Morelli <dino@ui3.info>
