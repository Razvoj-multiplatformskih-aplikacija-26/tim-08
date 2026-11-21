import 'package:domain/domain.dart';
import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';

import 'api_http_client.dart';



class RemoteDogadjajRepository implements DogadjajRepository {
  final ApiClient client;

  const RemoteDogadjajRepository({
    required this.client,
  });

  @override
  Future<List<Dogadjaj>> getDogadjaji() async {
    const limit = 50;
    final events = <Dogadjaj>[];
    var afterId = 0;
    while (true) {
      final page = await client
          .getList(ApiRoutes.eventsPage(afterId: afterId, limit: limit));
      final mapped = page
          .map((json) => dogadjajFromApi(ApiEventDto.fromJson(json)))
          .toList();
      if (mapped.isNotEmpty && mapped.last.id.value <= afterId) return events;
      events.addAll(mapped);
      if (mapped.length < limit) return events;
      afterId = mapped.last.id.value;
    }
  }

  @override
  Future<Dogadjaj> promeniStanje(
    DogadjajId id,
    StanjeDogadjaja novoStanje,
  ) async {
    final result = await client.patchObject(
      ApiRoutes.eventState(id.value),
      body: stanjeToChangeRequest(novoStanje).toJson(),
    );

    return dogadjajFromApi(
      ApiEventDto.fromJson(result),
    );
  }

  @override
  Future<Dogadjaj> promeniKapacitet(
    DogadjajId id,
    int noviKapacitet,
  ) async {
    final result = await client.patchObject(
      ApiRoutes.eventCapacity(id.value),
      body: kapacitetToChangeRequest(noviKapacitet).toJson(),
    );

    return dogadjajFromApi(
      ApiEventDto.fromJson(result),
    );
  }

  @override
  Future<Dogadjaj> kreirajDogadjaj(
    Dogadjaj dogadjaj,
  ) async {
    final result = await client.postObject(
      ApiRoutes.events,
      body: dogadjajToCreateRequest(dogadjaj).toJson(),
    );

    return dogadjajFromApi(
      ApiEventDto.fromJson(result),
    );
  }
}


class RemotePrijavaRepository implements PrijavaRepository {
  final ApiClient client;

  const RemotePrijavaRepository({
    required this.client,
  });

  @override
  Future<List<Prijava>> getMojePrijave() async {
    if (!client.hasSession) return const [];
    final result = await client.getList(
      ApiRoutes.myRegistrations,
    );

    return result
        .map(
          (json) => prijavaFromApi(
            ApiRegistrationDto.fromJson(json),
          ),
        )
        .toList();
  }

  @override
  Future<int> getBrojAktivnihPrijava(
    DogadjajId dogadjajId,
  ) async {
    final result = await client.getObject(
      ApiRoutes.eventRegistrationCount(
        dogadjajId.value,
      ),
    );

    return result['count'] as int;
  }

  @override
  Future<Prijava> kreirajPrijavu(
    DogadjajId dogadjajId,
  ) async {
    final result = await client.postObject(
      ApiRoutes.eventRegistrations(
        dogadjajId.value,
      ),
      body: const ApiCreateRegistrationRequest().toJson(),
    );

    return prijavaFromApi(
      ApiRegistrationDto.fromJson(result),
    );
  }

  @override
  Future<void> otkaziPrijavu(
    PrijavaId prijavaId,
  ) async {
    await client.delete(
      ApiRoutes.registration(
        prijavaId.value,
      ),
    );
  }
}


class RemoteRecenzijaRepository implements RecenzijaRepository {
  final ApiClient client;

  const RemoteRecenzijaRepository({
    required this.client,
  });

  @override
  Future<List<Recenzija>> getRecenzije() async {
    final result = await client.getList(
      ApiRoutes.reviews,
    );

    return result
        .map(
          (json) => recenzijaFromApi(
            ApiReviewDto.fromJson(json),
          ),
        )
        .toList();
  }

  @override
  Future<Recenzija> kreirajRecenziju({
    required DogadjajId dogadjajId,
    required int ocena,
    required String komentar,
  }) async {
    final request = ApiCreateReviewRequest(
      rating: ocena,
      comment: komentar,
    );

    final result = await client.postObject(
      ApiRoutes.eventReviews(
        dogadjajId.value,
      ),
      body: request.toJson(),
    );

    return recenzijaFromApi(
      ApiReviewDto.fromJson(result),
    );
  }
}
