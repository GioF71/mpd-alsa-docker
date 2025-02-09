ARG BASE_IMAGE=${BASE_IMAGE:-giof71/mpd-compiler:bookworm}
FROM ${BASE_IMAGE} AS base

ARG INTEGER_UPSAMPLING_SUPPORT=${INTEGER_UPSAMPLING_SUPPORT:-yes}
ARG USE_APT_PROXY=${USE_APT_PROXY:-no}
ARG IS_VANILLA=${IS_VANILLA:-no}
ARG BUILD_MODE=${BUILD_MODE:-full}

RUN mkdir -p /app/conf

RUN echo "USE_APT_PROXY=["${USE_APT_PROXY}"]"
RUN echo "INTEGER_UPSAMPLING_SUPPORT=["${INTEGER_UPSAMPLING_SUPPORT}"]"
RUN echo "BUILD_MODE=["${BUILD_MODE}"]"

RUN echo $BUILD_MODE > /app/conf/build_mode.txt

COPY app/conf/01-apt-proxy /app/conf/

RUN if [ "${USE_APT_PROXY}" = "Y" ]; then \
    echo "Builind using apt proxy"; \
    cp /app/conf/01-apt-proxy /etc/apt/apt.conf.d/01-apt-proxy; \
    cat /etc/apt/apt.conf.d/01-apt-proxy; \
    else \
    echo "Building without apt proxy"; \
    fi

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y mpc ca-certificates ffmpeg
#RUN apt-get upgrade -y

# install mpd from repo
RUN if [ "${IS_VANILLA}" = "yes" ]; then \
        echo "Vanilla build, installing mpd ..."; \
        apt-get install -y mpd --no-install-recommends; \
        echo ". done"; \
        echo "yes" > /app/conf/mpd_installed.txt; \
    else \
        echo "MPD should be already installed, but just to be safe ..."; \
        apt-get install -y mpd --no-install-recommends; \
        echo ". done"; \
        echo "yes" > /app/conf/mpd_installed.txt; \
    fi

# install required libraries
RUN if [ "${BUILD_MODE}" = "full" ]; then \
        apt-get install -y --no-install-recommends alsa-utils libasound2-plugin-equal; \
        echo "yes" > /app/conf/alsa_packages_installed.txt; \
    else \
        apt-get remove -y alsa-utils libasound2-plugin-equal; \
        echo "no" > /app/conf/alsa_packages_installed.txt; \
    fi

RUN if [ "${BUILD_MODE}" = "full" ]; then \
        apt-get install -y --no-install-recommends pulseaudio-utils; \
        echo "yes" > /app/conf/pulse_packages_installed.txt; \
    else \
        apt-get remove -y pulseaudio-utils; \
        echo "no" > /app/conf/pulse_packages_installed.txt; \
    fi

# install scrobbler (mpdscribble)
RUN if [ "${BUILD_MODE}" = "full" ]; then \
        apt-get install -y --no-install-recommends mpdscribble; \
    fi

RUN apt-get autoremove -y

RUN if [ "${USE_APT_PROXY}" = "Y" ]; then \
        rm /etc/apt/apt.conf.d/01-apt-proxy; \
    fi

RUN rm -rf /var/lib/apt/lists/*

FROM scratch
COPY --from=base / /

LABEL maintainer="GioF71"
LABEL source="https://github.com/GioF71/mpd-alsa-docker"

RUN mkdir -p /app
RUN mkdir -p /app/assets
RUN mkdir -p /app/bin
RUN mkdir -p /app/conf
RUN mkdir -p /app/doc
RUN mkdir -p /app/log
RUN mkdir -p /app/log/mpd
RUN mkdir -p /app/assets

RUN mkdir -p /app/run/conf
RUN chmod 777 /app/run/conf

VOLUME /db
VOLUME /music
VOLUME /playlists
VOLUME /log
VOLUME /user/config

# default mpd port
EXPOSE 6600
# default http port
EXPOSE 8000

ENV DATABASE_MODE ""
ENV MUSIC_DIRECTORY ""

ENV DATABASE_PROXY_HOST ""
ENV DATABASE_PROXY_PORT ""
ENV DATABASE_PROXY_PASSWORD ""
ENV DATABASE_PROXY_KEEPALIVE ""

ENV MPD_BIND_ADDRESS ""
ENV MPD_PORT ""

# ALSA Outputs
ENV ALSA_OUTPUT_CREATE ""
ENV ALSA_OUTPUT_ENABLED ""
ENV ALSA_OUTPUT_NAME ""
ENV ALSA_OUTPUT_PRESET ""
ENV ALSA_OUTPUT_DEVICE ""
ENV ALSA_OUTPUT_AUTO_FIND_MIXER ""
ENV ALSA_OUTPUT_MIXER_TYPE ""
ENV ALSA_OUTPUT_MIXER_DEVICE ""
ENV ALSA_OUTPUT_MIXER_CONTROL ""
ENV ALSA_OUTPUT_MIXER_INDEX ""
ENV ALSA_OUTPUT_ALLOWED_FORMATS ""
ENV ALSA_OUTPUT_ALLOWED_FORMATS_PRESET ""
ENV ALSA_OUTPUT_FORMAT ""
ENV ALSA_OUTPUT_AUTO_RESAMPLE ""
ENV ALSA_OUTPUT_THESYCON_DSD_WORKAROUND ""
ENV ALSA_OUTPUT_STOP_DSD_SILENCE ""
ENV ALSA_OUTPUT_INTEGER_UPSAMPLING ""
ENV ALSA_OUTPUT_INTEGER_UPSAMPLING_ALLOWED ""
ENV ALSA_OUTPUT_INTEGER_UPSAMPLING_ALLOWED_PRESET ""
ENV ALSA_OUTPUT_DOP ""

# PulseAudio Outputs
ENV PULSE_AUDIO_OUTPUT_CREATE ""
ENV PULSE_AUDIO_OUTPUT_ENABLED ""
ENV PULSE_AUDIO_OUTPUT_NAME ""
ENV PULSE_AUDIO_OUTPUT_SINK ""
ENV PULSE_AUDIO_OUTPUT_MEDIA_ROLE ""
ENV PULSE_AUDIO_OUTPUT_SCALE_FACTOR ""

# HTTPD Outputs
ENV HTTPD_OUTPUT_CREATE ""
ENV HTTPD_OUTPUT_ENABLED ""
ENV HTTPD_OUTPUT_NAME ""
ENV HTTPD_OUTPUT_PORT ""
ENV HTTPD_OUTPUT_BIND_TO_ADDRESS ""
ENV HTTPD_OUTPUT_ENCODER ""
ENV HTTPD_OUTPUT_MAX_CLIENTS ""
ENV HTTPD_OUTPUT_ALWAYS_ON ""
ENV HTTPD_OUTPUT_TAGS ""
ENV HTTPD_OUTPUT_FORMAT ""
ENV HTTPD_MIXER_TYPE ""

# ShoutCast/IceCast Outputs
ENV SHOUT_OUTPUT_CREATE ""
ENV SHOUT_OUTPUT_ENABLED ""
ENV SHOUT_OUTPUT_NAME ""
ENV SHOUT_OUTPUT_PROTOCOL ""
ENV SHOUT_OUTPUT_TLS ""
ENV SHOUT_OUTPUT_FORMAT ""
ENV SHOUT_OUTPUT_ENCODER ""
ENV SHOUT_OUTPUT_ENCODER_BITRATE ""
ENV SHOUT_OUTPUT_ENCODER_QUALITY ""
ENV SHOUT_OUTPUT_HOST ""
ENV SHOUT_OUTPUT_PORT ""
ENV SHOUT_OUTPUT_MOUNT ""
ENV SHOUT_OUTPUT_USER ""
ENV SHOUT_OUTPUT_PASSWORD ""
ENV SHOUT_OUTPUT_PUBLIC ""
ENV SHOUT_OUTPUT_MIXER_TYPE ""
ENV SHOUT_OUTPUT_ALWAYS_ON ""

# NULL outputs
ENV NULL_OUTPUT_CREATE ""
ENV NULL_OUTPUT_ENABLED ""
ENV NULL_OUTPUT_NAME ""
ENV NULL_OUTPUT_SYNC ""
ENV NULL_OUTPUT_MIXER_TYPE ""

ENV INPUT_CACHE_SIZE ""

# Qobuz Input Plugin
ENV QOBUZ_PLUGIN_ENABLED ""
ENV QOBUZ_APP_ID ""
ENV QOBUZ_APP_SECRET ""
ENV QOBUZ_USERNAME ""
ENV QOBUZ_PASSWORD ""
ENV QOBUZ_FORMAT_ID ""

ENV REPLAYGAIN_MODE ""
ENV REPLAYGAIN_PREAMP ""
ENV REPLAYGAIN_MISSING_PREAMP ""
## replaygain_limit does not seem to be relevant anymore
ENV REPLAYGAIN_LIMIT ""
ENV VOLUME_NORMALIZATION ""
ENV SAMPLERATE_CONVERTER ""

ENV AUTO_UPDATE ""
ENV AUTO_UPDATE_DEPTH ""

ENV SOXR_PLUGIN_ENABLE ""
ENV SOXR_PLUGIN_QUALITY ""
ENV SOXR_PLUGIN_THREADS ""
ENV SOXR_PLUGIN_PRECISION ""
ENV SOXR_PLUGIN_PHASE_RESPONSE ""
ENV SOXR_PLUGIN_PASSBAND_END ""
ENV SOXR_PLUGIN_STOPBAND_BEGIN ""
ENV SOXR_PLUGIN_ATTENUATION ""
ENV SOXR_PLUGIN_FLAGS ""

ENV SOXR_PLUGIN_PRESET ""

ENV LASTFM_USERNAME ""
ENV LASTFM_PASSWORD ""

ENV LIBREFM_USERNAME ""
ENV LIBREFM_PASSWORD ""

ENV JAMENDO_USERNAME ""
ENV JAMENDO_PASSWORD ""

ENV MPD_ENABLE_LOGGING ""
ENV MPD_LOG_LEVEL ""
ENV SCRIBBLE_VERBOSE ""

ENV PROXY ""

ENV USER_MODE ""
ENV PUID ""
ENV PGID ""
ENV AUDIO_GID ""

ENV SCROBBLER_MPD_HOST ""
ENV SCROBBLER_MPD_PORT ""

ENV ZEROCONF_ENABLED ""
ENV ZEROCONF_NAME ""

ENV HYBRID_DSD_ENABLED ""
ENV OPUS_DECODER_ENABLED ""

ENV AUDIO_BUFFER_SIZE ""

ENV RESTORE_PAUSED ""
ENV STATE_FILE_INTERVAL ""
ENV ENFORCE_PLAYER_STATE ""
ENV FORCE_REPO_BINARY ""

ENV STARTUP_DELAY_SEC ""

ENV DEFAULT_PERMISSIONS ""
ENV HOST_PERMISSIONS ""
ENV LOCAL_PERMISSIONS ""
ENV PASSWORD ""

ENV FFMPEG_ENABLED ""

ENV CURL_ENABLED ""
ENV CURL_PROXY ""
ENV CURL_PROXY_USER ""
ENV CURL_PROXY_PASSWORD ""
ENV CURL_VERIFY_PEER ""
ENV CURL_VERIFY_HOST ""
ENV CURL_CACERT ""

ENV MAX_PERMISSIONS ""

ENV MAX_ADDITIONAL_OUTPUTS_BY_TYPE ""

ENV CONNECTION_TIMEOUT ""
ENV MAX_CONNECTIONS ""
ENV MAX_PLAYLIST_LENGTH ""
ENV MAX_COMMAND_LIST_SIZE ""
ENV MAX_OUTPUT_BUFFER_SIZE ""

ENV STDERR_ENABLED ""

COPY README.md /app/doc/
COPY doc/* /app/doc/

COPY app/assets/pulse-client-template.conf /app/assets/pulse-client-template.conf
COPY app/assets/alsa-presets.conf /app/assets/alsa-presets.conf
COPY app/bin/build-soxr-presets.sh /app/bin/
COPY app/bin/build-allowed-formats-presets.sh /app/bin/
COPY app/bin/build-integer-upsampling-allowed-presets.sh /app/bin/
COPY app/bin/load-alsa-presets.sh /app/bin/
COPY app/bin/build-additional.sh /app/bin/
COPY app/bin/user-management.sh /app/bin/
COPY app/bin/any-of.sh /app/bin/
COPY app/bin/get-value.sh /app/bin/
COPY app/bin/read-file.sh /app/bin/
# most likely to change ...
COPY app/bin/run-mpd.sh /app/bin/
RUN chmod +x /app/bin/*.sh

WORKDIR /app/bin

ENTRYPOINT ["/app/bin/run-mpd.sh"]
