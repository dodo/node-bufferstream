{ Stream } = require('stream')
buffertools = require('buffertools')
[isArray, isBuffer] = [Array.isArray, Buffer.isBuffer]
{ min, max } = Math


split = () ->
    return unless @buffer.length
    can_split = yes
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
    constructor: (@encoding = 'utf8') ->
        @finished = no
        @paused = off
        @enabled = on
        @writable = on
        @readable = on
        @splitters = []
        @buffer = new Buffer(0)
        @__defineGetter__ 'length', () => @buffer.length
        super

    getBuffer:   () => @buffer
    toString:    () => @buffer.toString()
    destroySoon: () => @destroy()
    setEncoding: (@encoding) =>

    pause:  () =>
        @paused = on
        @emit('pause')
    resume: () =>
        @paused = off
        @emit('resume')
        @flush() unless @enabled
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
        unless args.length and @splitters.length
            @enabled = off
            @flush() unless @paused


    flush: () =>
        return unless @buffer.length
        @emit('data', @buffer)
        @buffer = new Buffer(0)

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

        if @enabled or @paused
            @buffer = concat_(@buffer, buffer)
            split.call(this) if @enabled and @splitters.length
        else if not @paused
            @emit('data', buffer)
        yes # it's safe to immediately write again

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
