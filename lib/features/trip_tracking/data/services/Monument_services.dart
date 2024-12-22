import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/monument.dart';

class MonumentService {
  static const String _url = 'https://temp-backend-mob.onrender.com/monument';
  static const String _monumentKey = 'monuments';

  /// Fetch monuments from the API or local storage
  static Future<List<Monument>> fetchMonuments() async {
    print('🛠️ Initializing SharedPreferences...');
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // First check if we have local data
    final storedData = prefs.getString(_monumentKey);
    if (storedData != null) {
      print('📦 Found local data. Using cached monuments...');
      final List<dynamic> data = json.decode(storedData);
      return data.map((item) {
        return Monument(
          id: item['_id'] as String,
          name: item['name'] as String,
          position: LatLng(
            item['lat'] as double,
            item['long'] as double,
          ),
          radius: 50.0,
          description: null,
        );
      }).toList();
    }

    // If no local data, fetch from API
    try {
      print('🌐 Sending GET request to $_url...');
      final response = await http.get(Uri.parse(_url));
      print('📥 Response received with status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Successfully fetched data from the API!');
        final List<dynamic> data = json.decode(response.body);
        // print('📊 Decoded API response: $data');

        print('💾 Saving fetched data to local storage...');
        await prefs.setString(_monumentKey, json.encode(data));
        print('✔️ Data saved locally under key: $_monumentKey');

        print('🔄 Converting API data to Monument objects...');
        return data.map((item) {
          return Monument(
            id: item['_id'] as String,
            name: item['name'] as String,
            position: LatLng(
              item['lat'] as double,
              item['long'] as double,
            ),
            radius:
                50.0, // Use a default radius since the backend doesn't provide one
            description: null, // Optional field not provided by the backend
          );
        }).toList();
      } else {
        print('❌ Failed to fetch monuments from the API.');
        throw Exception('Failed to fetch monuments');
      }
    } catch (e) {
      print('⚠️ Error occurred during API call: $e');

      print('📂 Attempting to load monuments from local storage...');
      final storedData = prefs.getString(_monumentKey);
      if (storedData != null) {
        print('📦 Found local data. Decoding...');
        final List<dynamic> data = json.decode(storedData);
        print('📊 Decoded local data: $data');

        print('🔄 Converting local data to Monument objects...');
        return data.map((item) {
          return Monument(
            id: item['_id'] as String,
            name: item['name'] as String,
            position: LatLng(
              item['lat'] as double,
              item['long'] as double,
            ),
            radius: 50.0, // Use a default radius for local data as well
            description: null, // Optional field
          );
        }).toList();
      }

      print('❌ No local data found. Throwing exception...');
      throw Exception('Failed to fetch monuments and no local data found');
    }
  }

  static Future<Monument?> findNearestMonument(LatLng currentLocation) async {
    try {
      final monuments = await fetchMonuments();
      if (monuments.isEmpty) return null;

      Monument nearestMonument = monuments.first;
      double shortestDistance = _calculateDistance(
        currentLocation,
        nearestMonument.position,
      );

      for (var monument in monuments) {
        double distance =
            _calculateDistance(currentLocation, monument.position);
        if (distance < shortestDistance) {
          shortestDistance = distance;
          nearestMonument = monument;
        }
      }

      // Only return the monument if we're within its radius
      if (shortestDistance <= nearestMonument.radius) {
        return nearestMonument;
      }
      return nearestMonument;
      //return null;
    } catch (e) {
      print('Error finding nearest monument: $e');
      return null;
    }
  }

  static double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }
}
