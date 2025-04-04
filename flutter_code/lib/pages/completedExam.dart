import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'studentDashboard.dart';


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


  Map<String,dynamic> mapQuestion(){
    String correct = correctIndex!;
    return type==QuestionTypes.mcq?
    {
      "type" : type==QuestionTypes.mcq?"mcq":"tf",
      "question": question,
      "options":options,
      "correctAnswer":options![int.parse(correct)],
      "score":score,
      "attachment":attachment,
      "examID":examID,
    }:(type==QuestionTypes.tf?
    {
      "type" : type==QuestionTypes.mcq?"mcq":"tf",
      "question": question,
      "options":options,
      "correctAnswer":correctAnswer,
      "score":score,
      "attachment":attachment,
      "examID":examID,
    }:{
      "type" : type==QuestionTypes.short?"short":"essay",
      "question": question,
      "score":score,
      "attachment":attachment,
      "examID":examID,
    });
  }

  Question(this.type, this.question, this.score, this.examID, this.attachment,{ this.options, this.correctAnswer, this.correctIndex, this.radioIndex});
}



// ============================================================================================================
// Firestore Class
// ============================================================================================================      
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Add or update data
  Future<void> addExam(Map<String,dynamic> exam, List<Question> questioInExam) async {
    DocumentReference examRef = await FirebaseFirestore.instance.collection('Exams').add(exam);
    List<String> questionsIds = [];
    for(var question in questioInExam){
      question.examID=examRef.id;
      DocumentReference questionRef = await FirebaseFirestore.instance.collection('Questions').add(question.mapQuestion());
      questionsIds.add(questionRef.id);
    }
    DocumentReference examAddedBefore = _db.collection("Exams").doc(examRef.id);
    await examAddedBefore.update({"questionList": questionsIds});

  }

  Future<Map<String, dynamic>?> getExam(String id) async{
    try{
      DocumentSnapshot doc = await _db.collection("Exams").doc(id).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
    }catch(e){
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getQuestion(String id) async{
    try{
      DocumentSnapshot doc = await _db.collection("Questions").doc(id).get();
      if (doc.exists) {
        return {...doc.data() as Map<String, dynamic>};
      }
    }catch(e){
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> getRegestiration(String id) async{
    try{
      DocumentSnapshot doc = await _db.collection("Registered").doc(id).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
    }catch(e){
      return {"error":"the registiration is deleted"}; 
    }
    return {"error":"the registiration is deleted"}; 
  }
  
}



////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Completed Exam
////////////////////////////////////////////////////////////////////////////////////////////////////////
class CompletedExam extends StatefulWidget {
  Map<String, dynamic> rigesterRow;
  CompletedExam({super.key, required this.rigesterRow});

  @override
  State<CompletedExam> createState() => _CompletedExamState();
}

class _CompletedExamState extends State<CompletedExam> {

  FirestoreService FB = FirestoreService();
  Map<String, dynamic>? rigesterData;
  Map<String, dynamic>? examData;
  late String title;
  String? description;
  late int totalScore;
  late int Score;
  String? feedback;
  bool isLoading = true;
  Map<String,dynamic>  questionList ={}; 
  Map<String,dynamic>  answers ={}; 

  @override
  void initState() {
    super.initState();
    getDocument(); 
  }

  Future<void> getDocument() async {
    try {
      int count =0;
      rigesterData = widget.rigesterRow;

      answers= rigesterData!["answers"];

      examData = await FB.getExam(rigesterData!['examID']);
      title = examData!["title"];
      description= examData?["description"]??"";
      totalScore= examData!["totalScore"];
      Score= rigesterData!["totalScore"];
      feedback = rigesterData!["feedback"]??"";

      for(var x in examData!["questionList"]){
        Map<String,dynamic>? questionInstance = await FB.getQuestion(x);
        questionList[x.toString()]=questionInstance;
      }

      setState(() {
        isLoading = false; 
      });
    } catch (e) {
      setState(() {
        isLoading = false; 
      });
    }
  }

  displayQuestion(String key, dynamic value, bool isGrade){
    Map<String,dynamic> thisQuestionAnswer = answers[key]; 
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.white,
        child:(value["type"]== "mcq" ||value["type"]== "tf") ?
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(value["question"]??""),
                ),
                Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color:const Color.fromARGB(255, 238, 238, 238),
                  ),
                  margin: const EdgeInsets.all(15),
                  padding: const EdgeInsets.all(8),
                  child:Text("score  ${thisQuestionAnswer["score"]}/${value["score"]}"),
                )
              ],
            ),
            (value["attachment"] != null && value["attachment"] != "") ? Container(
              margin: EdgeInsets.all(20),
              child: Image(
                image: AssetImage(value["attachment"]!), 
                width: double.infinity, 
                height: 200, 
              ),
            ) : const SizedBox(),
            ...value["options"].map((entry) {
              return ListTile(
                tileColor: (entry == thisQuestionAnswer["answer"] && (examData!['endTime'].toDate()).compareTo(DateTime.now())<0)? ((entry == value["correctAnswer"] )?const Color.fromARGB(222, 203, 237, 204):const Color.fromARGB(227, 248, 175, 175)):Colors.transparent,
                leading: entry == thisQuestionAnswer["answer"] ? const Icon(Icons.radio_button_checked):const Icon(Icons.radio_button_off),
                title: Text(entry),
                trailing: (entry == value["correctAnswer"] && examData!['endTime'].toDate().compareTo(DateTime.now())<0)? const Text("Correct Answer"):const SizedBox(),
              );
            }).toList(),
            const SizedBox(height: 20)
          ],
        ):Column(
          children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(value["question"]??""),
                ),
                Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color.fromARGB(255, 238, 238, 238),
                  ),
                  margin: const EdgeInsets.all(15),
                  padding: const EdgeInsets.all(8),
                  child:isGrade?Text("score  ${thisQuestionAnswer["score"]}/${value["score"]}"):const Text("Not Graded"),
                )
              ],
            ),
            (value["attachment"] != null && value["attachment"] != "") ?Container(
              margin: EdgeInsets.all(20),
              child: Image(
                image: AssetImage(value["attachment"]!), 
                width: double.infinity, 
                height: 200, 
              ),
            ): const SizedBox(),
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color:const Color.fromARGB(255, 238, 238, 238),
                  ),
              child: Text(thisQuestionAnswer["answer"] ?? ""),
            ),
            const SizedBox(height: 10),
            SizedBox(width: MediaQuery.of(context).size.width * 0.9,child: const Text("Feedback: "),),
            
            const SizedBox(height: 10),
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color.fromARGB(255, 238, 238, 238),
                  ),
              child: Text(thisQuestionAnswer["feedback"]??""),
            ),
            const SizedBox(height: 20)
        ],),
      ),
    );
  }


  examDisplay(){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(title, style: const TextStyle(fontSize: 25),),
              ),
              Container(
                width: 150,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:const Color.fromARGB(255, 238, 238, 238),
                ),
                
                padding: const EdgeInsets.all(8),
                child:Text("Total Score  $Score/$totalScore"),
              )
            ],
          ),
        ),
        ListTile(
          title: const Text("description: "),
          subtitle: Text(description??"No discription"),
        ),
        ListTile(
          title: const Text("feedback: "),
          subtitle: Text(feedback??"No feedback"),
        ),
        ...questionList.entries.map((entry) {
          return displayQuestion(entry.key, entry.value, rigesterData!["isGraded"]);
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Completed Exam"),backgroundColor: const Color(0xFF354F52), foregroundColor: Colors.white),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : rigesterData == null || examData == null
              ? const Center(child: Text("Failed to load data"))
              : Scrollbar(
                child: SingleChildScrollView(
                  child: Column(
                      children: [
                        examDisplay(),
                      ],
                    ),
                ),
              ),
    );
  }
}
