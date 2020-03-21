import 'package:flutter/material.dart';

class Me extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return MeState();
  }
}

class MeState extends State<Me>{
  List<Widget> initList(){
    return <Widget>[
      ListTile(
        leading: FlutterLogo(size: 24.0),
        title: Text('设置'),
        trailing: Icon(Icons.chevron_right),
        onTap: (){
          Navigator.pushNamed(context, '/setting');
        },
      ),
    ];
  }
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white54,
        body: Column(
          children: <Widget>[
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.only( top: 40),
              margin: const EdgeInsets.only( bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    bottom: BorderSide(color: Colors.black12,width: 1)
                ),
              ),
              child: Text('个人信息'),
            ),
            Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: Colors.black12,width: 1),
                      bottom: BorderSide(color: Colors.black12,width: 1)
                  ),
                ),
                child: Wrap(
                  children: initList(),
                )
            ),

          ],
        )
    );
  }

}
