import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> generateImage(String text, {bool isRegenerate = false}) async {
    setState(() {
      _loading = true;
      if (!isRegenerate) {
        _messages.add(Message(text: text, isUser: true));
      }
      _messages
          .add(Message(text: "We are treating your prompt...", isUser: false));
    });
    _scrollToBottom();

    try {
      String engineId = "stable-diffusion-v1-6";
      String apiHost = 'https://api.stability.ai';
      String apiKey = "sk-c0sd5OkEX9B7bTjtMUhdVtAkdxhBCvM2Txipin4jRy9Rtuiy";

      final response = await http.post(
        Uri.parse("$apiHost/v1/generation/$engineId/text-to-image"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "image/png",
          "Authorization": "Bearer $apiKey"
        },
        body: jsonEncode({
          "text_prompts": [
            {
              "text": text,
              "weight": 1,
            }
          ],
          "cfg_scale": 7,
          "height": 512,
          "width": 512,
          "samples": 1,
          "steps": 30,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _messages.removeLast(); // Remove the loading message
          _messages.add(Message(
              text: "AI Generated Image",
              isUser: false,
              imageData: response.bodyBytes,
              prompt: text));
          _loading = false;
        });
      } else {
        setState(() {
          _messages.removeLast(); // Remove the loading message
          _messages.add(Message(
              text: "Failed to generate image: ${response.statusCode}",
              isUser: false));
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.removeLast(); // Remove the loading message
        _messages
            .add(Message(text: "Error generating image: $e", isUser: false));
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> saveImage(Uint8List imageData) async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final directory = Directory('/storage/emulated/0/aiimages');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File(
          '${directory.path}/image_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageData);

      // Scan the file to make it visible in the gallery
      await MediaScanner.loadMedia(path: file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Image saved to ${file.path} and added to gallery')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied to save image')),
      );
    }
  }

  void _showFullScreenImage(Uint8List imageData) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Container(
              color: Colors.black,
              child: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.memory(imageData),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isLastImage =
                    index == _messages.length - 1 && message.imageData != null;
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? const Color(0xFF587AF6)
                          : const Color(0xFFf0f5fe),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: message.isUser
                            ? const Radius.circular(20)
                            : const Radius.circular(0),
                        bottomRight: message.isUser
                            ? const Radius.circular(0)
                            : const Radius.circular(20),
                      ),
                    ),
                    child: message.imageData != null
                        ? Column(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _showFullScreenImage(message.imageData!),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(message.imageData!,
                                      width: 200, height: 200),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.save),
                                    onPressed: () =>
                                        saveImage(message.imageData!),
                                  ),
                                  if (isLastImage)
                                    IconButton(
                                      icon: const Icon(Icons.refresh),
                                      onPressed: () => generateImage(
                                          message.prompt!,
                                          isRegenerate: true),
                                    ),
                                ],
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: "Enter a prompt",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFf0f5fe),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 20.0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    if (_controller.text.isNotEmpty) {
                      generateImage(_controller.text);
                      _controller.clear();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                        color: Color(0xFF587AF6), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final Uint8List? imageData;
  final String? prompt;

  Message(
      {required this.text, required this.isUser, this.imageData, this.prompt});
}
