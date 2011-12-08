isBuffer = Buffer.isBuffer
{ min, max } = Math

{ indexOf:exports.indexOf } = require 'buffertools'

exports.concat = (args...) ->
    # buffertools.concat returns SlowBuffer D:
    idx = -1
    length = 0
    buffers = []
    for input, i in args
        if isBuffer(input)
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

exports.split = (buffer, pos, offset = 0) ->
        buflen = buffer.length
        found = new Buffer(min(buflen, pos))
        rest = new Buffer(max(0, buflen - pos - offset))
        buffer.copy(found, 0, 0, min(buflen, pos))
        buffer.copy(rest, 0, min(buflen, pos + offset))
        return [found, rest]

