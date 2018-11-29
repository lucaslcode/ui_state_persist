#  ui_state_persist

  

When mobile devices are out of memory, they tell apps to save their state, then kill them. This means Flutter apps can sometimes (or often, for low-memory devices) go back to the beginning when multi-tasking. Flutter doesn't expose the Android or iOS "native" ways of restoring state [(see issue here)](https://github.com/flutter/flutter/issues/6827). This library tries to provide a Dart-only solution, with some limitations.

  

##  How to use this library
### Load the state
`UIState` is a singleton class. This means you can access it anywhere with `UIState()`. You need to load it first:

    void  main() async {
        await  UIState().load();
        runApp(MyApp());
    }
If anyone can think of a better way to access/setup this class that is more testing-friendly or less "global", please open an issue/let me know!

### Routing
This is a bit awkward. It should be better once [named routes can be used with parameters](https://github.com/flutter/flutter/issues/6225).
You must set up routing like this:

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
                case "/view":
                    return MaterialPageRoute(
                    	builder: (context) => ViewPage(Entry.fromJson(UIState().routeArgument))
                    );
                }
            }
        );
    }
Then when you want to go to a different page:

    MaterialButton(
      onPressed: ()  {
        //clear first
        UIState().clear();
        // then set the routeArgument (null if not needed)
        UIState().routeArgument = Entry(
          index: i + _counter,
          color: HSVColor.fromAHSV(1.0, i/100 * 360, 1.0, 1.0).toColor(),
        ).toJson();
        //then navigate using pushNamed
        Navigator.of(context).pushNamed("/view");
      },
      ...
    )
    
### Listenables
Controllers, animations, FocusNodes, etc. are all listenables in flutter. Right now only `ScrollController`, `TextEditingController` and `ValueNotifier` are supported. It's easy to add more, which I will be doing, or pull requests are welcome.

To use a listenable, follow this example in your build method:

	TextField(
		controller: UIState().useListenable<TextEditingController>("textedit1"),
		decoration: InputDecoration(labelText: "Comments"),
	)
    
Tip: you can use [`ValueNotifier`](https://docs.flutter.io/flutter/foundation/ValueNotifier-class.html) to wrap a variable and it will be auto-magically persisted.

### Streams
I plan on adding a `useStream(String key, Stream stream)` function to use with BLoCs easily.

### Manually persisting variables
Use `getRaw<T>(String key)` to manually get a variable, but it won't be updated unless you call `setRaw(String key, dynamic value)`.

### Using with Custom Classes
This library uses jsonEncode and jsonDecode. This means you can use it with your own models/classes - just implement `toJson()` and `fromJson()`. Note that loading a custom class will return a `Map<String, dynamic>`, so you have to pass it to your `toJson()`.

Example:

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
Using in a `MaterialPageRoute`:

    return MaterialPageRoute(
      builder: (context) => ViewPage(Entry.fromJson(UIState().routeArgument))
    );
    
Setting the routeArgument. Note the use of `toJson()`

	UIState().routeArgument = Entry(
      index: i + _counter,
      color: HSVColor.fromAHSV(1.0, i/100 * 360, 1.0, 1.0).toColor(),
    ).toJson();
    
  ## Limitations
  - This is really just an experiment. Use at your own risk
  - It's a Very Bad Idea to use this to manage your App State, since it only does one page at a time.
  - Only the `routeArgument` to the top route is preserved, and the top route's UI State. I will probably fix this first
  - No tests yet