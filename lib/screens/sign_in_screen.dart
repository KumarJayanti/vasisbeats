import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../splash.dart';
import '../home.dart';

class EmailLinkSignInScreen extends StatefulWidget {
  final bool beatsReady;
  EmailLinkSignInScreen({required this.beatsReady});

  @override
  _EmailLinkSignInScreenState createState() => _EmailLinkSignInScreenState();
}

class _EmailLinkSignInScreenState extends State<EmailLinkSignInScreen> {
  final _emailController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isSendingLink = false;
  bool _isSigningIn = false;
  bool _linkSent = false;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkForStoredLink();
  }

  Future<void> _checkForStoredLink() async {
    if (!Platform.isMacOS) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final link = prefs.getString('macos_email_link');
      final email = prefs.getString('email_for_signin');

      if (link != null && email != null && _auth.isSignInWithEmailLink(link)) {
        setState(() => _isSigningIn = true);
        await _auth.signInWithEmailLink(email: email, emailLink: link);
        await prefs.remove('macos_email_link');
        await prefs.remove('email_for_signin');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen(beatsReady: widget.beatsReady)),
        );
      }
    } catch (e) {
      print('🔗 Error processing macOS sign-in link: $e');
    } finally {
      setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signInManually() async {
    final email = _emailController.text.trim();
    final link = _linkController.text.trim();

    if (email.isEmpty || link.isEmpty) return;

    if (!_auth.isSignInWithEmailLink(link)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid sign-in link.")),
      );
      return;
    }

    try {
      setState(() => _isSigningIn = true);
      await _auth.signInWithEmailLink(email: email, emailLink: link);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen(beatsReady: widget.beatsReady)),
      );
    } catch (e) {
      print("❌ Manual sign-in failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Manual sign-in failed. Try again.")),
      );
    } finally {
      setState(() => _isSigningIn = false);
    }
  }

  Future<void> _sendSignInLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSendingLink = true);
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://vasis-beats.web.app/emailSignInRedirect',
      handleCodeInApp: true,
      iOSBundleId: 'dev.spiritsoft.flutterAudioServiceDemo',
      androidPackageName: 'dev.suragch.flutter_audio_service_demo',
      androidInstallApp: true,
      androidMinimumVersion: '21',
      dynamicLinkDomain: 'vasisbeats.page.link',
    );

    try {
      await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: actionCodeSettings);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email_for_signin', email);
      setState(() => _linkSent = true);
      print("📧 Sign-in link sent to $email");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📩 Sign-in link sent to $email'),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print("❌ Failed to send sign-in link: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send link. Check your Firebase setup."),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSendingLink = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Signed out successfully.")),
    );
    setState(() {
      _linkSent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Email Link Sign-In")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentUser != null) ...[
                Text("👋 Welcome, ${currentUser.email}"),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileScreen(beatsReady: widget.beatsReady)),
                  ),
                  child: Text("Go to Profile"),
                ),
                ElevatedButton(
                  onPressed: _signOut,
                  child: Text("Sign Out"),
                ),
              ] else ...[
                Text("Enter your email to receive a sign-in link:"),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: "Email"),
                ),
                SizedBox(height: 20),
                _isSendingLink
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _sendSignInLink,
                        child: Text("Send Sign-In Link"),
                      ),
                if (_linkSent)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      "✅ Email sent. Please check your inbox.",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                if (Platform.isMacOS) ...[
                  SizedBox(height: 30),
                  Text("Paste the sign-in link you received:"),
                  TextField(
                    controller: _linkController,
                    decoration: InputDecoration(labelText: "Email sign-in link"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _signInManually,
                    child: Text("Sign In with Link"),
                  ),
                ],
              ],
              if (_isSigningIn) ...[
                SizedBox(height: 20),
                CircularProgressIndicator(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final bool beatsReady;
  ProfileScreen({required this.beatsReady});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Email: ${user?.email ?? "Unknown"}"),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => EmailLinkSignInScreen(beatsReady: beatsReady)),
                  (_) => false,
                );
              },
              child: Text("Sign Out"),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => beatsReady ? HomeScreen() : SplashScreen()),
                );
              },
              child: Text("Go to Beats"),
            ),
          )
        ],
      ),
    );
  }
}
