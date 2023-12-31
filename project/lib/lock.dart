import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main.dart';

Future<bool> firstPermission() async {
  PermissionStatus permissionLocation = await Permission.location.request();
  PermissionStatus permissionNotification =
      await Permission.notification.request();
  return permissionLocation.isGranted && permissionNotification.isGranted;
}

Future<bool> checkPermission() async {
  PermissionStatus permissionLocation = await Permission.location.status;
  PermissionStatus permissionNotification =
      await Permission.notification.status;
  return permissionLocation.isGranted && permissionNotification.isGranted;
}

class LockPage extends StatefulWidget {
  const LockPage({super.key, required this.title});
  final String title;

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  bool statusLocation = false;
  bool statusNotification = false;

  @override
  void initState() {
    super.initState();
    Timer.periodic(
      // 第一引数：繰り返す間隔の時間を設定
      const Duration(seconds: 2),
      // 第二引数：その間隔ごとに動作させたい処理を書く
      (Timer timer) async {
        if (await checkPermission()) {
          timer.cancel();
          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MyHomePage(title: 'ホーム')),
          );
        }
        statusLocation = await Permission.location.status.isGranted;
        statusNotification = await Permission.notification.status.isGranted;
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  double getFontSize(double coefficient) {
    return MediaQuery.of(context).size.width * coefficient;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.black,
          title: Text(
            widget.title,
            style: TextStyle(color: Colors.white, fontSize: getFontSize(0.06)),
          ),
        ),
        body: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            SwitchListTile(
              value: statusNotification,
              activeColor: Colors.blue,
              inactiveThumbColor: Colors.grey,
              title: statusNotification
                  ? const Text('通知は許可されています',
                      style: TextStyle(fontWeight: FontWeight.bold))
                  : const Text('通知が許可されていません',
                      style: TextStyle(fontWeight: FontWeight.bold)),
              onChanged: (bool value) {},
            ),
            SwitchListTile(
                value: statusLocation,
                activeColor: Colors.blue,
                inactiveThumbColor: Colors.grey,
                title: statusLocation
                    ? const Text('位置情報は許可されています',
                        style: TextStyle(fontWeight: FontWeight.bold))
                    : const Text('位置情報が許可されていません',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                onChanged: (bool value) {}),
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            Text(
              '以下のように設定してください',
              style: TextStyle(
                fontSize: getFontSize(0.05),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Image.asset(
              'assets/images/setting.jpg',
              width: MediaQuery.of(context).size.height * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
              ),
              label: const Text('アプリ設定を開く'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                openAppSettings();
              },
            ),
          ],
        ));
  }
}
