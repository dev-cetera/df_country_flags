//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:df_log/df_log.dart';

import 'country_code.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@visibleForTesting
class CountryFlagBuilder extends StatelessWidget {
  //
  //
  //

  final String? cacheKey;
  final CountryCode countryCode;
  final double? width;
  final double? height;
  final Widget Function(BuildContext context, Uint8List byteData) builder;
  final Widget Function(BuildContext context, String assetPath)? fallbackBuilder;

  // In-memory cache for flag data
  static final Map<String, Uint8List> _memoryCache = {};

  //
  //
  //

  const CountryFlagBuilder({
    super.key,
    this.cacheKey = 'df_country_flags',
    this.width,
    this.height,
    required this.countryCode,
    required this.builder,
    this.fallbackBuilder,
  });

  //
  //
  //

  Future<Uint8List?> _loadSvg(BuildContext context, String? cacheKey) async {
    final assetPath = countryCode.assetPath;
    final k = cacheKey != null ? '${cacheKey}_${countryCode.name.toLowerCase()}' : null;

    if (k != null) {
      // Check in-memory cache first.
      if (_memoryCache.containsKey(k)) {
        return _memoryCache[k]!;
      }

      // Fall back to SharedPreferences.
      try {
        final p = await SharedPreferences.getInstance();
        final base64String = p.getString(k);
        if (base64String != null) {
          final byteData = base64Decode(base64String);
          _memoryCache[k] = byteData;
          return byteData;
        }
      } catch (e) {
        Glog.err(e);
      }
    }

    // Load from assets if not in cache.
    try {
      final byteData = await rootBundle.loadStructuredBinaryData(
        assetPath,
        (e) => e.buffer.asUint8List(),
      );
      if (k != null) {
        try {
          // Store in memory cache.
          _memoryCache[k] = byteData;
          final base64String = base64Encode(byteData);
          final p = await SharedPreferences.getInstance();
          // Store in SharedPreferences.
          await p.setString(k, base64String);
        } catch (e) {
          Glog.err(e);
        }
      }
      return byteData;
    } catch (_) {
      Glog.err('Error loading asset: $assetPath. Falling back to dummy asset.');
      try {
        final fallbackBytes = await rootBundle.loadStructuredBinaryData(
          CountryCode.DUMMY.assetPath,
          (e) => e.buffer.asUint8List(),
        );
        return fallbackBytes;
      } catch (_) {
        Glog.err('Error loading dummy asset. Falling back to null.');
        return null;
      }
    }
  }

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadSvg(context, cacheKey),
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          return builder(context, snapshot.data!);
        }
        return fallbackBuilder != null
            ? fallbackBuilder!(context, countryCode.assetPath)
            : const SizedBox.shrink();
      },
    );
  }
}
