import 'dart:async';
import 'dart:developer';
import 'dart:ffi';

import 'package:fit_equipment/devices.dart';
import 'package:fit_equipment/features/devices/view/settings_screen.dart';
import 'package:fit_equipment/features/devices/view/widgets/loading.dart';
import 'package:fit_equipment/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:dio/dio.dart';

// final musculsArr = [
//   ["3a131001-55f3-421e-a928-3c7d7c395c8c", "Плечи"],
//   ["3a131002-55f3-421e-a928-3c7d7c395c8c", 'Ноги'],
//   ["3a131003-55f3-421e-a928-3c7d7c395c8c", 'Живот'],
//   ["3a131004-55f3-421e-a928-3c7d7c395c8c", "Грудь"],
//   ["3a131005-55f3-421e-a928-3c7d7c395c8c", 'Верх спины'],
//   ["3a131006-55f3-421e-a928-3c7d7c395c8c", 'Низ спины'],
//   ["3a131007-55f3-421e-a928-3c7d7c395c8c", 'Ягодицы'],
//   ["3a131008-55f3-421e-a928-3c7d7c395c8c", 'Arm'],
//   ["3a131009-55f3-421e-a928-3c7d7c395c8c", 'Char 9'],
// ];

String findMuscle(String id) {
  log("FINDER UUID   $id");
  final musculsArr = [
    ["3a131001-55f3-421e-a928-3c7d7c395c8c", "Плечи"],
    ["3a131002-55f3-421e-a928-3c7d7c395c8c", 'Ноги'],
    ["3a131003-55f3-421e-a928-3c7d7c395c8c", 'Живот'],
    ["3a131004-55f3-421e-a928-3c7d7c395c8c", "Грудь"],
    ["3a131005-55f3-421e-a928-3c7d7c395c8c", 'Верх спины'],
    ["3a131006-55f3-421e-a928-3c7d7c395c8c", 'Низ спины'],
    ["3a131007-55f3-421e-a928-3c7d7c395c8c", 'Ягодицы'],
    ["3a131008-55f3-421e-a928-3c7d7c395c8c", 'Arm'],
    ["3a131009-55f3-421e-a928-3c7d7c395c8c", 'Char 9'],
  ];

  for (var muscle in musculsArr) {
    if (muscle[0] == id) {
      return muscle[1];
    }
  }
  return "Характеристика";
}

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({super.key, required this.device});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  StreamSubscription<BluetoothConnectionState>? _deviceSub;
  int? _battarey;
  BluetoothCharacteristic? _innerPulseChar;
  BluetoothCharacteristic? _pulsePeriodChar;
  BluetoothCharacteristic? _pulseTimeChar;
  BluetoothCharacteristic? _burstTimeChar;
  BluetoothCharacteristic? _burstPeriodChar;
  BluetoothCharacteristic? _startStopChar;
  int _startStopValue = 0;
  int _innerPulseValue = 0;
  int _pulsePeriodValue = 0;
  List<int> _pulseTimeValue = [];
  List<int> _burstTimeValue = [];
  List<int> _burstPeriodValue = [];

  bool _isAuth = false;

  //BluetoothService? _musculsService;
  List<BluetoothCharacteristic> _musculChars = [];

  int _allMusculsCount = 0;

  bool _isLoading = false;
  // void setLoading(bool value) {
  //   _isLoading = value;

  //   setState(() {});
  // }

  //! TIMER
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _seconds = 0;
        _isRunning = false;
      });
    } else {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
      });
      setState(() {
        _isRunning = true;
      });
    }
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  //! / TIMER

  @override
  void initState() {
    final device = widget.device;
    _deviceSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        connectAndRead(device);
      }
    });

    super.initState();
    fetchData();
  }

  @override
  void dispose() async {
    await _onDisconnect();
    //_deviceSub?.cancel();
    super.dispose();
  }

  //!CONNECTION WEB
  void fetchData() async {
    final dio = Dio();
    const url = 'http://195.133.199.147:7000/api/devises';
    final devaseId = widget.device.remoteId.str;
    final body = {
      'deviseId': devaseId,
      'initDate': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final response = await dio.post(url, data: body);
      log('Response data: ${response.data}');
      if (response.data.status) {
        _isAuth = true;
        setState(() {});
      }
    } catch (e) {
      log('Error: $e');
    }
  }

  //!CONNECTION BLE

  Future<void> connectAndRead(BluetoothDevice device) async {
    await device.connect();
    final List<BluetoothService> services = await device.discoverServices();

    log(services.toString());

    const battareyServiceUuid = "0000180f-0000-1000-8000-00805f9b34fb";
    const battaryCharacteristicUuid = "00002a19-0000-1000-8000-00805f9b34fb";

    const trainintServiceUuid = "3a130000-55f3-421e-a928-3c7d7c395c8c";
    const musculsServiceUuid = "3a131000-55f3-421e-a928-3c7d7c395c8c";

    const startStopCHarUuid = "3a130001-55f3-421e-a928-3c7d7c395c8c";
    const innerPulseCharUuid = '3a130002-55f3-421e-a928-3c7d7c395c8c';
    const pulsePeriodCharUuid = '3a130003-55f3-421e-a928-3c7d7c395c8c';
    const burstTimeCharUuid = '3a130004-55f3-421e-a928-3c7d7c395c8c';
    const burstPeriodCharUuid = '3a130005-55f3-421e-a928-3c7d7c395c8c';
    const pulseTimeCharUuid = '3a130006-55f3-421e-a928-3c7d7c395c8c';

    //BATTAREY
    final isBattaryServ =
        services.where((e) => e.uuid.str128 == battareyServiceUuid).isNotEmpty;
    if (!isBattaryServ) return;

    final battaryServ =
        services.firstWhere((e) => e.uuid.str128 == battareyServiceUuid);

    final isBattaryChar = battaryServ.characteristics
        .where((e) => e.uuid.str128 == battaryCharacteristicUuid)
        .isNotEmpty;
    if (!isBattaryChar) return;

    final battaryChar = battaryServ.characteristics
        .firstWhere((e) => e.uuid.str128 == battaryCharacteristicUuid);

    final battaryValue = (await battaryChar.read()).first;
    log(battaryValue.toString());

    _battarey = battaryValue;

    //?TRAINING
    if (services.where((e) => e.uuid.str128 == trainintServiceUuid).isEmpty) {
      return;
    }

    final trainingService =
        services.firstWhere((e) => e.uuid.str128 == trainintServiceUuid);

    //?  MUSCULS
    if (services.where((e) => e.uuid.str128 == musculsServiceUuid).isEmpty) {
      return;
    }

    final musculsService =
        services.firstWhere((e) => e.uuid.str128 == musculsServiceUuid);
    //_musculsService = musculsService;
    _musculChars = musculsService.characteristics;

    //!  START/STOP

    if (trainingService.characteristics
        .where((e) => e.uuid.str128 == startStopCHarUuid)
        .isEmpty) return;
    final startStopChar = trainingService.characteristics
        .firstWhere((e) => e.uuid.str128 == startStopCHarUuid);
    _startStopChar = startStopChar;
    _startStopValue = (await startStopChar.read()).first;

    //!INNER PULSE
    if (trainingService.characteristics
        .where((e) => e.uuid.str128 == innerPulseCharUuid)
        .isEmpty) return;
    final innerPulseChar = trainingService.characteristics
        .firstWhere((e) => e.uuid.str128 == innerPulseCharUuid);

    _innerPulseChar = innerPulseChar;
    _innerPulseValue = (await innerPulseChar.read()).first;
    //!PULSE PERIOD
    if (trainingService.characteristics
        .where((e) => e.uuid.str128 == pulsePeriodCharUuid)
        .isEmpty) return;
    final pulsePeriodChar = trainingService.characteristics
        .firstWhere((e) => e.uuid.str128 == pulsePeriodCharUuid);

    _pulsePeriodChar = pulsePeriodChar;
    _pulsePeriodValue = (await pulsePeriodChar.read()).first;

    //!PULSE TIME
    if (trainingService.characteristics
        .where((e) => e.uuid.str128 == pulseTimeCharUuid)
        .isEmpty) return;
    final pulseTimeChar = trainingService.characteristics
        .firstWhere((e) => e.uuid.str128 == pulseTimeCharUuid);

    _pulseTimeChar = pulseTimeChar;
    final pulseValue = await pulseTimeChar.read();
    _pulseTimeValue = pulseValue;

    //! BURST TIME
    //[232, 3]
    if (trainingService.characteristics
        .where((e) => e.uuid.str128 == burstTimeCharUuid)
        .isEmpty) return;
    final burstTimeChar = trainingService.characteristics
        .firstWhere((e) => e.uuid.str128 == burstTimeCharUuid);

    _burstTimeChar = burstTimeChar;
    //await burstTimeChar.write([232, 3]);
    final burstValue = await burstTimeChar.read();
    _burstTimeValue = burstValue;

    //! BURST PERIOD
    //[208, 7]
    if (trainingService.characteristics
        .where((e) => e.uuid.str128 == burstPeriodCharUuid)
        .isEmpty) return;
    final burstPeriodChar = trainingService.characteristics
        .firstWhere((e) => e.uuid.str128 == burstPeriodCharUuid);

    _burstPeriodChar = burstPeriodChar;
    //await burstTimeChar.write([232, 3]);
    final burstPeriodValue = await burstPeriodChar.read();
    _burstPeriodValue = burstPeriodValue;

    setState(() {});
  }

  //? CHAR FUNCS

  //! START STOP FUNC

  void _startStopToggle() {
    int curValue;
    setState(() {
      if (_startStopValue == 1) {
        curValue = 0;
      } else {
        curValue = 1;
      }
      _toggleTimer();
      _startStopValue = curValue;

      final characteristic = _startStopChar;
      if (characteristic != null) {
        characteristic.write([curValue]);
      }
    });
  }

  //! INNER PULSE FUNCS
  void _setPulseValue(int value) {
    setState(() {
      _innerPulseValue = value;
      final characteristic = _innerPulseChar;
      if (characteristic != null) {
        characteristic.write([value]);
      }
    });
  }

  void _onSetInnerPulse(double value) {
    final valueInt = value.toInt();
    _setPulseValue(valueInt);
  }

  //!PULSE PERIOD FUNCS
  void _setPulsePeriodValue(int value) {
    setState(() {
      _pulsePeriodValue = value;
      final characteristic = _pulsePeriodChar;
      if (characteristic != null) {
        characteristic.write([value]);
      }
    });
  }

  void _onSetPeriodPulse(double value) {
    final valueInt = value.toInt();
    _setPulsePeriodValue(valueInt);
  }

  //! PULSE TIME FUNCS
  void _setPulseTimeValue(int value) {
    final valueArr = intToByteArray(value);
    setState(() {
      _pulseTimeValue = valueArr;
      final characteristic = _pulseTimeChar;
      if (characteristic != null) {
        characteristic.write(valueArr);
      }
    });
  }

  void _onSetTimePulse(double value) {
    final valueInt = value.toInt();
    _setPulseTimeValue(valueInt);
  }

  //! BURST TIME FUNCS
  void _setBurstTimeValue(int value) {
    final valueArr = intToByteArray(value);
    setState(() {
      _burstTimeValue = valueArr;
      final characteristic = _burstTimeChar;
      if (characteristic != null) {
        characteristic.write(valueArr);
      }
    });
  }

  void _onBurstTimeAdd() {
    final valueIntUs = byteArrayToInt(_burstTimeValue);

    if (valueIntUs < 60000) {
      _setBurstTimeValue(valueIntUs + 1000);
    }
  }

  void _onBurstTimeDel() {
    final valueIntUs = byteArrayToInt(_burstTimeValue);

    if (valueIntUs > 0) {
      _setBurstTimeValue(valueIntUs - 1000);
    }
  }

  //! BURST PERIOD FUNCS
  void _setBurstPeriodValue(int value) {
    final valueArr = intToByteArray(value);
    setState(() {
      _burstPeriodValue = valueArr;
      final characteristic = _burstPeriodChar;
      if (characteristic != null) {
        characteristic.write(valueArr);
      }
    });
  }

  void _onBurstPeriodAdd() {
    final valueIntUs = byteArrayToInt(_burstPeriodValue);

    if (valueIntUs < 60000) {
      _setBurstPeriodValue(valueIntUs + 1000);
    }
  }

  void _onBurstPeriodDel() {
    final valueIntUs = byteArrayToInt(_burstPeriodValue);

    if (valueIntUs > 0) {
      _setBurstPeriodValue(valueIntUs - 1000);
    }
  }

  //! DEVICE CONTROL FUNC

  Future<void> _onDisconnect() async {
    if (_startStopValue == 1) {
      final characteristic = _startStopChar;
      if (characteristic != null) {
        characteristic.write([0]);
      }
    }
    _deviceSub?.cancel();
    await widget.device.disconnect();
  }

  //! ALL MUSCULS FUNC
  Future<void> _onAddAllMusculs(bool add) async {
    _timer?.cancel();
    List<int> valuesArr = [];
    _isLoading = true;
    setState(() {});

    await Future.forEach(_musculChars, (char) async {
      int value = (await char.read())[0];
      valuesArr = [...valuesArr, value];
      if (add) {
        if (value < 100) {
          await char.write([value + 1]);
        }
      } else {
        if (value > 0) {
          await char.write([value - 1]);
        }
      }
    });
    add ? _allMusculsCount++ : _allMusculsCount--;
    _isLoading = false;
    setState(() {});
  }

  //COLORS

  final Color defColor = Color.fromARGB(255, 239, 246, 232);
  final Color backColor = const Color.fromARGB(255, 231, 231, 231);
  final Color logoBackColor = const Color.fromARGB(255, 194, 206, 235);
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        backgroundColor: backColor,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 152, 178, 190),
                  Color.fromARGB(255, 231, 231, 231)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
          leading: _battarey != null
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.blue,
                  ),
                  onPressed: () async {
                    if (!_isLoading) {
                      await _onDisconnect();
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const DevicesListScreen(
                                isBack: true,
                              )));
                    }
                  },
                )
              : const Text(''),
          actions: [
            _battarey != null
                ? IconButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SettingsScreen(
                                onDisconnect: _onDisconnect,
                                onSetTimePulse: _onSetTimePulse,
                                timePulseValue: byteArrayToInt(_pulseTimeValue),
                                innerPulseValue: _innerPulseValue,
                                onSetInnerPulse: _onSetInnerPulse,
                                onSetPeriodPulse: _onSetPeriodPulse,
                                periodrPulseValue: _pulsePeriodValue,
                                battarey: _battarey!,
                              )));
                    },
                    icon: const Icon(Icons.settings),
                  )
                : const Text(''),
          ],
          toolbarHeight: 80,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                verticalDirection: VerticalDirection.down,
                children: [
                  Text('EMS',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: Color.fromARGB(255, 104, 107, 150),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Interceptor',
                          fontSize: 30,
                          height: -1,
                          letterSpacing: 1)),
                  Padding(
                    padding: EdgeInsets.all(0),
                    child: Text(
                      'TECHNOLOGY',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Interceptor',
                          fontSize: 30,
                          height: 0.6,
                          letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: ListView(
          shrinkWrap: true,
          children: [
            // !_isLoading
            //     ?
            Container(
              margin: const EdgeInsets.only(
                left: 10,
                right: 10,
                bottom: 20,
              ),
              padding: const EdgeInsets.only(
                  top: 5, left: 10, right: 10, bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: _battarey == null
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: _battarey != null
                        ? [
                            // _isLoading
                            //     ? Loading(
                            //         size: 21,
                            //       )
                            //     : const Text(''),
                            // Text(_isAuth.toString()),
                            // Icon(!_isAuth
                            //     ? Icons.wrong_location
                            //     : Icons.one_k_sharp),
                            ControlLine(
                              name: 'Общая Мощность Импульсов',
                              //name: 'Разрыв время',
                              value: _allMusculsCount,
                              onAdd: () => _onAddAllMusculs(true),
                              onDel: () => _onAddAllMusculs(false),
                              unit: '',
                              color: const Color.fromARGB(255, 219, 249, 244),
                              isLoading: _isLoading,
                            ),
                            ControlLine(
                              name: 'Длительность Импулься',
                              //name: 'Разрыв время',
                              value: byteArrayToInt(_burstTimeValue) ~/ 1000,
                              onAdd: _onBurstTimeAdd,
                              onDel: _onBurstTimeDel,
                              unit: 'sec',
                              color: defColor,
                              isLoading: _isLoading,
                            ),
                            ControlLine(
                              name: 'Задержка Между Импульсами',
                              // name: 'Разрыв период',
                              value: byteArrayToInt(_burstPeriodValue) ~/ 1000,
                              onAdd: _onBurstPeriodAdd,
                              onDel: _onBurstPeriodDel,
                              unit: 'sec',
                              color: defColor,
                              isLoading: _isLoading,
                            ),

                            //? условие для обновления виджета
                            // !_isLoading
                            //     ?
                            MusculServicesList(
                              chars: _musculChars,
                              isLoading: _isLoading,
                            ),
                            // : const CircularProgressIndicator(
                            //     strokeWidth: 3,
                            //     valueColor: AlwaysStoppedAnimation<Color>(
                            //         Colors.blue),
                            //   )
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextButton(
                                  autofocus: true,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: _startStopValue == 0
                                        ? Colors.green
                                        : Colors.red,
                                    padding: const EdgeInsets.all(16.0),
                                    textStyle: const TextStyle(
                                        fontSize: 25, color: Colors.black),
                                  ),
                                  onPressed: _startStopToggle,
                                  child: Column(
                                    children: [
                                      Text(
                                        '  ${_startStopValue == 0 ? 'Начало' : 'Конец '} тренировки ',
                                      ),
                                      Text(_formatTime(_seconds))
                                    ],
                                  )),
                            ),
                          ]
                        : [
                            // Настройки для индикатора загрузки
                            SizedBox(
                              height: screenHeight,
                              child: Center(
                                child: Loading(
                                  size: 50,
                                ),
                              ),
                            ),
                          ],
                  ),
                ),
              ),
            )
            // : Text('loading'),
          ],
        ));
  }
}

//! -----------------------------CONTROL LINE

class ControlLine extends StatelessWidget {
  const ControlLine({
    super.key,
    required this.name,
    required this.value,
    required this.onAdd,
    required this.onDel,
    required this.unit,
    required this.color,
    required this.isLoading,
  });
  final int value;
  final String name;
  final String unit;
  final Function() onAdd;
  final Function() onDel;
  final Color color;
  final isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(5, 3),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                        onPressed: !isLoading ? onDel : () {},
                        child: const Icon(Icons.remove)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.white),
                      child: Text(
                        "$value $unit",
                        style: const TextStyle(
                            fontSize: 20,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                        onPressed: !isLoading ? onAdd : () {},
                        child: const Icon(Icons.add)),
                    const Divider(height: 1, color: Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//! --------------- MUSCUL LIST
class MusculServicesList extends StatefulWidget {
  final List<BluetoothCharacteristic> chars;

  final bool isLoading;

  const MusculServicesList({
    super.key,
    required this.chars,
    required this.isLoading,
  });

  @override
  State<MusculServicesList> createState() => _MusculServicesListState();
}

class _MusculServicesListState extends State<MusculServicesList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.chars.map((characteristic) {
        return MusculTile(
          characteristic: characteristic,
          isLoading: widget.isLoading,
        );
      }).toList(),
    );
  }
}

//! ------------- MUSCUL ITEM
class MusculTile extends StatefulWidget {
  final BluetoothCharacteristic characteristic;
  final bool isLoading;

  const MusculTile({
    super.key,
    required this.characteristic,
    required this.isLoading,
  });

  @override
  State<MusculTile> createState() => _MusculTileState();
}

class _MusculTileState extends State<MusculTile> {
  int _musculValue = 999;
  String _charUuid = "";

  @override
  void initState() {
    _readChar(widget.characteristic);

    super.initState();
  }

  @override
  void didUpdateWidget(MusculTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      // Параметр изменился, выполните необходимые действия
      print('✅ Parameter changed: ${widget.isLoading}');
      _readChar(widget.characteristic);
    }
  }

  void _onAdd() async {
    if (_musculValue < 100) _musculValue++;
    log('ADD ➡️ $_musculValue');
    await widget.characteristic.write([_musculValue]);
    setState(() {});
  }

  void _onDel() async {
    if (_musculValue > 1) _musculValue--;
    log('DEL ➡️ $_musculValue');
    await widget.characteristic.write([_musculValue]);
    setState(() {});
  }

  Future<void> _readChar(BluetoothCharacteristic char) async {
    if (!widget.isLoading) {
      _musculValue = (await char.read())[0];
      _charUuid = char.uuid.str128;
      char.uuid.str;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        color: const Color.fromARGB(255, 233, 232, 232),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 123, 123, 123).withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(5, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            findMuscle(_charUuid),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(onPressed: _onDel, icon: const Icon(Icons.remove)),
              Container(
                padding: const EdgeInsets.only(left: 10, right: 10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white),
                child: Container(
                  child: widget.isLoading
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 3),
                          child: Loading(size: 18),
                        )
                      : Text(
                          _musculValue != 999 ? _musculValue.toString() : ' ',
                          //positiveCalcValue(),
                          style: const TextStyle(
                              fontSize: 20,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              IconButton(onPressed: _onAdd, icon: const Icon(Icons.add)),
            ],
          )
        ],
      ),
    );
  }
}
