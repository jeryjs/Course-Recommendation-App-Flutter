// ignore_for_file: prefer_const_constructors, prefer_final_fields
import 'package:flutter/material.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int _step = 1;
  late int _totSteps = _qnTitles.length;
  List<String> _qnTitles = [
    "Your interests",
    "Your personality",
    'Your skills',
    'Your goals',
  ];
  List<List<String>> _opts = [
    [
      "Sports",
      "Music",
      "Art",
      "Dance",
      "Reading",
      "Coding",
      "Gardening",
      "Cooking",
      "Photography",
      "Traveling",
      "Writing",
      "Yoga",
      "Gaming",
      "Hiking",
      "Fishing",
      "Painting",
      "Singing",
      "Swimming",
      "Knitting",
      "Chess"
    ],
    [
      "Outgoing",
      "Friendly",
      "Creative",
      "Analytical",
      "Persistent",
      "Flexible",
      "Patient",
      "Responsible",
      "Independent",
      "Organized",
      "Detail-oriented",
      "Adventurous",
      "Calm",
      "Enthusiastic",
      "Ambitious",
      "Curious",
      "Empathetic",
      "Assertive",
      "Humorous",
      "Imaginative"
    ],
    [
      "Programming",
      "Designing",
      "Testing",
      "Debugging",
      "Problem Solving",
      "Communication",
      "Project Management",
      "Data Analysis",
      "Creativity",
      "Leadership",
      "Time Management",
      "Collaboration",
      "Adaptability",
      "Decision Making",
      "Critical Thinking",
      "Networking",
      "Negotiation",
      "Conflict Resolution",
      "Customer Service",
      "Technical Writing"
    ],
    [
      "Start a business",
      "Learn a new skill",
      "Get a promotion",
      "Change careers",
      "Improve leadership skills",
      "Improve communication",
      "Improve problem solving",
      "Improve technical skills",
      "Improve creativity",
      "Improve time management",
      "Improve work-life balance",
      "Travel more",
      "Volunteer",
      "Learn a new language",
      "Write a book",
      "Run a marathon",
      "Buy a house",
      "Save for retirement",
      "Get fit",
      "Spend more time with family and friends"
    ],
    [''],
  ];
  late List<bool> _selectedOpts;

  gotoStep(int i) {
    setState(() {
      _step = i;
      _selectedOpts =
          List<bool>.generate(_opts[_step - 1].length, (index) => false);
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedOpts =
        List<bool>.generate(_opts[_step - 1].length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(2),
      child: Column(
        children: [
          Text('Step $_step out of $_totSteps'),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: _step / _totSteps,
              onChanged: (double value) {
                gotoStep(
                    ((value * _totSteps).toInt() > 0)
                    ? (value * _totSteps).toInt()
                    : 1
                  );
              },
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 30)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_qnTitles[_step - 1], style: TextStyle(fontSize: 28)),
              Text('Pick what describe you best~',
                  style: Theme.of(context).textTheme.titleSmall),
              Padding(padding: EdgeInsets.only(top: 50)),
              Stack(clipBehavior: Clip.none, children: <Widget>[
                Card(
                  child: Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      direction: Axis.horizontal,
                      alignment: WrapAlignment.spaceEvenly,
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children:
                          List<Widget>.generate(_opts[_step - 1].length, (i) {
                        return FilterChip(
                          label: Text(_opts[_step - 1][i]),
                          selected: _selectedOpts[i],
                          onSelected: (s) =>
                              setState(() => _selectedOpts[i] = s),
                        );
                      }),
                    ),
                  ),
                ),
                Positioned(
                  top: -125,
                  right: -10,
                  child: Image.asset('assets/images/andy_2.gif', width: 80),
                ),
              ]),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 46, horizontal: 16),
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () {
                      gotoStep(_step+1);
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).colorScheme.primaryContainer,
                      ),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        EdgeInsets.symmetric(vertical: 16),
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    child: Text('Submit', style: TextStyle(fontSize: 20))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
