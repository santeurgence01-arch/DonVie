import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_emergency/core/constants/app_constants.dart';

/// Doc `stock/{structureId}_{groupeSanguin}` — quantité courante d'un
/// groupe sanguin pour une structure.
class StockItem {
  const StockItem({
    required this.structureId,
    required this.groupeSanguin,
    required this.quantite,
    required this.seuilAlerte,
    required this.objectif,
  });

  final String structureId;
  final String groupeSanguin;
  final int quantite;
  final int seuilAlerte;
  final int objectif;

  /// Pourcentage du stock par rapport à l'objectif (peut dépasser 100%).
  double get pourcentageObjectif =>
      objectif <= 0 ? 0 : quantite / objectif;

  /// Vert si > 150% du seuil, orange si 100-150%, rouge si sous le seuil —
  /// §4.3.
  StockLevel get niveau {
    if (seuilAlerte <= 0) return StockLevel.normal;
    final ratio = quantite / seuilAlerte;
    if (ratio < 1) return StockLevel.critique;
    if (ratio <= 1.5) return StockLevel.moyen;
    return StockLevel.normal;
  }

  factory StockItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return StockItem(
      structureId: data['structureId'] as String? ?? '',
      groupeSanguin: data['groupeSanguin'] as String? ?? '',
      quantite: (data['quantite'] as num?)?.toInt() ?? 0,
      seuilAlerte: (data['seuilAlerte'] as num?)?.toInt() ?? 10,
      objectif: (data['objectif'] as num?)?.toInt() ?? 20,
    );
  }

  StockItem copyWith({int? quantite, int? seuilAlerte, int? objectif}) {
    return StockItem(
      structureId: structureId,
      groupeSanguin: groupeSanguin,
      quantite: quantite ?? this.quantite,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      objectif: objectif ?? this.objectif,
    );
  }
}

enum StockLevel { normal, moyen, critique }

/// Doc `historique_dons/{id}` — un mouvement de stock (entrée = don reçu,
/// sortie = utilisation médicale / péremption / autre). Si [donneurId] est
/// renseigné, ce mouvement correspond à un don physique de ce donneur et
/// apparaît aussi dans son historique personnel — §4.4.2 / §4.5.
class MouvementStock {
  const MouvementStock({
    required this.id,
    required this.structureId,
    required this.groupeSanguin,
    required this.type,
    required this.quantite,
    required this.motif,
    this.donneurId,
    this.donneurNom,
    this.date,
  });

  final String id;
  final String structureId;
  final String groupeSanguin;
  final MouvementType type;
  final int quantite;
  final String motif;
  final String? donneurId;
  final String? donneurNom;
  final DateTime? date;

  factory MouvementStock.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MouvementStock(
      id: doc.id,
      structureId: data['structureId'] as String? ?? '',
      groupeSanguin: data['groupeSanguin'] as String? ?? '',
      type: (data['type'] as String?) == 'entree'
          ? MouvementType.entree
          : MouvementType.sortie,
      quantite: (data['quantite'] as num?)?.toInt() ?? 0,
      motif: data['motif'] as String? ?? '',
      donneurId: data['donneurId'] as String?,
      donneurNom: data['donneurNom'] as String?,
      date: (data['date'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'structureId': structureId,
      'groupeSanguin': groupeSanguin,
      'type': type == MouvementType.entree ? 'entree' : 'sortie',
      'quantite': quantite,
      'motif': motif,
      'donneurId': donneurId,
      'donneurNom': donneurNom,
      'date': FieldValue.serverTimestamp(),
    };
  }
}
