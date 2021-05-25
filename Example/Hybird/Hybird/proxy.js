clay.import("net.js");

function clayAjax(d){
    var url = d["url"];
    var completion = d["completion"];
    @SimpleHttp.request(url,onCompletion:completion);
}
