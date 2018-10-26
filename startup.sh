#!/bin/bash

function run-unique {
  if ! pgrep $1;
  then
    $@&
  fi
}

function awful-spawn-unique {
  PNAME=`echo $3 | cut -c-15`
  if ! pgrep $PNAME;
  then
    awesome-client "
      awful=require(\"awful\");
      s = $1;
      t = $2;
      awful.spawn(\"${@:3}\", {
        screen    = s,
        tag       = t,
      })"
  fi
}

setxkbmap -layout us,ru -option 'grp:alt_shift_toggle'
run-unique compton
run-unique dunst -conf $HOME/.config/dunst/dunstrc
run-unique cava -p $HOME/.config/cava/raw

awful-spawn-unique 'math.min(2, screen.count())' 'screen.count() == 2 and 1 or 4' telegram-desktop
awful-spawn-unique 'math.min(2, screen.count())' 'screen.count() == 2 and 1 or 4' slack
