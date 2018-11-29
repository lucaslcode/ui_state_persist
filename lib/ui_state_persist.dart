library ui_state_persist;
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';

const filename = "uistate.json";
const timestampKey = "timestamp";
const routeKey = "route";
const routeArgumentKey = "routeArgument";

/// Handles persisting of UI State
class UIState with RouteAware {
  /// Contains the relevant UI variables
  Map<String, dynamic> _state;

  /// Stores the listenables to avoid using statefulwidgets
  Map<String, dynamic> _listenables = {};

  /// Directory that the file will be written to
  String tempDir;

  /// Ro help stop simultaneous file writing
  Future<Null> lock;

  static final UIState _instance = UIState._();
  UIState._();
  factory UIState() {
    return _instance;
  }

  /// Loads the uistate if it was saved more recently the optional expiry argument, returning the saved route string.
  Future<String> load([Duration expiry]) async {
    //initialize the state map
    _state = {routeKey: "/"};
    try {
      tempDir = (await getTemporaryDirectory()).path;
      File stateFile = File(path.join(tempDir, filename));
      String data;
      if (await stateFile.exists()) {
        data = await stateFile.readAsString();
      } else {
        data = "{}";
      }
      Map<String, dynamic> decoded = jsonDecode(data);
      if (!decoded.containsKey(timestampKey) || expiry == null
          || DateTime.parse(decoded[timestampKey]).add(expiry).isAfter(DateTime.now())) {
        _state = decoded;
      }
    } catch (e) {
      return Future.error(e);
    }
    return _state[routeKey];
  }

  /// Updates the value and writes the state. Can be called with no arguments to write the current state.
  Future<void> _update([String key, dynamic value]) async {
    if (key != null) {
      _state[key] = value;
    }

    if (lock != null) {
      await lock;
      return _update(key, value);
    }
    var completer = Completer<Null>();
    lock = completer.future;

    _state[timestampKey] = DateTime.now().toIso8601String();
    try {
      File stateFile = File(path.join(tempDir, filename));
      String data = jsonEncode(_state);
      await stateFile.writeAsString(data);

      completer.complete();
      lock = null;
    } catch (e) {
      completer?.complete();
      lock = null;
      print(e.toString());
      return Future.error(e);
    }
  }

  /// Empties the state without writing it.
  void clear() {
    _listenables.clear();
    _state.clear();
    _state[routeKey] = "/";
  }

  /// Returns the current route that is persisted.
  String get route => getRaw<String>(routeKey);

  set route(String value) => _update(routeKey, value);

  dynamic get routeArgument => getRaw<dynamic>(routeArgumentKey);

  set routeArgument(dynamic value) =>  _update(routeArgumentKey, value);

  /// Returns the requested part of the ui state that is Listenable.
  T useListenable<T>(String key) {
    // If the listenable is already in _listenables, it's already being listened to
    if (_listenables.containsKey(key)) return _listenables[key];

    // Should return the stored var from state or a 'blank' variable if key doesn't exists,
    // and listen to changes
    switch (T) {
      case ScrollController:
        _listenables[key] = ScrollController(
          initialScrollOffset: _state.containsKey(key) ? _state[key] : 0.0
        );
        _listenables[key].addListener(
          () => _update(key, _listenables[key].offset)
        );
        break;
      case TextEditingController:
        _listenables[key] = TextEditingController(
          text: _state.containsKey(key) ? _state[key] : ""
        );
        _listenables[key].addListener(
          () => _update(key, _listenables[key].text)
        );
        break;
      case ValueNotifier:
        _listenables[key] = ValueNotifier(
          _state.containsKey(key) ? _state[key] : null
        );
        _listenables[key].addListener(
          () => _update(key, _listenables[key].value)
        );
        break;
      default:
        throw UnimplementedError("Not yet supported by ui_state_persist.");
    }
    return _listenables[key];
  }

  /// Returns a value that must be later updated manually, or null if it doesn't exist.
  T getRaw<T>(String key) {
    return _state.containsKey(key) ? _state[key] as T : null;
  }

  /// Set a value manually.
  void setRaw(String key, dynamic value) {
    _update(key, value);
  }
}
