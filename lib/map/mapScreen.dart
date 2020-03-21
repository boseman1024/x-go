import 'package:flutter/material.dart';
import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'package:x_gogo/utils/utils.export.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:x_amap_track/x_amap_track.dart';
import 'package:x_gogo/db/sqlUtil.dart';
import 'package:x_gogo/utils/pointFilter.dart';
import 'package:x_gogo/map/taskType.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

final _icon_current_location = Uri.parse('images/icon_current_location.png');
final _icon_start = Uri.parse('images/icon_start.png');
final _icon_end = Uri.parse('images/icon_end.png');
final _icon_check_point = Uri.parse('images/icon_check_point.png');

class MapScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return MapState();
  }
}

class MapState extends State<MapScreen> with WidgetsBindingObserver{
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();
  AmapController _controller;
  MapType _curMapType = MapType.Standard;
  TaskType _taskType = TaskType.LESS;
  LatLng _latLng = LatLng(39, 116);
  List<LatLng> _latLngBox = [];
  Polyline _currentPolyline;
  double _distance = 0;
  bool _isStart = false;
  //记录时间
  Timer _timer;
  static const _duration = const Duration(seconds: 1);
  int _secondsPassed = 0;
  int _seconds = 0;
  int _minutes = 0;
  int _hours = 0;
  //记录编号
  String _taskId;
  var taskSql;
  var pointSql;
  //轨迹过滤器
  PointFilter pf;
  //打点
  List<Marker> _markerList = [];

  List<Color> colors = [
    Color(0xFFff4136),Color(0xFFff4f31),
    Color(0xFFff5d2c),Color(0xFFff6b27),
    Color(0xFFff7922),Color(0xFFff871d),
    Color(0xFFff9619),Color(0xFFffa414),
    Color(0xFFffb20f),Color(0xFFffc00a),
    Color(0xFFffce05),Color(0xFFffdc00)
  ];
  int colorIndex = 0;
  bool colorCirle = true;
  static const EventChannel _eventChannel = EventChannel("x_amap_track_event_channel");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pointSql = SqlUtil.setTable("points");
    XAmapTrack.bindLocation();
    _eventChannel.receiveBroadcastStream().listen((data) async{
      final point = json.decode(data);
      point['time'] = DateTime.now().millisecondsSinceEpoch;
      bool isValid = false;
      if(_taskType==TaskType.LESS){
        isValid = pointFilter(point);
      }else{
        isValid = await pf.checkPoint(point);
      }
      if(!isValid){
        return;
      }
      point['taskId'] = _taskId;
      if(_isStart&&data!=null){
        setState(() {
          print('当前点位：$point');
          LatLng value = LatLng(point['lat'],point['lng']);
          isInCheckPoint(value);
          bool flag = false;
          if (_latLngBox.length == 0) {
            _latLngBox.add(value);
            _controller.addMarker(MarkerOption(latLng: value,iconUri: _icon_start,imageConfig: createLocalImageConfiguration(context)));
            return;
          }
          if (_latLngBox.length > 0 && compareLatLng(_latLngBox.elementAt(_latLngBox.length-1),value)) {
            flag = true;
            AmapService.calculateDistance(
                _latLngBox.elementAt(_latLngBox.length - 1), value).then((distance) {
                    _distance += distance;
                });
            }
          if (flag) {
            _latLngBox.add(value);
            pointSql.insert(point);
            List<LatLng> temp = [_latLngBox.elementAt(_latLngBox.length-2),value];
            _controller.addPolyline(PolylineOption(
              lineJoinType: LineJoinType.Round,
              lineCapType: LineCapType.Round,
              latLngList: temp,
              width: 20,
              strokeColor:colors[colorIndex],
            )).then((polyline) {
              if(colorCirle){
                colorIndex++;
              }else{
                colorIndex--;
              }
              colorCirle = colorIndex==11?false:colorIndex==0?true:colorCirle;
              if (_currentPolyline != null) {
                //_currentPolyline.remove();
              }
              _currentPolyline = polyline;
            });
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if(state == AppLifecycleState.paused){
      print("生命周期：暂停");
    }
    if(state == AppLifecycleState.resumed){
      print("生命周期：恢复");
    }
  }

  @override
  void dispose() {
    XAmapTrack.unbindLocation();
    if(_timer!=null){
      _timer.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);//销毁
    super.dispose();
  }

  void start() async{
    if (await requestPermission()) {
      if(_taskId==null){
        taskSql = SqlUtil.setTable("tasks");
        String taskId = await initCode(16);
        Map<String, dynamic> map = new Map();
        map['taskId'] = taskId;
        map['date'] = DateTime.now().millisecondsSinceEpoch;
        taskSql.insert(map);
        setState(() {
          _taskId  = taskId;
        });
      }
      await XAmapTrack.startLocation();
      setState(()=>_isStart = true);
      if(_timer == null){
        _timer = Timer.periodic(_duration, (Timer t){
          setState(() {
            _secondsPassed++;
            _seconds = _secondsPassed % 60;
            _minutes = _secondsPassed ~/ 60;
            _hours = _secondsPassed ~/ (60 * 60);
          });
        });
      }
    }
  }

  void stop() async{
    await XAmapTrack.stopLocation();
    if(_timer!=null){
      _timer.cancel();
    }
    setState(() {
      _timer = null;
      _isStart = false;
    });
    await _controller.dispose();
    Navigator.pop(context);
  }

  void addCheckPoint() async{
    LatLng latLng = await _controller.getCenterCoordinate();
    Marker marker = await _controller.addMarker(MarkerOption(latLng: latLng,draggable:true,iconUri: _icon_check_point,imageConfig: createLocalImageConfiguration(context)));
    _markerList.add(marker);
  }
  void isInCheckPoint(LatLng latlng) async{
    for(int i=0;i<_markerList.length;i++){
      LatLng checkPoint = await _markerList[i].location;
      double distance = await AmapService.calculateDistance(checkPoint, latlng);
      if(distance<10){
        print('经过点位：$_markerList[i]');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    dynamic obj = ModalRoute.of(context).settings.arguments;
    setState(() {
      _taskType = obj["taskType"];
    });
    pf = PointFilter(obj["taskType"]);
    return Scaffold(
        key: _scaffoldKey,
      floatingActionButton: FloatingActionButton(
          onPressed: (){
            if(!_isStart){
              if (obj != null) {
                start();
              }
            }else{
              stop();
            }
          },
          child: !_isStart?Icon(Icons.add):Icon(Icons.remove),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        endDrawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  '设置',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              Text('地图类型'),
              ListTile(
                leading: Icon(Icons.map),
                title: Text('标准视图'),
                trailing: Radio(
                  value: MapType.Standard,
                  groupValue: _curMapType,
                  onChanged: (MapType value) {
                    setState(() { _curMapType = value; });
                    _controller.setMapType(value);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: Icon(Icons.account_circle),
                title: Text('卫星视图'),
                trailing: Radio(
                  value: MapType.Satellite,
                  groupValue: _curMapType,
                  onChanged: (MapType value) {
                    setState(() { _curMapType = value; });
                    _controller.setMapType(value);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      body: SlidingUpPanel(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
        panel:Center(
          child: Text("This is the Widget behind the sliding panel"),
        ),
        collapsed: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0))
            ),
            width: double.infinity,
            height: 90,
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top:12 ),
                      width: 30,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.all(Radius.circular(12.0))
                      ),
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    text: (_distance/1000).toStringAsFixed(2),
                    style: TextStyle(
                        fontSize: 40,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold
                    ),
                    children: <TextSpan>[
                      TextSpan(text: '公里', style: TextStyle(
                          color: Colors.black26,
                          fontSize: 14,
                          fontWeight: FontWeight.bold
                      )),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: _hours.toString().padLeft(2,'0')+':'+_minutes.toString().padLeft(2,'0')+':'+_seconds.toString().padLeft(2,'0'),
                    style: TextStyle(
                        fontSize: 26,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold
                    ),
                    children: <TextSpan>[
                      TextSpan(text: '用时', style: TextStyle(
                          color: Colors.black26,
                          fontSize: 14,
                          fontWeight: FontWeight.bold
                      )),
                    ],
                  ),
                ),
              ],
            )
        ),
        body: Stack(
          children: <Widget>[
            Container(
              width: double.infinity,
              height:double.infinity ,
              child: AmapView(
                // 地图类型
                mapType: MapType.Standard,
                // 是否显示缩放控件
                showZoomControl: false,
                // 是否显示指南针控件
                showCompass: false,
                // 是否显示比例尺控件
                showScaleControl: false,
                // 是否使能缩放手势
                zoomGesturesEnabled: true,
                // 是否使能滚动手势
                scrollGesturesEnabled: true,
                // 是否使能旋转手势
                rotateGestureEnabled: true,
                // 是否使能倾斜手势
                tiltGestureEnabled: true,
                // 缩放级别
                zoomLevel: 15,
                // 中心点坐标
                centerCoordinate: _latLng,
                // 标记
                markers: <MarkerOption>[],
                // 标识点击回调
                onMarkerClicked: (Marker marker) {
                  return;
                },
                // 地图点击回调
                onMapClicked: (LatLng coord) {
                  return;
                },
                // 地图创建完成回调
                onMapCreated: (controller) async {
                  setState(() => _controller = controller);
                  //是否显示定位控件
                  if (await requestPermission()) {
                    await controller.showMyLcation(
                      true,
                      iconUri: _icon_current_location,
                      imageConfig: createLocalImageConfiguration(context)
                    );
                  }
                },
              ),
            ),
            Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.fromLTRB(5, 50, 0, 0),
                child: RaisedButton(
                  padding: EdgeInsets.all(10),
                  color: Colors.white,
                  highlightColor: Colors.white70,
                  colorBrightness: Brightness.dark,
                  splashColor: Colors.grey,
                  child: Icon(Icons.undo,color: Colors.black87,),
                  shape: CircleBorder(),
                  onPressed: (){Navigator.of(context).pop();},
                )
            ),
            Container(
                alignment: Alignment.topRight,
                margin: EdgeInsets.fromLTRB(0, 50, 5, 0),
                child: RaisedButton(
                  padding: EdgeInsets.all(10),
                  color: Colors.white,
                  highlightColor: Colors.white70,
                  colorBrightness: Brightness.dark,
                  splashColor: Colors.grey,
                  child: Icon(Icons.settings,color: Colors.black87,),
                  shape: CircleBorder(),
                  onPressed: (){_scaffoldKey.currentState.openEndDrawer();},
                )
            ),
            Container(
                alignment: Alignment.topRight,
                margin: EdgeInsets.fromLTRB(0, 100, 5, 0),
                child: RaisedButton(
                  padding: EdgeInsets.all(10),
                  color: Colors.white,
                  highlightColor: Colors.white70,
                  colorBrightness: Brightness.dark,
                  splashColor: Colors.grey,
                  child: Icon(Icons.add_location,color: Colors.black87,),
                  shape: CircleBorder(),
                  onPressed: (){addCheckPoint();},
                )
            ),
          ],
        ),
      ),

    );
  }

}