#!/bin/bash

function run-unique {
  if ! pgrep $1;
  then
    $@&
  fi
}

export LC_ALL=C

setxkbmap -layout us,ru -option 'grp:alt_shift_toggle'
run-unique compton
run-unique dunst -conf "$HOME/.config/dunst/dunstrc"
run-unique cava -p "$HOME/.config/cava/raw"

run-unique telegram-desktop
run-unique slack

if ! pgrep "conky"
then
  conky -c "$HOME/.conky/rings" & # the main conky with rings
  sleep 8 #time for the main conky to start; needed so that the smaller ones draw above not below (probably can be lower, but we still have to wait 5s for the rings to avoid segfaults)
  conky -c "$HOME/.conky/cpu" &
  sleep 1
  conky -c "$HOME/.conky/mem" &
  conky -c "$HOME/.conky/notes" &
fi
