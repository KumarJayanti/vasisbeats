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
import 'package:flutter/services.dart';

// Helper widget for the AppBar title
Widget _buildAppBarTitle() {
  return Row(
    children: [
      const CircleAvatar(
        radius: 16,
        backgroundImage: AssetImage('images/appicon.png'),
        backgroundColor: Colors.transparent,
      ),
      const SizedBox(width: 12),
      const Text("VasisBeats"),
    ],
  );
}

class EmailLinkSignInScreen extends StatefulWidget {
  final bool beatsReady;
  EmailLinkSignInScreen({required this.beatsReady});

  @override
  _EmailLinkSignInScreenState createState() => _EmailLinkSignInScreenState();
}

class _EmailLinkSignInScreenState extends State<EmailLinkSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isSendingLink = false;
  bool _isSigningIn = false;
  bool _linkSent = false;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // If user is already signed in, redirect them to the profile screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_auth.currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProfileScreen(beatsReady: widget.beatsReady)),
        );
      }
    });
    _checkForStoredLink();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _linkController.dispose();
    super.dispose();
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
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _signInManually() async {
    final email = _emailController.text.trim();
    final link = _linkController.text.trim();

    if (email.isEmpty || link.isEmpty) return;

    if (!_auth.isSignInWithEmailLink(link)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid sign-in link.")),
      );
      return;
    }

    setState(() => _isSigningIn = true);
    try {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Manual sign-in failed. Try again.")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _sendSignInLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    setState(() => _isSendingLink = true);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📩 Sign-in link sent to $email'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print("❌ Failed to send sign-in link: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to send link. Check your Firebase setup."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingLink = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        backgroundColor: Colors.purple,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('images/vasis.jpeg', fit: BoxFit.cover),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 8,
                color: Colors.black.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Sign in to continue",
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Email",
                            labelStyle:
                                const TextStyle(color: Colors.purpleAccent),
                            prefixIcon:
                                const Icon(Icons.email_outlined, color: Colors.purpleAccent),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Colors.purpleAccent),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        if (_isSendingLink || _isSigningIn)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton.icon(
                            onPressed: _sendSignInLink,
                            icon: const Icon(Icons.send),
                            label: const Text("Send Sign-In Link"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        if (_linkSent)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              "✅ Email sent. Please check your inbox.",
                              style: TextStyle(color: Colors.green[400]),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (Platform.isMacOS) ...[
                          const SizedBox(height: 20),
                          const Divider(color: Colors.purpleAccent),
                          const SizedBox(height: 10),
                          Text(
                            "Already have a link? Paste it here.",
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _linkController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Email sign-in link",
                              labelStyle: const TextStyle(
                                  color: Colors.purpleAccent),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.purpleAccent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _signInManually,
                            icon: const Icon(Icons.login),
                            label: const Text("Sign In with Link"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
  late TextEditingController _nameController;
  Future<Map<String, dynamic>>? _userDataFuture;
  bool _isEditing = false;
  bool _isUpdating = false;

  final List<int> _donationAmounts = [5, 10, 15, 20];
  int _selectedDonationAmount = 5;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => EmailLinkSignInScreen(beatsReady: true)),
            (route) => false,
          );
        }
      });
    } else {
      _nameController = TextEditingController(
        text: user.displayName ?? (user.email?.split('@').first ?? ""),
      );
      _userDataFuture = _getUserData(user.uid);
    }
  }

  @override
  void dispose() {
    // Only dispose if initialized, to prevent errors when redirecting.
    if (_userDataFuture != null) {
      _nameController.dispose();
    }
    super.dispose();
  }

  Future<void> _updateDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUpdating = true);
    try {
      await user.updateDisplayName(newName);
      await user.reload();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'userName': newName,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _userDataFuture = _getUserData(user.uid);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully')),
        );
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

  Future<void> _pickAndUploadProfilePicture() async {
    final picker = ImagePicker();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final fileSize = await picked.length();
      const maxSize = 200 * 1024; // 200KB

      if (fileSize > maxSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image size should be less than 200KB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos/${user.uid}.jpg');
      await ref.putData(await picked.readAsBytes());
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);
      await user.reload();
      if (mounted) {
        setState(() {
          _userDataFuture = _getUserData(user.uid);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
    // If the future is null, it means we are in the process of redirecting.
    // Show a loading indicator to prevent a null error on the future.
    if (_userDataFuture == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/vasis.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _userDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("Could not load user data."));
              }

              final data = snapshot.data!;
              final isAdmin = data['is_admin'] ?? false;

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildUserInfoCard(data),
                  const SizedBox(height: 20),
                  _buildDonationCard(data),
                  const SizedBox(height: 40),
                  _buildActionButtons(context, isAdmin, data),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = data['userName'] ?? "N/A";
    final email = data['email'] ?? "N/A";
    final accountType = data['role'] == 'admin'
        ? "Paid (Admin)"
        : data['account_type'] ?? "Free";
    final donation = data['donation_amount'] ?? 0.0;

    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Profile", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Stack(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundImage: (user?.photoURL != null &&
                          user!.photoURL!.isNotEmpty)
                      ? NetworkImage(user.photoURL!)
                      : const AssetImage('images/default_profile.png')
                          as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAndUploadProfilePicture,
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.edit, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Username"),
              subtitle: _isEditing
                  ? TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration(isDense: true),
                    )
                  : Text(userName,
                      style: Theme.of(context).textTheme.titleMedium),
              trailing: _isEditing
                  ? _isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: _updateDisplayName),
                          IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => setState(() => _isEditing = false)),
                        ])
                  : IconButton(
                      icon: Icon(Icons.edit, color: Colors.purple[700]),
                      onPressed: () {
                        _nameController.text = userName;
                        setState(() => _isEditing = true);
                      },
                    ),
            ),
            ListTile(
              title: const Text("Email"),
              subtitle: Text(email, style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              title: const Text("Account Type"),
              subtitle: Text(
                accountType,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: accountType == "Free" ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              title: const Text("Donation"),
              subtitle: Text(
                "\$${donation.toStringAsFixed(1)}",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: donation > 0 ? Colors.green : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> data) {
    final userName = data['userName'] ?? "N/A";
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text("Support VasisBeats",
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.titleMedium,
                children: [
                  const TextSpan(
                      text:
                          "Donate USD 5\$ or more to Vasis Studios and send details to "),
                  WidgetSpan(
                    child: InkWell(
                      onTap: () async {
                        final Uri emailLaunchUri = Uri(
                          scheme: 'mailto',
                          path: 'vasiskirtan@gmail.com',
                          query:
                              "subject=VASIS Donation Receipt - $_selectedDonationAmount&body=Hello VASIS Team,%0D%0A%0D%0AI have donated $_selectedDonationAmount to support VASIS.%0D%0A%0D%0ATransaction Details:%0D%0A- Amount: $_selectedDonationAmount%0D%0A- Date: ${DateTime.now().toString().split(' ')[0]}%0D%0A- Payment Method: [Please specify]%0D%0A- Username: $userName%0D%0A%0D%0AI have attached the transaction screenshot for your reference.%0D%0A%0D%0AThanks,%0D%0A$userName",
                        );
                        if (await canLaunchUrl(emailLaunchUri)) {
                          await launchUrl(emailLaunchUri,
                              mode: LaunchMode.externalApplication);
                        } else {
                          await Clipboard.setData(
                              const ClipboardData(text: 'vasiskirtan@gmail.com'));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Email address copied to clipboard')),
                            );
                          }
                        }
                      },
                      child: Text(
                        'vasiskirtan@gmail.com',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Image.asset('images/upi_qr.png',
                        height: 120, width: 120, fit: BoxFit.contain),
                    const SizedBox(height: 8),
                    const Text("Donate with UPI"),
                  ],
                ),
                Column(
                  children: [
                    DropdownButton<int>(
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
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        launchUrl(Uri.parse(
                            "https://www.paypal.com/paypalme/Girigovardhana/${_selectedDonationAmount}USD"));
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text("Donate via PayPal"),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, bool isAdmin, Map<String, dynamic> data) {
    // Helper for button style
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            String userStatus = "free";
            if ((data['role'] == 'admin') ||
                (data['account_type'] == 'paid') ||
                ((data['donation_amount'] ?? 0.0) > 0.0)) {
              userStatus = "paid";
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => widget.beatsReady
                    ? HomeScreen()
                    : SplashScreen(userStatus: userStatus),
              ),
            );
          },
          child: const Text("Go to Beats"),
          style: buttonStyle,
        ),
        const SizedBox(height: 12),
        if (isAdmin) ...[
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => AdminPanelScreen()));
            },
            child: const Text("Admin Panel"),
            style: buttonStyle,
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => EmailLinkSignInScreen(beatsReady: true)),
              (_) => false,
            );
          },
          child: const Text("Sign Out"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}