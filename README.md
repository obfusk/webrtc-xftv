[]: {{{1

    File        : README.md
    Maintainer  : Felix C. Stegerman <flx@obfusk.net>
    Date        : 2013-04-21

    Copyright   : Copyright (C) 2013  Felix C. Stegerman
    Version     : 0.0.3.SNAPSHOT

[]: }}}1

## TODO

  * audio recording not yet implemented on firefox!
  * make audio recording optional?
  * improve! (websockets?)

## CAVEATS

  * works with chromium 28; 25 and 26 CANNOT RECORD AUDIO!

## Description
[]: {{{1

  webrtc-xftv - record video+audio with webrtc/xftv/recorderjs

  webrtc-xftv uses webrtc to record a webcam video as a series of
  (jpeg) images with timestamps; this is sent to the backend where
  xuggle-frames-to-video turns it into a (webm) video file; the audio
  is recorded with recorderjs and then merged with the video using
  ffmpeg/avconv.

  See https://github.com/obfusk/xuggle-frames-to-video,
      https://github.com/mattdiamond/Recorderjs.

[]: }}}1

## License
[]: {{{1

  GPLv2 [1].

[]: }}}1

## References
[]: {{{1

  [1] GNU General Public License, version 2
  --- http://www.opensource.org/licenses/GPL-2.0

[]: }}}1

[]: ! ( vim: set tw=70 sw=2 sts=2 et fdm=marker : )
