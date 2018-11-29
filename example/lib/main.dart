import 'package:flutter/material.dart';
import 'package:ui_state_persist/ui_state_persist.dart';

const viewRoute = "/view";

@immutable
class Entry {
  final int index;
  final Color color;
  Entry({this.index, this.color});
  Entry.fromJson(Map<String, dynamic> json) :
    index = json["index"],
    color = Color(json["color"]);
  Map<String, dynamic> toJson() => {
    "index": index,
    "color": color.value,
  };
}

void main() async {
  await UIState().load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ui_state_persist example',
      //make sure to set the initialRoute
      initialRoute: UIState().route,
      //note there is no "home" or anything else for the routes, just onGenerateRoute
      onGenerateRoute: (routeSettings) {
        //Route name is set here but not cleared, because of arguments.
        //This means is won't get cleared when restoring to a deeply-nested
        //route and pressing/swiping 'back'
        UIState().route = routeSettings.name;
        switch (routeSettings.name) {
          case "/":
            return MaterialPageRoute(
              builder: (context) => MyHomePage(title: 'ui_state_persist example')
            );
          case viewRoute:
            return MaterialPageRoute(
              builder: (context) => ViewPage(Entry.fromJson(UIState().routeArgument))
            );
        }
      }
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = UIState().getRaw("counter") ?? 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    UIState().setRaw("counter", _counter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        controller: UIState().useListenable<ScrollController>("scroll1"),
        itemCount: 100,
        itemBuilder: (context, i) => MaterialButton(
          onPressed: ()  {
            //clear first
            UIState().clear();
            // then set the routeArgument (null if not needed)
            UIState().routeArgument = Entry(
              index: i + _counter,
              color: HSVColor.fromAHSV(1.0, i/100 * 360, 1.0, 1.0).toColor(),
            ).toJson();
            //then navigate using pushNamed
            Navigator.of(context).pushNamed(viewRoute);
          },
          child: Text('${_counter + i}',
            style: Theme.of(context).textTheme.display1,
          ),
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), 
    );
  }
}


class ViewPage extends StatelessWidget {
  final Entry entry;
  ViewPage(this.entry);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("View"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(entry.index.toString()),
            Icon(Icons.sentiment_satisfied, size: 72.0, color: entry.color),
            TextField(
              controller: UIState().useListenable<TextEditingController>("textedit1"),
              decoration: InputDecoration(labelText: "Comments"),
            )
          ],
        ),
      ),
    );
  }
}