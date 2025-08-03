import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
    /*
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://vasis-beats.web.app/emailSignInRedirect',
      handleCodeInApp: true,
      iOSBundleId: 'dev.spiritsoft.flutterAudioServiceDemo',
      androidPackageName: 'dev.suragch.flutter_audio_service_demo',
      //change to true before publishing
      androidInstallApp: false,
      androidMinimumVersion: '21',
      //dynamicLinkDomain: 'vasisbeats.page.link',
    );*/

    final actionCodeSettings = ActionCodeSettings(
      url: 'https://vasis-beats.web.app/emailSignInRedirect',
      handleCodeInApp: true,
      iOSBundleId: 'dev.spiritsoft.flutterAudioServiceDemo',
      androidPackageName: 'dev.suragch.flutter_audio_service_demo',
      androidInstallApp: false,
      androidMinimumVersion: '21',
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
        appBar: AppBar(
          title: Text("Email Link Sign-In"),
          backgroundColor: Colors.purple,
        ),
        body: Stack(children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'images/vasis.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
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
                            builder: (context) =>
                                ProfileScreen(beatsReady: widget.beatsReady)),
                      ),
                      child: Text("Go to Profile"),
                    ),
                    ElevatedButton(
                      onPressed: _signOut,
                      child: Text("Sign Out"),
                    ),
                  ] else ...[
                    Text(
                      "Enter your email to receive a sign-in link:",
                      style: TextStyle(color: Colors.purple),
                    ),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: Colors.purple),
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.bold),
                      ),
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
                      Text(
                        "Paste the sign-in link you received:",
                        style: TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: _linkController,
                        style: TextStyle(color: Colors.purple),
                        decoration: InputDecoration(
                          labelText: "Email sign-in link",
                          labelStyle: TextStyle(
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold),
                        ),
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
          )
        ]));
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
      'photo_url': 'https://storage.googleapis.com/vasis/default_profile.png',
    });
  }
}

class ProfileScreen extends StatefulWidget {
  final bool beatsReady;

  ProfileScreen({required this.beatsReady});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isEditing = false;
  bool _isUpdating = false;

  // Donation amount dropdown
  final List<int> _donationAmounts = [5, 10, 15, 20];
  int _selectedDonationAmount = 5;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(
      text: user?.displayName ?? (user?.email?.split('@').first ?? ""),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isUpdating = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update in Firebase Auth
        await user.updateDisplayName(newName);
        await user.reload();

        // Update in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'userName': newName,
          'updated_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Username updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update username: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _isEditing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName =
        user?.displayName ?? (user?.email?.split('@').first ?? "N/A");
    final email = user?.email ?? "N/A";

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

    return Scaffold(
        appBar: AppBar(
          title: Text("Profile"),
          backgroundColor: Colors.purple,
        ),
        body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/vasis.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black
                  .withOpacity(0.3), // semi-transparent overlay for readability
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // User Info Card with Profile Pic
                          Card(
                            elevation: 4,
                            color: Colors.white
                                .withOpacity(0.7), // Semi-transparent white
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Profile Picture
                                      Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 40,
                                            backgroundImage: (FirebaseAuth
                                                            .instance
                                                            .currentUser
                                                            ?.photoURL !=
                                                        null &&
                                                    FirebaseAuth
                                                        .instance
                                                        .currentUser!
                                                        .photoURL!
                                                        .isNotEmpty)
                                                ? NetworkImage(FirebaseAuth
                                                    .instance
                                                    .currentUser!
                                                    .photoURL!)
                                                : AssetImage(
                                                        'images/default_profile.png')
                                                    as ImageProvider,
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () async {
                                                final picker = ImagePicker();
                                                final user = FirebaseAuth
                                                    .instance.currentUser;
                                                if (user == null) return;

                                                try {
                                                  final picked =
                                                      await picker.pickImage(
                                                          source: ImageSource
                                                              .gallery);
                                                  if (picked == null) return;

                                                  // Check file size (200KB = 200 * 1024 bytes)
                                                  final fileSize =
                                                      await picked.length();
                                                  const maxSize = 200 *
                                                      1024; // 200KB in bytes

                                                  if (fileSize > maxSize) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Image size should be less than 200KB'),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                    }
                                                    return;
                                                  }

                                                  final ref = FirebaseStorage
                                                      .instance
                                                      .ref()
                                                      .child(
                                                          'profile_photos/${user.uid}.jpg');
                                                  await ref.putData(await picked
                                                      .readAsBytes());
                                                  final url = await ref
                                                      .getDownloadURL();
                                                  await user
                                                      .updatePhotoURL(url);
                                                  await user.reload();
                                                  // ignore: use_build_context_synchronously
                                                  if (context.mounted) {
                                                    (context as Element)
                                                        .markNeedsBuild();
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Error uploading image: ${e.toString()}'),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              child: CircleAvatar(
                                                radius: 14,
                                                backgroundColor: Colors.white,
                                                child: Icon(Icons.edit,
                                                    size: 16,
                                                    color: Colors.purple[700]),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 20),
                                      // User Details in Table Layout
                                      Expanded(
                                        child: Table(
                                          columnWidths: const {
                                            0: IntrinsicColumnWidth(),
                                            1: FlexColumnWidth(),
                                          },
                                          defaultVerticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          children: [
                                            // Username Row
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8.0),
                                                  child: Text("Username:",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ),
                                                if (!_isEditing)
                                                  Row(
                                                    children: [
                                                      Text(
                                                        userName,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.edit,
                                                            size: 18,
                                                            color: Colors
                                                                .purple[700]),
                                                        onPressed: () {
                                                          _nameController.text =
                                                              userName;
                                                          setState(() {
                                                            _isEditing = true;
                                                          });
                                                        },
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            BoxConstraints(),
                                                      ),
                                                    ],
                                                  )
                                                else
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextFormField(
                                                          controller:
                                                              _nameController,
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14),
                                                          decoration:
                                                              InputDecoration(
                                                            isDense: true,
                                                            contentPadding:
                                                                EdgeInsets
                                                                    .symmetric(
                                                                        vertical:
                                                                            4,
                                                                        horizontal:
                                                                            8),
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                              borderSide: BorderSide(
                                                                  color: Colors
                                                                          .grey[
                                                                      400]!),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      if (_isUpdating)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      8.0),
                                                          child: SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child:
                                                                CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2),
                                                          ),
                                                        )
                                                      else
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              icon: Icon(
                                                                  Icons.check,
                                                                  size: 18,
                                                                  color: Colors
                                                                      .green),
                                                              onPressed:
                                                                  _updateDisplayName,
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  BoxConstraints(),
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                  Icons.close,
                                                                  size: 18,
                                                                  color: Colors
                                                                      .red),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _isEditing =
                                                                      false;
                                                                });
                                                              },
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  BoxConstraints(),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                            // Email Row
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8.0),
                                                  child: Text("Email:",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ),
                                                Text(email,
                                                    style: TextStyle(
                                                        fontSize: 14)),
                                              ],
                                            ),
                                            // Account Type Row
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8.0),
                                                  child: Text("Account Type:",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ),
                                                Text(
                                                  accountType,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: accountType == "Free"
                                                        ? Colors.red
                                                        : Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Donation Amount Row
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8.0),
                                                  child: Text("Donation:",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ),
                                                Text(
                                                  "\$${donation.toStringAsFixed(1)}",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: donation > 0
                                                        ? Colors.green
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // Donate Section
                          Card(
                            elevation: 4,
                            margin: EdgeInsets.zero,
                            color: Colors.white
                                .withOpacity(0.7), // Semi-transparent white
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              "Donate USD 5\$ or more to Vasis Studios and Send Details to ",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        WidgetSpan(
                                          child: GestureDetector(
                                            onTap: () async {
                                              final Uri emailLaunchUri = Uri(
                                                scheme: 'mailto',
                                                path: 'vasiskirtan@gmail.com',
                                              );
                                              if (await canLaunchUrl(
                                                  emailLaunchUri)) {
                                                await launchUrl(emailLaunchUri);
                                              }
                                            },
                                            child: Text(
                                              'vasiskirtan@gmail.com',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: Colors.blue,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      // On smaller screens, stack the items vertically
                                      if (constraints.maxWidth < 600) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Column(
                                              children: [
                                                Image.asset(
                                                  'images/upi_qr.png',
                                                  height: 160,
                                                  width: 160,
                                                  fit: BoxFit.contain,
                                                ),
                                                SizedBox(height: 10),
                                                Text("Donate with UPI"),
                                                SizedBox(height: 20),
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                // Donation amount dropdown for mobile view
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    border: Border.all(
                                                        color: Colors.white30),
                                                  ),
                                                  child:
                                                      DropdownButtonHideUnderline(
                                                    child: DropdownButton<int>(
                                                      value:
                                                          _selectedDonationAmount,
                                                      dropdownColor:
                                                          Colors.purple[800],
                                                      style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 14),
                                                      icon: Icon(
                                                          Icons.arrow_drop_down,
                                                          color: Colors.black),
                                                      items: _donationAmounts
                                                          .map((int amount) {
                                                        return DropdownMenuItem<
                                                            int>(
                                                          value: amount,
                                                          child: Text(
                                                              '\$$amount',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      14)),
                                                        );
                                                      }).toList(),
                                                      onChanged:
                                                          (int? newValue) {
                                                        if (newValue != null) {
                                                          setState(() {
                                                            _selectedDonationAmount =
                                                                newValue;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                // Donate button for mobile view
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    launchUrl(Uri.parse(
                                                        "https://www.paypal.com/paypalme/nityakishore/${_selectedDonationAmount}USD"));
                                                  },
                                                  icon: Icon(Icons.payment),
                                                  label:
                                                      Text("Donate via PayPal"),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      }
                                      // On larger screens, show items side by side
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Column(
                                            children: [
                                              Image.asset(
                                                'images/upi_qr.png',
                                                height: 160,
                                                width: 160,
                                                fit: BoxFit.contain,
                                              ),
                                              SizedBox(height: 10),
                                              Text("Donate with UPI"),
                                            ],
                                          ),
                                          SizedBox(width: 20),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Donation amount dropdown
                                              Container(
                                                width:
                                                    75, // Further reduced width
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 4, vertical: 0),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.purple[700]!,
                                                      Colors.purple[500]!,
                                                      Colors.purple[700]!,
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                      color: Colors.white30),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.purple
                                                          .withOpacity(0.3),
                                                      spreadRadius: 1,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child:
                                                    DropdownButtonHideUnderline(
                                                  child: DropdownButton<int>(
                                                    isExpanded: true,
                                                    value:
                                                        _selectedDonationAmount,
                                                    dropdownColor:
                                                        Colors.purple[700],
                                                    iconSize: 18,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 1.1,
                                                    ),
                                                    icon: Icon(
                                                        Icons.arrow_drop_down,
                                                        color: Colors.white),
                                                    items: _donationAmounts
                                                        .map((int amount) {
                                                      return DropdownMenuItem<
                                                          int>(
                                                        value: amount,
                                                        child: Center(
                                                          child: Text(
                                                            '\$$amount',
                                                            style: TextStyle(
                                                                fontSize: 14),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                    onChanged: (int? newValue) {
                                                      if (newValue != null) {
                                                        setState(() {
                                                          _selectedDonationAmount =
                                                              newValue;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              // Donate button
                                              Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.purple[700]!,
                                                      Colors.purple[500]!,
                                                      Colors.purple[700]!,
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.purple
                                                          .withOpacity(0.3),
                                                      spreadRadius: 1,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    launchUrl(Uri.parse(
                                                        "https://www.paypal.com/paypalme/nityakishore/${_selectedDonationAmount}USD"));
                                                  },
                                                  icon: Icon(Icons.payment,
                                                      color: Colors.white,
                                                      size: 18),
                                                  label: Text(
                                                      "Donate via PayPal",
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white)),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    shadowColor:
                                                        Colors.transparent,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 10),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
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
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purple[700]!,
                                      Colors.purple[500]!,
                                      Colors.purple[700]!,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseAuth.instance.signOut();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => EmailLinkSignInScreen(
                                              beatsReady: true)),
                                      (_) => false,
                                    );
                                  },
                                  child: Text("Sign Out",
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ),
                              if (isAdmin)
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple[700]!,
                                        Colors.purple[500]!,
                                        Colors.purple[700]!,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  AdminPanelScreen()));
                                    },
                                    child: Text("Admin Panel",
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purple[700]!,
                                      Colors.purple[500]!,
                                      Colors.purple[700]!,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Determine user status: paid or free
                                    String userStatus = "free";
                                    // Treat as paid if admin or account_type is paid or donation_amount > 0
                                    if ((data['role'] == 'admin') ||
                                        (data['account_type'] == 'paid') ||
                                        ((data['donation_amount'] ?? 0.0) >
                                            0.0)) {
                                      userStatus = "paid";
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              data['beatsReady'] == true
                                                  ? HomeScreen()
                                                  : SplashScreen(
                                                      userStatus: userStatus)),
                                    );
                                  },
                                  child: Text("Go to Beats",
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  }),
            )));
  }
}
