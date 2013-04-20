# --                                                            ; {{{1
#
# File        : webrtc-xftv.rb
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-04-20
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
    /__coffee__/webrtc-xftv.js
  }
  CSS     = %w{ /css/index.css }

  XFTV    = 'java -jar ./xftv.jar'
  CONV    = ->(file,h,w,fps) { "#{XFTV} #{file} #{w} #{h} #{fps}" }

  REC     = {}

  set :server, :thin

  helpers do
    def mash(data)                                              # {{{1
      case data
        when Array  then  data.map { |x| mash x }
        when Hash   then  Hashie::Mash.new data
        else              data
      end
    end                                                         # }}}1

    def start_recording(w, h, fps)                              # {{{1
      id      = SecureRandom.hex 16
      tmpdir  = Dir.mktmpdir
      outfile = "#{tmpdir}/out.webm"
      io      = IO.popen CONV[outfile, w, h, fps], 'r+'
      rec     = REC[id] = mash id: id, tmpdir: tmpdir,
                  outfile: outfile, io: io, i: 0

      puts "[#{id}] starting; #{rec.inspect}"                 #  DEBUG

      { id: id }
    end                                                         # }}}1

    def record(id, images, done)                                # {{{1
      rec = REC[id] or raise 'OOPS'                             # TODO
      images.each do |x|
        file = "#{rec.tmpdir}/#{rec.i}.jpg"

        puts "[#{id}] file: #{file}"                          #  DEBUG
        puts "[#{id}] time: #{x.timestamp}"                   #  DEBUG

        File.open(file, 'w') do |f|
          f.write Base64.decode64(x.image)
        end
        rec.io.puts file, x.timestamp; rec.i += 1
      end
      if done
        puts "[#{id}] done."                                  #  DEBUG

        rec.io.each { |line| } # read all output; done.
        FileUtils.remove_entry_secure rec.tmpdir
      end
    end                                                         # }}}1
  end

  get '/' do
    haml :index
  end

  post '/rec' do
    data = mash JSON.parse(params[:data])
    start_recording(data.width, data.height, data.fps).to_json
  end

  post '/rec/:id' do |id|
    data = mash JSON.parse(params[:data])
    record(id, data.images, data.done).to_json
  end

  get '/__coffee__/:name.js' do |name|
    content_type 'text/javascript'
    coffee :"coffee/#{name}"
  end

end

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
