import 'package:flutter/material.dart';
import 'package:medi_home/auth/login.dart';
import 'package:medi_home/auth/signup.dart';
import 'package:medi_home/auth/home.dart';
import 'package:get/get.dart';
import 'package:flutter_config/flutter_config.dart';

void main() async {
  // Get library가 사용이 가능한 app으로 변환시켜주는 함수
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterConfig.loadEnvVariables();
  runApp(GetMaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  // 메인 함수 실행
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MEDi-Home', // 앱의 타이틀은 MEDi-Home으로 설정
      initialRoute: '/login', // 첫 실행시 나타나는 화면은 auth/login.dart를 실행
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) =>
            HomePage(), // 대시보드 화면 경로를 root 로 설정하며 실행시킬 함수 이름은 HomePage()
        '/login': (context) =>
            LoginPage(), // 로그인 화면 경로를 /login으로 설정하며 실행시킬 함수 이름은 LoginPage()
        '/signup': (context) =>
            SignupPage(), // 회원가입 화면 경로를 /signup으로 설정하며 실행시킬 함수 이름은 SignupPage()
      },
    );
  }
}
