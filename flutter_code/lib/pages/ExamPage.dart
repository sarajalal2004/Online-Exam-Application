import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'StudentDashboard.dart';

class examPage extends StatefulWidget {
  final Map<String, dynamic> registerRow;

  const examPage({super.key, required this.registerRow});

  @override
  State<examPage> createState() => _examPageState();
}

class _examPageState extends State<examPage> {
  Timestamp? startTime;
  Timestamp? endTime;
  late DocumentReference examD;
  late CollectionReference questions;
  int? examDuration;
  bool? isRandom;
  String? examTitle;
  Timestamp? examEndTime;
  String? examCreator;
  String? studentName;
  bool attemptStatusInProgress = false;
  Map<String, dynamic> answers = {};
  Map<String, TextEditingController?> textControllers = {};
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> questionDataList = [];
  List<Map<String, dynamic>> filteredQuestions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    examD = FirebaseFirestore.instance
        .collection('Exams')
        .doc(widget.registerRow['examID']);
    questions = FirebaseFirestore.instance.collection("Questions");
    FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.registerRow["userID"])
        .get()
        .then((v) {
      studentName = v.get("name");
    });
    fetchExam().then((_) {
      setState(
        () {
          if (widget.registerRow['attemptStatus'] == 'inProgress') {
            startTime = widget.registerRow['startTime'] as Timestamp;
            attemptStatusInProgress = true;
          } else {
            startTime = Timestamp.now();
          }
          endTime = Timestamp.fromDate(
              startTime!.toDate().add(Duration(minutes: examDuration!)));

          _endExamTimer();
          if (endTime != null) {
            final duration = endTime!.toDate().difference(DateTime.now());
            Timer(duration, () {
              if (DateTime.now().isAfter(endTime!.toDate())) {
                _submit();
              }
            });
          }
        },
      );
      fetchQuestionData();
      setState(() {
        isLoading = false;
      });
    });
    searchController.addListener(() {
      final query = searchController.text.toLowerCase();
      setState(() {
        filteredQuestions = questionDataList.where((question) {
          return question['question'].toLowerCase().contains(query);
        }).toList();
      });
    });
  }

  Future<void> fetchExam() async {
    try {
      DocumentSnapshot examSnapshot = await examD.get();
      if (examSnapshot.exists) {
        examDuration = examSnapshot.get("duration");
        isRandom = examSnapshot.get("isRandom");
        examTitle = examSnapshot.get("title");
        examEndTime = examSnapshot.get('endTime') as Timestamp?;
        examCreator = examSnapshot.get('userID');
      } else {
        print("Exam document not found");
      }
    } catch (e) {
      print("Error fetching exam data: $e");
    }
  }

  // fetch exam questions and intialize requierd questions controllers
  // and randomize if requiered
  Future<void> fetchQuestionData() async {
    try {
      List<String> questionIds = widget.registerRow['answers'].keys.toList();
      List<Map<String, dynamic>> fetchedQuestions = await Future.wait(
        questionIds.map((id) async {
          DocumentSnapshot questionSnapshot = await questions.doc(id).get();
          Map<String, dynamic> questionData =
              questionSnapshot.data() as Map<String, dynamic>;
          if ((questionData['type'] == 'short' ||
                  questionData['type'] == 'essay') &&
              !textControllers.containsKey(id)) {
            textControllers[id] = TextEditingController(
              text: widget.registerRow['answers'][id]?['answer'],
            );
          }
          return {
            "id": id,
            ...questionData,
          };
        }),
      );
      setState(() {
        questionDataList = fetchedQuestions;
        if (isRandom == true) {
          questionDataList.shuffle();
        }
        filteredQuestions = List.from(fetchedQuestions);
      });
    } catch (e) {
      print("Error fetching question data: $e");
    }
  }

  @override
  void dispose() {
    textControllers.forEach((key, controller) {
      controller?.dispose();
    });
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF354F52),
            ),
            child: Center(
              child: Text(
                examTitle!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          Container(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "Search Questions",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                ),
                TimeLeftProgressBar(
                    startTime: startTime!.toDate(), endTime: endTime!.toDate()),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredQuestions.length,
              itemBuilder: (context, index) {
                var question = filteredQuestions[index];
                var questionId = question['id'];

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Q: ${question['question']}'),
                              Text('${question['score'].toString()} score'),
                            ],
                          ),
                          if (question['attachment'] != null &&
                              question['attachment'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Image.asset(
                                "${question['attachment']}",
                                width: double.infinity,
                                height: 200,
                              ),
                            ),
                          if (question['type'] == 'tf' ||
                              question['type'] == 'mcq')
                            ..._printOptions(question, questionId)
                          else if (question['type'] == 'short')
                            _shortT(questionId)
                          else if (question['type'] == 'essay')
                            _essayT(questionId),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF354F52),
                  ),
                  onPressed: () {
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Confirm Save'),
                        content: const Text(
                            'Are you sure you want to save your progress?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Yes, Save'),
                            onPressed: () {
                              Navigator.pop(context, 'Yes, Save');
                              Map<String, dynamic> updatedAnswers = {};
                              widget.registerRow["answers"]
                                  .forEach((questionId, answerDetails) {
                                updatedAnswers[questionId] = {
                                  "answer": answers[questionId] ??
                                      answerDetails['answer'],
                                  "feedback": "",
                                  "score": 0,
                                };
                              });
                              FirebaseFirestore.instance
                                  .collection("Registered")
                                  .doc(widget.registerRow['id'])
                                  .set({
                                "userID": widget.registerRow['userID'],
                                "examID": widget.registerRow['examID'],
                                "totalScore": 0,
                                "isGraded": false,
                                "feedback": "",
                                "startTime": startTime,
                                if (attemptStatusInProgress)
                                  "attemptsRemaining":
                                      widget.registerRow['attemptsRemaining']
                                else
                                  "attemptsRemaining":
                                      widget.registerRow['attemptsRemaining'] -
                                          1,
                                "attemptStatus": "inProgress",
                                "answers": updatedAnswers,
                              });
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => studentDashboard(
                                    userId: widget.registerRow['userID'],
                                  ),
                                ),
                              );
                            },
                          ),
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text("  Save & Exit  "),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Container(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF354F52),
                  ),
                  onPressed: () {
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Confirm Submit'),
                        content: const Text(
                            'Are you sure you want to submit your work?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Yes, Submit'),
                            onPressed: () {
                              Navigator.pop(context, 'Yes, Submit');
                              _submit();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => studentDashboard(
                                    userId: widget.registerRow['userID'],
                                  ),
                                ),
                              );
                            },
                          ),
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text("    Submit    "),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 2,
          )
        ],
      ),
    );
  }

  Widget _shortT(String qid) {
    if (textControllers[qid] == null) {
      textControllers[qid] = TextEditingController(
        text: widget.registerRow['answers'][qid]?['answer'],
      );
    }

    final controller = textControllers[qid];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 2,
        onChanged: (value) {
          setState(() {
            answers[qid] = value;
          });
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _essayT(String qid) {
    if (textControllers[qid] == null) {
      textControllers[qid] = TextEditingController(
        text: widget.registerRow['answers'][qid]?['answer'],
      );
    }

    final controller = textControllers[qid];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 200,
        onChanged: (value) {
          setState(() {
            answers[qid] = value;
          });
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  List<Widget> _printOptions(Map<String, dynamic> questionData, String qid) {
    if (questionData['options'] != null && questionData['options'] is List) {
      var options = questionData['options'] as List;
      String? initialAnswer =
          answers[qid] ?? widget.registerRow['answers'][qid]?['answer'];

      return List.generate(
        options.length,
        (index) {
          return RadioListTile(
            title: Text(options[index].toString()),
            value: options[index].toString(),
            groupValue: initialAnswer,
            onChanged: (value) {
              setState(() {
                answers[qid] = value;
              });
            },
          );
        },
      );
    } else {
      return [const Text('No options available')];
    }
  }

  void _submit() {
    Map<String, dynamic> updatedAnswers = {};
    widget.registerRow["answers"].forEach((questionId, answerDetails) {
      updatedAnswers[questionId] = {
        "answer": answers[questionId] ?? answerDetails['answer'],
        "feedback": "",
        "score": 0,
      };
    });
    FirebaseFirestore.instance
        .collection("Registered")
        .doc(widget.registerRow['id'])
        .set({
      "userID": widget.registerRow['userID'],
      "examID": widget.registerRow['examID'],
      "totalScore": 0,
      "isGraded": false,
      "feedback": "",
      "startTime": startTime,
      "endTime": Timestamp.now(),
      if (attemptStatusInProgress)
        "attemptsRemaining": widget.registerRow['attemptsRemaining']
      else
        "attemptsRemaining": widget.registerRow['attemptsRemaining'] - 1,
      "attemptStatus": "completed",
      "answers": updatedAnswers,
    });
    FirebaseFirestore.instance.collection("Notifications").doc().set({
      "dateTime": Timestamp.now(),
      "description": "$studentName has submitted $examTitle",
      "isRead": false,
      "title": "New Submitted Exam",
      "userID": examCreator,
    });
  }

  void _endExamTimer() {
    if (endTime != null) {
      final durationToEndTime = endTime!.toDate().difference(DateTime.now());
      Timer(durationToEndTime, () {
        if (DateTime.now().isAfter(endTime!.toDate())) {
          _endExamMessage(
            "Time's up!",
            "The allocated exam time has ended. Your answers have been submitted automatically.",
          );
        }
      });
    }

    if (examEndTime != null) {
      final durationToExamEndTime =
          examEndTime!.toDate().difference(DateTime.now());
      Timer(durationToExamEndTime, () {
        if (DateTime.now().isAfter(examEndTime!.toDate())) {
          _endExamMessage(
            "Exam Closed",
            "The exam has officially ended as per the scheduled end time. Your answers have been submitted automatically.",
          );
        }
      });
    }
  }

  void _endExamMessage(String title, String message) {
    _submit();
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => studentDashboard(
                      userId: widget.registerRow['userID'],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}

class TimeLeftProgressBar extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;

  const TimeLeftProgressBar({
    super.key,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<TimeLeftProgressBar> createState() => _TimeLeftProgressBarState();
}

class _TimeLeftProgressBarState extends State<TimeLeftProgressBar> {
  late Timer _timer;
  late Duration _totalDuration;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.endTime.difference(widget.startTime);
    _timeLeft = widget.endTime.difference(DateTime.now());

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft = widget.endTime.difference(DateTime.now());
        if (_timeLeft.isNegative || _timeLeft == Duration.zero) {
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Duration elapsedTime = DateTime.now().difference(widget.startTime);

    double progress = elapsedTime.inSeconds / _totalDuration.inSeconds;
    progress = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white,
            valueColor: const AlwaysStoppedAnimation<Color>(
                Color.fromARGB(255, 19, 67, 74)),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _timeLeft.isNegative
              ? "Time's up!"
              : "Time Left  ${_timeLeft.inMinutes.toString().padLeft(2, '0')}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}",
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }
}
