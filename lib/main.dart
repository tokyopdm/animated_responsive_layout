import 'package:flutter/material.dart';

// animated_responsive_layout codelab imports
import 'animations.dart';
import 'models/data.dart' as data;
import 'models/models.dart';
import 'transitions/list_detail_transition.dart';
import 'widgets/animated_floating_action_button.dart';
import 'widgets/disappearing_bottom_navigation_bar.dart';  // Add import
import 'widgets/disappearing_navigation_rail.dart';        // Add import
import 'widgets/email_list_view.dart';
import 'widgets/reply_list_view.dart';

// soloud codelab imports
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'audio/audio_controller.dart';

void main() async {
  // The `flutter_soloud` package logs everything
  // (from severe warnings to fine debug messages)
  // using the standard `package:logging`.
  // You can listen to the logs as shown below.
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;
  Logger.root.onRecord.listen((record) {
    dev.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });

  WidgetsFlutterBinding.ensureInitialized();

  final audioController = AudioController();
  await audioController.initialize();

  runApp(MyApp(audioController: audioController));
  //runApp(const MainApp());
}

class MyApp extends StatelessWidget {
  const MyApp({required this.audioController, super.key});

  final AudioController audioController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SoLoud Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: MyHomePage(audioController: audioController),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.audioController});

  final AudioController audioController;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _gap = SizedBox(height: 16);

  bool filterApplied = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter SoLoud Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            OutlinedButton(
              onPressed: () {
                widget.audioController.playSound('assets/sounds/pew1.mp3');
              },
              child: const Text('Play Sound'),
            ),
            _gap,
            OutlinedButton(
              onPressed: () {
                widget.audioController.startMusic();
              },
              child: const Text('Start Music'),
            ),
            _gap,
            OutlinedButton(
              onPressed: () {
                widget.audioController.fadeOutMusic();
              },
              child: const Text('Fade Out Music'),
            ),
            _gap,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Apply Filter'),
                Checkbox(
                  value: filterApplied,
                  onChanged: (value) {
                    setState(() {
                      filterApplied = value!;
                    });
                    if (filterApplied) {
                      widget.audioController.applyFilter();
                    } else {
                      widget.audioController.removeFilter();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: Feed(currentUser: data.user_0),
    );
  }
}

class Feed extends StatefulWidget {
  const Feed({super.key, required this.currentUser});

  final User currentUser;

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> with SingleTickerProviderStateMixin {
  late final _colorScheme = Theme.of(context).colorScheme;
  late final _backgroundColor = Color.alphaBlend(
    _colorScheme.primary.withAlpha(36),
    _colorScheme.surface,
  );

  late final _controller = AnimationController(
    duration: const Duration(milliseconds: 1000),
    reverseDuration: const Duration(milliseconds: 1250),
    value: 0,
    vsync: this,
  );
  late final _railAnimation = RailAnimation(parent: _controller);
  late final _railFabAnimation = RailFabAnimation(parent: _controller);
  late final _barAnimation = BarAnimation(parent: _controller);

  int selectedIndex = 0;

  bool controllerInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final double width = MediaQuery.of(context).size.width;

    final AnimationStatus status = _controller.status;
    if (width > 600) {
      if (status != AnimationStatus.forward &&
          status != AnimationStatus.completed) {
        _controller.forward();
      }
    } else {
      if (status != AnimationStatus.reverse &&
          status != AnimationStatus.dismissed) {
        _controller.reverse();
      }
    }
    if (!controllerInitialized) {
      controllerInitialized = true;
      _controller.value = width > 600 ? 1 : 0;
    }
  
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          body: Row(
            children: [
              DisappearingNavigationRail(
                railAnimation: _railAnimation,
                railFabAnimation: _railFabAnimation,
                selectedIndex: selectedIndex,
                backgroundColor: _backgroundColor,
                onDestinationSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              ),
              Expanded(
                child: Container(
                  color: _backgroundColor,
                  child: ListDetailTransition(
                    animation: _railAnimation,
                    one: EmailListView(
                      selectedIndex: selectedIndex,
                      onSelected: (index) {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      currentUser: widget.currentUser,
                    ),
                    two: const ReplyListView(),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: AnimatedFloatingActionButton(
            animation: _barAnimation,
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: DisappearingBottomNavigationBar(
            barAnimation: _barAnimation,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}