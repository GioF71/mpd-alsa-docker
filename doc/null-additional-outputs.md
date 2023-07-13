# Null additional outputs

Additional Null can be configured using the following variables:

VARIABLE|DESCRIPTION
:---|:---
NULL_OUTPUT_CREATE|Set to `yes` if you want to create an additional null output
NULL_OUTPUT_ENABLED|Sets the output as enabled if set to `yes`, otherwise mpd's default behavior applies
NULL_OUTPUT_NAME|The name of the Null output, defaults to `null`
NULL_OUTPUT_SYNC|Sync mode for the `null` output, can be `yes` (default) or `no`

Refer to the MPD [documentation](https://mpd.readthedocs.io/en/stable/plugins.html#null) for the meaning of the variables.  

