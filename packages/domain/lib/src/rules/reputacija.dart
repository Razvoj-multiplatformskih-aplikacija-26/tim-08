import '../models/dogadjaj.dart';
import '../models/id_types.dart';
import '../models/recenzija.dart';


double? izracunajProsecnuOcenuDogadjaja(
    DogadjajId dogadjajId,
    List<Recenzija> recenzije,
    ) {
  final ocene = recenzije
      .where((r) => r.dogadjajId == dogadjajId)
      .map((r) => r.ocena)
      .toList();

  if (ocene.isEmpty) {
    return null;
  }

  final zbir = ocene.fold<int>(
    0,
        (sum, ocena) => sum + ocena,
  );

  final prosek = zbir / ocene.length;

  return (prosek * 100).round() / 100;
}


double? izracunajReputacijuHosta({
  required KorisnikId hostId,
  required List<Dogadjaj> dogadjaji,
  required List<Recenzija> recenzije,
}) {
  final hostDogadjajIds = dogadjaji
      .where((d) => d.hostId == hostId)
      .map((d) => d.id)
      .toSet();

  final ocene = recenzije
      .where((r) => hostDogadjajIds.contains(r.dogadjajId))
      .map((r) => r.ocena)
      .toList();

  if (ocene.isEmpty) {
    return null;
  }

  final zbir = ocene.fold<int>(
    0,
        (sum, ocena) => sum + ocena,
  );

  final prosek = zbir / ocene.length;

  return (prosek * 100).round() / 100;
}