import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import "package:collection/collection.dart";
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ForecastEvent {
  final String dateKey;
  final double temp;
  final double cloudScore;
  final double humidityScore;
  final double isgoodScore;
  final bool isDay;
  final int hour;

  const ForecastEvent({
    required this.dateKey,
    required this.temp,
    required this.cloudScore,
    required this.humidityScore,
    required this.isgoodScore,
    required this.isDay,
    required this.hour,
  });

  factory ForecastEvent.fromJson(Map<String, dynamic> json) {
    var cloudScore = json['clouds']['all'] * 1.0;
    var humidityScore = json['main']['humidity'] * 1.0;
    var temp = json['main']['temp'] * 1.0;
    var dt = DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000).toLocal();
    var dateKey = DateFormat('EEEE MMM dd').format(dt);
    int hour = int.parse(DateFormat('H').format(dt));
    bool isDay = hour >= 9 && hour <= 19;
    return ForecastEvent(
        dateKey: dateKey,
        temp: temp,
        cloudScore: cloudScore,
        humidityScore: humidityScore,
        isgoodScore: (humidityScore < 85) & (cloudScore < 10) ? 1 : 0,
        isDay: isDay,
        hour: hour);
  }
}

class ForecastEventSummary {
  final bool isNotEmpty;
  final String dateKey;
  final double temp;
  final double cloudScore;
  final double humidityScore;
  final double isgoodScore;

  const ForecastEventSummary({
    required this.isNotEmpty,
    required this.dateKey,
    required this.temp,
    required this.cloudScore,
    required this.humidityScore,
    required this.isgoodScore,
  });

  factory ForecastEventSummary.fromEvents(
      String dateKey, List<ForecastEvent> events) {
    var dayEvents = events.where((e) => e.isDay);
    var isNotEmpty = dayEvents.isNotEmpty;
    return ForecastEventSummary(
      isNotEmpty: isNotEmpty,
      dateKey: dateKey,
      temp: isNotEmpty
          ? events.where((e) => e.isDay).map((e) => e.temp).average
          : 0,
      cloudScore: isNotEmpty
          ? events.where((e) => e.isDay).map((e) => e.cloudScore).average
          : 0,
      humidityScore: isNotEmpty
          ? events.where((e) => e.isDay).map((e) => e.humidityScore).average
          : 0,
      isgoodScore: isNotEmpty
          ? events.where((e) => e.isDay).map((e) => e.isgoodScore).average * 100
          : 0,
    );
  }
}

class ForecastResponse {
  final int cnt;
  final List<ForecastEvent> events;
  final List<ForecastEventSummary> summaries;

  const ForecastResponse({
    required this.cnt,
    required this.events,
    required this.summaries,
  });

  factory ForecastResponse.fromJson(Map<String, dynamic> json) {
    var events = [for (var e in json['list']) ForecastEvent.fromJson(e)];
    var summaries = groupBy(events, (ForecastEvent p0) => p0.dateKey)
        .map((dk, es) => MapEntry(dk, ForecastEventSummary.fromEvents(dk, es)));

    return ForecastResponse(
      // userId: json['userId'] as int,
      // id: json['id'] as int,
      // title: json['title'] as String,
      cnt: json['cnt'] as int,
      events: events,
      summaries: summaries.values.toList().where((e) => e.isNotEmpty).toList(),
    );
  }
}

Future<ForecastResponse> fetchForecastResponse() async {
  final response = await http.get(Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?lat=-34.0192056&lon=151.0658292&appid=4fbe2c3c02d76185e9ebb7e2c24b54d0&units=metric'));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return ForecastResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load Forecast response');
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<ForecastResponse> futureForecastResponse;

  @override
  void initState() {
    super.initState();
    futureForecastResponse = fetchForecastResponse();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laundry Days',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Laundry Days'),
        ),
        body: Center(
          child: FutureBuilder<ForecastResponse>(
            future: futureForecastResponse,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                // return Text(snapshot.data!.cnt.toString());

                // parse the response

                return ListView.builder(
                  itemCount: snapshot.data!.summaries.length,
                  // itemCount: snapshot.data!.cnt,
                  itemBuilder: (context, index) {
                    // final item = HeadingItem(
                    //     // '${snapshot.data!.events[index].dateKey} ${snapshot.data!.events[index].cloudScore.toString()} ${snapshot.data!.events[index].isgoodScore.toString()}');
                    //     '${snapshot.data!.summaries[index].dateKey.split(' ')[0]} ${snapshot.data!.summaries[index].cloudScore.toInt().toString()} ${snapshot.data!.summaries[index].humidityScore.toInt().toString()} ${snapshot.data!.summaries[index].isgoodScore.toInt().toString()}');
                    final item = ForecastEventSummaryItem(
                        snapshot.data!.summaries[index]);

                    return ListTile(
                      title: item.buildTitle(context),
                      subtitle: item.buildSubtitle(context),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}

// void main() {
//   runApp(
//     MyApp(
//       items: List<ListItem>.generate(
//         1000,
//         (i) => i % 6 == 0
//             ? HeadingItem('Heading $i')
//             : MessageItem('Sender $i', 'Message body $i'),
//       ),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   final List<ListItem> items;

//   const MyApp({super.key, required this.items});

//   @override
//   Widget build(BuildContext context) {
//     const title = 'Laundry Days';

//     return MaterialApp(
//       title: title,
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text(title),
//         ),
//         body: ListView.builder(
//           // Let the ListView know how many items it needs to build.
//           itemCount: items.length,
//           // Provide a builder function. This is where the magic happens.
//           // Convert each item into a widget based on the type of item it is.
//           itemBuilder: (context, index) {
//             final item = items[index];

//             return ListTile(
//               title: item.buildTitle(context),
//               subtitle: item.buildSubtitle(context),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

/// The base class for the different types of items the list can contain.
abstract class ListItem {
  /// The title line to show in a list item.
  Widget buildTitle(BuildContext context);

  /// The subtitle line, if any, to show in a list item.
  Widget buildSubtitle(BuildContext context);
}

class ForecastEventSummaryItem implements ListItem {
  final ForecastEventSummary summary;

  ForecastEventSummaryItem(this.summary);

  @override
  Widget buildTitle(BuildContext context) {
    return Container(
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            Container(
              width: 145,
              padding: const EdgeInsets.all(8.0),
              color: summary.isgoodScore < 50
                  ? Colors.blue[300]
                  : Colors.blue[600],
              alignment: Alignment.center,
              transform: Matrix4.rotationZ(summary.isgoodScore < 50 ? 0.1 : 0),
              child: Text(summary.dateKey.split(' ')[0],
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(color: Colors.white)),
            ),
            Container(
              width: 55,
              alignment: Alignment.center,
              color: Colors.yellow,
              child: Text(
                summary.temp.toInt().toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Container(
              width: 55,
              alignment: Alignment.center,
              color: Colors.blueGrey,
              child: Text(
                summary.cloudScore.toInt().toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Container(
              width: 55,
              alignment: Alignment.center,
              color: Colors.blueAccent,
              child: Text(
                summary.humidityScore.toInt().toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Container(
              width: 55,
              alignment: Alignment.center,
              color: Colors.greenAccent,
              child: Text(
                summary.isgoodScore.toInt().toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ));
  }

  @override
  Widget buildSubtitle(BuildContext context) => const SizedBox.shrink();
}

/// A ListItem that contains data to display a heading.
class HeadingItem implements ListItem {
  final String heading;

  HeadingItem(this.heading);

  @override
  Widget buildTitle(BuildContext context) {
    return Text(
      heading,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  @override
  Widget buildSubtitle(BuildContext context) => const SizedBox.shrink();
}

/// A ListItem that contains data to display a message.
class MessageItem implements ListItem {
  final String sender;
  final String body;

  MessageItem(this.sender, this.body);

  @override
  Widget buildTitle(BuildContext context) => Text(sender);

  @override
  Widget buildSubtitle(BuildContext context) => Text(body);
}
