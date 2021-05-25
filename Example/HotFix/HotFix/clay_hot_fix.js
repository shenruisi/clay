clayClass("ViewController:UIViewController",{
           viewDidLoad:function(self){
            var s = clay.super(self);
            @s.viewDidLoad();
            @self.view.backgroundColor = UIColor.blueColor();
           }
           });
