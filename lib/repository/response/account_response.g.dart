// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountResponseImpl _$$AccountResponseImplFromJson(
  Map<String, dynamic> json,
) => _$AccountResponseImpl(
  summary: _parseSummary(json['summary']),
  list:
      (json['list'] as List<dynamic>?)
          ?.map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$AccountResponseImplToJson(
  _$AccountResponseImpl instance,
) => <String, dynamic>{'summary': instance.summary, 'list': instance.list};

_$AccountSummaryImpl _$$AccountSummaryImplFromJson(
  Map<String, dynamic> json,
) => _$AccountSummaryImpl(
  totalBalance: json['totalBalance'] == null
      ? '0'
      : _parseString(json['totalBalance']),
  totalCount: json['totalCount'] == null ? 0 : _parseInt(json['totalCount']),
  totalPage: json['totalPage'] == null ? 1 : _parseInt(json['totalPage']),
  currentPage: json['currentPage'] == null ? 1 : _parseInt(json['currentPage']),
);

Map<String, dynamic> _$$AccountSummaryImplToJson(
  _$AccountSummaryImpl instance,
) => <String, dynamic>{
  'totalBalance': instance.totalBalance,
  'totalCount': instance.totalCount,
  'totalPage': instance.totalPage,
  'currentPage': instance.currentPage,
};

_$AccountImpl _$$AccountImplFromJson(Map<String, dynamic> json) =>
    _$AccountImpl(
      id: json['id'] == null ? 0 : _parseInt(json['id']),
      accountName: json['accountName'] == null
          ? '이름 없음'
          : _parseString(json['accountName']),
      accountNumber: json['accountNumber'] == null
          ? ''
          : _parseString(json['accountNumber']),
      balance: json['balance'] == null ? '0' : _parseString(json['balance']),
      type: json['type'] == null ? 'PERSONAL' : _parseString(json['type']),
      status: json['status'] == null ? 'PENDING' : _parseString(json['status']),
      owner: _parseUser(json['owner']),
    );

Map<String, dynamic> _$$AccountImplToJson(_$AccountImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountName': instance.accountName,
      'accountNumber': instance.accountNumber,
      'balance': instance.balance,
      'type': instance.type,
      'status': instance.status,
      'owner': instance.owner,
    };

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  userId: json['userId'] == null ? '' : _parseString(json['userId']),
  name: json['name'] == null ? '알 수 없음' : _parseString(json['name']),
);

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{'userId': instance.userId, 'name': instance.name};
