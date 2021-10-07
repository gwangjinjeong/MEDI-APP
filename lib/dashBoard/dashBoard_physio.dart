import 'dart:core';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medi_home/auth/login.dart';

Color primaryColor = Color(0xff6bceff);

class MeasuredData {
  //데이터를 차트 폼에 맞게 형성시키기 위한 클래스
  MeasuredData({this.time, this.bcm});
  final String time;
  final double bcm;
}

extension ExtendedIterable<E> on Iterable<E> {
  // python의 enumerate 함수를 이용하기 위한 함수
  /// 자료형(리스트, 튜플, 문자열)을 입력으로 받아 인덱스와 인덱스의 값을 출력
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }

  void forEachIndexed(void Function(E e, int i) f) {
    var i = 0;
    forEach((e) => f(e, i++));
  }
}

class HospitalDashboardHome extends StatelessWidget {
  const HospitalDashboardHome({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(context),
    );
  }

  Widget _buildAppBar() {
    // 앱의 가장 상단 AppBar 부분
    return AppBar(
      title: Text("Hi $userid ~!"),
      backgroundColor: primaryColor,
      elevation: 0,
      actions: <Widget>[
        Container(
          width: 50,
          alignment: Alignment.center,
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    // 앱의 Body 부분으로 측정데이터 분석결과 Chart가 들어간다.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Flexible(
          flex: 3,
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
              child: ListView(
                children: <Widget>[
                  Text(
                    "Latest Analysis Data",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildCard(context, 'Oxy-hemoglobin'),
                  SizedBox(height: 10),
                  _buildCard(context, 'Deoxy-hemoglobin'),
                  SizedBox(height: 10),
                  _buildCard(context, 'Water'),
                  SizedBox(height: 10),
                  _buildCard(context, 'Fat'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  preprocessingBCM(bcmMap, bcm_name) {
    // 서버로 부터 받은 데이터를 차트로 표현해주는 함수
    List<MeasuredData> chartData = []; //차트에 그릴 데이터를 담는 리스트변수 초기화
    switch (bcm_name) {
      case 'Oxy-hemoglobin':
        var bcm = bcmMap['data'][0]['hbo2'];
        for (int i = 0; i < bcm.length; i++) {
          chartData.add(MeasuredData(time: "$i sec", bcm: bcm[i]));
        }
        break;
      case 'Deoxy-hemoglobin':
        var bcm = bcmMap['data'][0]['hhb'];
        for (int i = 0; i < bcm.length; i++) {
          chartData.add(MeasuredData(time: "$i sec", bcm: bcm[i]));
        }
        break;
      case 'Water':
        var bcm = bcmMap['data'][0]['water'];
        for (int i = 0; i < bcm.length; i++) {
          chartData.add(MeasuredData(time: "$i sec", bcm: bcm[i]));
        }
        break;
      case 'Fat':
        var bcm = bcmMap['data'][0]['fat'];
        for (int i = 0; i < bcm.length; i++) {
          chartData.add(MeasuredData(time: "$i sec", bcm: bcm[i]));
        }
        break;
    }
    return chartData;
  }

  _getData(bcm_name) async {
    // 로그인한 사용자의 userid에 따른 측정데이터를 서버에서 받아와서 출력
    try {
      final String url = "https://mediplatform-lawla.run.goorm.io/user/physio/";
      final String apiAddr = url + userid;
      final response = await http.get(apiAddr);
      Map<String, dynamic> responseJson = json.decode(response.body);

      return responseJson;
    } catch (_) {
      // 어떤에러던 감지시 모든데이터를 각 wavelength 0으로 반환
      return [
        'T000000000000h000000000000h000000000000h000000000000h000000000000h000000000000'
      ];
    }
  }

  Widget _buildCard(context, bcm_name) {
    // 각 차트를 그리는데 쓰이는 함수
    // 참고: https://github.com/syncfusion/flutter-examples/blob/master/lib/samples/chart/cartesian_charts/chart_types/stacked_charts/stacked_line_chart.dart
    return Card(
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: FutureBuilder(
          future: _getData(bcm_name),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != 0) {
              return Container(
                  child: SfCartesianChart(
                      // chart 라이브러리의 SfCartesianChart를 사용한다.
                      plotAreaBorderWidth: 0,
                      title: ChartTitle(text: '$bcm_name'),
                      legend: Legend(isVisible: true),
                      primaryXAxis: CategoryAxis(
                        majorGridLines: MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                          axisLine: AxisLine(width: 0),
                          majorTickLines: MajorTickLines(size: 10)),
                      series: _getineSeries(
                          // 차트에 들어가는 데이터는 서버로부터 데이터 받은 데이터를 입력으로 _getineSeries함수를 호출하여 받는다.
                          preprocessingBCM(snapshot.data, bcm_name)
                              as List<MeasuredData>),
                      tooltipBehavior: TooltipBehavior(enable: true)));
            } else
              return Center(child: CircularProgressIndicator());
          }),
    );
  }

  List<LineSeries<MeasuredData, String>> _getineSeries(
      //각 차트를 맨 위에 설정해둿던 class의 형식에 맞춰서 차트데이터를 반환
      List<MeasuredData> chartData) {
    return <LineSeries<MeasuredData, String>>[
      LineSeries<MeasuredData, String>(
          dataSource: chartData,
          xValueMapper: (MeasuredData bcm, _) => bcm.time,
          yValueMapper: (MeasuredData bcm, _) => bcm.bcm,
          markerSettings: MarkerSettings(isVisible: true)),
    ];
  }
}
