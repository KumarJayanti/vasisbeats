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
        backgroundColor: Colors.purple,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/vasis.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: StreamBuilder<QuerySnapshot>(
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
                elevation: 4,
                color: Colors.white.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['userName'] ?? userData['email'],
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Text("Email: ${userData['email']}", style: TextStyle(color: Colors.black87)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text("Account Type: ", style: TextStyle(color: Colors.black87)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!)
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: accountType,
                                dropdownColor: Colors.white,
                                icon: Icon(Icons.arrow_drop_down, color: Colors.purple),
                                items: ['free', 'paid']
                                    .map((type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(type, style: TextStyle(color: Colors.black87)),
                                        ))
                                    .toList(),
                                onChanged: (newType) {
                                  setState(() {
                                    accountType = newType!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text("Donation: ", style: TextStyle(color: Colors.black87)),
                          SizedBox(width: 10),
                          Container(
                            width: 100,
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!)
                            ),
                            child: TextField(
                              controller: amountController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: "0.0",
                                hintStyle: TextStyle(color: Colors.black54),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
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
                            double donation = double.tryParse(amountController.text) ?? 0.0;
                            String finalType = donation >= donationThreshold ? 'paid' : accountType;

                            try {
                              await usersRef.doc(user.id).update({
                                'donation_amount': donation,
                                'account_type': finalType,
                              });

                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("✅ Updated ${userData['email']}"),
                                backgroundColor: Colors.green,
                              ));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("❌ Failed to update: $e"),
                                backgroundColor: Colors.red,
                              ));
                            }
                          },
                          child: Text("Update", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
            },
          ),
        ),
      ),
    );
  }
}
