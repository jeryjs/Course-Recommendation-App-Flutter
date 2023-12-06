// chat_screen.dart
import 'dart:math';

import 'package:ashiq/question_data.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:markdown_widget/config/all.dart';
import 'dart:convert';
import 'package:markdown_widget/widget/markdown.dart';

class ChatScreen extends StatefulWidget {
  final String course;
  final QuestionData ans;

  const ChatScreen({super.key, required this.course, required this.ans});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  var _awaitingResponse = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final List<MessageBubble> _chatHistory = [];
  List<String> loadingPhrases = [
    'Working on it, one sec.',
    'I\'ll get back to you on that.',
    'Just a moment, please.',
    'Let me check on that.',
    'I\'m almost there.',
    'Hang tight.',
    'Coming right up.',
    'I\'m on it.',
    'Be right back.',
    'Just a sec, I\'m buffering.'
  ];

  @override
  void initState() {
    super.initState();
    initMessage();
  }

  void initMessage() async {
    setState(() => _awaitingResponse = true);
    String response = await fetchResultFromBard(
        'Why was I recommended the course [${widget.course}]');
    setState(() {
      _addMessage(response, false);
      _awaitingResponse = false;
    });
  }

  void _addMessage(String response, bool isUserMessage) {
    _chatHistory.add(MessageBubble(content: response, isUserMessage: isUserMessage));
    try {_listKey.currentState!.insertItem(_chatHistory.length - 1);} catch (e) {debugPrint(e.toString());}
    // Scroll to the bottom of the list
    // Schedule the scroll after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _onSubmitted(String message) async {
    _messageController.clear();
    setState(() {
      _addMessage(message, true);
      _awaitingResponse = true;
    });
    final result = await fetchResultFromBard(message);
    setState(() {
      _addMessage(result, false);
      _awaitingResponse = false;
    });
  }

  Future<String> fetchResultFromGPT(String course) async {
    OpenAI.apiKey = await rootBundle.loadString('assets/openai.key');
    OpenAI.showLogs = true;
    OpenAI.showResponsesLogs = true;

    final prompt =
        "Hello! I'm interested in learning more about $course. Can you tell me more about the course and provide some suggestions on what I should learn first?";

    final completion = await OpenAI.instance.chat.create(
      model: 'gpt-3.5-turbo',
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
        ),
      ],
      maxTokens: 150,
      temperature: 0.7,
    );

    if (completion.choices.isNotEmpty) {
      return completion.choices.first.message.content!.first.text.toString();
    } else {
      throw Exception('Failed to load result');
    }
  }

  Future<String> fetchResultFromBard(String message) async {
    final apiKey = await rootBundle.loadString('assets/bard.key');
    final endpoint =
        "https://generativelanguage.googleapis.com/v1beta2/models/chat-bison-001:generateMessage?key=$apiKey";

    final chatHistory = _chatHistory.map((bubble) {
      return {"content": bubble.content};
    }).toList();
    if (chatHistory.isEmpty) chatHistory.add({"content": message});

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "prompt": {
          "context": '''
            You are Nero, a very friendly, discerning course recommendation bot who helps students pick the best course for them and answer in markdown.
            You are trained to reject to answer questions that are too offtopic and reply in under 40-60 words unless more are needed.
            You are chatting with a student who is interested in the course ["${widget.course}"] and so will speak only regarding it.
            The student asks you to tell them more about the course and provide some suggestions on what they should learn first.
            You respond to them with the most helpful information you can think of as well as base your answers on their previous
            questions and the answers they have provided in the following survey json:\n${widget.ans.toJson()}''',
          "examples": [
            {
              "input": {"content": "Who are you."},
              "output": {
                "content":
                    "I'm Nero, a helpful course recommending bot. I've been trained to help you pick a course for your higher studies."
              }
            },
            {
              "input": {
                "content": "Let's talk about smoething other than the course."
              },
              "output": {
                "content":
                    "I apollogise if I am not making this conversation fun enough, but I cant talk about anything unrelated to the course. So, to make things interesting, how about we play a small game to help u get a better idea of your course?."
              }
            },
            {
              "input": {"content": "What is the course about?"},
              "output": {
                "content":
                    "That's a very good question!! The course is about ${widget.course}. It is a very interesting course that will help you learn a lot of things."
              }
            }
          ],
          "messages": chatHistory,
        },
        "candidate_count": 1,
        "top_p": 0.8,
        "temperature": 0.7,
      }),
    );
    debugPrint("$chatHistory");
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      debugPrint('Response: $json');
      if (json['filters'] != null) {
        return "Whoops~ Looks like your response was too offtopic, so it was filtered due to reason [${json['filters'][0]['reason']}].\nLet's try again, shall we?";
      } else {
        return json['candidates'][0]['content'];
      }
    } else {
      // throw Exception('Failed to load result: ${response.body}');
      return 'Status [${response.statusCode}]\nFailed to load result: ${response.body}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final clrSchm = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Talk to Nero"),
        backgroundColor: clrSchm.primaryContainer.withOpacity(0.2),
        actions: [
          IconButton(
            icon: Icon(Icons.restart_alt, color: clrSchm.onPrimary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Refresh Chat'),
                    content: const Text(
                        'Are you sure you want to restart the conversation?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Restart'),
                        onPressed: () {
                          setState(() {
                            _chatHistory.clear();
                            initMessage();
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _chatHistory.isNotEmpty
      ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: min(720, screenSize.width * 0.95),
              child: AnimatedList(
                key: _listKey,
                controller: _scrollController,
                initialItemCount: _chatHistory.length,
                itemBuilder: (context, index, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: _chatHistory[index],
                  );
                },
              ),
            ),
          ),
        )
      : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            [
              SpinKitPouringHourGlassRefined(color: clrSchm.primary, size: 120),
              SpinKitDancingSquare(color: clrSchm.primary, size: 120),
              SpinKitSpinningLines(color: clrSchm.primary, size: 120),
              SpinKitPulsingGrid(color: clrSchm.primary, size: 120)
            ][Random().nextInt(4)],
            const SizedBox(height: 10),
            StreamBuilder<String>(
              stream: Stream.periodic(const Duration(seconds: 3), (i) => loadingPhrases[Random().nextInt(loadingPhrases.length)]),
              builder: (context, snapshot) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(sizeFactor: animation, axis: Axis.horizontal, axisAlignment: -1, child: child),
                    );
                  },
                  child: Text(
                    snapshot.data ?? loadingPhrases[Random().nextInt(loadingPhrases.length)],
                    key: ValueKey<String>(snapshot.data ?? loadingPhrases[Random().nextInt(loadingPhrases.length)]),
                    style: TextStyle(fontSize: 20),
                  ),
                );
              },
            ),
          ],
        ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: clrSchm.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: clrSchm.secondary, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: !_awaitingResponse
                  ? RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (RawKeyEvent event) {
                        if (event is RawKeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.enter) {
                            if (event.isShiftPressed) {
                              _messageController.text =
                                  '${_messageController.text}\n';
                              _messageController.selection =
                                  TextSelection.fromPosition(TextPosition(
                                      offset: _messageController.text.length));
                            } else {
                              _onSubmitted(_messageController.text);
                            }
                          }
                        }
                      },
                      child: TextField(
                        minLines: 1,
                        maxLines: 5,
                        controller: _messageController,
                        onSubmitted: _onSubmitted,
                        decoration: InputDecoration(
                          hintText: 'What would you like to know...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0)),
                          prefixIcon: Icon(Icons.question_answer,
                              color: clrSchm.primary),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: 24,
                            width: 24,
                            child: SpinKitPouringHourGlassRefined(
                                color: clrSchm.primary)),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: StreamBuilder<String>(
                            stream: Stream.periodic(
                                const Duration(seconds: 3),
                                (i) => loadingPhrases[
                                    Random().nextInt(loadingPhrases.length)]),
                            builder: (context, snapshot) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                        scale: animation,
                                        alignment: Alignment.centerLeft,
                                        child: child),
                                  );
                                },
                                child: Text(
                                  snapshot.data ??
                                      loadingPhrases[Random()
                                          .nextInt(loadingPhrases.length)],
                                  key: ValueKey<String>(snapshot.data ??
                                      loadingPhrases[Random()
                                          .nextInt(loadingPhrases.length)]),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
            ),
            IconButton(
              onPressed: !_awaitingResponse
                  ? () => _onSubmitted(_messageController.text.trim())
                  : null,
              icon: Icon(Icons.send, color: clrSchm.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String content;
  final bool isUserMessage;

  const MessageBubble({
    required this.content,
    required this.isUserMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUserMessage
            ? themeData.colorScheme.secondary.withOpacity(0.4)
            : themeData.colorScheme.primary.withOpacity(0.4),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isUserMessage ? 'You' : 'Nero',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            MarkdownWidget(
                data: content,
                shrinkWrap: true,
                config: MarkdownConfig.darkConfig),
          ],
        ),
      ),
    );
  }
}
