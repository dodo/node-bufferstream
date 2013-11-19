{ Stream } = require 'stream'
fn = require './fn'
[isArray, isBuffer] = [Array.isArray, Buffer.isBuffer]


split = () ->
    return unless @buffer.length
    can_split = @enabled and @splitters.length
    while can_split
        cur = null
        pos = buflen = @buffer.length
        for splitter in @splitters
            continue if buflen < splitter.length
            i = fn.indexOf.call(@buffer, splitter)
            if i isnt -1 and i < pos and i < buflen
                cur = splitter
                pos = i
        can_split = cur isnt null
        break unless can_split
        [found, rest] = fn.split(@buffer, pos, cur.length)
        @buffer = rest
        @emit('split', found, cur)
        break if @paused or not @enabled or @buffer.length is 0



class BufferStream extends Stream
    constructor: (opts = {}) ->
        if typeof opts is 'string'
            opts = encoding:opts
        # defaults
        opts.size     ?= 'none'
        opts.encoding ?= null
        opts.blocking ?= yes
        # values
        @size = opts.size
        @blocking = opts.blocking
        @splitters = []
        @__defineGetter__ 'length', () => @buffer.length
        @setEncoding(opts.encoding)
        # states
        @enabled  = on
        @writable = on
        @readable = on
        @finished = off
        @paused   = off
        #init
        @reset()
        super()
        # shortcuts
        if opts.split?
            if isArray(opts.split)
                @split opts.split
            else
                @split opts.split, (data) ->
                    @emit('data', data)
        @disable() if opts.disabled

    getBuffer: () => @buffer
    toString:     => @buffer.toString(arguments...)
    setEncoding: (@encoding) =>
    setSize: (@size) =>
        @clear() if not @paused and @size is 'none'

    enable:  () => @enabled = on
    disable: (args...) =>
        if args.length is 1 and isArray(args[0])
            args = args[0]
        for splitter in args
            i = @splitters.indexOf(splitter)
            continue if i is -1
            @splitters.splice(i, 1)
            break unless @splitters.length
        unless @splitters.length
            @enabled = off
        unless args.length
            @enabled = off
            @clear() unless @paused

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
        unless @writable
            @emit 'error', new Error("Stream is not writable.")
            return false

        if isBuffer(buffer)
            # no action required
        else if typeof buffer is 'string'
            buffer = new Buffer(buffer, encoding ? @encoding)
        else @emit('error',
            new Error("Argument should be either a buffer or a string."))

        if @buffer.length is 0
            @buffer = buffer
        else
            @buffer = fn.concat(@buffer, buffer)

        return false if @paused

        if @size is 'none'
            split.call(this) if @enabled
            return @clear()

        else if @size is 'flexible'
            # we buffer everything
            split.call(this) if @enabled
            if @finished # currently finishing
                return @clear()

            if @blocking
                @clear() unless @enabled
                return true # it's safe to immediately write again
            else
                # prevent write calls from blocking the whole process
                process.nextTick =>
                    @emit 'drain'
                return false


        else # size is a number
            throw new Error("not implemented yet :(") # TODO

    clear: () =>
        return true unless @buffer.length
        buffer = @buffer # get before reset
        @reset()
        @emit 'data', buffer # sync call
        return not @paused # can be changed after emit('data', data)

    reset: () =>
        if typeof @size is 'number'
            @buffer = new Buffer(@size)
        else
            @buffer = new Buffer(0)

    pause: () ->
        return if @paused
        @paused = yes
        @emit 'pause'

    resume: () ->
        return unless @paused
        @paused = no
        split.call(this)
        return if @paused # can be changed during split
        if not @enabled or @size is 'none' or @finished
            return unless @clear()
        @emit 'drain'
        @emit 'resume' if @size is 'none'
        if @finished
            @emit 'end'
            @emit 'close'

    end: (data, encoding) ->
        return if @finished
        @finished = yes # we give write the change to eg clear the buffer
        @write(data, encoding) if data?
        @writable = off
        unless @paused
            @emit 'end'
            @emit 'close'

# exports

BufferStream.fn = fn
module.exports = BufferStream
