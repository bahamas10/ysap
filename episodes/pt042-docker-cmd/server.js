#!/usr/bin/env node
const http = require("http");

const host = 'localhost';
const port = 8000;


const requestListener = function (req, res) {
    res.setHeader("Content-Type", "application/json");

    if (req.method === 'PUT') {
        // this breaks if a lot of data is pushed at once lmao i hate javascript
        req.on('data', function(chunk) {
            var body = {
                validJson: false,
            };
            console.log('received data: "%s"', chunk);
            try {
                var data = JSON.parse(chunk);
                body.validJson = true;
                body.data = data;
            } catch (err) {
                body.err = err.message;
            }

            res.write(JSON.stringify(body, null, 2) + "\n");
            res.end();
        });
        return;
    }

    res.end();
};

const server = http.createServer(requestListener);
server.listen(port, host, () => {
    console.log(`Server is running on http://${host}:${port}`);
});
