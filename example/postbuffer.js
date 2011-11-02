var http = require('http'),
    PostBuffer = require('../postbuffer');

http.createServer(function(req, res) {
    var postHandler = new PostBuffer(req);
    postHandler.onEnd(function(data) {
        console.log('Data:', data.toString());
        process.exit();
    });
}).listen(3000, function ready() {
    var request = http.request({ port: 3000, method: 'POST' });
    request.end(new Buffer('teststring'));
});
