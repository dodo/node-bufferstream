path = require 'path'
{ createReadStream, readFileSync } = require 'fs'
BufferStream = require '../'
{ isBuffer } = Buffer

module.exports =

    defaults: (æ) ->
        buffer = new BufferStream size:'flexible'

        æ.equal buffer.length, 0

        results = ["123", "bufferstream", "a", "bc", "def"]

        # only one result expected
        buffer.on 'data', (data) ->
            æ.equal data.toString(), results.join("")

        buffer.on 'end', ->
            æ.equal buffer.toString(), ""
            buf = buffer.getBuffer()
            æ.equal isBuffer(buf), true
            æ.equal buffer.length, 0
            æ.equal buf.length, 0
            æ.done()

        buffer.write result for result in Array::slice(results)
        buffer.end()


    concat: (æ) ->
        concat = BufferStream.fn.concat

        b1 = new Buffer "a"
        b2 = new Buffer "bc"
        b3 = new Buffer "def"

        æ.equal concat(b1, b2, b3).toString(), b1 + "" + b2 + "" + b3
        æ.equal concat(    b2, b3).toString(),           b2 + "" + b3
        æ.equal concat(        b3).toString(),                "" + b3
        æ.done()


    split: (æ) ->
        stream = new BufferStream
            encoding:'utf8'
            size:'flexible'
            split:['//', ':']
        stream.on 'end', ->
            æ.equal stream.finished, yes
            æ.equal i, 0
            æ.done()

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

        æ.equal stream.writable, yes
        æ.equal stream.size, 'flexible'
        æ.equal stream.write("buffer:stream//23:42//disabled"), true
        stream.end()


    pipe: (æ) ->
        buffer = new BufferStream size:'flexible'
        buffer.on 'data', (data) -> throw 'up'
        buffer.on 'end', ->
            æ.equal buffer.enabled, yes
            æ.equal "#{buffer.toString()}END", readme
            æ.done()

        filename = path.join(__dirname,"..","README.md")
        readme = "#{readFileSync(filename)}END"
        stream = createReadStream filename

        stream.pipe buffer


    drainage: (æ) ->
        buffer = new BufferStream
            size:'flexible'
            disabled:yes
        buffer.on 'data', (data) -> æ.equals results.shift(), data.toString()
        buffer.on 'end', ->
            æ.equals 0, results.length
            æ.done()
        results = [
            "foo"
            "barbaz"
            "chaos"
        ]

        buffer.write "foo"
        æ.equals 0, buffer.length
        buffer.pause()
        buffer.write "bar"
        buffer.write "baz"
        buffer.resume()
        æ.equals 0, buffer.length
        buffer.write "chaos"
        æ.equals 0, buffer.length
        buffer.end()



