import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // GeoProvider의 fetchGeoData 호출
      Provider.of<GeoProvider>(context, listen: false).fetchGeoData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final geoProvider = Provider.of<GeoProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text("Home"), actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.person, semanticLabel: 'profile'),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
      ]),
      body: Column(
        children: [
          Column(
            children: [
              if (geoProvider.errorMessage != null)
                Text(
                  geoProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              if (geoProvider.latitude != null && geoProvider.longitude != null)
                Column(
                  children: [
                    Text('위도: ${geoProvider.latitude}'),
                    Text('경도: ${geoProvider.longitude}'),
                  ],
                )
              else
                const CircularProgressIndicator(),
              Text("어떤 팟빵에 드갈래"),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/result',
                        arguments: 0,
                      );
                    },
                    child: const Text('배달팟빵'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/result',
                        arguments: 1,
                      );
                    },
                    child: const Text('택시팟빵'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/result',
                        arguments: 2,
                      );
                    },
                    child: const Text('공구팟빵'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/result',
                        arguments: 3,
                      );
                    },
                    child: const Text('기타팟빵'),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
