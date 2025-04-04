import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'pages/CreateExam.dart';
//import 'pages/examDetails.dart';
import 'ExamDetailsAndViewSubmissions.dart';
import 'GradeEvalutation.dart';
import 'createExam.dart';
import 'Notificaton.dart';

class FirestoreServicesAd {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchAdminDashboard(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('Exams')
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

  Future<int> getNumNotification(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('Notifications')
          .where('userID', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Convert documents to a list of maps
      List<Map<String, dynamic>> notifications = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return notifications.length;
    } catch (e) {
      print("Error fetching notifications: $e");
      return 0;
    }
  }
}

class adminDashboard extends StatefulWidget {
  final String userId;

  const adminDashboard({super.key, required this.userId});
  @override
  State<adminDashboard> createState() => _adminDashboardState();
}

class _adminDashboardState extends State<adminDashboard> {
  List<Map<String, dynamic>> exams = [];
  int notification = 0;
  FirestoreServicesAd firestoreServices = FirestoreServicesAd();

  @override
  void initState() {
    _Refresh();
    // TODO: implement initState
    super.initState();
  }

  Future<void> _Refresh() async {
    List<Map<String, dynamic>> fetchedExams =
        await firestoreServices.fetchAdminDashboard(widget.userId);
    int not = await firestoreServices.getNumNotification(widget.userId);
    setState(() {
      exams = fetchedExams;
      notification = not;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Container(),
          backgroundColor: const Color(0xFF354F52),
          title: const Text(
            "Admin Dashboard",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            Stack(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        print("notification");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NotificationPage(userID: widget.userId),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                    notification != 0
                        ? Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 6,
                              backgroundColor: Colors.red,
                              child: Text(
                                notification.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ],
                ),
              ],
            ),
          ],
        ),
        body: Padding(
            padding: const EdgeInsets.all(5),
            child: ListView.builder(
                itemCount: exams.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> exam = exams[index];
                  String description = exam["description"];
                  String truncatedDescription = description.length > 100
                      ? "${description.substring(0, 100)}..."
                      : description;
                  String examId = exam['id'];
                  Timestamp timestamp = exam['endTime'];
                  DateTime dueDate = timestamp.toDate();
                  return GestureDetector(
                    onTap: () {
                      print("Tapped on: ${exam['title']} with ID: $examId");
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  examDetails(examId: examId)));
                    },
                    child: Column(
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
                          Text(
                            "Title: ${exam['title']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            truncatedDescription,
                            style: const TextStyle(
                                fontSize: 14, color: Color.fromARGB(255, 81, 81, 81)),
                          ),
                          const SizedBox(height: 10),
                          dueDate.isBefore(DateTime.now())
                              ? Row(
                                children: [
                                  Text(
                                      "Current Status:\t",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold),
                                    ),
                                  const Text(
                                      "CLOSED",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                ],
                              )
                              : Text(
                                  "Due Date:\t$dueDate",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                ),
                        ],
                                              ),
                                            ),
                      ],
                    ),
                  );
                })),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF2F3E46),
          onPressed: () {
            print("to create exam");
            //////////////////// to create exam ////////////////////////////////
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CreateExam(userID: widget.userId)));
          },
          label: const Text(
            'Create',
            style: TextStyle(color: Colors.white),
          ),
          icon: const Icon(Icons.add, color: Colors.white, size: 25),
        ));
  }
}
