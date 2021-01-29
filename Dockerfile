from debian:buster-slim

RUN apt-get update
RUN apt-get install mpd -y
RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.mpd

RUN mkdir -p /db
RUN mkdir -p /music
RUN mkdir -p /playlists

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

COPY mpd.conf /etc/mpd.conf
COPY run-mpd.sh /run-mpd.sh
RUN chmod u+x /run-mpd.sh

ENTRYPOINT ["/run-mpd.sh"]
