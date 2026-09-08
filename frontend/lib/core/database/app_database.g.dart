// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalUsersTable extends LocalUsers
    with TableInfo<$LocalUsersTable, LocalUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    fullName,
    phoneNumber,
    avatarUrl,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUser(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalUsersTable createAlias(String alias) {
    return $LocalUsersTable(attachedDatabase, alias);
  }
}

class LocalUser extends DataClass implements Insertable<LocalUser> {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const LocalUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalUsersCompanion toCompanion(bool nullToAbsent) {
    return LocalUsersCompanion(
      id: Value(id),
      email: Value(email),
      fullName: Value(fullName),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      isActive: Value(isActive),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalUser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUser(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      fullName: serializer.fromJson<String>(json['fullName']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'fullName': serializer.toJson<String>(fullName),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalUser copyWith({
    String? id,
    String? email,
    String? fullName,
    Value<String?> phoneNumber = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    bool? isActive,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalUser(
    id: id ?? this.id,
    email: email ?? this.email,
    fullName: fullName ?? this.fullName,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalUser copyWithCompanion(LocalUsersCompanion data) {
    return LocalUser(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUser(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    fullName,
    phoneNumber,
    avatarUrl,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUser &&
          other.id == this.id &&
          other.email == this.email &&
          other.fullName == this.fullName &&
          other.phoneNumber == this.phoneNumber &&
          other.avatarUrl == this.avatarUrl &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalUsersCompanion extends UpdateCompanion<LocalUser> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> fullName;
  final Value<String?> phoneNumber;
  final Value<String?> avatarUrl;
  final Value<bool> isActive;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalUsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.fullName = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUsersCompanion.insert({
    required String id,
    required String email,
    required String fullName,
    this.phoneNumber = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       email = Value(email),
       fullName = Value(fullName);
  static Insertable<LocalUser> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? fullName,
    Expression<String>? phoneNumber,
    Expression<String>? avatarUrl,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (fullName != null) 'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUsersCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String>? fullName,
    Value<String?>? phoneNumber,
    Value<String?>? avatarUrl,
    Value<bool>? isActive,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalUsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalHomesTable extends LocalHomes
    with TableInfo<$LocalHomesTable, LocalHome> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalHomesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inviteCodeMeta = const VerificationMeta(
    'inviteCode',
  );
  @override
  late final GeneratedColumn<String> inviteCode = GeneratedColumn<String>(
    'invite_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentUserRoleMeta = const VerificationMeta(
    'currentUserRole',
  );
  @override
  late final GeneratedColumn<String> currentUserRole = GeneratedColumn<String>(
    'current_user_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('MEMBER'),
  );
  static const VerificationMeta _memberCountMeta = const VerificationMeta(
    'memberCount',
  );
  @override
  late final GeneratedColumn<int> memberCount = GeneratedColumn<int>(
    'member_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    inviteCode,
    createdBy,
    currentUserRole,
    memberCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_homes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalHome> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('invite_code')) {
      context.handle(
        _inviteCodeMeta,
        inviteCode.isAcceptableOrUnknown(data['invite_code']!, _inviteCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_inviteCodeMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('current_user_role')) {
      context.handle(
        _currentUserRoleMeta,
        currentUserRole.isAcceptableOrUnknown(
          data['current_user_role']!,
          _currentUserRoleMeta,
        ),
      );
    }
    if (data.containsKey('member_count')) {
      context.handle(
        _memberCountMeta,
        memberCount.isAcceptableOrUnknown(
          data['member_count']!,
          _memberCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalHome map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalHome(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      inviteCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invite_code'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      currentUserRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_user_role'],
      )!,
      memberCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalHomesTable createAlias(String alias) {
    return $LocalHomesTable(attachedDatabase, alias);
  }
}

class LocalHome extends DataClass implements Insertable<LocalHome> {
  final String id;
  final String name;
  final String inviteCode;
  final String? createdBy;
  final String currentUserRole;
  final int memberCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const LocalHome({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.createdBy,
    required this.currentUserRole,
    required this.memberCount,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['invite_code'] = Variable<String>(inviteCode);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['current_user_role'] = Variable<String>(currentUserRole);
    map['member_count'] = Variable<int>(memberCount);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalHomesCompanion toCompanion(bool nullToAbsent) {
    return LocalHomesCompanion(
      id: Value(id),
      name: Value(name),
      inviteCode: Value(inviteCode),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      currentUserRole: Value(currentUserRole),
      memberCount: Value(memberCount),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalHome.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalHome(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      inviteCode: serializer.fromJson<String>(json['inviteCode']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      currentUserRole: serializer.fromJson<String>(json['currentUserRole']),
      memberCount: serializer.fromJson<int>(json['memberCount']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'inviteCode': serializer.toJson<String>(inviteCode),
      'createdBy': serializer.toJson<String?>(createdBy),
      'currentUserRole': serializer.toJson<String>(currentUserRole),
      'memberCount': serializer.toJson<int>(memberCount),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalHome copyWith({
    String? id,
    String? name,
    String? inviteCode,
    Value<String?> createdBy = const Value.absent(),
    String? currentUserRole,
    int? memberCount,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalHome(
    id: id ?? this.id,
    name: name ?? this.name,
    inviteCode: inviteCode ?? this.inviteCode,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    currentUserRole: currentUserRole ?? this.currentUserRole,
    memberCount: memberCount ?? this.memberCount,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalHome copyWithCompanion(LocalHomesCompanion data) {
    return LocalHome(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      inviteCode: data.inviteCode.present
          ? data.inviteCode.value
          : this.inviteCode,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      currentUserRole: data.currentUserRole.present
          ? data.currentUserRole.value
          : this.currentUserRole,
      memberCount: data.memberCount.present
          ? data.memberCount.value
          : this.memberCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalHome(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('createdBy: $createdBy, ')
          ..write('currentUserRole: $currentUserRole, ')
          ..write('memberCount: $memberCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    inviteCode,
    createdBy,
    currentUserRole,
    memberCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalHome &&
          other.id == this.id &&
          other.name == this.name &&
          other.inviteCode == this.inviteCode &&
          other.createdBy == this.createdBy &&
          other.currentUserRole == this.currentUserRole &&
          other.memberCount == this.memberCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalHomesCompanion extends UpdateCompanion<LocalHome> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> inviteCode;
  final Value<String?> createdBy;
  final Value<String> currentUserRole;
  final Value<int> memberCount;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalHomesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.currentUserRole = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalHomesCompanion.insert({
    required String id,
    required String name,
    required String inviteCode,
    this.createdBy = const Value.absent(),
    this.currentUserRole = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       inviteCode = Value(inviteCode);
  static Insertable<LocalHome> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? inviteCode,
    Expression<String>? createdBy,
    Expression<String>? currentUserRole,
    Expression<int>? memberCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (createdBy != null) 'created_by': createdBy,
      if (currentUserRole != null) 'current_user_role': currentUserRole,
      if (memberCount != null) 'member_count': memberCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalHomesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? inviteCode,
    Value<String?>? createdBy,
    Value<String>? currentUserRole,
    Value<int>? memberCount,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalHomesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (inviteCode.present) {
      map['invite_code'] = Variable<String>(inviteCode.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (currentUserRole.present) {
      map['current_user_role'] = Variable<String>(currentUserRole.value);
    }
    if (memberCount.present) {
      map['member_count'] = Variable<int>(memberCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalHomesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('createdBy: $createdBy, ')
          ..write('currentUserRole: $currentUserRole, ')
          ..write('memberCount: $memberCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalHomeMembersTable extends LocalHomeMembers
    with TableInfo<$LocalHomeMembersTable, LocalHomeMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalHomeMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<String> joinedAt = GeneratedColumn<String>(
    'joined_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    homeId,
    userId,
    fullName,
    email,
    avatarUrl,
    role,
    joinedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_home_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalHomeMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalHomeMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalHomeMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}joined_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalHomeMembersTable createAlias(String alias) {
    return $LocalHomeMembersTable(attachedDatabase, alias);
  }
}

class LocalHomeMember extends DataClass implements Insertable<LocalHomeMember> {
  final String id;
  final String homeId;
  final String userId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String role;
  final String? joinedAt;
  final DateTime? updatedAt;
  const LocalHomeMember({
    required this.id,
    required this.homeId,
    required this.userId,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.joinedAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['home_id'] = Variable<String>(homeId);
    map['user_id'] = Variable<String>(userId);
    map['full_name'] = Variable<String>(fullName);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || joinedAt != null) {
      map['joined_at'] = Variable<String>(joinedAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalHomeMembersCompanion toCompanion(bool nullToAbsent) {
    return LocalHomeMembersCompanion(
      id: Value(id),
      homeId: Value(homeId),
      userId: Value(userId),
      fullName: Value(fullName),
      email: Value(email),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      role: Value(role),
      joinedAt: joinedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(joinedAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalHomeMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalHomeMember(
      id: serializer.fromJson<String>(json['id']),
      homeId: serializer.fromJson<String>(json['homeId']),
      userId: serializer.fromJson<String>(json['userId']),
      fullName: serializer.fromJson<String>(json['fullName']),
      email: serializer.fromJson<String>(json['email']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      role: serializer.fromJson<String>(json['role']),
      joinedAt: serializer.fromJson<String?>(json['joinedAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'homeId': serializer.toJson<String>(homeId),
      'userId': serializer.toJson<String>(userId),
      'fullName': serializer.toJson<String>(fullName),
      'email': serializer.toJson<String>(email),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'role': serializer.toJson<String>(role),
      'joinedAt': serializer.toJson<String?>(joinedAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalHomeMember copyWith({
    String? id,
    String? homeId,
    String? userId,
    String? fullName,
    String? email,
    Value<String?> avatarUrl = const Value.absent(),
    String? role,
    Value<String?> joinedAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalHomeMember(
    id: id ?? this.id,
    homeId: homeId ?? this.homeId,
    userId: userId ?? this.userId,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    role: role ?? this.role,
    joinedAt: joinedAt.present ? joinedAt.value : this.joinedAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalHomeMember copyWithCompanion(LocalHomeMembersCompanion data) {
    return LocalHomeMember(
      id: data.id.present ? data.id.value : this.id,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      userId: data.userId.present ? data.userId.value : this.userId,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      email: data.email.present ? data.email.value : this.email,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      role: data.role.present ? data.role.value : this.role,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalHomeMember(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('userId: $userId, ')
          ..write('fullName: $fullName, ')
          ..write('email: $email, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    homeId,
    userId,
    fullName,
    email,
    avatarUrl,
    role,
    joinedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalHomeMember &&
          other.id == this.id &&
          other.homeId == this.homeId &&
          other.userId == this.userId &&
          other.fullName == this.fullName &&
          other.email == this.email &&
          other.avatarUrl == this.avatarUrl &&
          other.role == this.role &&
          other.joinedAt == this.joinedAt &&
          other.updatedAt == this.updatedAt);
}

class LocalHomeMembersCompanion extends UpdateCompanion<LocalHomeMember> {
  final Value<String> id;
  final Value<String> homeId;
  final Value<String> userId;
  final Value<String> fullName;
  final Value<String> email;
  final Value<String?> avatarUrl;
  final Value<String> role;
  final Value<String?> joinedAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalHomeMembersCompanion({
    this.id = const Value.absent(),
    this.homeId = const Value.absent(),
    this.userId = const Value.absent(),
    this.fullName = const Value.absent(),
    this.email = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.role = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalHomeMembersCompanion.insert({
    required String id,
    required String homeId,
    required String userId,
    required String fullName,
    required String email,
    this.avatarUrl = const Value.absent(),
    required String role,
    this.joinedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       homeId = Value(homeId),
       userId = Value(userId),
       fullName = Value(fullName),
       email = Value(email),
       role = Value(role);
  static Insertable<LocalHomeMember> custom({
    Expression<String>? id,
    Expression<String>? homeId,
    Expression<String>? userId,
    Expression<String>? fullName,
    Expression<String>? email,
    Expression<String>? avatarUrl,
    Expression<String>? role,
    Expression<String>? joinedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeId != null) 'home_id': homeId,
      if (userId != null) 'user_id': userId,
      if (fullName != null) 'full_name': fullName,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (role != null) 'role': role,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalHomeMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? homeId,
    Value<String>? userId,
    Value<String>? fullName,
    Value<String>? email,
    Value<String?>? avatarUrl,
    Value<String>? role,
    Value<String?>? joinedAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalHomeMembersCompanion(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<String>(joinedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalHomeMembersCompanion(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('userId: $userId, ')
          ..write('fullName: $fullName, ')
          ..write('email: $email, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCategoriesTable extends LocalCategories
    with TableInfo<$LocalCategoriesTable, LocalCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconNameMeta = const VerificationMeta(
    'iconName',
  );
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('category'),
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#6366F1'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    homeId,
    name,
    iconName,
    colorHex,
    sortOrder,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(
        _iconNameMeta,
        iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalCategoriesTable createAlias(String alias) {
    return $LocalCategoriesTable(attachedDatabase, alias);
  }
}

class LocalCategory extends DataClass implements Insertable<LocalCategory> {
  final String id;
  final String homeId;
  final String name;
  final String iconName;
  final String colorHex;
  final int sortOrder;
  final DateTime? updatedAt;
  const LocalCategory({
    required this.id,
    required this.homeId,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.sortOrder,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['home_id'] = Variable<String>(homeId);
    map['name'] = Variable<String>(name);
    map['icon_name'] = Variable<String>(iconName);
    map['color_hex'] = Variable<String>(colorHex);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalCategoriesCompanion toCompanion(bool nullToAbsent) {
    return LocalCategoriesCompanion(
      id: Value(id),
      homeId: Value(homeId),
      name: Value(name),
      iconName: Value(iconName),
      colorHex: Value(colorHex),
      sortOrder: Value(sortOrder),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCategory(
      id: serializer.fromJson<String>(json['id']),
      homeId: serializer.fromJson<String>(json['homeId']),
      name: serializer.fromJson<String>(json['name']),
      iconName: serializer.fromJson<String>(json['iconName']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'homeId': serializer.toJson<String>(homeId),
      'name': serializer.toJson<String>(name),
      'iconName': serializer.toJson<String>(iconName),
      'colorHex': serializer.toJson<String>(colorHex),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalCategory copyWith({
    String? id,
    String? homeId,
    String? name,
    String? iconName,
    String? colorHex,
    int? sortOrder,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalCategory(
    id: id ?? this.id,
    homeId: homeId ?? this.homeId,
    name: name ?? this.name,
    iconName: iconName ?? this.iconName,
    colorHex: colorHex ?? this.colorHex,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalCategory copyWithCompanion(LocalCategoriesCompanion data) {
    return LocalCategory(
      id: data.id.present ? data.id.value : this.id,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      name: data.name.present ? data.name.value : this.name,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategory(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('colorHex: $colorHex, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, homeId, name, iconName, colorHex, sortOrder, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCategory &&
          other.id == this.id &&
          other.homeId == this.homeId &&
          other.name == this.name &&
          other.iconName == this.iconName &&
          other.colorHex == this.colorHex &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt);
}

class LocalCategoriesCompanion extends UpdateCompanion<LocalCategory> {
  final Value<String> id;
  final Value<String> homeId;
  final Value<String> name;
  final Value<String> iconName;
  final Value<String> colorHex;
  final Value<int> sortOrder;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalCategoriesCompanion({
    this.id = const Value.absent(),
    this.homeId = const Value.absent(),
    this.name = const Value.absent(),
    this.iconName = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCategoriesCompanion.insert({
    required String id,
    required String homeId,
    required String name,
    this.iconName = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       homeId = Value(homeId),
       name = Value(name);
  static Insertable<LocalCategory> custom({
    Expression<String>? id,
    Expression<String>? homeId,
    Expression<String>? name,
    Expression<String>? iconName,
    Expression<String>? colorHex,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeId != null) 'home_id': homeId,
      if (name != null) 'name': name,
      if (iconName != null) 'icon_name': iconName,
      if (colorHex != null) 'color_hex': colorHex,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? homeId,
    Value<String>? name,
    Value<String>? iconName,
    Value<String>? colorHex,
    Value<int>? sortOrder,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalCategoriesCompanion(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('colorHex: $colorHex, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalInventoryItemsTable extends LocalInventoryItems
    with TableInfo<$LocalInventoryItemsTable, LocalInventoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalInventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('General'),
  );
  static const VerificationMeta _categoryIconMeta = const VerificationMeta(
    'categoryIcon',
  );
  @override
  late final GeneratedColumn<String> categoryIcon = GeneratedColumn<String>(
    'category_icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('category'),
  );
  static const VerificationMeta _categoryColorMeta = const VerificationMeta(
    'categoryColor',
  );
  @override
  late final GeneratedColumn<String> categoryColor = GeneratedColumn<String>(
    'category_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#6366F1'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pcs'),
  );
  static const VerificationMeta _minimumQuantityMeta = const VerificationMeta(
    'minimumQuantity',
  );
  @override
  late final GeneratedColumn<double> minimumQuantity = GeneratedColumn<double>(
    'minimum_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _maximumQuantityMeta = const VerificationMeta(
    'maximumQuantity',
  );
  @override
  late final GeneratedColumn<double> maximumQuantity = GeneratedColumn<double>(
    'maximum_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storageLocationMeta = const VerificationMeta(
    'storageLocation',
  );
  @override
  late final GeneratedColumn<String> storageLocation = GeneratedColumn<String>(
    'storage_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePriceMeta = const VerificationMeta(
    'purchasePrice',
  );
  @override
  late final GeneratedColumn<double> purchasePrice = GeneratedColumn<double>(
    'purchase_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<String> purchaseDate = GeneratedColumn<String>(
    'purchase_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<String> expiryDate = GeneratedColumn<String>(
    'expiry_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockStatusMeta = const VerificationMeta(
    'stockStatus',
  );
  @override
  late final GeneratedColumn<String> stockStatus = GeneratedColumn<String>(
    'stock_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('IN_STOCK'),
  );
  static const VerificationMeta _expiryStatusMeta = const VerificationMeta(
    'expiryStatus',
  );
  @override
  late final GeneratedColumn<String> expiryStatus = GeneratedColumn<String>(
    'expiry_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('SAFE'),
  );
  static const VerificationMeta _daysUntilExpiryMeta = const VerificationMeta(
    'daysUntilExpiry',
  );
  @override
  late final GeneratedColumn<int> daysUntilExpiry = GeneratedColumn<int>(
    'days_until_expiry',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityStatusMeta = const VerificationMeta(
    'quantityStatus',
  );
  @override
  late final GeneratedColumn<String> quantityStatus = GeneratedColumn<String>(
    'quantity_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantitySourceMeta = const VerificationMeta(
    'quantitySource',
  );
  @override
  late final GeneratedColumn<String> quantitySource = GeneratedColumn<String>(
    'quantity_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('VERIFIED'),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('HIGH'),
  );
  static const VerificationMeta _estimatedDaysRemainingMeta =
      const VerificationMeta('estimatedDaysRemaining');
  @override
  late final GeneratedColumn<int> estimatedDaysRemaining = GeneratedColumn<int>(
    'estimated_days_remaining',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedDailyConsumptionMeta =
      const VerificationMeta('estimatedDailyConsumption');
  @override
  late final GeneratedColumn<double> estimatedDailyConsumption =
      GeneratedColumn<double>(
        'estimated_daily_consumption',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastVerifiedAtMeta = const VerificationMeta(
    'lastVerifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastVerifiedAt =
      GeneratedColumn<DateTime>(
        'last_verified_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastEstimatedAtMeta = const VerificationMeta(
    'lastEstimatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastEstimatedAt =
      GeneratedColumn<DateTime>(
        'last_estimated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isLocalOnlyMeta = const VerificationMeta(
    'isLocalOnly',
  );
  @override
  late final GeneratedColumn<bool> isLocalOnly = GeneratedColumn<bool>(
    'is_local_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    homeId,
    categoryId,
    categoryName,
    categoryIcon,
    categoryColor,
    name,
    brand,
    quantity,
    unit,
    minimumQuantity,
    maximumQuantity,
    storageLocation,
    purchasePrice,
    purchaseDate,
    expiryDate,
    imageUrl,
    notes,
    stockStatus,
    expiryStatus,
    daysUntilExpiry,
    barcode,
    productId,
    quantityStatus,
    quantitySource,
    confidence,
    estimatedDaysRemaining,
    estimatedDailyConsumption,
    lastVerifiedAt,
    lastEstimatedAt,
    isDeleted,
    isLocalOnly,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_inventory_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalInventoryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('category_icon')) {
      context.handle(
        _categoryIconMeta,
        categoryIcon.isAcceptableOrUnknown(
          data['category_icon']!,
          _categoryIconMeta,
        ),
      );
    }
    if (data.containsKey('category_color')) {
      context.handle(
        _categoryColorMeta,
        categoryColor.isAcceptableOrUnknown(
          data['category_color']!,
          _categoryColorMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('minimum_quantity')) {
      context.handle(
        _minimumQuantityMeta,
        minimumQuantity.isAcceptableOrUnknown(
          data['minimum_quantity']!,
          _minimumQuantityMeta,
        ),
      );
    }
    if (data.containsKey('maximum_quantity')) {
      context.handle(
        _maximumQuantityMeta,
        maximumQuantity.isAcceptableOrUnknown(
          data['maximum_quantity']!,
          _maximumQuantityMeta,
        ),
      );
    }
    if (data.containsKey('storage_location')) {
      context.handle(
        _storageLocationMeta,
        storageLocation.isAcceptableOrUnknown(
          data['storage_location']!,
          _storageLocationMeta,
        ),
      );
    }
    if (data.containsKey('purchase_price')) {
      context.handle(
        _purchasePriceMeta,
        purchasePrice.isAcceptableOrUnknown(
          data['purchase_price']!,
          _purchasePriceMeta,
        ),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('stock_status')) {
      context.handle(
        _stockStatusMeta,
        stockStatus.isAcceptableOrUnknown(
          data['stock_status']!,
          _stockStatusMeta,
        ),
      );
    }
    if (data.containsKey('expiry_status')) {
      context.handle(
        _expiryStatusMeta,
        expiryStatus.isAcceptableOrUnknown(
          data['expiry_status']!,
          _expiryStatusMeta,
        ),
      );
    }
    if (data.containsKey('days_until_expiry')) {
      context.handle(
        _daysUntilExpiryMeta,
        daysUntilExpiry.isAcceptableOrUnknown(
          data['days_until_expiry']!,
          _daysUntilExpiryMeta,
        ),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('quantity_status')) {
      context.handle(
        _quantityStatusMeta,
        quantityStatus.isAcceptableOrUnknown(
          data['quantity_status']!,
          _quantityStatusMeta,
        ),
      );
    }
    if (data.containsKey('quantity_source')) {
      context.handle(
        _quantitySourceMeta,
        quantitySource.isAcceptableOrUnknown(
          data['quantity_source']!,
          _quantitySourceMeta,
        ),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('estimated_days_remaining')) {
      context.handle(
        _estimatedDaysRemainingMeta,
        estimatedDaysRemaining.isAcceptableOrUnknown(
          data['estimated_days_remaining']!,
          _estimatedDaysRemainingMeta,
        ),
      );
    }
    if (data.containsKey('estimated_daily_consumption')) {
      context.handle(
        _estimatedDailyConsumptionMeta,
        estimatedDailyConsumption.isAcceptableOrUnknown(
          data['estimated_daily_consumption']!,
          _estimatedDailyConsumptionMeta,
        ),
      );
    }
    if (data.containsKey('last_verified_at')) {
      context.handle(
        _lastVerifiedAtMeta,
        lastVerifiedAt.isAcceptableOrUnknown(
          data['last_verified_at']!,
          _lastVerifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_estimated_at')) {
      context.handle(
        _lastEstimatedAtMeta,
        lastEstimatedAt.isAcceptableOrUnknown(
          data['last_estimated_at']!,
          _lastEstimatedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('is_local_only')) {
      context.handle(
        _isLocalOnlyMeta,
        isLocalOnly.isAcceptableOrUnknown(
          data['is_local_only']!,
          _isLocalOnlyMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalInventoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalInventoryItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      categoryIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_icon'],
      )!,
      categoryColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_color'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      minimumQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}minimum_quantity'],
      )!,
      maximumQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}maximum_quantity'],
      ),
      storageLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_location'],
      ),
      purchasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_price'],
      ),
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_date'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expiry_date'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      stockStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock_status'],
      )!,
      expiryStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expiry_status'],
      )!,
      daysUntilExpiry: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_until_expiry'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      quantityStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_status'],
      ),
      quantitySource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_source'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence'],
      )!,
      estimatedDaysRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_days_remaining'],
      ),
      estimatedDailyConsumption: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}estimated_daily_consumption'],
      ),
      lastVerifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_verified_at'],
      ),
      lastEstimatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_estimated_at'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      isLocalOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local_only'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalInventoryItemsTable createAlias(String alias) {
    return $LocalInventoryItemsTable(attachedDatabase, alias);
  }
}

class LocalInventoryItem extends DataClass
    implements Insertable<LocalInventoryItem> {
  final String id;
  final String homeId;
  final String? categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final String name;
  final String? brand;
  final double quantity;
  final String unit;
  final double minimumQuantity;
  final double? maximumQuantity;
  final String? storageLocation;
  final double? purchasePrice;
  final String? purchaseDate;
  final String? expiryDate;
  final String? imageUrl;
  final String? notes;
  final String stockStatus;
  final String expiryStatus;
  final int? daysUntilExpiry;
  final String? barcode;
  final String? productId;
  final String? quantityStatus;
  final String quantitySource;
  final String confidence;
  final int? estimatedDaysRemaining;
  final double? estimatedDailyConsumption;
  final DateTime? lastVerifiedAt;
  final DateTime? lastEstimatedAt;
  final bool isDeleted;

  /// True if this item was created locally and hasn't been synced yet
  final bool isLocalOnly;
  final DateTime? updatedAt;
  const LocalInventoryItem({
    required this.id,
    required this.homeId,
    this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.name,
    this.brand,
    required this.quantity,
    required this.unit,
    required this.minimumQuantity,
    this.maximumQuantity,
    this.storageLocation,
    this.purchasePrice,
    this.purchaseDate,
    this.expiryDate,
    this.imageUrl,
    this.notes,
    required this.stockStatus,
    required this.expiryStatus,
    this.daysUntilExpiry,
    this.barcode,
    this.productId,
    this.quantityStatus,
    required this.quantitySource,
    required this.confidence,
    this.estimatedDaysRemaining,
    this.estimatedDailyConsumption,
    this.lastVerifiedAt,
    this.lastEstimatedAt,
    required this.isDeleted,
    required this.isLocalOnly,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['home_id'] = Variable<String>(homeId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['category_name'] = Variable<String>(categoryName);
    map['category_icon'] = Variable<String>(categoryIcon);
    map['category_color'] = Variable<String>(categoryColor);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    map['minimum_quantity'] = Variable<double>(minimumQuantity);
    if (!nullToAbsent || maximumQuantity != null) {
      map['maximum_quantity'] = Variable<double>(maximumQuantity);
    }
    if (!nullToAbsent || storageLocation != null) {
      map['storage_location'] = Variable<String>(storageLocation);
    }
    if (!nullToAbsent || purchasePrice != null) {
      map['purchase_price'] = Variable<double>(purchasePrice);
    }
    if (!nullToAbsent || purchaseDate != null) {
      map['purchase_date'] = Variable<String>(purchaseDate);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<String>(expiryDate);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['stock_status'] = Variable<String>(stockStatus);
    map['expiry_status'] = Variable<String>(expiryStatus);
    if (!nullToAbsent || daysUntilExpiry != null) {
      map['days_until_expiry'] = Variable<int>(daysUntilExpiry);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || quantityStatus != null) {
      map['quantity_status'] = Variable<String>(quantityStatus);
    }
    map['quantity_source'] = Variable<String>(quantitySource);
    map['confidence'] = Variable<String>(confidence);
    if (!nullToAbsent || estimatedDaysRemaining != null) {
      map['estimated_days_remaining'] = Variable<int>(estimatedDaysRemaining);
    }
    if (!nullToAbsent || estimatedDailyConsumption != null) {
      map['estimated_daily_consumption'] = Variable<double>(
        estimatedDailyConsumption,
      );
    }
    if (!nullToAbsent || lastVerifiedAt != null) {
      map['last_verified_at'] = Variable<DateTime>(lastVerifiedAt);
    }
    if (!nullToAbsent || lastEstimatedAt != null) {
      map['last_estimated_at'] = Variable<DateTime>(lastEstimatedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_local_only'] = Variable<bool>(isLocalOnly);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalInventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalInventoryItemsCompanion(
      id: Value(id),
      homeId: Value(homeId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryName: Value(categoryName),
      categoryIcon: Value(categoryIcon),
      categoryColor: Value(categoryColor),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      quantity: Value(quantity),
      unit: Value(unit),
      minimumQuantity: Value(minimumQuantity),
      maximumQuantity: maximumQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(maximumQuantity),
      storageLocation: storageLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(storageLocation),
      purchasePrice: purchasePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePrice),
      purchaseDate: purchaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDate),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      stockStatus: Value(stockStatus),
      expiryStatus: Value(expiryStatus),
      daysUntilExpiry: daysUntilExpiry == null && nullToAbsent
          ? const Value.absent()
          : Value(daysUntilExpiry),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      quantityStatus: quantityStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityStatus),
      quantitySource: Value(quantitySource),
      confidence: Value(confidence),
      estimatedDaysRemaining: estimatedDaysRemaining == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedDaysRemaining),
      estimatedDailyConsumption:
          estimatedDailyConsumption == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedDailyConsumption),
      lastVerifiedAt: lastVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerifiedAt),
      lastEstimatedAt: lastEstimatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEstimatedAt),
      isDeleted: Value(isDeleted),
      isLocalOnly: Value(isLocalOnly),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalInventoryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalInventoryItem(
      id: serializer.fromJson<String>(json['id']),
      homeId: serializer.fromJson<String>(json['homeId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      categoryIcon: serializer.fromJson<String>(json['categoryIcon']),
      categoryColor: serializer.fromJson<String>(json['categoryColor']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      minimumQuantity: serializer.fromJson<double>(json['minimumQuantity']),
      maximumQuantity: serializer.fromJson<double?>(json['maximumQuantity']),
      storageLocation: serializer.fromJson<String?>(json['storageLocation']),
      purchasePrice: serializer.fromJson<double?>(json['purchasePrice']),
      purchaseDate: serializer.fromJson<String?>(json['purchaseDate']),
      expiryDate: serializer.fromJson<String?>(json['expiryDate']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      notes: serializer.fromJson<String?>(json['notes']),
      stockStatus: serializer.fromJson<String>(json['stockStatus']),
      expiryStatus: serializer.fromJson<String>(json['expiryStatus']),
      daysUntilExpiry: serializer.fromJson<int?>(json['daysUntilExpiry']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      productId: serializer.fromJson<String?>(json['productId']),
      quantityStatus: serializer.fromJson<String?>(json['quantityStatus']),
      quantitySource: serializer.fromJson<String>(json['quantitySource']),
      confidence: serializer.fromJson<String>(json['confidence']),
      estimatedDaysRemaining: serializer.fromJson<int?>(
        json['estimatedDaysRemaining'],
      ),
      estimatedDailyConsumption: serializer.fromJson<double?>(
        json['estimatedDailyConsumption'],
      ),
      lastVerifiedAt: serializer.fromJson<DateTime?>(json['lastVerifiedAt']),
      lastEstimatedAt: serializer.fromJson<DateTime?>(json['lastEstimatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isLocalOnly: serializer.fromJson<bool>(json['isLocalOnly']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'homeId': serializer.toJson<String>(homeId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'categoryName': serializer.toJson<String>(categoryName),
      'categoryIcon': serializer.toJson<String>(categoryIcon),
      'categoryColor': serializer.toJson<String>(categoryColor),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'minimumQuantity': serializer.toJson<double>(minimumQuantity),
      'maximumQuantity': serializer.toJson<double?>(maximumQuantity),
      'storageLocation': serializer.toJson<String?>(storageLocation),
      'purchasePrice': serializer.toJson<double?>(purchasePrice),
      'purchaseDate': serializer.toJson<String?>(purchaseDate),
      'expiryDate': serializer.toJson<String?>(expiryDate),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'notes': serializer.toJson<String?>(notes),
      'stockStatus': serializer.toJson<String>(stockStatus),
      'expiryStatus': serializer.toJson<String>(expiryStatus),
      'daysUntilExpiry': serializer.toJson<int?>(daysUntilExpiry),
      'barcode': serializer.toJson<String?>(barcode),
      'productId': serializer.toJson<String?>(productId),
      'quantityStatus': serializer.toJson<String?>(quantityStatus),
      'quantitySource': serializer.toJson<String>(quantitySource),
      'confidence': serializer.toJson<String>(confidence),
      'estimatedDaysRemaining': serializer.toJson<int?>(estimatedDaysRemaining),
      'estimatedDailyConsumption': serializer.toJson<double?>(
        estimatedDailyConsumption,
      ),
      'lastVerifiedAt': serializer.toJson<DateTime?>(lastVerifiedAt),
      'lastEstimatedAt': serializer.toJson<DateTime?>(lastEstimatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isLocalOnly': serializer.toJson<bool>(isLocalOnly),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalInventoryItem copyWith({
    String? id,
    String? homeId,
    Value<String?> categoryId = const Value.absent(),
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? name,
    Value<String?> brand = const Value.absent(),
    double? quantity,
    String? unit,
    double? minimumQuantity,
    Value<double?> maximumQuantity = const Value.absent(),
    Value<String?> storageLocation = const Value.absent(),
    Value<double?> purchasePrice = const Value.absent(),
    Value<String?> purchaseDate = const Value.absent(),
    Value<String?> expiryDate = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? stockStatus,
    String? expiryStatus,
    Value<int?> daysUntilExpiry = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    Value<String?> productId = const Value.absent(),
    Value<String?> quantityStatus = const Value.absent(),
    String? quantitySource,
    String? confidence,
    Value<int?> estimatedDaysRemaining = const Value.absent(),
    Value<double?> estimatedDailyConsumption = const Value.absent(),
    Value<DateTime?> lastVerifiedAt = const Value.absent(),
    Value<DateTime?> lastEstimatedAt = const Value.absent(),
    bool? isDeleted,
    bool? isLocalOnly,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalInventoryItem(
    id: id ?? this.id,
    homeId: homeId ?? this.homeId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    categoryIcon: categoryIcon ?? this.categoryIcon,
    categoryColor: categoryColor ?? this.categoryColor,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    minimumQuantity: minimumQuantity ?? this.minimumQuantity,
    maximumQuantity: maximumQuantity.present
        ? maximumQuantity.value
        : this.maximumQuantity,
    storageLocation: storageLocation.present
        ? storageLocation.value
        : this.storageLocation,
    purchasePrice: purchasePrice.present
        ? purchasePrice.value
        : this.purchasePrice,
    purchaseDate: purchaseDate.present ? purchaseDate.value : this.purchaseDate,
    expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    notes: notes.present ? notes.value : this.notes,
    stockStatus: stockStatus ?? this.stockStatus,
    expiryStatus: expiryStatus ?? this.expiryStatus,
    daysUntilExpiry: daysUntilExpiry.present
        ? daysUntilExpiry.value
        : this.daysUntilExpiry,
    barcode: barcode.present ? barcode.value : this.barcode,
    productId: productId.present ? productId.value : this.productId,
    quantityStatus: quantityStatus.present
        ? quantityStatus.value
        : this.quantityStatus,
    quantitySource: quantitySource ?? this.quantitySource,
    confidence: confidence ?? this.confidence,
    estimatedDaysRemaining: estimatedDaysRemaining.present
        ? estimatedDaysRemaining.value
        : this.estimatedDaysRemaining,
    estimatedDailyConsumption: estimatedDailyConsumption.present
        ? estimatedDailyConsumption.value
        : this.estimatedDailyConsumption,
    lastVerifiedAt: lastVerifiedAt.present
        ? lastVerifiedAt.value
        : this.lastVerifiedAt,
    lastEstimatedAt: lastEstimatedAt.present
        ? lastEstimatedAt.value
        : this.lastEstimatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    isLocalOnly: isLocalOnly ?? this.isLocalOnly,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalInventoryItem copyWithCompanion(LocalInventoryItemsCompanion data) {
    return LocalInventoryItem(
      id: data.id.present ? data.id.value : this.id,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      categoryIcon: data.categoryIcon.present
          ? data.categoryIcon.value
          : this.categoryIcon,
      categoryColor: data.categoryColor.present
          ? data.categoryColor.value
          : this.categoryColor,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      minimumQuantity: data.minimumQuantity.present
          ? data.minimumQuantity.value
          : this.minimumQuantity,
      maximumQuantity: data.maximumQuantity.present
          ? data.maximumQuantity.value
          : this.maximumQuantity,
      storageLocation: data.storageLocation.present
          ? data.storageLocation.value
          : this.storageLocation,
      purchasePrice: data.purchasePrice.present
          ? data.purchasePrice.value
          : this.purchasePrice,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      notes: data.notes.present ? data.notes.value : this.notes,
      stockStatus: data.stockStatus.present
          ? data.stockStatus.value
          : this.stockStatus,
      expiryStatus: data.expiryStatus.present
          ? data.expiryStatus.value
          : this.expiryStatus,
      daysUntilExpiry: data.daysUntilExpiry.present
          ? data.daysUntilExpiry.value
          : this.daysUntilExpiry,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantityStatus: data.quantityStatus.present
          ? data.quantityStatus.value
          : this.quantityStatus,
      quantitySource: data.quantitySource.present
          ? data.quantitySource.value
          : this.quantitySource,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      estimatedDaysRemaining: data.estimatedDaysRemaining.present
          ? data.estimatedDaysRemaining.value
          : this.estimatedDaysRemaining,
      estimatedDailyConsumption: data.estimatedDailyConsumption.present
          ? data.estimatedDailyConsumption.value
          : this.estimatedDailyConsumption,
      lastVerifiedAt: data.lastVerifiedAt.present
          ? data.lastVerifiedAt.value
          : this.lastVerifiedAt,
      lastEstimatedAt: data.lastEstimatedAt.present
          ? data.lastEstimatedAt.value
          : this.lastEstimatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isLocalOnly: data.isLocalOnly.present
          ? data.isLocalOnly.value
          : this.isLocalOnly,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryItem(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryIcon: $categoryIcon, ')
          ..write('categoryColor: $categoryColor, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('minimumQuantity: $minimumQuantity, ')
          ..write('maximumQuantity: $maximumQuantity, ')
          ..write('storageLocation: $storageLocation, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('notes: $notes, ')
          ..write('stockStatus: $stockStatus, ')
          ..write('expiryStatus: $expiryStatus, ')
          ..write('daysUntilExpiry: $daysUntilExpiry, ')
          ..write('barcode: $barcode, ')
          ..write('productId: $productId, ')
          ..write('quantityStatus: $quantityStatus, ')
          ..write('quantitySource: $quantitySource, ')
          ..write('confidence: $confidence, ')
          ..write('estimatedDaysRemaining: $estimatedDaysRemaining, ')
          ..write('estimatedDailyConsumption: $estimatedDailyConsumption, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('lastEstimatedAt: $lastEstimatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isLocalOnly: $isLocalOnly, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    homeId,
    categoryId,
    categoryName,
    categoryIcon,
    categoryColor,
    name,
    brand,
    quantity,
    unit,
    minimumQuantity,
    maximumQuantity,
    storageLocation,
    purchasePrice,
    purchaseDate,
    expiryDate,
    imageUrl,
    notes,
    stockStatus,
    expiryStatus,
    daysUntilExpiry,
    barcode,
    productId,
    quantityStatus,
    quantitySource,
    confidence,
    estimatedDaysRemaining,
    estimatedDailyConsumption,
    lastVerifiedAt,
    lastEstimatedAt,
    isDeleted,
    isLocalOnly,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalInventoryItem &&
          other.id == this.id &&
          other.homeId == this.homeId &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.categoryIcon == this.categoryIcon &&
          other.categoryColor == this.categoryColor &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.minimumQuantity == this.minimumQuantity &&
          other.maximumQuantity == this.maximumQuantity &&
          other.storageLocation == this.storageLocation &&
          other.purchasePrice == this.purchasePrice &&
          other.purchaseDate == this.purchaseDate &&
          other.expiryDate == this.expiryDate &&
          other.imageUrl == this.imageUrl &&
          other.notes == this.notes &&
          other.stockStatus == this.stockStatus &&
          other.expiryStatus == this.expiryStatus &&
          other.daysUntilExpiry == this.daysUntilExpiry &&
          other.barcode == this.barcode &&
          other.productId == this.productId &&
          other.quantityStatus == this.quantityStatus &&
          other.quantitySource == this.quantitySource &&
          other.confidence == this.confidence &&
          other.estimatedDaysRemaining == this.estimatedDaysRemaining &&
          other.estimatedDailyConsumption == this.estimatedDailyConsumption &&
          other.lastVerifiedAt == this.lastVerifiedAt &&
          other.lastEstimatedAt == this.lastEstimatedAt &&
          other.isDeleted == this.isDeleted &&
          other.isLocalOnly == this.isLocalOnly &&
          other.updatedAt == this.updatedAt);
}

class LocalInventoryItemsCompanion extends UpdateCompanion<LocalInventoryItem> {
  final Value<String> id;
  final Value<String> homeId;
  final Value<String?> categoryId;
  final Value<String> categoryName;
  final Value<String> categoryIcon;
  final Value<String> categoryColor;
  final Value<String> name;
  final Value<String?> brand;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<double> minimumQuantity;
  final Value<double?> maximumQuantity;
  final Value<String?> storageLocation;
  final Value<double?> purchasePrice;
  final Value<String?> purchaseDate;
  final Value<String?> expiryDate;
  final Value<String?> imageUrl;
  final Value<String?> notes;
  final Value<String> stockStatus;
  final Value<String> expiryStatus;
  final Value<int?> daysUntilExpiry;
  final Value<String?> barcode;
  final Value<String?> productId;
  final Value<String?> quantityStatus;
  final Value<String> quantitySource;
  final Value<String> confidence;
  final Value<int?> estimatedDaysRemaining;
  final Value<double?> estimatedDailyConsumption;
  final Value<DateTime?> lastVerifiedAt;
  final Value<DateTime?> lastEstimatedAt;
  final Value<bool> isDeleted;
  final Value<bool> isLocalOnly;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalInventoryItemsCompanion({
    this.id = const Value.absent(),
    this.homeId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryIcon = const Value.absent(),
    this.categoryColor = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.minimumQuantity = const Value.absent(),
    this.maximumQuantity = const Value.absent(),
    this.storageLocation = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.notes = const Value.absent(),
    this.stockStatus = const Value.absent(),
    this.expiryStatus = const Value.absent(),
    this.daysUntilExpiry = const Value.absent(),
    this.barcode = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantityStatus = const Value.absent(),
    this.quantitySource = const Value.absent(),
    this.confidence = const Value.absent(),
    this.estimatedDaysRemaining = const Value.absent(),
    this.estimatedDailyConsumption = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.lastEstimatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isLocalOnly = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalInventoryItemsCompanion.insert({
    required String id,
    required String homeId,
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryIcon = const Value.absent(),
    this.categoryColor = const Value.absent(),
    required String name,
    this.brand = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.minimumQuantity = const Value.absent(),
    this.maximumQuantity = const Value.absent(),
    this.storageLocation = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.notes = const Value.absent(),
    this.stockStatus = const Value.absent(),
    this.expiryStatus = const Value.absent(),
    this.daysUntilExpiry = const Value.absent(),
    this.barcode = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantityStatus = const Value.absent(),
    this.quantitySource = const Value.absent(),
    this.confidence = const Value.absent(),
    this.estimatedDaysRemaining = const Value.absent(),
    this.estimatedDailyConsumption = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.lastEstimatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isLocalOnly = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       homeId = Value(homeId),
       name = Value(name);
  static Insertable<LocalInventoryItem> custom({
    Expression<String>? id,
    Expression<String>? homeId,
    Expression<String>? categoryId,
    Expression<String>? categoryName,
    Expression<String>? categoryIcon,
    Expression<String>? categoryColor,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<double>? minimumQuantity,
    Expression<double>? maximumQuantity,
    Expression<String>? storageLocation,
    Expression<double>? purchasePrice,
    Expression<String>? purchaseDate,
    Expression<String>? expiryDate,
    Expression<String>? imageUrl,
    Expression<String>? notes,
    Expression<String>? stockStatus,
    Expression<String>? expiryStatus,
    Expression<int>? daysUntilExpiry,
    Expression<String>? barcode,
    Expression<String>? productId,
    Expression<String>? quantityStatus,
    Expression<String>? quantitySource,
    Expression<String>? confidence,
    Expression<int>? estimatedDaysRemaining,
    Expression<double>? estimatedDailyConsumption,
    Expression<DateTime>? lastVerifiedAt,
    Expression<DateTime>? lastEstimatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? isLocalOnly,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeId != null) 'home_id': homeId,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (categoryIcon != null) 'category_icon': categoryIcon,
      if (categoryColor != null) 'category_color': categoryColor,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (minimumQuantity != null) 'minimum_quantity': minimumQuantity,
      if (maximumQuantity != null) 'maximum_quantity': maximumQuantity,
      if (storageLocation != null) 'storage_location': storageLocation,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (imageUrl != null) 'image_url': imageUrl,
      if (notes != null) 'notes': notes,
      if (stockStatus != null) 'stock_status': stockStatus,
      if (expiryStatus != null) 'expiry_status': expiryStatus,
      if (daysUntilExpiry != null) 'days_until_expiry': daysUntilExpiry,
      if (barcode != null) 'barcode': barcode,
      if (productId != null) 'product_id': productId,
      if (quantityStatus != null) 'quantity_status': quantityStatus,
      if (quantitySource != null) 'quantity_source': quantitySource,
      if (confidence != null) 'confidence': confidence,
      if (estimatedDaysRemaining != null)
        'estimated_days_remaining': estimatedDaysRemaining,
      if (estimatedDailyConsumption != null)
        'estimated_daily_consumption': estimatedDailyConsumption,
      if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
      if (lastEstimatedAt != null) 'last_estimated_at': lastEstimatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isLocalOnly != null) 'is_local_only': isLocalOnly,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalInventoryItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? homeId,
    Value<String?>? categoryId,
    Value<String>? categoryName,
    Value<String>? categoryIcon,
    Value<String>? categoryColor,
    Value<String>? name,
    Value<String?>? brand,
    Value<double>? quantity,
    Value<String>? unit,
    Value<double>? minimumQuantity,
    Value<double?>? maximumQuantity,
    Value<String?>? storageLocation,
    Value<double?>? purchasePrice,
    Value<String?>? purchaseDate,
    Value<String?>? expiryDate,
    Value<String?>? imageUrl,
    Value<String?>? notes,
    Value<String>? stockStatus,
    Value<String>? expiryStatus,
    Value<int?>? daysUntilExpiry,
    Value<String?>? barcode,
    Value<String?>? productId,
    Value<String?>? quantityStatus,
    Value<String>? quantitySource,
    Value<String>? confidence,
    Value<int?>? estimatedDaysRemaining,
    Value<double?>? estimatedDailyConsumption,
    Value<DateTime?>? lastVerifiedAt,
    Value<DateTime?>? lastEstimatedAt,
    Value<bool>? isDeleted,
    Value<bool>? isLocalOnly,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalInventoryItemsCompanion(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      maximumQuantity: maximumQuantity ?? this.maximumQuantity,
      storageLocation: storageLocation ?? this.storageLocation,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      stockStatus: stockStatus ?? this.stockStatus,
      expiryStatus: expiryStatus ?? this.expiryStatus,
      daysUntilExpiry: daysUntilExpiry ?? this.daysUntilExpiry,
      barcode: barcode ?? this.barcode,
      productId: productId ?? this.productId,
      quantityStatus: quantityStatus ?? this.quantityStatus,
      quantitySource: quantitySource ?? this.quantitySource,
      confidence: confidence ?? this.confidence,
      estimatedDaysRemaining:
          estimatedDaysRemaining ?? this.estimatedDaysRemaining,
      estimatedDailyConsumption:
          estimatedDailyConsumption ?? this.estimatedDailyConsumption,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      lastEstimatedAt: lastEstimatedAt ?? this.lastEstimatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (categoryIcon.present) {
      map['category_icon'] = Variable<String>(categoryIcon.value);
    }
    if (categoryColor.present) {
      map['category_color'] = Variable<String>(categoryColor.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (minimumQuantity.present) {
      map['minimum_quantity'] = Variable<double>(minimumQuantity.value);
    }
    if (maximumQuantity.present) {
      map['maximum_quantity'] = Variable<double>(maximumQuantity.value);
    }
    if (storageLocation.present) {
      map['storage_location'] = Variable<String>(storageLocation.value);
    }
    if (purchasePrice.present) {
      map['purchase_price'] = Variable<double>(purchasePrice.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<String>(purchaseDate.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<String>(expiryDate.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (stockStatus.present) {
      map['stock_status'] = Variable<String>(stockStatus.value);
    }
    if (expiryStatus.present) {
      map['expiry_status'] = Variable<String>(expiryStatus.value);
    }
    if (daysUntilExpiry.present) {
      map['days_until_expiry'] = Variable<int>(daysUntilExpiry.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantityStatus.present) {
      map['quantity_status'] = Variable<String>(quantityStatus.value);
    }
    if (quantitySource.present) {
      map['quantity_source'] = Variable<String>(quantitySource.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (estimatedDaysRemaining.present) {
      map['estimated_days_remaining'] = Variable<int>(
        estimatedDaysRemaining.value,
      );
    }
    if (estimatedDailyConsumption.present) {
      map['estimated_daily_consumption'] = Variable<double>(
        estimatedDailyConsumption.value,
      );
    }
    if (lastVerifiedAt.present) {
      map['last_verified_at'] = Variable<DateTime>(lastVerifiedAt.value);
    }
    if (lastEstimatedAt.present) {
      map['last_estimated_at'] = Variable<DateTime>(lastEstimatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isLocalOnly.present) {
      map['is_local_only'] = Variable<bool>(isLocalOnly.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryIcon: $categoryIcon, ')
          ..write('categoryColor: $categoryColor, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('minimumQuantity: $minimumQuantity, ')
          ..write('maximumQuantity: $maximumQuantity, ')
          ..write('storageLocation: $storageLocation, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('notes: $notes, ')
          ..write('stockStatus: $stockStatus, ')
          ..write('expiryStatus: $expiryStatus, ')
          ..write('daysUntilExpiry: $daysUntilExpiry, ')
          ..write('barcode: $barcode, ')
          ..write('productId: $productId, ')
          ..write('quantityStatus: $quantityStatus, ')
          ..write('quantitySource: $quantitySource, ')
          ..write('confidence: $confidence, ')
          ..write('estimatedDaysRemaining: $estimatedDaysRemaining, ')
          ..write('estimatedDailyConsumption: $estimatedDailyConsumption, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('lastEstimatedAt: $lastEstimatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isLocalOnly: $isLocalOnly, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStockTransactionsTable extends LocalStockTransactions
    with TableInfo<$LocalStockTransactionsTable, LocalStockTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStockTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventoryItemIdMeta = const VerificationMeta(
    'inventoryItemId',
  );
  @override
  late final GeneratedColumn<String> inventoryItemId = GeneratedColumn<String>(
    'inventory_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityChangeMeta = const VerificationMeta(
    'quantityChange',
  );
  @override
  late final GeneratedColumn<double> quantityChange = GeneratedColumn<double>(
    'quantity_change',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousQuantityMeta = const VerificationMeta(
    'previousQuantity',
  );
  @override
  late final GeneratedColumn<double> previousQuantity = GeneratedColumn<double>(
    'previous_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newQuantityMeta = const VerificationMeta(
    'newQuantity',
  );
  @override
  late final GeneratedColumn<double> newQuantity = GeneratedColumn<double>(
    'new_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pcs'),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLocalOnlyMeta = const VerificationMeta(
    'isLocalOnly',
  );
  @override
  late final GeneratedColumn<bool> isLocalOnly = GeneratedColumn<bool>(
    'is_local_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inventoryItemId,
    itemName,
    userName,
    transactionType,
    quantityChange,
    previousQuantity,
    newQuantity,
    unit,
    reason,
    createdAt,
    isLocalOnly,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_stock_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStockTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inventory_item_id')) {
      context.handle(
        _inventoryItemIdMeta,
        inventoryItemId.isAcceptableOrUnknown(
          data['inventory_item_id']!,
          _inventoryItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventoryItemIdMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('quantity_change')) {
      context.handle(
        _quantityChangeMeta,
        quantityChange.isAcceptableOrUnknown(
          data['quantity_change']!,
          _quantityChangeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityChangeMeta);
    }
    if (data.containsKey('previous_quantity')) {
      context.handle(
        _previousQuantityMeta,
        previousQuantity.isAcceptableOrUnknown(
          data['previous_quantity']!,
          _previousQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_previousQuantityMeta);
    }
    if (data.containsKey('new_quantity')) {
      context.handle(
        _newQuantityMeta,
        newQuantity.isAcceptableOrUnknown(
          data['new_quantity']!,
          _newQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_newQuantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_local_only')) {
      context.handle(
        _isLocalOnlyMeta,
        isLocalOnly.isAcceptableOrUnknown(
          data['is_local_only']!,
          _isLocalOnlyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStockTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStockTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inventoryItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_item_id'],
      )!,
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      quantityChange: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_change'],
      )!,
      previousQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}previous_quantity'],
      )!,
      newQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}new_quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      isLocalOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local_only'],
      )!,
    );
  }

  @override
  $LocalStockTransactionsTable createAlias(String alias) {
    return $LocalStockTransactionsTable(attachedDatabase, alias);
  }
}

class LocalStockTransaction extends DataClass
    implements Insertable<LocalStockTransaction> {
  final String id;
  final String inventoryItemId;
  final String itemName;
  final String userName;
  final String transactionType;
  final double quantityChange;
  final double previousQuantity;
  final double newQuantity;
  final String unit;
  final String? reason;
  final String createdAt;
  final bool isLocalOnly;
  const LocalStockTransaction({
    required this.id,
    required this.inventoryItemId,
    required this.itemName,
    required this.userName,
    required this.transactionType,
    required this.quantityChange,
    required this.previousQuantity,
    required this.newQuantity,
    required this.unit,
    this.reason,
    required this.createdAt,
    required this.isLocalOnly,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['inventory_item_id'] = Variable<String>(inventoryItemId);
    map['item_name'] = Variable<String>(itemName);
    map['user_name'] = Variable<String>(userName);
    map['transaction_type'] = Variable<String>(transactionType);
    map['quantity_change'] = Variable<double>(quantityChange);
    map['previous_quantity'] = Variable<double>(previousQuantity);
    map['new_quantity'] = Variable<double>(newQuantity);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['is_local_only'] = Variable<bool>(isLocalOnly);
    return map;
  }

  LocalStockTransactionsCompanion toCompanion(bool nullToAbsent) {
    return LocalStockTransactionsCompanion(
      id: Value(id),
      inventoryItemId: Value(inventoryItemId),
      itemName: Value(itemName),
      userName: Value(userName),
      transactionType: Value(transactionType),
      quantityChange: Value(quantityChange),
      previousQuantity: Value(previousQuantity),
      newQuantity: Value(newQuantity),
      unit: Value(unit),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      createdAt: Value(createdAt),
      isLocalOnly: Value(isLocalOnly),
    );
  }

  factory LocalStockTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStockTransaction(
      id: serializer.fromJson<String>(json['id']),
      inventoryItemId: serializer.fromJson<String>(json['inventoryItemId']),
      itemName: serializer.fromJson<String>(json['itemName']),
      userName: serializer.fromJson<String>(json['userName']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      quantityChange: serializer.fromJson<double>(json['quantityChange']),
      previousQuantity: serializer.fromJson<double>(json['previousQuantity']),
      newQuantity: serializer.fromJson<double>(json['newQuantity']),
      unit: serializer.fromJson<String>(json['unit']),
      reason: serializer.fromJson<String?>(json['reason']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      isLocalOnly: serializer.fromJson<bool>(json['isLocalOnly']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inventoryItemId': serializer.toJson<String>(inventoryItemId),
      'itemName': serializer.toJson<String>(itemName),
      'userName': serializer.toJson<String>(userName),
      'transactionType': serializer.toJson<String>(transactionType),
      'quantityChange': serializer.toJson<double>(quantityChange),
      'previousQuantity': serializer.toJson<double>(previousQuantity),
      'newQuantity': serializer.toJson<double>(newQuantity),
      'unit': serializer.toJson<String>(unit),
      'reason': serializer.toJson<String?>(reason),
      'createdAt': serializer.toJson<String>(createdAt),
      'isLocalOnly': serializer.toJson<bool>(isLocalOnly),
    };
  }

  LocalStockTransaction copyWith({
    String? id,
    String? inventoryItemId,
    String? itemName,
    String? userName,
    String? transactionType,
    double? quantityChange,
    double? previousQuantity,
    double? newQuantity,
    String? unit,
    Value<String?> reason = const Value.absent(),
    String? createdAt,
    bool? isLocalOnly,
  }) => LocalStockTransaction(
    id: id ?? this.id,
    inventoryItemId: inventoryItemId ?? this.inventoryItemId,
    itemName: itemName ?? this.itemName,
    userName: userName ?? this.userName,
    transactionType: transactionType ?? this.transactionType,
    quantityChange: quantityChange ?? this.quantityChange,
    previousQuantity: previousQuantity ?? this.previousQuantity,
    newQuantity: newQuantity ?? this.newQuantity,
    unit: unit ?? this.unit,
    reason: reason.present ? reason.value : this.reason,
    createdAt: createdAt ?? this.createdAt,
    isLocalOnly: isLocalOnly ?? this.isLocalOnly,
  );
  LocalStockTransaction copyWithCompanion(
    LocalStockTransactionsCompanion data,
  ) {
    return LocalStockTransaction(
      id: data.id.present ? data.id.value : this.id,
      inventoryItemId: data.inventoryItemId.present
          ? data.inventoryItemId.value
          : this.inventoryItemId,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      userName: data.userName.present ? data.userName.value : this.userName,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      quantityChange: data.quantityChange.present
          ? data.quantityChange.value
          : this.quantityChange,
      previousQuantity: data.previousQuantity.present
          ? data.previousQuantity.value
          : this.previousQuantity,
      newQuantity: data.newQuantity.present
          ? data.newQuantity.value
          : this.newQuantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isLocalOnly: data.isLocalOnly.present
          ? data.isLocalOnly.value
          : this.isLocalOnly,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockTransaction(')
          ..write('id: $id, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('itemName: $itemName, ')
          ..write('userName: $userName, ')
          ..write('transactionType: $transactionType, ')
          ..write('quantityChange: $quantityChange, ')
          ..write('previousQuantity: $previousQuantity, ')
          ..write('newQuantity: $newQuantity, ')
          ..write('unit: $unit, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('isLocalOnly: $isLocalOnly')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inventoryItemId,
    itemName,
    userName,
    transactionType,
    quantityChange,
    previousQuantity,
    newQuantity,
    unit,
    reason,
    createdAt,
    isLocalOnly,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStockTransaction &&
          other.id == this.id &&
          other.inventoryItemId == this.inventoryItemId &&
          other.itemName == this.itemName &&
          other.userName == this.userName &&
          other.transactionType == this.transactionType &&
          other.quantityChange == this.quantityChange &&
          other.previousQuantity == this.previousQuantity &&
          other.newQuantity == this.newQuantity &&
          other.unit == this.unit &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt &&
          other.isLocalOnly == this.isLocalOnly);
}

class LocalStockTransactionsCompanion
    extends UpdateCompanion<LocalStockTransaction> {
  final Value<String> id;
  final Value<String> inventoryItemId;
  final Value<String> itemName;
  final Value<String> userName;
  final Value<String> transactionType;
  final Value<double> quantityChange;
  final Value<double> previousQuantity;
  final Value<double> newQuantity;
  final Value<String> unit;
  final Value<String?> reason;
  final Value<String> createdAt;
  final Value<bool> isLocalOnly;
  final Value<int> rowid;
  const LocalStockTransactionsCompanion({
    this.id = const Value.absent(),
    this.inventoryItemId = const Value.absent(),
    this.itemName = const Value.absent(),
    this.userName = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.quantityChange = const Value.absent(),
    this.previousQuantity = const Value.absent(),
    this.newQuantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isLocalOnly = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStockTransactionsCompanion.insert({
    required String id,
    required String inventoryItemId,
    this.itemName = const Value.absent(),
    this.userName = const Value.absent(),
    required String transactionType,
    required double quantityChange,
    required double previousQuantity,
    required double newQuantity,
    this.unit = const Value.absent(),
    this.reason = const Value.absent(),
    required String createdAt,
    this.isLocalOnly = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inventoryItemId = Value(inventoryItemId),
       transactionType = Value(transactionType),
       quantityChange = Value(quantityChange),
       previousQuantity = Value(previousQuantity),
       newQuantity = Value(newQuantity),
       createdAt = Value(createdAt);
  static Insertable<LocalStockTransaction> custom({
    Expression<String>? id,
    Expression<String>? inventoryItemId,
    Expression<String>? itemName,
    Expression<String>? userName,
    Expression<String>? transactionType,
    Expression<double>? quantityChange,
    Expression<double>? previousQuantity,
    Expression<double>? newQuantity,
    Expression<String>? unit,
    Expression<String>? reason,
    Expression<String>? createdAt,
    Expression<bool>? isLocalOnly,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inventoryItemId != null) 'inventory_item_id': inventoryItemId,
      if (itemName != null) 'item_name': itemName,
      if (userName != null) 'user_name': userName,
      if (transactionType != null) 'transaction_type': transactionType,
      if (quantityChange != null) 'quantity_change': quantityChange,
      if (previousQuantity != null) 'previous_quantity': previousQuantity,
      if (newQuantity != null) 'new_quantity': newQuantity,
      if (unit != null) 'unit': unit,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (isLocalOnly != null) 'is_local_only': isLocalOnly,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStockTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? inventoryItemId,
    Value<String>? itemName,
    Value<String>? userName,
    Value<String>? transactionType,
    Value<double>? quantityChange,
    Value<double>? previousQuantity,
    Value<double>? newQuantity,
    Value<String>? unit,
    Value<String?>? reason,
    Value<String>? createdAt,
    Value<bool>? isLocalOnly,
    Value<int>? rowid,
  }) {
    return LocalStockTransactionsCompanion(
      id: id ?? this.id,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      itemName: itemName ?? this.itemName,
      userName: userName ?? this.userName,
      transactionType: transactionType ?? this.transactionType,
      quantityChange: quantityChange ?? this.quantityChange,
      previousQuantity: previousQuantity ?? this.previousQuantity,
      newQuantity: newQuantity ?? this.newQuantity,
      unit: unit ?? this.unit,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inventoryItemId.present) {
      map['inventory_item_id'] = Variable<String>(inventoryItemId.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (quantityChange.present) {
      map['quantity_change'] = Variable<double>(quantityChange.value);
    }
    if (previousQuantity.present) {
      map['previous_quantity'] = Variable<double>(previousQuantity.value);
    }
    if (newQuantity.present) {
      map['new_quantity'] = Variable<double>(newQuantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (isLocalOnly.present) {
      map['is_local_only'] = Variable<bool>(isLocalOnly.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('itemName: $itemName, ')
          ..write('userName: $userName, ')
          ..write('transactionType: $transactionType, ')
          ..write('quantityChange: $quantityChange, ')
          ..write('previousQuantity: $previousQuantity, ')
          ..write('newQuantity: $newQuantity, ')
          ..write('unit: $unit, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('isLocalOnly: $isLocalOnly, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalShoppingListsTable extends LocalShoppingLists
    with TableInfo<$LocalShoppingListsTable, LocalShoppingList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShoppingListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Home Shopping List'),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    homeId,
    name,
    isDefault,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shopping_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalShoppingList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalShoppingList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalShoppingList(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalShoppingListsTable createAlias(String alias) {
    return $LocalShoppingListsTable(attachedDatabase, alias);
  }
}

class LocalShoppingList extends DataClass
    implements Insertable<LocalShoppingList> {
  final String id;
  final String homeId;
  final String name;
  final bool isDefault;
  final DateTime? updatedAt;
  const LocalShoppingList({
    required this.id,
    required this.homeId,
    required this.name,
    required this.isDefault,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['home_id'] = Variable<String>(homeId);
    map['name'] = Variable<String>(name);
    map['is_default'] = Variable<bool>(isDefault);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalShoppingListsCompanion toCompanion(bool nullToAbsent) {
    return LocalShoppingListsCompanion(
      id: Value(id),
      homeId: Value(homeId),
      name: Value(name),
      isDefault: Value(isDefault),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalShoppingList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalShoppingList(
      id: serializer.fromJson<String>(json['id']),
      homeId: serializer.fromJson<String>(json['homeId']),
      name: serializer.fromJson<String>(json['name']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'homeId': serializer.toJson<String>(homeId),
      'name': serializer.toJson<String>(name),
      'isDefault': serializer.toJson<bool>(isDefault),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalShoppingList copyWith({
    String? id,
    String? homeId,
    String? name,
    bool? isDefault,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalShoppingList(
    id: id ?? this.id,
    homeId: homeId ?? this.homeId,
    name: name ?? this.name,
    isDefault: isDefault ?? this.isDefault,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalShoppingList copyWithCompanion(LocalShoppingListsCompanion data) {
    return LocalShoppingList(
      id: data.id.present ? data.id.value : this.id,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      name: data.name.present ? data.name.value : this.name,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingList(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, homeId, name, isDefault, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalShoppingList &&
          other.id == this.id &&
          other.homeId == this.homeId &&
          other.name == this.name &&
          other.isDefault == this.isDefault &&
          other.updatedAt == this.updatedAt);
}

class LocalShoppingListsCompanion extends UpdateCompanion<LocalShoppingList> {
  final Value<String> id;
  final Value<String> homeId;
  final Value<String> name;
  final Value<bool> isDefault;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalShoppingListsCompanion({
    this.id = const Value.absent(),
    this.homeId = const Value.absent(),
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShoppingListsCompanion.insert({
    required String id,
    required String homeId,
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       homeId = Value(homeId);
  static Insertable<LocalShoppingList> custom({
    Expression<String>? id,
    Expression<String>? homeId,
    Expression<String>? name,
    Expression<bool>? isDefault,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeId != null) 'home_id': homeId,
      if (name != null) 'name': name,
      if (isDefault != null) 'is_default': isDefault,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShoppingListsCompanion copyWith({
    Value<String>? id,
    Value<String>? homeId,
    Value<String>? name,
    Value<bool>? isDefault,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalShoppingListsCompanion(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingListsCompanion(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalShoppingListItemsTable extends LocalShoppingListItems
    with TableInfo<$LocalShoppingListItemsTable, LocalShoppingListItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShoppingListItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shoppingListIdMeta = const VerificationMeta(
    'shoppingListId',
  );
  @override
  late final GeneratedColumn<String> shoppingListId = GeneratedColumn<String>(
    'shopping_list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventoryItemIdMeta = const VerificationMeta(
    'inventoryItemId',
  );
  @override
  late final GeneratedColumn<String> inventoryItemId = GeneratedColumn<String>(
    'inventory_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIconMeta = const VerificationMeta(
    'categoryIcon',
  );
  @override
  late final GeneratedColumn<String> categoryIcon = GeneratedColumn<String>(
    'category_icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('category'),
  );
  static const VerificationMeta _categoryColorMeta = const VerificationMeta(
    'categoryColor',
  );
  @override
  late final GeneratedColumn<String> categoryColor = GeneratedColumn<String>(
    'category_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#6366F1'),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pcs'),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isAutoGeneratedMeta = const VerificationMeta(
    'isAutoGenerated',
  );
  @override
  late final GeneratedColumn<bool> isAutoGenerated = GeneratedColumn<bool>(
    'is_auto_generated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_auto_generated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _addedByNameMeta = const VerificationMeta(
    'addedByName',
  );
  @override
  late final GeneratedColumn<String> addedByName = GeneratedColumn<String>(
    'added_by_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _completedByNameMeta = const VerificationMeta(
    'completedByName',
  );
  @override
  late final GeneratedColumn<String> completedByName = GeneratedColumn<String>(
    'completed_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isLocalOnlyMeta = const VerificationMeta(
    'isLocalOnly',
  );
  @override
  late final GeneratedColumn<bool> isLocalOnly = GeneratedColumn<bool>(
    'is_local_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shoppingListId,
    inventoryItemId,
    itemName,
    categoryName,
    categoryIcon,
    categoryColor,
    quantity,
    unit,
    isCompleted,
    isAutoGenerated,
    addedByName,
    completedByName,
    completedAt,
    notes,
    barcode,
    productId,
    isLocalOnly,
    isDeleted,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shopping_list_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalShoppingListItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shopping_list_id')) {
      context.handle(
        _shoppingListIdMeta,
        shoppingListId.isAcceptableOrUnknown(
          data['shopping_list_id']!,
          _shoppingListIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shoppingListIdMeta);
    }
    if (data.containsKey('inventory_item_id')) {
      context.handle(
        _inventoryItemIdMeta,
        inventoryItemId.isAcceptableOrUnknown(
          data['inventory_item_id']!,
          _inventoryItemIdMeta,
        ),
      );
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('category_icon')) {
      context.handle(
        _categoryIconMeta,
        categoryIcon.isAcceptableOrUnknown(
          data['category_icon']!,
          _categoryIconMeta,
        ),
      );
    }
    if (data.containsKey('category_color')) {
      context.handle(
        _categoryColorMeta,
        categoryColor.isAcceptableOrUnknown(
          data['category_color']!,
          _categoryColorMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('is_auto_generated')) {
      context.handle(
        _isAutoGeneratedMeta,
        isAutoGenerated.isAcceptableOrUnknown(
          data['is_auto_generated']!,
          _isAutoGeneratedMeta,
        ),
      );
    }
    if (data.containsKey('added_by_name')) {
      context.handle(
        _addedByNameMeta,
        addedByName.isAcceptableOrUnknown(
          data['added_by_name']!,
          _addedByNameMeta,
        ),
      );
    }
    if (data.containsKey('completed_by_name')) {
      context.handle(
        _completedByNameMeta,
        completedByName.isAcceptableOrUnknown(
          data['completed_by_name']!,
          _completedByNameMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('is_local_only')) {
      context.handle(
        _isLocalOnlyMeta,
        isLocalOnly.isAcceptableOrUnknown(
          data['is_local_only']!,
          _isLocalOnlyMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalShoppingListItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalShoppingListItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shoppingListId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shopping_list_id'],
      )!,
      inventoryItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_item_id'],
      ),
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      ),
      categoryIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_icon'],
      )!,
      categoryColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_color'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      isAutoGenerated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_auto_generated'],
      )!,
      addedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added_by_name'],
      )!,
      completedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_by_name'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      isLocalOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local_only'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalShoppingListItemsTable createAlias(String alias) {
    return $LocalShoppingListItemsTable(attachedDatabase, alias);
  }
}

class LocalShoppingListItem extends DataClass
    implements Insertable<LocalShoppingListItem> {
  final String id;
  final String shoppingListId;
  final String? inventoryItemId;
  final String itemName;
  final String? categoryName;
  final String categoryIcon;
  final String categoryColor;
  final double quantity;
  final String unit;
  final bool isCompleted;
  final bool isAutoGenerated;
  final String addedByName;
  final String? completedByName;
  final String? completedAt;
  final String? notes;
  final String? barcode;
  final String? productId;
  final bool isLocalOnly;
  final bool isDeleted;
  final DateTime? updatedAt;
  const LocalShoppingListItem({
    required this.id,
    required this.shoppingListId,
    this.inventoryItemId,
    required this.itemName,
    this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.quantity,
    required this.unit,
    required this.isCompleted,
    required this.isAutoGenerated,
    required this.addedByName,
    this.completedByName,
    this.completedAt,
    this.notes,
    this.barcode,
    this.productId,
    required this.isLocalOnly,
    required this.isDeleted,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shopping_list_id'] = Variable<String>(shoppingListId);
    if (!nullToAbsent || inventoryItemId != null) {
      map['inventory_item_id'] = Variable<String>(inventoryItemId);
    }
    map['item_name'] = Variable<String>(itemName);
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    map['category_icon'] = Variable<String>(categoryIcon);
    map['category_color'] = Variable<String>(categoryColor);
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['is_auto_generated'] = Variable<bool>(isAutoGenerated);
    map['added_by_name'] = Variable<String>(addedByName);
    if (!nullToAbsent || completedByName != null) {
      map['completed_by_name'] = Variable<String>(completedByName);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['is_local_only'] = Variable<bool>(isLocalOnly);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalShoppingListItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalShoppingListItemsCompanion(
      id: Value(id),
      shoppingListId: Value(shoppingListId),
      inventoryItemId: inventoryItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(inventoryItemId),
      itemName: Value(itemName),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      categoryIcon: Value(categoryIcon),
      categoryColor: Value(categoryColor),
      quantity: Value(quantity),
      unit: Value(unit),
      isCompleted: Value(isCompleted),
      isAutoGenerated: Value(isAutoGenerated),
      addedByName: Value(addedByName),
      completedByName: completedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(completedByName),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      isLocalOnly: Value(isLocalOnly),
      isDeleted: Value(isDeleted),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalShoppingListItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalShoppingListItem(
      id: serializer.fromJson<String>(json['id']),
      shoppingListId: serializer.fromJson<String>(json['shoppingListId']),
      inventoryItemId: serializer.fromJson<String?>(json['inventoryItemId']),
      itemName: serializer.fromJson<String>(json['itemName']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      categoryIcon: serializer.fromJson<String>(json['categoryIcon']),
      categoryColor: serializer.fromJson<String>(json['categoryColor']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      isAutoGenerated: serializer.fromJson<bool>(json['isAutoGenerated']),
      addedByName: serializer.fromJson<String>(json['addedByName']),
      completedByName: serializer.fromJson<String?>(json['completedByName']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      productId: serializer.fromJson<String?>(json['productId']),
      isLocalOnly: serializer.fromJson<bool>(json['isLocalOnly']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shoppingListId': serializer.toJson<String>(shoppingListId),
      'inventoryItemId': serializer.toJson<String?>(inventoryItemId),
      'itemName': serializer.toJson<String>(itemName),
      'categoryName': serializer.toJson<String?>(categoryName),
      'categoryIcon': serializer.toJson<String>(categoryIcon),
      'categoryColor': serializer.toJson<String>(categoryColor),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'isAutoGenerated': serializer.toJson<bool>(isAutoGenerated),
      'addedByName': serializer.toJson<String>(addedByName),
      'completedByName': serializer.toJson<String?>(completedByName),
      'completedAt': serializer.toJson<String?>(completedAt),
      'notes': serializer.toJson<String?>(notes),
      'barcode': serializer.toJson<String?>(barcode),
      'productId': serializer.toJson<String?>(productId),
      'isLocalOnly': serializer.toJson<bool>(isLocalOnly),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalShoppingListItem copyWith({
    String? id,
    String? shoppingListId,
    Value<String?> inventoryItemId = const Value.absent(),
    String? itemName,
    Value<String?> categoryName = const Value.absent(),
    String? categoryIcon,
    String? categoryColor,
    double? quantity,
    String? unit,
    bool? isCompleted,
    bool? isAutoGenerated,
    String? addedByName,
    Value<String?> completedByName = const Value.absent(),
    Value<String?> completedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    Value<String?> productId = const Value.absent(),
    bool? isLocalOnly,
    bool? isDeleted,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalShoppingListItem(
    id: id ?? this.id,
    shoppingListId: shoppingListId ?? this.shoppingListId,
    inventoryItemId: inventoryItemId.present
        ? inventoryItemId.value
        : this.inventoryItemId,
    itemName: itemName ?? this.itemName,
    categoryName: categoryName.present ? categoryName.value : this.categoryName,
    categoryIcon: categoryIcon ?? this.categoryIcon,
    categoryColor: categoryColor ?? this.categoryColor,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    isCompleted: isCompleted ?? this.isCompleted,
    isAutoGenerated: isAutoGenerated ?? this.isAutoGenerated,
    addedByName: addedByName ?? this.addedByName,
    completedByName: completedByName.present
        ? completedByName.value
        : this.completedByName,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    notes: notes.present ? notes.value : this.notes,
    barcode: barcode.present ? barcode.value : this.barcode,
    productId: productId.present ? productId.value : this.productId,
    isLocalOnly: isLocalOnly ?? this.isLocalOnly,
    isDeleted: isDeleted ?? this.isDeleted,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalShoppingListItem copyWithCompanion(
    LocalShoppingListItemsCompanion data,
  ) {
    return LocalShoppingListItem(
      id: data.id.present ? data.id.value : this.id,
      shoppingListId: data.shoppingListId.present
          ? data.shoppingListId.value
          : this.shoppingListId,
      inventoryItemId: data.inventoryItemId.present
          ? data.inventoryItemId.value
          : this.inventoryItemId,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      categoryIcon: data.categoryIcon.present
          ? data.categoryIcon.value
          : this.categoryIcon,
      categoryColor: data.categoryColor.present
          ? data.categoryColor.value
          : this.categoryColor,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      isAutoGenerated: data.isAutoGenerated.present
          ? data.isAutoGenerated.value
          : this.isAutoGenerated,
      addedByName: data.addedByName.present
          ? data.addedByName.value
          : this.addedByName,
      completedByName: data.completedByName.present
          ? data.completedByName.value
          : this.completedByName,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      productId: data.productId.present ? data.productId.value : this.productId,
      isLocalOnly: data.isLocalOnly.present
          ? data.isLocalOnly.value
          : this.isLocalOnly,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingListItem(')
          ..write('id: $id, ')
          ..write('shoppingListId: $shoppingListId, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('itemName: $itemName, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryIcon: $categoryIcon, ')
          ..write('categoryColor: $categoryColor, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('isAutoGenerated: $isAutoGenerated, ')
          ..write('addedByName: $addedByName, ')
          ..write('completedByName: $completedByName, ')
          ..write('completedAt: $completedAt, ')
          ..write('notes: $notes, ')
          ..write('barcode: $barcode, ')
          ..write('productId: $productId, ')
          ..write('isLocalOnly: $isLocalOnly, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shoppingListId,
    inventoryItemId,
    itemName,
    categoryName,
    categoryIcon,
    categoryColor,
    quantity,
    unit,
    isCompleted,
    isAutoGenerated,
    addedByName,
    completedByName,
    completedAt,
    notes,
    barcode,
    productId,
    isLocalOnly,
    isDeleted,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalShoppingListItem &&
          other.id == this.id &&
          other.shoppingListId == this.shoppingListId &&
          other.inventoryItemId == this.inventoryItemId &&
          other.itemName == this.itemName &&
          other.categoryName == this.categoryName &&
          other.categoryIcon == this.categoryIcon &&
          other.categoryColor == this.categoryColor &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.isCompleted == this.isCompleted &&
          other.isAutoGenerated == this.isAutoGenerated &&
          other.addedByName == this.addedByName &&
          other.completedByName == this.completedByName &&
          other.completedAt == this.completedAt &&
          other.notes == this.notes &&
          other.barcode == this.barcode &&
          other.productId == this.productId &&
          other.isLocalOnly == this.isLocalOnly &&
          other.isDeleted == this.isDeleted &&
          other.updatedAt == this.updatedAt);
}

class LocalShoppingListItemsCompanion
    extends UpdateCompanion<LocalShoppingListItem> {
  final Value<String> id;
  final Value<String> shoppingListId;
  final Value<String?> inventoryItemId;
  final Value<String> itemName;
  final Value<String?> categoryName;
  final Value<String> categoryIcon;
  final Value<String> categoryColor;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<bool> isCompleted;
  final Value<bool> isAutoGenerated;
  final Value<String> addedByName;
  final Value<String?> completedByName;
  final Value<String?> completedAt;
  final Value<String?> notes;
  final Value<String?> barcode;
  final Value<String?> productId;
  final Value<bool> isLocalOnly;
  final Value<bool> isDeleted;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalShoppingListItemsCompanion({
    this.id = const Value.absent(),
    this.shoppingListId = const Value.absent(),
    this.inventoryItemId = const Value.absent(),
    this.itemName = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryIcon = const Value.absent(),
    this.categoryColor = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.isAutoGenerated = const Value.absent(),
    this.addedByName = const Value.absent(),
    this.completedByName = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.barcode = const Value.absent(),
    this.productId = const Value.absent(),
    this.isLocalOnly = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShoppingListItemsCompanion.insert({
    required String id,
    required String shoppingListId,
    this.inventoryItemId = const Value.absent(),
    required String itemName,
    this.categoryName = const Value.absent(),
    this.categoryIcon = const Value.absent(),
    this.categoryColor = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.isAutoGenerated = const Value.absent(),
    this.addedByName = const Value.absent(),
    this.completedByName = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.barcode = const Value.absent(),
    this.productId = const Value.absent(),
    this.isLocalOnly = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shoppingListId = Value(shoppingListId),
       itemName = Value(itemName);
  static Insertable<LocalShoppingListItem> custom({
    Expression<String>? id,
    Expression<String>? shoppingListId,
    Expression<String>? inventoryItemId,
    Expression<String>? itemName,
    Expression<String>? categoryName,
    Expression<String>? categoryIcon,
    Expression<String>? categoryColor,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<bool>? isCompleted,
    Expression<bool>? isAutoGenerated,
    Expression<String>? addedByName,
    Expression<String>? completedByName,
    Expression<String>? completedAt,
    Expression<String>? notes,
    Expression<String>? barcode,
    Expression<String>? productId,
    Expression<bool>? isLocalOnly,
    Expression<bool>? isDeleted,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shoppingListId != null) 'shopping_list_id': shoppingListId,
      if (inventoryItemId != null) 'inventory_item_id': inventoryItemId,
      if (itemName != null) 'item_name': itemName,
      if (categoryName != null) 'category_name': categoryName,
      if (categoryIcon != null) 'category_icon': categoryIcon,
      if (categoryColor != null) 'category_color': categoryColor,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (isAutoGenerated != null) 'is_auto_generated': isAutoGenerated,
      if (addedByName != null) 'added_by_name': addedByName,
      if (completedByName != null) 'completed_by_name': completedByName,
      if (completedAt != null) 'completed_at': completedAt,
      if (notes != null) 'notes': notes,
      if (barcode != null) 'barcode': barcode,
      if (productId != null) 'product_id': productId,
      if (isLocalOnly != null) 'is_local_only': isLocalOnly,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShoppingListItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? shoppingListId,
    Value<String?>? inventoryItemId,
    Value<String>? itemName,
    Value<String?>? categoryName,
    Value<String>? categoryIcon,
    Value<String>? categoryColor,
    Value<double>? quantity,
    Value<String>? unit,
    Value<bool>? isCompleted,
    Value<bool>? isAutoGenerated,
    Value<String>? addedByName,
    Value<String?>? completedByName,
    Value<String?>? completedAt,
    Value<String?>? notes,
    Value<String?>? barcode,
    Value<String?>? productId,
    Value<bool>? isLocalOnly,
    Value<bool>? isDeleted,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalShoppingListItemsCompanion(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      itemName: itemName ?? this.itemName,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isCompleted: isCompleted ?? this.isCompleted,
      isAutoGenerated: isAutoGenerated ?? this.isAutoGenerated,
      addedByName: addedByName ?? this.addedByName,
      completedByName: completedByName ?? this.completedByName,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      barcode: barcode ?? this.barcode,
      productId: productId ?? this.productId,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shoppingListId.present) {
      map['shopping_list_id'] = Variable<String>(shoppingListId.value);
    }
    if (inventoryItemId.present) {
      map['inventory_item_id'] = Variable<String>(inventoryItemId.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (categoryIcon.present) {
      map['category_icon'] = Variable<String>(categoryIcon.value);
    }
    if (categoryColor.present) {
      map['category_color'] = Variable<String>(categoryColor.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (isAutoGenerated.present) {
      map['is_auto_generated'] = Variable<bool>(isAutoGenerated.value);
    }
    if (addedByName.present) {
      map['added_by_name'] = Variable<String>(addedByName.value);
    }
    if (completedByName.present) {
      map['completed_by_name'] = Variable<String>(completedByName.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (isLocalOnly.present) {
      map['is_local_only'] = Variable<bool>(isLocalOnly.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingListItemsCompanion(')
          ..write('id: $id, ')
          ..write('shoppingListId: $shoppingListId, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('itemName: $itemName, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryIcon: $categoryIcon, ')
          ..write('categoryColor: $categoryColor, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('isAutoGenerated: $isAutoGenerated, ')
          ..write('addedByName: $addedByName, ')
          ..write('completedByName: $completedByName, ')
          ..write('completedAt: $completedAt, ')
          ..write('notes: $notes, ')
          ..write('barcode: $barcode, ')
          ..write('productId: $productId, ')
          ..write('isLocalOnly: $isLocalOnly, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStoresTable extends LocalStores
    with TableInfo<$LocalStoresTable, LocalStore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, homeId, name, location, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStore(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalStoresTable createAlias(String alias) {
    return $LocalStoresTable(attachedDatabase, alias);
  }
}

class LocalStore extends DataClass implements Insertable<LocalStore> {
  final String id;
  final String homeId;
  final String name;
  final String? location;
  final DateTime? updatedAt;
  const LocalStore({
    required this.id,
    required this.homeId,
    required this.name,
    this.location,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['home_id'] = Variable<String>(homeId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalStoresCompanion toCompanion(bool nullToAbsent) {
    return LocalStoresCompanion(
      id: Value(id),
      homeId: Value(homeId),
      name: Value(name),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalStore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStore(
      id: serializer.fromJson<String>(json['id']),
      homeId: serializer.fromJson<String>(json['homeId']),
      name: serializer.fromJson<String>(json['name']),
      location: serializer.fromJson<String?>(json['location']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'homeId': serializer.toJson<String>(homeId),
      'name': serializer.toJson<String>(name),
      'location': serializer.toJson<String?>(location),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalStore copyWith({
    String? id,
    String? homeId,
    String? name,
    Value<String?> location = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalStore(
    id: id ?? this.id,
    homeId: homeId ?? this.homeId,
    name: name ?? this.name,
    location: location.present ? location.value : this.location,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalStore copyWithCompanion(LocalStoresCompanion data) {
    return LocalStore(
      id: data.id.present ? data.id.value : this.id,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      name: data.name.present ? data.name.value : this.name,
      location: data.location.present ? data.location.value : this.location,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStore(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, homeId, name, location, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStore &&
          other.id == this.id &&
          other.homeId == this.homeId &&
          other.name == this.name &&
          other.location == this.location &&
          other.updatedAt == this.updatedAt);
}

class LocalStoresCompanion extends UpdateCompanion<LocalStore> {
  final Value<String> id;
  final Value<String> homeId;
  final Value<String> name;
  final Value<String?> location;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalStoresCompanion({
    this.id = const Value.absent(),
    this.homeId = const Value.absent(),
    this.name = const Value.absent(),
    this.location = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStoresCompanion.insert({
    required String id,
    required String homeId,
    required String name,
    this.location = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       homeId = Value(homeId),
       name = Value(name);
  static Insertable<LocalStore> custom({
    Expression<String>? id,
    Expression<String>? homeId,
    Expression<String>? name,
    Expression<String>? location,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeId != null) 'home_id': homeId,
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStoresCompanion copyWith({
    Value<String>? id,
    Value<String>? homeId,
    Value<String>? name,
    Value<String?>? location,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalStoresCompanion(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      location: location ?? this.location,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStoresCompanion(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPurchasesTable extends LocalPurchases
    with TableInfo<$LocalPurchasesTable, LocalPurchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedByNameMeta = const VerificationMeta(
    'recordedByName',
  );
  @override
  late final GeneratedColumn<String> recordedByName = GeneratedColumn<String>(
    'recorded_by_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<String> purchaseDate = GeneratedColumn<String>(
    'purchase_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _receiptImageUrlMeta = const VerificationMeta(
    'receiptImageUrl',
  );
  @override
  late final GeneratedColumn<String> receiptImageUrl = GeneratedColumn<String>(
    'receipt_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isLocalOnlyMeta = const VerificationMeta(
    'isLocalOnly',
  );
  @override
  late final GeneratedColumn<bool> isLocalOnly = GeneratedColumn<bool>(
    'is_local_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    homeId,
    storeId,
    storeName,
    recordedByName,
    purchaseDate,
    totalAmount,
    currency,
    receiptImageUrl,
    notes,
    isLocalOnly,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_purchases';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPurchase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    }
    if (data.containsKey('recorded_by_name')) {
      context.handle(
        _recordedByNameMeta,
        recordedByName.isAcceptableOrUnknown(
          data['recorded_by_name']!,
          _recordedByNameMeta,
        ),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('receipt_image_url')) {
      context.handle(
        _receiptImageUrlMeta,
        receiptImageUrl.isAcceptableOrUnknown(
          data['receipt_image_url']!,
          _receiptImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_local_only')) {
      context.handle(
        _isLocalOnlyMeta,
        isLocalOnly.isAcceptableOrUnknown(
          data['is_local_only']!,
          _isLocalOnlyMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPurchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPurchase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      storeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_name'],
      ),
      recordedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_name'],
      )!,
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_date'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      receiptImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_image_url'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isLocalOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local_only'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalPurchasesTable createAlias(String alias) {
    return $LocalPurchasesTable(attachedDatabase, alias);
  }
}

class LocalPurchase extends DataClass implements Insertable<LocalPurchase> {
  final String id;
  final String homeId;
  final String? storeId;
  final String? storeName;
  final String recordedByName;
  final String purchaseDate;
  final double totalAmount;
  final String currency;
  final String? receiptImageUrl;
  final String? notes;
  final bool isLocalOnly;
  final DateTime? updatedAt;
  const LocalPurchase({
    required this.id,
    required this.homeId,
    this.storeId,
    this.storeName,
    required this.recordedByName,
    required this.purchaseDate,
    required this.totalAmount,
    required this.currency,
    this.receiptImageUrl,
    this.notes,
    required this.isLocalOnly,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['home_id'] = Variable<String>(homeId);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || storeName != null) {
      map['store_name'] = Variable<String>(storeName);
    }
    map['recorded_by_name'] = Variable<String>(recordedByName);
    map['purchase_date'] = Variable<String>(purchaseDate);
    map['total_amount'] = Variable<double>(totalAmount);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || receiptImageUrl != null) {
      map['receipt_image_url'] = Variable<String>(receiptImageUrl);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_local_only'] = Variable<bool>(isLocalOnly);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalPurchasesCompanion toCompanion(bool nullToAbsent) {
    return LocalPurchasesCompanion(
      id: Value(id),
      homeId: Value(homeId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      storeName: storeName == null && nullToAbsent
          ? const Value.absent()
          : Value(storeName),
      recordedByName: Value(recordedByName),
      purchaseDate: Value(purchaseDate),
      totalAmount: Value(totalAmount),
      currency: Value(currency),
      receiptImageUrl: receiptImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptImageUrl),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isLocalOnly: Value(isLocalOnly),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalPurchase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPurchase(
      id: serializer.fromJson<String>(json['id']),
      homeId: serializer.fromJson<String>(json['homeId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      storeName: serializer.fromJson<String?>(json['storeName']),
      recordedByName: serializer.fromJson<String>(json['recordedByName']),
      purchaseDate: serializer.fromJson<String>(json['purchaseDate']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      currency: serializer.fromJson<String>(json['currency']),
      receiptImageUrl: serializer.fromJson<String?>(json['receiptImageUrl']),
      notes: serializer.fromJson<String?>(json['notes']),
      isLocalOnly: serializer.fromJson<bool>(json['isLocalOnly']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'homeId': serializer.toJson<String>(homeId),
      'storeId': serializer.toJson<String?>(storeId),
      'storeName': serializer.toJson<String?>(storeName),
      'recordedByName': serializer.toJson<String>(recordedByName),
      'purchaseDate': serializer.toJson<String>(purchaseDate),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'currency': serializer.toJson<String>(currency),
      'receiptImageUrl': serializer.toJson<String?>(receiptImageUrl),
      'notes': serializer.toJson<String?>(notes),
      'isLocalOnly': serializer.toJson<bool>(isLocalOnly),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalPurchase copyWith({
    String? id,
    String? homeId,
    Value<String?> storeId = const Value.absent(),
    Value<String?> storeName = const Value.absent(),
    String? recordedByName,
    String? purchaseDate,
    double? totalAmount,
    String? currency,
    Value<String?> receiptImageUrl = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isLocalOnly,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalPurchase(
    id: id ?? this.id,
    homeId: homeId ?? this.homeId,
    storeId: storeId.present ? storeId.value : this.storeId,
    storeName: storeName.present ? storeName.value : this.storeName,
    recordedByName: recordedByName ?? this.recordedByName,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    totalAmount: totalAmount ?? this.totalAmount,
    currency: currency ?? this.currency,
    receiptImageUrl: receiptImageUrl.present
        ? receiptImageUrl.value
        : this.receiptImageUrl,
    notes: notes.present ? notes.value : this.notes,
    isLocalOnly: isLocalOnly ?? this.isLocalOnly,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalPurchase copyWithCompanion(LocalPurchasesCompanion data) {
    return LocalPurchase(
      id: data.id.present ? data.id.value : this.id,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      recordedByName: data.recordedByName.present
          ? data.recordedByName.value
          : this.recordedByName,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      currency: data.currency.present ? data.currency.value : this.currency,
      receiptImageUrl: data.receiptImageUrl.present
          ? data.receiptImageUrl.value
          : this.receiptImageUrl,
      notes: data.notes.present ? data.notes.value : this.notes,
      isLocalOnly: data.isLocalOnly.present
          ? data.isLocalOnly.value
          : this.isLocalOnly,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPurchase(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('storeId: $storeId, ')
          ..write('storeName: $storeName, ')
          ..write('recordedByName: $recordedByName, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('currency: $currency, ')
          ..write('receiptImageUrl: $receiptImageUrl, ')
          ..write('notes: $notes, ')
          ..write('isLocalOnly: $isLocalOnly, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    homeId,
    storeId,
    storeName,
    recordedByName,
    purchaseDate,
    totalAmount,
    currency,
    receiptImageUrl,
    notes,
    isLocalOnly,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPurchase &&
          other.id == this.id &&
          other.homeId == this.homeId &&
          other.storeId == this.storeId &&
          other.storeName == this.storeName &&
          other.recordedByName == this.recordedByName &&
          other.purchaseDate == this.purchaseDate &&
          other.totalAmount == this.totalAmount &&
          other.currency == this.currency &&
          other.receiptImageUrl == this.receiptImageUrl &&
          other.notes == this.notes &&
          other.isLocalOnly == this.isLocalOnly &&
          other.updatedAt == this.updatedAt);
}

class LocalPurchasesCompanion extends UpdateCompanion<LocalPurchase> {
  final Value<String> id;
  final Value<String> homeId;
  final Value<String?> storeId;
  final Value<String?> storeName;
  final Value<String> recordedByName;
  final Value<String> purchaseDate;
  final Value<double> totalAmount;
  final Value<String> currency;
  final Value<String?> receiptImageUrl;
  final Value<String?> notes;
  final Value<bool> isLocalOnly;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalPurchasesCompanion({
    this.id = const Value.absent(),
    this.homeId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.storeName = const Value.absent(),
    this.recordedByName = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.receiptImageUrl = const Value.absent(),
    this.notes = const Value.absent(),
    this.isLocalOnly = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPurchasesCompanion.insert({
    required String id,
    required String homeId,
    this.storeId = const Value.absent(),
    this.storeName = const Value.absent(),
    this.recordedByName = const Value.absent(),
    required String purchaseDate,
    required double totalAmount,
    this.currency = const Value.absent(),
    this.receiptImageUrl = const Value.absent(),
    this.notes = const Value.absent(),
    this.isLocalOnly = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       homeId = Value(homeId),
       purchaseDate = Value(purchaseDate),
       totalAmount = Value(totalAmount);
  static Insertable<LocalPurchase> custom({
    Expression<String>? id,
    Expression<String>? homeId,
    Expression<String>? storeId,
    Expression<String>? storeName,
    Expression<String>? recordedByName,
    Expression<String>? purchaseDate,
    Expression<double>? totalAmount,
    Expression<String>? currency,
    Expression<String>? receiptImageUrl,
    Expression<String>? notes,
    Expression<bool>? isLocalOnly,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeId != null) 'home_id': homeId,
      if (storeId != null) 'store_id': storeId,
      if (storeName != null) 'store_name': storeName,
      if (recordedByName != null) 'recorded_by_name': recordedByName,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (currency != null) 'currency': currency,
      if (receiptImageUrl != null) 'receipt_image_url': receiptImageUrl,
      if (notes != null) 'notes': notes,
      if (isLocalOnly != null) 'is_local_only': isLocalOnly,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPurchasesCompanion copyWith({
    Value<String>? id,
    Value<String>? homeId,
    Value<String?>? storeId,
    Value<String?>? storeName,
    Value<String>? recordedByName,
    Value<String>? purchaseDate,
    Value<double>? totalAmount,
    Value<String>? currency,
    Value<String?>? receiptImageUrl,
    Value<String?>? notes,
    Value<bool>? isLocalOnly,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalPurchasesCompanion(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      recordedByName: recordedByName ?? this.recordedByName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      notes: notes ?? this.notes,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (recordedByName.present) {
      map['recorded_by_name'] = Variable<String>(recordedByName.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<String>(purchaseDate.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (receiptImageUrl.present) {
      map['receipt_image_url'] = Variable<String>(receiptImageUrl.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isLocalOnly.present) {
      map['is_local_only'] = Variable<bool>(isLocalOnly.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPurchasesCompanion(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('storeId: $storeId, ')
          ..write('storeName: $storeName, ')
          ..write('recordedByName: $recordedByName, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('currency: $currency, ')
          ..write('receiptImageUrl: $receiptImageUrl, ')
          ..write('notes: $notes, ')
          ..write('isLocalOnly: $isLocalOnly, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPurchaseItemsTable extends LocalPurchaseItems
    with TableInfo<$LocalPurchaseItemsTable, LocalPurchaseItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPurchaseItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseIdMeta = const VerificationMeta(
    'purchaseId',
  );
  @override
  late final GeneratedColumn<String> purchaseId = GeneratedColumn<String>(
    'purchase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventoryItemIdMeta = const VerificationMeta(
    'inventoryItemId',
  );
  @override
  late final GeneratedColumn<String> inventoryItemId = GeneratedColumn<String>(
    'inventory_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPriceMeta = const VerificationMeta(
    'totalPrice',
  );
  @override
  late final GeneratedColumn<double> totalPrice = GeneratedColumn<double>(
    'total_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    purchaseId,
    inventoryItemId,
    itemName,
    categoryName,
    quantity,
    unit,
    unitPrice,
    totalPrice,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_purchase_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPurchaseItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('purchase_id')) {
      context.handle(
        _purchaseIdMeta,
        purchaseId.isAcceptableOrUnknown(data['purchase_id']!, _purchaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_purchaseIdMeta);
    }
    if (data.containsKey('inventory_item_id')) {
      context.handle(
        _inventoryItemIdMeta,
        inventoryItemId.isAcceptableOrUnknown(
          data['inventory_item_id']!,
          _inventoryItemIdMeta,
        ),
      );
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('total_price')) {
      context.handle(
        _totalPriceMeta,
        totalPrice.isAcceptableOrUnknown(data['total_price']!, _totalPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_totalPriceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPurchaseItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPurchaseItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      purchaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_id'],
      )!,
      inventoryItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_item_id'],
      ),
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      totalPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_price'],
      )!,
    );
  }

  @override
  $LocalPurchaseItemsTable createAlias(String alias) {
    return $LocalPurchaseItemsTable(attachedDatabase, alias);
  }
}

class LocalPurchaseItem extends DataClass
    implements Insertable<LocalPurchaseItem> {
  final String id;
  final String purchaseId;
  final String? inventoryItemId;
  final String itemName;
  final String? categoryName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;
  const LocalPurchaseItem({
    required this.id,
    required this.purchaseId,
    this.inventoryItemId,
    required this.itemName,
    this.categoryName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['purchase_id'] = Variable<String>(purchaseId);
    if (!nullToAbsent || inventoryItemId != null) {
      map['inventory_item_id'] = Variable<String>(inventoryItemId);
    }
    map['item_name'] = Variable<String>(itemName);
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    map['unit_price'] = Variable<double>(unitPrice);
    map['total_price'] = Variable<double>(totalPrice);
    return map;
  }

  LocalPurchaseItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalPurchaseItemsCompanion(
      id: Value(id),
      purchaseId: Value(purchaseId),
      inventoryItemId: inventoryItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(inventoryItemId),
      itemName: Value(itemName),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      quantity: Value(quantity),
      unit: Value(unit),
      unitPrice: Value(unitPrice),
      totalPrice: Value(totalPrice),
    );
  }

  factory LocalPurchaseItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPurchaseItem(
      id: serializer.fromJson<String>(json['id']),
      purchaseId: serializer.fromJson<String>(json['purchaseId']),
      inventoryItemId: serializer.fromJson<String?>(json['inventoryItemId']),
      itemName: serializer.fromJson<String>(json['itemName']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      totalPrice: serializer.fromJson<double>(json['totalPrice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'purchaseId': serializer.toJson<String>(purchaseId),
      'inventoryItemId': serializer.toJson<String?>(inventoryItemId),
      'itemName': serializer.toJson<String>(itemName),
      'categoryName': serializer.toJson<String?>(categoryName),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'totalPrice': serializer.toJson<double>(totalPrice),
    };
  }

  LocalPurchaseItem copyWith({
    String? id,
    String? purchaseId,
    Value<String?> inventoryItemId = const Value.absent(),
    String? itemName,
    Value<String?> categoryName = const Value.absent(),
    double? quantity,
    String? unit,
    double? unitPrice,
    double? totalPrice,
  }) => LocalPurchaseItem(
    id: id ?? this.id,
    purchaseId: purchaseId ?? this.purchaseId,
    inventoryItemId: inventoryItemId.present
        ? inventoryItemId.value
        : this.inventoryItemId,
    itemName: itemName ?? this.itemName,
    categoryName: categoryName.present ? categoryName.value : this.categoryName,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    unitPrice: unitPrice ?? this.unitPrice,
    totalPrice: totalPrice ?? this.totalPrice,
  );
  LocalPurchaseItem copyWithCompanion(LocalPurchaseItemsCompanion data) {
    return LocalPurchaseItem(
      id: data.id.present ? data.id.value : this.id,
      purchaseId: data.purchaseId.present
          ? data.purchaseId.value
          : this.purchaseId,
      inventoryItemId: data.inventoryItemId.present
          ? data.inventoryItemId.value
          : this.inventoryItemId,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      totalPrice: data.totalPrice.present
          ? data.totalPrice.value
          : this.totalPrice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPurchaseItem(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('itemName: $itemName, ')
          ..write('categoryName: $categoryName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('totalPrice: $totalPrice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    purchaseId,
    inventoryItemId,
    itemName,
    categoryName,
    quantity,
    unit,
    unitPrice,
    totalPrice,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPurchaseItem &&
          other.id == this.id &&
          other.purchaseId == this.purchaseId &&
          other.inventoryItemId == this.inventoryItemId &&
          other.itemName == this.itemName &&
          other.categoryName == this.categoryName &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.unitPrice == this.unitPrice &&
          other.totalPrice == this.totalPrice);
}

class LocalPurchaseItemsCompanion extends UpdateCompanion<LocalPurchaseItem> {
  final Value<String> id;
  final Value<String> purchaseId;
  final Value<String?> inventoryItemId;
  final Value<String> itemName;
  final Value<String?> categoryName;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<double> unitPrice;
  final Value<double> totalPrice;
  final Value<int> rowid;
  const LocalPurchaseItemsCompanion({
    this.id = const Value.absent(),
    this.purchaseId = const Value.absent(),
    this.inventoryItemId = const Value.absent(),
    this.itemName = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.totalPrice = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPurchaseItemsCompanion.insert({
    required String id,
    required String purchaseId,
    this.inventoryItemId = const Value.absent(),
    required String itemName,
    this.categoryName = const Value.absent(),
    required double quantity,
    required String unit,
    required double unitPrice,
    required double totalPrice,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       purchaseId = Value(purchaseId),
       itemName = Value(itemName),
       quantity = Value(quantity),
       unit = Value(unit),
       unitPrice = Value(unitPrice),
       totalPrice = Value(totalPrice);
  static Insertable<LocalPurchaseItem> custom({
    Expression<String>? id,
    Expression<String>? purchaseId,
    Expression<String>? inventoryItemId,
    Expression<String>? itemName,
    Expression<String>? categoryName,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<double>? unitPrice,
    Expression<double>? totalPrice,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (purchaseId != null) 'purchase_id': purchaseId,
      if (inventoryItemId != null) 'inventory_item_id': inventoryItemId,
      if (itemName != null) 'item_name': itemName,
      if (categoryName != null) 'category_name': categoryName,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (totalPrice != null) 'total_price': totalPrice,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPurchaseItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? purchaseId,
    Value<String?>? inventoryItemId,
    Value<String>? itemName,
    Value<String?>? categoryName,
    Value<double>? quantity,
    Value<String>? unit,
    Value<double>? unitPrice,
    Value<double>? totalPrice,
    Value<int>? rowid,
  }) {
    return LocalPurchaseItemsCompanion(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      itemName: itemName ?? this.itemName,
      categoryName: categoryName ?? this.categoryName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (purchaseId.present) {
      map['purchase_id'] = Variable<String>(purchaseId.value);
    }
    if (inventoryItemId.present) {
      map['inventory_item_id'] = Variable<String>(inventoryItemId.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (totalPrice.present) {
      map['total_price'] = Variable<double>(totalPrice.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPurchaseItemsCompanion(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('itemName: $itemName, ')
          ..write('categoryName: $categoryName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('totalPrice: $totalPrice, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalNotificationsTable extends LocalNotifications
    with TableInfo<$LocalNotificationsTable, LocalNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    message,
    type,
    isRead,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalNotification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalNotification(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $LocalNotificationsTable createAlias(String alias) {
    return $LocalNotificationsTable(attachedDatabase, alias);
  }
}

class LocalNotification extends DataClass
    implements Insertable<LocalNotification> {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String? type;
  final bool isRead;
  final DateTime? createdAt;
  const LocalNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type,
    required this.isRead,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  LocalNotificationsCompanion toCompanion(bool nullToAbsent) {
    return LocalNotificationsCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      message: Value(message),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      isRead: Value(isRead),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory LocalNotification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalNotification(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      message: serializer.fromJson<String>(json['message']),
      type: serializer.fromJson<String?>(json['type']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'message': serializer.toJson<String>(message),
      'type': serializer.toJson<String?>(type),
      'isRead': serializer.toJson<bool>(isRead),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  LocalNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    Value<String?> type = const Value.absent(),
    bool? isRead,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => LocalNotification(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    message: message ?? this.message,
    type: type.present ? type.value : this.type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  LocalNotification copyWithCompanion(LocalNotificationsCompanion data) {
    return LocalNotification(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      message: data.message.present ? data.message.value : this.message,
      type: data.type.present ? data.type.value : this.type,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotification(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('type: $type, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, title, message, type, isRead, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalNotification &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.message == this.message &&
          other.type == this.type &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt);
}

class LocalNotificationsCompanion extends UpdateCompanion<LocalNotification> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String> message;
  final Value<String?> type;
  final Value<bool> isRead;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const LocalNotificationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.type = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalNotificationsCompanion.insert({
    required String id,
    required String userId,
    required String title,
    required String message,
    this.type = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       title = Value(title),
       message = Value(message);
  static Insertable<LocalNotification> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? message,
    Expression<String>? type,
    Expression<bool>? isRead,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (type != null) 'type': type,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalNotificationsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? title,
    Value<String>? message,
    Value<String?>? type,
    Value<bool>? isRead,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalNotificationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('type: $type, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueEntriesTable extends SyncQueueEntries
    with TableInfo<$SyncQueueEntriesTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationId,
    operationType,
    entityType,
    entityId,
    payload,
    createdAt,
    retryCount,
    status,
    lastError,
    homeId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
    );
  }

  @override
  $SyncQueueEntriesTable createAlias(String alias) {
    return $SyncQueueEntriesTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final int id;
  final String operationId;
  final String operationType;
  final String entityType;
  final String entityId;
  final String payload;
  final DateTime createdAt;
  final int retryCount;
  final String status;
  final String? lastError;
  final String homeId;
  const SyncQueueEntry({
    required this.id,
    required this.operationId,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    required this.status,
    this.lastError,
    required this.homeId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation_id'] = Variable<String>(operationId);
    map['operation_type'] = Variable<String>(operationType);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['home_id'] = Variable<String>(homeId);
    return map;
  }

  SyncQueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueEntriesCompanion(
      id: Value(id),
      operationId: Value(operationId),
      operationType: Value(operationType),
      entityType: Value(entityType),
      entityId: Value(entityId),
      payload: Value(payload),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      homeId: Value(homeId),
    );
  }

  factory SyncQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      id: serializer.fromJson<int>(json['id']),
      operationId: serializer.fromJson<String>(json['operationId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      homeId: serializer.fromJson<String>(json['homeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operationId': serializer.toJson<String>(operationId),
      'operationType': serializer.toJson<String>(operationType),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
      'homeId': serializer.toJson<String>(homeId),
    };
  }

  SyncQueueEntry copyWith({
    int? id,
    String? operationId,
    String? operationType,
    String? entityType,
    String? entityId,
    String? payload,
    DateTime? createdAt,
    int? retryCount,
    String? status,
    Value<String?> lastError = const Value.absent(),
    String? homeId,
  }) => SyncQueueEntry(
    id: id ?? this.id,
    operationId: operationId ?? this.operationId,
    operationType: operationType ?? this.operationType,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    status: status ?? this.status,
    lastError: lastError.present ? lastError.value : this.lastError,
    homeId: homeId ?? this.homeId,
  );
  SyncQueueEntry copyWithCompanion(SyncQueueEntriesCompanion data) {
    return SyncQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('id: $id, ')
          ..write('operationId: $operationId, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('homeId: $homeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationId,
    operationType,
    entityType,
    entityId,
    payload,
    createdAt,
    retryCount,
    status,
    lastError,
    homeId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.id == this.id &&
          other.operationId == this.operationId &&
          other.operationType == this.operationType &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.status == this.status &&
          other.lastError == this.lastError &&
          other.homeId == this.homeId);
}

class SyncQueueEntriesCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<int> id;
  final Value<String> operationId;
  final Value<String> operationType;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String> status;
  final Value<String?> lastError;
  final Value<String> homeId;
  const SyncQueueEntriesCompanion({
    this.id = const Value.absent(),
    this.operationId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.homeId = const Value.absent(),
  });
  SyncQueueEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String operationId,
    required String operationType,
    required String entityType,
    required String entityId,
    required String payload,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    required String homeId,
  }) : operationId = Value(operationId),
       operationType = Value(operationType),
       entityType = Value(entityType),
       entityId = Value(entityId),
       payload = Value(payload),
       createdAt = Value(createdAt),
       homeId = Value(homeId);
  static Insertable<SyncQueueEntry> custom({
    Expression<int>? id,
    Expression<String>? operationId,
    Expression<String>? operationType,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<String>? homeId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationId != null) 'operation_id': operationId,
      if (operationType != null) 'operation_type': operationType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (homeId != null) 'home_id': homeId,
    });
  }

  SyncQueueEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? operationId,
    Value<String>? operationType,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<String>? status,
    Value<String?>? lastError,
    Value<String>? homeId,
  }) {
    return SyncQueueEntriesCompanion(
      id: id ?? this.id,
      operationId: operationId ?? this.operationId,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      homeId: homeId ?? this.homeId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntriesCompanion(')
          ..write('id: $id, ')
          ..write('operationId: $operationId, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('homeId: $homeId')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataEntriesTable extends SyncMetadataEntries
    with TableInfo<$SyncMetadataEntriesTable, SyncMetadataEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [homeId, lastSyncedAt, syncVersion];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {homeId};
  @override
  SyncMetadataEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataEntry(
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $SyncMetadataEntriesTable createAlias(String alias) {
    return $SyncMetadataEntriesTable(attachedDatabase, alias);
  }
}

class SyncMetadataEntry extends DataClass
    implements Insertable<SyncMetadataEntry> {
  final String homeId;
  final DateTime? lastSyncedAt;
  final int syncVersion;
  const SyncMetadataEntry({
    required this.homeId,
    this.lastSyncedAt,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['home_id'] = Variable<String>(homeId);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  SyncMetadataEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataEntriesCompanion(
      homeId: Value(homeId),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncVersion: Value(syncVersion),
    );
  }

  factory SyncMetadataEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataEntry(
      homeId: serializer.fromJson<String>(json['homeId']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'homeId': serializer.toJson<String>(homeId),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  SyncMetadataEntry copyWith({
    String? homeId,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    int? syncVersion,
  }) => SyncMetadataEntry(
    homeId: homeId ?? this.homeId,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  SyncMetadataEntry copyWithCompanion(SyncMetadataEntriesCompanion data) {
    return SyncMetadataEntry(
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataEntry(')
          ..write('homeId: $homeId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(homeId, lastSyncedAt, syncVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataEntry &&
          other.homeId == this.homeId &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncVersion == this.syncVersion);
}

class SyncMetadataEntriesCompanion extends UpdateCompanion<SyncMetadataEntry> {
  final Value<String> homeId;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const SyncMetadataEntriesCompanion({
    this.homeId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataEntriesCompanion.insert({
    required String homeId,
    this.lastSyncedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : homeId = Value(homeId);
  static Insertable<SyncMetadataEntry> custom({
    Expression<String>? homeId,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (homeId != null) 'home_id': homeId,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataEntriesCompanion copyWith({
    Value<String>? homeId,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return SyncMetadataEntriesCompanion(
      homeId: homeId ?? this.homeId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataEntriesCompanion(')
          ..write('homeId: $homeId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProductOffersTable extends LocalProductOffers
    with TableInfo<$LocalProductOffersTable, LocalProductOffer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductOffersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shoppingItemIdMeta = const VerificationMeta(
    'shoppingItemId',
  );
  @override
  late final GeneratedColumn<String> shoppingItemId = GeneratedColumn<String>(
    'shopping_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryChargeMeta = const VerificationMeta(
    'deliveryCharge',
  );
  @override
  late final GeneratedColumn<double> deliveryCharge = GeneratedColumn<double>(
    'delivery_charge',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _effectivePriceMeta = const VerificationMeta(
    'effectivePrice',
  );
  @override
  late final GeneratedColumn<double> effectivePrice = GeneratedColumn<double>(
    'effective_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _availabilityMeta = const VerificationMeta(
    'availability',
  );
  @override
  late final GeneratedColumn<String> availability = GeneratedColumn<String>(
    'availability',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedDeliveryMeta = const VerificationMeta(
    'estimatedDelivery',
  );
  @override
  late final GeneratedColumn<String> estimatedDelivery =
      GeneratedColumn<String>(
        'estimated_delivery',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _affiliateUrlMeta = const VerificationMeta(
    'affiliateUrl',
  );
  @override
  late final GeneratedColumn<String> affiliateUrl = GeneratedColumn<String>(
    'affiliate_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _matchConfidenceMeta = const VerificationMeta(
    'matchConfidence',
  );
  @override
  late final GeneratedColumn<double> matchConfidence = GeneratedColumn<double>(
    'match_confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _matchTypeMeta = const VerificationMeta(
    'matchType',
  );
  @override
  late final GeneratedColumn<String> matchType = GeneratedColumn<String>(
    'match_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pricePerUnitLabelMeta = const VerificationMeta(
    'pricePerUnitLabel',
  );
  @override
  late final GeneratedColumn<String> pricePerUnitLabel =
      GeneratedColumn<String>(
        'price_per_unit_label',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastCheckedAtMeta = const VerificationMeta(
    'lastCheckedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCheckedAt =
      GeneratedColumn<DateTime>(
        'last_checked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shoppingItemId,
    provider,
    productName,
    brand,
    price,
    deliveryCharge,
    effectivePrice,
    currency,
    availability,
    estimatedDelivery,
    affiliateUrl,
    imageUrl,
    matchConfidence,
    matchType,
    pricePerUnitLabel,
    lastCheckedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_product_offers';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProductOffer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shopping_item_id')) {
      context.handle(
        _shoppingItemIdMeta,
        shoppingItemId.isAcceptableOrUnknown(
          data['shopping_item_id']!,
          _shoppingItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shoppingItemIdMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('delivery_charge')) {
      context.handle(
        _deliveryChargeMeta,
        deliveryCharge.isAcceptableOrUnknown(
          data['delivery_charge']!,
          _deliveryChargeMeta,
        ),
      );
    }
    if (data.containsKey('effective_price')) {
      context.handle(
        _effectivePriceMeta,
        effectivePrice.isAcceptableOrUnknown(
          data['effective_price']!,
          _effectivePriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectivePriceMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('availability')) {
      context.handle(
        _availabilityMeta,
        availability.isAcceptableOrUnknown(
          data['availability']!,
          _availabilityMeta,
        ),
      );
    }
    if (data.containsKey('estimated_delivery')) {
      context.handle(
        _estimatedDeliveryMeta,
        estimatedDelivery.isAcceptableOrUnknown(
          data['estimated_delivery']!,
          _estimatedDeliveryMeta,
        ),
      );
    }
    if (data.containsKey('affiliate_url')) {
      context.handle(
        _affiliateUrlMeta,
        affiliateUrl.isAcceptableOrUnknown(
          data['affiliate_url']!,
          _affiliateUrlMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('match_confidence')) {
      context.handle(
        _matchConfidenceMeta,
        matchConfidence.isAcceptableOrUnknown(
          data['match_confidence']!,
          _matchConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('match_type')) {
      context.handle(
        _matchTypeMeta,
        matchType.isAcceptableOrUnknown(data['match_type']!, _matchTypeMeta),
      );
    }
    if (data.containsKey('price_per_unit_label')) {
      context.handle(
        _pricePerUnitLabelMeta,
        pricePerUnitLabel.isAcceptableOrUnknown(
          data['price_per_unit_label']!,
          _pricePerUnitLabelMeta,
        ),
      );
    }
    if (data.containsKey('last_checked_at')) {
      context.handle(
        _lastCheckedAtMeta,
        lastCheckedAt.isAcceptableOrUnknown(
          data['last_checked_at']!,
          _lastCheckedAtMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProductOffer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProductOffer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shoppingItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shopping_item_id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      deliveryCharge: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}delivery_charge'],
      ),
      effectivePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}effective_price'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      availability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}availability'],
      ),
      estimatedDelivery: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estimated_delivery'],
      ),
      affiliateUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}affiliate_url'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      matchConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}match_confidence'],
      ),
      matchType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_type'],
      ),
      pricePerUnitLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price_per_unit_label'],
      ),
      lastCheckedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_checked_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      ),
    );
  }

  @override
  $LocalProductOffersTable createAlias(String alias) {
    return $LocalProductOffersTable(attachedDatabase, alias);
  }
}

class LocalProductOffer extends DataClass
    implements Insertable<LocalProductOffer> {
  final String id;
  final String shoppingItemId;
  final String provider;
  final String productName;
  final String? brand;
  final double price;
  final double? deliveryCharge;
  final double effectivePrice;
  final String currency;
  final String? availability;
  final String? estimatedDelivery;
  final String? affiliateUrl;
  final String? imageUrl;
  final double? matchConfidence;
  final String? matchType;
  final String? pricePerUnitLabel;
  final DateTime? lastCheckedAt;
  final DateTime? cachedAt;
  const LocalProductOffer({
    required this.id,
    required this.shoppingItemId,
    required this.provider,
    required this.productName,
    this.brand,
    required this.price,
    this.deliveryCharge,
    required this.effectivePrice,
    required this.currency,
    this.availability,
    this.estimatedDelivery,
    this.affiliateUrl,
    this.imageUrl,
    this.matchConfidence,
    this.matchType,
    this.pricePerUnitLabel,
    this.lastCheckedAt,
    this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shopping_item_id'] = Variable<String>(shoppingItemId);
    map['provider'] = Variable<String>(provider);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['price'] = Variable<double>(price);
    if (!nullToAbsent || deliveryCharge != null) {
      map['delivery_charge'] = Variable<double>(deliveryCharge);
    }
    map['effective_price'] = Variable<double>(effectivePrice);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || availability != null) {
      map['availability'] = Variable<String>(availability);
    }
    if (!nullToAbsent || estimatedDelivery != null) {
      map['estimated_delivery'] = Variable<String>(estimatedDelivery);
    }
    if (!nullToAbsent || affiliateUrl != null) {
      map['affiliate_url'] = Variable<String>(affiliateUrl);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || matchConfidence != null) {
      map['match_confidence'] = Variable<double>(matchConfidence);
    }
    if (!nullToAbsent || matchType != null) {
      map['match_type'] = Variable<String>(matchType);
    }
    if (!nullToAbsent || pricePerUnitLabel != null) {
      map['price_per_unit_label'] = Variable<String>(pricePerUnitLabel);
    }
    if (!nullToAbsent || lastCheckedAt != null) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt);
    }
    if (!nullToAbsent || cachedAt != null) {
      map['cached_at'] = Variable<DateTime>(cachedAt);
    }
    return map;
  }

  LocalProductOffersCompanion toCompanion(bool nullToAbsent) {
    return LocalProductOffersCompanion(
      id: Value(id),
      shoppingItemId: Value(shoppingItemId),
      provider: Value(provider),
      productName: Value(productName),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      price: Value(price),
      deliveryCharge: deliveryCharge == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryCharge),
      effectivePrice: Value(effectivePrice),
      currency: Value(currency),
      availability: availability == null && nullToAbsent
          ? const Value.absent()
          : Value(availability),
      estimatedDelivery: estimatedDelivery == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedDelivery),
      affiliateUrl: affiliateUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(affiliateUrl),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      matchConfidence: matchConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(matchConfidence),
      matchType: matchType == null && nullToAbsent
          ? const Value.absent()
          : Value(matchType),
      pricePerUnitLabel: pricePerUnitLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(pricePerUnitLabel),
      lastCheckedAt: lastCheckedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckedAt),
      cachedAt: cachedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cachedAt),
    );
  }

  factory LocalProductOffer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProductOffer(
      id: serializer.fromJson<String>(json['id']),
      shoppingItemId: serializer.fromJson<String>(json['shoppingItemId']),
      provider: serializer.fromJson<String>(json['provider']),
      productName: serializer.fromJson<String>(json['productName']),
      brand: serializer.fromJson<String?>(json['brand']),
      price: serializer.fromJson<double>(json['price']),
      deliveryCharge: serializer.fromJson<double?>(json['deliveryCharge']),
      effectivePrice: serializer.fromJson<double>(json['effectivePrice']),
      currency: serializer.fromJson<String>(json['currency']),
      availability: serializer.fromJson<String?>(json['availability']),
      estimatedDelivery: serializer.fromJson<String?>(
        json['estimatedDelivery'],
      ),
      affiliateUrl: serializer.fromJson<String?>(json['affiliateUrl']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      matchConfidence: serializer.fromJson<double?>(json['matchConfidence']),
      matchType: serializer.fromJson<String?>(json['matchType']),
      pricePerUnitLabel: serializer.fromJson<String?>(
        json['pricePerUnitLabel'],
      ),
      lastCheckedAt: serializer.fromJson<DateTime?>(json['lastCheckedAt']),
      cachedAt: serializer.fromJson<DateTime?>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shoppingItemId': serializer.toJson<String>(shoppingItemId),
      'provider': serializer.toJson<String>(provider),
      'productName': serializer.toJson<String>(productName),
      'brand': serializer.toJson<String?>(brand),
      'price': serializer.toJson<double>(price),
      'deliveryCharge': serializer.toJson<double?>(deliveryCharge),
      'effectivePrice': serializer.toJson<double>(effectivePrice),
      'currency': serializer.toJson<String>(currency),
      'availability': serializer.toJson<String?>(availability),
      'estimatedDelivery': serializer.toJson<String?>(estimatedDelivery),
      'affiliateUrl': serializer.toJson<String?>(affiliateUrl),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'matchConfidence': serializer.toJson<double?>(matchConfidence),
      'matchType': serializer.toJson<String?>(matchType),
      'pricePerUnitLabel': serializer.toJson<String?>(pricePerUnitLabel),
      'lastCheckedAt': serializer.toJson<DateTime?>(lastCheckedAt),
      'cachedAt': serializer.toJson<DateTime?>(cachedAt),
    };
  }

  LocalProductOffer copyWith({
    String? id,
    String? shoppingItemId,
    String? provider,
    String? productName,
    Value<String?> brand = const Value.absent(),
    double? price,
    Value<double?> deliveryCharge = const Value.absent(),
    double? effectivePrice,
    String? currency,
    Value<String?> availability = const Value.absent(),
    Value<String?> estimatedDelivery = const Value.absent(),
    Value<String?> affiliateUrl = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<double?> matchConfidence = const Value.absent(),
    Value<String?> matchType = const Value.absent(),
    Value<String?> pricePerUnitLabel = const Value.absent(),
    Value<DateTime?> lastCheckedAt = const Value.absent(),
    Value<DateTime?> cachedAt = const Value.absent(),
  }) => LocalProductOffer(
    id: id ?? this.id,
    shoppingItemId: shoppingItemId ?? this.shoppingItemId,
    provider: provider ?? this.provider,
    productName: productName ?? this.productName,
    brand: brand.present ? brand.value : this.brand,
    price: price ?? this.price,
    deliveryCharge: deliveryCharge.present
        ? deliveryCharge.value
        : this.deliveryCharge,
    effectivePrice: effectivePrice ?? this.effectivePrice,
    currency: currency ?? this.currency,
    availability: availability.present ? availability.value : this.availability,
    estimatedDelivery: estimatedDelivery.present
        ? estimatedDelivery.value
        : this.estimatedDelivery,
    affiliateUrl: affiliateUrl.present ? affiliateUrl.value : this.affiliateUrl,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    matchConfidence: matchConfidence.present
        ? matchConfidence.value
        : this.matchConfidence,
    matchType: matchType.present ? matchType.value : this.matchType,
    pricePerUnitLabel: pricePerUnitLabel.present
        ? pricePerUnitLabel.value
        : this.pricePerUnitLabel,
    lastCheckedAt: lastCheckedAt.present
        ? lastCheckedAt.value
        : this.lastCheckedAt,
    cachedAt: cachedAt.present ? cachedAt.value : this.cachedAt,
  );
  LocalProductOffer copyWithCompanion(LocalProductOffersCompanion data) {
    return LocalProductOffer(
      id: data.id.present ? data.id.value : this.id,
      shoppingItemId: data.shoppingItemId.present
          ? data.shoppingItemId.value
          : this.shoppingItemId,
      provider: data.provider.present ? data.provider.value : this.provider,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      brand: data.brand.present ? data.brand.value : this.brand,
      price: data.price.present ? data.price.value : this.price,
      deliveryCharge: data.deliveryCharge.present
          ? data.deliveryCharge.value
          : this.deliveryCharge,
      effectivePrice: data.effectivePrice.present
          ? data.effectivePrice.value
          : this.effectivePrice,
      currency: data.currency.present ? data.currency.value : this.currency,
      availability: data.availability.present
          ? data.availability.value
          : this.availability,
      estimatedDelivery: data.estimatedDelivery.present
          ? data.estimatedDelivery.value
          : this.estimatedDelivery,
      affiliateUrl: data.affiliateUrl.present
          ? data.affiliateUrl.value
          : this.affiliateUrl,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      matchConfidence: data.matchConfidence.present
          ? data.matchConfidence.value
          : this.matchConfidence,
      matchType: data.matchType.present ? data.matchType.value : this.matchType,
      pricePerUnitLabel: data.pricePerUnitLabel.present
          ? data.pricePerUnitLabel.value
          : this.pricePerUnitLabel,
      lastCheckedAt: data.lastCheckedAt.present
          ? data.lastCheckedAt.value
          : this.lastCheckedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductOffer(')
          ..write('id: $id, ')
          ..write('shoppingItemId: $shoppingItemId, ')
          ..write('provider: $provider, ')
          ..write('productName: $productName, ')
          ..write('brand: $brand, ')
          ..write('price: $price, ')
          ..write('deliveryCharge: $deliveryCharge, ')
          ..write('effectivePrice: $effectivePrice, ')
          ..write('currency: $currency, ')
          ..write('availability: $availability, ')
          ..write('estimatedDelivery: $estimatedDelivery, ')
          ..write('affiliateUrl: $affiliateUrl, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('matchConfidence: $matchConfidence, ')
          ..write('matchType: $matchType, ')
          ..write('pricePerUnitLabel: $pricePerUnitLabel, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shoppingItemId,
    provider,
    productName,
    brand,
    price,
    deliveryCharge,
    effectivePrice,
    currency,
    availability,
    estimatedDelivery,
    affiliateUrl,
    imageUrl,
    matchConfidence,
    matchType,
    pricePerUnitLabel,
    lastCheckedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProductOffer &&
          other.id == this.id &&
          other.shoppingItemId == this.shoppingItemId &&
          other.provider == this.provider &&
          other.productName == this.productName &&
          other.brand == this.brand &&
          other.price == this.price &&
          other.deliveryCharge == this.deliveryCharge &&
          other.effectivePrice == this.effectivePrice &&
          other.currency == this.currency &&
          other.availability == this.availability &&
          other.estimatedDelivery == this.estimatedDelivery &&
          other.affiliateUrl == this.affiliateUrl &&
          other.imageUrl == this.imageUrl &&
          other.matchConfidence == this.matchConfidence &&
          other.matchType == this.matchType &&
          other.pricePerUnitLabel == this.pricePerUnitLabel &&
          other.lastCheckedAt == this.lastCheckedAt &&
          other.cachedAt == this.cachedAt);
}

class LocalProductOffersCompanion extends UpdateCompanion<LocalProductOffer> {
  final Value<String> id;
  final Value<String> shoppingItemId;
  final Value<String> provider;
  final Value<String> productName;
  final Value<String?> brand;
  final Value<double> price;
  final Value<double?> deliveryCharge;
  final Value<double> effectivePrice;
  final Value<String> currency;
  final Value<String?> availability;
  final Value<String?> estimatedDelivery;
  final Value<String?> affiliateUrl;
  final Value<String?> imageUrl;
  final Value<double?> matchConfidence;
  final Value<String?> matchType;
  final Value<String?> pricePerUnitLabel;
  final Value<DateTime?> lastCheckedAt;
  final Value<DateTime?> cachedAt;
  final Value<int> rowid;
  const LocalProductOffersCompanion({
    this.id = const Value.absent(),
    this.shoppingItemId = const Value.absent(),
    this.provider = const Value.absent(),
    this.productName = const Value.absent(),
    this.brand = const Value.absent(),
    this.price = const Value.absent(),
    this.deliveryCharge = const Value.absent(),
    this.effectivePrice = const Value.absent(),
    this.currency = const Value.absent(),
    this.availability = const Value.absent(),
    this.estimatedDelivery = const Value.absent(),
    this.affiliateUrl = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.matchConfidence = const Value.absent(),
    this.matchType = const Value.absent(),
    this.pricePerUnitLabel = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductOffersCompanion.insert({
    required String id,
    required String shoppingItemId,
    required String provider,
    required String productName,
    this.brand = const Value.absent(),
    required double price,
    this.deliveryCharge = const Value.absent(),
    required double effectivePrice,
    this.currency = const Value.absent(),
    this.availability = const Value.absent(),
    this.estimatedDelivery = const Value.absent(),
    this.affiliateUrl = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.matchConfidence = const Value.absent(),
    this.matchType = const Value.absent(),
    this.pricePerUnitLabel = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shoppingItemId = Value(shoppingItemId),
       provider = Value(provider),
       productName = Value(productName),
       price = Value(price),
       effectivePrice = Value(effectivePrice);
  static Insertable<LocalProductOffer> custom({
    Expression<String>? id,
    Expression<String>? shoppingItemId,
    Expression<String>? provider,
    Expression<String>? productName,
    Expression<String>? brand,
    Expression<double>? price,
    Expression<double>? deliveryCharge,
    Expression<double>? effectivePrice,
    Expression<String>? currency,
    Expression<String>? availability,
    Expression<String>? estimatedDelivery,
    Expression<String>? affiliateUrl,
    Expression<String>? imageUrl,
    Expression<double>? matchConfidence,
    Expression<String>? matchType,
    Expression<String>? pricePerUnitLabel,
    Expression<DateTime>? lastCheckedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shoppingItemId != null) 'shopping_item_id': shoppingItemId,
      if (provider != null) 'provider': provider,
      if (productName != null) 'product_name': productName,
      if (brand != null) 'brand': brand,
      if (price != null) 'price': price,
      if (deliveryCharge != null) 'delivery_charge': deliveryCharge,
      if (effectivePrice != null) 'effective_price': effectivePrice,
      if (currency != null) 'currency': currency,
      if (availability != null) 'availability': availability,
      if (estimatedDelivery != null) 'estimated_delivery': estimatedDelivery,
      if (affiliateUrl != null) 'affiliate_url': affiliateUrl,
      if (imageUrl != null) 'image_url': imageUrl,
      if (matchConfidence != null) 'match_confidence': matchConfidence,
      if (matchType != null) 'match_type': matchType,
      if (pricePerUnitLabel != null) 'price_per_unit_label': pricePerUnitLabel,
      if (lastCheckedAt != null) 'last_checked_at': lastCheckedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductOffersCompanion copyWith({
    Value<String>? id,
    Value<String>? shoppingItemId,
    Value<String>? provider,
    Value<String>? productName,
    Value<String?>? brand,
    Value<double>? price,
    Value<double?>? deliveryCharge,
    Value<double>? effectivePrice,
    Value<String>? currency,
    Value<String?>? availability,
    Value<String?>? estimatedDelivery,
    Value<String?>? affiliateUrl,
    Value<String?>? imageUrl,
    Value<double?>? matchConfidence,
    Value<String?>? matchType,
    Value<String?>? pricePerUnitLabel,
    Value<DateTime?>? lastCheckedAt,
    Value<DateTime?>? cachedAt,
    Value<int>? rowid,
  }) {
    return LocalProductOffersCompanion(
      id: id ?? this.id,
      shoppingItemId: shoppingItemId ?? this.shoppingItemId,
      provider: provider ?? this.provider,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      effectivePrice: effectivePrice ?? this.effectivePrice,
      currency: currency ?? this.currency,
      availability: availability ?? this.availability,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      affiliateUrl: affiliateUrl ?? this.affiliateUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      matchConfidence: matchConfidence ?? this.matchConfidence,
      matchType: matchType ?? this.matchType,
      pricePerUnitLabel: pricePerUnitLabel ?? this.pricePerUnitLabel,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shoppingItemId.present) {
      map['shopping_item_id'] = Variable<String>(shoppingItemId.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (deliveryCharge.present) {
      map['delivery_charge'] = Variable<double>(deliveryCharge.value);
    }
    if (effectivePrice.present) {
      map['effective_price'] = Variable<double>(effectivePrice.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (availability.present) {
      map['availability'] = Variable<String>(availability.value);
    }
    if (estimatedDelivery.present) {
      map['estimated_delivery'] = Variable<String>(estimatedDelivery.value);
    }
    if (affiliateUrl.present) {
      map['affiliate_url'] = Variable<String>(affiliateUrl.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (matchConfidence.present) {
      map['match_confidence'] = Variable<double>(matchConfidence.value);
    }
    if (matchType.present) {
      map['match_type'] = Variable<String>(matchType.value);
    }
    if (pricePerUnitLabel.present) {
      map['price_per_unit_label'] = Variable<String>(pricePerUnitLabel.value);
    }
    if (lastCheckedAt.present) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductOffersCompanion(')
          ..write('id: $id, ')
          ..write('shoppingItemId: $shoppingItemId, ')
          ..write('provider: $provider, ')
          ..write('productName: $productName, ')
          ..write('brand: $brand, ')
          ..write('price: $price, ')
          ..write('deliveryCharge: $deliveryCharge, ')
          ..write('effectivePrice: $effectivePrice, ')
          ..write('currency: $currency, ')
          ..write('availability: $availability, ')
          ..write('estimatedDelivery: $estimatedDelivery, ')
          ..write('affiliateUrl: $affiliateUrl, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('matchConfidence: $matchConfidence, ')
          ..write('matchType: $matchType, ')
          ..write('pricePerUnitLabel: $pricePerUnitLabel, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProductsTable extends LocalProducts
    with TableInfo<$LocalProductsTable, LocalProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeTypeMeta = const VerificationMeta(
    'barcodeType',
  );
  @override
  late final GeneratedColumn<String> barcodeType = GeneratedColumn<String>(
    'barcode_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EAN_13'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('General'),
  );
  static const VerificationMeta _packageSizeMeta = const VerificationMeta(
    'packageSize',
  );
  @override
  late final GeneratedColumn<double> packageSize = GeneratedColumn<double>(
    'package_size',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pcs'),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LOCAL'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    barcode,
    barcodeType,
    name,
    normalizedName,
    brand,
    categoryId,
    categoryName,
    packageSize,
    unit,
    imageUrl,
    source,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('barcode_type')) {
      context.handle(
        _barcodeTypeMeta,
        barcodeType.isAcceptableOrUnknown(
          data['barcode_type']!,
          _barcodeTypeMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('package_size')) {
      context.handle(
        _packageSizeMeta,
        packageSize.isAcceptableOrUnknown(
          data['package_size']!,
          _packageSizeMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProduct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      barcodeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode_type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      packageSize: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}package_size'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalProductsTable createAlias(String alias) {
    return $LocalProductsTable(attachedDatabase, alias);
  }
}

class LocalProduct extends DataClass implements Insertable<LocalProduct> {
  final String id;
  final String? barcode;
  final String barcodeType;
  final String name;
  final String normalizedName;
  final String? brand;
  final String? categoryId;
  final String categoryName;
  final double? packageSize;
  final String unit;
  final String? imageUrl;
  final String source;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const LocalProduct({
    required this.id,
    this.barcode,
    required this.barcodeType,
    required this.name,
    required this.normalizedName,
    this.brand,
    this.categoryId,
    required this.categoryName,
    this.packageSize,
    required this.unit,
    this.imageUrl,
    required this.source,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['barcode_type'] = Variable<String>(barcodeType);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['category_name'] = Variable<String>(categoryName);
    if (!nullToAbsent || packageSize != null) {
      map['package_size'] = Variable<double>(packageSize);
    }
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalProductsCompanion toCompanion(bool nullToAbsent) {
    return LocalProductsCompanion(
      id: Value(id),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      barcodeType: Value(barcodeType),
      name: Value(name),
      normalizedName: Value(normalizedName),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryName: Value(categoryName),
      packageSize: packageSize == null && nullToAbsent
          ? const Value.absent()
          : Value(packageSize),
      unit: Value(unit),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      source: Value(source),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProduct(
      id: serializer.fromJson<String>(json['id']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      barcodeType: serializer.fromJson<String>(json['barcodeType']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      brand: serializer.fromJson<String?>(json['brand']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      packageSize: serializer.fromJson<double?>(json['packageSize']),
      unit: serializer.fromJson<String>(json['unit']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'barcode': serializer.toJson<String?>(barcode),
      'barcodeType': serializer.toJson<String>(barcodeType),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'brand': serializer.toJson<String?>(brand),
      'categoryId': serializer.toJson<String?>(categoryId),
      'categoryName': serializer.toJson<String>(categoryName),
      'packageSize': serializer.toJson<double?>(packageSize),
      'unit': serializer.toJson<String>(unit),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalProduct copyWith({
    String? id,
    Value<String?> barcode = const Value.absent(),
    String? barcodeType,
    String? name,
    String? normalizedName,
    Value<String?> brand = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    String? categoryName,
    Value<double?> packageSize = const Value.absent(),
    String? unit,
    Value<String?> imageUrl = const Value.absent(),
    String? source,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalProduct(
    id: id ?? this.id,
    barcode: barcode.present ? barcode.value : this.barcode,
    barcodeType: barcodeType ?? this.barcodeType,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    brand: brand.present ? brand.value : this.brand,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    packageSize: packageSize.present ? packageSize.value : this.packageSize,
    unit: unit ?? this.unit,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    source: source ?? this.source,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalProduct copyWithCompanion(LocalProductsCompanion data) {
    return LocalProduct(
      id: data.id.present ? data.id.value : this.id,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      barcodeType: data.barcodeType.present
          ? data.barcodeType.value
          : this.barcodeType,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      brand: data.brand.present ? data.brand.value : this.brand,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      packageSize: data.packageSize.present
          ? data.packageSize.value
          : this.packageSize,
      unit: data.unit.present ? data.unit.value : this.unit,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProduct(')
          ..write('id: $id, ')
          ..write('barcode: $barcode, ')
          ..write('barcodeType: $barcodeType, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('brand: $brand, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('packageSize: $packageSize, ')
          ..write('unit: $unit, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    barcode,
    barcodeType,
    name,
    normalizedName,
    brand,
    categoryId,
    categoryName,
    packageSize,
    unit,
    imageUrl,
    source,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProduct &&
          other.id == this.id &&
          other.barcode == this.barcode &&
          other.barcodeType == this.barcodeType &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.brand == this.brand &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.packageSize == this.packageSize &&
          other.unit == this.unit &&
          other.imageUrl == this.imageUrl &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalProductsCompanion extends UpdateCompanion<LocalProduct> {
  final Value<String> id;
  final Value<String?> barcode;
  final Value<String> barcodeType;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<String?> brand;
  final Value<String?> categoryId;
  final Value<String> categoryName;
  final Value<double?> packageSize;
  final Value<String> unit;
  final Value<String?> imageUrl;
  final Value<String> source;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalProductsCompanion({
    this.id = const Value.absent(),
    this.barcode = const Value.absent(),
    this.barcodeType = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.brand = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.packageSize = const Value.absent(),
    this.unit = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductsCompanion.insert({
    required String id,
    this.barcode = const Value.absent(),
    this.barcodeType = const Value.absent(),
    required String name,
    required String normalizedName,
    this.brand = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.packageSize = const Value.absent(),
    this.unit = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       normalizedName = Value(normalizedName);
  static Insertable<LocalProduct> custom({
    Expression<String>? id,
    Expression<String>? barcode,
    Expression<String>? barcodeType,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<String>? brand,
    Expression<String>? categoryId,
    Expression<String>? categoryName,
    Expression<double>? packageSize,
    Expression<String>? unit,
    Expression<String>? imageUrl,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (barcode != null) 'barcode': barcode,
      if (barcodeType != null) 'barcode_type': barcodeType,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (brand != null) 'brand': brand,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (packageSize != null) 'package_size': packageSize,
      if (unit != null) 'unit': unit,
      if (imageUrl != null) 'image_url': imageUrl,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductsCompanion copyWith({
    Value<String>? id,
    Value<String?>? barcode,
    Value<String>? barcodeType,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<String?>? brand,
    Value<String?>? categoryId,
    Value<String>? categoryName,
    Value<double?>? packageSize,
    Value<String>? unit,
    Value<String?>? imageUrl,
    Value<String>? source,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalProductsCompanion(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      barcodeType: barcodeType ?? this.barcodeType,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      brand: brand ?? this.brand,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      packageSize: packageSize ?? this.packageSize,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (barcodeType.present) {
      map['barcode_type'] = Variable<String>(barcodeType.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (packageSize.present) {
      map['package_size'] = Variable<double>(packageSize.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductsCompanion(')
          ..write('id: $id, ')
          ..write('barcode: $barcode, ')
          ..write('barcodeType: $barcodeType, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('brand: $brand, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('packageSize: $packageSize, ')
          ..write('unit: $unit, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalConsumptionProfilesTable extends LocalConsumptionProfiles
    with TableInfo<$LocalConsumptionProfilesTable, LocalConsumptionProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalConsumptionProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inventoryItemIdMeta = const VerificationMeta(
    'inventoryItemId',
  );
  @override
  late final GeneratedColumn<String> inventoryItemId = GeneratedColumn<String>(
    'inventory_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averageDailyConsumptionMeta =
      const VerificationMeta('averageDailyConsumption');
  @override
  late final GeneratedColumn<double> averageDailyConsumption =
      GeneratedColumn<double>(
        'average_daily_consumption',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _weightedDailyConsumptionMeta =
      const VerificationMeta('weightedDailyConsumption');
  @override
  late final GeneratedColumn<double> weightedDailyConsumption =
      GeneratedColumn<double>(
        'weighted_daily_consumption',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _typicalIntervalDaysMeta =
      const VerificationMeta('typicalIntervalDays');
  @override
  late final GeneratedColumn<double> typicalIntervalDays =
      GeneratedColumn<double>(
        'typical_interval_days',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(7.0),
      );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LOW'),
  );
  static const VerificationMeta _estimatedDaysRemainingMeta =
      const VerificationMeta('estimatedDaysRemaining');
  @override
  late final GeneratedColumn<int> estimatedDaysRemaining = GeneratedColumn<int>(
    'estimated_days_remaining',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    homeId,
    inventoryItemId,
    itemName,
    averageDailyConsumption,
    weightedDailyConsumption,
    typicalIntervalDays,
    confidence,
    estimatedDaysRemaining,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_consumption_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalConsumptionProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('inventory_item_id')) {
      context.handle(
        _inventoryItemIdMeta,
        inventoryItemId.isAcceptableOrUnknown(
          data['inventory_item_id']!,
          _inventoryItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventoryItemIdMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('average_daily_consumption')) {
      context.handle(
        _averageDailyConsumptionMeta,
        averageDailyConsumption.isAcceptableOrUnknown(
          data['average_daily_consumption']!,
          _averageDailyConsumptionMeta,
        ),
      );
    }
    if (data.containsKey('weighted_daily_consumption')) {
      context.handle(
        _weightedDailyConsumptionMeta,
        weightedDailyConsumption.isAcceptableOrUnknown(
          data['weighted_daily_consumption']!,
          _weightedDailyConsumptionMeta,
        ),
      );
    }
    if (data.containsKey('typical_interval_days')) {
      context.handle(
        _typicalIntervalDaysMeta,
        typicalIntervalDays.isAcceptableOrUnknown(
          data['typical_interval_days']!,
          _typicalIntervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('estimated_days_remaining')) {
      context.handle(
        _estimatedDaysRemainingMeta,
        estimatedDaysRemaining.isAcceptableOrUnknown(
          data['estimated_days_remaining']!,
          _estimatedDaysRemainingMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalConsumptionProfile map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalConsumptionProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      inventoryItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_item_id'],
      )!,
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      averageDailyConsumption: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_daily_consumption'],
      )!,
      weightedDailyConsumption: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weighted_daily_consumption'],
      )!,
      typicalIntervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}typical_interval_days'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence'],
      )!,
      estimatedDaysRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_days_remaining'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalConsumptionProfilesTable createAlias(String alias) {
    return $LocalConsumptionProfilesTable(attachedDatabase, alias);
  }
}

class LocalConsumptionProfile extends DataClass
    implements Insertable<LocalConsumptionProfile> {
  final String id;
  final String homeId;
  final String inventoryItemId;
  final String itemName;
  final double averageDailyConsumption;
  final double weightedDailyConsumption;
  final double typicalIntervalDays;
  final String confidence;
  final int? estimatedDaysRemaining;
  final DateTime? updatedAt;
  const LocalConsumptionProfile({
    required this.id,
    required this.homeId,
    required this.inventoryItemId,
    required this.itemName,
    required this.averageDailyConsumption,
    required this.weightedDailyConsumption,
    required this.typicalIntervalDays,
    required this.confidence,
    this.estimatedDaysRemaining,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['home_id'] = Variable<String>(homeId);
    map['inventory_item_id'] = Variable<String>(inventoryItemId);
    map['item_name'] = Variable<String>(itemName);
    map['average_daily_consumption'] = Variable<double>(
      averageDailyConsumption,
    );
    map['weighted_daily_consumption'] = Variable<double>(
      weightedDailyConsumption,
    );
    map['typical_interval_days'] = Variable<double>(typicalIntervalDays);
    map['confidence'] = Variable<String>(confidence);
    if (!nullToAbsent || estimatedDaysRemaining != null) {
      map['estimated_days_remaining'] = Variable<int>(estimatedDaysRemaining);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalConsumptionProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalConsumptionProfilesCompanion(
      id: Value(id),
      homeId: Value(homeId),
      inventoryItemId: Value(inventoryItemId),
      itemName: Value(itemName),
      averageDailyConsumption: Value(averageDailyConsumption),
      weightedDailyConsumption: Value(weightedDailyConsumption),
      typicalIntervalDays: Value(typicalIntervalDays),
      confidence: Value(confidence),
      estimatedDaysRemaining: estimatedDaysRemaining == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedDaysRemaining),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalConsumptionProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalConsumptionProfile(
      id: serializer.fromJson<String>(json['id']),
      homeId: serializer.fromJson<String>(json['homeId']),
      inventoryItemId: serializer.fromJson<String>(json['inventoryItemId']),
      itemName: serializer.fromJson<String>(json['itemName']),
      averageDailyConsumption: serializer.fromJson<double>(
        json['averageDailyConsumption'],
      ),
      weightedDailyConsumption: serializer.fromJson<double>(
        json['weightedDailyConsumption'],
      ),
      typicalIntervalDays: serializer.fromJson<double>(
        json['typicalIntervalDays'],
      ),
      confidence: serializer.fromJson<String>(json['confidence']),
      estimatedDaysRemaining: serializer.fromJson<int?>(
        json['estimatedDaysRemaining'],
      ),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'homeId': serializer.toJson<String>(homeId),
      'inventoryItemId': serializer.toJson<String>(inventoryItemId),
      'itemName': serializer.toJson<String>(itemName),
      'averageDailyConsumption': serializer.toJson<double>(
        averageDailyConsumption,
      ),
      'weightedDailyConsumption': serializer.toJson<double>(
        weightedDailyConsumption,
      ),
      'typicalIntervalDays': serializer.toJson<double>(typicalIntervalDays),
      'confidence': serializer.toJson<String>(confidence),
      'estimatedDaysRemaining': serializer.toJson<int?>(estimatedDaysRemaining),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalConsumptionProfile copyWith({
    String? id,
    String? homeId,
    String? inventoryItemId,
    String? itemName,
    double? averageDailyConsumption,
    double? weightedDailyConsumption,
    double? typicalIntervalDays,
    String? confidence,
    Value<int?> estimatedDaysRemaining = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalConsumptionProfile(
    id: id ?? this.id,
    homeId: homeId ?? this.homeId,
    inventoryItemId: inventoryItemId ?? this.inventoryItemId,
    itemName: itemName ?? this.itemName,
    averageDailyConsumption:
        averageDailyConsumption ?? this.averageDailyConsumption,
    weightedDailyConsumption:
        weightedDailyConsumption ?? this.weightedDailyConsumption,
    typicalIntervalDays: typicalIntervalDays ?? this.typicalIntervalDays,
    confidence: confidence ?? this.confidence,
    estimatedDaysRemaining: estimatedDaysRemaining.present
        ? estimatedDaysRemaining.value
        : this.estimatedDaysRemaining,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalConsumptionProfile copyWithCompanion(
    LocalConsumptionProfilesCompanion data,
  ) {
    return LocalConsumptionProfile(
      id: data.id.present ? data.id.value : this.id,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      inventoryItemId: data.inventoryItemId.present
          ? data.inventoryItemId.value
          : this.inventoryItemId,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      averageDailyConsumption: data.averageDailyConsumption.present
          ? data.averageDailyConsumption.value
          : this.averageDailyConsumption,
      weightedDailyConsumption: data.weightedDailyConsumption.present
          ? data.weightedDailyConsumption.value
          : this.weightedDailyConsumption,
      typicalIntervalDays: data.typicalIntervalDays.present
          ? data.typicalIntervalDays.value
          : this.typicalIntervalDays,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      estimatedDaysRemaining: data.estimatedDaysRemaining.present
          ? data.estimatedDaysRemaining.value
          : this.estimatedDaysRemaining,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalConsumptionProfile(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('itemName: $itemName, ')
          ..write('averageDailyConsumption: $averageDailyConsumption, ')
          ..write('weightedDailyConsumption: $weightedDailyConsumption, ')
          ..write('typicalIntervalDays: $typicalIntervalDays, ')
          ..write('confidence: $confidence, ')
          ..write('estimatedDaysRemaining: $estimatedDaysRemaining, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    homeId,
    inventoryItemId,
    itemName,
    averageDailyConsumption,
    weightedDailyConsumption,
    typicalIntervalDays,
    confidence,
    estimatedDaysRemaining,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalConsumptionProfile &&
          other.id == this.id &&
          other.homeId == this.homeId &&
          other.inventoryItemId == this.inventoryItemId &&
          other.itemName == this.itemName &&
          other.averageDailyConsumption == this.averageDailyConsumption &&
          other.weightedDailyConsumption == this.weightedDailyConsumption &&
          other.typicalIntervalDays == this.typicalIntervalDays &&
          other.confidence == this.confidence &&
          other.estimatedDaysRemaining == this.estimatedDaysRemaining &&
          other.updatedAt == this.updatedAt);
}

class LocalConsumptionProfilesCompanion
    extends UpdateCompanion<LocalConsumptionProfile> {
  final Value<String> id;
  final Value<String> homeId;
  final Value<String> inventoryItemId;
  final Value<String> itemName;
  final Value<double> averageDailyConsumption;
  final Value<double> weightedDailyConsumption;
  final Value<double> typicalIntervalDays;
  final Value<String> confidence;
  final Value<int?> estimatedDaysRemaining;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalConsumptionProfilesCompanion({
    this.id = const Value.absent(),
    this.homeId = const Value.absent(),
    this.inventoryItemId = const Value.absent(),
    this.itemName = const Value.absent(),
    this.averageDailyConsumption = const Value.absent(),
    this.weightedDailyConsumption = const Value.absent(),
    this.typicalIntervalDays = const Value.absent(),
    this.confidence = const Value.absent(),
    this.estimatedDaysRemaining = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalConsumptionProfilesCompanion.insert({
    required String id,
    required String homeId,
    required String inventoryItemId,
    required String itemName,
    this.averageDailyConsumption = const Value.absent(),
    this.weightedDailyConsumption = const Value.absent(),
    this.typicalIntervalDays = const Value.absent(),
    this.confidence = const Value.absent(),
    this.estimatedDaysRemaining = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       homeId = Value(homeId),
       inventoryItemId = Value(inventoryItemId),
       itemName = Value(itemName);
  static Insertable<LocalConsumptionProfile> custom({
    Expression<String>? id,
    Expression<String>? homeId,
    Expression<String>? inventoryItemId,
    Expression<String>? itemName,
    Expression<double>? averageDailyConsumption,
    Expression<double>? weightedDailyConsumption,
    Expression<double>? typicalIntervalDays,
    Expression<String>? confidence,
    Expression<int>? estimatedDaysRemaining,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeId != null) 'home_id': homeId,
      if (inventoryItemId != null) 'inventory_item_id': inventoryItemId,
      if (itemName != null) 'item_name': itemName,
      if (averageDailyConsumption != null)
        'average_daily_consumption': averageDailyConsumption,
      if (weightedDailyConsumption != null)
        'weighted_daily_consumption': weightedDailyConsumption,
      if (typicalIntervalDays != null)
        'typical_interval_days': typicalIntervalDays,
      if (confidence != null) 'confidence': confidence,
      if (estimatedDaysRemaining != null)
        'estimated_days_remaining': estimatedDaysRemaining,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalConsumptionProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? homeId,
    Value<String>? inventoryItemId,
    Value<String>? itemName,
    Value<double>? averageDailyConsumption,
    Value<double>? weightedDailyConsumption,
    Value<double>? typicalIntervalDays,
    Value<String>? confidence,
    Value<int?>? estimatedDaysRemaining,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalConsumptionProfilesCompanion(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      itemName: itemName ?? this.itemName,
      averageDailyConsumption:
          averageDailyConsumption ?? this.averageDailyConsumption,
      weightedDailyConsumption:
          weightedDailyConsumption ?? this.weightedDailyConsumption,
      typicalIntervalDays: typicalIntervalDays ?? this.typicalIntervalDays,
      confidence: confidence ?? this.confidence,
      estimatedDaysRemaining:
          estimatedDaysRemaining ?? this.estimatedDaysRemaining,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (inventoryItemId.present) {
      map['inventory_item_id'] = Variable<String>(inventoryItemId.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (averageDailyConsumption.present) {
      map['average_daily_consumption'] = Variable<double>(
        averageDailyConsumption.value,
      );
    }
    if (weightedDailyConsumption.present) {
      map['weighted_daily_consumption'] = Variable<double>(
        weightedDailyConsumption.value,
      );
    }
    if (typicalIntervalDays.present) {
      map['typical_interval_days'] = Variable<double>(
        typicalIntervalDays.value,
      );
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (estimatedDaysRemaining.present) {
      map['estimated_days_remaining'] = Variable<int>(
        estimatedDaysRemaining.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalConsumptionProfilesCompanion(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('itemName: $itemName, ')
          ..write('averageDailyConsumption: $averageDailyConsumption, ')
          ..write('weightedDailyConsumption: $weightedDailyConsumption, ')
          ..write('typicalIntervalDays: $typicalIntervalDays, ')
          ..write('confidence: $confidence, ')
          ..write('estimatedDaysRemaining: $estimatedDaysRemaining, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalUsersTable localUsers = $LocalUsersTable(this);
  late final $LocalHomesTable localHomes = $LocalHomesTable(this);
  late final $LocalHomeMembersTable localHomeMembers = $LocalHomeMembersTable(
    this,
  );
  late final $LocalCategoriesTable localCategories = $LocalCategoriesTable(
    this,
  );
  late final $LocalInventoryItemsTable localInventoryItems =
      $LocalInventoryItemsTable(this);
  late final $LocalStockTransactionsTable localStockTransactions =
      $LocalStockTransactionsTable(this);
  late final $LocalShoppingListsTable localShoppingLists =
      $LocalShoppingListsTable(this);
  late final $LocalShoppingListItemsTable localShoppingListItems =
      $LocalShoppingListItemsTable(this);
  late final $LocalStoresTable localStores = $LocalStoresTable(this);
  late final $LocalPurchasesTable localPurchases = $LocalPurchasesTable(this);
  late final $LocalPurchaseItemsTable localPurchaseItems =
      $LocalPurchaseItemsTable(this);
  late final $LocalNotificationsTable localNotifications =
      $LocalNotificationsTable(this);
  late final $SyncQueueEntriesTable syncQueueEntries = $SyncQueueEntriesTable(
    this,
  );
  late final $SyncMetadataEntriesTable syncMetadataEntries =
      $SyncMetadataEntriesTable(this);
  late final $LocalProductOffersTable localProductOffers =
      $LocalProductOffersTable(this);
  late final $LocalProductsTable localProducts = $LocalProductsTable(this);
  late final $LocalConsumptionProfilesTable localConsumptionProfiles =
      $LocalConsumptionProfilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localUsers,
    localHomes,
    localHomeMembers,
    localCategories,
    localInventoryItems,
    localStockTransactions,
    localShoppingLists,
    localShoppingListItems,
    localStores,
    localPurchases,
    localPurchaseItems,
    localNotifications,
    syncQueueEntries,
    syncMetadataEntries,
    localProductOffers,
    localProducts,
    localConsumptionProfiles,
  ];
}

typedef $$LocalUsersTableCreateCompanionBuilder =
    LocalUsersCompanion Function({
      required String id,
      required String email,
      required String fullName,
      Value<String?> phoneNumber,
      Value<String?> avatarUrl,
      Value<bool> isActive,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalUsersTableUpdateCompanionBuilder =
    LocalUsersCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String> fullName,
      Value<String?> phoneNumber,
      Value<String?> avatarUrl,
      Value<bool> isActive,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalUsersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalUsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalUsersTable,
          LocalUser,
          $$LocalUsersTableFilterComposer,
          $$LocalUsersTableOrderingComposer,
          $$LocalUsersTableAnnotationComposer,
          $$LocalUsersTableCreateCompanionBuilder,
          $$LocalUsersTableUpdateCompanionBuilder,
          (
            LocalUser,
            BaseReferences<_$AppDatabase, $LocalUsersTable, LocalUser>,
          ),
          LocalUser,
          PrefetchHooks Function()
        > {
  $$LocalUsersTableTableManager(_$AppDatabase db, $LocalUsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUsersCompanion(
                id: id,
                email: email,
                fullName: fullName,
                phoneNumber: phoneNumber,
                avatarUrl: avatarUrl,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String email,
                required String fullName,
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUsersCompanion.insert(
                id: id,
                email: email,
                fullName: fullName,
                phoneNumber: phoneNumber,
                avatarUrl: avatarUrl,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalUsersTable,
      LocalUser,
      $$LocalUsersTableFilterComposer,
      $$LocalUsersTableOrderingComposer,
      $$LocalUsersTableAnnotationComposer,
      $$LocalUsersTableCreateCompanionBuilder,
      $$LocalUsersTableUpdateCompanionBuilder,
      (LocalUser, BaseReferences<_$AppDatabase, $LocalUsersTable, LocalUser>),
      LocalUser,
      PrefetchHooks Function()
    >;
typedef $$LocalHomesTableCreateCompanionBuilder =
    LocalHomesCompanion Function({
      required String id,
      required String name,
      required String inviteCode,
      Value<String?> createdBy,
      Value<String> currentUserRole,
      Value<int> memberCount,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalHomesTableUpdateCompanionBuilder =
    LocalHomesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> inviteCode,
      Value<String?> createdBy,
      Value<String> currentUserRole,
      Value<int> memberCount,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalHomesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalHomesTable> {
  $$LocalHomesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentUserRole => $composableBuilder(
    column: $table.currentUserRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalHomesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalHomesTable> {
  $$LocalHomesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentUserRole => $composableBuilder(
    column: $table.currentUserRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalHomesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalHomesTable> {
  $$LocalHomesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get currentUserRole => $composableBuilder(
    column: $table.currentUserRole,
    builder: (column) => column,
  );

  GeneratedColumn<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalHomesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalHomesTable,
          LocalHome,
          $$LocalHomesTableFilterComposer,
          $$LocalHomesTableOrderingComposer,
          $$LocalHomesTableAnnotationComposer,
          $$LocalHomesTableCreateCompanionBuilder,
          $$LocalHomesTableUpdateCompanionBuilder,
          (
            LocalHome,
            BaseReferences<_$AppDatabase, $LocalHomesTable, LocalHome>,
          ),
          LocalHome,
          PrefetchHooks Function()
        > {
  $$LocalHomesTableTableManager(_$AppDatabase db, $LocalHomesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalHomesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalHomesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalHomesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> inviteCode = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String> currentUserRole = const Value.absent(),
                Value<int> memberCount = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalHomesCompanion(
                id: id,
                name: name,
                inviteCode: inviteCode,
                createdBy: createdBy,
                currentUserRole: currentUserRole,
                memberCount: memberCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String inviteCode,
                Value<String?> createdBy = const Value.absent(),
                Value<String> currentUserRole = const Value.absent(),
                Value<int> memberCount = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalHomesCompanion.insert(
                id: id,
                name: name,
                inviteCode: inviteCode,
                createdBy: createdBy,
                currentUserRole: currentUserRole,
                memberCount: memberCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalHomesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalHomesTable,
      LocalHome,
      $$LocalHomesTableFilterComposer,
      $$LocalHomesTableOrderingComposer,
      $$LocalHomesTableAnnotationComposer,
      $$LocalHomesTableCreateCompanionBuilder,
      $$LocalHomesTableUpdateCompanionBuilder,
      (LocalHome, BaseReferences<_$AppDatabase, $LocalHomesTable, LocalHome>),
      LocalHome,
      PrefetchHooks Function()
    >;
typedef $$LocalHomeMembersTableCreateCompanionBuilder =
    LocalHomeMembersCompanion Function({
      required String id,
      required String homeId,
      required String userId,
      required String fullName,
      required String email,
      Value<String?> avatarUrl,
      required String role,
      Value<String?> joinedAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalHomeMembersTableUpdateCompanionBuilder =
    LocalHomeMembersCompanion Function({
      Value<String> id,
      Value<String> homeId,
      Value<String> userId,
      Value<String> fullName,
      Value<String> email,
      Value<String?> avatarUrl,
      Value<String> role,
      Value<String?> joinedAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalHomeMembersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalHomeMembersTable> {
  $$LocalHomeMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalHomeMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalHomeMembersTable> {
  $$LocalHomeMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalHomeMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalHomeMembersTable> {
  $$LocalHomeMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get homeId =>
      $composableBuilder(column: $table.homeId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalHomeMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalHomeMembersTable,
          LocalHomeMember,
          $$LocalHomeMembersTableFilterComposer,
          $$LocalHomeMembersTableOrderingComposer,
          $$LocalHomeMembersTableAnnotationComposer,
          $$LocalHomeMembersTableCreateCompanionBuilder,
          $$LocalHomeMembersTableUpdateCompanionBuilder,
          (
            LocalHomeMember,
            BaseReferences<
              _$AppDatabase,
              $LocalHomeMembersTable,
              LocalHomeMember
            >,
          ),
          LocalHomeMember,
          PrefetchHooks Function()
        > {
  $$LocalHomeMembersTableTableManager(
    _$AppDatabase db,
    $LocalHomeMembersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalHomeMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalHomeMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalHomeMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> homeId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> joinedAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalHomeMembersCompanion(
                id: id,
                homeId: homeId,
                userId: userId,
                fullName: fullName,
                email: email,
                avatarUrl: avatarUrl,
                role: role,
                joinedAt: joinedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String homeId,
                required String userId,
                required String fullName,
                required String email,
                Value<String?> avatarUrl = const Value.absent(),
                required String role,
                Value<String?> joinedAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalHomeMembersCompanion.insert(
                id: id,
                homeId: homeId,
                userId: userId,
                fullName: fullName,
                email: email,
                avatarUrl: avatarUrl,
                role: role,
                joinedAt: joinedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalHomeMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalHomeMembersTable,
      LocalHomeMember,
      $$LocalHomeMembersTableFilterComposer,
      $$LocalHomeMembersTableOrderingComposer,
      $$LocalHomeMembersTableAnnotationComposer,
      $$LocalHomeMembersTableCreateCompanionBuilder,
      $$LocalHomeMembersTableUpdateCompanionBuilder,
      (
        LocalHomeMember,
        BaseReferences<_$AppDatabase, $LocalHomeMembersTable, LocalHomeMember>,
      ),
      LocalHomeMember,
      PrefetchHooks Function()
    >;
typedef $$LocalCategoriesTableCreateCompanionBuilder =
    LocalCategoriesCompanion Function({
      required String id,
      required String homeId,
      required String name,
      Value<String> iconName,
      Value<String> colorHex,
      Value<int> sortOrder,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalCategoriesTableUpdateCompanionBuilder =
    LocalCategoriesCompanion Function({
      Value<String> id,
      Value<String> homeId,
      Value<String> name,
      Value<String> iconName,
      Value<String> colorHex,
      Value<int> sortOrder,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get homeId =>
      $composableBuilder(column: $table.homeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCategoriesTable,
          LocalCategory,
          $$LocalCategoriesTableFilterComposer,
          $$LocalCategoriesTableOrderingComposer,
          $$LocalCategoriesTableAnnotationComposer,
          $$LocalCategoriesTableCreateCompanionBuilder,
          $$LocalCategoriesTableUpdateCompanionBuilder,
          (
            LocalCategory,
            BaseReferences<_$AppDatabase, $LocalCategoriesTable, LocalCategory>,
          ),
          LocalCategory,
          PrefetchHooks Function()
        > {
  $$LocalCategoriesTableTableManager(
    _$AppDatabase db,
    $LocalCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> homeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCategoriesCompanion(
                id: id,
                homeId: homeId,
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String homeId,
                required String name,
                Value<String> iconName = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCategoriesCompanion.insert(
                id: id,
                homeId: homeId,
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCategoriesTable,
      LocalCategory,
      $$LocalCategoriesTableFilterComposer,
      $$LocalCategoriesTableOrderingComposer,
      $$LocalCategoriesTableAnnotationComposer,
      $$LocalCategoriesTableCreateCompanionBuilder,
      $$LocalCategoriesTableUpdateCompanionBuilder,
      (
        LocalCategory,
        BaseReferences<_$AppDatabase, $LocalCategoriesTable, LocalCategory>,
      ),
      LocalCategory,
      PrefetchHooks Function()
    >;
typedef $$LocalInventoryItemsTableCreateCompanionBuilder =
    LocalInventoryItemsCompanion Function({
      required String id,
      required String homeId,
      Value<String?> categoryId,
      Value<String> categoryName,
      Value<String> categoryIcon,
      Value<String> categoryColor,
      required String name,
      Value<String?> brand,
      Value<double> quantity,
      Value<String> unit,
      Value<double> minimumQuantity,
      Value<double?> maximumQuantity,
      Value<String?> storageLocation,
      Value<double?> purchasePrice,
      Value<String?> purchaseDate,
      Value<String?> expiryDate,
      Value<String?> imageUrl,
      Value<String?> notes,
      Value<String> stockStatus,
      Value<String> expiryStatus,
      Value<int?> daysUntilExpiry,
      Value<String?> barcode,
      Value<String?> productId,
      Value<String?> quantityStatus,
      Value<String> quantitySource,
      Value<String> confidence,
      Value<int?> estimatedDaysRemaining,
      Value<double?> estimatedDailyConsumption,
      Value<DateTime?> lastVerifiedAt,
      Value<DateTime?> lastEstimatedAt,
      Value<bool> isDeleted,
      Value<bool> isLocalOnly,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalInventoryItemsTableUpdateCompanionBuilder =
    LocalInventoryItemsCompanion Function({
      Value<String> id,
      Value<String> homeId,
      Value<String?> categoryId,
      Value<String> categoryName,
      Value<String> categoryIcon,
      Value<String> categoryColor,
      Value<String> name,
      Value<String?> brand,
      Value<double> quantity,
      Value<String> unit,
      Value<double> minimumQuantity,
      Value<double?> maximumQuantity,
      Value<String?> storageLocation,
      Value<double?> purchasePrice,
      Value<String?> purchaseDate,
      Value<String?> expiryDate,
      Value<String?> imageUrl,
      Value<String?> notes,
      Value<String> stockStatus,
      Value<String> expiryStatus,
      Value<int?> daysUntilExpiry,
      Value<String?> barcode,
      Value<String?> productId,
      Value<String?> quantityStatus,
      Value<String> quantitySource,
      Value<String> confidence,
      Value<int?> estimatedDaysRemaining,
      Value<double?> estimatedDailyConsumption,
      Value<DateTime?> lastVerifiedAt,
      Value<DateTime?> lastEstimatedAt,
      Value<bool> isDeleted,
      Value<bool> isLocalOnly,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalInventoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalInventoryItemsTable> {
  $$LocalInventoryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryIcon => $composableBuilder(
    column: $table.categoryIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryColor => $composableBuilder(
    column: $table.categoryColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minimumQuantity => $composableBuilder(
    column: $table.minimumQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maximumQuantity => $composableBuilder(
    column: $table.maximumQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageLocation => $composableBuilder(
    column: $table.storageLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stockStatus => $composableBuilder(
    column: $table.stockStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expiryStatus => $composableBuilder(
    column: $table.expiryStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get daysUntilExpiry => $composableBuilder(
    column: $table.daysUntilExpiry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityStatus => $composableBuilder(
    column: $table.quantityStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantitySource => $composableBuilder(
    column: $table.quantitySource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedDaysRemaining => $composableBuilder(
    column: $table.estimatedDaysRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get estimatedDailyConsumption => $composableBuilder(
    column: $table.estimatedDailyConsumption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastEstimatedAt => $composableBuilder(
    column: $table.lastEstimatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocalOnly => $composableBuilder(
    column: $table.isLocalOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalInventoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalInventoryItemsTable> {
  $$LocalInventoryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryIcon => $composableBuilder(
    column: $table.categoryIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryColor => $composableBuilder(
    column: $table.categoryColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minimumQuantity => $composableBuilder(
    column: $table.minimumQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maximumQuantity => $composableBuilder(
    column: $table.maximumQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageLocation => $composableBuilder(
    column: $table.storageLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockStatus => $composableBuilder(
    column: $table.stockStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expiryStatus => $composableBuilder(
    column: $table.expiryStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysUntilExpiry => $composableBuilder(
    column: $table.daysUntilExpiry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityStatus => $composableBuilder(
    column: $table.quantityStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantitySource => $composableBuilder(
    column: $table.quantitySource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedDaysRemaining => $composableBuilder(
    column: $table.estimatedDaysRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get estimatedDailyConsumption => $composableBuilder(
    column: $table.estimatedDailyConsumption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastEstimatedAt => $composableBuilder(
    column: $table.lastEstimatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocalOnly => $composableBuilder(
    column: $table.isLocalOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalInventoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalInventoryItemsTable> {
  $$LocalInventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get homeId =>
      $composableBuilder(column: $table.homeId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryIcon => $composableBuilder(
    column: $table.categoryIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryColor => $composableBuilder(
    column: $table.categoryColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get minimumQuantity => $composableBuilder(
    column: $table.minimumQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maximumQuantity => $composableBuilder(
    column: $table.maximumQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storageLocation => $composableBuilder(
    column: $table.storageLocation,
    builder: (column) => column,
  );

  GeneratedColumn<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get stockStatus => $composableBuilder(
    column: $table.stockStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expiryStatus => $composableBuilder(
    column: $table.expiryStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get daysUntilExpiry => $composableBuilder(
    column: $table.daysUntilExpiry,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get quantityStatus => $composableBuilder(
    column: $table.quantityStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quantitySource => $composableBuilder(
    column: $table.quantitySource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimatedDaysRemaining => $composableBuilder(
    column: $table.estimatedDaysRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<double> get estimatedDailyConsumption => $composableBuilder(
    column: $table.estimatedDailyConsumption,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastEstimatedAt => $composableBuilder(
    column: $table.lastEstimatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isLocalOnly => $composableBuilder(
    column: $table.isLocalOnly,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalInventoryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalInventoryItemsTable,
          LocalInventoryItem,
          $$LocalInventoryItemsTableFilterComposer,
          $$LocalInventoryItemsTableOrderingComposer,
          $$LocalInventoryItemsTableAnnotationComposer,
          $$LocalInventoryItemsTableCreateCompanionBuilder,
          $$LocalInventoryItemsTableUpdateCompanionBuilder,
          (
            LocalInventoryItem,
            BaseReferences<
              _$AppDatabase,
              $LocalInventoryItemsTable,
              LocalInventoryItem
            >,
          ),
          LocalInventoryItem,
          PrefetchHooks Function()
        > {
  $$LocalInventoryItemsTableTableManager(
    _$AppDatabase db,
    $LocalInventoryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalInventoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalInventoryItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalInventoryItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> homeId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<String> categoryIcon = const Value.absent(),
                Value<String> categoryColor = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> minimumQuantity = const Value.absent(),
                Value<double?> maximumQuantity = const Value.absent(),
                Value<String?> storageLocation = const Value.absent(),
                Value<double?> purchasePrice = const Value.absent(),
                Value<String?> purchaseDate = const Value.absent(),
                Value<String?> expiryDate = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> stockStatus = const Value.absent(),
                Value<String> expiryStatus = const Value.absent(),
                Value<int?> daysUntilExpiry = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> quantityStatus = const Value.absent(),
                Value<String> quantitySource = const Value.absent(),
                Value<String> confidence = const Value.absent(),
                Value<int?> estimatedDaysRemaining = const Value.absent(),
                Value<double?> estimatedDailyConsumption = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<DateTime?> lastEstimatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isLocalOnly = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryItemsCompanion(
                id: id,
                homeId: homeId,
                categoryId: categoryId,
                categoryName: categoryName,
                categoryIcon: categoryIcon,
                categoryColor: categoryColor,
                name: name,
                brand: brand,
                quantity: quantity,
                unit: unit,
                minimumQuantity: minimumQuantity,
                maximumQuantity: maximumQuantity,
                storageLocation: storageLocation,
                purchasePrice: purchasePrice,
                purchaseDate: purchaseDate,
                expiryDate: expiryDate,
                imageUrl: imageUrl,
                notes: notes,
                stockStatus: stockStatus,
                expiryStatus: expiryStatus,
                daysUntilExpiry: daysUntilExpiry,
                barcode: barcode,
                productId: productId,
                quantityStatus: quantityStatus,
                quantitySource: quantitySource,
                confidence: confidence,
                estimatedDaysRemaining: estimatedDaysRemaining,
                estimatedDailyConsumption: estimatedDailyConsumption,
                lastVerifiedAt: lastVerifiedAt,
                lastEstimatedAt: lastEstimatedAt,
                isDeleted: isDeleted,
                isLocalOnly: isLocalOnly,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String homeId,
                Value<String?> categoryId = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<String> categoryIcon = const Value.absent(),
                Value<String> categoryColor = const Value.absent(),
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> minimumQuantity = const Value.absent(),
                Value<double?> maximumQuantity = const Value.absent(),
                Value<String?> storageLocation = const Value.absent(),
                Value<double?> purchasePrice = const Value.absent(),
                Value<String?> purchaseDate = const Value.absent(),
                Value<String?> expiryDate = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> stockStatus = const Value.absent(),
                Value<String> expiryStatus = const Value.absent(),
                Value<int?> daysUntilExpiry = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> quantityStatus = const Value.absent(),
                Value<String> quantitySource = const Value.absent(),
                Value<String> confidence = const Value.absent(),
                Value<int?> estimatedDaysRemaining = const Value.absent(),
                Value<double?> estimatedDailyConsumption = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<DateTime?> lastEstimatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isLocalOnly = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryItemsCompanion.insert(
                id: id,
                homeId: homeId,
                categoryId: categoryId,
                categoryName: categoryName,
                categoryIcon: categoryIcon,
                categoryColor: categoryColor,
                name: name,
                brand: brand,
                quantity: quantity,
                unit: unit,
                minimumQuantity: minimumQuantity,
                maximumQuantity: maximumQuantity,
                storageLocation: storageLocation,
                purchasePrice: purchasePrice,
                purchaseDate: purchaseDate,
                expiryDate: expiryDate,
                imageUrl: imageUrl,
                notes: notes,
                stockStatus: stockStatus,
                expiryStatus: expiryStatus,
                daysUntilExpiry: daysUntilExpiry,
                barcode: barcode,
                productId: productId,
                quantityStatus: quantityStatus,
                quantitySource: quantitySource,
                confidence: confidence,
                estimatedDaysRemaining: estimatedDaysRemaining,
                estimatedDailyConsumption: estimatedDailyConsumption,
                lastVerifiedAt: lastVerifiedAt,
                lastEstimatedAt: lastEstimatedAt,
                isDeleted: isDeleted,
                isLocalOnly: isLocalOnly,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalInventoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalInventoryItemsTable,
      LocalInventoryItem,
      $$LocalInventoryItemsTableFilterComposer,
      $$LocalInventoryItemsTableOrderingComposer,
      $$LocalInventoryItemsTableAnnotationComposer,
      $$LocalInventoryItemsTableCreateCompanionBuilder,
      $$LocalInventoryItemsTableUpdateCompanionBuilder,
      (
        LocalInventoryItem,
        BaseReferences<
          _$AppDatabase,
          $LocalInventoryItemsTable,
          LocalInventoryItem
        >,
      ),
      LocalInventoryItem,
      PrefetchHooks Function()
    >;
typedef $$LocalStockTransactionsTableCreateCompanionBuilder =
    LocalStockTransactionsCompanion Function({
      required String id,
      required String inventoryItemId,
      Value<String> itemName,
      Value<String> userName,
      required String transactionType,
      required double quantityChange,
      required double previousQuantity,
      required double newQuantity,
      Value<String> unit,
      Value<String?> reason,
      required String createdAt,
      Value<bool> isLocalOnly,
      Value<int> rowid,
    });
typedef $$LocalStockTransactionsTableUpdateCompanionBuilder =
    LocalStockTransactionsCompanion Function({
      Value<String> id,
      Value<String> inventoryItemId,
      Value<String> itemName,
      Value<String> userName,
      Value<String> transactionType,
      Value<double> quantityChange,
      Value<double> previousQuantity,
      Value<double> newQuantity,
      Value<String> unit,
      Value<String?> reason,
      Value<String> createdAt,
      Value<bool> isLocalOnly,
      Value<int> rowid,
    });

class $$LocalStockTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStockTransactionsTable> {
  $$LocalStockTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventoryItemId => $composableBuilder(
    column: $table.inventoryItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityChange => $composableBuilder(
    column: $table.quantityChange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get previousQuantity => $composableBuilder(
    column: $table.previousQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get newQuantity => $composableBuilder(
    column: $table.newQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocalOnly => $composableBuilder(
    column: $table.isLocalOnly,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStockTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStockTransactionsTable> {
  $$LocalStockTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventoryItemId => $composableBuilder(
    column: $table.inventoryItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityChange => $composableBuilder(
    column: $table.quantityChange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get previousQuantity => $composableBuilder(
    column: $table.previousQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get newQuantity => $composableBuilder(
    column: $table.newQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocalOnly => $composableBuilder(
    column: $table.isLocalOnly,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStockTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStockTransactionsTable> {
  $$LocalStockTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get inventoryItemId => $composableBuilder(
    column: $table.inventoryItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantityChange => $composableBuilder(
    column: $table.quantityChange,
    builder: (column) => column,
  );

  GeneratedColumn<double> get previousQuantity => $composableBuilder(
    column: $table.previousQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get newQuantity => $composableBuilder(
    column: $table.newQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isLocalOnly => $composableBuilder(
    column: $table.isLocalOnly,
    builder: (column) => column,
  );
}

class $$LocalStockTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStockTransactionsTable,
          LocalStockTransaction,
          $$LocalStockTransactionsTableFilterComposer,
          $$LocalStockTransactionsTableOrderingComposer,
          $$LocalStockTransactionsTableAnnotationComposer,
          $$LocalStockTransactionsTableCreateCompanionBuilder,
          $$LocalStockTransactionsTableUpdateCompanionBuilder,
          (
            LocalStockTransaction,
            BaseReferences<
              _$AppDatabase,
              $LocalStockTransactionsTable,
              LocalStockTransaction
            >,
          ),
          LocalStockTransaction,
          PrefetchHooks Function()
        > {
  $$LocalStockTransactionsTableTableManager(
    _$AppDatabase db,
    $LocalStockTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStockTransactionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalStockTransactionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalStockTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inventoryItemId = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<String> userName = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<double> quantityChange = const Value.absent(),
                Value<double> previousQuantity = const Value.absent(),
                Value<double> newQuantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<bool> isLocalOnly = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStockTransactionsCompanion(
                id: id,
                inventoryItemId: inventoryItemId,
                itemName: itemName,
                userName: userName,
                transactionType: transactionType,
                quantityChange: quantityChange,
                previousQuantity: previousQuantity,
                newQuantity: newQuantity,
                unit: unit,
                reason: reason,
                createdAt: createdAt,
                isLocalOnly: isLocalOnly,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inventoryItemId,
                Value<String> itemName = const Value.absent(),
                Value<String> userName = const Value.absent(),
                required String transactionType,
                required double quantityChange,
                required double previousQuantity,
                required double newQuantity,
                Value<String> unit = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                required String createdAt,
                Value<bool> isLocalOnly = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStockTransactionsCompanion.insert(
                id: id,
                inventoryItemId: inventoryItemId,
                itemName: itemName,
                userName: userName,
                transactionType: transactionType,
                quantityChange: quantityChange,
                previousQuantity: previousQuantity,
                newQuantity: newQuantity,
                unit: unit,
                reason: reason,
                createdAt: createdAt,
                isLocalOnly: isLocalOnly,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStockTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStockTransactionsTable,
      LocalStockTransaction,
      $$LocalStockTransactionsTableFilterComposer,
      $$LocalStockTransactionsTableOrderingComposer,
      $$LocalStockTransactionsTableAnnotationComposer,
      $$LocalStockTransactionsTableCreateCompanionBuilder,
      $$LocalStockTransactionsTableUpdateCompanionBuilder,
      (
        LocalStockTransaction,
        BaseReferences<
          _$AppDatabase,
          $LocalStockTransactionsTable,
          LocalStockTransaction
        >,
      ),
      LocalStockTransaction,
      PrefetchHooks Function()
    >;
typedef $$LocalShoppingListsTableCreateCompanionBuilder =
    LocalShoppingListsCompanion Function({
      required String id,
      required String homeId,
      Value<String> name,
      Value<bool> isDefault,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalShoppingListsTableUpdateCompanionBuilder =
    LocalShoppingListsCompanion Function({
      Value<String> id,
      Value<String> homeId,
      Value<String> name,
      Value<bool> isDefault,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalShoppingListsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalShoppingListsTable> {
  $$LocalShoppingListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalShoppingListsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalShoppingListsTable> {
  $$LocalShoppingListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalShoppingListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalShoppingListsTable> {
  $$LocalShoppingListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get homeId =>
      $composableBuilder(column: $table.homeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalShoppingListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalShoppingListsTable,
          LocalShoppingList,
          $$LocalShoppingListsTableFilterComposer,
          $$LocalShoppingListsTableOrderingComposer,
          $$LocalShoppingListsTableAnnotationComposer,
          $$LocalShoppingListsTableCreateCompanionBuilder,
          $$LocalShoppingListsTableUpdateCompanionBuilder,
          (
            LocalShoppingList,
            BaseReferences<
              _$AppDatabase,
              $LocalShoppingListsTable,
              LocalShoppingList
            >,
          ),
          LocalShoppingList,
          PrefetchHooks Function()
        > {
  $$LocalShoppingListsTableTableManager(
    _$AppDatabase db,
    $LocalShoppingListsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalShoppingListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalShoppingListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalShoppingListsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> homeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingListsCompanion(
                id: id,
                homeId: homeId,
                name: name,
                isDefault: isDefault,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String homeId,
                Value<String> name = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingListsCompanion.insert(
                id: id,
                homeId: homeId,
                name: name,
                isDefault: isDefault,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalShoppingListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalShoppingListsTable,
      LocalShoppingList,
      $$LocalShoppingListsTableFilterComposer,
      $$LocalShoppingListsTableOrderingComposer,
      $$LocalShoppingListsTableAnnotationComposer,
      $$LocalShoppingListsTableCreateCompanionBuilder,
      $$LocalShoppingListsTableUpdateCompanionBuilder,
      (
        LocalShoppingList,
        BaseReferences<
          _$AppDatabase,
          $LocalShoppingListsTable,
          LocalShoppingList
        >,
      ),
      LocalShoppingList,
      PrefetchHooks Function()
    >;
typedef $$LocalShoppingListItemsTableCreateCompanionBuilder =
    LocalShoppingListItemsCompanion Function({
      required String id,
      required String shoppingListId,
      Value<String?> inventoryItemId,
      required String itemName,
      Value<String?> categoryName,
      Value<String> categoryIcon,
      Value<String> categoryColor,
      Value<double> quantity,
      Value<String> unit,
      Value<bool> isCompleted,
      Value<bool> isAutoGenerated,
      Value<String> addedByName,
      Value<String?> completedByName,
      Value<String?> completedAt,
      Value<String?> notes,
      Value<String?> barcode,
      Value<String?> productId,
      Value<bool> isLocalOnly,
      Value<bool> isDeleted,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalShoppingListItemsTableUpdateCompanionBuilder =
    LocalShoppingListItemsCompanion Function({
      Value<String> id,
      Value<String> shoppingListId,
      Value<String?> inventoryItemId,
      Value<String> itemName,
      Value<String?> categoryName,
      Value<String> categoryIcon,
      Value<String> categoryColor,
      Value<double> quantity,
      Value<String> unit,
      Value<bool> isCompleted,
      Value<bool> isAutoGenerated,
      Value<String> addedByName,
      Value<String?> completedByName,
      Value<String?> completedAt,
      Value<String?> notes,
      Value<String?> barcode,
      Value<String?> productId,
      Value<bool> isLocalOnly,
      Value<bool> isDeleted,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalShoppingListItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalShoppingListItemsTable> {
  $$LocalShoppingListItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shoppingListId => $composableBuilder(
    column: $table.shoppingListId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventoryItemId => $composableBuilder(
    column: $table.inventoryItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryIcon => $composableBuilder(
    column: $table.categoryIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryColor => $composableBuilder(
    column: $table.categoryColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAutoGenerated => $composableBuilder(
    column: $table.isAutoGenerated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addedByName => $composableBuilder(
    column: $table.addedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedByName => $composableBuilder(
    column: $table.completedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocalOnly => $composableBuilder(
    column: $table.isLocalOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalShoppingListItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalShoppingListItemsTable> {
  $$LocalShoppingListItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shoppingListId => $composableBuilder(
    column: $table.shoppingListId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventoryItemId => $composableBuilder(
    column: $table.inventoryItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryIcon => $composableBuilder(
    column: $table.categoryIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryColor => $composableBuilder(
    column: $table.categoryColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAutoGenerated => $composableBuilder(
    column: $table.isAutoGenerated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addedByName => $composableBuilder(
    column: $table.addedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedByName => $composableBuilder(
    column: $table.completedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocalOnly => $composableBuilder(
    column: $table.isLocalOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalShoppingListItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalShoppingListItemsTable> {
  $$LocalShoppingListItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shoppingListId => $composableBuilder(
    column: $table.shoppingListId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inventoryItemId => $composableBuilder(
    column: $table.inventoryItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryIcon => $composableBuilder(
    column: $table.categoryIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryColor => $composableBuilder(
    column: $table.categoryColor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAutoGenerated => $composableBuilder(
    column: $table.isAutoGenerated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get addedByName => $composableBuilder(
    column: $table.addedByName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completedByName => $composableBuilder(
    column: $table.completedByName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<bool> get isLocalOnly => $composableBuilder(
    column: $table.isLocalOnly,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalShoppingListItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalShoppingListItemsTable,
          LocalShoppingListItem,
          $$LocalShoppingListItemsTableFilterComposer,
          $$LocalShoppingListItemsTableOrderingComposer,
          $$LocalShoppingListItemsTableAnnotationComposer,
          $$LocalShoppingListItemsTableCreateCompanionBuilder,
          $$LocalShoppingListItemsTableUpdateCompanionBuilder,
          (
            LocalShoppingListItem,
            BaseReferences<
              _$AppDatabase,
              $LocalShoppingListItemsTable,
              LocalShoppingListItem
            >,
          ),
          LocalShoppingListItem,
          PrefetchHooks Function()
        > {
  $$LocalShoppingListItemsTableTableManager(
    _$AppDatabase db,
    $LocalShoppingListItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalShoppingListItemsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalShoppingListItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalShoppingListItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shoppingListId = const Value.absent(),
                Value<String?> inventoryItemId = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<String> categoryIcon = const Value.absent(),
                Value<String> categoryColor = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<bool> isAutoGenerated = const Value.absent(),
                Value<String> addedByName = const Value.absent(),
                Value<String?> completedByName = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<bool> isLocalOnly = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingListItemsCompanion(
                id: id,
                shoppingListId: shoppingListId,
                inventoryItemId: inventoryItemId,
                itemName: itemName,
                categoryName: categoryName,
                categoryIcon: categoryIcon,
                categoryColor: categoryColor,
                quantity: quantity,
                unit: unit,
                isCompleted: isCompleted,
                isAutoGenerated: isAutoGenerated,
                addedByName: addedByName,
                completedByName: completedByName,
                completedAt: completedAt,
                notes: notes,
                barcode: barcode,
                productId: productId,
                isLocalOnly: isLocalOnly,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shoppingListId,
                Value<String?> inventoryItemId = const Value.absent(),
                required String itemName,
                Value<String?> categoryName = const Value.absent(),
                Value<String> categoryIcon = const Value.absent(),
                Value<String> categoryColor = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<bool> isAutoGenerated = const Value.absent(),
                Value<String> addedByName = const Value.absent(),
                Value<String?> completedByName = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<bool> isLocalOnly = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingListItemsCompanion.insert(
                id: id,
                shoppingListId: shoppingListId,
                inventoryItemId: inventoryItemId,
                itemName: itemName,
                categoryName: categoryName,
                categoryIcon: categoryIcon,
                categoryColor: categoryColor,
                quantity: quantity,
                unit: unit,
                isCompleted: isCompleted,
                isAutoGenerated: isAutoGenerated,
                addedByName: addedByName,
                completedByName: completedByName,
                completedAt: completedAt,
                notes: notes,
                barcode: barcode,
                productId: productId,
                isLocalOnly: isLocalOnly,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalShoppingListItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalShoppingListItemsTable,
      LocalShoppingListItem,
      $$LocalShoppingListItemsTableFilterComposer,
      $$LocalShoppingListItemsTableOrderingComposer,
      $$LocalShoppingListItemsTableAnnotationComposer,
      $$LocalShoppingListItemsTableCreateCompanionBuilder,
      $$LocalShoppingListItemsTableUpdateCompanionBuilder,
      (
        LocalShoppingListItem,
        BaseReferences<
          _$AppDatabase,
          $LocalShoppingListItemsTable,
          LocalShoppingListItem
        >,
      ),
      LocalShoppingListItem,
      PrefetchHooks Function()
    >;
typedef $$LocalStoresTableCreateCompanionBuilder =
    LocalStoresCompanion Function({
      required String id,
      required String homeId,
      required String name,
      Value<String?> location,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalStoresTableUpdateCompanionBuilder =
    LocalStoresCompanion Function({
      Value<String> id,
      Value<String> homeId,
      Value<String> name,
      Value<String?> location,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalStoresTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStoresTable> {
  $$LocalStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStoresTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStoresTable> {
  $$LocalStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStoresTable> {
  $$LocalStoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get homeId =>
      $composableBuilder(column: $table.homeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalStoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStoresTable,
          LocalStore,
          $$LocalStoresTableFilterComposer,
          $$LocalStoresTableOrderingComposer,
          $$LocalStoresTableAnnotationComposer,
          $$LocalStoresTableCreateCompanionBuilder,
          $$LocalStoresTableUpdateCompanionBuilder,
          (
            LocalStore,
            BaseReferences<_$AppDatabase, $LocalStoresTable, LocalStore>,
          ),
          LocalStore,
          PrefetchHooks Function()
        > {
  $$LocalStoresTableTableManager(_$AppDatabase db, $LocalStoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalStoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> homeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStoresCompanion(
                id: id,
                homeId: homeId,
                name: name,
                location: location,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String homeId,
                required String name,
                Value<String?> location = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStoresCompanion.insert(
                id: id,
                homeId: homeId,
                name: name,
                location: location,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStoresTable,
      LocalStore,
      $$LocalStoresTableFilterComposer,
      $$LocalStoresTableOrderingComposer,
      $$LocalStoresTableAnnotationComposer,
      $$LocalStoresTableCreateCompanionBuilder,
      $$LocalStoresTableUpdateCompanionBuilder,
      (
        LocalStore,
        BaseReferences<_$AppDatabase, $LocalStoresTable, LocalStore>,
      ),
      LocalStore,
      PrefetchHooks Function()
    >;
typedef $$LocalPurchasesTableCreateCompanionBuilder =
    LocalPurchasesCompanion Function({
      required String id,
      required String homeId,
      Value<String?> storeId,
      Value<String?> storeName,
      Value<String> recordedByName,
      required String purchaseDate,
      required double totalAmount,
      Value<String> currency,
      Value<String?> receiptImageUrl,
      Value<String?> notes,
      Value<bool> isLocalOnly,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalPurchasesTableUpdateCompanionBuilder =
    LocalPurchasesCompanion Function({
      Value<String> id,
      Value<String> homeId,
      Value<String?> storeId,
      Value<String?> storeName,
      Value<String> recordedByName,
      Value<String> purchaseDate,
      Value<double> totalAmount,
      Value<String> currency,
      Value<String?> receiptImageUrl,
      Value<String?> notes,
      Value<bool> isLocalOnly,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalPurchasesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPurchasesTable> {
  $$LocalPurchasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedByName => $composableBuilder(
    column: $table.recordedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptImageUrl => $composableBuilder(
    column: $table.receiptImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocalOnly => $composableBuilder(
    column: $table.isLocalOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPurchasesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPurchasesTable> {
  $$LocalPurchasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedByName => $composableBuilder(
    column: $table.recordedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptImageUrl => $composableBuilder(
    column: $table.receiptImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocalOnly => $composableBuilder(
    column: $table.isLocalOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPurchasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPurchasesTable> {
  $$LocalPurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get homeId =>
      $composableBuilder(column: $table.homeId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<String> get recordedByName => $composableBuilder(
    column: $table.recordedByName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get receiptImageUrl => $composableBuilder(
    column: $table.receiptImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isLocalOnly => $composableBuilder(
    column: $table.isLocalOnly,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalPurchasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPurchasesTable,
          LocalPurchase,
          $$LocalPurchasesTableFilterComposer,
          $$LocalPurchasesTableOrderingComposer,
          $$LocalPurchasesTableAnnotationComposer,
          $$LocalPurchasesTableCreateCompanionBuilder,
          $$LocalPurchasesTableUpdateCompanionBuilder,
          (
            LocalPurchase,
            BaseReferences<_$AppDatabase, $LocalPurchasesTable, LocalPurchase>,
          ),
          LocalPurchase,
          PrefetchHooks Function()
        > {
  $$LocalPurchasesTableTableManager(
    _$AppDatabase db,
    $LocalPurchasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPurchasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPurchasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> homeId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<String> recordedByName = const Value.absent(),
                Value<String> purchaseDate = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> receiptImageUrl = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isLocalOnly = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPurchasesCompanion(
                id: id,
                homeId: homeId,
                storeId: storeId,
                storeName: storeName,
                recordedByName: recordedByName,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                currency: currency,
                receiptImageUrl: receiptImageUrl,
                notes: notes,
                isLocalOnly: isLocalOnly,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String homeId,
                Value<String?> storeId = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<String> recordedByName = const Value.absent(),
                required String purchaseDate,
                required double totalAmount,
                Value<String> currency = const Value.absent(),
                Value<String?> receiptImageUrl = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isLocalOnly = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPurchasesCompanion.insert(
                id: id,
                homeId: homeId,
                storeId: storeId,
                storeName: storeName,
                recordedByName: recordedByName,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                currency: currency,
                receiptImageUrl: receiptImageUrl,
                notes: notes,
                isLocalOnly: isLocalOnly,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPurchasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPurchasesTable,
      LocalPurchase,
      $$LocalPurchasesTableFilterComposer,
      $$LocalPurchasesTableOrderingComposer,
      $$LocalPurchasesTableAnnotationComposer,
      $$LocalPurchasesTableCreateCompanionBuilder,
      $$LocalPurchasesTableUpdateCompanionBuilder,
      (
        LocalPurchase,
        BaseReferences<_$AppDatabase, $LocalPurchasesTable, LocalPurchase>,
      ),
      LocalPurchase,
      PrefetchHooks Function()
    >;
typedef $$LocalPurchaseItemsTableCreateCompanionBuilder =
    LocalPurchaseItemsCompanion Function({
      required String id,
      required String purchaseId,
      Value<String?> inventoryItemId,
      required String itemName,
      Value<String?> categoryName,
      required double quantity,
      required String unit,
      required double unitPrice,
      required double totalPrice,
      Value<int> rowid,
    });
typedef $$LocalPurchaseItemsTableUpdateCompanionBuilder =
    LocalPurchaseItemsCompanion Function({
      Value<String> id,
      Value<String> purchaseId,
      Value<String?> inventoryItemId,
      Value<String> itemName,
      Value<String?> categoryName,
      Value<double> quantity,
      Value<String> unit,
      Value<double> unitPrice,
      Value<double> totalPrice,
      Value<int> rowid,
    });

class $$LocalPurchaseItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPurchaseItemsTable> {
  $$LocalPurchaseItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseId => $composableBuilder(
    column: $table.purchaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventoryItemId => $composableBuilder(
    column: $table.inventoryItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPrice => $composableBuilder(
    column: $table.totalPrice,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPurchaseItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPurchaseItemsTable> {
  $$LocalPurchaseItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseId => $composableBuilder(
    column: $table.purchaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventoryItemId => $composableBuilder(
    column: $table.inventoryItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPrice => $composableBuilder(
    column: $table.totalPrice,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPurchaseItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPurchaseItemsTable> {
  $$LocalPurchaseItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get purchaseId => $composableBuilder(
    column: $table.purchaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inventoryItemId => $composableBuilder(
    column: $table.inventoryItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get totalPrice => $composableBuilder(
    column: $table.totalPrice,
    builder: (column) => column,
  );
}

class $$LocalPurchaseItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPurchaseItemsTable,
          LocalPurchaseItem,
          $$LocalPurchaseItemsTableFilterComposer,
          $$LocalPurchaseItemsTableOrderingComposer,
          $$LocalPurchaseItemsTableAnnotationComposer,
          $$LocalPurchaseItemsTableCreateCompanionBuilder,
          $$LocalPurchaseItemsTableUpdateCompanionBuilder,
          (
            LocalPurchaseItem,
            BaseReferences<
              _$AppDatabase,
              $LocalPurchaseItemsTable,
              LocalPurchaseItem
            >,
          ),
          LocalPurchaseItem,
          PrefetchHooks Function()
        > {
  $$LocalPurchaseItemsTableTableManager(
    _$AppDatabase db,
    $LocalPurchaseItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPurchaseItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPurchaseItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPurchaseItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> purchaseId = const Value.absent(),
                Value<String?> inventoryItemId = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> totalPrice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPurchaseItemsCompanion(
                id: id,
                purchaseId: purchaseId,
                inventoryItemId: inventoryItemId,
                itemName: itemName,
                categoryName: categoryName,
                quantity: quantity,
                unit: unit,
                unitPrice: unitPrice,
                totalPrice: totalPrice,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String purchaseId,
                Value<String?> inventoryItemId = const Value.absent(),
                required String itemName,
                Value<String?> categoryName = const Value.absent(),
                required double quantity,
                required String unit,
                required double unitPrice,
                required double totalPrice,
                Value<int> rowid = const Value.absent(),
              }) => LocalPurchaseItemsCompanion.insert(
                id: id,
                purchaseId: purchaseId,
                inventoryItemId: inventoryItemId,
                itemName: itemName,
                categoryName: categoryName,
                quantity: quantity,
                unit: unit,
                unitPrice: unitPrice,
                totalPrice: totalPrice,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPurchaseItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPurchaseItemsTable,
      LocalPurchaseItem,
      $$LocalPurchaseItemsTableFilterComposer,
      $$LocalPurchaseItemsTableOrderingComposer,
      $$LocalPurchaseItemsTableAnnotationComposer,
      $$LocalPurchaseItemsTableCreateCompanionBuilder,
      $$LocalPurchaseItemsTableUpdateCompanionBuilder,
      (
        LocalPurchaseItem,
        BaseReferences<
          _$AppDatabase,
          $LocalPurchaseItemsTable,
          LocalPurchaseItem
        >,
      ),
      LocalPurchaseItem,
      PrefetchHooks Function()
    >;
typedef $$LocalNotificationsTableCreateCompanionBuilder =
    LocalNotificationsCompanion Function({
      required String id,
      required String userId,
      required String title,
      required String message,
      Value<String?> type,
      Value<bool> isRead,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$LocalNotificationsTableUpdateCompanionBuilder =
    LocalNotificationsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> title,
      Value<String> message,
      Value<String?> type,
      Value<bool> isRead,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$LocalNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalNotificationsTable> {
  $$LocalNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalNotificationsTable> {
  $$LocalNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalNotificationsTable> {
  $$LocalNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalNotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalNotificationsTable,
          LocalNotification,
          $$LocalNotificationsTableFilterComposer,
          $$LocalNotificationsTableOrderingComposer,
          $$LocalNotificationsTableAnnotationComposer,
          $$LocalNotificationsTableCreateCompanionBuilder,
          $$LocalNotificationsTableUpdateCompanionBuilder,
          (
            LocalNotification,
            BaseReferences<
              _$AppDatabase,
              $LocalNotificationsTable,
              LocalNotification
            >,
          ),
          LocalNotification,
          PrefetchHooks Function()
        > {
  $$LocalNotificationsTableTableManager(
    _$AppDatabase db,
    $LocalNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalNotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalNotificationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalNotificationsCompanion(
                id: id,
                userId: userId,
                title: title,
                message: message,
                type: type,
                isRead: isRead,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String title,
                required String message,
                Value<String?> type = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalNotificationsCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                message: message,
                type: type,
                isRead: isRead,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalNotificationsTable,
      LocalNotification,
      $$LocalNotificationsTableFilterComposer,
      $$LocalNotificationsTableOrderingComposer,
      $$LocalNotificationsTableAnnotationComposer,
      $$LocalNotificationsTableCreateCompanionBuilder,
      $$LocalNotificationsTableUpdateCompanionBuilder,
      (
        LocalNotification,
        BaseReferences<
          _$AppDatabase,
          $LocalNotificationsTable,
          LocalNotification
        >,
      ),
      LocalNotification,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueEntriesTableCreateCompanionBuilder =
    SyncQueueEntriesCompanion Function({
      Value<int> id,
      required String operationId,
      required String operationType,
      required String entityType,
      required String entityId,
      required String payload,
      required DateTime createdAt,
      Value<int> retryCount,
      Value<String> status,
      Value<String?> lastError,
      required String homeId,
    });
typedef $$SyncQueueEntriesTableUpdateCompanionBuilder =
    SyncQueueEntriesCompanion Function({
      Value<int> id,
      Value<String> operationId,
      Value<String> operationType,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String> status,
      Value<String?> lastError,
      Value<String> homeId,
    });

class $$SyncQueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get homeId =>
      $composableBuilder(column: $table.homeId, builder: (column) => column);
}

class $$SyncQueueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueEntriesTable,
          SyncQueueEntry,
          $$SyncQueueEntriesTableFilterComposer,
          $$SyncQueueEntriesTableOrderingComposer,
          $$SyncQueueEntriesTableAnnotationComposer,
          $$SyncQueueEntriesTableCreateCompanionBuilder,
          $$SyncQueueEntriesTableUpdateCompanionBuilder,
          (
            SyncQueueEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncQueueEntriesTable,
              SyncQueueEntry
            >,
          ),
          SyncQueueEntry,
          PrefetchHooks Function()
        > {
  $$SyncQueueEntriesTableTableManager(
    _$AppDatabase db,
    $SyncQueueEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> homeId = const Value.absent(),
              }) => SyncQueueEntriesCompanion(
                id: id,
                operationId: operationId,
                operationType: operationType,
                entityType: entityType,
                entityId: entityId,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                status: status,
                lastError: lastError,
                homeId: homeId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String operationId,
                required String operationType,
                required String entityType,
                required String entityId,
                required String payload,
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required String homeId,
              }) => SyncQueueEntriesCompanion.insert(
                id: id,
                operationId: operationId,
                operationType: operationType,
                entityType: entityType,
                entityId: entityId,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                status: status,
                lastError: lastError,
                homeId: homeId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueEntriesTable,
      SyncQueueEntry,
      $$SyncQueueEntriesTableFilterComposer,
      $$SyncQueueEntriesTableOrderingComposer,
      $$SyncQueueEntriesTableAnnotationComposer,
      $$SyncQueueEntriesTableCreateCompanionBuilder,
      $$SyncQueueEntriesTableUpdateCompanionBuilder,
      (
        SyncQueueEntry,
        BaseReferences<_$AppDatabase, $SyncQueueEntriesTable, SyncQueueEntry>,
      ),
      SyncQueueEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncMetadataEntriesTableCreateCompanionBuilder =
    SyncMetadataEntriesCompanion Function({
      required String homeId,
      Value<DateTime?> lastSyncedAt,
      Value<int> syncVersion,
      Value<int> rowid,
    });
typedef $$SyncMetadataEntriesTableUpdateCompanionBuilder =
    SyncMetadataEntriesCompanion Function({
      Value<String> homeId,
      Value<DateTime?> lastSyncedAt,
      Value<int> syncVersion,
      Value<int> rowid,
    });

class $$SyncMetadataEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataEntriesTable> {
  $$SyncMetadataEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataEntriesTable> {
  $$SyncMetadataEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataEntriesTable> {
  $$SyncMetadataEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get homeId =>
      $composableBuilder(column: $table.homeId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );
}

class $$SyncMetadataEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataEntriesTable,
          SyncMetadataEntry,
          $$SyncMetadataEntriesTableFilterComposer,
          $$SyncMetadataEntriesTableOrderingComposer,
          $$SyncMetadataEntriesTableAnnotationComposer,
          $$SyncMetadataEntriesTableCreateCompanionBuilder,
          $$SyncMetadataEntriesTableUpdateCompanionBuilder,
          (
            SyncMetadataEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncMetadataEntriesTable,
              SyncMetadataEntry
            >,
          ),
          SyncMetadataEntry,
          PrefetchHooks Function()
        > {
  $$SyncMetadataEntriesTableTableManager(
    _$AppDatabase db,
    $SyncMetadataEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncMetadataEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> homeId = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataEntriesCompanion(
                homeId: homeId,
                lastSyncedAt: lastSyncedAt,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String homeId,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataEntriesCompanion.insert(
                homeId: homeId,
                lastSyncedAt: lastSyncedAt,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataEntriesTable,
      SyncMetadataEntry,
      $$SyncMetadataEntriesTableFilterComposer,
      $$SyncMetadataEntriesTableOrderingComposer,
      $$SyncMetadataEntriesTableAnnotationComposer,
      $$SyncMetadataEntriesTableCreateCompanionBuilder,
      $$SyncMetadataEntriesTableUpdateCompanionBuilder,
      (
        SyncMetadataEntry,
        BaseReferences<
          _$AppDatabase,
          $SyncMetadataEntriesTable,
          SyncMetadataEntry
        >,
      ),
      SyncMetadataEntry,
      PrefetchHooks Function()
    >;
typedef $$LocalProductOffersTableCreateCompanionBuilder =
    LocalProductOffersCompanion Function({
      required String id,
      required String shoppingItemId,
      required String provider,
      required String productName,
      Value<String?> brand,
      required double price,
      Value<double?> deliveryCharge,
      required double effectivePrice,
      Value<String> currency,
      Value<String?> availability,
      Value<String?> estimatedDelivery,
      Value<String?> affiliateUrl,
      Value<String?> imageUrl,
      Value<double?> matchConfidence,
      Value<String?> matchType,
      Value<String?> pricePerUnitLabel,
      Value<DateTime?> lastCheckedAt,
      Value<DateTime?> cachedAt,
      Value<int> rowid,
    });
typedef $$LocalProductOffersTableUpdateCompanionBuilder =
    LocalProductOffersCompanion Function({
      Value<String> id,
      Value<String> shoppingItemId,
      Value<String> provider,
      Value<String> productName,
      Value<String?> brand,
      Value<double> price,
      Value<double?> deliveryCharge,
      Value<double> effectivePrice,
      Value<String> currency,
      Value<String?> availability,
      Value<String?> estimatedDelivery,
      Value<String?> affiliateUrl,
      Value<String?> imageUrl,
      Value<double?> matchConfidence,
      Value<String?> matchType,
      Value<String?> pricePerUnitLabel,
      Value<DateTime?> lastCheckedAt,
      Value<DateTime?> cachedAt,
      Value<int> rowid,
    });

class $$LocalProductOffersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProductOffersTable> {
  $$LocalProductOffersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shoppingItemId => $composableBuilder(
    column: $table.shoppingItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deliveryCharge => $composableBuilder(
    column: $table.deliveryCharge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get effectivePrice => $composableBuilder(
    column: $table.effectivePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estimatedDelivery => $composableBuilder(
    column: $table.estimatedDelivery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get affiliateUrl => $composableBuilder(
    column: $table.affiliateUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get matchConfidence => $composableBuilder(
    column: $table.matchConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchType => $composableBuilder(
    column: $table.matchType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pricePerUnitLabel => $composableBuilder(
    column: $table.pricePerUnitLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProductOffersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProductOffersTable> {
  $$LocalProductOffersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shoppingItemId => $composableBuilder(
    column: $table.shoppingItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deliveryCharge => $composableBuilder(
    column: $table.deliveryCharge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get effectivePrice => $composableBuilder(
    column: $table.effectivePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estimatedDelivery => $composableBuilder(
    column: $table.estimatedDelivery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get affiliateUrl => $composableBuilder(
    column: $table.affiliateUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get matchConfidence => $composableBuilder(
    column: $table.matchConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchType => $composableBuilder(
    column: $table.matchType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pricePerUnitLabel => $composableBuilder(
    column: $table.pricePerUnitLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProductOffersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProductOffersTable> {
  $$LocalProductOffersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shoppingItemId => $composableBuilder(
    column: $table.shoppingItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<double> get deliveryCharge => $composableBuilder(
    column: $table.deliveryCharge,
    builder: (column) => column,
  );

  GeneratedColumn<double> get effectivePrice => $composableBuilder(
    column: $table.effectivePrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estimatedDelivery => $composableBuilder(
    column: $table.estimatedDelivery,
    builder: (column) => column,
  );

  GeneratedColumn<String> get affiliateUrl => $composableBuilder(
    column: $table.affiliateUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<double> get matchConfidence => $composableBuilder(
    column: $table.matchConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchType =>
      $composableBuilder(column: $table.matchType, builder: (column) => column);

  GeneratedColumn<String> get pricePerUnitLabel => $composableBuilder(
    column: $table.pricePerUnitLabel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$LocalProductOffersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProductOffersTable,
          LocalProductOffer,
          $$LocalProductOffersTableFilterComposer,
          $$LocalProductOffersTableOrderingComposer,
          $$LocalProductOffersTableAnnotationComposer,
          $$LocalProductOffersTableCreateCompanionBuilder,
          $$LocalProductOffersTableUpdateCompanionBuilder,
          (
            LocalProductOffer,
            BaseReferences<
              _$AppDatabase,
              $LocalProductOffersTable,
              LocalProductOffer
            >,
          ),
          LocalProductOffer,
          PrefetchHooks Function()
        > {
  $$LocalProductOffersTableTableManager(
    _$AppDatabase db,
    $LocalProductOffersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductOffersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProductOffersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProductOffersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shoppingItemId = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<double?> deliveryCharge = const Value.absent(),
                Value<double> effectivePrice = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> availability = const Value.absent(),
                Value<String?> estimatedDelivery = const Value.absent(),
                Value<String?> affiliateUrl = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<double?> matchConfidence = const Value.absent(),
                Value<String?> matchType = const Value.absent(),
                Value<String?> pricePerUnitLabel = const Value.absent(),
                Value<DateTime?> lastCheckedAt = const Value.absent(),
                Value<DateTime?> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductOffersCompanion(
                id: id,
                shoppingItemId: shoppingItemId,
                provider: provider,
                productName: productName,
                brand: brand,
                price: price,
                deliveryCharge: deliveryCharge,
                effectivePrice: effectivePrice,
                currency: currency,
                availability: availability,
                estimatedDelivery: estimatedDelivery,
                affiliateUrl: affiliateUrl,
                imageUrl: imageUrl,
                matchConfidence: matchConfidence,
                matchType: matchType,
                pricePerUnitLabel: pricePerUnitLabel,
                lastCheckedAt: lastCheckedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shoppingItemId,
                required String provider,
                required String productName,
                Value<String?> brand = const Value.absent(),
                required double price,
                Value<double?> deliveryCharge = const Value.absent(),
                required double effectivePrice,
                Value<String> currency = const Value.absent(),
                Value<String?> availability = const Value.absent(),
                Value<String?> estimatedDelivery = const Value.absent(),
                Value<String?> affiliateUrl = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<double?> matchConfidence = const Value.absent(),
                Value<String?> matchType = const Value.absent(),
                Value<String?> pricePerUnitLabel = const Value.absent(),
                Value<DateTime?> lastCheckedAt = const Value.absent(),
                Value<DateTime?> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductOffersCompanion.insert(
                id: id,
                shoppingItemId: shoppingItemId,
                provider: provider,
                productName: productName,
                brand: brand,
                price: price,
                deliveryCharge: deliveryCharge,
                effectivePrice: effectivePrice,
                currency: currency,
                availability: availability,
                estimatedDelivery: estimatedDelivery,
                affiliateUrl: affiliateUrl,
                imageUrl: imageUrl,
                matchConfidence: matchConfidence,
                matchType: matchType,
                pricePerUnitLabel: pricePerUnitLabel,
                lastCheckedAt: lastCheckedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProductOffersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProductOffersTable,
      LocalProductOffer,
      $$LocalProductOffersTableFilterComposer,
      $$LocalProductOffersTableOrderingComposer,
      $$LocalProductOffersTableAnnotationComposer,
      $$LocalProductOffersTableCreateCompanionBuilder,
      $$LocalProductOffersTableUpdateCompanionBuilder,
      (
        LocalProductOffer,
        BaseReferences<
          _$AppDatabase,
          $LocalProductOffersTable,
          LocalProductOffer
        >,
      ),
      LocalProductOffer,
      PrefetchHooks Function()
    >;
typedef $$LocalProductsTableCreateCompanionBuilder =
    LocalProductsCompanion Function({
      required String id,
      Value<String?> barcode,
      Value<String> barcodeType,
      required String name,
      required String normalizedName,
      Value<String?> brand,
      Value<String?> categoryId,
      Value<String> categoryName,
      Value<double?> packageSize,
      Value<String> unit,
      Value<String?> imageUrl,
      Value<String> source,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalProductsTableUpdateCompanionBuilder =
    LocalProductsCompanion Function({
      Value<String> id,
      Value<String?> barcode,
      Value<String> barcodeType,
      Value<String> name,
      Value<String> normalizedName,
      Value<String?> brand,
      Value<String?> categoryId,
      Value<String> categoryName,
      Value<double?> packageSize,
      Value<String> unit,
      Value<String?> imageUrl,
      Value<String> source,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalProductsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcodeType => $composableBuilder(
    column: $table.barcodeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get packageSize => $composableBuilder(
    column: $table.packageSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcodeType => $composableBuilder(
    column: $table.barcodeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get packageSize => $composableBuilder(
    column: $table.packageSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get barcodeType => $composableBuilder(
    column: $table.barcodeType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get packageSize => $composableBuilder(
    column: $table.packageSize,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProductsTable,
          LocalProduct,
          $$LocalProductsTableFilterComposer,
          $$LocalProductsTableOrderingComposer,
          $$LocalProductsTableAnnotationComposer,
          $$LocalProductsTableCreateCompanionBuilder,
          $$LocalProductsTableUpdateCompanionBuilder,
          (
            LocalProduct,
            BaseReferences<_$AppDatabase, $LocalProductsTable, LocalProduct>,
          ),
          LocalProduct,
          PrefetchHooks Function()
        > {
  $$LocalProductsTableTableManager(_$AppDatabase db, $LocalProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> barcodeType = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<double?> packageSize = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductsCompanion(
                id: id,
                barcode: barcode,
                barcodeType: barcodeType,
                name: name,
                normalizedName: normalizedName,
                brand: brand,
                categoryId: categoryId,
                categoryName: categoryName,
                packageSize: packageSize,
                unit: unit,
                imageUrl: imageUrl,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> barcode = const Value.absent(),
                Value<String> barcodeType = const Value.absent(),
                required String name,
                required String normalizedName,
                Value<String?> brand = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<double?> packageSize = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductsCompanion.insert(
                id: id,
                barcode: barcode,
                barcodeType: barcodeType,
                name: name,
                normalizedName: normalizedName,
                brand: brand,
                categoryId: categoryId,
                categoryName: categoryName,
                packageSize: packageSize,
                unit: unit,
                imageUrl: imageUrl,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProductsTable,
      LocalProduct,
      $$LocalProductsTableFilterComposer,
      $$LocalProductsTableOrderingComposer,
      $$LocalProductsTableAnnotationComposer,
      $$LocalProductsTableCreateCompanionBuilder,
      $$LocalProductsTableUpdateCompanionBuilder,
      (
        LocalProduct,
        BaseReferences<_$AppDatabase, $LocalProductsTable, LocalProduct>,
      ),
      LocalProduct,
      PrefetchHooks Function()
    >;
typedef $$LocalConsumptionProfilesTableCreateCompanionBuilder =
    LocalConsumptionProfilesCompanion Function({
      required String id,
      required String homeId,
      required String inventoryItemId,
      required String itemName,
      Value<double> averageDailyConsumption,
      Value<double> weightedDailyConsumption,
      Value<double> typicalIntervalDays,
      Value<String> confidence,
      Value<int?> estimatedDaysRemaining,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalConsumptionProfilesTableUpdateCompanionBuilder =
    LocalConsumptionProfilesCompanion Function({
      Value<String> id,
      Value<String> homeId,
      Value<String> inventoryItemId,
      Value<String> itemName,
      Value<double> averageDailyConsumption,
      Value<double> weightedDailyConsumption,
      Value<double> typicalIntervalDays,
      Value<String> confidence,
      Value<int?> estimatedDaysRemaining,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalConsumptionProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalConsumptionProfilesTable> {
  $$LocalConsumptionProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventoryItemId => $composableBuilder(
    column: $table.inventoryItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageDailyConsumption => $composableBuilder(
    column: $table.averageDailyConsumption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightedDailyConsumption => $composableBuilder(
    column: $table.weightedDailyConsumption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get typicalIntervalDays => $composableBuilder(
    column: $table.typicalIntervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedDaysRemaining => $composableBuilder(
    column: $table.estimatedDaysRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalConsumptionProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalConsumptionProfilesTable> {
  $$LocalConsumptionProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeId => $composableBuilder(
    column: $table.homeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventoryItemId => $composableBuilder(
    column: $table.inventoryItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageDailyConsumption => $composableBuilder(
    column: $table.averageDailyConsumption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightedDailyConsumption => $composableBuilder(
    column: $table.weightedDailyConsumption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get typicalIntervalDays => $composableBuilder(
    column: $table.typicalIntervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedDaysRemaining => $composableBuilder(
    column: $table.estimatedDaysRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalConsumptionProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalConsumptionProfilesTable> {
  $$LocalConsumptionProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get homeId =>
      $composableBuilder(column: $table.homeId, builder: (column) => column);

  GeneratedColumn<String> get inventoryItemId => $composableBuilder(
    column: $table.inventoryItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<double> get averageDailyConsumption => $composableBuilder(
    column: $table.averageDailyConsumption,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightedDailyConsumption => $composableBuilder(
    column: $table.weightedDailyConsumption,
    builder: (column) => column,
  );

  GeneratedColumn<double> get typicalIntervalDays => $composableBuilder(
    column: $table.typicalIntervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimatedDaysRemaining => $composableBuilder(
    column: $table.estimatedDaysRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalConsumptionProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalConsumptionProfilesTable,
          LocalConsumptionProfile,
          $$LocalConsumptionProfilesTableFilterComposer,
          $$LocalConsumptionProfilesTableOrderingComposer,
          $$LocalConsumptionProfilesTableAnnotationComposer,
          $$LocalConsumptionProfilesTableCreateCompanionBuilder,
          $$LocalConsumptionProfilesTableUpdateCompanionBuilder,
          (
            LocalConsumptionProfile,
            BaseReferences<
              _$AppDatabase,
              $LocalConsumptionProfilesTable,
              LocalConsumptionProfile
            >,
          ),
          LocalConsumptionProfile,
          PrefetchHooks Function()
        > {
  $$LocalConsumptionProfilesTableTableManager(
    _$AppDatabase db,
    $LocalConsumptionProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalConsumptionProfilesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalConsumptionProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalConsumptionProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> homeId = const Value.absent(),
                Value<String> inventoryItemId = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<double> averageDailyConsumption = const Value.absent(),
                Value<double> weightedDailyConsumption = const Value.absent(),
                Value<double> typicalIntervalDays = const Value.absent(),
                Value<String> confidence = const Value.absent(),
                Value<int?> estimatedDaysRemaining = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalConsumptionProfilesCompanion(
                id: id,
                homeId: homeId,
                inventoryItemId: inventoryItemId,
                itemName: itemName,
                averageDailyConsumption: averageDailyConsumption,
                weightedDailyConsumption: weightedDailyConsumption,
                typicalIntervalDays: typicalIntervalDays,
                confidence: confidence,
                estimatedDaysRemaining: estimatedDaysRemaining,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String homeId,
                required String inventoryItemId,
                required String itemName,
                Value<double> averageDailyConsumption = const Value.absent(),
                Value<double> weightedDailyConsumption = const Value.absent(),
                Value<double> typicalIntervalDays = const Value.absent(),
                Value<String> confidence = const Value.absent(),
                Value<int?> estimatedDaysRemaining = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalConsumptionProfilesCompanion.insert(
                id: id,
                homeId: homeId,
                inventoryItemId: inventoryItemId,
                itemName: itemName,
                averageDailyConsumption: averageDailyConsumption,
                weightedDailyConsumption: weightedDailyConsumption,
                typicalIntervalDays: typicalIntervalDays,
                confidence: confidence,
                estimatedDaysRemaining: estimatedDaysRemaining,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalConsumptionProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalConsumptionProfilesTable,
      LocalConsumptionProfile,
      $$LocalConsumptionProfilesTableFilterComposer,
      $$LocalConsumptionProfilesTableOrderingComposer,
      $$LocalConsumptionProfilesTableAnnotationComposer,
      $$LocalConsumptionProfilesTableCreateCompanionBuilder,
      $$LocalConsumptionProfilesTableUpdateCompanionBuilder,
      (
        LocalConsumptionProfile,
        BaseReferences<
          _$AppDatabase,
          $LocalConsumptionProfilesTable,
          LocalConsumptionProfile
        >,
      ),
      LocalConsumptionProfile,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalUsersTableTableManager get localUsers =>
      $$LocalUsersTableTableManager(_db, _db.localUsers);
  $$LocalHomesTableTableManager get localHomes =>
      $$LocalHomesTableTableManager(_db, _db.localHomes);
  $$LocalHomeMembersTableTableManager get localHomeMembers =>
      $$LocalHomeMembersTableTableManager(_db, _db.localHomeMembers);
  $$LocalCategoriesTableTableManager get localCategories =>
      $$LocalCategoriesTableTableManager(_db, _db.localCategories);
  $$LocalInventoryItemsTableTableManager get localInventoryItems =>
      $$LocalInventoryItemsTableTableManager(_db, _db.localInventoryItems);
  $$LocalStockTransactionsTableTableManager get localStockTransactions =>
      $$LocalStockTransactionsTableTableManager(
        _db,
        _db.localStockTransactions,
      );
  $$LocalShoppingListsTableTableManager get localShoppingLists =>
      $$LocalShoppingListsTableTableManager(_db, _db.localShoppingLists);
  $$LocalShoppingListItemsTableTableManager get localShoppingListItems =>
      $$LocalShoppingListItemsTableTableManager(
        _db,
        _db.localShoppingListItems,
      );
  $$LocalStoresTableTableManager get localStores =>
      $$LocalStoresTableTableManager(_db, _db.localStores);
  $$LocalPurchasesTableTableManager get localPurchases =>
      $$LocalPurchasesTableTableManager(_db, _db.localPurchases);
  $$LocalPurchaseItemsTableTableManager get localPurchaseItems =>
      $$LocalPurchaseItemsTableTableManager(_db, _db.localPurchaseItems);
  $$LocalNotificationsTableTableManager get localNotifications =>
      $$LocalNotificationsTableTableManager(_db, _db.localNotifications);
  $$SyncQueueEntriesTableTableManager get syncQueueEntries =>
      $$SyncQueueEntriesTableTableManager(_db, _db.syncQueueEntries);
  $$SyncMetadataEntriesTableTableManager get syncMetadataEntries =>
      $$SyncMetadataEntriesTableTableManager(_db, _db.syncMetadataEntries);
  $$LocalProductOffersTableTableManager get localProductOffers =>
      $$LocalProductOffersTableTableManager(_db, _db.localProductOffers);
  $$LocalProductsTableTableManager get localProducts =>
      $$LocalProductsTableTableManager(_db, _db.localProducts);
  $$LocalConsumptionProfilesTableTableManager get localConsumptionProfiles =>
      $$LocalConsumptionProfilesTableTableManager(
        _db,
        _db.localConsumptionProfiles,
      );
}
