import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_cloud_firestore/firebase_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';
import 'completedExam.dart';
import "AdminDashboard.dart";


// ============================================================================================================
// Firestore Class
// ============================================================================================================
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add or update data
 Future<void> addExam(Map<String, dynamic> exam, List<Question> questionsInExam) async {
  try {
    // Add the exam and get the document reference
    DocumentReference examRef = await FirebaseFirestore.instance.collection('Exams').add(exam);

    print('exam ref id: ${examRef.id}');

    String exID = examRef.id; 

    
    print(QuestionList._questionsInExam);

    for (int i = 0; i < QuestionList._questionsInExam.length; i++) {
  var question = QuestionList._questionsInExam[i];
  print('Processing question at index $i: ${question.question}');
}

    //List<Question> questions = context.read<QuestionList>().questionsInExam;
    for (var question in QuestionList._questionsInExam) {
      question.examID = exID; // Assign the exam ID to the question
      print('question ref id: ${question.mapQuestion()}');
    }
    // List to store question IDs
    List<String> questionsIds = [];
    print(questionsInExam.length);
    // Add questions to Firestore and collect their IDs
    for (var question in questionsInExam) {
      question.examID = exID; // Assign the exam ID to the question
      DocumentReference questionRef = await FirebaseFirestore.instance
          .collection('Questions')
          .add(question.mapQuestion());
      
      questionsIds.add(questionRef.id);
      print('question ref id: ${questionRef.id}');
    }

    // Update the exam document with the question list
    await FirebaseFirestore.instance
        .collection('Exams')
        .doc(examRef.id)
        .update({"questionList": questionsIds});

    print('Exam and questions successfully added!');
  } catch (e) {
    print('Error adding exam and questions: $e');
    // Handle the error gracefully or rethrow it if necessary
  }
}

  Future<Map<String, dynamic>?> getExam(String id) async {
    try {
      DocumentSnapshot doc = await _db.collection("Exams").doc(id).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getQuestion(String id) async {
    try {
      DocumentSnapshot doc = await _db.collection("Questions").doc(id).get();
      if (doc.exists) {
        return {...doc.data() as Map<String, dynamic>};
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> getRegestiration(String id) async {
    try {
      DocumentSnapshot doc = await _db.collection("Registered").doc(id).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
    } catch (e) {
      return {"error": "the registiration is deleted"};
    }
    return {"error": "the registiration is deleted"};
  }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Exam class
////////////////////////////////////////////////////////////////////////////////////////////////////////

Map<String, dynamic> Exam = {
  "title": "",
  "description": "",
  "startTime": DateTime.now(),
  "endTime": DateTime.now().add(const Duration(days: 1)),
  "duration": const Duration(hours: 1),
  "attempts": 1,
  "isRandom": false,
  "questionList": [],
  "totalScore": 0,
  "userID": ""
};

////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Question class
////////////////////////////////////////////////////////////////////////////////////////////////////////
enum QuestionTypes { mcq, tf, short, essay }

class Question {
  QuestionTypes type = QuestionTypes.mcq;
  String? question;
  List<String>? options;
  String? correctAnswer;
  String? correctIndex = "0";
  int? score;
  String? attachment;
  String? examID;
  List<String>? radioIndex;


  

  Map<String, dynamic> mapQuestion() {
    String correct = correctIndex ?? "0";
    List<String> opts = options ?? [];

    print('$question, $score, $attachment, $examID');
    

    if(type == QuestionTypes.mcq)
    {
      return {
        "type": "mcq",
            "question": question ?? "",
            "score": score ?? 0,
            "examID": examID ?? "",
            "attachment": attachment ?? "",
            "options": opts,
            "correctAnswer": opts.isNotEmpty ? opts[int.parse(correct)] : ""
      };
    } else if(type == QuestionTypes.tf)
    {
      return {
        "type": "tf",
      "question": question ?? "",
      "score": score ?? 0,
      "examID": examID ?? "",
      "attachment": attachment ?? "",
      "options": opts,
      "correctAnswer": opts.isNotEmpty ? opts[int.parse(correct)] : "",
      };
    }
    else if(type == QuestionTypes.short) {
      return {
        "type": "short",
            "question": question ?? "",
            "score": score ?? "",
            "examID": examID ?? "",
            "attachment": attachment ?? "",
      };
    }
    else if(type == QuestionTypes.essay) {
      return {
        "type": "essay",
            "question": question ?? "",
            "score": score ?? "",
            "examID": examID ?? "",
            "attachment": attachment ?? "",
      };
    }
    else {
      return {
        "type": type.toString(),
            "question": question ?? "",
            "score": score ?? "",
            "examID": examID ?? "",
            "attachment": attachment ?? "",
      };
    }

  }

  Question(this.type, this.question, this.score, this.examID, this.attachment,
      {this.options, this.correctAnswer, this.correctIndex, this.radioIndex});
}

class QuestionList extends ChangeNotifier {
  static List<Question> _questionsInExam = [];

  List<Question> get questionsInExam => _questionsInExam;

  void addQuestion(Question question) {
    _questionsInExam.add(question);
    print(_questionsInExam);
    notifyListeners();
  }

  void removeQuestion(Question question) {
    _questionsInExam.remove(question);
    notifyListeners();
  }

  void removeAll() {
    _questionsInExam = [];
    notifyListeners();
  }

  void updateTotal() {
    Exam['totalScore'] = 0;
    for (var question in _questionsInExam) {
      Exam['totalScore'] += question.score ?? 0;
    }
    notifyListeners();
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Create Exam
////////////////////////////////////////////////////////////////////////////////////////////////////////

class CreateExam extends StatefulWidget {
  String userID;
  CreateExam({super.key, required this.userID});

  @override
  State<CreateExam> createState() => CreateExamState();
}

enum TF { True, False }

class CreateExamState extends State<CreateExam> {

  

  TextEditingController startTimeCrtl = TextEditingController();
  TextEditingController endTimeCrtl = TextEditingController();
  TextEditingController durationCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();

  QuestionTypes selectedType = QuestionTypes.mcq;
  int? hours = 0;
  int? minute = 0;
  String attach = "";

  final GlobalKey<FormState> keyform = GlobalKey<FormState>();
  final RegExp attempts = RegExp(r"^[0-9]{0,3}$");
  Widget display(Question object, BuildContext context) {
    final RegExp scoreCheck = RegExp(r"^[0-9]+$");

  addAndDisplayAttachement(){
   
    return ListTile(
      title: const Text("Choose Image to attach: "),
      trailing: DropdownButton(
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF354F52)),
        iconSize: 30,
        focusColor: Colors.transparent,
        value: object.attachment,
        items: const [
        DropdownMenuItem<String>(
          value: "",
          child: Text("Select Attachment"),
        ),
        DropdownMenuItem<String>(
          value: 'clock.jpg',
          child: Text('Clock'),
        ),
        DropdownMenuItem<String>(
          value: 'insect.jpg',
          child: Text('Insect Image'),
        ),
        DropdownMenuItem<String>(
          value: 'java.png',
          child: Text('Java Code'),
        ),
        DropdownMenuItem<String>(
          value: 'map.webp',
          child: Text('Map'),
        ),
        DropdownMenuItem<String>(
          value: 'math.jpg',
          child: Text('Math equation'),
        ),
        DropdownMenuItem<String>(
          value: 'measure.jpg',
          child: Text('Ruler measurement'),
        ),
        DropdownMenuItem<String>(
          value: 'physics.jpg',
          child: Text('Physics'),
        ),
        DropdownMenuItem<String>(
          value: 'planets.jpg',
          child: Text('Solar System planets'),
        ),
        DropdownMenuItem<String>(
          value: 'reaction.png',
          child: Text('Chemical reaction'),
        ),
        DropdownMenuItem<String>(
          value: 'reading.jpg',
          child: Text('Small Reading'),
        ),
      ],onChanged: (String? newAttach){
        setState(() {
          object.attachment = newAttach ?? ""; 
        });
      }),
    );
  }

    displayShortAndEssay() {
      return TextFormField(
          readOnly: true,
          minLines: object.type == QuestionTypes.short ? 1 : 3,
          maxLines: object.type == QuestionTypes.short ? 1 : 100,
          decoration: InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: true,
            hintText: object.type == QuestionTypes.short
                ? "short answer here "
                : "assay answer here ",
          ));
    }

    displayMcq() {
      int count = object.options!.length;

      return Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: count,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Radio<String>(
                  activeColor: const Color(0xFF354F52),
                  value: object.radioIndex![index],
                  groupValue: object.correctIndex,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        object.correctIndex = value;
                      });
                    }
                  },
                ),
                title: TextFormField(
                  decoration: InputDecoration(
                    labelText: "Option ${index + 1}",
                    hintText: "Option ${index + 1}",
                    border: const OutlineInputBorder(),
                  ),
                  initialValue: object.options![index],
                  onChanged: (value) {
                    setState(() {
                      object.options![index] = value;
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) return "Please write option";
                    return null;
                  },
                ),
                trailing: object.correctIndex == object.radioIndex![index]
                    ? const Text("correct answer")
                    : const SizedBox(),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF354F52),
                foregroundColor: Colors.white,
                maximumSize: Size(MediaQuery.of(context).size.width * 0.3, 80)),
            onPressed: () {
              setState(() {
                object.radioIndex!.add("${count + 1}");
                object.options!.add("");
              });
            },
            child: const Row(
              children: [Icon(Icons.add), Text("Add Option")],
            ),
          ),
        ],
      );
    }

    displayTf() {
      return Column(
        children: [
          ListTile(
            leading: Radio(
                value: "true",
                groupValue: object.correctAnswer,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      object.correctAnswer = value;
                    });
                  }
                }),
            title: const Text("true"),
            trailing: object.correctAnswer == "true"
                ? const Text("correct answer")
                : const SizedBox(),
          ),
          ListTile(
            leading: Radio(
                value: "false",
                groupValue: object.correctAnswer,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      object.correctAnswer = value;
                    });
                  }
                }),
            title: const Text("false"),
            trailing: object.correctAnswer == "false"
                ? const Text("correct answer")
                : const SizedBox(),
          ),
        ],
      );
    }

    return Card(
      key: ValueKey(object),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(10),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Question",
                      hintText: "Question",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: object.question,
                    onChanged: (value) {
                      object.question = value;
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "please write question";
                      }
                      return null;
                    },
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.35,
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Text("question score"),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            hintText: "score",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "please\nspecify\nScore";
                            }
                            if (!scoreCheck.hasMatch(value)) {
                              return "should only\nnumbers";
                            }

                            return null;
                          },
                          onChanged: (value) {
                            object.score = value.isEmpty ? 0 : int.parse(value);
                            context.read<QuestionList>().updateTotal();
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            addAndDisplayAttachement(),
            const SizedBox(height: 10),
            object.type == QuestionTypes.mcq
                ? displayMcq()
                : (object.type == QuestionTypes.tf
                    ? displayTf()
                    : displayShortAndEssay()),
            Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Delete Question"),
                              content: const Text(
                                  "Are you sure you want to delete the question?"),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      context
                                          .read<QuestionList>()
                                          .removeQuestion(object);
                                      context
                                          .read<QuestionList>()
                                          .updateTotal();
                                      Navigator.pop(context, "Delete");
                                      const successDelete = SnackBar(
                                        content: Text(
                                            "Question Deleted Successfully",
                                            style:
                                                TextStyle(color: Colors.black)),
                                        backgroundColor: Colors.lime,
                                        duration: Duration(seconds: 2),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(successDelete);
                                    },
                                    child: const Text("Delete")),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, "Cancel");
                                    },
                                    child: const Text("Cancel")),
                              ],
                            );
                          });
                    },
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: Colors.red,
                    )))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Exam"),backgroundColor: const Color(0xFF354F52), foregroundColor: Colors.white),
      body: Scrollbar(
        child: SingleChildScrollView(
          controller: scrollCtrl,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Form(
              key: keyform,
              child: Column(
                children: [
                  // automatic total score calculated
                  Container(
                    width: 150,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color.fromARGB(255, 238, 238, 238),
                    ),
                    margin: const EdgeInsets.all(15),
                    padding: const EdgeInsets.all(8),
                    child: Text("Total Score ${Exam['totalScore']}"),
                  ),
                  // title of the exam
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: "title",
                        hintText: "title",
                        icon: Icon(Icons.title_rounded),
                        border: OutlineInputBorder()),
                    initialValue: Exam['title'],
                    onChanged: (value) {
                      Exam['title'] = value;
                    },
                    validator: (value) {
                      if (value!.isEmpty) return "Please write title";
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // description of the exam
                  TextFormField(
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: "Description",
                        hintText: "Description",
                        icon: Icon(Icons.description_rounded),
                        border: OutlineInputBorder()),
                    initialValue: Exam['description'],
                    onChanged: (value) {
                      Exam['description'] = value;
                    },
                    validator: (value) {
                      if (value!.isEmpty) return "Please write description";
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // start time of the exam
                  Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: startTimeCrtl,
                          decoration: const InputDecoration(
                              labelText: "Start Time",
                              hintText: "Start Time",
                              border: OutlineInputBorder()),
                          readOnly: true,
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: (365 * 4))),
                            );
                            TimeOfDay? selectedTime = await showTimePicker(
                                context: context, initialTime: TimeOfDay.now());
                            if (selectedDate != null) {
                              Exam['startTime'] = selectedDate.add(Duration(
                                  hours: selectedTime?.hour ?? 0,
                                  minutes: selectedTime?.minute ?? 0));
                              startTimeCrtl.text = Exam['startTime'].toString();
                            }
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Please choose start time";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: endTimeCrtl,
                          decoration: const InputDecoration(
                              labelText: "End Time",
                              hintText: "End Time",
                              border: OutlineInputBorder()),
                          readOnly: true,
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: (365 * 4))),
                            );
                            TimeOfDay? selectedTime = await showTimePicker(
                                context: context, initialTime: TimeOfDay.now());
                            if (selectedDate != null) {
                              Exam['endTime'] = selectedDate.add(Duration(
                                  hours: selectedTime?.hour ?? 0,
                                  minutes: selectedTime?.minute ?? 0));
                              endTimeCrtl.text = Exam['endTime'].toString();
                            }
                          },
                          validator: (value) {
                            if (value!.isEmpty) return "Please choose end time";
                            if (Exam['endTime'].compareTo(Exam['startTime']) <=
                                0) {
                              return "time of end must be\nafter than start";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  //duration & randomize
                  TextFormField(
                      controller: durationCtrl,
                      decoration: const InputDecoration(
                          labelText: "Duration",
                          hintText: "Duration",
                          border: OutlineInputBorder(),
                          icon: Icon(Icons.timelapse_rounded)),
                      validator: (value) {
                        if (value!.isEmpty) return "Please choose duration";
                        if (Exam['endTime']
                                .difference(Exam['startTime'])
                                .inMinutes <
                            Exam['duration']) {
                          return "please make duration approtiate with the available time";
                        }
                        return null;
                      },
                      readOnly: true,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(builder: (BuildContext
                                    context,
                                void Function(void Function()) setDialogState) {
                              return AlertDialog(
                                title: const Text("duration of the exam"),
                                content: Row(
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text("hours"),
                                        NumberPicker(
                                          value: hours ?? 0,
                                          minValue: 0,
                                          maxValue: 100,
                                          step: 1,
                                          onChanged: (value) => setDialogState(
                                              () => hours = value),
                                        )
                                      ],
                                    ),
                                    const Text(":"),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text("minute"),
                                        NumberPicker(
                                          value: minute ?? 0,
                                          minValue: 0,
                                          maxValue: 59,
                                          step: 1,
                                          onChanged: (value) => setDialogState(
                                              () => minute = value),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        durationCtrl.text =
                                            "$hours hours $minute minutes";
                                        Exam['duration'] = Duration(
                                                hours: hours ?? 0,
                                                minutes: minute ?? 0)
                                            .inMinutes;
                                        Navigator.pop(context, "Select");
                                      },
                                      child: const Text("Select")),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, "Cancel");
                                      },
                                      child: const Text("Cancel")),
                                ],
                              );
                            });
                          },
                        );
                      }),
                  const SizedBox(height: 8),
                  //is random switch
                  ListTile(
                    contentPadding: const EdgeInsets.all(0),
                    leading: const Icon(Icons.sort),
                    title: const Text("randomize question"),
                    trailing: Switch(
                      activeColor: const Color(0xFF354F52),
                      inactiveTrackColor: Colors.white,
                      value: Exam["isRandom"],
                      onChanged: (value) {
                        setState(() {
                          Exam["isRandom"] = value;
                        });
                      },
                    ),
                  ),

                  Row(
                    // number of allowed attempts feild
                    children: [
                      const Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.all(0),
                          leading: Icon(Icons.repeat_rounded),
                          title: Text("Number of attemps allowed"),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: Expanded(
                          child: TextFormField(
                              maxLength: 3,
                              initialValue: Exam['attempts'].toString(),
                              onChanged: (value) {
                                Exam['attempts'] = int.parse(value);
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Please enter a number";
                                } else if (!attempts.hasMatch(value)) {
                                  return "should only numbers";
                                }
                                return null;
                              }),
                        ),
                      ),
                    ],
                  ),
                  Text(
                      context.read<QuestionList>().questionsInExam.isEmpty
                          ? "plaese add one question at least"
                          : "",
                      style: const TextStyle(color: Colors.red)),
                  ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          context.watch<QuestionList>().questionsInExam.length,
                      itemBuilder: (context, index) {
                        return display(
                            context
                                .watch<QuestionList>()
                                .questionsInExam[index],
                            context);
                      }),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF354F52),
                              foregroundColor: Colors.white),
                          onPressed: context
                                  .read<QuestionList>()
                                  .questionsInExam
                                  .isEmpty
                              ? null
                              : () {
                                  if (keyform.currentState!.validate()) {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Create Exam"),
                                            content: const Text(
                                                "Are you sure you want to save this exam?"),
                                            actions: [
                                              TextButton(
                                                  onPressed: () async {
                                                    FirestoreService FB = FirestoreService();
                                                    List<Question> questions = context.read<QuestionList>().questionsInExam;
                                                    print(questions);
                                                    Exam['userID'] = widget.userID;
                                                    await FB.addExam(Exam, questions);

                                                    setState(() {
                                                      Exam = {
                                                        "title": "",
                                                        "description": "",
                                                        "startTime":
                                                            DateTime.now(),
                                                        "endTime":
                                                            DateTime.now().add(
                                                                const Duration(
                                                                    days: 1)),
                                                        "duration":
                                                            const Duration(
                                                                hours: 1),
                                                        "attempts": 1,
                                                        "isRandom": false,
                                                        "questionList": [],
                                                        "totalScore": 0,
                                                        "userID": widget.userID
                                                      };
                                                      context
                                                          .read<QuestionList>()
                                                          .removeAll();
                                                      keyform.currentState!
                                                          .reset();
                                                    });
                                                    Navigator.pop(
                                                        context, "Save");
                                                        Navigator.pushReplacement(context, 
                                              MaterialPageRoute(builder: (context){return adminDashboard(userId: widget.userID);})
                                            );

                                                    const successAdd = SnackBar(
                                                      content: Text(
                                                          "Exam Added Successfully",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .black)),
                                                      backgroundColor:
                                                          Colors.lime,
                                                      duration:
                                                          Duration(seconds: 2),
                                                    );
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            successAdd);
                                                  },
                                                  child: const Text("Save")),
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(
                                                        context, "Cancel");
                                                  },
                                                  child: const Text("Cancel")),
                                            ],
                                          );
                                        });
                                  }
                                },
                          child: const Text("Save")),
                      const SizedBox(width: 20),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF354F52),
                              foregroundColor: Colors.white),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Cancel Exam"),
                                    content: const Text(
                                        "Are you sure you want to cancel? You will lose your progress."),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            keyform.currentState!.reset();
                                            Exam = {
                                              "title": "",
                                              "description": "",
                                              "startTime": DateTime.now(),
                                              "endTime": DateTime.now()
                                                  .add(const Duration(days: 1)),
                                              "duration":
                                                  const Duration(hours: 1),
                                              "attempts": 1,
                                              "isRandom": false,
                                              "questionList": [],
                                              "totalScore": 0,
                                            };
                                            print(Exam);
                                            setState(() {});
                                            context
                                                .read<QuestionList>()
                                                .removeAll();
                                            Navigator.pushReplacement(context, 
                                              MaterialPageRoute(builder: (context){return adminDashboard(userId: widget.userID);})
                                            );
                                          },
                                          child: const Text("Cancel it")),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                                context, "Continue working");
                                          },
                                          child:
                                              const Text("Continue working")),
                                    ],
                                  );
                                });
                          },
                          child: const Text("Cancel")),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: PopupMenuButton<QuestionTypes>(
          color: Colors.white,
          icon: Container(
              child: const Icon(
            Icons.add_circle_rounded,
            size: 35,
            color: Color(0xFF354F52),
          )),
          tooltip: "Add question",
          initialValue: selectedType,
          onSelected: (QuestionTypes type) {

            Question newQuestion;
            if(type == QuestionTypes.mcq)
            {
              newQuestion = Question(type, "", 0, "", "",
                options: ["", ""],
                correctAnswer: "",
                correctIndex: "0",
                radioIndex: ["0", "1"]);
            } else if(type == QuestionTypes.tf)
            {
              newQuestion = Question(type, "", 0, "", "",
                        options: ["true", "false"], correctAnswer: "true", correctIndex: "0", radioIndex: ["0", "1"]);
            }
            else if(type == QuestionTypes.short){
              newQuestion = Question(QuestionTypes.short, "", 0, "", "");
            }
            else if(type == QuestionTypes.essay) {
              newQuestion = Question(QuestionTypes.essay, "", 0, "", "");
            } else {
              newQuestion = Question(type, "", 0, "", "");
            }

            print(newQuestion);
            /*Question newQuestion = type == QuestionTypes.mcq
                ? Question(type, "", 0, "", "",
                    options: ["", ""],
                    correctAnswer: "",
                    correctIndex: "0",
                    radioIndex: ["0", "1"])
                : (type == QuestionTypes.tf
                    ? Question(type, "", 0, "", "",
                        options: ["true", "false"], correctAnswer: "true", correctIndex: "0", radioIndex: ["0", "1"])
                    : Question(type, "", 0, "", "",));*/
            setState(() {
              context.read<QuestionList>().addQuestion(newQuestion);

              // Animate the scroller to the end of the list with a delay
              Future.delayed(const Duration(milliseconds: 200), () {
                scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeIn);
              });
            });
          },
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<QuestionTypes>>[
              const PopupMenuItem<QuestionTypes>(
                value: QuestionTypes.mcq,
                child: Text('multipule choice question'),
              ),
              const PopupMenuItem<QuestionTypes>(
                value: QuestionTypes.tf,
                child: Text('True or false question'),
              ),
              const PopupMenuItem<QuestionTypes>(
                value: QuestionTypes.short,
                child: Text('short answer question'),
              ),
              const PopupMenuItem<QuestionTypes>(
                value: QuestionTypes.essay,
                child: Text('essay question'),
              ),
            ];
          }),
    );
  }
}
