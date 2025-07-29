// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsuariosTable extends Usuarios
    with TableInfo<$UsuariosTable, UsuarioDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsuariosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _correoMeta = const VerificationMeta('correo');
  @override
  late final GeneratedColumn<String> correo = GeneratedColumn<String>(
    'correo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _rolMeta = const VerificationMeta('rol');
  @override
  late final GeneratedColumn<String> rol = GeneratedColumn<String>(
    'rol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('usuario'),
  );
  static const VerificationMeta _uuidDistribuidoraMeta = const VerificationMeta(
    'uuidDistribuidora',
  );
  @override
  late final GeneratedColumn<String> uuidDistribuidora =
      GeneratedColumn<String>(
        'uuid_distribuidora',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, bool>, String>
  permisos = GeneratedColumn<String>(
    'permisos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  ).withConverter<Map<String, bool>>($UsuariosTable.$converterpermisos);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uid,
    nombre,
    correo,
    rol,
    uuidDistribuidora,
    permisos,
    updatedAt,
    deleted,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usuarios';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsuarioDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    }
    if (data.containsKey('correo')) {
      context.handle(
        _correoMeta,
        correo.isAcceptableOrUnknown(data['correo']!, _correoMeta),
      );
    }
    if (data.containsKey('rol')) {
      context.handle(
        _rolMeta,
        rol.isAcceptableOrUnknown(data['rol']!, _rolMeta),
      );
    }
    if (data.containsKey('uuid_distribuidora')) {
      context.handle(
        _uuidDistribuidoraMeta,
        uuidDistribuidora.isAcceptableOrUnknown(
          data['uuid_distribuidora']!,
          _uuidDistribuidoraMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  UsuarioDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsuarioDb(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      correo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correo'],
      )!,
      rol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rol'],
      )!,
      uuidDistribuidora: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid_distribuidora'],
      )!,
      permisos: $UsuariosTable.$converterpermisos.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}permisos'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $UsuariosTable createAlias(String alias) {
    return $UsuariosTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, bool>, String> $converterpermisos =
      const PermisosConverter();
}

class UsuarioDb extends DataClass implements Insertable<UsuarioDb> {
  final String uid;
  final String nombre;
  final String correo;
  final String rol;
  final String uuidDistribuidora;
  final Map<String, bool> permisos;
  final DateTime updatedAt;
  final bool deleted;
  final bool isSynced;
  const UsuarioDb({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.uuidDistribuidora,
    required this.permisos,
    required this.updatedAt,
    required this.deleted,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['nombre'] = Variable<String>(nombre);
    map['correo'] = Variable<String>(correo);
    map['rol'] = Variable<String>(rol);
    map['uuid_distribuidora'] = Variable<String>(uuidDistribuidora);
    {
      map['permisos'] = Variable<String>(
        $UsuariosTable.$converterpermisos.toSql(permisos),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  UsuariosCompanion toCompanion(bool nullToAbsent) {
    return UsuariosCompanion(
      uid: Value(uid),
      nombre: Value(nombre),
      correo: Value(correo),
      rol: Value(rol),
      uuidDistribuidora: Value(uuidDistribuidora),
      permisos: Value(permisos),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      isSynced: Value(isSynced),
    );
  }

  factory UsuarioDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsuarioDb(
      uid: serializer.fromJson<String>(json['uid']),
      nombre: serializer.fromJson<String>(json['nombre']),
      correo: serializer.fromJson<String>(json['correo']),
      rol: serializer.fromJson<String>(json['rol']),
      uuidDistribuidora: serializer.fromJson<String>(json['uuidDistribuidora']),
      permisos: serializer.fromJson<Map<String, bool>>(json['permisos']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'nombre': serializer.toJson<String>(nombre),
      'correo': serializer.toJson<String>(correo),
      'rol': serializer.toJson<String>(rol),
      'uuidDistribuidora': serializer.toJson<String>(uuidDistribuidora),
      'permisos': serializer.toJson<Map<String, bool>>(permisos),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  UsuarioDb copyWith({
    String? uid,
    String? nombre,
    String? correo,
    String? rol,
    String? uuidDistribuidora,
    Map<String, bool>? permisos,
    DateTime? updatedAt,
    bool? deleted,
    bool? isSynced,
  }) => UsuarioDb(
    uid: uid ?? this.uid,
    nombre: nombre ?? this.nombre,
    correo: correo ?? this.correo,
    rol: rol ?? this.rol,
    uuidDistribuidora: uuidDistribuidora ?? this.uuidDistribuidora,
    permisos: permisos ?? this.permisos,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    isSynced: isSynced ?? this.isSynced,
  );
  UsuarioDb copyWithCompanion(UsuariosCompanion data) {
    return UsuarioDb(
      uid: data.uid.present ? data.uid.value : this.uid,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      correo: data.correo.present ? data.correo.value : this.correo,
      rol: data.rol.present ? data.rol.value : this.rol,
      uuidDistribuidora: data.uuidDistribuidora.present
          ? data.uuidDistribuidora.value
          : this.uuidDistribuidora,
      permisos: data.permisos.present ? data.permisos.value : this.permisos,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsuarioDb(')
          ..write('uid: $uid, ')
          ..write('nombre: $nombre, ')
          ..write('correo: $correo, ')
          ..write('rol: $rol, ')
          ..write('uuidDistribuidora: $uuidDistribuidora, ')
          ..write('permisos: $permisos, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uid,
    nombre,
    correo,
    rol,
    uuidDistribuidora,
    permisos,
    updatedAt,
    deleted,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsuarioDb &&
          other.uid == this.uid &&
          other.nombre == this.nombre &&
          other.correo == this.correo &&
          other.rol == this.rol &&
          other.uuidDistribuidora == this.uuidDistribuidora &&
          other.permisos == this.permisos &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.isSynced == this.isSynced);
}

class UsuariosCompanion extends UpdateCompanion<UsuarioDb> {
  final Value<String> uid;
  final Value<String> nombre;
  final Value<String> correo;
  final Value<String> rol;
  final Value<String> uuidDistribuidora;
  final Value<Map<String, bool>> permisos;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const UsuariosCompanion({
    this.uid = const Value.absent(),
    this.nombre = const Value.absent(),
    this.correo = const Value.absent(),
    this.rol = const Value.absent(),
    this.uuidDistribuidora = const Value.absent(),
    this.permisos = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsuariosCompanion.insert({
    required String uid,
    this.nombre = const Value.absent(),
    this.correo = const Value.absent(),
    this.rol = const Value.absent(),
    this.uuidDistribuidora = const Value.absent(),
    this.permisos = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid);
  static Insertable<UsuarioDb> custom({
    Expression<String>? uid,
    Expression<String>? nombre,
    Expression<String>? correo,
    Expression<String>? rol,
    Expression<String>? uuidDistribuidora,
    Expression<String>? permisos,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (nombre != null) 'nombre': nombre,
      if (correo != null) 'correo': correo,
      if (rol != null) 'rol': rol,
      if (uuidDistribuidora != null) 'uuid_distribuidora': uuidDistribuidora,
      if (permisos != null) 'permisos': permisos,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsuariosCompanion copyWith({
    Value<String>? uid,
    Value<String>? nombre,
    Value<String>? correo,
    Value<String>? rol,
    Value<String>? uuidDistribuidora,
    Value<Map<String, bool>>? permisos,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return UsuariosCompanion(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      uuidDistribuidora: uuidDistribuidora ?? this.uuidDistribuidora,
      permisos: permisos ?? this.permisos,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (correo.present) {
      map['correo'] = Variable<String>(correo.value);
    }
    if (rol.present) {
      map['rol'] = Variable<String>(rol.value);
    }
    if (uuidDistribuidora.present) {
      map['uuid_distribuidora'] = Variable<String>(uuidDistribuidora.value);
    }
    if (permisos.present) {
      map['permisos'] = Variable<String>(
        $UsuariosTable.$converterpermisos.toSql(permisos.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsuariosCompanion(')
          ..write('uid: $uid, ')
          ..write('nombre: $nombre, ')
          ..write('correo: $correo, ')
          ..write('rol: $rol, ')
          ..write('uuidDistribuidora: $uuidDistribuidora, ')
          ..write('permisos: $permisos, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DistribuidoresTable extends Distribuidores
    with TableInfo<$DistribuidoresTable, DistribuidorDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DistribuidoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _grupoMeta = const VerificationMeta('grupo');
  @override
  late final GeneratedColumn<String> grupo = GeneratedColumn<String>(
    'grupo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('AFMZD'),
  );
  static const VerificationMeta _direccionMeta = const VerificationMeta(
    'direccion',
  );
  @override
  late final GeneratedColumn<String> direccion = GeneratedColumn<String>(
    'direccion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _latitudMeta = const VerificationMeta(
    'latitud',
  );
  @override
  late final GeneratedColumn<double> latitud = GeneratedColumn<double>(
    'latitud',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _longitudMeta = const VerificationMeta(
    'longitud',
  );
  @override
  late final GeneratedColumn<double> longitud = GeneratedColumn<double>(
    'longitud',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uid,
    nombre,
    grupo,
    direccion,
    activo,
    latitud,
    longitud,
    updatedAt,
    deleted,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'distribuidores';
  @override
  VerificationContext validateIntegrity(
    Insertable<DistribuidorDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    }
    if (data.containsKey('grupo')) {
      context.handle(
        _grupoMeta,
        grupo.isAcceptableOrUnknown(data['grupo']!, _grupoMeta),
      );
    }
    if (data.containsKey('direccion')) {
      context.handle(
        _direccionMeta,
        direccion.isAcceptableOrUnknown(data['direccion']!, _direccionMeta),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('latitud')) {
      context.handle(
        _latitudMeta,
        latitud.isAcceptableOrUnknown(data['latitud']!, _latitudMeta),
      );
    }
    if (data.containsKey('longitud')) {
      context.handle(
        _longitudMeta,
        longitud.isAcceptableOrUnknown(data['longitud']!, _longitudMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DistribuidorDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DistribuidorDb(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      grupo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grupo'],
      )!,
      direccion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direccion'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      latitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitud'],
      )!,
      longitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $DistribuidoresTable createAlias(String alias) {
    return $DistribuidoresTable(attachedDatabase, alias);
  }
}

class DistribuidorDb extends DataClass implements Insertable<DistribuidorDb> {
  final String uid;
  final String nombre;
  final String grupo;
  final String direccion;
  final bool activo;
  final double latitud;
  final double longitud;
  final DateTime updatedAt;
  final bool deleted;
  final bool isSynced;
  const DistribuidorDb({
    required this.uid,
    required this.nombre,
    required this.grupo,
    required this.direccion,
    required this.activo,
    required this.latitud,
    required this.longitud,
    required this.updatedAt,
    required this.deleted,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['nombre'] = Variable<String>(nombre);
    map['grupo'] = Variable<String>(grupo);
    map['direccion'] = Variable<String>(direccion);
    map['activo'] = Variable<bool>(activo);
    map['latitud'] = Variable<double>(latitud);
    map['longitud'] = Variable<double>(longitud);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  DistribuidoresCompanion toCompanion(bool nullToAbsent) {
    return DistribuidoresCompanion(
      uid: Value(uid),
      nombre: Value(nombre),
      grupo: Value(grupo),
      direccion: Value(direccion),
      activo: Value(activo),
      latitud: Value(latitud),
      longitud: Value(longitud),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      isSynced: Value(isSynced),
    );
  }

  factory DistribuidorDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DistribuidorDb(
      uid: serializer.fromJson<String>(json['uid']),
      nombre: serializer.fromJson<String>(json['nombre']),
      grupo: serializer.fromJson<String>(json['grupo']),
      direccion: serializer.fromJson<String>(json['direccion']),
      activo: serializer.fromJson<bool>(json['activo']),
      latitud: serializer.fromJson<double>(json['latitud']),
      longitud: serializer.fromJson<double>(json['longitud']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'nombre': serializer.toJson<String>(nombre),
      'grupo': serializer.toJson<String>(grupo),
      'direccion': serializer.toJson<String>(direccion),
      'activo': serializer.toJson<bool>(activo),
      'latitud': serializer.toJson<double>(latitud),
      'longitud': serializer.toJson<double>(longitud),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  DistribuidorDb copyWith({
    String? uid,
    String? nombre,
    String? grupo,
    String? direccion,
    bool? activo,
    double? latitud,
    double? longitud,
    DateTime? updatedAt,
    bool? deleted,
    bool? isSynced,
  }) => DistribuidorDb(
    uid: uid ?? this.uid,
    nombre: nombre ?? this.nombre,
    grupo: grupo ?? this.grupo,
    direccion: direccion ?? this.direccion,
    activo: activo ?? this.activo,
    latitud: latitud ?? this.latitud,
    longitud: longitud ?? this.longitud,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    isSynced: isSynced ?? this.isSynced,
  );
  DistribuidorDb copyWithCompanion(DistribuidoresCompanion data) {
    return DistribuidorDb(
      uid: data.uid.present ? data.uid.value : this.uid,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      grupo: data.grupo.present ? data.grupo.value : this.grupo,
      direccion: data.direccion.present ? data.direccion.value : this.direccion,
      activo: data.activo.present ? data.activo.value : this.activo,
      latitud: data.latitud.present ? data.latitud.value : this.latitud,
      longitud: data.longitud.present ? data.longitud.value : this.longitud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DistribuidorDb(')
          ..write('uid: $uid, ')
          ..write('nombre: $nombre, ')
          ..write('grupo: $grupo, ')
          ..write('direccion: $direccion, ')
          ..write('activo: $activo, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uid,
    nombre,
    grupo,
    direccion,
    activo,
    latitud,
    longitud,
    updatedAt,
    deleted,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DistribuidorDb &&
          other.uid == this.uid &&
          other.nombre == this.nombre &&
          other.grupo == this.grupo &&
          other.direccion == this.direccion &&
          other.activo == this.activo &&
          other.latitud == this.latitud &&
          other.longitud == this.longitud &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.isSynced == this.isSynced);
}

class DistribuidoresCompanion extends UpdateCompanion<DistribuidorDb> {
  final Value<String> uid;
  final Value<String> nombre;
  final Value<String> grupo;
  final Value<String> direccion;
  final Value<bool> activo;
  final Value<double> latitud;
  final Value<double> longitud;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const DistribuidoresCompanion({
    this.uid = const Value.absent(),
    this.nombre = const Value.absent(),
    this.grupo = const Value.absent(),
    this.direccion = const Value.absent(),
    this.activo = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DistribuidoresCompanion.insert({
    required String uid,
    this.nombre = const Value.absent(),
    this.grupo = const Value.absent(),
    this.direccion = const Value.absent(),
    this.activo = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid);
  static Insertable<DistribuidorDb> custom({
    Expression<String>? uid,
    Expression<String>? nombre,
    Expression<String>? grupo,
    Expression<String>? direccion,
    Expression<bool>? activo,
    Expression<double>? latitud,
    Expression<double>? longitud,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (nombre != null) 'nombre': nombre,
      if (grupo != null) 'grupo': grupo,
      if (direccion != null) 'direccion': direccion,
      if (activo != null) 'activo': activo,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DistribuidoresCompanion copyWith({
    Value<String>? uid,
    Value<String>? nombre,
    Value<String>? grupo,
    Value<String>? direccion,
    Value<bool>? activo,
    Value<double>? latitud,
    Value<double>? longitud,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return DistribuidoresCompanion(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      grupo: grupo ?? this.grupo,
      direccion: direccion ?? this.direccion,
      activo: activo ?? this.activo,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (grupo.present) {
      map['grupo'] = Variable<String>(grupo.value);
    }
    if (direccion.present) {
      map['direccion'] = Variable<String>(direccion.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (latitud.present) {
      map['latitud'] = Variable<double>(latitud.value);
    }
    if (longitud.present) {
      map['longitud'] = Variable<double>(longitud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DistribuidoresCompanion(')
          ..write('uid: $uid, ')
          ..write('nombre: $nombre, ')
          ..write('grupo: $grupo, ')
          ..write('direccion: $direccion, ')
          ..write('activo: $activo, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsuariosTable usuarios = $UsuariosTable(this);
  late final $DistribuidoresTable distribuidores = $DistribuidoresTable(this);
  late final UsuariosDao usuariosDao = UsuariosDao(this as AppDatabase);
  late final DistribuidoresDao distribuidoresDao = DistribuidoresDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    usuarios,
    distribuidores,
  ];
}

typedef $$UsuariosTableCreateCompanionBuilder =
    UsuariosCompanion Function({
      required String uid,
      Value<String> nombre,
      Value<String> correo,
      Value<String> rol,
      Value<String> uuidDistribuidora,
      Value<Map<String, bool>> permisos,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$UsuariosTableUpdateCompanionBuilder =
    UsuariosCompanion Function({
      Value<String> uid,
      Value<String> nombre,
      Value<String> correo,
      Value<String> rol,
      Value<String> uuidDistribuidora,
      Value<Map<String, bool>> permisos,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$UsuariosTableFilterComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correo => $composableBuilder(
    column: $table.correo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuidDistribuidora => $composableBuilder(
    column: $table.uuidDistribuidora,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Map<String, bool>, Map<String, bool>, String>
  get permisos => $composableBuilder(
    column: $table.permisos,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsuariosTableOrderingComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correo => $composableBuilder(
    column: $table.correo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuidDistribuidora => $composableBuilder(
    column: $table.uuidDistribuidora,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permisos => $composableBuilder(
    column: $table.permisos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsuariosTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get correo =>
      $composableBuilder(column: $table.correo, builder: (column) => column);

  GeneratedColumn<String> get rol =>
      $composableBuilder(column: $table.rol, builder: (column) => column);

  GeneratedColumn<String> get uuidDistribuidora => $composableBuilder(
    column: $table.uuidDistribuidora,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Map<String, bool>, String> get permisos =>
      $composableBuilder(column: $table.permisos, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$UsuariosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsuariosTable,
          UsuarioDb,
          $$UsuariosTableFilterComposer,
          $$UsuariosTableOrderingComposer,
          $$UsuariosTableAnnotationComposer,
          $$UsuariosTableCreateCompanionBuilder,
          $$UsuariosTableUpdateCompanionBuilder,
          (UsuarioDb, BaseReferences<_$AppDatabase, $UsuariosTable, UsuarioDb>),
          UsuarioDb,
          PrefetchHooks Function()
        > {
  $$UsuariosTableTableManager(_$AppDatabase db, $UsuariosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsuariosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsuariosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsuariosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> correo = const Value.absent(),
                Value<String> rol = const Value.absent(),
                Value<String> uuidDistribuidora = const Value.absent(),
                Value<Map<String, bool>> permisos = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion(
                uid: uid,
                nombre: nombre,
                correo: correo,
                rol: rol,
                uuidDistribuidora: uuidDistribuidora,
                permisos: permisos,
                updatedAt: updatedAt,
                deleted: deleted,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                Value<String> nombre = const Value.absent(),
                Value<String> correo = const Value.absent(),
                Value<String> rol = const Value.absent(),
                Value<String> uuidDistribuidora = const Value.absent(),
                Value<Map<String, bool>> permisos = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion.insert(
                uid: uid,
                nombre: nombre,
                correo: correo,
                rol: rol,
                uuidDistribuidora: uuidDistribuidora,
                permisos: permisos,
                updatedAt: updatedAt,
                deleted: deleted,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsuariosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsuariosTable,
      UsuarioDb,
      $$UsuariosTableFilterComposer,
      $$UsuariosTableOrderingComposer,
      $$UsuariosTableAnnotationComposer,
      $$UsuariosTableCreateCompanionBuilder,
      $$UsuariosTableUpdateCompanionBuilder,
      (UsuarioDb, BaseReferences<_$AppDatabase, $UsuariosTable, UsuarioDb>),
      UsuarioDb,
      PrefetchHooks Function()
    >;
typedef $$DistribuidoresTableCreateCompanionBuilder =
    DistribuidoresCompanion Function({
      required String uid,
      Value<String> nombre,
      Value<String> grupo,
      Value<String> direccion,
      Value<bool> activo,
      Value<double> latitud,
      Value<double> longitud,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$DistribuidoresTableUpdateCompanionBuilder =
    DistribuidoresCompanion Function({
      Value<String> uid,
      Value<String> nombre,
      Value<String> grupo,
      Value<String> direccion,
      Value<bool> activo,
      Value<double> latitud,
      Value<double> longitud,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$DistribuidoresTableFilterComposer
    extends Composer<_$AppDatabase, $DistribuidoresTable> {
  $$DistribuidoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grupo => $composableBuilder(
    column: $table.grupo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direccion => $composableBuilder(
    column: $table.direccion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DistribuidoresTableOrderingComposer
    extends Composer<_$AppDatabase, $DistribuidoresTable> {
  $$DistribuidoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grupo => $composableBuilder(
    column: $table.grupo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direccion => $composableBuilder(
    column: $table.direccion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DistribuidoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $DistribuidoresTable> {
  $$DistribuidoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get grupo =>
      $composableBuilder(column: $table.grupo, builder: (column) => column);

  GeneratedColumn<String> get direccion =>
      $composableBuilder(column: $table.direccion, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<double> get latitud =>
      $composableBuilder(column: $table.latitud, builder: (column) => column);

  GeneratedColumn<double> get longitud =>
      $composableBuilder(column: $table.longitud, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$DistribuidoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DistribuidoresTable,
          DistribuidorDb,
          $$DistribuidoresTableFilterComposer,
          $$DistribuidoresTableOrderingComposer,
          $$DistribuidoresTableAnnotationComposer,
          $$DistribuidoresTableCreateCompanionBuilder,
          $$DistribuidoresTableUpdateCompanionBuilder,
          (
            DistribuidorDb,
            BaseReferences<_$AppDatabase, $DistribuidoresTable, DistribuidorDb>,
          ),
          DistribuidorDb,
          PrefetchHooks Function()
        > {
  $$DistribuidoresTableTableManager(
    _$AppDatabase db,
    $DistribuidoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DistribuidoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DistribuidoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DistribuidoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> grupo = const Value.absent(),
                Value<String> direccion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<double> latitud = const Value.absent(),
                Value<double> longitud = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DistribuidoresCompanion(
                uid: uid,
                nombre: nombre,
                grupo: grupo,
                direccion: direccion,
                activo: activo,
                latitud: latitud,
                longitud: longitud,
                updatedAt: updatedAt,
                deleted: deleted,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                Value<String> nombre = const Value.absent(),
                Value<String> grupo = const Value.absent(),
                Value<String> direccion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<double> latitud = const Value.absent(),
                Value<double> longitud = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DistribuidoresCompanion.insert(
                uid: uid,
                nombre: nombre,
                grupo: grupo,
                direccion: direccion,
                activo: activo,
                latitud: latitud,
                longitud: longitud,
                updatedAt: updatedAt,
                deleted: deleted,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DistribuidoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DistribuidoresTable,
      DistribuidorDb,
      $$DistribuidoresTableFilterComposer,
      $$DistribuidoresTableOrderingComposer,
      $$DistribuidoresTableAnnotationComposer,
      $$DistribuidoresTableCreateCompanionBuilder,
      $$DistribuidoresTableUpdateCompanionBuilder,
      (
        DistribuidorDb,
        BaseReferences<_$AppDatabase, $DistribuidoresTable, DistribuidorDb>,
      ),
      DistribuidorDb,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsuariosTableTableManager get usuarios =>
      $$UsuariosTableTableManager(_db, _db.usuarios);
  $$DistribuidoresTableTableManager get distribuidores =>
      $$DistribuidoresTableTableManager(_db, _db.distribuidores);
}
