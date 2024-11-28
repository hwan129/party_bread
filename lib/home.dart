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
    return Scaffold(
        appBar: AppBar(
          title: Consumer<GeoProvider>(
            builder: (context, geoProvider, child) {
              return Text(
                geoProvider.address ?? "주소를 가져오는 중...",
                style: const TextStyle(fontSize: 16),
              );
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.person, semanticLabel: 'profile'),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
        body: Consumer<GeoProvider>(builder: (context, geoProvider, child) {
          if (geoProvider.isLoading) {
            // 로딩 중 표시
            return const Center(child: CircularProgressIndicator());
          }
          if (geoProvider.errorMessage != null) {
            // 에러 메시지 표시
            return Center(
              child: Text(
                geoProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (geoProvider.latitude != null && geoProvider.longitude != null) {
            return Column(
              children: [
                Column(
                  children: [
                    if (geoProvider.errorMessage != null)
                      Text(
                        geoProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    if (geoProvider.latitude != null &&
                        geoProvider.longitude != null)
                      Column(
                        children: [
                          Text('위도: ${geoProvider.latitude}'),
                          Text('경도: ${geoProvider.longitude}'),
                          Text('주소: ${geoProvider.address}'),
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
            );
          }
          return const Center(child: Text("데이터를 가져올 수 없습니다."));
        }));
  }
}
