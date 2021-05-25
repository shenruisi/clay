clay.import("proxy.js");


clayAjax(
         {
            url:"https://www.baidu.com",
            completion:function(response){
                clay.log(response);
            },
         }
);
