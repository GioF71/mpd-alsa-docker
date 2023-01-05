# Build

## Using Docker build

You can build (or rebuild) the image by opening a terminal from the root of the repository and issuing the following command:

`docker build . -t giof71/mpd-alsa`

It will take very little time even on a Raspberry Pi. When it's finished, you can run the container following the previous instructions.  
Just be careful to use the tag you have built.

## Using the convenience script

There is a script, named `build.sh`, in the root of the repository.  
By default it builds using the current debian image and will tag the resulting image as `giof71/mpd-alsa:local`.

### Usage

The usage of the switches should be quite straightforward, but I will add more documentation here, as soon as I can.
