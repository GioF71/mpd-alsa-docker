ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN mkdir -p /root/.mpd

RUN mkdir -p /db
RUN mkdir -p /music
RUN mkdir -p /playlists

VOLUME /db
VOLUME /music
VOLUME /playlists

RUN mkdir -p /app       # might be created in base image
RUN mkdir -p /app/bin   # might be created in base image
RUN mkdir -p /app/doc   # might be created in base image

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
