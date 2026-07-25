import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/features/stock/data/stock_model.dart';

class InsufficientStockException implements Exception {
  const InsufficientStockException();
}

class StockRepository {
  StockRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _stock =>
      _firestore.collection('stock');

  CollectionReference<Map<String, dynamic>> get _mouvements =>
      _firestore.collection('historique_dons');

  String _docId(String structureId, String groupeSanguin) =>
      '${structureId}_$groupeSanguin';

  /// Un flux par groupe sanguin, fusionné en une seule liste de 8 entrées
  /// (créées avec des valeurs par défaut si elles n'existent pas encore).
  Stream<List<StockItem>> watchStock(String structureId) {
    return _stock
        .where('structureId', isEqualTo: structureId)
        .snapshots()
        .map((snap) {
          final existing = {
            for (final doc in snap.docs)
              (doc.data()['groupeSanguin'] as String): StockItem.fromDoc(doc),
          };
          return [
            for (final bt in kBloodTypes)
              existing[bt.value] ??
                  StockItem(
                    structureId: structureId,
                    groupeSanguin: bt.value,
                    quantite: 0,
                    seuilAlerte: 10,
                    objectif: 20,
                  ),
          ];
        });
  }

  Stream<List<MouvementStock>> watchHistory(
    String structureId, {
    String? groupeSanguin,
  }) {
    Query<Map<String, dynamic>> query = _mouvements.where(
      'structureId',
      isEqualTo: structureId,
    );
    if (groupeSanguin != null) {
      query = query.where('groupeSanguin', isEqualTo: groupeSanguin);
    }
    return query
        .orderBy('date', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(MouvementStock.fromDoc).toList());
  }

  /// Ajoute ou retire une quantité de poches (transaction : lecture +
  /// validation + écriture atomiques) et journalise le mouvement — §4.5.
  Future<void> applyMovement({
    required String structureId,
    required String groupeSanguin,
    required MouvementType type,
    required int quantite,
    required String motif,
    String? donneurId,
    String? donneurNom,
  }) async {
    final ref = _stock.doc(_docId(structureId, groupeSanguin));

    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final current = snapshot.exists
          ? (snapshot.data()!['quantite'] as num?)?.toInt() ?? 0
          : 0;

      final next = type == MouvementType.entree
          ? current + quantite
          : current - quantite;
      if (next < 0) throw const InsufficientStockException();

      if (snapshot.exists) {
        tx.update(ref, {'quantite': next});
      } else {
        tx.set(ref, {
          'structureId': structureId,
          'groupeSanguin': groupeSanguin,
          'quantite': next,
          'seuilAlerte': 10,
          'objectif': 20,
        });
      }

      final mouvementRef = _mouvements.doc();
      tx.set(
        mouvementRef,
        MouvementStock(
          id: mouvementRef.id,
          structureId: structureId,
          groupeSanguin: groupeSanguin,
          type: type,
          quantite: quantite,
          motif: motif,
          donneurId: donneurId,
          donneurNom: donneurNom,
        ).toMap(),
      );
    });
  }

  Future<void> configureThresholds({
    required String structureId,
    required String groupeSanguin,
    required int seuilAlerte,
    required int objectif,
  }) {
    return _stock.doc(_docId(structureId, groupeSanguin)).set({
      'structureId': structureId,
      'groupeSanguin': groupeSanguin,
      'seuilAlerte': seuilAlerte,
      'objectif': objectif,
    }, SetOptions(merge: true));
  }
}
