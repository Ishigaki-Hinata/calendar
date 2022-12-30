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

final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId:
  'OAuth Client ID',
  scopes: <String>[
    googleAPI.CalendarApi.calendarScope,
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

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
            return Container(
                child: Stack(
                  children: [
                    Container(
                      child: SfCalendar(
                        view: CalendarView.month,
                        dataSource: GoogleDataSource(events: snapshot.data),
                        monthViewSettings: MonthViewSettings(
                            appointmentDisplayMode:
                            MonthAppointmentDisplayMode.appointment
                        ),
                      ),
                    ),
                    snapshot.data != null
                        ? Container()
                        : Center(
                      child: CircularProgressIndicator(),
                    )
                  ],
                )
            );
          },
        ),
      ),
    );
  }
}

Future<List<googleAPI.Event>> getGoogleEventsData() async {
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  final GoogleAPIClient httpClient = GoogleAPIClient(await googleUser!.authHeaders);
  final googleAPI.CalendarApi calendarAPI = googleAPI.CalendarApi(httpClient);
  final googleAPI.Events calEvents = await calendarAPI.events.list(
    "primary",
  );
  final List<googleAPI.Event> appointments = <googleAPI.Event>[];
  if (calEvents != null && calEvents.items != null) {
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
        : event.summary;
  }
}

class GoogleAPIClient extends IOClient {
  Map<String, String> _headers;

  GoogleAPIClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(BaseRequest request) =>
      super.send(request..headers.addAll(_headers));

  @override
  Future<Response> head(Uri url, { Map<String, String> ? headers}) =>
      super.head(url, headers: headers!..addAll(_headers));
}
