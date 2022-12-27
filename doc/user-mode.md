# User mode

You can enable user-mode by specifying `USER_MODE` to `Y` or `YES`.  
For `alsa` mode, it is important that the container knows the group id of the host `audio` group. On my system it's `995`, however it is possible to verify using the following command:

```code
getent group audio
```

On my system, this commands outputs:

```text
audio:x:995:brltty,mpd,squeezelite
```

In any case, make sure to set the variable `AUDIO_GID` accordingly. The variable is mandatory for user mode with alsa output.  
Also, if your user/group id are not both `1000`, set `PUID` and `PGID` accordingly.  
It is possible to verify the uid and gid of the currently logged user using the following command:

```code
id
```

On my system this command outputs:

```text
uid=1000(giovanni) gid=1000(giovanni) groups=1000(giovanni),3(sys),90(network),98(power),957(autologin),965(docker),967(libvirt),991(lp),992(kvm),998(wheel)
```
