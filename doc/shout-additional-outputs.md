# Shout additional outputs

VARIABLE|DESCRIPTION
:---|:---
SHOUT_OUTPUT_CREATE|Set to `yes` if you want to create an additional shout output
SHOUT_OUTPUT_ENABLED|Sets the output as enabled if set to `yes`, otherwise mpd's default behavior applies
SHOUT_OUTPUT_NAME|The name of the shout output, defaults to `shout`
SHOUT_OUTPUT_PROTOCOL|Specifies the protocol that wil be used to connect to the server, can be `icecast2` (default), `icecast1`, `shoutcast`
SHOUT_OUTPUT_TLS|Specifies what kind of TLS to use, can be `disabled` (default), `auto`, `auto_no_plain`, `rfc2818`, `rfc2817`
SHOUT_OUTPUT_FORMAT|The output format, defaults to `44100:16:2`
SHOUT_OUTPUT_ENCODER|The encoder defaults to `vorbis`, see [here](https://mpd.readthedocs.io/en/stable/plugins.html#encoder-plugins) for other options. BITRATE and QUALITY are typically alternative, so do not specify both of them.
SHOUT_OUTPUT_ENCODER_BITRATE|Encoder bitrate. Refer to the encoder [documentation](https://mpd.readthedocs.io/en/stable/plugins.html#encoder-plugins)
SHOUT_OUTPUT_ENCODER_QUALITY|Encoder quality. Refer to the encoder [documentation](https://mpd.readthedocs.io/en/stable/plugins.html#encoder-plugins)
SHOUT_OUTPUT_HOST|Sets the host name of the ShoutCast / IceCast server, defaults to `icecast`, this seems a sensible default in a docker environment
SHOUT_OUTPUT_PORT|Connect to this port number on the specified host, defaults to `8000`
SHOUT_OUTPUT_MOUNT|Mounts the MPD stream in the specified URI
SHOUT_OUTPUT_USER|Sets the user name for submitting the stream to the server, defaults to `source`
SHOUT_OUTPUT_PASSWORD|Sets the password for submitting the stream to the server, defaults to `hackme`
SHOUT_OUTPUT_PUBLIC|Specifies whether the stream should be "public", defaults to `no`
SHOUT_MIXER_TYPE|Set to `software` if you want to be able to change the volume of the output stream
