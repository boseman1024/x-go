import 'package:amap_map_fluttify/amap_map_fluttify.dart';

bool compareLatLng(LatLng var1,LatLng var2){
  return var1.latitude != var2.latitude && var1.longitude != var2.longitude;
}

bool pointFilter(Map point){
  return point['trustedLevel']<4||point['accuracy']<=30;
}
//平滑轨迹
List<LatLng> optimizePoints(List<LatLng> list){
  int size = list.length;
  if(size<5){
    return list;
  }else{
    list.elementAt(0).latitude = (3.0*list.elementAt(0).latitude+2.0*list.elementAt(1).latitude+list.elementAt(2).latitude-list.elementAt(4).latitude)/5.0 ;
    list.elementAt(1).latitude = (4.0*list.elementAt(0).latitude+3.0*list.elementAt(1).latitude+2*list.elementAt(2).latitude+list.elementAt(3).latitude)/10.0;
    list.elementAt(size-2).latitude = (4.0*list.elementAt(size-1).latitude+3.0*list.elementAt(size-2).latitude+2*list.elementAt(size-3).latitude+list.elementAt(size-4).latitude)/10.0;
    list.elementAt(size-1).latitude = (3.0*list.elementAt(size-1).latitude+2.0*list.elementAt(size-2).latitude+list.elementAt(size-3).latitude-list.elementAt(size-5).latitude)/5.0;

    list.elementAt(0).longitude = (3.0*list.elementAt(0).longitude+2.0*list.elementAt(1).longitude+list.elementAt(2).longitude-list.elementAt(4).longitude)/5.0;
    list.elementAt(1).longitude = (4.0*list.elementAt(0).longitude+3.0*list.elementAt(1).longitude+2*list.elementAt(2).longitude+list.elementAt(3).longitude)/10.0;
    list.elementAt(size-2).longitude = (4.0*list.elementAt(size-1).longitude+3.0*list.elementAt(size-2).longitude+2*list.elementAt(size-3).longitude+list.elementAt(size-4).longitude)/10.0;
    list.elementAt(size-1).longitude = (3.0*list.elementAt(size-1).longitude+2.0*list.elementAt(size-2).longitude+list.elementAt(size-3).longitude-list.elementAt(size-5).longitude)/5.0;
  }
  return list;
}