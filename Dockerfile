ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG USE_APT_PROXY

LABEL maintainer="GioF71"
LABEL source="https://github.com/GioF71/mpd-alsa-docker"

RUN mkdir -p /app
RUN mkdir -p /app/bin
RUN mkdir -p /app/conf
RUN mkdir -p /app/doc
RUN mkdir -p /app/assets

COPY app/conf/01-apt-proxy /app/conf/

RUN echo "USE_APT_PROXY=["${USE_APT_PROXY}"]"

RUN if [ "${USE_APT_PROXY}" = "Y" ]; then \
    echo "Builind using apt proxy"; \
    cp /app/conf/01-apt-proxy /etc/apt/apt.conf.d/01-apt-proxy; \
    cat /etc/apt/apt.conf.d/01-apt-proxy; \
    else \
    echo "Building without apt proxy"; \
    fi

RUN apt-get update && apt-get install --no-install-recommends -y mpd

RUN mkdir -p /root/.mpd

VOLUME /db
VOLUME /music
VOLUME /playlists

EXPOSE 6600

ENV MPD_AUDIO_DEVICE default
ENV ALSA_DEVICE_NAME Alsa Device
ENV MIXER_TYPE hardware
ENV MIXER_DEVICE default
ENV MIXER_CONTROL PCM
ENV MIXER_INDEX 0
ENV DOP yes

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

ENV STARTUP_DELAY_SEC 0

COPY app/conf/mpd.conf /app/conf/mpd-alsa.conf
COPY app/bin/run-mpd.sh /app/bin/run-mpd.sh
RUN chmod u+x /app/bin/run-mpd.sh

COPY README.md /app/doc/

WORKDIR /app/bin

ENTRYPOINT ["/app/bin/run-mpd.sh"]
