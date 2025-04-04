import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'GradeEvalutation.dart';
import 'completedExam.dart';


class FirestoreServices{
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchexamId(String examId) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Exams')
          .doc(examId)
          .get();

      if (documentSnapshot.exists) {
        return documentSnapshot.data() as Map<String, dynamic>;
      } 
      return {};
    } catch (e) {
      print("Error fetching exam: $e");
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetcheQuestions(String examId) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('Questions')
          .where('examID', isEqualTo: examId) 
          .get();

      List<Map<String, dynamic>> questions = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>; 
        data['id'] = doc.id;
        return data;
      }).toList();

      return questions;
    } catch (e) {
      print("Error fetching questions: $e");
      return [];
    }
  }
}

// ============================================================================================================
// Tabs Page (Details, Not Graded, Graded)
// ============================================================================================================
class examDetails extends StatefulWidget {
  final String examId;
  const examDetails({super.key, required this.examId});

  @override
  State<examDetails> createState() => _examDetailsState();
}

class _examDetailsState extends State<examDetails> {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0, // Open 'Details' from the start 
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Exam Details",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF354F52),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Container(
              color: Colors.white,
              child: const TabBar(
                indicator: BoxDecoration(
                  color: Colors.grey, 
                ),
                labelColor: Colors.black, 
                unselectedLabelColor: Colors.grey, 
                indicatorSize: TabBarIndicatorSize.tab, 
                tabs: [
                  Tab(text: 'Details'),
                  Tab(text: 'Not Graded'),
                  Tab(text: 'Graded'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            ExamDetailPage(examId: widget.examId),
            NotGradedPage(examId: widget.examId),
            GradedPage(examId: widget.examId),
          ],
        ),
      ),
    );
  }
}

// ============================================================================================================
// Tab 1 - Exam Details Page
// ============================================================================================================
class ExamDetailPage extends StatefulWidget {
  final String examId;
  const ExamDetailPage({super.key, required this.examId});

  @override
  _ExamDetailPageState createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  late Future<Map<String, dynamic>> examFuture;
  late Future<List<Map<String, dynamic>>> questionsFuture;

  @override
  void initState() {
    super.initState();
    examFuture = FirestoreServices().fetchexamId(widget.examId);
    questionsFuture = FirestoreServices().fetcheQuestions(widget.examId);
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${_twoDigitFormat(dateTime.day)}-${_twoDigitFormat(dateTime.month)}-${dateTime.year} ${
      _twoDigitFormat(dateTime.hour)}:${_twoDigitFormat(dateTime.minute)}:${_twoDigitFormat(dateTime.second)}';
  }
  String _twoDigitFormat(int value) {
    return value.toString().padLeft(2, '0');
  }

  Widget questionCard(BuildContext context, Map<String, dynamic> questionData) {
    final String questionText = questionData['question'] ?? '';
    final String type = questionData['type'] ?? '';
    final num score = questionData['score'] ?? 0;
    final String correctAnswer = questionData['correctAnswer'] ?? '';
    final List options = questionData['options'] ?? [];
    final String attachment = questionData['attachment'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question & Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Q: $questionText",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color.fromARGB(255, 238, 238, 238),
                ),
                child: Text(
                  "$score",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Display attachment if it exists
          if (attachment.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Image(
                image: AssetImage("$attachment"), 
                width: double.infinity, 
                height: 200, 
              ),
            ),
          const SizedBox(height: 10),

          // MCQ, True/False
          if (type == 'mcq' || type == 'tf')
            Column(
              children: List.generate(
                options.length,
                (index) {
                  String optionValue = options[index];
                  bool isCorrect = optionValue == correctAnswer;

                  return Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(optionValue),
                          value: optionValue,
                          groupValue: optionValue == correctAnswer ? optionValue : null, 
                          onChanged: null, 
                          dense: true,
                        ),
                      ),
                      if (isCorrect)
                        const Text(
                          "Correct Option",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  );
                },
              ),
            ),

          // Short Answer, Essay Answer 
          if (type == 'short' || type == 'essay')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                TextField(
                  controller: TextEditingController(
                    text: 'Answer is corrected manually by the teacher.',
                  ),
                  readOnly: true,
                  maxLines: type == 'essay' ? 4 : 1,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color.fromARGB(255, 248, 248, 248),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: examFuture,
      builder: (context, examSnapshot) {
        if (examSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (examSnapshot.hasError) {
          return Center(child: Text('Error: ${examSnapshot.error}'));
        } else if (!examSnapshot.hasData || examSnapshot.data == null) {
          return const Center(child: Text('No data found.'));
        }
        Map<String, dynamic> exam = examSnapshot.data!;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: questionsFuture,
          builder: (context, questionSnapshot) {
            if (questionSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (questionSnapshot.hasError) {
              return Center(child: Text('Error: ${questionSnapshot.error}'));
            } else if (!questionSnapshot.hasData || questionSnapshot.data!.isEmpty) {
              return const Center(child: Text('No questions found.'));
            }
            List<Map<String, dynamic>> questions = questionSnapshot.data!;

            return Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    //////////////Exam Information Section//////////////
                    Card(
                      margin: const EdgeInsets.all(16.0),
                      elevation: 5,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Title: ${exam['title'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color.fromARGB(255, 238, 238, 238),
                                  ),
                                  child: Text(
                                    'Total Score: ${exam['totalScore'] ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Description: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey[700],
                              ),
                            ),
                            Text(
                              exam['description'] ?? '',
                              style: const TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Start Time: ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                                Text(
                                  _formatTimestamp(exam['startTime']),
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'End Time: ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                                Text(
                                  _formatTimestamp(exam['endTime']),
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Duration: ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                                Text(
                                  '${exam['duration'] ?? ''} minutes',
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Allowed Attempts: ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                                Text(
                                  '${exam['attempts'] ?? ''}',
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Randomize: ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                                Text(
                                  exam['isRandom'] == true ? 'Yes' : 'No',
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Questions Number: ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                                Text(
                                  '${(exam['questionList'] ?? []).length}',
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    //////////////Questions Section//////////////
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        return questionCard(context, questions[index]);
                      },
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}


// ============================================================================================================
// Tab 2 - Not Graded Page
// ============================================================================================================
class NotGradedPage extends StatelessWidget {
  final String examId;
  const NotGradedPage({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    return SubmissionListPage(
      examId: examId,
      isGraded: false, // Not graded submissions
    );
  }
}

// ============================================================================================================
// Tab 3 - Graded Page
// ============================================================================================================
class GradedPage extends StatelessWidget {
  final String examId;
  const GradedPage({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    return SubmissionListPage(
      examId: examId,
      isGraded: true, // Graded submissions
    );
  }
}

// ============================================================================================================
// Displaying submissions (graded or not)
// ============================================================================================================
class SubmissionListPage extends StatefulWidget {
  final String examId;
  final bool isGraded; 
  const SubmissionListPage({super.key, required this.examId, required this.isGraded});

  @override
  _SubmissionListPageState createState() => _SubmissionListPageState();
}

class _SubmissionListPageState extends State<SubmissionListPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> submissions = [];
  DateTime? examEndTime; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSubmissions();
  }

  Future<void> fetchSubmissions() async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('Registered')
          .where('examID', isEqualTo: widget.examId)
          .where('isGraded', isEqualTo: widget.isGraded)
          .where('attemptStatus', isEqualTo: 'completed')
          .get();

      List<Map<String, dynamic>> fetchedSubmissions = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        submissions = fetchedSubmissions;
      });

      await fetchUserNamesFromSubmissions();
      isLoading = false;

    } catch (e) {
      print("Error fetching submissions: $e");
    } 
  }

  /// Fetch all names from userID
  Future<void> fetchUserNamesFromSubmissions() async {
    for (var submission in submissions) {
      String userID = submission['userID'];
      String? userName = await fetchUserName(userID);
      submission['userName'] = userName ?? ''; // Add name to submission
    }
    setState(() {}); 
  }

  /// Fetch one user name from Users collection
  Future<String?> fetchUserName(String userID) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('Users').doc(userID).get();
      if (userDoc.exists) {
        return userDoc['name'] as String?;
      }
    } catch (e) {
      print("Error fetching user name: $e");
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) 
          : submissions.isEmpty 
              ? const Center(child: Text("No submissions found."))
              : ListView.builder(
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final submission = submissions[index];
                    final String studentName = submission['userName'] ?? '';
                    final Timestamp? endTimeStamp = submission['endTime'];
                    final String endTime = endTimeStamp != null
                        ? "${endTimeStamp.toDate().day}-${endTimeStamp.toDate().month}-${endTimeStamp.toDate().year} ${
                          endTimeStamp.toDate().hour}:${endTimeStamp.toDate().minute}:${endTimeStamp.toDate().second}"
                        : "";

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: ListTile(
                          title: Text(
                            "Student: $studentName",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Submit in: $endTime"),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward, color: Color(0xFF354F52)),
                            onPressed: () {
                              // Check if the submission is graded
                              if (widget.isGraded) {
                                // Navigate to CompletedExam for graded submissions
                                Navigator.push(context, MaterialPageRoute(
                                  //CompletedExam(rigesterRow: registerRow!)
                                    builder: (context) => CompletedExam(rigesterRow: submission),
                                  ),
                                );
                              } else {
                                // Navigate to HomePage (feedback Page) for ungraded submissions
                                Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => EvalutationPage(registeredID: submission['id']),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
