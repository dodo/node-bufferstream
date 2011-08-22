BufferStream = require('./buffer-stream')

class PostBuffer
    constructor: (req) ->
        @callback = null
        @got_all_data = no
        @stream = new BufferStream(size:'flexible')
        req.pipe(@stream)
        req.on 'end', =>
            @got_all_data = yes
            @callback?(@stream.buffer)

    onEnd: (@callback) =>
        @callback(@stream.buffer) if @got_all_data

    pipe: (dest) =>
        @stream.pipe(dest)
        @stream.setSize('none')
        dest # Allow for unix-like usage: A.pipe(B).pipe(C)
# exports

module.exports = PostBuffer
