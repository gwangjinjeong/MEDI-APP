import 'package:flutter/material.dart';
import 'package:medi_home/ble/blePage.dart';

class GuidePage extends StatelessWidget {
  // 처음 bluetooth페이지 바텀아이콘 클릭시 나오는 화면
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 사용자에게 보여줄 텍스트 설정
            Text(
              '1. 핸드폰 블루투스가 켜져있는지 확인해주세요',
            ),
            Text(
              '',
            ),
            Text(
              '2. MDCW를 켜주세요',
            ),
            Text(
              '',
            ),
            Text(
              '3. 아래 버튼을 눌러 MEDi기기를 찾아주세요',
            ),
            Text(
              '',
            ),
            IconButton(
                //bluetooth 아이콘 클릭시 넘긴다.
                icon: Icon(Icons.bluetooth_sharp),
                onPressed: () {
                  Navigator.of(context).push(
                      // contet가지고 와서 오브젝트를 생성해서 MaterialPageRoute를 통해서 BlePage페이지로 간다.
                      MaterialPageRoute(builder: (context) => BlePage()));
                })
          ],
        ),
      ),
    );
  }
}
