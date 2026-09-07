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
}
