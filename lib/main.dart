import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Calls(),
    ),
  );
}

class Calls extends StatefulWidget {
  const Calls({Key? key}) : super(key: key);

  @override
  State<Calls> createState() => _CallsState();
}

class _CallsState extends State<Calls> {
  PhoneState status = PhoneState.nothing();
  bool granted = false;
  Duration callDuration = Duration.zero;
  DateTime? callStartTime;

  Future<bool> requestPermission() async {
    var status = await Permission.phone.request();

    return status.isGranted;
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) setStream();
  }

  void setStream() {
    PhoneState.stream.listen((event) {
      setState(() {
        if (event.status == PhoneStateStatus.CALL_STARTED) {
          callStartTime = DateTime.now();
        } else if (event.status == PhoneStateStatus.CALL_ENDED) {
          if (callStartTime != null) {
            callDuration = DateTime.now().difference(callStartTime!);
            callStartTime = null;
          }
        }
        status = event;
      });
    });
  }

  void makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(url as Uri)) {
      await launchUrl(url as Uri);
    } else {
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to make a phone call.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone State"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (Platform.isAndroid)
              MaterialButton(
                onPressed: !granted
                    ? () async {
                  bool temp = await requestPermission();
                  setState(() {
                    granted = temp;
                    if (granted) {
                      setStream();
                    }
                  });
                }
                    : null,
                child: const Text("Request permission of Phone"),
              ),
            ElevatedButton(
              onPressed: () async {
                final call = Uri.parse('tel:01103896244');
                if (await canLaunchUrl(call)) {
                  launchUrl(call);
                } else {
                  throw 'Could not launch $call';
                }
              },
              child: const Text('Call : 01103896244'),
            ),

            if (status.status == PhoneStateStatus.CALL_INCOMING || status.status == PhoneStateStatus.CALL_STARTED)
              GestureDetector(
                onTap: () {
                  if (status.number != null) {
                    makePhoneCall(status.number!);
                  }
                },
                child: Text(
                  "Number: ${status.number}",
                  style: const TextStyle(fontSize: 24, decoration: TextDecoration.underline),
                ),
              ),
            Icon(
              getIcons(),
              color: getColor(),
              size: 80,
            ),
            Text(
              "Call duration: ${callDuration.inSeconds} seconds",
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  IconData getIcons() {
    return status.status == PhoneStateStatus.NOTHING
        ? Icons.clear
        : status.status == PhoneStateStatus.CALL_INCOMING
        ? Icons.add_call
        : status.status == PhoneStateStatus.CALL_STARTED
        ? Icons.call
        : Icons.call_end;
  }

  Color getColor() {
    return status.status == PhoneStateStatus.NOTHING || status.status == PhoneStateStatus.CALL_ENDED
        ? Colors.red
        : status.status == PhoneStateStatus.CALL_INCOMING
        ? Colors.green
        : Colors.orange;
  }
}