var BufferStream = require('../bufferstream');


var stream = new BufferStream('utf8');
stream.split('//', ':');

stream.on('split', function (chunk, token) {
    console.log("got '%s' by '%s'", chunk.toString(), token.toString());
});

stream.write("buffer:stream//23");
console.log(stream.toString());