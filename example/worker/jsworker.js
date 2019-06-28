
onmessage = function(e) {
    console.log("message?");
    console.log(e.data.port);
    //postMessage("js worker working");
    e.data.port.postMessage("blah?");
}