var BufferStream = require('../bufferstream');


var stream = new BufferStream('utf8');
stream.split('//', ':');

var i = 2;
stream.on('split', function (chunk, token) {
    console.log("got '%s' by '%s'", chunk.toString(), token.toString());
    if (token === ':'  || (token === '//' && !--i)) stream.disable(token);
});

stream.write("buffer:stream//23:42//disabled");
console.log(stream.toString());