import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OSMMapScreen extends StatelessWidget {
  const OSMMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ OpenStreetMap')),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(10.8231, 106.6297),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.goship',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: const LatLng(10.8231, 106.6297),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
