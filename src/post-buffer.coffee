BufferStream = require('./buffer-stream')

class PostBuffer
    constructor: (req, opts = {}) ->
        @callback = null
        @got_all_data = no
        opts.size ?= 'flexible' # recommended
        @stream = new BufferStream(opts)
        req.on 'end', =>
            @got_all_data = yes
            @callback?(@stream.buffer)
        req.pipe(@stream)

    onEnd: (@callback) =>
        @callback(@stream.buffer) if @got_all_data

    pipe: (dest, options) =>
        @stream.pipe(dest, options)
        @stream.setSize('none')
        dest # Allow for unix-like usage: A.pipe(B).pipe(C)

# exports

module.exports = PostBuffer
