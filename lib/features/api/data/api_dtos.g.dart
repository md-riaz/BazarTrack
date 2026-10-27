// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiEnvelopeDto<T> _$ApiEnvelopeDtoFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ApiEnvelopeDto<T>(data: fromJsonT(json['data']));

Map<String, dynamic> _$ApiEnvelopeDtoToJson<T>(
  ApiEnvelopeDto<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{'data': toJsonT(instance.data)};

ApiUserDto _$ApiUserDtoFromJson(Map<String, dynamic> json) => ApiUserDto(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  role: json['role'] as String,
  name: json['name'] as String,
  isActive: _apiBool(json['is_active']),
  phone: json['phone'] as String?,
  email: json['email'] as String?,
);

Map<String, dynamic> _$ApiUserDtoToJson(ApiUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'role': instance.role,
      'name': instance.name,
      'is_active': instance.isActive,
      'phone': instance.phone,
      'email': instance.email,
    };

ApiLoginDto _$ApiLoginDtoFromJson(Map<String, dynamic> json) => ApiLoginDto(
  token: json['token'] as String,
  tokenType: json['tokenType'] as String,
  user: ApiUserDto.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ApiLoginDtoToJson(ApiLoginDto instance) =>
    <String, dynamic>{
      'token': instance.token,
      'tokenType': instance.tokenType,
      'user': instance.user,
    };

ApiBazarItemDto _$ApiBazarItemDtoFromJson(Map<String, dynamic> json) =>
    ApiBazarItemDto(
      id: json['id'] as String,
      bazarId: json['bazar_id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as Object,
      updatedAt: json['updated_at'] as Object,
      quantity: (json['quantity'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      note: json['note'] as String?,
      receiptUrl: json['receipt_url'] as String?,
    );

Map<String, dynamic> _$ApiBazarItemDtoToJson(ApiBazarItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bazar_id': instance.bazarId,
      'name': instance.name,
      'status': instance.status,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'quantity': instance.quantity,
      'price': instance.price,
      'note': instance.note,
      'receipt_url': instance.receiptUrl,
    };
