import 'package:flet/flet.dart';
import 'package:flutter/material.dart';

class WebviewWindows extends StatefulWidget {
  final String url;

  const WebviewWindows({Key? key, required this.url}) : super(key: key);

  @override
  State<WebviewWindows> createState() => _WebviewWindowsState();
}

class _WebviewWindowsState extends State<WebviewWindows> {
  @override
  Widget build(BuildContext context) {
    return const ErrorControl("Webview is not yet supported on this Platform.");
  }
}
