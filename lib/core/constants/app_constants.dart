class BloodType {
  final String value;
  final String label;

  const BloodType(this.value, this.label);
}

const List<BloodType> kBloodTypes = [
  BloodType('O+', 'O+'),
  BloodType('O-', 'O-'),
  BloodType('A+', 'A+'),
  BloodType('A-', 'A-'),
  BloodType('B+', 'B+'),
  BloodType('B-', 'B-'),
  BloodType('AB+', 'AB+'),
  BloodType('AB-', 'AB-'),
];

class StructureType {
  final String value;
  final String label;

  const StructureType(this.value, this.label);
}

const List<StructureType> kStructureTypes = [
  StructureType('hopital', 'Hôpital'),
  StructureType('csi', 'Centre de santé intégré (CSI)'),
  StructureType('medico_legal', 'Structure médico-légale'),
];

const double kMobileBreakpoint = 600;
const double kMaxContentWidth = 1200;

enum UrgencyLevel {
  normal('normal', 'Normal'),
  urgent('urgent', 'Urgent'),
  critique('critique', 'Critique');

  const UrgencyLevel(this.value, this.label);

  final String value;
  final String label;

  static UrgencyLevel fromValue(String value) => UrgencyLevel.values.firstWhere(
    (e) => e.value == value,
    orElse: () => UrgencyLevel.normal,
  );
}

enum DemandeStatut { active, cloturee }

enum ReponseStatut { enAttente, confirme, decline }

enum MouvementType { entree, sortie }
