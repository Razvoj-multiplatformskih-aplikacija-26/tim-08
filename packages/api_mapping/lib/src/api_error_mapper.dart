import 'package:domain/domain.dart';
import 'package:api_contract/api_contract.dart';

enum ApiErrorCategory {
  validation,
  unauthenticated,
  forbidden,
  notFound,
  conflict,
  server,
  unknown,
}

class ApiMappedError {
  final String code;
  final ApiErrorCategory category;
  final Map<String, Object?> details;


  final GreskaValidacije? validationError;

  const ApiMappedError({
    required this.code,
    required this.category,
    required this.details,
    this.validationError,
  });
}


ApiMappedError apiErrorToDomain(ApiErrorDto error) {
  switch (error.code) {

    case 'INVALID_CAPACITY':
      return ApiMappedError(
        code: error.code,
        category: ApiErrorCategory.validation,
        details: error.details,
        validationError: const GreskaNeodgovarajuciKapacitet(),
      );

    case 'HOST_REPUTATION_OUT_OF_RANGE':
      return ApiMappedError(
        code: error.code,
        category: ApiErrorCategory.validation,
        details: error.details,
        validationError: const GreskaReputacijaIzvanOpsega(),
      );

    case 'EVENT_CAPACITY_REACHED':
      return ApiMappedError(
        code: error.code,
        category: ApiErrorCategory.validation,
        details: error.details,
        validationError: const GreskaNemaSlobodnihMesta(),
      );

    case 'INVALID_REVIEW_RATING':
      return ApiMappedError(
        code: error.code,
        category: ApiErrorCategory.validation,
        details: error.details,
        validationError: const GreskaOcenaIzvanOpsega(),
      );

    case 'REVIEW_COMMENT_TOO_SHORT':
      return ApiMappedError(
        code: error.code,
        category: ApiErrorCategory.validation,
        details: error.details,
        validationError: const GreskaKomentarPrekratak(),
      );

    case 'REVIEW_COMMENT_TOO_LONG':
      return ApiMappedError(
        code: error.code,
        category: ApiErrorCategory.validation,
        details: error.details,
        validationError: const GreskaKomentarPredugacak(),
      );


    case 'INVALID_CREDENTIALS':
    case 'UNAUTHENTICATED':
    case 'SESSION_EXPIRED':
      return ApiMappedError(
        code: error.code,
        category: ApiErrorCategory.unauthenticated,
        details: error.details,
      );


    case 'BACKOFFICE_ROLE_REQUIRED':
    case 'MOBILE_ROLE_REQUIRED':
    case 'FORBIDDEN':
    case 'HOST_REPUTATION_TOO_LOW':
    case 'ACCOUNT_BANNED':
      return ApiMappedError(
        code: error.code,
        category: ApiErrorCategory.forbidden,
        details: error.details,
      );



    case 'EVENT_NOT_FOUND':
    case 'USER_NOT_FOUND':
    case 'REGISTRATION_NOT_FOUND':
    case 'REVIEW_NOT_FOUND':
      return ApiMappedError(
        code: error.code,
        category: ApiErrorCategory.notFound,
        details: error.details,
      );


    case 'INVALID_EVENT_TRANSITION':
    case 'DUPLICATE_REGISTRATION':
    case 'DUPLICATE_REVIEW':
    case 'EVENT_REGISTRATION_CLOSED':
      return ApiMappedError(
        code: error.code,
        category: ApiErrorCategory.conflict,
        details: error.details,
      );



    case 'INTERNAL_SERVER_ERROR':
      return ApiMappedError(
        code: error.code,
        category: ApiErrorCategory.server,
        details: error.details,
      );

    default:
      return ApiMappedError(
        code: error.code,
        category: ApiErrorCategory.unknown,
        details: error.details,
      );
  }
}


ApiErrorDto domainValidationToApi(
  RezultatValidacije rezultat, {
  Map<String, Object?> details = const {},
}) {
  final String code;

  switch (rezultat) {
    case UspehValidacije():
      throw ArgumentError(
        'Uspeh validacije nije API greška.',
      );

    case GreskaNeodgovarajuciKapacitet():
      code = 'INVALID_CAPACITY';

    case GreskaReputacijaIzvanOpsega():
      code = 'HOST_REPUTATION_OUT_OF_RANGE';

    case GreskaNemaSlobodnihMesta():
      code = 'EVENT_CAPACITY_REACHED';

    case GreskaOcenaIzvanOpsega():
      code = 'INVALID_REVIEW_RATING';

    case GreskaKomentarPrekratak():
      code = 'REVIEW_COMMENT_TOO_SHORT';

    case GreskaKomentarPredugacak():
      code = 'REVIEW_COMMENT_TOO_LONG';
  }

  return ApiErrorDto(
    code: code,
    details: details,
  );
}
