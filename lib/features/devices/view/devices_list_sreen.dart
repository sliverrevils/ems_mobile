import 'dart:async';
import 'dart:developer';

import 'package:fit_equipment/devices.dart';
import 'package:fit_equipment/features/devices/view/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DevicesListScreen extends StatefulWidget {
  const DevicesListScreen({
    super.key,
    required this.isBack,
  });
  final bool isBack;

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}

bool wasBack = false;

bool _bleOn = false;
bool _bleSup = false;

class _DevicesListScreenState extends State<DevicesListScreen> {
  List<ScanResult>? _scanResults;

  StreamSubscription<List<ScanResult>>? _devicesSub;

  bool? _isLoading;

  @override
  void initState() {
    // log('INIT 💡💡💡💡 - ${widget.isBack}');
    if (widget.isBack) {
      _scanResults = null;
    }
    _enableFlutterBle();
    super.initState();
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    wasBack = false;
    super.dispose();
  }

  @override
  void didUpdateWidget(DevicesListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBack != widget.isBack) {
      log('✅✅✅ IS BACK');
    }
  }

  Future<void> _enableFlutterBle() async {
    _scanResults = null;
    final isBack = widget.isBack;
    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      log("Bluetooth not supported by this device");
      _bleSup = false;
      setState(() {});
      return;
    } else {
      _bleSup = true;
      setState(() {});
      log('Всё круто 👍');
    }

    final state = await FlutterBluePlus.adapterState.first;

    log(state.toString());
    if (state != BluetoothAdapterState.on) {
      log('Bluetooth off');
      _bleOn = false;
      setState(() {});

      return;
    } else {
      _bleOn = true;
      setState(() {});
    }

    _devicesSub?.cancel();
    _devicesSub = FlutterBluePlus.onScanResults.listen(
      (results) {
        // log(FlutterBluePlus.isScanningNow.toString());
        // log(results.toString());
        setState(() => _scanResults = results);

        if (isBack) {
          wasBack = true;
        }

        //log('2 BACK ➡️➡️➡️➡️➡️  wasBack : ${wasBack} -results.length: ${_scanResults?.length}');
        if (!wasBack && results.length == 1) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).push(MaterialPageRoute(
              builder: (contex) => DeviceScreen(device: results[0].device)));
        }

        return;
      },
      onError: (e) => log(e),
    );
    _isLoading = null;
    setState(() {});
    await FlutterBluePlus.startScan(
        withNames: ['EMS-Fitness'], timeout: const Duration(seconds: 15));
    _isLoading = false;
    setState(() {});
  }

  Widget screenLogic() {
    if (!_bleOn) {
      return ErrorScreen(
          '⚠️Включите Bluetooth на этом устройстве. \n✅Нажмите кнопку "Поиск устройств" ',
          true);
    }
    if (!_bleSup) {
      return ErrorScreen(
          '⚠️Ваше устройство не поддерживает bluetooth. \n✅Подключитесь с другого устройства',
          false);
    }
    if (_isLoading != null) {
      if (_isLoading!) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Поиск устройств...'),
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
          ),
        );
      }
    }

    if (_scanResults != null && _scanResults!.isNotEmpty) {
      return ListView.separated(
        itemCount: _scanResults!.length,
        itemBuilder: (context, index) {
          final result = _scanResults![index];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(5, 3), // changes position of shadow
                  ),
                ],
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20.0), // Радиус округления углов
                  child: Image.asset(
                    './images/EMS_logo_edit.png',
                  ),
                ),
                title: Text(result.device.advName),
                subtitle: Text(result.device.platformName),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (contex) =>
                          DeviceScreen(device: result.device)));
                },
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(height: 1),
      );
    }

    if (_scanResults != null &&
        _scanResults!.toList()!.length == 0 &&
        _isLoading != null &&
        !wasBack) {
      return ErrorScreen(
          '1️⃣Включите "EMS-Fitness" устройство\n2️⃣Нажмите кнопку "Поиск устройств"',
          true,
          19);
    }
    if (_isLoading != null && _isLoading != false) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }
    if (wasBack && _scanResults != null && _scanResults!.length == 0) {
      return ErrorScreen(
          '1️⃣Включите "EMS-Fitness" устройство\n2️⃣Нажмите кнопку "Поиск устройств"',
          true,
          19);
    }

    if (wasBack) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    return const Text('Лист пуст');
  }

  // ignore: non_constant_identifier_names
  Center ErrorScreen(String text, bool showButton, [double fontSize = 20]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                text,
                style: TextStyle(color: Colors.blue[400], fontSize: fontSize),
              ),
            ),

            if (showButton)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[400],
                  minimumSize: const Size(
                      double.infinity, 75), // Ширина на всю ширину экрана
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10), // Округленные границы
                  ),
                ),
                onPressed: _enableFlutterBle,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Поиск устройств',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                      ),
                    ),
                  ),
                ),
              ),
            //const Text('Устройства не найдено'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Список устройств',
          style: TextStyle(),
        ),
        // 'Список устройств\n loading-$_isLoading, on-$_bleOn,  sup-$_bleSup '),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
          child: screenLogic(), onRefresh: () => _enableFlutterBle()),
      floatingActionButton: _bleOn && _bleSup
          ? FloatingActionButton(
              backgroundColor: Colors.blue[400],
              onPressed: _enableFlutterBle,
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
