# HTTPD additional outputs

Additional httpd outputs can be configured using the following variables:

VARIABLE|DESCRIPTION
:---|:---
HTTPD_OUTPUT_CREATE|Set to `yes` if you want to create an additional httpd output
HTTPD_OUTPUT_ENABLED|Sets the output as enabled if set to `yes`, otherwise mpd's default behavior applies
HTTPD_OUTPUT_NAME|The name of the httpd output, defaults to `httpd`
HTTPD_OUTPUT_PORT|The port for the httpd output stream, defaults to `8000` if not specified
HTTPD_OUTPUT_BIND_TO_ADDRESS|Allows to specify the bind address
HTTPD_OUTPUT_ENCODER|The encoder defaults to `wave`, see [here](https://mpd.readthedocs.io/en/stable/plugins.html#encoder-plugins) for other options
HTTPD_OUTPUT_ENCODER_BITRATE|Encoder bitrate. Refer to the encoder [documentation](https://mpd.readthedocs.io/en/stable/plugins.html#encoder-plugins)
HTTPD_OUTPUT_ENCODER_QUALITY|Encoder quality. Refer to the encoder [documentation](https://mpd.readthedocs.io/en/stable/plugins.html#encoder-plugins)
HTTPD_OUTPUT_MAX_CLIENTS|Sets a limit, number of concurrent clients. When set to 0 no limit will apply. Defaults to `0`
HTTPD_OUTPUT_ALWAYS_ON|If set to `yes`, then MPD attempts to keep this audio output always open. This may be useful for streaming servers, when you don’t want to disconnect all listeners even when playback is accidentally stopped. Defaults to `yes`
HTTPD_OUTPUT_TAGS|If set to no, then MPD will not send tags to this output. This is only useful for output plugins that can receive tags, for example the httpd output plugin. Defaults to `yes`
HTTPD_OUTPUT_FORMAT|The output format, defaults to `44100:16:2`
HTTPD_OUTPUT_MIXER_TYPE|Set to `software` if you want to be able to change the volume of the output stream

The port number default is calculated for each index by incrementing the default (`8000`) value.  
When using multiple httpd outputs, remember to open *all* the relevant ports, not only `8000`, otherwise only the first output will work.
