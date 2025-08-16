import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk_platform_interface/flutter_google_places_sdk_platform_interface.dart';
export 'package:flutter_google_places_sdk_platform_interface/flutter_google_places_sdk_platform_interface.dart';

/// Client used to call methods on the native google places sdk
class FlutterGooglePlacesSdk {
  FlutterGooglePlacesSdk(this._apiKey, {Locale? locale, bool useNewApi = false})
      : this._locale = locale,
        this._useNewApi = useNewApi;

  static const AssetImage ASSET_POWERED_BY_GOOGLE_ON_WHITE =
      FlutterGooglePlacesSdkPlatform.ASSET_POWERED_BY_GOOGLE_ON_WHITE;

  static const AssetImage ASSET_POWERED_BY_GOOGLE_ON_NON_WHITE =
      FlutterGooglePlacesSdkPlatform.ASSET_POWERED_BY_GOOGLE_ON_NON_WHITE;

  static FlutterGooglePlacesSdkPlatform platform =
      FlutterGooglePlacesSdkPlatform.instance;

  String get apiKey => _apiKey;
  String _apiKey;

  Locale? get locale => _locale;
  Locale? _locale;

  bool _useNewApi;

  Future<void>? _lastMethodCall;
  Future<void>? _initialization;

  Future<T> _addMethodCall<T>(Future<T> Function() method) async {
    Future<T> response;
    if (_lastMethodCall == null) {
      response = _callMethod(method);
    } else {
      response = _lastMethodCall!.then((_) {
        return _callMethod(method);
      });
    }
    _lastMethodCall = _waitFor(response);
    return response;
  }

  static Future<void> _waitFor(Future<void> future) {
    final Completer<void> completer = Completer<void>();
    future.whenComplete(completer.complete).catchError((dynamic err) {
      print('FlutterGooglePlacesSdk::call error: $err');
      throw err;
    });
    return completer.future;
  }

  Future<T> _callMethod<T>(Future<T> Function() method) async {
    await _ensureInitialized();
    return await method();
  }

  Future<void> _ensureInitialized() {
    return _initialization ??=
        platform.initialize(apiKey, locale: locale, useNewApi: _useNewApi)
          ..catchError((dynamic err) {
            print('FlutterGooglePlacesSdk::_ensureInitialized error: $err');
            _initialization = null;
          });
  }

  /// Fetches autocomplete predictions based on a query.
  Future<FindAutocompletePredictionsResponse> findAutocompletePredictions(
    String query, {
    List<String>? countries,
    List<PlaceTypeFilter> placeTypesFilter = const [],
    bool? newSessionToken,
    String? sessionToken, // 👈 added
    LatLng? origin,
    LatLngBounds? locationBias,
    LatLngBounds? locationRestriction,
  }) {
    return _addMethodCall(() => platform.findAutocompletePredictions(
          query,
          countries: countries,
          placeTypesFilter:
              placeTypesFilter.map((type) => type.apiExpectedValue).toList(),
          newSessionToken: newSessionToken,
          sessionToken: sessionToken, // 👈 pass through
          origin: origin,
          locationBias: locationBias,
          locationRestriction: locationRestriction,
        ));
  }

  /// Fetches the details of a place.
  Future<FetchPlaceResponse> fetchPlace(
    String placeId, {
    required List<PlaceField> fields,
    String? sessionToken, // 👈 added
  }) {
    return _addMethodCall(() =>
        platform.fetchPlace(placeId, fields: fields, sessionToken: sessionToken));
  }

  /// Fetches a photo of a place.
  Future<FetchPlacePhotoResponse> fetchPlacePhoto(PhotoMetadata photoMetadata,
      {int? maxWidth, int? maxHeight}) {
    return _addMethodCall(() => platform.fetchPlacePhoto(photoMetadata,
        maxWidth: maxWidth, maxHeight: maxHeight));
  }

  Future<bool?> isInitialized() {
    return _addMethodCall(platform.isInitialized);
  }

  Future<void> updateSettings(
      {String? apiKey, Locale? locale, bool? useNewApi}) {
    _apiKey = apiKey ?? this.apiKey;
    _locale = locale;
    _useNewApi = useNewApi ?? _useNewApi;

    return _addMethodCall(() => platform.updateSettings(_apiKey,
        locale: locale, useNewApi: _useNewApi));
  }
}
