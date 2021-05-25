////创建Objective-C类
var view = @UIView();
//设置属性
@view.backgroundColor = UIColor.blueColor(); //test

//读取属性
var backgroundColor = @view.backgroundColor/*test*/;
/*This is
 a test
 */
//调用方法
@view.removeFromSuperview();

//自定义类
clayClass("ClayView:UIView",{
          b:function(self){
          },
            //实例方法 有参数
            a_sayHelloToB:function(self,i,you){
                clay.log(
                         @NSString(initWithFormat:"hello %@,I\'m %@",you,i)
                        );
            },
            //静态方法
            alwaysSayHi:function(){
                clay.log("hi clay!");
            }
          });

var cView = @ClayView();
@cView.b();
@cView.a("Amy",sayHelloToB:"Ben");
@ClayView.alwaysSayHi();

//自定义协议
clayProtocol("ClayProtocol:NSObject",{
                beginExcuteScript:{},
                processExpr_inFile:{}
             });


