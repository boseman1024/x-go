import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

Future<bool> requestPermission() async {
  final permissions = await PermissionHandler().requestPermissions([PermissionGroup.location,PermissionGroup.notification,PermissionGroup.sensors]);
  if (permissions[PermissionGroup.location] == PermissionStatus.granted) {
    return true;
  } else {
    return false;
  }
}

Future<String> initCode(num length) async{
  String alphabet = 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM';
  String code = '';
  for (var i = 0; i < length; i++) {
    code = code + alphabet[Random().nextInt(alphabet.length)];
  }
  return code;
}

