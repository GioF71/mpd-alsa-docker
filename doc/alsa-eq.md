# ALSA Equaliser

This image incudes the `libasound2-plugin-equal` package which allows the user to enable and apply equalisation to your ALSA ouputs.

## HOW-to

### Method 1

This method will apply the equalisation to the default output created when running the container.

First create `asoundrc.txt` file and mount it to `/user/config/asoundrc.txt`. This file should contain the following:

```bash
pcm.!default {
  type plug
  slave.pcm plugequal;
}
ctl.!default {
  type hw card 0
}
ctl.equal {
  type equal;
}
pcm.plugequal {
  type equal;
  slave.pcm "plughw:0,0"; # NOTE this line MUST be your hardware device.
}
pcm.equal {
  type plug;
  slave.pcm plugequal;
}
```

### Method 2

This method will apply the equalisation to a separate output created when running the container. It will not affect your default output.

First create `asoundrc.txt` file and mount it to `/user/config/asoundrc.txt`. This file should contain the following:

```text
ctl.equal {
  type equal;
}
pcm.plugequal {
  type equal;
  slave.pcm "plughw:0,0"; # NOTE this line MUST be your hardware device.
}
pcm.equal {
  type plug;
  slave.pcm plugequal;
}
```

Now create a separate output by adding this your `additional-outputs.txt`:

```text
audio_output {
  type "alsa"
  name "ALSA EQ" # You can name it as you like
  device "plug:plugequal"
}
```

Playing audio through this output will have the equalisation applied.

## ALSA EQ CLI

The ALSA EQ cli can be accessed by running the following command:

```text
docker exec -it mpd alsamixer -D equal
```

![ALSA EQ cli](https://i.imgur.com/Wa3Uoau.jpeg)

## EQ Presets

ALSA EQ Presets can be created in the form of bash scripts which then later can be ran to apply different EQ Preset of choice.

### EQ Preset (example script)

Here 66 = base value of each frequency. Value ranges from 0 to 100. Below 66 is negative value and above 66 is positive value.

```text
default.sh
...
#!/bin/bash
/usr/bin/amixer -D equal -q set '00. 31 Hz' 66
/usr/bin/amixer -D equal -q set '01. 63 Hz' 66
/usr/bin/amixer -D equal -q set '02. 125 Hz' 66
/usr/bin/amixer -D equal -q set '03. 250 Hz' 66
/usr/bin/amixer -D equal -q set '04. 500 Hz' 66
/usr/bin/amixer -D equal -q set '05. 1 kHz' 66
/usr/bin/amixer -D equal -q set '06. 2 kHz' 66
/usr/bin/amixer -D equal -q set '07. 4 kHz' 66
/usr/bin/amixer -D equal -q set '08. 8 kHz' 66
/usr/bin/amixer -D equal -q set '09. 16 kHz' 66
echo "EQ: ${0##*/} applied"
```

Also make it executable by doing `chmod +x default.sh`. You can create your own presets by getting the values using ALSA EQ cli.

### Presets Volume & Applying

Mount a directory containing all your preset scripts to `/user/config/eq-presets` and then run `docker exec -it mpd sh /user/config/eq-presets/<preset-name>.sh`
