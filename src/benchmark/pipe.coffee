fs = require 'fs'
cli = require 'cli'
path = require 'path'
express = require 'express'
{ spawn } = require 'child_process'
BufferStream = require '../buffer-stream'

cli.enable 'status'
cli.setUsage "pipe-benchmark [OPTIONS] filename"

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

            buffer = new BufferStream 'binary'
            file = spawn 'cat', [filename]

            file.stdout.pipe buffer
            buffer.pipe res

            do buffer.disable
            buffer.on 'data', (chunk) ->
                length += chunk.length
                cli.progress length / stats.size


        server.listen opts.port, 'localhost', () =>
            @ok "server listen on port #{opts.port} …"
            @info "you can now test it with: wget -Otest http://localhost:#{opts.port}/"
