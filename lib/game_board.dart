import 'package:flutter/material.dart';

class GameBoard extends StatefulWidget {
  GameBoard({Key key}) : super(key: key);

  @override
  _GameBoardState createState() => new _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 20.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _scoreBox('dddd', 'John', 3),
                Text(
                  'VS',
                  style: TextStyle(fontSize: 45.0),
                ),
                _scoreBox('dddd', 'Mary', 5),
              ],
            ),
            Text("John's turn", style: TextStyle(color:Theme.of(context).accentColor, fontSize: 20.0),),
            Expanded(
              child: Container(
                child: Center(child: _playBox()),
              ),
            ),
            _menuButton('PLAY AGAIN', () {})
          ],
        ),
      ),
    );
  }

  _playBox() {
    Color borderColor = Color(0xFF206efe);
    double borderWidth = 4.0;
    Border lrBorder = Border(
        left: BorderSide(color: borderColor, width: borderWidth ),
        right: BorderSide(color: borderColor, width: borderWidth ));
    Border tbBorder = Border(
        top: BorderSide(color: borderColor, width: borderWidth ),
        bottom: BorderSide(color: borderColor, width: borderWidth ));
    Border centreBorder = Border.merge(lrBorder, tbBorder);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _tt(),
            _tt(border: lrBorder),
            _tt(),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _tt(border: tbBorder),
            _tt(border: centreBorder),
            _tt(border: tbBorder),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _tt(),
            _tt(border: lrBorder),
            _tt(),
          ],
        )
      ],
    );
  }

  _tt({border}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(border: border),
        height: 120.0,
        child: Center(
            child: Text(
          'X',
          style: TextStyle(
              fontSize: 65.0, fontWeight: FontWeight.bold,),
        )),
      ),
    );
  }

  _menuButton(String text, onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: SizedBox(
        width: 300.0,
        child: RaisedButton(
            color: Color(0XFFF8D320),
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Text(
                text,
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
            ),
            onPressed: onPressed),
      ),
    );
  }

  _scoreBox(String avatarUrl, String username, int score) {
    return Column(
      children: <Widget>[
        CircleAvatar(
          child: Text(username.substring(0, 1)),
        ),
        Text(
          username,
          style: TextStyle(fontSize: 20.0),
        ),
        Text(
          score.toString(),
          style: TextStyle(color: Theme.of(context).accentColor, fontSize: 30.0),
        ),
      ],
    );
  }
}
