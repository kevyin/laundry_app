import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForecastEvent {
  final double cloudScore;
  final double humidityScore;
  final double isgoodScore;

  const ForecastEvent({
    required this.cloudScore,
    required this.humidityScore,
    required this.isgoodScore,
  });

  factory ForecastEvent.fromJson(Map<String, dynamic> json) {
    return ForecastEvent(
        cloudScore: json['main']['humidity'] * 1.0,
        humidityScore: json['clouds']['all'] * 1.0,
        isgoodScore: 0);
  }
}

class ForecastResponse {
  // final int userId;
  // final int id;
  // final String title;
  final int cnt;
  final List<ForecastEvent> events;

  const ForecastResponse({
    // required this.userId,
    // required this.id,
    // required this.title,
    required this.cnt,
    required this.events,
  });

  factory ForecastResponse.fromJson(Map<String, dynamic> json) {
    var events = [for (var e in json['list']) ForecastEvent.fromJson(e)];

    return ForecastResponse(
      // userId: json['userId'] as int,
      // id: json['id'] as int,
      // title: json['title'] as String,
      cnt: json['cnt'] as int,
      events: events,
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
      title: 'Fetch Data Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Fetch Data Example'),
        ),
        body: Center(
          child: FutureBuilder<ForecastResponse>(
            future: futureForecastResponse,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                // return Text(snapshot.data!.cnt.toString());

                // parse the response

                return ListView.builder(
                  itemCount: snapshot.data!.cnt,
                  itemBuilder: (context, index) {
                    final item = HeadingItem(
                        'CloudScore ${snapshot.data!.events[index].cloudScore.toString()}');

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
