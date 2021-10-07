import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:medi_home/auth/login.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

String postValue; //
Color primaryColor = Color(0xff6bceff);

class BlePage extends StatefulWidget {
  //메인함수 실행
  final String title;
  BlePage({Key key, this.title}) : super(key: key);

  @override
  _BlePage createState() => _BlePage();
}

class _BlePage extends State<BlePage> {
  BleManager _bleManager = BleManager(); //BLE 라이브러리에서 BLE 매니저 가지고 옴
  bool _isScanning = false; //스캔 확인을 위한 bool 변수
  bool _connected = false; // 연결 확인을 위한 bool 변수
  Peripheral _curPeripheral; // 연결된 장치를 컨트롤 하기위한 변수
  List<String> stringValue = [];
  List<BleDeviceItem> deviceList = []; //BLE 정보 저장용
  String _statusText = ''; // BLE 상태 변수
  double agcmonPD1; //flowchart 참고
  double agcmonPD2;
  double agcmonPD3;
  double agcDPPD1;
  double agcDPPD2;
  double agcDPPD3;
  double gainPD1temp;
  double gainPD2temp;
  double gainPD3temp;
  double gainPD1temp2;
  double gainPD2temp2;
  double gainPD3temp2;
  double gainPD1;
  double gainPD2;
  double gainPD3;

  //Nordic 설정
  static const String BLE_SERVICE_UUID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String BLE_RX_CHARACTERISTIC =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
  static const String BLE_TX_CHARACTERISTIC =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  @override
  void initState() {
    init();
    super.initState();
  }

  bool chgMode(bool mode) {
    return !mode;
  }

  void setBLEState(txt) {
    // 상태 변경하면서 페이지도 갱신하는 함수
    setState(() => _statusText = txt);
  }

  // BLE 초기화 함수
  void init() async {
    //BLE 매니저 생성
    await _bleManager
        .createClient(
            restoreStateIdentifier: "example-restore-state-identifier",
            restoreStateAction: (peripherals) {
              peripherals?.forEach((peripheral) {
                print("Restored peripheral: ${peripheral.name}");
              });
            })
        .catchError((e) => print("Couldn't create BLE client  $e"))
        .then((_) => _checkPermissions()) //BLE 생성 후 권한 체크
        .catchError((e) => print("Permission check error $e"));
  }

  //권한 체크, 없다면 퍼미면 동의 화면 출력 (for android)
  _checkPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.contacts.request().isGranted) {}
      Map<Permission, PermissionStatus> statuses =
          await [Permission.location].request();
      print(statuses[Permission.location]);
    }
  }

  //스캔 ON/OFF
  void scan() async {
    if (!_isScanning) {
      deviceList.clear(); //기존 장치 리스트 초기화
      //SCAN 시작
      // listen 이벤트 형식으로 장치가 발견되면 해당 루틴을 계속 탄다.
      _bleManager.startPeripheralScan().listen((scanResult) {
        // Peripheral.name 항목에 이름이 있으면 그걸 사용하고
        // 없다면 Advertiesement Data의 이름을 사용하고 그것 마져 없으면 Unknown으로 표시
        var name = scanResult.peripheral.name ??
            scanResult.advertisementData.localName ??
            "Unknown";

        // 기존에 존재하는 장치인지 mac 주소로 확인
        var findDevice = deviceList.any((element) {
          if (element.peripheral.identifier ==
              scanResult.peripheral.identifier) {
            //이미 존재하면 기존 값을 갱신.
            element.peripheral = scanResult.peripheral;
            element.advertisementData = scanResult.advertisementData;
            element.rssi = scanResult.rssi;
            return true;
          }
          return false;
        });
        //처음 발견된 장치라면 devicelist에 추가
        if (!findDevice) {
          deviceList.add(BleDeviceItem(name, scanResult.rssi,
              scanResult.peripheral, scanResult.advertisementData));
        }
        //갱신 적용.
        setState(() {});
      });
      //BLE상태가 변경되면 스캔중으로 변수 변경
      setState(() {
        _isScanning = true;
        setBLEState('Scanning');
      });
    } else {
      //스캔중이었다면 스캔 정지
      _bleManager.stopPeripheralScan();
      setState(() {
        _isScanning = false;
        setBLEState('Stop');
      });
    }
  }

  //디바이스 리스트 화면에 출력
  list() {
    return ListView.builder(
      itemCount: deviceList.length,
      itemBuilder: (context, index) {
        return ListTile(
            //디바이스 이름과 맥주소 그리고 신호 세기를 표시한다.
            title: Text(deviceList[index].deviceName),
            subtitle: Text(deviceList[index].peripheral.identifier),
            trailing: Text("${deviceList[index].rssi}"),
            onTap: () {
              // 리스트중 한개를 탭(터치) 하면 해당 디바이스와 연결을 시도한다.
              connect(index);
            });
      },
    );
  }

  //BLE 연결시 예외 처리를 위한 함수
  _runWithErrorHandling(runFunction) async {
    try {
      await runFunction();
    } on BleError catch (e) {
      print("BleError caught: ${e.errorCode.value} ${e.reason}");
    } catch (e) {
      if (e is Error) {
        debugPrintStack(stackTrace: e.stackTrace);
      }
      print("${e.runtimeType}: $e");
    }
  }

  writeCommand(message) {
    // 명령어 보낼때
    String command = message + "\n";

    _curPeripheral?.writeCharacteristic(BLE_SERVICE_UUID, BLE_TX_CHARACTERISTIC,
        Uint8List.fromList(command.codeUnits), false);
  }

  Future<Map<String, dynamic>> postRequest(String userid, String bcm,
      double gainPD1, double gainPD2, double gainPD3) async {
    var baseURL = "https://mediplatform-lawla.run.goorm.io/user/bcm";
    final body = {
      'userid': userid,
      'bcmdata': bcm,
      'gainPD1': gainPD1,
      'gainPD2': gainPD2,
      'gainPD3': gainPD3
    };
    http.Response response = await http.post(
      baseURL,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode(body),
    );
    return json.decode(response.body);
  }

  readCommand(List valueList) async {
    //선택한 캐리터리스틱의 BLE로 부터 값들 모니터링 ON 함수
    var characteristicUpdates = _curPeripheral.monitorCharacteristic(
        BLE_SERVICE_UUID, BLE_RX_CHARACTERISTIC);

    //데이터 받는 리스너 핸들 변수
    StreamSubscription monitoringStreamSubscription;

    //이미 리스너가 있다면 취소
    await monitoringStreamSubscription?.cancel();
    monitoringStreamSubscription = characteristicUpdates.listen(
      (value) {
        print(value);
        print("read data : ${value.value}"); //데이터 출력

        valueList.addAll(value.value);
        print(valueList);
      },
      onError: (error) {
        print("Error while monitoring characteristic \n$error"); //실패시
      },
      cancelOnError: true, //에러 발생시 자동으로 listen 취소
    );
    return valueList;
  }

  setNotiCommand() {}
  // 연결 함수
  connect(index) async {
    if (_connected) {
      //이미 연결상태면 연결 해제후 종료
      await _curPeripheral?.disconnectOrCancelConnection();
      return;
    }

    // 선택한 장치의 peripheral 값을 가져온다.
    Peripheral peripheral = deviceList[index].peripheral;
    // 해당 장치와의 연결상태를 관찰하는 리스너 실행
    peripheral
        .observeConnectionState(emitCurrentValue: true)
        .listen((connectionState) {
      // 연결상태가 변경되면 해당루틴을 탄다.
      switch (connectionState) {
        case PeripheralConnectionState.connected:
          {
            //연결된경우
            _curPeripheral = peripheral;
            print('$_curPeripheral');
            setBLEState('connected');
            _bleManager.stopPeripheralScan();
            setState(() {
              _isScanning = false;
              setBLEState('Stop');
            });
          }
          break;
        case PeripheralConnectionState.connecting:
          {
            setBLEState('connecting');
          }
          break;
        case PeripheralConnectionState.disconnected:
          {
            _connected = false;
            print('${peripheral.name} has Disconnected');
            setBLEState('disconnected');
          }
          break;
        case PeripheralConnectionState.disconnecting:
          {
            setBLEState('disconnectiong');
          }
          break;
        default:
          {
            print("Unknown the state of connection: \n $connectionState");
          }
          break;
      }
    });
    _runWithErrorHandling(() async {
      //해당 장치와 이미 연결되어 있는지 확인
      bool isConnected = await peripheral.isConnected();
      if (isConnected) {
        print('device is already connected');
        //이미 연결되어 있기때문에 무시하고 종료..
        return;
      }
      await peripheral.connect().then((_) {
        //연결이 되면 장치의 모든 서비스와 캐릭터리스틱을 검색한다.
        peripheral
            .discoverAllServicesAndCharacteristics()
            .then((_) => peripheral.services())
            .then((services) async {
          print("PRINTING SERVICES for ${peripheral.name}");

          //각각의 서비스의 하위 캐릭터리스틱 정보를 디버깅창에 표시한다.
          for (var service in services) {
            print("Found service ${service.uuid}");
            List<Characteristic> characteristics =
                await service.characteristics();
            for (var characteristic in characteristics) {
              print("${characteristic.uuid}");
            }
          }
          //모든 과정이 마무리되면 연결되었다고 표시
          _connected = true;
          print("${peripheral.name} has CONNECTED");
        });
      });
    });
  }

  // 페이지 구성
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("State : $_statusText"),
        backgroundColor: primaryColor,
        actions: <Widget>[
          ElevatedButton(
              //scan 버튼
              onPressed: scan,
              child: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
              style: ElevatedButton.styleFrom(primary: primaryColor)),
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  //상태 정보 표시
                  ElevatedButton(
                    onPressed: () async {
                      // adjust 버튼을 누르면 실행되는 명령어들
                      var templist01 = [];
                      var templist02 = [];
                      var garbagelist = [];
                      garbagelist = await readCommand(garbagelist);
                      await writeCommand("Sg0");
                      await Future.delayed(Duration(seconds: 1));

                      await writeCommand("Sf1");
                      await Future.delayed(Duration(seconds: 1));
// Switch PD1
                      await writeCommand("Se2");
                      await Future.delayed(Duration(seconds: 1));
                      templist01 = await readCommand(templist01);
                      await writeCommand("Si");
                      await Future.delayed(Duration(seconds: 1));
                      // print('templist01');
                      templist01.forEach((ascii) {
                        if (ascii != 10) {
                          String temp = String.fromCharCode(ascii);
                          templist02.add(temp);
                        }
                      });
                      int endlist = templist02.length;
                      print(templist02);
                      print(templist02.sublist(endlist - 4, endlist));
                      int pd1 = int.parse(
                          templist02
                              .sublist(endlist - 4, endlist)
                              .join("")
                              .toString(),
                          radix: 16);
                      print('pd1');
                      print(pd1);
                      agcmonPD1 = pd1 * 3.3 / 4095;
                      if (agcmonPD1 > 1.1)
                        agcmonPD1 = 1.1;
                      else if (agcmonPD1 <= 0.7) agcmonPD1 = 0.7;
                      agcDPPD1 = (agcmonPD1 * 1934.167 - 412) /
                          (-1 * 26.04167 * agcmonPD1 + 39.0625);
// Switch PD2
                      templist01 = [];
                      templist02 = [];
                      garbagelist = await readCommand(garbagelist);
                      await writeCommand("Se1");
                      await Future.delayed(Duration(seconds: 1));
                      templist01 = await readCommand(templist01);
                      await Future.delayed(Duration(seconds: 1));
                      await writeCommand("Si");
                      await Future.delayed(Duration(seconds: 1));
                      templist01.forEach((ascii) {
                        if (ascii != 10) {
                          String temp = String.fromCharCode(ascii);
                          templist02.add(temp);
                        }
                      });
                      endlist = templist02.length;
                      print(templist02.sublist(endlist - 4, endlist));
                      int pd2 = int.parse(
                          templist02
                              .sublist(endlist - 4, endlist)
                              .join("")
                              .toString(),
                          radix: 16);
                      print(pd2);
                      agcmonPD2 = pd2 * 3.3 / 4095;
                      if (agcmonPD2 > 1.1)
                        agcmonPD2 = 1.1;
                      else if (agcmonPD2 <= 0.5) agcmonPD2 = 0.5;
                      agcDPPD2 = (agcmonPD2 * 1934.167 - 412) /
                          (-26.04167 * agcmonPD2 + 39.0625);
// Switch PD3
                      templist01 = [];
                      templist02 = [];
                      garbagelist = await readCommand(garbagelist);
                      await writeCommand("Se1");
                      await Future.delayed(Duration(seconds: 1));
                      templist01 = await readCommand(templist01);
                      await Future.delayed(Duration(seconds: 1));
                      await writeCommand("Si");
                      await Future.delayed(Duration(seconds: 1));
                      templist01.forEach((ascii) {
                        if (ascii != 10) {
                          String temp = String.fromCharCode(ascii);
                          templist02.add(temp);
                        }
                      });
                      endlist = templist02.length;
                      print(templist02.sublist(endlist - 4, endlist));
                      int pd3 = int.parse(
                          templist02
                              .sublist(endlist - 4, endlist)
                              .join("")
                              .toString(),
                          radix: 16);
                      print(pd3);
                      agcmonPD3 = pd3 * 3.3 / 4095;
                      if (agcmonPD3 > 1.1) {
                        agcmonPD3 = 1.1;
                      } else if (agcmonPD3 <= 0.3) {
                        agcmonPD3 = 0.3;
                      }
                      agcDPPD3 = (agcmonPD3 * 1934.167 - 412) /
                          (-26.04167 * agcmonPD3 + 39.0625);
                      print("Finally");
                      print(agcDPPD1);
                      print(agcDPPD1.toInt().toRadixString(16));
                      print(agcDPPD2);
                      print(agcDPPD3);
                      print("Sb12" + agcDPPD1.toInt().toRadixString(16));
                      print("Sb11" + agcDPPD2.toInt().toRadixString(16));
                      print("Sb10" + agcDPPD3.toInt().toRadixString(16));
                      await writeCommand(
                          "Sb12" + agcDPPD1.toInt().toRadixString(16));
                      await Future.delayed(Duration(seconds: 1));
                      await writeCommand(
                          "Sb11" + agcDPPD2.toInt().toRadixString(16));
                      await Future.delayed(Duration(seconds: 1));
                      await writeCommand(
                          "Sb10" + agcDPPD3.toInt().toRadixString(16));
                      await Future.delayed(Duration(seconds: 1));

                      await writeCommand("Sf0");
                      await Future.delayed(Duration(seconds: 1));
// Switch PD1 for set ADC & Gain
                      print("Switch PD1 for set ADC & Gain");
                      await writeCommand("Se2");
                      garbagelist = [];
                      await Future.delayed(Duration(seconds: 1));
                      garbagelist = await readCommand(garbagelist);
                      await Future.delayed(Duration(seconds: 1));

                      var tempPD1list01 = [];
                      var tempPD1list02 = [];
                      tempPD1list01 = await readCommand(tempPD1list01);

                      for (int i = 0; i < 3; i++) {
                        await writeCommand("Si");
                        await Future.delayed(Duration(milliseconds: 500));
                      }
                      print(tempPD1list01);
                      tempPD1list01.forEach((ascii) {
                        if (ascii != 10) {
                          String temp = String.fromCharCode(ascii);
                          tempPD1list02.add(temp);
                        }
                      });
                      String temp = tempPD1list02.join("");
                      List<String> v1 = temp.split("Ti");
                      var distinctIds = v1.toSet().toList(); //remove duplicate
                      distinctIds = distinctIds.sublist(1, distinctIds.length);
                      double foraverage = 0;
                      distinctIds.forEach((item) {
                        int item2 = int.parse(item, radix: 16);
                        foraverage = foraverage + item2;
                      });
                      var data01 = foraverage / 3;
                      var adcPd1 = data01 * 3.3 / 4095;
                      gainPD1temp = (adcPd1 * (-80) + 88) / 20;
                      gainPD1temp2 = pow(10, gainPD1temp);

// Switch PD2 for set ADC & Gain#######################
                      print("Switch PD2 for set ADC & Gain");
                      garbagelist = [];
                      garbagelist = await readCommand(garbagelist);
                      await Future.delayed(Duration(milliseconds: 500));
                      await writeCommand("Se1");
                      await Future.delayed(Duration(seconds: 1));
                      var tempPD2list01 = [];
                      var tempPD2list02 = [];
                      tempPD2list01 = await readCommand(tempPD2list01);
                      for (int i = 0; i < 3; i++) {
                        await writeCommand("Si");
                        await Future.delayed(Duration(milliseconds: 500));
                      }
                      print(tempPD2list01);
                      tempPD2list01.forEach((ascii) {
                        if (ascii != 10) {
                          String temp = String.fromCharCode(ascii);
                          tempPD2list02.add(temp);
                        }
                      });
                      temp = tempPD2list02.join("");
                      v1 = temp.split("Ti");
                      distinctIds = v1.toSet().toList(); //remove duplicate
                      distinctIds = distinctIds.sublist(1, distinctIds.length);
                      foraverage = 0;
                      distinctIds.forEach((item) {
                        int item2 = int.parse(item, radix: 16);
                        foraverage = foraverage + item2;
                      });
                      var data02 = foraverage / 3;
                      var adcPD2 = data02 * 3.3 / 4095;
                      gainPD2temp = (adcPD2 * (-80) + 88) / 20;
                      gainPD2temp2 = pow(10, gainPD2temp);

// Switch PD3 for set ADC & Gain#########################
                      print("Switch PD3 for set ADC & Gain");
                      await writeCommand("Se0");
                      await Future.delayed(Duration(seconds: 1));
                      garbagelist = [];
                      garbagelist = await readCommand(garbagelist);
                      await Future.delayed(Duration(milliseconds: 500));

                      var tempPD3list01 = [];
                      var tempPD3list02 = [];
                      tempPD3list01 = await readCommand(tempPD3list01);

                      for (int i = 0; i < 3; i++) {
                        await writeCommand("Si");
                        await Future.delayed(Duration(milliseconds: 500));
                      }
                      print(tempPD3list01);
                      tempPD3list01.forEach((ascii) {
                        if (ascii != 10) {
                          String temp = String.fromCharCode(ascii);
                          tempPD3list02.add(temp);
                        }
                      });
                      temp = tempPD3list02.join("");
                      v1 = temp.split("Ti");
                      distinctIds = v1.toSet().toList(); //remove duplicate
                      distinctIds = distinctIds.sublist(1, distinctIds.length);
                      foraverage = 0;
                      distinctIds.forEach((item) {
                        int item2 = int.parse(item, radix: 16);
                        foraverage = foraverage + item2;
                      });
                      var data03 = foraverage / 3;
                      var adcPD3 = data03 * 3.3 / 4095;
                      gainPD3temp = ((adcPD3 * -80) + 88) / 20;
                      gainPD3temp2 = pow(10, gainPD3temp);

                      await writeCommand("Se2");
                      await Future.delayed(Duration(seconds: 1));
                      await writeCommand("Sg0");
                      await Future.delayed(Duration(seconds: 1));
                      print('Adjust is done');
                      print(gainPD1temp2);
                      print(gainPD2temp2);
                      print(gainPD3temp2);
                    },
                    child: Text('Adjust'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // 측정버튼 누르면 측정을 시작한다. for문을 통해 횟수를 설정할 수 있음.

                      var newValueList = [];
                      var newtemplist02 = [];
                      newValueList = await readCommand(newValueList);
                      await Future.delayed(Duration(seconds: 1));
                      for (int i = 0; i < 10; i++) {
                        await writeCommand("Sh");
                        await Future.delayed(Duration(seconds: 1));
                      }
                      newValueList.forEach((ascii) {
                        // 측정해서 받은 데이터를 newtemplist02 리스트에 담음
                        String temp = String.fromCharCode(ascii);
                        newtemplist02.add(temp);
                      });
                      var bcmData = newtemplist02
                          .join(""); //newtemplist02 전부 한 String으로 만듬
                      print(postRequest(
                          //마지막으로 측정정보와 Gain값들 출력과 함께 서버로 전송
                          userid,
                          bcmData,
                          gainPD1,
                          gainPD2,
                          gainPD3));
                      postValue = bcmData;
                    },
                    child: Text('measurment'),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: list(), //리스트 출력
            ),
          ],
        ),
      ),
    );
  }

  chgmode(bool mode) {}
}

//BLE 장치 정보 저장 클래스
class BleDeviceItem {
  String deviceName;
  Peripheral peripheral;
  int rssi;
  AdvertisementData advertisementData;
  BleDeviceItem(
      this.deviceName, this.rssi, this.peripheral, this.advertisementData);
}
