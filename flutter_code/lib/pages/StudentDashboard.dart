import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'completedExam.dart';
import 'examPage.dart';

class FirestoreServicesSt {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ////////////////////////////////////// to fetch all exams //////////////////////////////////////////////////
  Future<List<Map<String, dynamic>>> fetchAll() async {
    try {
      QuerySnapshot querySnapshot = await _db.collection('Exams').get();

      List<Map<String, dynamic>> exams = querySnapshot.docs.map((doc) {
        // Get the data as a Map
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Add the document id to the map
        data['id'] = doc.id; // Add the document id

        return data;
      }).toList();
      return exams;
    } catch (e) {
      print("Error fetching exams: $e");
      return [];
    }
  }

  ////////////////////////////////////// to fetch all exams with status //////////////////////////////////////////////////
  Future<List<Map<String, dynamic>>> fetchRegistered(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('Registered')
          .where('userID', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> exams = querySnapshot.docs.map((doc) {
        // Get the data as a Map
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Add the document id to the map
        data['id'] = doc.id; // Add the document id

        return data;
      }).toList();
      return exams;
    } catch (e) {
      print("Error fetching exams: $e");
      return [];
    }
  }

  ////////////////////////////// to fetch all exams with status ////////////////////////////////////////
  Future<List<Map<String, dynamic>>> fetchWithStatus(
      String userId, String status) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('Registered')
          .where('userID', isEqualTo: userId)
          .where('attemptStatus', isEqualTo: status)
          .get();

      List<Map<String, dynamic>> exams = querySnapshot.docs.map((doc) {
        // Get the data as a Map
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Add the document id to the map
        data['id'] = doc.id; // Add the document id

        return data;
      }).toList();
      return exams;
    } catch (e) {
      print("Error fetching exams: $e");
      return [];
    }
  }

  ////////////////////////////// to fetch all exams with status ////////////////////////////////////////
  Future<Map<String, dynamic>> fetchexamId(String examId) async {
    try {
      // Get the document by its ID
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Exams')
          .doc(examId)
          .get();

      // Check if the document exists
      if (documentSnapshot.exists) {
        return documentSnapshot.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print("Error fetching exam: $e");
      return {};
    }
  }

////////////////////////////// to fetch all exams with status ////////////////////////////////////////
  Future<String?> fetchId(String userId, String examId) async {
    try {
      // Query the Registered collection for the matching record
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Registered')
          .where('userID', isEqualTo: userId)
          .where('examID', isEqualTo: examId)
          .get();

      // Check if a document was found
      if (querySnapshot.docs.isNotEmpty) {
        // Return the ID of the first document found
        return querySnapshot.docs.first.id;
      } else {
        print("No record found for the given userID and examID.");
        return null;
      }
    } catch (e) {
      print("Error fetching record ID: $e");
      return null;
    }
  }

  //////////////////////////////////////////// add record ///////////////////////////////////////////////////
  Future<Map<String, dynamic>> addOrUpdateRecord(
      String examId, String userId) async {
    try {
      final CollectionReference registeredCollection =
          FirebaseFirestore.instance.collection('Registered');

      // Step 1: Check if a record with the same examId and userId exists
      QuerySnapshot querySnapshot = await registeredCollection
          .where('examID', isEqualTo: examId)
          .where('userID', isEqualTo: userId)
          .get();

      Map<String, dynamic> existingRecord = {};

      if (querySnapshot.docs.isNotEmpty) {
        // Record exists, get its data
        DocumentSnapshot existingDoc = querySnapshot.docs.first;
        existingRecord = existingDoc.data() as Map<String, dynamic>;
        existingRecord['id'] = existingDoc.id; // Include document ID

        // Step 2: Delete the existing record
        await existingDoc.reference.delete();
      }

      // Step 3: Fetch exam data for the new record
      Map<String, dynamic> record = await fetchexamId(examId);

      // Prepare answers map
      Map<String, dynamic> answers = {};
      for (int i = 0; i < record['questionList'].length; i++) {
        answers[record['questionList'][i]] = {
          'answer': '',
          'feedback': '',
          'score': 0,
        };
      }

      // Step 4: Prepare new record data
      Map<String, dynamic> newData = {
        'answers': answers,
        'attemptStatus': 'notStarted',
        'attemptsRemaining': existingRecord.isNotEmpty
            ? existingRecord['attemptsRemaining']
            : record['attempts'],
        'examID': examId,
        'feedback': '',
        'isGraded': false,
        'totalScore': 0,
        'userID': userId,
      };

      // Step 5: Add the new record and get its reference
      DocumentReference newDocRef = await registeredCollection.add(newData);

      // Fetch the complete document record using the document ID
      DocumentSnapshot newDocSnapshot = await newDocRef.get();

      if (newDocSnapshot.exists) {
        // Include the document ID in the returned data
        Map<String, dynamic> newRecord =
            newDocSnapshot.data() as Map<String, dynamic>;
        newRecord['id'] = newDocSnapshot.id; // Add document ID to the record
        return newRecord;
      } else {
        print("New document not found.");
        return {};
      }
    } catch (e) {
      print("Error adding or updating record: $e");
      return {};
    }
  }
}

class studentDashboard extends StatefulWidget {
  final String userId;
  const studentDashboard({super.key, required this.userId});

  @override
  State<studentDashboard> createState() => _studentDashboardState();
}

class _studentDashboardState extends State<studentDashboard> {
  FirestoreServicesSt firestoreServices = FirestoreServicesSt();
  List<Map<String, dynamic>> exams = [];
  List<Map<String, dynamic>> registered = [];

  Future<void> _fetch() async {
    List<Map<String, dynamic>> fetchedExams =
        await firestoreServices.fetchAll();

    List<Map<String, dynamic>> fetchedReg =
        await firestoreServices.fetchRegistered(widget.userId);

    setState(() {
      exams = fetchedExams;
      registered = fetchedReg;
    });
  }

  _showConfirmationAlertCmNotReg(String msg, String examId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Register and $msg"),
            content: const Text("Are you sure you want to Register?"),
            actions: [
              TextButton(
                onPressed: () {
                  _register(examId);
                  Navigator.pop(context, "Yes");
                },
                child: const Text("Yes"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'Cancel'),
                child: const Text("Cancel"),
              ),
            ],
          );
        });
  }

  void _showConfirmationAlertExRg(String msg, Map<String, dynamic> row) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(msg),
          content: Text("Are you sure you want to $msg?"),
          actions: [
            TextButton(
              onPressed: () {
                // First close the dialog, then navigate to the new page
                Navigator.pop(context); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => examPage(registerRow: row),
                  ),
                );
              },
              child: const Text("Yes"),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, 'Cancel'), // Close the dialog
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  _showConfirmationAlertExNewRg(String msg, String examId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(msg),
            content: Text("Are you sure you want to $msg?"),
            actions: [
              TextButton(
                onPressed: () {
                  _register(examId);
                  Navigator.pop(context, "Yes");
                },
                child: const Text("Yes"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'Cancel'),
                child: const Text("Cancel"),
              ),
            ],
          );
        });
  }

  _showConfirmationAlertExNewRgWORoute(String msg, String examId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(msg),
            content: Text("Are you sure you want to $msg?"),
            actions: [
              TextButton(
                onPressed: () {
                  _registerWORoute(examId);
                  Navigator.pop(context, "Yes");
                },
                child: const Text("Yes"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'Cancel'),
                child: const Text("Cancel"),
              ),
            ],
          );
        });
  }

  void _register(examId) async {
    Map<String, dynamic> rec =
        await firestoreServices.addOrUpdateRecord(examId, widget.userId);
    print(rec);
    setState(() {});
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => examPage(registerRow: rec)));
  }

  void _registerWORoute(examId) async {
    Map<String, dynamic> rec =
        await firestoreServices.addOrUpdateRecord(examId, widget.userId);
    print(rec);
    setState(() {
      _fetch();
    });
  }

  Widget _All() {
    return ListView.builder(
        itemCount: exams.length,
        itemBuilder: (context, index) {
          String status = "";
          bool isGraded = false;
          double grade = 0;
          bool reg = false;
          int attempts = 0;
          String? regId;
          Map<String, dynamic>? registerRow;

          for (int i = 0; i < registered.length; i++) {
            if (registered[i]['examID'] != null && exams[index]['id'] != null) {
              if (registered[i]['examID'] == exams[index]['id']) {
                reg = true;
                status = registered[i]['attemptStatus'];
                regId = registered[i]['id'];
                registerRow = registered[i];

                attempts = registered[i]['attemptsRemaining'];
                // Check if the exam is graded
                if (registered[i]['isGraded'] == true) {
                  isGraded = true;
                  grade = registered[i]['totalScore'];
                }
              }
            }
          }

          String description = exams[index]["description"];
          String truncatedDescription = description.length > 100
              ? "${description.substring(0, 100)}..."
              : description;
          String examId = exams[index]['id'];
          Timestamp timestamp = exams[index]['endTime'];
          DateTime EndDate = timestamp.toDate();
          Timestamp timestamp2 = exams[index]['startTime'];
          DateTime StartDate = timestamp2.toDate();
          bool due = EndDate.isBefore(DateTime.now());
          return Column(
            children: [
              const SizedBox(height: 20,),
              Container(
                padding: const EdgeInsets.all(20),
                                                  width: MediaQuery.of(context).size.width*0.85,
                                                  decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white),
                          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      exams[index]['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      width: 100,
                      child: Container(
                          alignment: Alignment.center,
                          width: 50,
                          height: 30,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color.fromARGB(255, 238, 238, 238)),
                          child: isGraded
                              ? Text(
                                  "${grade.toString()}/ ${exams[index]['totalScore'].toString()}")
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.remove,
                                      size: 16,
                                    ), // The icon
                                    Text(
                                        " / ${exams[index]['totalScore'].toString()}"), // The text
                                  ],
                                )),
                    )
                  ],
                ),
                const SizedBox(height: 14),
                //////////////////////// description //////////////////////////////////////////////////
                Text(
                  truncatedDescription,
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
                const SizedBox(height: 14),
              
                due
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Duration:\t\t",
                                style: TextStyle(
                                    fontSize: 13,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${exams[index]['duration']} minutes",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                                children: [
                                  Text(
                                      "Current Status:\t\t",
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold),
                                    ),
                                  const Text(
                                      "CLOSED",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold),
                                    ),
                                ],
                              )
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Time:\t\t$StartDate',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'End Time:\t\t$EndDate',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Attempts:\t\t${exams[index]['attempts']}",
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                "Duration:\t\t",
                                style: TextStyle(
                                    fontSize: 13,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${exams[index]['duration']} minutes",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          reg
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Left Attempts:\t\t$attempts",
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600], fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "Left Attempts:\t\t$attempts",
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600], fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          "Status:\t\t$status",
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600], fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : const Text(""),
                        ],
                      ),
                const SizedBox(height: 13),
              
                Column(
                  children: [
                    due
                        ? reg
                            ? isGraded
                                ? Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          style: ButtonStyle(
                                            backgroundColor:
                                                const WidgetStatePropertyAll(
                                                    Color(0xFF354F52)),
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            padding: const WidgetStatePropertyAll(
                                              EdgeInsetsDirectional.only(
                                                  top: 15,
                                                  bottom: 15,
                                                  start: 40,
                                                  end: 40),
                                            ),
                                          ),
                                          onPressed: () {
                                            // due + reg + graded
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        CompletedExam(
                                                            rigesterRow:
                                                                registerRow!)));
                                          },
                                          child: const Text(
                                              "View Grade and Key Answer",
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                    const Color(0xFF354F52)),
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            padding: WidgetStatePropertyAll(
                                              const EdgeInsetsDirectional.only(
                                                  top: 15,
                                                  bottom: 15,
                                                  start: 40,
                                                  end: 40),
                                            ),
                                          ),
                                          onPressed: () {
                                            // due + reg
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (contex) =>
                                                        CompletedExam(
                                                            rigesterRow:
                                                                registerRow!)));
                                          },
                                          child: const Text("View Key Answer",
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  )
                            : SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                        const Color(0xFF354F52)),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    padding: const WidgetStatePropertyAll(
                                      EdgeInsetsDirectional.only(
                                          top: 15,
                                          bottom: 15,
                                          start: 40,
                                          end: 40),
                                    ),
                                  ),
                                  onPressed: () {
                                    // due + not reg
                                    _showConfirmationAlertCmNotReg(
                                        "View Key Answer", examId);
                                  },
                                  child: const Text("View Key Answer",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              )
                        : reg
                            ? status == 'notStarted'
                                ? SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            StartDate.isAfter(DateTime.now())
                                                ? WidgetStatePropertyAll(
                                                    Colors.grey)
                                                : const WidgetStatePropertyAll(
                                                    Color(0xFF354F52)),
                                        shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        padding: WidgetStatePropertyAll(
                                          const EdgeInsetsDirectional.only(
                                              top: 15,
                                              bottom: 15,
                                              start: 40,
                                              end: 40),
                                        ),
                                      ),
                                      onPressed:
                                          StartDate.isAfter(DateTime.now())
                                              ? null
                                              : () {
                                                  // not due + reg + not started
                                                  _showConfirmationAlertExRg(
                                                      "Start Exam",
                                                      registerRow!);
                                                },
                                      child: const Text("Start Exam",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  )
                                : status == 'inProgress'
                                    ? SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                    const Color(0xFF354F52)),
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            padding: WidgetStatePropertyAll(
                                              const EdgeInsetsDirectional.only(
                                                  top: 15,
                                                  bottom: 15,
                                                  start: 40,
                                                  end: 40),
                                            ),
                                          ),
                                          onPressed: () {
                                            // not due + reg + in progress
                                            _showConfirmationAlertExRg(
                                                "Complete Exam", registerRow!);
                                          },
                                          child: const Text("Complete Exam",
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      )
                                    : status == 'completed'
                                        ? attempts > 0
                                            ? Column(
                                                children: [
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: TextButton(
                                                      style: ButtonStyle(
                                                        backgroundColor:
                                                            WidgetStatePropertyAll(
                                                                const Color(
                                                                    0xFF354F52)),
                                                        shape:
                                                            WidgetStatePropertyAll(
                                                          RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        padding:
                                                            WidgetStatePropertyAll(
                                                          const EdgeInsetsDirectional
                                                              .only(
                                                                  top: 15,
                                                                  bottom: 15,
                                                                  start: 40,
                                                                  end: 40),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        // not due + reg + complete + remaining > 0
                                                        _showConfirmationAlertExNewRg(
                                                            "Start New Attempt",
                                                            examId);
                                                      },
                                                      child: const Text(
                                                          "Start New Attempt",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      height:
                                                          10), // Add spacing between buttons
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: TextButton(
                                                      style: ButtonStyle(
                                                        backgroundColor: !isGraded
                                                            ? const WidgetStatePropertyAll(
                                                                Colors.grey)
                                                            : WidgetStatePropertyAll(
                                                                const Color(
                                                                    0xFF354F52)),
                                                        shape:
                                                            WidgetStatePropertyAll(
                                                          RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        padding:
                                                            WidgetStatePropertyAll(
                                                          const EdgeInsetsDirectional
                                                              .only(
                                                                  top: 15,
                                                                  bottom: 15,
                                                                  start: 40,
                                                                  end: 40),
                                                        ),
                                                      ),
                                                      onPressed: !isGraded
                                                          ? null
                                                          : () {
                                                              // not due + reg + complete to see grade
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) =>
                                                                          CompletedExam(
                                                                              rigesterRow: registerRow!)));
                                                            },
                                                      child: const Text("View Grade",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                  )
                                                ],
                                              )
                                            : SizedBox(
                                                width: double.infinity,
                                                child: TextButton(
                                                  style: ButtonStyle(
                                                    backgroundColor: isGraded
                                                        ? WidgetStatePropertyAll(
                                                            Colors.grey)
                                                        : WidgetStatePropertyAll(
                                                            const Color(0xFF354F52)),
                                                    shape:
                                                        WidgetStatePropertyAll(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    padding:
                                                        WidgetStatePropertyAll(
                                                      const EdgeInsetsDirectional
                                                          .only(
                                                              top: 15,
                                                              bottom: 15,
                                                              start: 40,
                                                              end: 40),
                                                    ),
                                                  ),
                                                  onPressed: isGraded
                                                      ? null
                                                      : () {
                                                          // not due + reg + complete + attempts = 0
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder: (context) =>
                                                                      CompletedExam(
                                                                          rigesterRow:
                                                                              registerRow!)));
                                                        },
                                                  child: const Text("View Grade",
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                ),
                                              )
                                        : const Text("something wrong")
                            : SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                        const Color(0xFF354F52)),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    padding: WidgetStatePropertyAll(
                                      const EdgeInsetsDirectional.only(
                                          top: 15,
                                          bottom: 15,
                                          start: 40,
                                          end: 40),
                                    ),
                                  ),
                                  onPressed: () {
                                    _showConfirmationAlertExNewRgWORoute(
                                        "Register", examId);
                                  },
                                  child: const Text("Register",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              )
                  ],
                ),
              ],
                          ),
                        ),
            ],
          );
        });
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////////
  final List<String> statuses = ["notStarted", "inProgress", "completed"];
  List<bool> isSelected = [true, false, false];
  String status = "notStarted";

  Widget _Registered() {
    return Container(
      padding: const EdgeInsets.all(16), // Added padding for better spacing
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(12),
              borderColor: const Color(0xFF354F52),
              selectedBorderColor: const Color(0xFF354F52),
              selectedColor: Colors.white,
              fillColor: const Color(0xFF354F52),
              isSelected: isSelected,
              onPressed: (index) {
                setState(() {
                  // Update selected state
                  for (int i = 0; i < isSelected.length; i++) {
                    isSelected[i] = i == index;
                  }
                  status = statuses[index];
                });
              },
              children: [
                SizedBox(
                  width: 100,
                  child: Center(child: Text("Not Started")),
                ),
                SizedBox(
                  width: 100,
                  child: Center(child: Text("In Progress")),
                ),
                SizedBox(
                  width: 100,
                  child: Center(child: Text("Completed")),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20), // Add spacing
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: firestoreServices.fetchWithStatus(widget.userId, status),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No exams found."));
                }

                List<Map<String, dynamic>> registeredwithStatus =
                    snapshot.data!;
                return ListView.builder(
                  itemCount: registeredwithStatus.length,
                  itemBuilder: (context, index) {
                    // Extract data from registeredwithStatus
                    String? title;
                    String? description;
                    Timestamp? timestamp;
                    Timestamp? timestamp2;
                    int? duration;
                    bool due;
                    double? totalScore;

                    for (int i = 0; i < exams.length; i++) {
                      if (registeredwithStatus[index]['examID'] ==
                          exams[i]['id']) {
                        title = exams[i]['title'];
                        description = exams[i]['description'];
                        timestamp = exams[i]["endTime"];
                        timestamp2 = exams[i]['startTime'];
                        duration = exams[i]["duration"];
                        totalScore = exams[i]['totalScore'];
                      }
                    }

                    DateTime EndDate = timestamp!.toDate();
                    DateTime StartDate = timestamp2!.toDate();
                    String truncatedDescription = description!.length > 100
                        ? "${description.substring(0, 100)}..."
                        : description;
                    due = EndDate.isBefore(DateTime.now());

                    return Card(
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(title!,
                                    style:
                                        const TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(
                                  width: 100,
                                  child: Container(
                                      alignment: Alignment.center,
                                      width: 50,
                                      height: 30,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: const Color.fromARGB(
                                              255, 238, 238, 238)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 5),
                                      child: registeredwithStatus[index]
                                              ['isGraded']
                                          ? Text(
                                              "${registeredwithStatus[index]['totalScore'].toString()}/ ${totalScore.toString()}")
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.remove,
                                                  size: 16,
                                                ),
                                                Text(
                                                    " / ${totalScore.toString()}"),
                                              ],
                                            )),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(truncatedDescription,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            due
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Duration: $duration minutes",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "CLOSED",
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '''Start Time: $StartDate 
End Time: $EndDate''',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Left Attempts: ${registeredwithStatus[index]['attemptsRemaining']}",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Duration: $duration minutes",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 5),
                            status == 'notStarted'
                                ? due
                                    ? Column(
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: TextButton(
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    const WidgetStatePropertyAll(
                                                        Color(0xFF354F52)),
                                                shape: WidgetStatePropertyAll(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                padding:
                                                    WidgetStatePropertyAll(
                                                  const EdgeInsetsDirectional.only(
                                                      top: 15,
                                                      bottom: 15,
                                                      start: 40,
                                                      end: 40),
                                                ),
                                              ),
                                              onPressed: () {
                                                //CompletedExam(rigesterRow: registerRow!)
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            CompletedExam(
                                                                rigesterRow:
                                                                    registeredwithStatus[
                                                                        index])));
                                              },
                                              child: const Text("View Key Answer",
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: TextButton(
                                              style: ButtonStyle(
                                                backgroundColor: StartDate
                                                        .isAfter(DateTime.now())
                                                    ? WidgetStatePropertyAll(
                                                        Colors.grey)
                                                    : const WidgetStatePropertyAll(
                                                        Color(0xFF354F52)),
                                                shape: WidgetStatePropertyAll(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                padding:
                                                    const WidgetStatePropertyAll(
                                                  EdgeInsetsDirectional.only(
                                                      top: 15,
                                                      bottom: 15,
                                                      start: 40,
                                                      end: 40),
                                                ),
                                              ),
                                              onPressed: StartDate.isAfter(
                                                      DateTime.now())
                                                  ? null
                                                  : () {
                                                      _showConfirmationAlertExRg(
                                                          "Start Exam",
                                                          registeredwithStatus[
                                                              index]);
                                                    },
                                              child: const Text("Start Exam",
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                          ),
                                        ],
                                      )
                                : status == 'inProgress'
                                    ? due
                                        ? Column(
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: TextButton(
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        const WidgetStatePropertyAll(
                                                            Color(0xFF354F52)),
                                                    shape:
                                                        WidgetStatePropertyAll(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    padding:
                                                        WidgetStatePropertyAll(
                                                      const EdgeInsetsDirectional
                                                          .only(
                                                              top: 15,
                                                              bottom: 15,
                                                              start: 40,
                                                              end: 40),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    //CompletedExam(rigesterRow: registerRow!)
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                CompletedExam(
                                                                    rigesterRow:
                                                                        registeredwithStatus[
                                                                            index])));
                                                  },
                                                  child: const Text("View Key Answer",
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: TextButton(
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        WidgetStatePropertyAll(
                                                            const Color(0xFF354F52)),
                                                    shape:
                                                        WidgetStatePropertyAll(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    padding:
                                                        const WidgetStatePropertyAll(
                                                      EdgeInsetsDirectional
                                                          .only(
                                                              top: 15,
                                                              bottom: 15,
                                                              start: 40,
                                                              end: 40),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    _showConfirmationAlertExRg(
                                                        "Complete Exam",
                                                        registeredwithStatus[
                                                            index]);
                                                  },
                                                  child: const Text("Complete Exam",
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                ),
                                              ),
                                            ],
                                          )
                                    : status == 'completed'
                                        ? due
                                            ? Column(
                                                children: [
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: TextButton(
                                                      style: ButtonStyle(
                                                        backgroundColor:
                                                            WidgetStatePropertyAll(
                                                                const Color(
                                                                    0xFF354F52)),
                                                        shape:
                                                            WidgetStatePropertyAll(
                                                          RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        padding:
                                                            const WidgetStatePropertyAll(
                                                          EdgeInsetsDirectional
                                                              .only(
                                                                  top: 15,
                                                                  bottom: 15,
                                                                  start: 40,
                                                                  end: 40),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        //CompletedExam(rigesterRow: registerRow!)
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) =>
                                                                    CompletedExam(
                                                                        rigesterRow:
                                                                            registeredwithStatus[index])));
                                                      },
                                                      child: const Text(
                                                          "View Key Answer",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      height:
                                                          10), // Space between buttons
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: TextButton(
                                                      style: ButtonStyle(
                                                        backgroundColor:
                                                            !registeredwithStatus[
                                                                        index]
                                                                    ['isGraded']
                                                                ? WidgetStatePropertyAll(
                                                                    Colors.grey)
                                                                : WidgetStatePropertyAll(
                                                                    const Color(
                                                                        0xFF354F52)),
                                                        shape:
                                                            WidgetStatePropertyAll(
                                                          RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        padding:
                                                            WidgetStatePropertyAll(
                                                          const EdgeInsetsDirectional
                                                              .only(
                                                                  top: 15,
                                                                  bottom: 15,
                                                                  start: 40,
                                                                  end: 40),
                                                        ),
                                                      ),
                                                      onPressed:
                                                          !registeredwithStatus[
                                                                      index]
                                                                  ['isGraded']
                                                              ? null
                                                              : () {
                                                                  //CompletedExam(rigesterRow: registerRow!)
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              CompletedExam(rigesterRow: registeredwithStatus[index])));
                                                                },
                                                      child: const Text("View Grade",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : registeredwithStatus[index]
                                                        ['attemptsRemaining'] >
                                                    0
                                                ? Column(
                                                    children: [
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: TextButton(
                                                          style: ButtonStyle(
                                                            backgroundColor:
                                                                WidgetStatePropertyAll(
                                                                    const Color(
                                                                        0xFF354F52)),
                                                            shape:
                                                                WidgetStatePropertyAll(
                                                              RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                            ),
                                                            padding:
                                                                WidgetStatePropertyAll(
                                                              const EdgeInsetsDirectional
                                                                  .only(
                                                                      top: 15,
                                                                      bottom:
                                                                          15,
                                                                      start: 40,
                                                                      end: 40),
                                                            ),
                                                          ),
                                                          onPressed: () {
                                                            _showConfirmationAlertExNewRg(
                                                                "Start New Attempt",
                                                                registeredwithStatus[
                                                                        index]
                                                                    ['examID']);
                                                          },
                                                          child: const Text(
                                                              "Start New Attempt",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white)),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height:
                                                              10), // Space between buttons
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: TextButton(
                                                          style: ButtonStyle(
                                                            backgroundColor: !registeredwithStatus[
                                                                        index]
                                                                    ['isGraded']
                                                                ? WidgetStatePropertyAll(
                                                                    Colors.grey)
                                                                : WidgetStatePropertyAll(
                                                                    const Color(
                                                                        0xFF354F52)),
                                                            shape:
                                                                WidgetStatePropertyAll(
                                                              RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                            ),
                                                            padding:
                                                                WidgetStatePropertyAll(
                                                              const EdgeInsetsDirectional
                                                                  .only(
                                                                      top: 15,
                                                                      bottom:
                                                                          15,
                                                                      start: 40,
                                                                      end: 40),
                                                            ),
                                                          ),
                                                          onPressed:
                                                              !registeredwithStatus[
                                                                          index]
                                                                      [
                                                                      'isGraded']
                                                                  ? null
                                                                  : () {
                                                                      //CompletedExam(rigesterRow: registerRow!)
                                                                      Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => CompletedExam(rigesterRow: registeredwithStatus[index])));
                                                                    },
                                                          child: const Text(
                                                              "View Grade",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white)),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Column(
                                                    children: [
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: TextButton(
                                                          style: ButtonStyle(
                                                            backgroundColor: !registeredwithStatus[
                                                                        index]
                                                                    ['isGraded']
                                                                ? const WidgetStatePropertyAll(
                                                                    Colors.grey)
                                                                : WidgetStatePropertyAll(
                                                                    const Color(
                                                                        0xFF354F52)),
                                                            shape:
                                                                WidgetStatePropertyAll(
                                                              RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                            ),
                                                            padding:
                                                                WidgetStatePropertyAll(
                                                              const EdgeInsetsDirectional
                                                                  .only(
                                                                      top: 15,
                                                                      bottom:
                                                                          15,
                                                                      start: 40,
                                                                      end: 40),
                                                            ),
                                                          ),
                                                          onPressed:
                                                              !registeredwithStatus[
                                                                          index]
                                                                      [
                                                                      'isGraded']
                                                                  ? null
                                                                  : () {
                                                                      Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => CompletedExam(rigesterRow: registeredwithStatus[index])));
                                                                    },
                                                          child: const Text(
                                                              "View Grade",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white)),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                        : const Column(
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: Text(
                                                    "Something went wrong"),
                                              ),
                                            ],
                                          )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<bool> view = [true, false];
  int selectedIndex = 0;
  @override
  void initState() {
    // TODO: implement initState
    _fetch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        title: const Text(
          "Student Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF354F52),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10,),
          Container(
            
            margin: const EdgeInsets.only(top: 5),
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(12),
              borderColor: const Color(0xFF354F52),
              selectedBorderColor: const Color(0xFF354F52),
              selectedColor: Colors.white,
              fillColor: const Color(0xFF354F52),
              isSelected: view,
              onPressed: (index) {
                setState(() {
                  selectedIndex = index;
                  for (int i = 0; i < view.length; i++) {
                    view[i] = (i == index);
                  }
                });
              },
              children: [
                SizedBox(
                  width: 100, // Set a fixed width
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    alignment: Alignment.center,
                    child: Text("All"),
                  ),
                ),
                SizedBox(
                  width: 100, // Set the same fixed width
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    alignment: Alignment.center,
                    child: Text("Registered"),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedIndex == 0 ? _All() : _Registered(),
          ),
        ],
      ),
    );
  }
}
