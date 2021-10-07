import 'package:flutter/material.dart';
import 'package:medi_home/dashBoard/dashBoard_physio.dart';
import 'package:medi_home/ble/guidePage.dart';
import 'package:flutter/cupertino.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //밑에 네비게이션 바 부분에 Dashboard와 Bluetooth 연동 페이지 연결
  int _selectedIndex = 0;
  final List<Widget> _children = <Widget>[
    HospitalDashboardHome(), // Dashborad 페이지
    GuidePage(), // Bluetooth 측정을 위한 Guide 페이지
  ];

  void _onItemTapped(int index) {
    //어떤 탭이 선택되었는지 index를 저장하여 확인
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _children.elementAt(_selectedIndex)),
      drawer: Drawer(
        // Appbar에서 뒤로가기 버튼
        child: Column(
          children: <Widget>[
            ListTile(
              leading: CircleAvatar(
                child: Icon(
                  Icons.cached,
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
              title: Text("back"),
              onTap: () {
                // 뒤로가기 버튼 클릭시 /login으로 이동
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // 밑에 네비게이션 바에 관한 디자인
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: Color(0xff6bceff),
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon:
                Icon(CupertinoIcons.waveform_circle, color: Color(0xff6bceff)),
            label: 'Measurement',
          )
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
      ),
    );
  }
}
