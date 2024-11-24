import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'previous_logins_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref("login_details");
  final FirebaseStorage _storage = FirebaseStorage.instance;

  int? _randomNumber;
  String? _ipAddress;
  String? _location;
  String? _qrImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _generateRandomNumber();
  }

  void _fetchUserDetails() async {
    try {
      final locationData = await Location().getLocation();
      final ipResponse =
          await http.get(Uri.parse("https://api64.ipify.org?format=json"));
      final ipData = jsonDecode(ipResponse.body);

      setState(() {
        _location =
            "Lat: ${locationData.latitude}, Lng: ${locationData.longitude}";
        _ipAddress = ipData["ip"];
      });
    } catch (e) {
      _showError("Failed to fetch user details.");
    }
  }

  void _generateRandomNumber() {
    setState(() {
      _randomNumber = Random().nextInt(100000);
    });
  }

  void _saveDetails() async {
    try {
      final qrImage = QrPainter(
        data: _randomNumber.toString(),
        version: QrVersions.auto,
      );

      final fileName = "QR_${_randomNumber}.png";
      final fileRef = _storage.ref().child(fileName);

      final pictureData = await qrImage.toImageData(400);
      if (pictureData != null) {
        await fileRef.putData(pictureData.buffer.asUint8List());
        final qrUrl = await fileRef.getDownloadURL();

        setState(() {
          _qrImageUrl = qrUrl;
        });

        await _dbRef.push().set({
          "ip": _ipAddress,
          "location": _location,
          "randomNumber": _randomNumber,
          "qrUrl": qrUrl,
          "timestamp": DateTime.now().toString(),
        });

        _showSuccess("Saved Successfully");
      }
    } catch (e) {
      _showError("Failed to save details.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _navigateToPreviousLogins() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PreviousLoginsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Random Number: $_randomNumber"),
            const SizedBox(height: 20),
            if (_qrImageUrl != null)
              Image.network(_qrImageUrl!)
            else
              QrImageView(data: _randomNumber.toString(), size: 200),
            ElevatedButton(
              onPressed: _saveDetails,
              child: const Text("Save"),
            ),
            ElevatedButton(
              onPressed: _navigateToPreviousLogins,
              child: const Text("View Last Logins"),
            ),
          ],
        ),
      ),
    );
  }
}
