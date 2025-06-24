import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../splash.dart';
import '../home.dart';
import '../utils.dart';
import 'admin_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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

        final cred =
            await _auth.signInWithEmailLink(email: email, emailLink: link);
        await createOrUpdateUserInFirestore(cred.user!);

        await prefs.remove('macos_email_link');
        await prefs.remove('email_for_signin');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProfileScreen(beatsReady: widget.beatsReady)),
        );
      }
    } catch (e) {
      print('🔗 Error processing macOS sign-in link: $e');
      if (e is FirebaseAuthException && e.message != null) {
        print('🔐 Keychain error details: ${e.message}');
      } else {
        print('⚠️ Sign-in error: $e');
      }
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
      final cred =
          await _auth.signInWithEmailLink(email: email, emailLink: link);
      await createOrUpdateUserInFirestore(cred.user!);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ProfileScreen(beatsReady: widget.beatsReady)),
      );
    } catch (e) {
      print("❌ Manual ####### sign-in failed: $e");
      if (e is FirebaseAuthException) {
        debugPrint('🔥 FirebaseAuthException: ${e.code}');
        debugPrint('Message: ${e.message}');
        debugPrint('Details: ${e.toString()}');
      } else {
        debugPrint('❌ Unknown error: $e');
      }
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
      //change to true before publishing
      androidInstallApp: false,
      androidMinimumVersion: '21',
      //dynamicLinkDomain: 'vasisbeats.page.link',
    );

    try {
      await _auth.sendSignInLinkToEmail(
          email: email, actionCodeSettings: actionCodeSettings);
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
                    MaterialPageRoute(
                        builder: (_) =>
                            ProfileScreen(beatsReady: widget.beatsReady)),
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
                    decoration:
                        InputDecoration(labelText: "Email sign-in link"),
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

Future<void> createOrUpdateUserInFirestore(User user) async {
  final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final snapshot = await docRef.get();

  final adminDoc =
      await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
  final isAdmin = adminDoc.exists;
  final userEmail = user.email ?? "";
  if (!snapshot.exists) {
    await docRef.set({
      'userId': user.uid,
      'userName': userEmail.split('@').first,
      'email': user.email ?? '',
      'role': isAdmin ? 'admin' : 'user',
      'account_type': 'free',
      'donation_amount': 0.0,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}

class ProfileScreen extends StatelessWidget {
  final bool beatsReady;

  ProfileScreen({required this.beatsReady});

  Future<Map<String, dynamic>> _getUserData(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final isAdmin =
        (await FirebaseFirestore.instance.collection('admins').doc(uid).get())
            .exists;
    return {
      ...data,
      'is_admin': isAdmin,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/vasis.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.3), // semi-transparent overlay for readability
          child: FutureBuilder<Map<String, dynamic>>(
            future: _getUserData(user!.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              final data = snapshot.data!;
              final userName = data['userName'] ?? "N/A";
              final email = data['email'] ?? "N/A";
              final accountType = data['role'] == 'admin'
                  ? "Paid (Admin)"
                  : data['account_type'] ?? "Free";
              final donation = data['donation_amount'] ?? 0.0;
              final isAdmin = data['is_admin'] ?? false;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // User Info + Profile Pic
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('images/default_profile.png'),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Username: $userName"),
                              Text("Email: $email"),
                              Text("Account Type: $accountType"),
                              Text(
                                  "Donation Amount: \$${donation.toStringAsFixed(1)}"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                // Donate Section
                Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Donate to Vasis Studios and Send Details to vasisbeats@gmail.com",
                            style: Theme.of(context).textTheme.titleMedium),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Image.asset(
                                  'images/upi_qr.png',
                                  height: 160,
                                  width: 160,
                                  fit: BoxFit.contain, // Ensures no distortion
                                ),
                                SizedBox(height: 10),
                                Text("Donate with UPI"),
                              ],
                            ),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    launchUrl(Uri.parse(
                                        "https://www.paypal.com/paypalme/bhagavatikumar"));
                                  },
                                  icon: Icon(Icons.payment),
                                  label: Text("Donate via PayPal"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Spacer(),

                // Footer buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  EmailLinkSignInScreen(beatsReady: true)),
                          (_) => false,
                        );
                      },
                      child: Text("Sign Out"),
                    ),
                    if (isAdmin)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => AdminPanelScreen()));
                        },
                        child: Text("Admin Panel"),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => data['beatsReady'] == true
                                  ? HomeScreen()
                                  : SplashScreen()),
                        );
                      },
                      child: Text("Go to Beats"),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    )
      )
    );
  }
}
