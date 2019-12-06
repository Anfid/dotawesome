#!/bin/bash

function run-unique {
  if ! pgrep $1;
  then
    $@&
  fi
}

export LC_ALL=C

setxkbmap -layout us,ru -variant colemak, -option 'grp:toggle'
run-unique compton
run-unique dunst -conf "$HOME/.config/dunst/dunstrc"
run-unique nm-applet

run-unique telegram-desktop

if ! pgrep "conky"
then
  conky -c "$HOME/.config/conky/rings" & # the main conky with rings
  sleep 3 #time for the main conky to start; needed so that the smaller ones draw above not below (probably can be lower, but we still have to wait 5s for the rings to avoid segfaults)
  conky -c "$HOME/.config/conky/cpu" &
  sleep 1
  conky -c "$HOME/.config/conky/mem" &
  conky -c "$HOME/.config/conky/notes" &
fi
