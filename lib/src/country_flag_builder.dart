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
import 'dart:developer';

import 'country_code.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

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

  Future<Uint8List> _loadSvg(BuildContext context, String? cacheKey) async {
    final p = await SharedPreferences.getInstance();
    final assetPath = countryCode.assetPath;
    final k = cacheKey != null ? '${cacheKey}_${countryCode.name}' : null;
    if (k != null) {
      try {
        final base64String = p.getString(k);
        if (base64String != null) {
          final byteData = base64Decode(base64String);
          return byteData;
        } else {
          log('No cache entry for: $assetPath', name: 'df_country_flags');
        }
      } catch (e) {
        log('Error retrieving cache: $e', name: 'df_country_flags');
      }
    }
    try {
      final byteData = await rootBundle.loadStructuredBinaryData(
        assetPath,
        (e) => e.buffer.asUint8List(),
      );
      debugPrint('[df_country_flags] Loaded from assets: $assetPath');
      if (k != null) {
        try {
          final base64String = base64Encode(byteData);
          await p.setString(k, base64String);
        } catch (e) {
          log('Error writing cache: $e', name: 'df_country_flags');
        }
      }
      return byteData;
    } catch (e) {
      log('Error loading asset: $e', name: 'df_country_flags');
      try {
        final fallbackBytes = await rootBundle.loadStructuredBinaryData(
          CountryCode.DUMMY.assetPath,
          (e) => e.buffer.asUint8List(),
        );
        log('Loaded fallback SVG', name: 'df_country_flags');
        return fallbackBytes;
      } catch (fallbackError) {
        log('Error loading fallback SVG: $fallbackError', name: 'df_country_flags');
        rethrow;
      }
    }
  }

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _loadSvg(context, cacheKey),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return builder(context, snapshot.data!);
        }
        return fallbackBuilder != null
            ? fallbackBuilder!(context, countryCode.assetPath)
            : const SizedBox.shrink();
      },
    );
  }
}
