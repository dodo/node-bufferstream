
var BufferStream = require('./bufferstream');

console.log("new stream");
stream = new BufferStream({size:'flexible', split:'\n'});
stream.on('data', function (data) {console.log("data:"+ data)})

setTimeout(function () {
    console.log("write data");
    stream.write("asd");
    stream.write("123\n456");
}, 123)
