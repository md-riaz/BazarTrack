import 'package:json_annotation/json_annotation.dart';

part 'api_dtos.g.dart';

bool _apiBool(Object? value) => value == true || value == 1 || value == '1';

@JsonSerializable(genericArgumentFactories: true)
class ApiEnvelopeDto<T> {
  const ApiEnvelopeDto({required this.data});

  final T data;

  factory ApiEnvelopeDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiEnvelopeDtoFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiEnvelopeDtoToJson(this, toJsonT);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ApiUserDto {
  const ApiUserDto({
    required this.id,
    required this.companyId,
    required this.role,
    required this.name,
    required this.isActive,
    this.phone,
    this.email,
  });

  final String id;
  final String companyId;
  final String role;
  final String name;
  @JsonKey(name: 'is_active', fromJson: _apiBool)
  final bool isActive;
  final String? phone;
  final String? email;

  factory ApiUserDto.fromJson(Map<String, dynamic> json) =>
      _$ApiUserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ApiUserDtoToJson(this);
}

@JsonSerializable()
class ApiLoginDto {
  const ApiLoginDto({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  final String token;
  @JsonKey(name: 'tokenType')
  final String tokenType;
  final ApiUserDto user;

  factory ApiLoginDto.fromJson(Map<String, dynamic> json) =>
      _$ApiLoginDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ApiLoginDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ApiBazarItemDto {
  const ApiBazarItemDto({
    required this.id,
    required this.bazarId,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.quantity,
    this.price,
    this.note,
    this.receiptUrl,
  });

  final String id;
  final String bazarId;
  final String name;
  final String status;
  final Object createdAt;
  final Object updatedAt;
  final double? quantity;
  final double? price;
  final String? note;
  final String? receiptUrl;

  factory ApiBazarItemDto.fromJson(Map<String, dynamic> json) =>
      _$ApiBazarItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ApiBazarItemDtoToJson(this);
}
