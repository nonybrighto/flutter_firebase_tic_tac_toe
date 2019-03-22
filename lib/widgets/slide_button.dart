import 'package:flutter/material.dart';

class SlideButton extends AnimatedWidget{

   final Animation<double> animation;
   final Function() onPressed;
   final String text;
  
  SlideButton({Key key, this.animation, this.onPressed, this.text}):super(key:key, listenable:animation);
  
  @override
  Widget build(BuildContext context) {
    return  Transform(
                        transform: Matrix4.translationValues(animation.value * 100.0, 0, 0),
                          child: _menuButton(text, onPressed),
                  );
  }

  _menuButton(String text, onPressed) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 30.0),
    child: SizedBox(
      width: 300.0,
      child: RaisedButton(
          color: Color(0XFFF8D320),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(text, style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),
          ), onPressed: onPressed),
    ),
  );
}
}