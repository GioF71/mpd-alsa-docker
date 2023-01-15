ARG BASE_IMAGE_TAG="${BASE_IMAGE_TAG:-bullseye-slim}"
FROM giof71/mpd-compiler:${BASE_IMAGE_TAG} AS BASE

ARG USE_APT_PROXY

RUN mkdir -p /app/conf

COPY app/conf/01-apt-proxy /app/conf/

RUN echo "USE_APT_PROXY=["${USE_APT_PROXY}"]"

RUN if [ "${USE_APT_PROXY}" = "Y" ]; then \
    echo "Builind using apt proxy"; \
    cp /app/conf/01-apt-proxy /etc/apt/apt.conf.d/01-apt-proxy; \
    cat /etc/apt/apt.conf.d/01-apt-proxy; \
    else \
    echo "Building without apt proxy"; \
    fi

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y mpd
RUN apt-get install -y --no-install-recommends alsa-utils
RUN apt-get install -y --no-install-recommends libasound2-plugin-equal
RUN apt-get install -y --no-install-recommends pulseaudio-utils
RUN apt-get install -y --no-install-recommends mpdscribble
RUN apt-get install -y --no-install-recommends libfmt7
RUN apt-get install -y --no-install-recommends libsidplay2
RUN apt-get install -y --no-install-recommends libsidutils0
RUN apt-get install -y --no-install-recommends libresid-builder-dev

RUN rm -rf /var/lib/apt/lists/*

FROM scratch
COPY --from=BASE / /

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
VOLUME /app/scribble
VOLUME /log
VOLUME /user/config

# default mpd port
EXPOSE 6600
# default httpd port
EXPOSE 8000

ENV DATABASE_MODE ""
ENV MUSIC_DIRECTORY ""

ENV DATABASE_PROXY_HOST ""
ENV DATABASE_PROXY_PORT ""

ENV MPD_BIND_ADDRESS ""
ENV MPD_PORT ""

ENV ALSA_PRESET ""
ENV ALSA_DEVICE_NAME ""
ENV MPD_AUDIO_DEVICE ""
ENV MIXER_TYPE ""
ENV MIXER_DEVICE ""
ENV MIXER_CONTROL ""
ENV MIXER_INDEX ""
ENV DOP ""
ENV ALSA_ALLOWED_FORMATS ""
ENV ALSA_ALLOWED_FORMATS_PRESET ""
ENV ALSA_OUTPUT_FORMAT ""
ENV AUTO_RESAMPLE ""
ENV THESYCON_DSD_WORKAROUND ""
ENV INTEGER_UPSAMPLING ""
ENV ALSA_AUTO_FIND_MIXER ""

ENV OUTPUT_MODE ""
ENV PULSEAUDIO_OUTPUT_NAME ""
ENV PULSEAUDIO_OUTPUT_ENABLED ""
ENV PULSEAUDIO_OUTPUT_MEDIA_ROLE ""
ENV PULSEAUDIO_OUTPUT_SCALE_FACTOR ""

ENV NULL_OUTPUT_NAME ""
ENV NULL_OUTPUT_SYNC ""

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
ENV ALSA_OUTPUT_OUTPUT_FORMAT ""
ENV ALSA_OUTPUT_AUTO_RESAMPLE ""
ENV ALSA_OUTPUT_THESYCON_DSD_WORKAROUND ""
ENV ALSA_OUTPUT_INTEGER_UPSAMPLING ""
ENV ALSA_OUTPUT_DOP ""

ENV PULSE_AUDIO_OUTPUT_CREATE ""
ENV PULSE_AUDIO_OUTPUT_ENABLED ""
ENV PULSE_AUDIO_OUTPUT_NAME ""
ENV PULSE_AUDIO_OUTPUT_MEDIA_ROLE ""
ENV PULSE_AUDIO_OUTPUT_SCALE_FACTOR ""

ENV HTTPD_OUTPUT_CREATE ""
ENV HTTPD_OUTPUT_ENABLED ""
ENV HTTPD_OUTPUT_NAME ""
ENV HTTPD_OUTPUT_PORT ""
ENV HTTPD_OUTPUT_BIND_TO_ADDRESS ""
ENV HTTPD_OUTPUT_ENCODER ""
ENV HTTPD_OUTPUT_MAX_CLIENTS ""
ENV HTTPD_OUTPUT_ALWAYS_ON ""
ENV HTTPS_OUTPUT_TAGS ""
ENV HTTPD_OUTPUT_FORMAT ""
ENV HTTPD_MIXER_TYPE ""

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
ENV SHOUT_MIXER_TYPE ""

ENV INPUT_CACHE_SIZE ""

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

ENV MAX_OUTPUT_BUFFER_SIZE ""

ENV MAX_ADDITIONAL_OUTPUTS_BY_TYPE ""

ENV STARTUP_DELAY_SEC ""

COPY app/assets/pulse-client-template.conf /app/assets/pulse-client-template.conf
COPY app/assets/alsa-presets.conf /app/assets/alsa-presets.conf
COPY app/conf/mpd-sample.conf /app/conf/
COPY app/bin/run-mpd.sh /app/bin/
COPY app/bin/get-value.sh /app/bin/
COPY app/bin/read-file.sh /app/bin/
COPY app/bin/build-soxr-presets.sh /app/bin/
COPY app/bin/build-allowed-formats-presets.sh /app/bin/
COPY app/bin/load-alsa-presets.sh /app/bin/
COPY app/bin/build-additional.sh /app/bin/
COPY app/bin/user-management.sh /app/bin/
COPY app/bin/pulse.sh /app/bin/
RUN chmod +x /app/bin/*.sh

COPY README.md /app/doc/
COPY doc/* /app/doc/

WORKDIR /app/bin

ENTRYPOINT ["/app/bin/run-mpd.sh"]
