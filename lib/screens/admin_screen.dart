import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final double donationThreshold = 10.0;
  final usersRef = FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("❌ Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return Center(child: Text("No users found."));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final TextEditingController amountController = TextEditingController(
                text: userData['donation_amount']?.toString() ?? '0.0',
              );
              String accountType = userData['account_type'] ?? 'free';

              return Card(
                margin: EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userData['userName'] ?? userData['email'],
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Email: ${userData['email']}"),
                      Row(
                        children: [
                          Text("Account Type: "),
                          DropdownButton<String>(
                            value: accountType,
                            items: ['free', 'paid']
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (newType) {
                              setState(() {
                                accountType = newType!;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text("Donation: "),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: amountController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(hintText: "Amount"),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          double donation = double.tryParse(amountController.text) ?? 0.0;
                          String finalType = donation >= donationThreshold ? 'paid' : accountType;

                          try {
                            await usersRef.doc(user.id).update({
                              'donation_amount': donation,
                              'account_type': finalType,
                            });

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("✅ Updated ${userData['email']}"),
                            ));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("❌ Failed to update: $e"),
                            ));
                          }
                        },
                        child: Text("Update"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
