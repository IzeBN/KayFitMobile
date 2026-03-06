// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String?,
      username: json['username'] as String?,
      telegramId: (json['telegramId'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'username': instance.username,
      'telegramId': instance.telegramId,
      'isActive': instance.isActive,
    };
