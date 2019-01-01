import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/widgets/logo_text.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AuthPage extends StatefulWidget {

  final bool signUp;
  AuthPage(this.signUp,{Key key}) : super(key: key);

  @override
  _AuthPageState createState() => new _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {

  final _formKey = GlobalKey<FormState>();

   TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView(

          children: <Widget>[

              Form(
                key: _formKey,
                child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        LogoText(),
                        SizedBox(height: 30.0,),
                        (widget.signUp)?_authTextField(controller: _usernameController, hintText: 'john_doe', labelText: 'Username', prefixIcon: Icons.supervised_user_circle): Container(),
                        SizedBox(height: 20.0,),
                        _authTextField(controller: _emailController, hintText: 'email@example.com',labelText: 'Email', prefixIcon: Icons.email),
                        SizedBox(height: 20.0,),
                        _authTextField(controller: _passwordController, hintText: 'password@123', labelText: 'Password', prefixIcon: Icons.lock, obscureText: true),
                        SizedBox(height: 20.0,),
                        SizedBox(
                          width: double.infinity,
                          child: RaisedButton(child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Text((widget.signUp)?'SIGN UP':'LOGIN', style: TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold
                            ),),
                          ), onPressed: (){}),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text((widget.signUp)?'Already registered?': 'Need to join ?', style: TextStyle(
                              fontSize: 20.0
                            ),),
                            FlatButton(
                              child: Text((widget.signUp)?'Login':'Sign Up', style: TextStyle(
                                color: Color(0xFF206efe),
                                fontSize: 20.0,
                              ),),
                              onPressed: (){
                                Navigator.of(context).push(MaterialPageRoute(builder:(index)=> AuthPage(!widget.signUp)));
                                
                              },
                            )
                          ],
                        ),
                        SizedBox(height: 10.0,),
                        _socialLoginBox()

                      ],

                ),
              )
            
          ],
        ),
      ),
    );
  }

  _socialLoginBox(){

    return Row(mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // CircleAvatar(
        //   child: Icon(Icons.subway),
        // )
        _socialIconButton(icon:FontAwesomeIcons.facebookF, color: Colors.blue, onTap:(){}),
        SizedBox(width: 10.0,),
        _socialIconButton(icon:FontAwesomeIcons.googlePlusG, color: Colors.red, onTap:(){})
      ],
    );
  }

  _socialIconButton({IconData icon, Function onTap, Color color}){

    return InkWell(
          child: CircleAvatar(
            backgroundColor: color,
        child: Icon(icon),
      ),
      onTap: onTap,
    );
  }

  _authTextField({TextEditingController controller, String hintText, String labelText, bool obscureText:false, IconData prefixIcon}){
  return TextFormField(
                        controller: controller,
                        obscureText: obscureText,
                        decoration:  InputDecoration(
                          hintText: hintText,
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 22.0
                          ),
                          labelText: labelText,
                          labelStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 23.0
                          ),
                          prefixIcon: Icon(prefixIcon, color: Theme.of(context).hintColor,),
                          prefixStyle: TextStyle(
                            color: Colors.red
                          )
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.0
                        ),
                      );
}
}

