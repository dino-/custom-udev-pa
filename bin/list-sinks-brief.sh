#! /bin/bash

pactl list sinks | grep -e 'Sink ' -e 'Name' -e 'Mute'
