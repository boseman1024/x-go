import 'package:flutter/material.dart';
import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'package:x_gogo/db/sqlUtil.dart';
import 'package:x_gogo/utils/utils.export.dart';

final _icon_start = Uri.parse('images/icon_start.png');
final _icon_end = Uri.parse('images/icon_end.png');

class MapLog extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return MapLogState();
  }
}

class MapLogState extends State<MapLog>{
  AmapController _controller;
  LatLng _latLng = LatLng(39, 116);
  List<LatLng> _latLngBox = [];
  Polyline _polyline;

  @override
  void initState() {
    super.initState();
  }

  void  getTasks(taskId) async{
    var sql = SqlUtil.setTable("points");
    Map<dynamic, dynamic> map = new Map();
    map['taskId'] = taskId;
    List list = await sql.query(map);
    for(final i in list){
      print(i);
      LatLng latLng = LatLng(i['lat'], i['lng']);
      setState(() {
        _latLng = latLng;
        _latLngBox.add(latLng);
      });
    }
    await _controller.zoomToSpan(_latLngBox);
    drawLine(_latLngBox);
    addMarker(_latLngBox.elementAt(0),_latLngBox.elementAt(_latLngBox.length-1));
  }

  void addMarker(LatLng start,LatLng end){
    _controller.addMarker(MarkerOption(latLng:start,iconUri: _icon_start,imageConfig: createLocalImageConfiguration(context)));
    _controller.addMarker(MarkerOption(latLng:end,iconUri: _icon_end,imageConfig: createLocalImageConfiguration(context)));
  }

  void drawLine(List<LatLng> latlngBox) async{
   await _controller.addPolyline(PolylineOption(
      lineJoinType: LineJoinType.Round,
      lineCapType: LineCapType.Round,
      latLngList: latlngBox,
      width: 20,
      strokeColor:Colors.orangeAccent,
    )).then((polyline) {
      setState(() {
        _polyline = polyline;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    dynamic obj = ModalRoute.of(context).settings.arguments;
    return Scaffold(
        appBar: AppBar(
          title: Text('记录'),
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
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.track_changes),
              onPressed: (){
                _polyline.remove();
                for(int i=0;i<_latLngBox.length-5;i++){
                  List<LatLng> temp = optimizePoints(_latLngBox.getRange(i, i+5).toList());
                  _latLngBox.setRange(i, i+5, temp);
                }
                drawLine(_latLngBox);
              },
              tooltip: '优化轨迹',
            )
          ],
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
                  if (obj != null) {
                    getTasks(obj["taskId"]);
                  }
                },
              ),
            ),
          ],
        )
    );
  }

}