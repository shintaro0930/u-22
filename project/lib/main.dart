import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/components/location.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'footer.dart';
import 'map.dart';
import 'settings.dart';
import './components/amount_provider.dart';
import './components/frequency_provider.dart';
import 'dart:async';
import './db/database_helper.dart';
import 'lock.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AmountProvider()),
        ChangeNotifierProvider(create: (context) => FrequencyProvider()),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: FutureBuilder(
          future: checkPermission(),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.data == true) {
              return const MyHomePage(title: 'ホーム');
            } else if (snapshot.data == false) {
              return const LockPage(title: '制限モード');
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage(title: 'ホーム')),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AroundSpotPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    }
  }

  String formatWeekDate(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final formatter = DateFormat('MM月dd日');
    final mondayFormatted = formatter.format(monday);
    final sundayFormatted = formatter.format(sunday);

    return '$mondayFormatted から $sundayFormatted';
  }

  Future<List<FlSpot>> getDataForGraph() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.rawQuery('SELECT timestamp, amount FROM payments');

    final List<FlSpot> spots = [];
    for (final row in data) {
      final timestamp = DateTime.parse(row['timestamp'] as String);
      final amount = row['amount'] as int;

      // 日付の形式を MM-dd に書式化
      final dateFormatter = DateFormat('MM-dd');
      final formattedDate = dateFormatter.format(timestamp);

      spots.add(FlSpot(formattedDate.hashCode.toDouble(), amount.toDouble()));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final amountProvider = Provider.of<AmountProvider>(context);
    final frequencyProvider = Provider.of<FrequencyProvider>(context);
    final currentDate = DateTime.now();
    final weekDateRange = formatWeekDate(currentDate);

    Future<int> fetchCumulativeAmount() async {
      final allPayments = await DatabaseHelper.instance.getAllPayments();
      return allPayments.fold<int>(
        0,
        (previousValue, payment) => previousValue + (payment['amount'] as int),
      );
    }

    Future<int> getWeeklyDonationTotal(context) async {
      final db = await DatabaseHelper.instance.database;
      final currentDate = DateTime.now();
      final monday =
          currentDate.subtract(Duration(days: currentDate.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));

      final total = Sqflite.firstIntValue(await db.rawQuery('''
    SELECT SUM(amount) FROM payments
    WHERE timestamp BETWEEN ? AND ?
  ''', [monday.toIso8601String(), sunday.toIso8601String()]));
      return total ?? 0;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            FutureBuilder<int>(
              future: fetchCumulativeAmount(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final cumulativeAmount = snapshot.data ?? 0;
                  return Text(
                    '累計金額: $cumulativeAmount 円',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  );
                }
              },
            ),
            Text(
              '今週の日付範囲: $weekDateRange',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            FutureBuilder<int>(
              future: getWeeklyDonationTotal(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final weeklyTotal = snapshot.data ?? 0;
                  return Text(
                    '週間の募金累計額: $weeklyTotal 円',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  );
                }
              },
            ),
            Text(
              '現在の金額: ${amountProvider.amount} 円',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              '現在の頻度',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              () {
                switch (frequencyProvider.selectedFrequency) {
                  case NotificationFrequency.unspecified:
                    return '指定なし';
                  case NotificationFrequency.oncePerDay:
                    return '1日に1回';
                  case NotificationFrequency.oncePerThreeDays:
                    return '1日に3回';
                  case NotificationFrequency.oncePerWeek:
                    return '1週間に1回';
                  default:
                    return 'その他の設定';
                }
              }(),
              style: const TextStyle(fontSize: 16),
            ),
            Image.asset(
              'assets/images/s2.png',
            ),
            SizedBox(
              width: 300,
              height: 200,
              child: FutureBuilder<List<FlSpot>>(
                future: getDataForGraph(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    final dataSpots = snapshot.data ?? [];

                    return LineChart(
                      LineChartData(
                        titlesData: const FlTitlesData(
                            // ... Configure your title data here ...
                            ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: dataSpots,
                            isCurved: true,
                            color: const Color.fromARGB(255, 63, 169, 255),
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: Footer(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
