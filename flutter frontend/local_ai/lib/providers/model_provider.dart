import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, error }

class LocalModel {
  final String id;
  final String name;
  final String specialty;
  final String description;
  final String url;
  final ModelType type;
  final String filename;

  LocalModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.description,
    required this.url,
    required this.type,
    required this.filename,
  });
}

class ModelProvider extends ChangeNotifier {
  final List<LocalModel> _availableModels = [
    LocalModel(
      id: 'gemma_2b_it',
      name: 'Gemma 2B IT (General)',
      specialty: 'General Assistant',
      description: 'Google\'s Gemma model optimized for general conversation and instructions.',
      url: 'https://huggingface.co/google/gemma-2b-it/resolve/main/gemma-2b-it-cpu-int4.task',
      type: ModelType.gemmaIt,
      filename: 'gemma-2b-it-cpu-int4.task',
    ),
    LocalModel(
      id: 'deepseek_r1_1.5b',
      name: 'DeepSeek R1 1.5B (Reasoning)',
      specialty: 'Reasoning & Coding',
      description: 'DeepSeek R1 distilled Qwen model optimized for reasoning, math, and code.',
      url: 'https://huggingface.co/DenisovAV/deepseek-r1-distill-qwen-1.5b-litert-lm/resolve/main/deepseek-r1-distill-qwen-1.5b.litertlm',
      type: ModelType.deepSeek,
      filename: 'deepseek-r1-distill-qwen-1.5b.litertlm',
    ),
    LocalModel(
      id: 'qwen_1.5b',
      name: 'Qwen 2.5 1.5B (Multilingual)',
      specialty: 'Multilingual & Chat',
      description: 'Alibaba\'s Qwen model optimized for multilingual understanding and chat.',
      url: 'https://huggingface.co/DenisovAV/qwen-2.5-1.5b-it-litert-lm/resolve/main/qwen-2.5-1.5b-it.litertlm',
      type: ModelType.qwen,
      filename: 'qwen-2.5-1.5b-it.litertlm',
    ),
    LocalModel(
      id: 'phi_3_mini',
      name: 'Phi 3 Mini (Logic)',
      specialty: 'Logic & Math',
      description: 'Microsoft\'s Phi-3 model optimized for reasoning and logical tasks.',
      url: 'https://huggingface.co/DenisovAV/phi-3-mini-4k-instruct-litert-lm/resolve/main/phi-3-mini-4k-instruct.litertlm',
      type: ModelType.phi,
      filename: 'phi-3-mini-4k-instruct.litertlm',
    ),
  ];

  final Map<String, DownloadStatus> _downloadStatuses = {};
  final Map<String, double> _downloadProgresses = {};

  LocalModel? _activeModel;
  bool _isLocalMode = false;
  List<LocalModel> get availableModels => _availableModels;
  LocalModel? get activeModel => _activeModel;
  bool get isLocalMode => _isLocalMode;

  DownloadStatus getDownloadStatus(String id) => _downloadStatuses[id] ?? DownloadStatus.notDownloaded;
  double getDownloadProgress(String id) => _downloadProgresses[id] ?? 0.0;

  ModelProvider() {
    _initStatuses();
  }

  Future<void> _initStatuses() async {
    for (final model in _availableModels) {
      _downloadStatuses[model.id] = DownloadStatus.notDownloaded;
      _downloadProgresses[model.id] = 0.0;
    }
    notifyListeners();
    await checkInstalledModels();
  }

  Future<void> checkInstalledModels() async {
    for (final model in _availableModels) {
      try {
        final isInstalled = await FlutterGemma.isModelInstalled(model.filename);
        if (isInstalled) {
          _downloadStatuses[model.id] = DownloadStatus.downloaded;
          _downloadProgresses[model.id] = 1.0;
          _activeModel ??= model;
        } else {
          // If we had it as downloaded but it's not actually there
          if (_downloadStatuses[model.id] == DownloadStatus.downloaded) {
            _downloadStatuses[model.id] = DownloadStatus.notDownloaded;
            _downloadProgresses[model.id] = 0.0;
            if (_activeModel?.id == model.id) {
              _activeModel = null;
            }
          }
        }
      } catch (e) {
        debugPrint('Error checking model install status for ${model.id}: $e');
      }
    }
    notifyListeners();
  }

  void setLocalMode(bool value) {
    _isLocalMode = value;
    notifyListeners();
  }

  void setActiveModel(LocalModel model) {
    if (getDownloadStatus(model.id) == DownloadStatus.downloaded) {
      _activeModel = model;
      notifyListeners();
    }
  }

  Future<void> downloadModel(LocalModel model) async {
    if (_downloadStatuses[model.id] == DownloadStatus.downloading ||
        _downloadStatuses[model.id] == DownloadStatus.downloaded) {
      return;
    }

    _downloadStatuses[model.id] = DownloadStatus.downloading;
    _downloadProgresses[model.id] = 0.0;
    notifyListeners();

    try {
      await FlutterGemma.installModel(modelType: model.type)
          .fromNetwork(model.url)
          .withProgress((progress) {
            double val = 0.0;
            try {
              final dynamic p = progress;
              final dynamic pct = p.percentage;
              if (pct is num) {
                if (pct > 1.0) {
                  val = pct / 100.0;
                } else {
                  val = pct.toDouble();
                }
              }
            } catch (_) {
              try {
                final dynamic p = progress;
                final dynamic prg = p.progress;
                if (prg is num) {
                  val = prg.toDouble();
                }
              } catch (_) {}
            }
            
            _downloadProgresses[model.id] = val;
            notifyListeners();
          })
          .install();

      _downloadStatuses[model.id] = DownloadStatus.downloaded;
      _downloadProgresses[model.id] = 1.0;
      _activeModel ??= model;
    } catch (e) {
      debugPrint('Error downloading model ${model.id}: $e');
      _downloadStatuses[model.id] = DownloadStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteModel(LocalModel model) async {
    try {
      await FlutterGemma.uninstallModel(model.filename);
      _downloadStatuses[model.id] = DownloadStatus.notDownloaded;
      _downloadProgresses[model.id] = 0.0;
      if (_activeModel?.id == model.id) {
        _activeModel = null;
        for (final m in _availableModels) {
          if (_downloadStatuses[m.id] == DownloadStatus.downloaded) {
            _activeModel = m;
            break;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting model ${model.id}: $e');
    }
  }
}
