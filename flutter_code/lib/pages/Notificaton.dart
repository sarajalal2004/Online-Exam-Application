import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';


class NotificationPage extends StatefulWidget {
  final String userID;
  const NotificationPage({super.key, required this.userID});

  @override
  State<NotificationPage> createState() => NotificationPageState();
}

class NotificationPageState extends State<NotificationPage> {
  Map<String, dynamic>? notifications;

  @override
  void initState() {
    super.initState();

    notifications = {};
    readNotification();

    setState(() {});
  }

  //read from DB
  readNotification() async {
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('Notifications');
    try {
      QuerySnapshot notification = await collectionRef.get();
      for (QueryDocumentSnapshot doc in notification.docs) {
        print("Document ID: ${doc.id}");
        print("Data: ${doc.data()}");

        String? notificationUserID = doc.get('userID');
        if (widget.userID == notificationUserID) {
          notifications![doc.id] = doc.data();
        }
      }

      setState(() {});
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  updateNotification(String notfID) {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection("Notifications").doc(notfID);

    Map<String, dynamic> Item = {
      "dateTime": notifications![notfID]['dateTime'],
      "description": notifications![notfID]['description'],
      "isRead": true,
      "title": notifications![notfID]['title'],
      "userID": notifications![notfID]['userID'],
    };

    readNotification();
    setState(() {});

    docRef.set(Item).whenComplete(() {
      print("Updated!!!!!!!!!!!!!!!!!!!!");
    });
  }

  getColor(bool isRead) {
    if (isRead) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifcation"),backgroundColor: const Color(0xFF354F52), foregroundColor: Colors.white
      ),
      body: Column(
        children: [
          /*Text("${widget.userID}"),
          Text('${notifications}'),*/
           Expanded(
                child: notifications!.isEmpty
                    ? const Center(
                        child: Text('No Notifications yet.',
                            style: TextStyle(
                                color: Color(0xFF354F52), fontSize: 18)))
                    : ListView.builder(
                        itemCount: notifications!.length,
                        itemBuilder: (context, index) {
                          final entry = notifications!.entries.toList()[index];
                          final notificationID =
                              entry.key; // Key of the map entry
                          final value = entry.value; // Value of the map entry
            
                          DateTime dateTime = value['dateTime'].toDate();
            
                          // Extract components
                          int year = dateTime.year;
                          int month = dateTime.month;
                          int day = dateTime.day;
                          int hour = dateTime.hour;
                          int minute = dateTime.minute;
                          int second = dateTime.second;
                          List<String> weekdays = [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday'
                          ];
                          String weekdayName = weekdays[dateTime.weekday - 1];
            
                          return Column(
                            children: [
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(1),
                                width: MediaQuery.of(context).size.width * 0.9,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white),
                                child: ListTile(
                                  leading: Container(
                                    height: 30,
                                    width: 5,
                                    decoration: BoxDecoration(
                                        color: getColor(value['isRead']),
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                  title: Text("${value['title']}"),
                                  subtitle: Text(
                                    "$weekdayName, on $day/$month/$year",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.info,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        showDialog<String>(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              AlertDialog(
                                            title: Text(
                                              "${value['title']}",
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            content: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const SizedBox(height: 10),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      "Description:   ",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Flexible(
                                                        child: Text(
                                                      "${value['description']}",
                                                      softWrap: true,
                                                    )),
                                                  ],
                                                ),
                                                const SizedBox(height: 5),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      "Received on:   ",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                        "$day-$month-$year $hour:$minute:$second")
                                                  ],
                                                )
                                              ],
                                            ),
                                            actions: <Widget>[
                                              if (!value['isRead']) ...[
                                                TextButton(
                                                  style: ButtonStyle(
                                                      backgroundColor:
                                                          const WidgetStatePropertyAll(
                                                              Color(0xFF354F52)),
                                                      shape: WidgetStatePropertyAll(
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8))),
                                                      padding:
                                                          const WidgetStatePropertyAll(
                                                              EdgeInsetsDirectional
                                                                  .only(
                                                                      top: 5,
                                                                      bottom: 5,
                                                                      start: 10,
                                                                      end: 10))),
                                                  onPressed: () {
                                                    updateNotification(
                                                        notificationID);
                                                    Navigator.pop(context, 'Ok');
                                                  },
                                                  child: const Text(
                                                    "Mark As Read",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ] else ...[
                                                TextButton(
                                                  style: ButtonStyle(
                                                      backgroundColor:
                                                          const WidgetStatePropertyAll(
                                                              Color(0xFF354F52)),
                                                      shape: WidgetStatePropertyAll(
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8))),
                                                      padding:
                                                          const WidgetStatePropertyAll(
                                                              EdgeInsetsDirectional
                                                                  .only(
                                                                      top: 5,
                                                                      bottom: 5,
                                                                      start: 10,
                                                                      end: 10))),
                                                  onPressed: () {
                                                    //process here
                                                    Navigator.pop(context, 'Ok');
                                                  },
                                                  child: const Text(
                                                    "Ok",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                              TextButton(
                                                style: ButtonStyle(
                                                    backgroundColor:
                                                        const WidgetStatePropertyAll(
                                                            Color(0xFF354F52)),
                                                    shape: WidgetStatePropertyAll(
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8))),
                                                    padding:
                                                        const WidgetStatePropertyAll(
                                                            EdgeInsetsDirectional
                                                                .only(
                                                                    top: 5,
                                                                    bottom: 5,
                                                                    start: 10,
                                                                    end: 10))),
                                                onPressed: () => Navigator.pop(
                                                    context, 'Cancel'),
                                                child: const Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        })),
          
        ],
      ),
    );
  }
}