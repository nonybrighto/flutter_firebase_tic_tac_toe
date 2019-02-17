import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/auth_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/bloc_provider.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/user_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/menu_page.dart';
import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:flutter_firebase_tic_tac_toe/models/auth.dart';
import 'package:flutter_firebase_tic_tac_toe/models/bloc_completer.dart';
import 'package:flutter_firebase_tic_tac_toe/models/load_status.dart';
import 'package:flutter_firebase_tic_tac_toe/services/user_service.dart';
import 'package:flutter_firebase_tic_tac_toe/utils/validator.dart';
import 'package:flutter_firebase_tic_tac_toe/widgets/logo_text.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AuthPage extends StatefulWidget {
  final bool signUp;
  AuthPage(this.signUp, {Key key}) : super(key: key);

  @override
  _AuthPageState createState() => new _AuthPageState();
}

class _AuthPageState extends State<AuthPage> implements BlocCompleter<User> {
  final _formKey = GlobalKey<FormState>();
  Validator _validator;
  BuildContext _context;

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  AuthBloc _authBloc;
  UserBloc _userBloc;

  bool signUp = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _authBloc = AuthBloc(new UserService(), this);
    _validator = Validator();
    signUp = widget.signUp;
  }

  @override
  Widget build(BuildContext context) {
    _userBloc = BlocProvider.of(context).userBloc;
    return Scaffold(
      body: Builder(
        builder: (context) {
          _context = context;
          return Padding(
            padding: const EdgeInsets.all(15.0),
            child: ListView(
              children: <Widget>[
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      LogoText(),
                      SizedBox(
                        height: 30.0,
                      ),
                      (signUp)
                          ? _authTextField(
                              controller: _usernameController,
                              hintText: 'john_doe',
                              labelText: 'Username',
                              prefixIcon: Icons.supervised_user_circle,
                              validator: _validator.usernameValidator)
                          : Container(),
                      SizedBox(
                        height: 20.0,
                      ),
                      _authTextField(
                          controller: _emailController,
                          hintText: 'email@example.com',
                          labelText: 'Email',
                          prefixIcon: Icons.email,
                          validator: _validator.emailValidator),
                      SizedBox(
                        height: 20.0,
                      ),
                      _authTextField(
                          controller: _passwordController,
                          hintText: 'password@123',
                          labelText: 'Password',
                          prefixIcon: Icons.lock,
                          obscureText: true,
                          validator: _validator.passwordValidator),
                      SizedBox(
                        height: 20.0,
                      ),
                      StreamBuilder(
                        initialData: LoadStatus.loaded,
                        stream: _authBloc.loadStatus,
                        builder: (context, snapshot) {
                          final loadStatus = snapshot.data;
                          return SizedBox(
                            width: double.infinity,
                            child: RaisedButton(
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: (loadStatus == LoadStatus.loading)
                                      ? CircularProgressIndicator()
                                      : Text(
                                          (signUp) ? 'SIGN UP' : 'LOGIN',
                                          style: TextStyle(
                                              fontSize: 22.0,
                                              fontWeight: FontWeight.bold),
                                        ),
                                ),
                                onPressed: (loadStatus == LoadStatus.loading)
                                    ? null
                                    : () {
                                        if (_formKey.currentState.validate()) {
                                          if (signUp) {
                                            _authBloc.signUp(
                                                _usernameController.text,
                                                _emailController.text,
                                                _passwordController.text);
                                          } else {
                                            _authBloc.login(
                                                _emailController.text,
                                                _passwordController.text);
                                          }
                                        }
                                      }),
                          );
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            (signUp)
                                ? 'Already registered?'
                                : 'Need to join ?',
                            style: TextStyle(fontSize: 20.0),
                          ),
                          FlatButton(
                            child: Text(
                              (signUp) ? 'Login' : 'Sign Up',
                              style: TextStyle(
                                color: Color(0xFF206efe),
                                fontSize: 20.0,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                               signUp = !signUp; 
                              });
                            },
                          )
                        ],
                      ), 
                      SizedBox(
                        height: 10.0,
                      ),
                      _socialLoginBox()
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  _socialLoginBox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _socialIconButton(
            icon: FontAwesomeIcons.facebookF,
            color: Colors.blue,
            onTap: () {
              _authBloc.loginWithSocial(SocialLoginType.facebook);
            }),
        SizedBox(
          width: 10.0,
        ),
        _socialIconButton(
            icon: FontAwesomeIcons.googlePlusG,
            color: Colors.red,
            onTap: () {
              _authBloc.loginWithSocial(SocialLoginType.google);
            })
      ],
    );
  }

  _socialIconButton({IconData icon, Function onTap, Color color}) {
    return InkWell(
      child: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon),
      ),
      onTap: onTap,
    );
  }

  _authTextField(
      {TextEditingController controller,
      String hintText,
      String labelText,
      Function validator,
      bool obscureText: false,
      IconData prefixIcon}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey, fontSize: 22.0),
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.white70, fontSize: 23.0),
          prefixIcon: Icon(
            prefixIcon,
            color: Theme.of(context).hintColor,
          ),
          prefixStyle: TextStyle(color: Colors.red)),
      style: TextStyle(color: Colors.white, fontSize: 22.0),
    );
  }

  @override
  completed(user) {
    _userBloc.changeCurrentUser(user);
    Navigator.of(context).push((MaterialPageRoute(builder:(context) => MenuPage())));
  }

  @override
  error(error) {
    Scaffold.of(_context).showSnackBar(SnackBar(
      content: Text('Error: ' + error.message),
    ));
  }
}
