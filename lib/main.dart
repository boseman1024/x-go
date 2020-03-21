import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:x_gogo/history/history.dart';
import 'package:x_gogo/map/mapScreen.dart';
import 'package:x_gogo/map/mapLog.dart';
import 'package:x_gogo/me/me.dart';
import 'package:x_gogo/me/setting.dart';

import 'package:x_gogo/db/provider.dart';

void main() async{
  runApp(MyApp());
  final provider = Provider();
  await provider.init();
}

class MyApp extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  List pageList = [ Text('主页'),History(), Me()];

  static Map<String, WidgetBuilder> routes;

  static initRoutes() {
    routes = {
      '/map': (context) => MapScreen(),
      '/log': (context) => MapLog(),
      '/setting': (context) => Setting()
    };
    return routes;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('zh', 'CN'),
      ],
      routes: initRoutes(),
      home: Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: pageList[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed, //允许多个菜单
            onTap: (index) {
              setState(() {
                this._currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.message), title: Text('主页')),
              BottomNavigationBarItem(icon: Icon(Icons.message), title: Text('历史')),
              BottomNavigationBarItem(icon: Icon(Icons.people), title: Text('个人'))
            ],
        ),
      ),
    );
  }
}