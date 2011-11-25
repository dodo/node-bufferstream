BufferStream = require '../buffer-stream'
{ isBuffer } = Buffer

module.exports =

    defaults: (æ) ->
        buffer = new BufferStream size:'flexible'

        æ.equal buffer.encoding, 'utf8'
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
        concat = BufferStream.concat_buffers

        b1 = new Buffer "a"
        b2 = new Buffer "bc"
        b3 = new Buffer "def"

        æ.equal concat(b1, b2, b3).toString(), b1 + "" + b2 + "" + b3
        æ.equal concat(    b2, b3).toString(),           b2 + "" + b3
        æ.equal concat(        b3).toString(),                "" + b3
        æ.done()

