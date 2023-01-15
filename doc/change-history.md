# Change History

Date|Major Changes
:---|:---
2023-01-15|Moved change history to separate document
2023-01-15|Add support for additional PulseAudio outputs
2023-01-15|Add support for `none` as OUTPUT_MODE
2023-01-15|Minor housekeeping tasks
2023-01-15|Removed defaults for `REPLAYGAIN_*` in Dockerfile
2023-01-15|Remove default for `STARTUP_DELAY` in Dockerfile
2023-01-14|Removed Qobuz default from Dockerfile
2023-01-14|Corrected some defaults from Dockerfile
2023-01-14|Removed default for `MPD_AUDIO_DEVICE` in Dockerfile
2023-01-07|Added [contributed](https://github.com/GioF71/mpd-alsa-docker/pull/172) documentation about equalization support
2023-01-05|Improved use of `ALSA_DEVICE_NAME`
2023-01-05|Allowing custom `.asoundrc`
2022-12-30|Removed `pull=always` from suggested systemd service
2022-12-30|Initial support for equalization (add package `libasound2-plugin-equal`)
2022-12-27|Support for additional `alsa` outputs
2022-12-24|`MAX_ADDITIONAL_OUTPUTS_BY_TYPE` now defaults to `20`
2022-12-17|Add `MPD_ENABLE_LOGGING`
2022-12-16|Preset `fiio-e18` now includes mixer
2022-12-16|Code cleanup
2022-12-14|Creation of `audio` group also for `pulse` mode if `AUDIO_GID` is specified
2022-12-13|Minor cleanup tasks
2022-12-13|Completed support for PulseAudio `sink` and `media_role`, `scale_factor`
2022-12-12|Support for `state_file_interval`
2022-12-12|Mount for `shout` has an index-aware default now
2022-12-12|Do not force `enabled` by default for additional outputs
2022-12-12|Support for additional `shout` outputs
2022-12-12|Support for `restore_paused`
2022-12-10|Support for `mixer_type` in httpd outputs
2022-12-10|Lookup table for more convenient `samplerate_converter` values
2022-12-09|Support for additional `httpd` outputs
2022-12-09|Max number of outputs by type (`MAX_ADDITIONAL_OUTPUTS_BY_TYPE`)
2022-12-07|Minor cleanup tasks
2022-12-07|Support for `thesycon_dsd_workaround`
2022-12-07|Support for `auto_resample`
2022-12-03|`HYBRID_DSD_ENABLED` added (enabled by default)
2022-12-03|Removed support for defunct Tidal plugin
2022-12-02|Support for `additional-outputs.txt`
2022-11-30|Support for `database_mode` with possible values `simple` and `proxy`
2022-11-30|Support for tuning of `music_directory`
2022-11-30|Bump to mpd version `v0.23.11`
2022-11-30|Add support for output mode `null`
2022-11-29|Add support for `max_output_buffer_size`
2022-11-28|Add support for `input_cache_size`
2022-11-24|Add `-sw` preset variants for presets which provide hardware volume support
2022-11-23|`MPD_BIND_ADDRESS` defaults to `0.0.0.0`
2022-11-23|Disabled `wildmidi` decoder plugin
2022-11-23|Support for `bind_address` (`MPD_BIND_ADDRESS`) and for `port` (`MPD_PORT`)
2022-11-22|Support for zeroconf configurations via `ZEROCONF_ENABLED` and `ZEROCONF_NAME`. Zeroconf is disabled by default.
2022-11-18|Preset names added
2022-11-18|Preset for Topping E30
2022-11-15|Add variable `ALSA_AUTO_FIND_MIXER` to enable automatic mixer search (experimental feature)
2022-11-15|Alsa mixer settings are empty by default
2022-11-15|Falling back to `software` when `MIXER_TYPE` is left empty
2022-11-14|Support for alsa presets `ALSA_PRESET`.
2022-11-14|Using `SOXR_PLUGIN_PRESET` instead of now deprecated `SOXR_PRESET`
2022-11-14|DOP empty by default
2022-11-14|Fix connection to mpd from the scrobbler. Add optional variables for forcing host and port in case of host mode (`SCROBBLER_MPD_HOST` and `SCROBBLER_MPD_PORT`)
2022-11-12|Presets for ALSA_ALLOWED_FORMATS (ALSA_ALLOWED_FORMATS_PRESET)
2022-11-12|Presets for SOXR_PLUGIN
2022-11-12|Building mpd in docker images takes a long time, so only bullseye and jammy images are built. But you can build your own variants!
2022-11-12|Patched version available, with support for upsampling
2022-11-12|MPD built from source
2022-11-01|Support for scrobbling service credentials in discrete files
2022-10-31|Added `--pull=always` to docker run command for systemd pulse service
2022-10-30|Docker pull before container stop for systemd pulse service
2022-10-30|Avoid `--no-install-recommends` for `mpd` installation
2022-10-29|PulseAudio user-level systemd service introduced
2022-10-26|Added support for `soxr` plugin
2022-10-26|Added support for `alsa` output format (`OUTPUT_FORMAT`)
2022-10-26|Added support for samplerate_converter
2022-10-26|Added support for PulseAudio
2022-10-26|Build mpd.conf at container runtime
2022-10-22|Support for daily builds
2022-10-22|Add builds for kinetic along with the current lts versions of ubuntu
2022-10-22|Fixed `AUDIO-GID` now effectively defaulting to `995`
2022-10-21|User mode support
2022-10-21|Add logging support
2022-10-20|Included `mpdscribble` for scrobbling support
2022-10-20|Multi-stage build
2022-10-05|Reviewed build process
2022-10-05|Add build from debian:bookworm-slim
2022-04-30|Rebased to mpd-base-images built on 2022-04-30
2022-03-12|Rebased to mpd-base-images built on 2022-03-12
2022-02-26|Rebased to mpd-base-images built on 2022-02-26
2022-02-25|Add README.md synchronization towards Docker Hub
2022-02-13|File `/etc/mpd.conf` is not overwritten. Using file `/app/conf/mpd-alsa.conf`. Launcher script moved to `/app/bin` in the container. Repository files reorganized.
2022-02-11|Automated builds thanks to [Der-Henning](https://github.com/Der-Henning/), Builds for arm64 also thanks to [Der-Henning](https://github.com/Der-Henning/), the README.md you are reading now is copied to the image under path `/app/doc/README.md`. Building from debian bullseye, debian buster and ubuntu focal. Created convenience script for local build.
