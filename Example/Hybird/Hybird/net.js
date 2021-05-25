clayClass("SimpleHttp:NSObject",{
          request_onCompletion:function(url,onCompletion){
            var request = @NSMutableURLRequest(initWithURL:NSURL(initWithString:url));
            @request.setHTTPMethod("GET");
            var completion = function(data,response,error){
                onCompletion(response);
            }
            @NSURLSession.sharedSession().dataTaskWithRequest(request,completionHandler:completion).resume();
          }
          });
