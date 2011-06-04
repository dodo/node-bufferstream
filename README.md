# BufferStream

painless stream buffering, cutting and piping.

## install

make sure you have `node-waf` installed (contained in `nodejs-dev` package).

    npm install bufferstream

## api

BufferStream is a full node.js [Stream](http://nodejs.org/docs/v0.4.7/api/streams.html) so it has apis of both [Writeable Stream](http://nodejs.org/docs/v0.4.7/api/streams.html#writable_Stream) and [Readable Stream](http://nodejs.org/docs/v0.4.7/api/streams.html#readable_Stream).

### BufferStream

    stream = new BufferStream([encoding])
 * `encoding` default encoding for writing strings

### stream.enable

    stream.enable()

enables stream buffering __default__

### stream.disable

    stream.disable()

flushes buffer and disables stream buffering.
BufferStream now pipes all data as long as the output accepting data.
when the output is draining BufferStream will buffer all input temporary.

### stream.split

    stream.split(token, ...)
    stream.split(tokens) // Array
 * `token[s]` buffer splitters (should be String or Buffer)

each time BufferStream finds a splitter token in the input data it will emit a __split__ event.
this also works for binary data.

### Event: 'split'

    stream.on('split', function (chunk, token) {…})
    stream.split(token, function (chunk, token) {…}) // only get called for given token

BufferStream slices its buffer to the first position of on of the splitter tokens and emits it.
this data will be lost when not handled.

__Warning:__ try to avoid calling `buffer.emit('data', data)` more than one time, because this will likely throw `Error: Offset is out of bounds`.

### stream.getBuffer

    stream.getBuffer()
    // or just
    stream.buffer

returns its [Buffer](http://nodejs.org/docs/v0.4.7/api/buffers.html).

### stream.toString

    stream.toString()

shortcut for `stream.buffer.toString()`

## example

    BufferStream = require('bufferstream')
    stream = new BufferStream('utf8')
    stream.split('//', ':')
    stream.on('split', function (chunk, token) {
        console.log("got '%s' by '%s'", chunk.toString(), token.toString())
    })
    stream.write("buffer:stream//23")
    console.log(stream.toString())

results in

    got 'buffer' by ':'
    got 'stream' by '//'
    23

* https://github.com/dodo/node-bufferstream/blob/master/example/split.js
