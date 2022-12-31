import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:googleapis/calendar/v3.dart' as googleAPI;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    //clientId: 'OAuth Client ID',
    scopes: <String>[
      googleAPI.CalendarApi.calendarScope,
    ],
  );

  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    print("#############################################initstate");
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        //getGoogleEventsData();
      }
    });
    _googleSignIn.signInSilently();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder(
          future: getGoogleEventsData(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            print("#############################################builder");
            return Container(
                child: Stack(
              children: [
                Container(
                  child: SfCalendar(
                    view: CalendarView.month,
                    dataSource: GoogleDataSource(events: snapshot.data),
                    monthViewSettings: MonthViewSettings(
                        appointmentDisplayMode:
                            MonthAppointmentDisplayMode.appointment),
                  ),
                ),
                snapshot.data != null
                    ? Container()
                    : Center(
                        child: CircularProgressIndicator(),
                      )
              ],
            ));
          },
        ),
      ),
    );
  }

  Future<List<googleAPI.Event>> getGoogleEventsData() async {
    print("#############################################getgoogleeventdata");
    //Googleサインイン1人目処理→同じような処理をすると2人目が出来そう
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if(googleUser == null) {
      print("#############################################googleUser_null");
    }else{
      print("#############################################googleUser_notnull"+ googleUser.email);
    }
    final GoogleAPIClient httpClient =
        GoogleAPIClient(await googleUser!.authHeaders);
    if(httpClient == null) {
      print("#############################################httpClient_null");
    }else{
      print("#############################################httpClient_notnull"+ httpClient.toString());
    }
    final googleAPI.CalendarApi calendarAPI = googleAPI.CalendarApi(httpClient);
    if(calendarAPI == null) {
      print("#############################################calendarAPI_null");
    }else{
      print("#############################################calendarAPI_notnull"+ calendarAPI.calendarList.toString());
    }
    final googleAPI.Events calEvents = await calendarAPI.events.list(
      "primary",
    );
    if(calEvents == null) {
      print("#############################################calEvents_null");
    }else{
      print("#############################################calEvents_notnull"+ calEvents.toString());
    }
    if(calEvents.items == null) {
      print("#############################################calEvents.items_null");
    }else{
      print("#############################################calEvents.items_notnull"+ calEvents.items.toString());
    }
    final List<googleAPI.Event> appointments = <googleAPI.Event>[];
    if(appointments == null) {
      print("#############################################appointments_null");
    }
    if (calEvents != null && calEvents.items != null) {
      print("#############################################get_if");
      for (int i = 0; i < calEvents.items!.length; i++) {
        final googleAPI.Event event = calEvents.items![i];
        if (event.start == null) {
          continue;
        }
        appointments.add(event);
      }
    }
    return appointments;
  }
}

class GoogleDataSource extends CalendarDataSource {
  GoogleDataSource({required List<googleAPI.Event> events}) {
    this.appointments = events;
  }

  @override
  DateTime getStartTime(int index) {
    final googleAPI.Event event = appointments![index];
    return event.start!.date ?? event.start!.dateTime!.toLocal();
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].start.date != null;
  }

  @override
  DateTime getEndTime(int index) {
    final googleAPI.Event event = appointments![index];
    return event.endTimeUnspecified != event.endTimeUnspecified
        ? (event.start!.date ?? event.start!.dateTime!.toLocal())
        : (event.end!.date != null
            ? event.end!.date!.add(Duration(days: -1))
            : event.end!.dateTime!.toLocal());
  }

  @override
  String getLocation(int index) {
    return appointments![index].location;
  }

  @override
  String getNotes(int index) {
    return appointments![index].description;
  }

  @override
  String getSubject(int index) {
    final googleAPI.Event event = appointments![index];
    return event.summary == null || event.summary!.isEmpty
        ? 'No Title'
        : event.summary!;
  }
}

class GoogleAPIClient extends IOClient {
  Map<String, String> _headers;

  GoogleAPIClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(BaseRequest request) =>
      super.send(request..headers.addAll(_headers));

  @override
  Future<Response> head(Uri url, {Map<String, String>? headers}) =>
      super.head(url, headers: headers!..addAll(_headers));
}
