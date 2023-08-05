import 'package:flutter/material.dart';
import 'package:flutter_google_map_themes/GoogleMap/map_screen.dart';
import 'package:provider/provider.dart';

import 'geo_locator.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<GeoLocatorService>(create: (context) => GeoLocatorService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final geoService = Provider.of<GeoLocatorService>(context, listen: false);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spade',

      home: FutureBuilder(
        future: geoService.getInitialLocation(),
        builder: (context, _) => GoogleMapScreen(),
      ),
    );
  }
}
