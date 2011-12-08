Valve = require 'valvestream'
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
        break if not can_split
        [found, rest] = fn.split(@buffer, pos, cur.length)
        @buffer = rest
        @emit('split', found, cur)
        break if not @enabled or @buffer.length is 0



class BufferStream extends Valve
    constructor: (opts = {}) ->
        if typeof opts is 'string'
            opts = encoding:opts
        # defaults
        opts.size ?= 'none'
        # values
        @size = opts.size
        @splitters = []
        @__defineGetter__ 'length', () => @buffer.length
        # states
        @enabled = on
        #init
        @reset()
        super
        # shortcuts
        if opts.split?
            if isArray(opts.split)
                @split opts.split
            else
                @split opts.split, (data) ->
                    @emit('data', data)
        @disable() if opts.disabled

    getBuffer: () => @buffer
    toString:  () => @buffer.toString()
    setSize: (@size) =>
        @clear() if not @paused and @size is 'none'

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

    ##
    # overwrite Valve::write
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
            @buffer = concat(@buffer, buffer)

        if @size is 'flexible'
            if @enabled
                # we buffer everything
                split.call(this)
                return true # it's safe to immediately write again
            else
                return @clear()

        else if @size is 'none'
            @buffer = split.call(this) if @enabled
            return @clear()

        else # size is a number
            throw new Error("not implemented yet :(") # TODO

    clear: () =>
        return unless @buffer.length
        buffer = @buffer # get before reset
        @reset()
        return @flush buffer # FIXME paused check # <---------------------------

    reset: () =>
        if typeof @size is 'number'
            @buffer = new Buffer(@size)
        else
            @buffer = new Buffer(0)

    # FIXME

    end: (data, encoding) ->
        @write(data, encoding) if data?
        @writable = off
        @finished = yes
        unless @paused
            @clear() # <--------------------------------------------------------
            @emit 'end'
            @emit 'close'

    resume: () ->
        return if not @paused or --@jammed
        @emit 'drain' if @paused
        @paused = no
        @clear() if not @enabled or @size is 'none' or @finished # <------------
        for source in @sources
            source.resume?() if source.readable
        @emit 'resume' if @size is 'none' # <-----------------------------------
        if @finished
            @emit 'end'
            @emit 'close'

# exports

BufferStream.fn = fn
module.exports = BufferStream
