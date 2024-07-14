import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Image Generator',
      theme: ThemeData(
        useMaterial3: false,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  Uint8List? _imageData;
  bool _loading = false;

  Future<void> generateImage(String text) async {
    setState(() {
      _loading = true;
    });

    try {
      String engineId = "stable-diffusion-v1-6";
      String apiHost = 'https://api.stability.ai';
      String apiKey =
          "sk-c0sd5OkEX9B7bTjtMUhdVtAkdxhBCvM2Txipin4jRy9Rtuiy"; // Replace with your actual API key

      final response = await http.post(
        Uri.parse("$apiHost/v1/generation/$engineId/text-to-image"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "image/png",
          "Authorization": "Bearer $apiKey"
        },
        body: jsonEncode(
          {
            "text_prompts": [
              {
                "text": text,
                "weight": 1,
              }
            ],
            "cfg_scale": 7,
            "height": 1024,
            "width": 1024,
            "samples": 1,
            "steps": 30,
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _imageData = response.bodyBytes;
          _loading = false;
        });

        // Save image to file
      } else {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to generate image: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      print('Error generating image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating image: $e')),
      );
    }
  }

//#
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : _imageData != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.memory(_imageData!))
                    : Container(),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Enter a prompt ",
                      hintStyle: const TextStyle(
                          color: Colors.grey), // Hint text color
                      filled: true, // To make the background filled
                      fillColor: const Color(0xFFf0f5fe), // Background color
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(25.0), // Rounded corners
                        borderSide: BorderSide.none, // No border
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 20.0), // Padding inside the field
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  onTap: () {
                    generateImage(_controller.text);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                        color: Color(0xFF587AF6), shape: BoxShape.circle),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
