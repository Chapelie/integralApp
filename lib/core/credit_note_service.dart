// lib/core/credit_note_service.dart
// Service for managing credit notes (avoirs)
library;

import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'company_warehouse_service.dart';
import 'constants.dart';
import '../models/credit_note.dart';

class CreditNoteService {
  static final CreditNoteService _instance = CreditNoteService._internal();
  factory CreditNoteService() => _instance;
  CreditNoteService._internal();

  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  final CompanyWarehouseService _companyWarehouseService = CompanyWarehouseService();

  static const String _storageKey = 'credit_notes';

  /// Create a new credit note
  Future<CreditNote> createCreditNote({
    String? customerId,
    required double initialAmount,
    String? originSaleId,
    String? originRefundId,
    bool isSynced = false,
  }) async {
    final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
    if (warehouseId == null) {
      throw Exception('No warehouse selected');
    }

    final creditNote = CreditNote(
      id: const Uuid().v4(),
      warehouseId: warehouseId,
      customerId: customerId,
      initialAmount: initialAmount,
      remaining: initialAmount,
      createdAt: DateTime.now(),
      originSaleId: originSaleId,
      originRefundId: originRefundId,
      isSynced: isSynced,
    );

    await _saveCreditNoteLocally(creditNote);

    // Attempt to sync with API in background
    try {
      final response = await _apiService.post(
        AppConstants.creditNotesEndpoint(warehouseId),
        data: creditNote.toJson(),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final syncedId = response.data['data']['id'] as String? ?? creditNote.id;
        final updatedNote = creditNote.copyWith(id: syncedId, isSynced: true, syncedAt: DateTime.now());
        await _saveCreditNoteLocally(updatedNote);
        return updatedNote;
      }
    } catch (e) {
      print('Failed to sync credit note ${creditNote.id}: $e');
    }

    return creditNote;
  }

  /// Get all credit notes
  Future<List<CreditNote>> getAllCreditNotes({bool forceRefresh = false}) async {
    List<CreditNote> localNotes = await _getAllCreditNotesLocally();

    if (!forceRefresh && localNotes.isNotEmpty) {
      _syncCreditNotesFromAPI().catchError((e) {
        print('[CreditNoteService] Background sync error: $e');
      });
      return localNotes;
    }

    return await _syncCreditNotesFromAPI();
  }

  /// Get a single credit note by ID
  Future<CreditNote?> getCreditNote(String id) async {
    return await _getCreditNoteLocally(id);
  }

  /// Apply a credit note (reduce its remaining balance)
  Future<CreditNote> applyCredit(String id, double amountToApply) async {
    final existingNote = await _getCreditNoteLocally(id);
    if (existingNote == null) {
      throw Exception('Credit note not found');
    }

    if (existingNote.remaining < amountToApply) {
      throw Exception('Amount to apply exceeds remaining credit');
    }

    final newRemaining = (existingNote.remaining - amountToApply).clamp(0.0, double.infinity);
    final updatedNote = existingNote.copyWith(
      remaining: newRemaining,
      status: newRemaining == 0 ? 'consumed' : 'open',
      isSynced: false,
    );

    await _saveCreditNoteLocally(updatedNote);

    // Attempt to sync update with API in background
    final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
    if (warehouseId != null) {
      try {
        final response = await _apiService.put(
          AppConstants.applyCreditNoteEndpoint(warehouseId, updatedNote.id),
          data: updatedNote.toJson(),
        );
        if (response.statusCode == 200 && response.data['success'] == true) {
          final finalUpdatedNote = updatedNote.copyWith(isSynced: true, syncedAt: DateTime.now());
          await _saveCreditNoteLocally(finalUpdatedNote);
          return finalUpdatedNote;
        }
      } catch (e) {
        print('Failed to sync credit note update ${updatedNote.id}: $e');
      }
    }

    return updatedNote;
  }

  /// Save credit note locally
  Future<void> _saveCreditNoteLocally(CreditNote creditNote) async {
    final notes = await _getAllCreditNotesLocally();
    final index = notes.indexWhere((n) => n.id == creditNote.id);

    if (index >= 0) {
      notes[index] = creditNote;
    } else {
      notes.add(creditNote);
    }

    final notesJson = notes.map((n) => n.toJson()).toList();
    await _storageService.writeSetting(_storageKey, notesJson);
  }

  /// Get credit note locally
  Future<CreditNote?> _getCreditNoteLocally(String id) async {
    final notes = await _getAllCreditNotesLocally();
    try {
      return notes.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all credit notes locally
  Future<List<CreditNote>> _getAllCreditNotesLocally() async {
    final notesData = _storageService.readSetting(_storageKey);
    if (notesData == null || notesData is! List) {
      return [];
    }
    return notesData.map((json) => CreditNote.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Sync credit notes from API
  Future<List<CreditNote>> _syncCreditNotesFromAPI() async {
    final warehouseId = await _companyWarehouseService.getSelectedWarehouseId();
    if (warehouseId == null) {
      return [];
    }

    try {
      final response = await _apiService.get(AppConstants.creditNotesEndpoint(warehouseId));
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<CreditNote> apiNotes = (response.data['data'] as List)
            .map((json) => CreditNote.fromJson(json as Map<String, dynamic>))
            .toList();

        // Merge with local data (API takes precedence for synced items)
        List<CreditNote> mergedNotes = await _getAllCreditNotesLocally();
        for (final apiNote in apiNotes) {
          final index = mergedNotes.indexWhere((n) => n.id == apiNote.id);
          if (index >= 0) {
            mergedNotes[index] = apiNote.copyWith(isSynced: true, syncedAt: DateTime.now());
          } else {
            mergedNotes.add(apiNote.copyWith(isSynced: true, syncedAt: DateTime.now()));
          }
        }
        await _storageService.writeSetting(_storageKey, mergedNotes.map((n) => n.toJson()).toList());
        return mergedNotes;
      }
      return await _getAllCreditNotesLocally();
    } catch (e) {
      print('[CreditNoteService] Error syncing credit notes from API: $e');
      return await _getAllCreditNotesLocally();
    }
  }
}


