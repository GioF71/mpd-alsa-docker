ARG BASE_IMAGE_TAG="${BASE_IMAGE_TAG:-bullseye-slim}"
FROM giof71/mpd-compiler:${BASE_IMAGE_TAG} AS BASE

#ARG BASE_IMAGE="${BASE_IMAGE:-debian:bullseye-slim}"
#FROM ${BASE_IMAGE} AS BASE
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

EXPOSE 6600

ENV MPD_AUDIO_DEVICE default
ENV ALSA_DEVICE_NAME Alsa Device
ENV MIXER_TYPE hardware
ENV MIXER_DEVICE default
ENV MIXER_CONTROL PCM
ENV MIXER_INDEX 0
ENV DOP yes
ENV ALSA_ALLOWED_FORMATS ""
ENV ALSA_OUTPUT_FORMAT ""
ENV INTEGER_UPSAMPLING ""

ENV OUTPUT_MODE alsa
ENV PULSEAUDIO_OUTPUT_NAME ""

ENV QOBUZ_PLUGIN_ENABLED no
ENV QOBUZ_APP_ID ID
ENV QOBUZ_APP_SECRET SECRET
ENV QOBUZ_USERNAME USERNAME
ENV QOBUZ_PASSWORD PASSWORD
ENV QOBUZ_FORMAT_ID N

ENV TIDAL_PLUGIN_ENABLED no
ENV TIDAL_APP_TOKEN TOKEN
ENV TIDAL_USERNAME USERNAME
ENV TIDAL_PASSWORD PASSWORD
ENV TIDAL_AUDIOQUALITY Q

ENV REPLAYGAIN_MODE off
ENV REPLAYGAIN_PREAMP 0
ENV REPLAYGAIN_MISSING_PREAMP 0
ENV REPLAYGAIN_LIMIT yes
ENV VOLUME_NORMALIZATION no
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

ENV MPD_LOG_LEVEL ""
ENV SCRIBBLE_VERBOSE ""

ENV PROXY ""

ENV USER_MODE ""
ENV PUID ""
ENV PGID ""
ENV AUDIO_GID ""

ENV STARTUP_DELAY_SEC 0

COPY app/assets/pulse-client-template.conf /app/assets/pulse-client-template.conf
COPY app/conf/mpd-sample.conf /app/conf/
COPY app/bin/run-mpd.sh /app/bin/
COPY app/bin/get-value.sh /app/bin/
COPY app/bin/read-file.sh /app/bin/
COPY app/bin/build-soxr-presets.sh /app/bin/
RUN chmod +x /app/bin/*.sh

COPY README.md /app/doc/

WORKDIR /app/bin

RUN /app/bin/compiled/mpd-ups --version

ENTRYPOINT ["/app/bin/run-mpd.sh"]
