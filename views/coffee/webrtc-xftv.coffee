# ... HEADER ...

$ ->
  anim  = window.webkitRequestAnimationFrame ||
          window.mozRequestAnimationFrame ||
          throw Error 'no *RequestAnimationFrame'

  gum   = navigator.webkitGetUserMedia ||
          navigator.mozGetUserMedia ||
          throw Error 'no *GetUserMedia'

  constraints = video: true, audio: true

  st =
    width: 640, height: 480, fps: 10, secs: 10                  # TODO
    t_start: null, t_last: null, n_pix: 0
    canvas: $('#canvas'), start: $('#start'), video: $('#video')

  media_err   = (err) -> alert "Media Error: #{err}"
  media_succ  = (stream) ->
    st.video[0].src = window.URL.createObjectURL stream
    st.video[0].play()

  take_pic = (ts) ->
    console.log 'taking pic ...', st.n_pix                    #  DEBUG
    ++st.n_pix
    st.canvas[0].width = st.width; st.canvas[0].height = st.height
    st.canvas[0].getContext('2d').drawImage st.video[0], 0, 0,
      st.width, st.height
    data = st.canvas[0].toDataURL 'image/jpeg'
    { image: data, timestamp: ts }

  send_pic = (data) ->
    # ...

  tick = (t) ->
    console.log 'tick ...'                                    # DEBUG
    ts = t - st.t_start
    if (t - st.t_last) > (1000 / st.fps)
      st.t_last = t; send_pic take_pic ts
    anim tick unless ts > st.secs * 1000

  gum.call navigator, constraints, media_succ, media_err

  $('#start').click ->
    st.t_start = st.t_last = +new Date; anim tick
