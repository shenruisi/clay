# Clay 


Clay用于帮助开发者通过类似原生平台的语法（在语句前添加`@`修饰符）来调用或是创建原生平台的类或是方法，并且支持与javascript进行混编。使得项目获得动态添加模块，损管后热补，内嵌网页调用原生接口等的能力。

Clay for iOS 基于JavascriptCore引擎以及Objective-C运行时。

## 如何运作
### JS端和Native端的实例是如何交互的
js预处理

处理前
```js
////创建Objective-C类
var view = @UIView();
//设置属性
@view.backgroundColor = UIColor.blueColor();
```

处理后
```js
var view = clay.expr('UIView();',{});

clay.expr('view.backgroundColor = UIColor.blueColor();',{"view":(__clay_isFunction(view)?(__js_method_map[("__clay_tmp_func0_a"+view.length)]=view,("__clay_tmp_func0_a"+view.length)):view)}); 
```

Native端弱引用返回到JS中的对象，当clay.expr语句执行时，传入一个{} 里面包含当然作用域中的变量

## 使用方式

### 在JS文件中

```
//创建Objective-C类
var view = @UIView();

//设置属性
@view.backgroundColor = UIColor.blueColor();

//读取属性
var backgroundColor = @view.backgroundColor;

//调用方法
@view.removeFromSuperView();

//自定义类
clayClass("ClayView:UIView",{
            //属性
            createdByClay:{
                set:function(self,yOrN){
                }
            },
            //实例方法 无参数
            sayHello:function(self){
                clay.log("hello clay!");
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
@cView.createdByClay = YES;
@cView.sayHello();
@cView.a("Amy",sayHelloToB:"Ben");
@ClayView.alwaysSayHi();

//自定义协议
clayProtocol("ClayProtocol:NSObject",{
                beginExcuteScript:{},
                processExpr_inFile:{}
             });
             
//引入纯JS文件
clay.require("pure.js");

//引入带有Clay的JS文件
clay.import("withclay.js");
         
```



