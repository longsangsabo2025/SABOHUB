import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to geocode addresses to coordinates using Nominatim (free, no API key).
/// Works on all platforms including web.
class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _userAgent = 'SABOHUB-App/1.1';

  /// Geocode from structured address fields.
  /// Returns (lat, lng) or null if not found.
  static Future<({double lat, double lng})?> geocodeFromFields({
    String? streetNumber,
    String? street,
    String? ward,
    String? district,
    String? city,
  }) async {
    final fullAddress = _buildAddress(
      streetNumber: streetNumber,
      street: street,
      ward: ward,
      district: district,
      city: city,
    );

    if (fullAddress.isEmpty) return null;

    // Try full address first
    var result = await _geocode(fullAddress);
    if (result != null) return result;

    // Fallback: district + city only
    final simpleAddress = _buildAddress(district: district, city: city);
    if (simpleAddress.isNotEmpty && simpleAddress != fullAddress) {
      result = await _geocode(simpleAddress);
    }

    return result;
  }

  /// Build a geocodable address string from structured fields
  static String _buildAddress({
    String? streetNumber,
    String? street,
    String? ward,
    String? district,
    String? city,
  }) {
    final parts = <String>[];

    if (streetNumber != null && streetNumber.trim().isNotEmpty) {
      parts.add(streetNumber.trim());
    }
    if (street != null && street.trim().isNotEmpty) {
      parts.add(street.trim());
    }

    if (ward != null && ward.trim().isNotEmpty) {
      final w = ward.trim();
      if (int.tryParse(w) != null) {
        parts.add('Phường $w');
      } else if (!w.startsWith('Phường') && !w.startsWith('Xã') && !w.startsWith('Thị trấn')) {
        parts.add('Phường $w');
      } else {
        parts.add(w);
      }
    }

    if (district != null && district.trim().isNotEmpty) {
      final d = district.trim();
      if (int.tryParse(d) != null) {
        parts.add('Quận $d');
      } else if (!d.startsWith('Quận') && !d.startsWith('Huyện') && !d.startsWith('Thành phố') && !d.startsWith('Thị xã')) {
        // Could be Gò Vấp, Tân Bình, etc.
        parts.add(d);
      } else {
        parts.add(d);
      }
    }

    if (city != null && city.trim().isNotEmpty) {
      final c = city.trim();
      if (!c.startsWith('Thành phố') && !c.startsWith('Tỉnh')) {
        parts.add('Thành phố $c');
      } else {
        parts.add(c);
      }
    } else {
      parts.add('Thành phố Hồ Chí Minh');
    }

    parts.add('Vietnam');
    return parts.join(', ');
  }

  /// Call Nominatim API to geocode an address
  static Future<({double lat, double lng})?> _geocode(String address) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': address,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'vn',
      });

      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'].toString());
          final lng = double.tryParse(data[0]['lon'].toString());

          if (lat != null && lng != null) {
            // Validate coordinates are in Vietnam
            if (lat > 8 && lat < 24 && lng > 102 && lng < 110) {
              return (lat: lat, lng: lng);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('GeocodingService error: $e');
    }
    return null;
  }
}
