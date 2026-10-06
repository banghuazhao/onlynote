import 'package:flutter/material.dart';

Widget buildNoteBlockImage(BuildContext context, String path) =>
    const ColoredBox(
      color: Color(0xFFE1D8C7),
      child: Center(child: Icon(Icons.landscape_outlined, size: 48)),
    );

Future<double?> readNoteBlockAspectRatio(String path) async => null;
