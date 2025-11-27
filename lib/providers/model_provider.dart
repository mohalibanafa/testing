import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flowder/flowder.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../models/model.dart';
import '../providers/preferences_provider.dart';
import '../constants.dart';

/// Provider handling the model downloads.
///
/// Uses the [PreferencesProvider] to store the model informations
/// and holds the [progress] and [currentDownloade] metrics.
class ModelProvider extends ChangeNotifier {
  late PreferencesProvider _preferences;
  double progress = 0;
  int currentDownloaded = 0;

  DownloaderCore? downloader;

  ModelProvider();

  /// Sets the [preferences] with the app [PreferencesProvider].
  void setPreferences(PreferencesProvider preferences) {
    _preferences = preferences;
  }

  /// Downloads the given [model] to the app external storage.
  ///
  /// Displays the progress on the [DownloadScreen].
  /// Runs the [onDone] callback when the download is over.
  void downloadModel(Model model, {required VoidCallback onDone}) async {
    final filename = '${model.name}${Models.fileExtension}';
    final directory = await _preferences.repository.modelsPath;

    final path = p.join(directory, filename);

    if (model.isAsset) {
      final byteData = await rootBundle.load('assets/models/$filename');
      final file = File(path);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      _preferences.repository.setModelPath(path, model.name);
      _preferences.setModel(model);
      onDone();
    } else {
      Get.toNamed('/model/download');

      final options = DownloaderUtils(
        progressCallback: (current, total) {
          progress = (current / total);
          currentDownloaded = current ~/ 1e6;
          notifyListeners();
        },
        file: File(path),
        progress: ProgressImplementation(),
        deleteOnCancel: true,
        onDone: () {
          _preferences.repository.setModelPath(path, model.name);
          _preferences.setModel(model);
          _clearDownload();

          onDone();
        },
      );

      try {
        if (model.url == null) {
          throw ArgumentError('Model URL cannot be null for non-asset models');
        }
        downloader = await Flowder.download(model.url!, options);
      } catch (e) {
        Get.snackbar(
          'Download error',
          'You must be connected in to download the model. '
              'Please check your connection and try again.',
          backgroundColor: ColorPalette.errorContainer,
          colorText: ColorPalette.onError,
          duration: const Duration(seconds: 5),
        );
        await Future.delayed(const Duration(seconds: 2));
        _clearDownload();
        notifyListeners();
      }
    }
  }

  /// Cancels the current download registered in the [downloader].
  void cancelDownload() {
    downloader?.cancel();
    _clearDownload();
    Get.back();
  }

  /// Clear the current download properties.
  void _clearDownload() {
    progress = 0;
    currentDownloaded = 0;
    downloader = null;
  }
}
