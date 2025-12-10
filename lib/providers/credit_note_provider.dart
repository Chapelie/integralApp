// lib/providers/credit_note_provider.dart
// Provider pour gérer les avoirs (credit notes)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/credit_note.dart';
import '../core/credit_note_service.dart';

// CreditNote State
class CreditNoteState {
  final List<CreditNote> creditNotes;
  final bool isLoading;
  final String? error;

  CreditNoteState({
    this.creditNotes = const [],
    this.isLoading = false,
    this.error,
  });

  CreditNoteState copyWith({
    List<CreditNote>? creditNotes,
    bool? isLoading,
    String? error,
  }) {
    return CreditNoteState(
      creditNotes: creditNotes ?? this.creditNotes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// CreditNote Notifier
class CreditNoteNotifier extends Notifier<CreditNoteState> {
  late final CreditNoteService _service;

  @override
  CreditNoteState build() {
    _service = ref.watch(creditNoteServiceProvider);
    // Use Future.microtask to avoid circular dependency
    Future.microtask(() {
      if (ref.mounted) {
        load();
      }
    });
    return CreditNoteState();
  }

  Future<void> load({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notes = await _service.getAllCreditNotes(forceRefresh: forceRefresh);
      state = state.copyWith(creditNotes: notes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await load(forceRefresh: true);
  }

  Future<void> createCreditNote({
    String? customerId,
    required double initialAmount,
    String? originSaleId,
    String? originRefundId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createCreditNote(
        customerId: customerId,
        initialAmount: initialAmount,
        originSaleId: originSaleId,
        originRefundId: originRefundId,
      );
      await load(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> applyCredit(String id, double amountToApply) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.applyCredit(id, amountToApply);
      await load(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final creditNoteProvider = NotifierProvider<CreditNoteNotifier, CreditNoteState>(
  () => CreditNoteNotifier(),
);

final creditNoteServiceProvider = Provider((ref) => CreditNoteService());

