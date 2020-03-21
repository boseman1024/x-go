import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'package:x_gogo/map/taskType.dart';


class PointFilter {

  bool isFirst = true;
  var weight1 = {};
  var weight2 = {};
  List w1List = [];
  List w2List = [];
  num w1Count = 0;
  num MAN_MAX_SPEED = 10;
  List pointList = [];
  TaskType taskType = TaskType.WALK;

  PointFilter(taskType){
    if(taskType==TaskType.WALK){
      MAN_MAX_SPEED = 5;
    }
    if(taskType==TaskType.RIDING){
      MAN_MAX_SPEED = 10;
    }
    if(taskType==TaskType.DRIVING){
      MAN_MAX_SPEED = 30;
    }
  }

  Future<bool> checkPoint(var point) async{
    try{
      print('轨迹过滤：点$point');
      if(isFirst){
        isFirst = false;
        weight1['lat'] = point['lat'];
        weight1['lng'] = point['lng'];
        weight1['speed'] = point['speed'];
        weight1['time'] = point['time'];
        w1List.add(point);
        w1Count++;
        print('轨迹过滤：初次定位');
        return true;
      }else{
        //速度小于1米，归于静止状态
        if(point['speed']<1){
          print('轨迹过滤：静止');
          return false;
        }
        print('轨迹过滤：${point['time']},${weight1['time']},${weight2}');
        if(weight2.length==0){
          num offsetTimeMils = point['time'] - weight1['time'];
          num offsetTimes = offsetTimeMils/1000;
          num maxDistance = offsetTimes * MAN_MAX_SPEED;
          num distance = await AmapService.calculateDistance(LatLng(weight1['lat'], weight1['lng']),LatLng(point['lat'], point['lng']));
          if(distance>maxDistance){
            weight2['lat'] = point['lat'];
            weight2['lng'] = point['lng'];
            weight2['speed'] = point['speed'];
            weight2['time'] = point['time'];
            w2List.add(point);
            return false;
          }else{
            w1List.add(point);
            w1Count++;
            weight1['lat'] = weight1['lat']*0.2 + point['lat']*0.8;
            weight1['lng'] = weight1['lng']*0.2 + point['lng']*0.8;
            weight1['speed'] = point['speed'];
            weight1['time'] = point['time'];
            if(w1List.length>3){
              pointList.addAll(w1List);
              w1List.clear();
              return true;
            }else{
              return false;
            }
          }
        }else{
          num offsetTimeMils = point['time'] - weight2['time'];
          num offsetTimes = offsetTimeMils/1000;
          num maxDistance = offsetTimes * MAN_MAX_SPEED;
          num distance = await AmapService.calculateDistance(LatLng(weight2['lat'], weight2['lng']),LatLng(point['lat'], point['lng']));

          if(distance>maxDistance){
              w2List.clear();
              weight2['lat'] = point['lat'];
              weight2['lng'] = point['lng'];
              weight2['speed'] = point['speed'];
              weight2['time'] = point['time'];
              w2List.add(point);
              return false;
          }else{
            w2List.add(point);
            weight2['lat'] = weight2['lat']*0.2 + point['lat']*0.8;
            weight2['lng'] = weight2['lng']*0.2 + point['lng']*0.8;
            weight2['speed'] = point['speed'];
            weight2['time'] = point['time'];

            if(w2List.length>4){
              if(w1Count>4){
                pointList.addAll(w1List);
              }else{
                w1List.clear();
              }
              pointList.addAll(w2List);
              w2List.clear();
              weight1 = weight2;
              weight2 = null;
              return true;
            }else{
              return false;
            }

          }

        }
      }

    }catch(e){
      print('轨迹过滤错误：$e');
    }
  }
}