import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../models/voice_models.dart';

class VoiceRepository {
  final ApiClient apiClient;

  VoiceRepository({required this.apiClient});

  Future<TranscriptionResult> transcribeAudio(
    String audioFilePath, {
    String? languageHint,
  }) async {
    try {
      final map = <String, dynamic>{
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'recording.m4a',
        ),
      };
      if (languageHint != null) {
        map['language'] = languageHint;
      }
      final formData = FormData.fromMap(map);

      final response = await apiClient.dio.post(
        ApiEndpoints.voiceTranscribe,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return TranscriptionResult.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data?['message'] ?? 'Failed to transcribe audio.');
    } catch (e) {
      throw ApiException(message: 'Error communicating with voice service: $e');
    }
  }

  Future<VoiceCommandResult> parseCommand(String transcript, String? homeId) async {
    try {
      final payload = <String, dynamic>{
        'transcript': transcript,
      };
      if (homeId != null) {
        payload['homeId'] = homeId;
      }

      final response = await apiClient.dio.post(
        ApiEndpoints.voiceCommand,
        data: payload,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return VoiceCommandResult.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data?['message'] ?? 'Failed to parse command.');
    } catch (e) {
      throw ApiException(message: 'Error parsing voice command: $e');
    }
  }

  Future<VoiceCommandResult> processAudio(
    String audioFilePath,
    String homeId, {
    String? languageHint,
  }) async {
    try {
      final map = <String, dynamic>{
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'recording.m4a',
        ),
        'homeId': homeId,
      };
      if (languageHint != null) {
        map['language'] = languageHint;
      }
      final formData = FormData.fromMap(map);

      final queryParams = <String, dynamic>{
        'homeId': homeId,
      };
      if (languageHint != null) {
        queryParams['language'] = languageHint;
      }

      final response = await apiClient.dio.post(
        ApiEndpoints.voiceProcessAudio,
        data: formData,
        queryParameters: queryParams,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return VoiceCommandResult.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data?['message'] ?? 'Failed to process voice audio.');
    } catch (e) {
      throw ApiException(message: 'Voice processing failed: $e');
    }
  }

  Future<ExecuteCommandResponse> executeCommand(ExecuteCommandRequest request) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.voiceExecute,
        data: request.toJson(),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return ExecuteCommandResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data?['message'] ?? 'Failed to execute voice command.');
    } catch (e) {
      throw ApiException(message: 'Command execution failed: $e');
    }
  }

  /// Production Gemini Voice AI audio command endpoint
  Future<VoiceCommandResult> processAiAudio(
    String audioFilePath,
    String homeId, {
    String? idempotencyKey,
  }) async {
    try {
      final map = <String, dynamic>{
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'recording.m4a',
          contentType: DioMediaType.parse('audio/mp4'),
        ),
        'homeId': homeId,
      };
      if (idempotencyKey != null) {
        map['idempotencyKey'] = idempotencyKey;
      }
      final formData = FormData.fromMap(map);

      final response = await apiClient.dio.post(
        ApiEndpoints.voiceAiCommand,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return VoiceCommandResult.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data?['message'] ?? 'Failed to process AI voice command.');
    } catch (e) {
      throw ApiException(message: 'AI voice processing failed: $e');
    }
  }

  /// Production Gemini Voice AI text parse endpoint
  Future<VoiceCommandResult> parseAiCommand(String transcript, String homeId) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.voiceAiParse,
        data: {
          'transcript': transcript,
          'homeId': homeId,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return VoiceCommandResult.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data?['message'] ?? 'Failed to parse AI command.');
    } catch (e) {
      throw ApiException(message: 'AI parse command failed: $e');
    }
  }

  /// Production Gemini Voice AI follow-up multi-turn endpoint
  Future<VoiceCommandResult> followUpAiCommand(String transcript, String homeId) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.voiceAiFollowUp,
        data: {
          'transcript': transcript,
          'homeId': homeId,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return VoiceCommandResult.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data?['message'] ?? 'Failed to process follow-up.');
    } catch (e) {
      throw ApiException(message: 'AI follow-up failed: $e');
    }
  }

  /// Voice command audit history
  Future<List<Map<String, dynamic>>> getAuditHistory(String homeId, {int page = 0, int size = 20}) async {
    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.voiceAudit,
        queryParameters: {
          'homeId': homeId,
          'page': page,
          'size': size,
        },
      );

      final data = response.data['data'];
      if (data != null && data['content'] is List) {
        return List<Map<String, dynamic>>.from(data['content'] as List);
      }
      return [];
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data?['message'] ?? 'Failed to fetch audit history.');
    } catch (e) {
      throw ApiException(message: 'Audit history fetch failed: $e');
    }
  }
}
