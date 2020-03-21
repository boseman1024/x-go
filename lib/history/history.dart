import 'package:flutter/material.dart';
import 'package:x_gogo/db/sqlUtil.dart';
import 'package:x_gogo/map/taskType.dart';
import 'package:flutter_rounded_date_picker/rounded_picker.dart';

class History extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return HistoryState();
  }
}

class HistoryState extends State<History> with WidgetsBindingObserver{
  List<Widget> widgets = [];
  DateTime _curDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getTasks();
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
    if(state == AppLifecycleState.detached){
      print("生命周期：detached");
    }
    if(state == AppLifecycleState.inactive){
      print("生命周期：inactive");
    }
  }

  void  getTasks() async{
    var sql = SqlUtil.setTable("tasks");
    int startDate = DateTime(_curDate.year,_curDate.month,_curDate.day).millisecondsSinceEpoch;
    int endDate = startDate+24*60*60*1000;
    List list = await sql.rawQuery('select * from tasks where date >=? and date <=? order by date desc', [startDate,endDate]);
    print('数据：${startDate},${endDate},$list');
    widgets = [];
    setState(() {
      for(final i in list){
        DateTime iDate = DateTime.fromMillisecondsSinceEpoch(i['date']);
        widgets.add(
            ListTile(
              title: Text('${i['taskId']} ${iDate.hour}时${iDate.minute}分'),
              onTap: (){
                Navigator.of(context).pushNamed('/log', arguments: {"taskId": i['taskId']});
              },
            )
        );
        if(i!=list.elementAt(list.length-1)){
          widgets.add(Divider(color: Colors.black12,indent:10,endIndent:10,height: 1,));
        }
      }
    });
    print('获取记录结束');
  }



  void changeDate() async{
    DateTime newDateTime = await showRoundedDatePicker(
      context: context,
      theme: ThemeData(primarySwatch: Colors.blue),
      imageHeader: AssetImage("images/calendar_header.jpg"),
      description: "选择日期，查询记录。",
    );
    if(newDateTime!=null){
      setState(() {
        _curDate = newDateTime;
      });
      getTasks();
    }
  }

  Future<void> askTaskType() async {
    switch (await showDialog<TaskType>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('选择出行方式'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, TaskType.LESS); },
                child: const Text('简单'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, TaskType.WALK); },
                child: const Text('步行'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, TaskType.RIDING); },
                child: const Text('骑行'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, TaskType.DRIVING); },
                child: const Text('驾车'),
              ),
            ],
          );
        }
    )) {
      case TaskType.LESS:
        Navigator.pushNamed(context, '/map',arguments: {"taskType": TaskType.LESS});
        break;
      case TaskType.WALK:
        Navigator.pushNamed(context, '/map',arguments: {"taskType": TaskType.WALK});
        break;
      case TaskType.RIDING:
        Navigator.pushNamed(context, '/map',arguments: {"taskType": TaskType.RIDING});
        break;
      case TaskType.DRIVING:
        Navigator.pushNamed(context, '/map',arguments: {"taskType": TaskType.DRIVING});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text("${_curDate.year}年${_curDate.month}月${_curDate.day}日"),
        centerTitle: true,
        backgroundColor: Colors.white,
        textTheme: TextTheme(
            title: TextStyle(
                color: Colors.black
            )
        ),
        iconTheme: IconThemeData(
          color: Colors.black
        ),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: (){
                changeDate();
              },
              tooltip: '查询日期',
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          askTaskType();
        },
        child: Icon(Icons.play_arrow),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      body: RefreshIndicator(
        child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: false,
            // 内容
            slivers: <Widget>[
              new SliverPadding(
                  padding: const EdgeInsets.all(0),
                  sliver: new SliverList(
                      delegate: new SliverChildListDelegate(
                          <Widget>[
                            Container(
                                color: Colors.white,
                                child: Wrap(
                                  children: widgets,
                                )
                            )
                          ])
                  )
              )]),
        onRefresh: ()async{
          getTasks();
        },
      ),
    );
  }

}