import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/note_model.dart';

/// Remote data source — the only layer that talks to MockAPI via [ApiClient].
class NotesRemoteDataSource {
  NotesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<NoteModel>> fetchNotes() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiConstants.notesEndpoint,
      );
      final data = response.data ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(NoteModel.fromRemoteJson)
          .where((note) => note.id.isNotEmpty)
          .toList();
    } on AppException {
      rethrow;
    } catch (error) {
      throw UnexpectedException('Failed to fetch notes: $error');
    }
  }

  Future<NoteModel> fetchNoteById(String apiId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.notesEndpoint}/$apiId',
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException('Note not found on server');
      }
      return NoteModel.fromRemoteJson(data);
    } on AppException {
      rethrow;
    } catch (error) {
      throw UnexpectedException('Failed to fetch note: $error');
    }
  }

  Future<NoteModel> createNote(NoteModel note) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.notesEndpoint,
        data: note.toRemoteJson(forCreate: true),
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException('Invalid create response');
      }
      return NoteModel.fromRemoteJson(data);
    } on AppException {
      rethrow;
    } catch (error) {
      throw UnexpectedException('Failed to create note: $error');
    }
  }

  Future<NoteModel> updateNote(NoteModel note, {required String apiId}) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiConstants.notesEndpoint}/$apiId',
        data: note.toRemoteJson(apiId: apiId),
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException('Invalid update response');
      }
      return NoteModel.fromRemoteJson(data);
    } on AppException {
      rethrow;
    } catch (error) {
      throw UnexpectedException('Failed to update note: $error');
    }
  }

  Future<void> deleteNote(String apiId) async {
    try {
      await _apiClient.delete<void>('${ApiConstants.notesEndpoint}/$apiId');
    } on AppException {
      rethrow;
    } catch (error) {
      throw UnexpectedException('Failed to delete note: $error');
    }
  }
}
