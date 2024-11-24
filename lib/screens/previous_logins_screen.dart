import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PreviousLoginsScreen extends StatelessWidget {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("login_details");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Previous Logins")),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No logins found."));
          }

          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final entries = data.values.map((e) => Map<String, dynamic>.from(e)).toList();

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                title: Text("IP: ${entry['ip']}"),
                subtitle: Text("Location: ${entry['location']}"),
                trailing: entry["qrUrl"] != null
                    ? Image.network(entry["qrUrl"], width: 50, height: 50)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
