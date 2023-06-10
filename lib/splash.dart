import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import 'main.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  route() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => HomeScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  static const colorizeColors = [
    Colors.purple,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];

  static const colorizeTextStyle = TextStyle(
    fontSize: 20.0,
    fontFamily: 'Horizon',
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProgress>(
      builder: (context, downloadProgress, _) {
        final percent = downloadProgress.percentDownloaded * 100;
        //print(downloadProgress.percentDownloaded);
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/vasis.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 20.0,
                    ),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        ColorizeAnimatedText(
                          'Downloading Beats Files...',
                          textStyle: colorizeTextStyle,
                          colors: colorizeColors,
                        )
                      ],
                      isRepeatingAnimation: true,
                      onTap: () {
                        print("Tap Event");
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${percent.toStringAsFixed(1)}% Downloaded',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 15.0,
                    ),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        WavyAnimatedText('__/\\o_ Kirtan For Life _o/\\__',
                            textStyle: TextStyle(color: Colors.purple)),
                      ],
                      isRepeatingAnimation: true,
                      onTap: () {
                        print("Tap Event");
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
