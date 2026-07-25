import 'package:cloud_firestore/cloud_firestore.dart';

class StructureDocument {
  const StructureDocument({
    required this.nom,
    required this.url,
    required this.taille,
    required this.type,
  });

  final String nom;
  final String url;
  final int taille;
  final String type;

  factory StructureDocument.fromMap(Map<String, dynamic> map) {
    return StructureDocument(
      nom: map['nom'] as String? ?? '',
      url: map['url'] as String? ?? '',
      taille: (map['taille'] as num?)?.toInt() ?? 0,
      type: map['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'nom': nom, 'url': url, 'taille': taille, 'type': type};
  }
}

class StructureModel {
  const StructureModel({
    this.nom,
    this.type,
    this.adresse,
    this.localisation,
    this.documents = const [],
    this.groupesSanguins = const [],
    this.criteresAdditionnels,
    this.configurationTerminee = false,
    this.notifStockBas = true,
    this.notifResumeActivite = true,
  });

  final String? nom;
  final String? type;
  final String? adresse;
  final GeoPoint? localisation;
  final List<StructureDocument> documents;
  final List<String> groupesSanguins;
  final String? criteresAdditionnels;
  final bool configurationTerminee;
  final bool notifStockBas;
  final bool notifResumeActivite;

  factory StructureModel.fromMap(Map<String, dynamic> map) {
    return StructureModel(
      nom: map['nom'] as String?,
      type: map['type'] as String?,
      adresse: map['adresse'] as String?,
      localisation: map['localisation'] as GeoPoint?,
      documents: (map['documents'] as List<dynamic>? ?? const [])
          .map((d) => StructureDocument.fromMap(Map<String, dynamic>.from(d as Map)))
          .toList(),
      groupesSanguins: List<String>.from(
        map['groupesSanguins'] as List<dynamic>? ?? const [],
      ),
      criteresAdditionnels: map['criteresAdditionnels'] as String?,
      configurationTerminee: map['configurationTerminee'] as bool? ?? false,
      notifStockBas: map['notifStockBas'] as bool? ?? true,
      notifResumeActivite: map['notifResumeActivite'] as bool? ?? true,
    );
  }
}
