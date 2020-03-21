import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:x_amap_track/x_amap_track.dart';
import 'package:android_intent/android_intent.dart';
import 'package:device_info/device_info.dart';
import 'package:x_gogo/db/provider.dart';
import 'dart:io';

class Setting extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return SettingState();
  }
}

class SettingState extends State<Setting>{
  PermissionStatus permission;
  bool _locationPermission = false;
  String _deviceInfo = '';
  DeviceInfoPlugin _deviceInfoPlugin;
  List<Widget> initList(){
    return <Widget>[
      ListTile(
        leading: FlutterLogo(size: 24.0),
        title: Text('定位权限'),
        subtitle: Text(_locationPermission?'定位权限已开启':'定位权限未开启，请前往设置'),
        trailing: Icon(Icons.chevron_right),
        onTap: (){
          XAmapTrack.openPermissionSetting();
        },
      ),
      Divider(color: Colors.black12,indent:10,endIndent:10,height: 1,),
      ListTile(
        leading: FlutterLogo(size: 24.0),
        title: Text('位置信息'),
        trailing: Icon(Icons.chevron_right),
        onTap: (){
          openPermission();
        },
      ),
      Divider(color: Colors.black12,indent:10,endIndent:10,height: 1,),
      ListTile(
        leading: FlutterLogo(size: 24.0),
        title: Text('清空数据'),
        subtitle: Text('慎重！'),
        trailing: Icon(Icons.clear_all),
        onTap: (){
          clearDataConfirm();
        },
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _deviceInfoPlugin = DeviceInfoPlugin();
    checkPermission();
    getDeviceInfo();
  }

  void checkPermission() async{
    permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.location);
    setState(() {
      _locationPermission = permission==PermissionStatus.granted;
    });
  }

  //获取设备信息
  void getDeviceInfo() async{
    AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
    setState(() {
      _deviceInfo = androidInfo.androidId+' '+androidInfo.model+' '+androidInfo.product+' '+androidInfo.version.baseOS;
    });
  }

  //位置信息
  void openPermission() async{
    if (Platform.isAndroid) {
      final AndroidIntent intent = AndroidIntent(
        action: 'action_location_source_settings',
      );
      await intent.launch();
    }
  }

  void clearData() async{
    final provider = Provider();
    await provider.reInit();
  }

  void clearDataConfirm() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('清空数据'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('该操作无法撤销，是否继续？'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('确认'),
              onPressed: () {
                clearData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('设置'),
          centerTitle: true,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(
            color: Colors.black
          ),
          textTheme: TextTheme(
              title: TextStyle(
                  color: Colors.black
              )
          ),
        ),
        body: Column(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Colors.black12,width: 1)
                ),
              ),
              child: Wrap(
                children: initList(),
              ),
            ),
            Center(
              child: Text(_deviceInfo),
            )
          ],
        )
    );
  }

}
