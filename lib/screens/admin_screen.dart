import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("❌ Error: ${snapshot.error}"));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;

              if (users.isEmpty) {
                return const Center(child: Text("No users found."));
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, index) {
                  final user = users[index];
                  return UserListItem(user: user);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class UserListItem extends StatefulWidget {
  final DocumentSnapshot user;

  const UserListItem({Key? key, required this.user}) : super(key: key);

  @override
  _UserListItemState createState() => _UserListItemState();
}

class _UserListItemState extends State<UserListItem> {
  late TextEditingController _amountController;
  late String _accountType;
  late String _currency;
  final double donationThreshold = 10.0;

  @override
  void initState() {
    super.initState();
    final userData = widget.user.data() as Map<String, dynamic>;
    
    // Handle new donation map structure
    final donationData = userData['donation'] as Map<String, dynamic>?;
    _amountController = TextEditingController(
      text: donationData?['amount']?.toString() ?? userData['donation_amount']?.toString() ?? '0.0',
    );
    _currency = donationData?['currency'] ?? 'USD'; // Default to USD

    _accountType = userData['account_type'] ?? 'free';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    String finalType = (amount >= donationThreshold && _currency == 'USD') ? 'paid' : _accountType;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({
        'donation': {
          'amount': amount,
          'currency': _currency,
        },
        'account_type': finalType,
        'donation_amount': FieldValue.delete(), // Remove old field
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ Updated ${widget.user['email']}"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ Failed to update: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.user.data() as Map<String, dynamic>;
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userData['userName'] ?? userData['email'],
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text("Email: ${userData['email']}", style: theme.textTheme.bodySmall),
            const Divider(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text("Account Type"),
              trailing: DropdownButton<String>(
                value: _accountType,
                items: ['free', 'paid']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (newType) {
                  if (newType != null) {
                    setState(() {
                      _accountType = newType;
                    });
                  }
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.monetization_on_outlined),
              title: const Text("Donation"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: "0.0",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _currency,
                    items: ['USD', 'INR']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (newCurrency) {
                      if (newCurrency != null) {
                        setState(() {
                          _currency = newCurrency;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _updateUser,
                icon: const Icon(Icons.update),
                label: const Text("Update"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
