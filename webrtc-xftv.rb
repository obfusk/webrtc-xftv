# --                                                            ; {{{1
#
# File        : webrtc-xftv.rb
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-04-21
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2
#
# --                                                            ; }}}1

require 'base64'
require 'coffee-script'
require 'haml'
require 'hashie'
require 'json'
require 'securerandom'
require 'sinatra/base'

class WebrtcXFTV < Sinatra::Base

  SCRIPTS = %w{
    http://code.jquery.com/jquery-1.9.1.min.js
    /js/recorderjs/recorder.js
    /__coffee__/webrtc-xftv.js
  }
  CSS     = %w{ /css/index.css }

  PREFS   = { width: 640, height: 480, fps: 10, secs: 2,
              send_every: 1 }

  XFTV    = 'java -jar ./xftv.jar'
  CONV    = ->(file,w,h,fps) { "#{XFTV} #{file} #{w} #{h} #{fps}" }

  MERGE   = ->(a,v,o) { "ffmpeg -i #{a} -i #{v} -acodec libvorbis" +
                        " -vcodec copy #{o}" }

  LINK    = ->(id) {       "/out/#{id}.webm" }
  VLINK   = ->(id) {       "/out/#{id}-v.webm" }

  OUT     = ->(id) { "public/out/#{id}.webm" }
  AOUT    = ->(id) { "public/out/#{id}-a.wav" }
  VOUT    = ->(id) { "public/out/#{id}-v.webm" }

  REC     = {}  # keep track of recordings

  helpers do
    def mash(data)                                              # {{{1
      case data
        when Array  then  data.map { |x| mash x }
        when Hash   then  Hashie::Mash.new data
        else              data
      end
    end                                                         # }}}1

    def start_recording(w, h, fps)                              # {{{1
      id    = SecureRandom.hex 16       ; tdir  = Dir.mktmpdir
      cmd   = CONV[VOUT[id], w, h, fps] ; io    = IO.popen cmd, 'r+'
      rec   = REC[id] = mash id: id, tdir: tdir, io: io, i: 0
      puts "starting #{rec.to_hash.inspect}"                  #  DEBUG
      { id: id }
    end                                                         # }}}1

    def done_recording_video(rec)                               # {{{1
      # close input! read all output! done!
      rec.io.close_write
      rec.io.each { |line| puts "[conv] #{line}" }              # TODO
      rec.io.close_read
      FileUtils.remove_entry_secure rec.tdir
      rec.video_done = true
      puts 'done recording video.'                            #  DEBUG
    end                                                         # }}}1

    def record(id, images, done = false)                        # {{{1
      rec = REC[id] or raise 'id not found'                     # TODO
      puts "recording video #{rec.to_hash.inspect}"           #  DEBUG
      images.each do |x|
        file = "#{rec.tdir}/#{rec.i}.jpg"
        puts "file:      #{file}"                             #  DEBUG
        puts "timestamp: #{x.timestamp}"                      #  DEBUG
        File.open(file, 'w') do |f|
          f.write Base64.decode64(x.image)
        end
        rec.io.puts file, x.timestamp; rec.i += 1
      end
      done_recording_video(rec) if done
    end                                                         # }}}1

    def merge_audio(id, audio)                                  # {{{1
      rec = REC[id] or raise 'id not found'                     # TODO
      raise 'not done!' unless rec.video_done                   # TODO
      link = if audio
        puts "merging audio #{rec.to_hash.inspect}"           #  DEBUG
        a, v, o = AOUT[id], VOUT[id], OUT[id]
        File.open(a, 'w') do |f|
          f.write Base64.decode64(audio)
        end
        system MERGE[a, v, o] or raise 'merge failed'           # TODO
        LINK[rec.id]
      else
        puts "not merging audio #{rec.to_hash.inspect}"       #  DEBUG
        VLINK[rec.id]
      end
      REC.delete rec.id; { link: link }
    end                                                         # }}}1
  end

  # DEBUG {                                                     # {{{1
  # require 'pp'
  # before /rec/ do
  #   data = mash JSON.parse(params[:data])
  #   data.images.each do |x|
  #     x.image = x.image[0..10] + '...'
  #   end if data.images
  #   puts "--> #{request.path}"; pp data.to_hash
  # end
  # } DEBUG                                                     # }}}1

  get '/' do
    haml :index
  end

  post '/rec/start' do
    data = mash JSON.parse(params[:data])
    args = data.values_at *%w{ width height fps }
    start_recording(*args.map { |x| Integer x }).to_json
  end

  post '/rec/:id/push' do |id|
    data = mash JSON.parse(params[:data])
    record id, data.images; nil
  end

  post '/rec/:id/done' do |id|
    data = mash JSON.parse(params[:data])
    record id, data.images, true; nil
  end

  post '/rec/:id/merge' do |id|
    data = mash JSON.parse(params[:data])
    merge_audio(id, data.audio).to_json
  end

  get '/__coffee__/:name.js' do |name|
    content_type 'text/javascript'
    coffee :"coffee/#{name}"
  end

end

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
