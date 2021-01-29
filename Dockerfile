from debian:buster-slim

RUN apt-get update
RUN apt-get install mpd -y
RUN rm -rf /var/lib/apt/lists/*

#RUN useradd mpd_user
#RUN usermod -a -G audio mpd_user

COPY mpd.conf /etc/mpd.conf
COPY run-mpd.sh /run-mpd.sh

RUN chmod u+x /run-mpd.sh

RUN cat /etc/mpd.conf

RUN mkdir -p /root/.mpd

RUN mkdir -p /music
RUN mkdir -p /playlists

#ENTRYPOINT ["/usr/bin/mpd", "--no-daemon", "/etc/mpd.conf"]
ENTRYPOINT ["/run-mpd.sh"]
