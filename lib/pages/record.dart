import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uaaccesos/classes/colors.dart';

class RecordPage extends StatefulWidget {
  static Route<dynamic> route() => MaterialPageRoute(builder: (context) => RecordPage());

  RecordPage({Key key}) : super(key: key);

  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  CollectionReference _logs = FirebaseFirestore.instance.collection('logs');
  Stream<QuerySnapshot> _query;

  DateTime _selectedDate = DateTime.now();
  int _chipSelected = 0;

  void _allDates(int index) {
    setState(() {
      _chipSelected = index;

      _dateQuery(null, null, true);
    });
  }

  void _todayDate(int index) {
    DateTime now = DateTime.now();

    setState(() {
      _chipSelected = index;

      _dateQuery(DateTime(now.year, now.month, now.day), DateTime(now.year, now.month, now.day + 1));
    });
  }

  Future<void> _selectDate(BuildContext context, int index) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // Refer step 1
      firstDate: DateTime(2000),
      lastDate: DateTime(2021),
      confirmText: 'LIST',
    );
    if (picked != null)
      setState(() {
        _chipSelected = index;
        _selectedDate = picked;

        _dateQuery(picked, DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + 1));
      });
  }

  void _dateQuery(DateTime start, DateTime end, [bool init = false]) {
    _query = !init
        ? _logs.where("date", isGreaterThanOrEqualTo: start).where("date", isLessThan: end).orderBy("date", descending: true).snapshots()
        : _logs.orderBy("date", descending: true).snapshots();
  }

  @override
  void initState() {
    _dateQuery(null, null, true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _chipFilters(),
          _logsList(),
        ],
      ),
    );
  }

  Widget _chipFilters() {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          width: 15,
        ),
        _chipBuilder("All", 0, (bool selected) => _allDates(0)),
        SizedBox(
          width: 15,
        ),
        _chipBuilder("Today", 1, (bool selected) => _todayDate(1)),
        SizedBox(
          width: 15,
        ),
        _chipBuilder("Custom Date", 2, (bool selected) => _selectDate(context, 2)),
      ],
    );
  }

  Widget _chipBuilder(String label, int index, Function callable) {
    return ChoiceChip(
      label: Text(label),
      elevation: 1,
      selected: _chipSelected == index,
      onSelected: callable,
      selectedColor: Colors.white,
    );
  }

  Widget _logsList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _query,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            List<QueryDocumentSnapshot> docs = snapshot.data.docs;
            List<Map<String, dynamic>> registers = docs
                .map(
                  (doc) => {
                    'door': doc['door'],
                    'date': DateFormat.yMMMd().add_Hm().format(doc['date'].toDate()),
                    'id': doc['email'].split("@")[0],
                    'initials': doc['user']['name'][0] + doc['user']['ap_pat'][0],
                  },
                )
                .toList();

            return ListView.separated(
              itemCount: docs.length,
              itemBuilder: (BuildContext context, int index) => _register(registers.elementAt(index)),
              separatorBuilder: (BuildContext context, int index) {
                return Container(
                  color: Colors.blueAccent.withOpacity(0.15),
                  height: 3.0,
                );
              },
            );
          }

          return CircularProgressIndicator();
        },
      ),
    );
  }

  Widget _register(Map<String, dynamic> register) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          register['initials'],
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: ColorPalette.secondary,
      ),
      title: Text(
        register['id'],
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18.0,
        ),
      ),
      subtitle: Text(
        register['date'],
        style: TextStyle(
          fontSize: 16.0,
          color: Colors.white54,
        ),
      ),
      trailing: Container(
        decoration: BoxDecoration(color: ColorPalette.accent.withOpacity(0.3), borderRadius: BorderRadius.circular(5.0)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RichText(
            text: TextSpan(
              children: [
                WidgetSpan(
                    child: Icon(
                  Icons.sensor_door_sharp,
                  size: 18,
                  color: Colors.white70,
                )),
                TextSpan(text: register['door'], style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 16.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
