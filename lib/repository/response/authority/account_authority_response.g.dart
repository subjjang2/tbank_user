// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_authority_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountAuthorityResponseImpl _$$AccountAuthorityResponseImplFromJson(
  Map<String, dynamic> json,
) => _$AccountAuthorityResponseImpl(
  accountNumber: json['accountNumber'] as String,
  isAuditorAllowed: json['isAuditorAllowed'] as bool? ?? false,
  isPending: json['isPending'] as bool? ?? false,
  permissions:
      (json['permissions'] as List<dynamic>?)
          ?.map((e) => Permission.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$AccountAuthorityResponseImplToJson(
  _$AccountAuthorityResponseImpl instance,
) => <String, dynamic>{
  'accountNumber': instance.accountNumber,
  'isAuditorAllowed': instance.isAuditorAllowed,
  'isPending': instance.isPending,
  'permissions': instance.permissions,
};

_$PermissionImpl _$$PermissionImplFromJson(Map<String, dynamic> json) =>
    _$PermissionImpl(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$$PermissionImplToJson(_$PermissionImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'userName': instance.userName,
      'type': instance.type,
    };
