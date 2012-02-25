fs = require 'fs'
cli = require 'cli'
path = require 'path'
express = require 'express'
{ spawn } = require 'child_process'
BufferStream = require '../buffer-stream'

cli.enable 'status'
cli.setUsage "benchmark [OPTIONS] streamed_filename"

cli.parse
    port:  ['p', 'Listen on this port', 'number', 3000]

cli.main (args, opts) ->
    process.on 'uncaughtException', (err) => @fatal err

    @fatal "path to file required!" unless args.length is 1
    filename = cli.getPath args[0]

    fs.stat filename, (err, stats) =>
        @fatal err if err
        @info "serving #{filename} (#{stats.size}) …"

        server = express.createServer()

        server.get '/', (req, res) =>
            @ok "start streaming …"
            res.header 'Content-Length', stats.size
            cli.progress length = 0

            buffer = new BufferStream size:'flexible', blocking:no
            file = spawn 'cat', [filename] # a wild cat appears!
            #file = {on:(->), stdout:fs.createReadStream(filename)}

            @info "buffer has #{buffer.size} size."

            setTimeout( () =>
                @info "set buffer size to none (buffer.length=#{buffer?.length})"
                buffer?.setSize 'none'
            , 500)

            buffer.on 'data', (chunk) ->
                length += chunk.length
                cli.progress length / stats.size

            buffer.on 'error', (err) =>
                @error "buffer errored: #{err}"

            res.on 'error', (err) =>
                @error "res errored: #{err}"

            file.on 'exit', (code) =>
                @debug "file.stdout exited with code #{code}."

            @debug "start piping."
            buffer.pipe res
            file.stdout.pipe buffer

        server.listen opts.port, 'localhost', () =>
            @ok "server listen on port #{opts.port} …"
            @info "you can now test it with: wget -Otest http://localhost:#{opts.port}/"
