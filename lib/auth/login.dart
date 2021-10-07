import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

String userid; //로그인한 userid를 전역변수로 설정

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginPageState();
  }
}

class Session {
  // 서버와 연결하여 세션을 형성시켜주는 클래스
  Map<String, String> headers = {
    // 헤더 미리 선언
    'Accept': 'application/json',
  };

  Future<dynamic> get(String url) async {
    // 입력된 url을 토대로 이에 대한 응답(response)를 받아와서 반환한다.
    http.Response response = await http.get(Uri.encodeFull(url));
    Map valueMap = json.decode(response.body);
    return valueMap;
  }
}

class _LoginPageState extends State<LoginPage> {
  // 본 페이지를 구성하는 클래스
  String password;
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String url =
        "https://mediplatform-lawla.run.goorm.io/user/"; // 연결할 서버의 groom url를 변수로 지정
    return Scaffold(
      //화면을 구성하는 디자인적인 부분
      body: Container(
        child: ListView(
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 3.5,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xff6bceff), Color(0xff6bceff)],
                  ),
                  borderRadius:
                      BorderRadius.only(bottomLeft: Radius.circular(90))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Spacer(),
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/logo.png',
                      height: 130,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.only(top: 62),
              child: Column(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width / 1.2,
                    height: 45,
                    padding:
                        EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 4),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 5)
                        ]),
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.person,
                          color: Color(0xff6bceff),
                        ),
                        hintText: 'ID',
                      ),
                      onChanged: (text) {
                        userid = text;
                      },
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width / 1.2,
                    height: 45,
                    margin: EdgeInsets.only(top: 32),
                    padding:
                        EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 4),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 5)
                        ]),
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.vpn_key,
                          color: Color(0xff6bceff),
                        ),
                        hintText: 'Password',
                      ),
                      onChanged: (text) {
                        password = text;
                      },
                    ),
                  ),
                  Spacer(),
                  InkWell(
                    onTap: () async {
                      // login버튼을 눌렀을때, 비밀번호가 맞는지 확인하고 맞으면 root 페이지로 넘어가게한다.
                      String newUrl = url + userid + '/' + password;
                      Map response = await new Session().get(newUrl) as Map;
                      if (response["code"] == 200) {
                        Navigator.pushNamed(context, '/');
                      } else {
                        print('wrong password');
                      }
                    },
                    child: Container(
                      height: 45,
                      width: MediaQuery.of(context).size.width / 1.2,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xff6bceff),
                              Color(0xFF00abff),
                            ],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(50))),
                      child: Center(
                        child: Text(
                          'Login'.toUpperCase(),
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
            ),
            InkWell(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Don't you have any account ?"),
                  Text(
                    "Sign Up",
                    style: TextStyle(color: Color(0xff6bceff)),
                  ),
                ],
              ),
              onTap: () {
                Navigator.pushNamed(context,
                    '/signup'); // signup 클릭시 /signup 페이지 즉, 회원가입하는 창으로 넘어간다.
              },
            ),
          ],
        ),
      ),
    );
  }
}
