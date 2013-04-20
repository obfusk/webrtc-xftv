# --                                                            ; {{{1
#
# File        : webrtc-xftv.coffee
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-04-20
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2
#
# --                                                            ; }}}1

$ ->
  anim  = window.webkitRequestAnimationFrame ||
          window.mozRequestAnimationFrame ||
          throw Error 'no *RequestAnimationFrame'

  gum   = navigator.webkitGetUserMedia ||
          navigator.mozGetUserMedia ||
          throw Error 'no *GetUserMedia'

  header  = /^data:image\/(png|jpeg);base64,/

  gum_req = video: true, audio: false                           # TODO
  prefs   = width: 640, height: 480, fps: 10, secs: 2, send_every: 1

  st      = id: null, n_pix: null, images: null, t_start: null, \
            t_prev_take: null, t_prev_send: null
  elems   = canvas: $('#canvas'), links: $('#links'), \
            start: $('#start'), video: $('#video')

  ajax_in_progress = false

  ajax_err  = (xhr, stat, err) -> alert "AJAX Error: #{err}"
  gum_err   = (err) -> alert "Media Error: #{err}"

  ajax_post = (url, data, s = null, e = ajax_err) ->            # {{{1
    console.log 'ajax ...', url, data                         #  DEBUG
    if ajax_in_progress
      console.log 'ajax in progress; delaying ...'            #  DEBUG
      setTimeout (-> ajax_post url, data, s, e), 100
    else
      ajax_in_progress = true
      f = (data, stat, xhr) ->
        ajax_in_progress = false; s JSON.parse data if s
      g = (err) ->
        ajax_in_progress = false; e err if e
      $.ajax type: 'POST', url: url, success: f, error: g, \
        data: { data: JSON.stringify data }
                                                                # }}}1

  gum_succ = (stream) ->
    console.log 'gum success'                                 #  DEBUG
    elems.video[0].src = window.URL.createObjectURL stream
    elems.video[0].play()

  take_pic = (ts) ->                                            # {{{1
    # console.log 'taking pic ...', st.n_pix                  #  DEBUG
    ++st.n_pix
    elems.canvas[0].width  = prefs.width
    elems.canvas[0].height = prefs.height
    elems.canvas[0].getContext('2d').drawImage elems.video[0],
      0, 0, prefs.width, prefs.height
    data = elems.canvas[0].toDataURL 'image/jpeg'
    st.images.push image: data.replace(header, ''), \
      timestamp: Math.round(ts) * 1e6   # nanoseconds, integer
                                                                # }}}1

  send_pix = ->
    console.log 'sending pix ...', st.n_pix, st.images.length #  DEBUG
    send = images: st.images; st.images = []
    ajax_post "/rec/#{st.id}", send

  send_done = ->                                                # {{{1
    console.log 'sending last pix ...', st.n_pix, st.images.length
                                                              #  DEBUG
    send = images: st.images, done: true; st.images = []
    ajax_post "/rec/#{st.id}", send, (data) ->
      li = $ '<li>'; a = $ '<a>'
      a.attr 'href', data.link; a.text data.link
      li.append a; elems.links.append li
      rec_done()
                                                                # }}}1

  tick = (t) ->                                                 # {{{1
    # console.log 'tick ...'                                  # DEBUG
    ts = t - st.t_start
    if (t - st.t_prev_take) >= (1000 / prefs.fps)
      st.t_prev_take = t; take_pic ts
    if (t - st.t_prev_send) >= prefs.send_every * 1000
      st.t_prev_send = t; send_pix()
    if ts >= prefs.secs * 1000 then send_done() else anim tick
                                                                # }}}1

  rec_start = ->                                                # {{{1
    console.log 'start recording'                             #  DEBUG
    $('.control').attr 'disabled', true
    prefs[k] = $("#prefs_#{k}").val() for k of prefs
    ajax_post '/rec', prefs, (data) ->
      st.id = data.id; st.n_pix = 0; st.images = []
      st.t_start = st.t_prev_take = st.t_prev_send = +new Date
      anim tick
                                                                # }}}1

  rec_done = ->
    console.log 'done recording'                              #  DEBUG
    $('.control').attr 'disabled', false

  gum.call navigator, gum_req, gum_succ, gum_err
  elems.start.click rec_start

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
