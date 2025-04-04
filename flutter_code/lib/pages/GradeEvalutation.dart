import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Notificaton.dart';



class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int count = 0;

  @override
  void initState() {
    super.initState();

    calculateNotifcations("qV5nS1E7HmWqhkMEzObZ");

    setState(() {});
  }

  calculateNotifcations(String userID) async {
    count = 0;

    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('Notifications');
    try {
      QuerySnapshot notification = await collectionRef.get();
      for (QueryDocumentSnapshot doc in notification.docs) {
        String? notificationUserID = doc.get('userID');
        if (userID == notificationUserID) {
          count++;
        }
      }

      setState(() {});
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            "Admin Dashboard",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF354F52),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return NotificationPage(
                      userID: "qV5nS1E7HmWqhkMEzObZ",
                    );
                  }));
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications,
                      color: Colors.white,
                    ),
                    Text(
                      '$count',
                      style: const TextStyle(color: Colors.white),
                    )
                  ],
                )),
          ]),
      body: Center(
        child: TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const EvalutationPage(registeredID: "y9iRaWtHWH83z8ZzPfaR");
              }));
            },
            child: const Text("Student Submitted Exam")),
      ),
    );
  }
}

class EvalutationPage extends StatefulWidget {
  final String registeredID;

  const EvalutationPage({super.key, required this.registeredID});

  @override
  State<EvalutationPage> createState() => _EvalutationPageState();
}

class _EvalutationPageState extends State<EvalutationPage> {
  String? attemptStatus;
  num? attemptsRemaining;
  Timestamp? endTime;
  Timestamp? startTime;
  String? userID;
  String? examID;
  String? overallfeedback;
  bool? isGraded;
  num? totalScore;
  num? examTotal;
  Map<String, dynamic>? answers;
  Map<String, dynamic>? data;
  late TextEditingController overallfeedbackController;
  late FocusNode overallfeedbackFocusNode;

  @override
  void initState() {
    super.initState();
    readRegistered().then((_) {
      readExam(examID!);
      data = {};
      answers!.forEach((key, value) {
        readQuetions(key);
        //in data just save the (type, question, options, correctAnswer, score)
        //then, down part we can print design with details, when submit just update (answers) map
      });
    });

    setState(() {});
  }

  //read from DB
  readRegistered() async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection("Registered")
        .doc(widget.registeredID);
    try {
      DocumentSnapshot snapshot = await docRef.get();
      if (snapshot.exists) {
        examID = snapshot.get("examID");
        isGraded = snapshot.get("isGraded");
        totalScore = snapshot.get("totalScore");
        overallfeedback = snapshot.get("feedback");
        answers = snapshot.get('answers') as Map<String, dynamic>;
        attemptStatus = snapshot.get("attemptStatus");
        attemptsRemaining = snapshot.get("attemptsRemaining");
        startTime = snapshot.get('startTime');
        endTime = snapshot.get('endTime');
        userID = snapshot.get("userID");
        setState(() {});
      } else {
        print("Document not found");
      }
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  readExam(String examID) async {
    print("Documentsdkkjwd");
    DocumentReference docRef =
        FirebaseFirestore.instance.collection("Exams").doc(examID);
    try {
      DocumentSnapshot snapshot = await docRef.get();
      if (snapshot.exists) {
        examTotal = snapshot.get("totalScore");
        setState(() {});
      } else {
        print("Document not found");
      }
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  readQuetions(String questionID) async {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection("Questions").doc(questionID);
    try {
      DocumentSnapshot snapshot = await docRef.get();
      if (snapshot.exists) {
        String question = snapshot.get("question");
        String type = snapshot.get("type");
        if (["mcq", "tf"].contains(type)) {
          data![questionID] = {
            'question': question,
            'type': type,
            'options': snapshot.get("options"),
            'correctAnswer': snapshot.get("correctAnswer"),
            'score': snapshot.get("score")
          };
        } else {
          data![questionID] = {
            'question': question,
            'type': type,
            'score': snapshot.get("score")
          };
        }
        setState(() {});
      } else {
        print("Document not found");
      }
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  updateData() {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection("Registered")
        .doc(widget.registeredID);

    Map<String, dynamic> Item = {
      "answers": answers,
      "attemptStatus": attemptStatus,
      "attemptsRemaining": attemptsRemaining,
      "endTime": endTime,
      "startTime": startTime,
      "feedback": overallfeedback,
      "examID": examID,
      "isGraded": isGraded,
      "totalScore": totalScore,
      "userID": userID
    };

    docRef.set(Item).whenComplete(() {
      print("Updated!!!!!!!!!!!!!!!!!!!!");
    });
  }

  calculateTotalScore() {
    num total = 0;

    answers!.forEach((key, value) {
      num score = value['score'] ?? 0;
      total = (total + score);
    });

    setState(() {
      totalScore = total;
    });
  }

  Widget DisplayCard(String id) {
    final String? questionText = data?[id]['question'];
    String? type = data?[id]['type'];

    late TextEditingController scoreController;
    late TextEditingController feedbackController;
    late FocusNode scoreFocusNode;
    late FocusNode feedbackFocusNode;

    scoreController =
        TextEditingController(text: answers![id]['score'].toString());
    feedbackController =
        TextEditingController(text: answers![id]['feedback'] ?? '');
    scoreFocusNode = FocusNode();
    feedbackFocusNode = FocusNode();

    scoreFocusNode.addListener(() {
      if (!scoreFocusNode.hasFocus) {
        setState(() {
          if (scoreController.text == "" ||
              num.tryParse(scoreController.text) == null) {
            scoreController.text = '0';
          }
          if (num.parse(scoreController.text) > data![id]['score']) {
            scoreController.text = '${data![id]['score']}';
          }

          answers![id]['score'] = num.parse(scoreController.text);
          calculateTotalScore();
        });
      }
    });

    feedbackFocusNode.addListener(() {
      if (!feedbackFocusNode.hasFocus) {
        setState(() {
          answers![id]['feedback'] = feedbackController.text;
        });
      }
    });

    @override
    void dispose() {
      scoreController.dispose();
      feedbackController.dispose();
      scoreFocusNode.dispose();
      feedbackFocusNode.dispose();
      super.dispose();
    }

    if (questionText == null) {
      return const Text('Question data not found');
    }

    if (['mcq', 'tf'].contains(type)) {
      //correcting question
      if (answers![id]['answer'] == data![id]['correctAnswer']) {
        answers![id]['score'] = data![id]['score'];
        calculateTotalScore();
      }

      return Column(
        children: [
          Container(
              padding: const EdgeInsets.all(20),
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), color: Colors.white),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Q:  $questionText"),
                      Container(
                        alignment: Alignment.center,
                        width: 50,
                        height: 30,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color.fromARGB(255, 238, 238, 238)),
                        child: Text(
                            "${answers![id]['score']} / ${data![id]['score']}"),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: List.generate(
                      data![id]['options'].length,
                      (index) {
                        String optionValue = data![id]['options'][index];
                        bool isCorrect =
                            optionValue == data![id]['correctAnswer'];

                        return Row(
                          children: [
                            Expanded(
                              child: RadioListTile(
                                title: Text(optionValue),
                                value: optionValue,
                                groupValue: answers![id]['answer'],
                                dense: true,
                                onChanged: null,
                              ),
                            ),
                            if (isCorrect)
                              const Text(
                                "Correct Option     ",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              )),
          const SizedBox(
            height: 10,
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.all(20),
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), color: Colors.white),
              child: Column(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Q:  $questionText"),
                        Container(
                            alignment: Alignment.center,
                            width: 80,
                            height: 30,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: const Color.fromARGB(255, 238, 238, 238)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                    width: 40,
                                    child: TextField(
                                      controller: scoreController,
                                      focusNode: scoreFocusNode,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        isCollapsed: true,
                                        isDense: true,
                                        filled: true,
                                        fillColor:
                                            Color.fromARGB(255, 210, 210, 210),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                          borderSide: BorderSide.none,
                                        ),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,
                                      ),
                                      keyboardType: TextInputType.number,
                                    )),
                                Text(" / ${data![id]['score']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))
                              ],
                            )),
                      ]),
                  const SizedBox(height: 10),
                  if (type == 'short')
                    TextField(
                      controller: TextEditingController(
                          text: answers![id]['answer'] ?? ''),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color.fromARGB(255, 248, 248, 248),
                        hoverColor: Color.fromARGB(255, 248, 248, 248),
                        focusColor: Color.fromARGB(255, 248, 248, 248),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      readOnly: true,
                    ),
                  if (type == 'essay')
                    TextField(
                      controller: TextEditingController(
                          text: answers![id]['answer'] ?? ''),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color.fromARGB(255, 248, 248, 248),
                        hoverColor: Color.fromARGB(255, 248, 248, 248),
                        focusColor: Color.fromARGB(255, 248, 248, 248),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      readOnly: true,
                      maxLines: 4,
                    ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("FeedBack:"),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: feedbackController,
                    focusNode: feedbackFocusNode,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color.fromARGB(255, 234, 234, 234),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    maxLines: 3,
                  ),
                ],
              )),
          const SizedBox(
            height: 10,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    overallfeedbackController =
        TextEditingController(text: overallfeedback ?? '');
    overallfeedbackFocusNode = FocusNode();

    @override
    void dispose() {
      overallfeedbackController.dispose();
      overallfeedbackFocusNode.dispose();
      super.dispose();
    }

    overallfeedbackFocusNode.addListener(() {
      if (!overallfeedbackFocusNode.hasFocus) {
        setState(() {
          overallfeedback = overallfeedbackController.text;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Grade Evalution",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF354F52),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Total Score: "),
                    Container(
                      alignment: Alignment.center,
                      width: 70,
                      height: 30,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color.fromARGB(255, 238, 238, 238)),
                      child: Text("  $totalScore / $examTotal  "),
                    )
                  ],
                )),
            const SizedBox(
              height: 10,
            ),
            if (data != null)
              ...data!.entries.map((entry) => DisplayCard(entry.key)),
            const SizedBox(
              height: 10,
            ),
            Container(
              padding: const EdgeInsets.all(20),
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), color: Colors.white),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Overall FeedBack:"),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: overallfeedbackController,
                    focusNode: overallfeedbackFocusNode,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color.fromARGB(255, 234, 234, 234),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    style: ButtonStyle(
                        backgroundColor:
                            const WidgetStatePropertyAll(Color(0xFF354F52)),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                        padding: const WidgetStatePropertyAll(
                            EdgeInsetsDirectional.only(
                                top: 15, bottom: 15, start: 40, end: 40))),
                    onPressed: () {
                      setState(() {
                        showDialog<String>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text('Confirmation'),
                            content: const Text(
                                "Are you sure to cancel the evaluation? All your work will not be saved."),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, 'Ok');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Evalutation is cancelled'),
                                      duration: Duration(seconds: 2),
                                      backgroundColor:
                                          Color.fromARGB(197, 168, 131, 44),
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text("Ok"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'Cancel'),
                                child: const Text("Cancel"),
                              ),
                            ],
                          ),
                        );
                      });
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    )),
                TextButton(
                    style: ButtonStyle(
                        backgroundColor:
                            const WidgetStatePropertyAll(Color(0xFF354F52)),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                        padding: const WidgetStatePropertyAll(
                            EdgeInsetsDirectional.only(
                                top: 15, bottom: 15, start: 40, end: 40))),
                    onPressed: () {
                      setState(() {
                        showDialog<String>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text('Confirmation'),
                            content: const Text(
                                "Are you sure to save the grade evalution?"),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  calculateTotalScore();
                                  isGraded = true;
                                  updateData();
                                  Navigator.pop(context, 'Ok');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Evalutation Saved Successfuly'),
                                      duration: Duration(seconds: 2),
                                      backgroundColor:
                                          Color.fromARGB(198, 69, 168, 44),
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text("Ok"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'Cancel'),
                                child: const Text("Cancel"),
                              ),
                            ],
                          ),
                        );
                      });
                    },
                    child: const Text(
                      "Save & Exit",
                      style: TextStyle(color: Colors.white),
                    ))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
