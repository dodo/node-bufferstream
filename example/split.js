var BufferStream = require('../bufferstream');


var stream = new BufferStream({encoding:'utf8', size:'flexible'});
console.log("stream size is", stream.size);

stream.split('//', ':');

var i = 2;
stream.on('split', function (chunk, token) {
    console.log("got '%s' by '%s'", chunk.toString(), token.toString());
    if (token === ':'  || (token === '//' && !--i)) stream.disable(token);
});

console.log("writing stream is",
            stream.write("buffer:stream//23:42//disabled") && "ok" || "failed");

console.log("stream content:", stream.toString());