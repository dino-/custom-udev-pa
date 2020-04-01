# custom-udev-pa


## Synopsis

Configuration for automatically switching between speakers and bluetooth
headphones on Ubuntu or similar distros


## Description

I wanted to configure a system to automatically use only the bluetooth
headphones when they connect and to switch back to the normal (HDMI, in this
case) sound output when the headphones disconnect. The default behavior in
Ubuntu 18.x's pulseaudio config was not doing this correctly.

The files in this project may be very Ubuntu-, or Debian-specific. I do know I
don't see the same `default.pa` file on Arch Linux.

My solution for this involves customizations in both udev rules and pulseaudio
configuration. This project contains notes, files and scripts that are the
result of this work.


## Installation

There are two parts to this: 1) Creating udev rules to perform actions in
response to bluetooth add/remove events for the headphones. 2) Configuring
pulse audio for the user and the script for switching audio.

### 1) Creating udev rules for the bluetooth headphone

Use `udevadm` to figure out what your device is

    # udevadm monitor -p
    # udevadm monitor -p -s bluetooth  # Limit to the bluetooth subsystem

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

Copy the file in this project `root/etc/udev/rules.d/99-my-device.rules` into
`/etc/udev/rules.d/`

Now we need to edit the file. For `<device>` use the bluetooth device we
discovered above. For `<user>` use the user who will be logged into X and will
be using the sound hardware.

Here's a copy of what's in that file:

    root/etc/udev/rules.d/99-my-device.rules
    ---
    ACTION=="add", ENV{DEVPATH}=="<device>", RUN+="/bin/su <user> -c '/home/<user>/bin/sound-switch.sh headphones'"
    ACTION=="remove", ENV{DEVPATH}=="<device>", RUN+="/bin/su <user> -c '/home/<user>/bin/sound-switch.sh speakers'"
    ---

There should be no need to restart the udev service but a rules reload may be
necessary after any changes:

    # udevadm control --reload-rules

Once you have added or made changes to the `.rules` file, test to see if your
script would be run

    # udevadm test "/devices/pci0000:00/0000:00:14.0/usb3/3-5/3-5:1.0/bluetooth/hci0/hci0:256"

In the output look for lines starting with `run: ` which means your script would be invoked.

### Configuring pulse audio for the user and the script for switching audio

#### Discover pulseaudio sinks

Use the script in this project `root/home/USER/bin/list-sinks-brief.sh` to see
the pulseaudio sinks your user has available. We'll use these in the next steps
to configure pulseaudio and the switch script.

We'll need to get the device "Name" values for the sinks that pulseaudio has
available for your user.

This command will get those for you

    $ pactl list sinks | grep -e "Sink " -e "Name" -e "Mute"

This command is also available in a convenience script in this project

    $ ./bin/list-sinks-brief.sh

#### Configure pulseaudio

On Ubuntu, the default configuration for pulseaudio was fighting me when
devices were connected and programs were being run. To take back control of
some of this it was necessary to make a custom user copy of `pulse/default.pa`

To get the default settings for pulseaudio to stop fighting me wrt default
sinks and volume settings, I made a copy of the `defaults.pa` file

    $ cd  # Current user's HOME
    $ mkdir .config/pulse  # Probably already exists
    $ cp /etc/pulse/default.pa .config/pulse

And then make these changes `$ diff .config/pulse/default.pa
/etc/pulse/default.pa`. Note that the `set-default-sink` name at the end is one
we discovered above with `pactl list sinks...`

Here's what the diff looked like at the time this README was last edited:

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

The important part is we're trying to prevent pulseaudio from doing
`module-stream-restore`, `module-switch-on-port-available` and
`module-switch-on-connect`.

The final one, `set-default-sink` helps with selecting the correct sink at boot
time, I believe.

#### Configure the `sound-switch.sh` script

Copy the file `root/home/USER/bin/sound-switch.sh` to somewhere on your PATH.
I often put user-specific scripts like this in `$HOME/bin/` but you'll
need to make sure that's on your PATH if you do so.

There are several variables at the beginning of `sound-switch.sh` which will
need to be set to values from the `pactl list sinks` output above.

One of them is the transient bluetooth device, one is the speakers we want to
use at other times. The third device is one that I never want to make any
noise. This is likely to be specific to my hardware, but this shows an example
of it being aggressively muted during all of the script's operations.

#### Test the whole thing

The `pactl list sinks` command above will also show you the mute/unmute status
of everything and can be used with `watch` to monitor how this is working more
easily.

Do this in a shell and then connect/disconnect your bluetooth device a few
times, making a note of the changes.

    $ watch 'pactl list sinks | grep -e "Sink " -e "Name" -e "Mute"'

Or, alternatively,

    $ watch ./bin/list-sinks-brief.sh

I did experience some weirdness after reboot initially due to incorrect
settings in `defaults.pa`. Reboot your system and test again to be sure
pulseaudio isn't doing anything funny.

## Development

Browse [on Github](https://github.com/dino-/custom-udev-pa)


## Contact

### Authors

Dino Morelli <dino@ui3.info>
