{ Stream } = require('stream')
buffertools = require('buffertools')
[isArray, isBuffer] = [Array.isArray, Buffer.isBuffer]
{ min, max } = Math


split = () ->
    return unless @buffer.length
    can_split = @enabled and @splitters.length
    while can_split
        cur = null
        pos = buflen = @buffer.length
        for splitter in @splitters
            continue if buflen < splitter.length
            i = buffertools.indexOf.call(@buffer, splitter)
            if i isnt -1 and i < pos and i < buflen
                cur = splitter
                pos = i
        can_split = cur isnt null
        break if not can_split
        found = new Buffer(min(buflen, pos))
        rest = new Buffer(max(0, buflen - cur.length - pos))
        @buffer.copy(found, 0, 0, min(buflen, pos))
        @buffer.copy(rest, 0, min(buflen, pos + cur.length))
        @buffer = rest
        @emit('split', found, cur)
        break if not @enabled or @buffer.length is 0


class BufferStream extends Stream
    constructor: (opts = {}) ->
        if typeof opts is 'string'
            opts = encoding:opts
        # defaults
        opts.encoding ?= 'utf8'
        opts.size ?= 'none'
        @encoding = opts.encoding
        @size = opts.size
        # states
        @finished = no
        @paused = off
        @enabled = on
        @writable = on
        @readable = on
        # values
        @splitters = []
        @__defineGetter__ 'length', () => @buffer.length
        # init
        @reset()
        @split opts.split, ((data) -> @emit('data', data)) if opts.split?
        super

    getBuffer:   () => @buffer
    toString:    () => @buffer.toString()
    destroySoon: () => @destroy()
    setEncoding: (@encoding) =>
    setSize:     (@size) =>
        @flush() if not @paused and @size is 'none'

    pause:  () =>
        @paused = on
        @emit('pause') if @size is 'none'
    resume: () =>
        @emit('drain') if @paused
        @paused = off
        @emit('resume') if @size is 'none'
        @flush() if not @enabled or @finished
        if @finished
            @emit('end')
            @emit('close')

    enable:  () => @enabled = on
    disable: (args...) =>
        if args.length is 1 and isArray(args[0])
            args = args[0]
        for splitter in args
            i = @splitters.indexOf(splitter)
            continue if i is -1
            @splitters = @splitters.slice(0,i).concat(@splitters.slice(i+1))
            break unless @splitters.length
        unless @splitters.length
            @enabled = off
        unless args.length
            @enabled = off
            @flush() unless @paused

    reset: () =>
        if typeof @size is 'number'
            @buffer = new Buffer(@size)
        else
            @buffer = new Buffer(0)

    flush: () =>
        return unless @buffer.length
        @emit('data', @buffer)
        @reset()

    split: (args...) =>
        if args.length is 1 and isArray(args[0])
            args = args[0]
        if args.length is 2 and typeof args[1] is 'function'
            [splitter, callback] = args
            @splitters.push(splitter)
            return @on 'split', (_, token) ->
                callback.apply(this, arguments) if token is splitter
        @splitters = @splitters.concat(args)

    write: (buffer, encoding) =>
        @emit('error', new Error("Stream is not writable.")) if not @writable
        if isBuffer(buffer)
            # no action required
        else if typeof buffer is 'string'
            buffer = new Buffer(buffer, encoding ? @encoding)
        else @emit('error',
            new Error("Argument should be either a buffer or a string."))

        if @buffer.length is 0
            @buffer = buffer
        else
            @buffer = concat_(@buffer, buffer)

        if @size is 'flexible'
            if @enabled
                split.call(this)
            else
                @flush() unless @paused
            yes # it's safe to immediately write again

        else if @size is 'none'
            @buffer = split.call(this) if @enabled
            if @paused
                no # because the sink is full
            else
                @flush()
                yes # the sink is'nt full yet

        else # size is a number
            throw new Error("not implemented yet :(") # TODO

    end: (buffer, encoding) =>
        @write(buffer, encoding) if buffer
        @writable = off
        @finished = yes
        unless @paused
            @flush() unless @enabled
            @emit('end')
            @emit('close')

    destroy: () =>
        @readable = off
        @writable = off


BufferStream.concat_buffers = concat_ = (args...) ->
    # buffertools.concat returns SlowBuffer D:
    idx = -1
    length = 0
    buffers = []
    for input, i in args
        if Buffer.isBuffer(input)
            idx = i if input.length
            length += input.length
            buffers.push(input)
    return args[idx] if idx isnt -1 and length is args[idx].length
    pos = 0
    result = new Buffer(length)
    for buffer in buffers
        continue unless buffer.length
        buffer.copy(result, pos)
        pos += buffer.length
    result


module.exports = BufferStream
