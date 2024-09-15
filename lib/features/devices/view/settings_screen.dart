import 'dart:developer';

import 'package:fit_equipment/devices.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.battarey,
    required this.onSetInnerPulse,
    required this.innerPulseValue,
    required this.onSetPeriodPulse,
    required this.periodrPulseValue,
    required this.onSetTimePulse,
    required this.timePulseValue,
    required this.onDisconnect,
  });

  final int battarey;
  final Function onSetInnerPulse;
  final Function onSetPeriodPulse;
  final Function onSetTimePulse;
  final int innerPulseValue;
  final int periodrPulseValue;
  final int timePulseValue;
  final Function onDisconnect;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _impulseValue = 10;
  double _timeValue = 10;
  double _periodValue = 10;

  @override
  void initState() {
    _impulseValue = widget.innerPulseValue.toDouble();
    _periodValue = widget.periodrPulseValue.toDouble();
    _timeValue = widget.timePulseValue.toDouble();
    super.initState();
  }

  void onChangeImpulse() {}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        actions: [
          BatteryWidget(
            batteryLevel: widget.battarey > 100 ? 100 : widget.battarey,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Text(
              'Импульс',
              style: TextStyle(fontSize: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: Text(
                    "Частота",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$_impulseValue kHz"),
                      const Text("60 kHz"),
                    ],
                  ),
                ),
                Slider(
                    min: 10,
                    max: 60,
                    divisions: 10,
                    value: _impulseValue,
                    inactiveColor: const Color.fromARGB(255, 194, 175, 228),
                    activeColor: Colors.blue[300],
                    onChanged: (curValue) {
                      _impulseValue = curValue;
                      log(curValue.toString());
                      widget.onSetInnerPulse(_impulseValue);
                      setState(() {});
                    }),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: Text(
                    "Длительность",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$_timeValue uS"),
                      const Text("500 uS"),
                    ],
                  ),
                ),
                Slider(
                    min: 100,
                    max: 500,
                    divisions: 40,
                    value: _timeValue,
                    inactiveColor: const Color.fromARGB(255, 194, 175, 228),
                    activeColor: Colors.blue[300],
                    onChanged: (curValue) {
                      _timeValue = curValue;
                      log(curValue.toString());
                      widget.onSetTimePulse(_timeValue);
                      setState(() {});
                    }),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: Text(
                    "Пауза",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$_periodValue mS"),
                      const Text("100 mS"),
                    ],
                  ),
                ),
                Slider(
                    min: 10,
                    max: 100,
                    divisions: 9,
                    value: _periodValue,
                    inactiveColor: const Color.fromARGB(255, 194, 175, 228),
                    activeColor: Colors.blue[300],
                    onChanged: (curValue) {
                      _periodValue = curValue;
                      log(curValue.toString());
                      widget.onSetPeriodPulse(_periodValue);
                      setState(() {});
                    }),
              ],
            ),
            SetButton(
              title: 'Отключить устройство',
              onClick: () async {
                await widget.onDisconnect();
                // ignore: use_build_context_synchronously
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const DevicesListScreen(
                          isBack: true,
                        )));
              },
            ),
            SetButton(
              title: 'Техника безопасности',
              onClick: () {},
            ),
            SetButton(
              title: 'Техническая инструкция',
              onClick: () {},
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Логин: admin_test@mail.ru',
                style: TextStyle(fontSize: 20),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SetButton extends StatelessWidget {
  final String title;
  final Function onClick;
  const SetButton({
    super.key,
    required this.title,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      child: ElevatedButton(
        onPressed: () => onClick(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(156, 21, 69, 146),
          minimumSize:
              const Size(double.infinity, 75), // Ширина на всю ширину экрана
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Округленные границы
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center, // Текст по центру
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
      ),
    );
  }
}

class BatteryWidget extends StatelessWidget {
  final int batteryLevel;

  const BatteryWidget({super.key, required this.batteryLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      // decoration: BoxDecoration(
      //   border: Border.all(color: Colors.black, width: 2),
      //   borderRadius: BorderRadius.circular(5),
      // ),
      child: Row(
        children: [
          Icon(
            Icons.battery_full,
            color: batteryLevel > 20 ? Colors.green : Colors.red,
          ),
          //SizedBox(width: 5),
          Text(
            '$batteryLevel%',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: batteryLevel > 20 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
