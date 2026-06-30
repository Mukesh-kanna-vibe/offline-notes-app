import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/note.dart';

class ApiService {
  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  final Dio _dio;

  Future<List<Note>> fetchNotes() async {
    final response = await _dio.get(ApiConfig.notesEndpoint);
    final data = response.data as List<dynamic>;
    return data
        .map((item) => Note.fromApiJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Note> createNote(Note note) async {
    // json-server ignores custom ids on POST; PUT upserts with our UUID.
    final response = await _dio.put(
      '${ApiConfig.notesEndpoint}/${note.id}',
      data: note.toApiJson(),
    );
    return Note.fromApiJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Note> updateNote(Note note) async {
    final response = await _dio.put(
      '${ApiConfig.notesEndpoint}/${note.id}',
      data: note.toApiJson(),
    );
    return Note.fromApiJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteNote(String id) async {
    await _dio.delete('${ApiConfig.notesEndpoint}/$id');
  }
}
