#!/bin/sh

systemctl --user daemon-reload
systemctl --user stop mpd-pulse
systemctl --user start mpd-pulse


