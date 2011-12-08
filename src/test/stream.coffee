path = require 'path'
{ createReadStream, readFileSync } = require 'fs'
BufferStream = require '../buffer-stream'
{ isBuffer } = Buffer

module.exports =

    defaults: (æ) ->
        buffer = new BufferStream

        æ.equal buffer.finished, no
        æ.equal buffer.writable, yes
        æ.equal buffer.readable, yes
        æ.equal buffer.size, 'none'

        results = ["123", "bufferstream"]

        buffer.on 'data', (data) -> æ.equal data, results.shift()
        buffer.on 'end', ->
            æ.equal buffer.toString(), ""
            buf = buffer.getBuffer()
            æ.equal isBuffer(buf), true
            æ.equal buffer.length, 0
            æ.equal buf.length, 0
            æ.done()

        buffer.write result for result in Array::slice(results)
        buffer.end()


    '::enable': (æ) ->
        buffer = new BufferStream disabled:yes
        æ.equal "enabled=#{buffer.enabled}", "enabled=false"
        buffer.enable()
        æ.equal "enabled=#{buffer.enabled}", "enabled=true"
        æ.done()


    '::disable': (æ) ->
        buffer = new BufferStream
        æ.equal "enabled=#{buffer.enabled}", "enabled=true"
        buffer.disable()
        æ.equal "enabled=#{buffer.enabled}", "enabled=false"
        æ.done()


    split: (æ) ->
        stream = new BufferStream
            encoding:'utf8'
            size:'flexible'
            split:['//', ':']
        stream.on 'end', æ.done

        results = [
            ["buffer",  ":"]
            ["stream", "//"]
            ["23:42" , "//"]
        ]

        i = 2
        stream.on 'split', (chunk, token) ->
            æ.deepEqual [chunk.toString(), token], results.shift()
            if token is ':' or token is '//' and !(--i)
                stream.disable(token)

        # only one result expected
        stream.on 'data', (chunk) -> æ.equal chunk.toString(), "disabled"

        æ.equal stream.write("buffer:stream//23:42//disabled"), true
        stream.end()


    shortcut: (æ) ->
        stream = new BufferStream size:'flexible', split:'\n'
        stream.on 'end', æ.done

        results = ["a", "bc", "def"]

        stream.on 'data', (chunk) -> æ.equal chunk.toString(), results.shift()
        stream.write "a\nbc\ndef"
        stream.end()


    pipe: (æ) ->
        buffer = new BufferStream split:'\n'
        buffer.on 'data', (data) -> æ.equal data.toString(), readme.shift()
        buffer.on 'end', ->
            æ.equal buffer.length, 0
            æ.equal buffer.toString(), ""
            æ.deepEqual readme, [ "END" ]
            æ.done()

        filename = path.join(__dirname,"..","..","..","README.md")
        readme = "#{readFileSync(filename)}END".split('\n')
        stream = createReadStream filename

        stream.pipe buffer

