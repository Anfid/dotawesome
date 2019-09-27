#!/bin/bash

if [ ! -f /tmp/play ]; then
  echo false > /tmp/play
fi

if [ $(< /tmp/play) == "false" ]; then
  echo true > /tmp/play
  # Set qwerty layout as default for games
  setxkbmap -layout us,us,ru -variant ,colemak, -option 'grp:alt_shift_toggle'
  killall compton
  compton --config $HOME/.config/compton-play.conf &
else
  echo false > /tmp/play
  setxkbmap -layout us,ru -variant colemak, -option 'grp:alt_shift_toggle'
  killall compton
  compton &
fi
