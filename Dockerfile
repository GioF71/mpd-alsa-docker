from debian:buster-slim

RUN apt-get update
RUN apt-get install mpd -y
RUN rm -rf /var/lib/apt/lists/*

COPY mpd.conf /etc/mpd.conf
COPY run-mpd.sh /run-mpd.sh

RUN chmod u+x /run-mpd.sh

RUN mkdir -p /root/.mpd

RUN mkdir -p /db
RUN mkdir -p /music
RUN mkdir -p /playlists

ENV MPD_AUDIO_DEVICE default
ENV ALSA_DEVICE_NAME Alsa Device

VOLUME /db

ENTRYPOINT ["/run-mpd.sh"]
