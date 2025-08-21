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

class $ReportesTable extends Reportes
    with TableInfo<$ReportesTable, ReportesDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReportesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _rutaRemotaMeta = const VerificationMeta(
    'rutaRemota',
  );
  @override
  late final GeneratedColumn<String> rutaRemota = GeneratedColumn<String>(
    'ruta_remota',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _rutaLocalMeta = const VerificationMeta(
    'rutaLocal',
  );
  @override
  late final GeneratedColumn<String> rutaLocal = GeneratedColumn<String>(
    'ruta_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    defaultValue: const Constant(true),
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
  @override
  List<GeneratedColumn> get $columns => [
    uid,
    nombre,
    fecha,
    rutaRemota,
    rutaLocal,
    tipo,
    updatedAt,
    isSynced,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reportes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReportesDb> instance, {
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
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    }
    if (data.containsKey('ruta_remota')) {
      context.handle(
        _rutaRemotaMeta,
        rutaRemota.isAcceptableOrUnknown(data['ruta_remota']!, _rutaRemotaMeta),
      );
    }
    if (data.containsKey('ruta_local')) {
      context.handle(
        _rutaLocalMeta,
        rutaLocal.isAcceptableOrUnknown(data['ruta_local']!, _rutaLocalMeta),
      );
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  ReportesDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReportesDb(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      rutaRemota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruta_remota'],
      )!,
      rutaLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruta_local'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $ReportesTable createAlias(String alias) {
    return $ReportesTable(attachedDatabase, alias);
  }
}

class ReportesDb extends DataClass implements Insertable<ReportesDb> {
  final String uid;
  final String nombre;
  final DateTime fecha;
  final String rutaRemota;
  final String rutaLocal;
  final String tipo;
  final DateTime updatedAt;
  final bool isSynced;
  final bool deleted;
  const ReportesDb({
    required this.uid,
    required this.nombre,
    required this.fecha,
    required this.rutaRemota,
    required this.rutaLocal,
    required this.tipo,
    required this.updatedAt,
    required this.isSynced,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['nombre'] = Variable<String>(nombre);
    map['fecha'] = Variable<DateTime>(fecha);
    map['ruta_remota'] = Variable<String>(rutaRemota);
    map['ruta_local'] = Variable<String>(rutaLocal);
    map['tipo'] = Variable<String>(tipo);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  ReportesCompanion toCompanion(bool nullToAbsent) {
    return ReportesCompanion(
      uid: Value(uid),
      nombre: Value(nombre),
      fecha: Value(fecha),
      rutaRemota: Value(rutaRemota),
      rutaLocal: Value(rutaLocal),
      tipo: Value(tipo),
      updatedAt: Value(updatedAt),
      isSynced: Value(isSynced),
      deleted: Value(deleted),
    );
  }

  factory ReportesDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReportesDb(
      uid: serializer.fromJson<String>(json['uid']),
      nombre: serializer.fromJson<String>(json['nombre']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      rutaRemota: serializer.fromJson<String>(json['rutaRemota']),
      rutaLocal: serializer.fromJson<String>(json['rutaLocal']),
      tipo: serializer.fromJson<String>(json['tipo']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'nombre': serializer.toJson<String>(nombre),
      'fecha': serializer.toJson<DateTime>(fecha),
      'rutaRemota': serializer.toJson<String>(rutaRemota),
      'rutaLocal': serializer.toJson<String>(rutaLocal),
      'tipo': serializer.toJson<String>(tipo),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  ReportesDb copyWith({
    String? uid,
    String? nombre,
    DateTime? fecha,
    String? rutaRemota,
    String? rutaLocal,
    String? tipo,
    DateTime? updatedAt,
    bool? isSynced,
    bool? deleted,
  }) => ReportesDb(
    uid: uid ?? this.uid,
    nombre: nombre ?? this.nombre,
    fecha: fecha ?? this.fecha,
    rutaRemota: rutaRemota ?? this.rutaRemota,
    rutaLocal: rutaLocal ?? this.rutaLocal,
    tipo: tipo ?? this.tipo,
    updatedAt: updatedAt ?? this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
    deleted: deleted ?? this.deleted,
  );
  ReportesDb copyWithCompanion(ReportesCompanion data) {
    return ReportesDb(
      uid: data.uid.present ? data.uid.value : this.uid,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      rutaRemota: data.rutaRemota.present
          ? data.rutaRemota.value
          : this.rutaRemota,
      rutaLocal: data.rutaLocal.present ? data.rutaLocal.value : this.rutaLocal,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReportesDb(')
          ..write('uid: $uid, ')
          ..write('nombre: $nombre, ')
          ..write('fecha: $fecha, ')
          ..write('rutaRemota: $rutaRemota, ')
          ..write('rutaLocal: $rutaLocal, ')
          ..write('tipo: $tipo, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uid,
    nombre,
    fecha,
    rutaRemota,
    rutaLocal,
    tipo,
    updatedAt,
    isSynced,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReportesDb &&
          other.uid == this.uid &&
          other.nombre == this.nombre &&
          other.fecha == this.fecha &&
          other.rutaRemota == this.rutaRemota &&
          other.rutaLocal == this.rutaLocal &&
          other.tipo == this.tipo &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced &&
          other.deleted == this.deleted);
}

class ReportesCompanion extends UpdateCompanion<ReportesDb> {
  final Value<String> uid;
  final Value<String> nombre;
  final Value<DateTime> fecha;
  final Value<String> rutaRemota;
  final Value<String> rutaLocal;
  final Value<String> tipo;
  final Value<DateTime> updatedAt;
  final Value<bool> isSynced;
  final Value<bool> deleted;
  final Value<int> rowid;
  const ReportesCompanion({
    this.uid = const Value.absent(),
    this.nombre = const Value.absent(),
    this.fecha = const Value.absent(),
    this.rutaRemota = const Value.absent(),
    this.rutaLocal = const Value.absent(),
    this.tipo = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReportesCompanion.insert({
    required String uid,
    this.nombre = const Value.absent(),
    this.fecha = const Value.absent(),
    this.rutaRemota = const Value.absent(),
    this.rutaLocal = const Value.absent(),
    this.tipo = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid);
  static Insertable<ReportesDb> custom({
    Expression<String>? uid,
    Expression<String>? nombre,
    Expression<DateTime>? fecha,
    Expression<String>? rutaRemota,
    Expression<String>? rutaLocal,
    Expression<String>? tipo,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (nombre != null) 'nombre': nombre,
      if (fecha != null) 'fecha': fecha,
      if (rutaRemota != null) 'ruta_remota': rutaRemota,
      if (rutaLocal != null) 'ruta_local': rutaLocal,
      if (tipo != null) 'tipo': tipo,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReportesCompanion copyWith({
    Value<String>? uid,
    Value<String>? nombre,
    Value<DateTime>? fecha,
    Value<String>? rutaRemota,
    Value<String>? rutaLocal,
    Value<String>? tipo,
    Value<DateTime>? updatedAt,
    Value<bool>? isSynced,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return ReportesCompanion(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      fecha: fecha ?? this.fecha,
      rutaRemota: rutaRemota ?? this.rutaRemota,
      rutaLocal: rutaLocal ?? this.rutaLocal,
      tipo: tipo ?? this.tipo,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deleted: deleted ?? this.deleted,
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
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (rutaRemota.present) {
      map['ruta_remota'] = Variable<String>(rutaRemota.value);
    }
    if (rutaLocal.present) {
      map['ruta_local'] = Variable<String>(rutaLocal.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReportesCompanion(')
          ..write('uid: $uid, ')
          ..write('nombre: $nombre, ')
          ..write('fecha: $fecha, ')
          ..write('rutaRemota: $rutaRemota, ')
          ..write('rutaLocal: $rutaLocal, ')
          ..write('tipo: $tipo, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModelosTable extends Modelos with TableInfo<$ModelosTable, ModeloDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModelosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _claveCatalogoMeta = const VerificationMeta(
    'claveCatalogo',
  );
  @override
  late final GeneratedColumn<String> claveCatalogo = GeneratedColumn<String>(
    'clave_catalogo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _marcaMeta = const VerificationMeta('marca');
  @override
  late final GeneratedColumn<String> marca = GeneratedColumn<String>(
    'marca',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Mazda'),
  );
  static const VerificationMeta _modeloMeta = const VerificationMeta('modelo');
  @override
  late final GeneratedColumn<String> modelo = GeneratedColumn<String>(
    'modelo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _anioMeta = const VerificationMeta('anio');
  @override
  late final GeneratedColumn<int> anio = GeneratedColumn<int>(
    'anio',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _transmisionMeta = const VerificationMeta(
    'transmision',
  );
  @override
  late final GeneratedColumn<String> transmision = GeneratedColumn<String>(
    'transmision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
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
  static const VerificationMeta _precioBaseMeta = const VerificationMeta(
    'precioBase',
  );
  @override
  late final GeneratedColumn<double> precioBase = GeneratedColumn<double>(
    'precio_base',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _fichaRutaRemotaMeta = const VerificationMeta(
    'fichaRutaRemota',
  );
  @override
  late final GeneratedColumn<String> fichaRutaRemota = GeneratedColumn<String>(
    'ficha_ruta_remota',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fichaRutaLocalMeta = const VerificationMeta(
    'fichaRutaLocal',
  );
  @override
  late final GeneratedColumn<String> fichaRutaLocal = GeneratedColumn<String>(
    'ficha_ruta_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    claveCatalogo,
    marca,
    modelo,
    anio,
    tipo,
    transmision,
    descripcion,
    activo,
    precioBase,
    fichaRutaRemota,
    fichaRutaLocal,
    createdAt,
    updatedAt,
    deleted,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'modelos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModeloDb> instance, {
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
    if (data.containsKey('clave_catalogo')) {
      context.handle(
        _claveCatalogoMeta,
        claveCatalogo.isAcceptableOrUnknown(
          data['clave_catalogo']!,
          _claveCatalogoMeta,
        ),
      );
    }
    if (data.containsKey('marca')) {
      context.handle(
        _marcaMeta,
        marca.isAcceptableOrUnknown(data['marca']!, _marcaMeta),
      );
    }
    if (data.containsKey('modelo')) {
      context.handle(
        _modeloMeta,
        modelo.isAcceptableOrUnknown(data['modelo']!, _modeloMeta),
      );
    }
    if (data.containsKey('anio')) {
      context.handle(
        _anioMeta,
        anio.isAcceptableOrUnknown(data['anio']!, _anioMeta),
      );
    } else if (isInserting) {
      context.missing(_anioMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    }
    if (data.containsKey('transmision')) {
      context.handle(
        _transmisionMeta,
        transmision.isAcceptableOrUnknown(
          data['transmision']!,
          _transmisionMeta,
        ),
      );
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('precio_base')) {
      context.handle(
        _precioBaseMeta,
        precioBase.isAcceptableOrUnknown(data['precio_base']!, _precioBaseMeta),
      );
    }
    if (data.containsKey('ficha_ruta_remota')) {
      context.handle(
        _fichaRutaRemotaMeta,
        fichaRutaRemota.isAcceptableOrUnknown(
          data['ficha_ruta_remota']!,
          _fichaRutaRemotaMeta,
        ),
      );
    }
    if (data.containsKey('ficha_ruta_local')) {
      context.handle(
        _fichaRutaLocalMeta,
        fichaRutaLocal.isAcceptableOrUnknown(
          data['ficha_ruta_local']!,
          _fichaRutaLocalMeta,
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
  ModeloDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModeloDb(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      claveCatalogo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clave_catalogo'],
      )!,
      marca: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marca'],
      )!,
      modelo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modelo'],
      )!,
      anio: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anio'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      transmision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transmision'],
      )!,
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      precioBase: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precio_base'],
      )!,
      fichaRutaRemota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ficha_ruta_remota'],
      )!,
      fichaRutaLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ficha_ruta_local'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
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
  $ModelosTable createAlias(String alias) {
    return $ModelosTable(attachedDatabase, alias);
  }
}

class ModeloDb extends DataClass implements Insertable<ModeloDb> {
  final String uid;
  final String claveCatalogo;
  final String marca;
  final String modelo;
  final int anio;
  final String tipo;
  final String transmision;
  final String descripcion;
  final bool activo;
  final double precioBase;
  final String fichaRutaRemota;
  final String fichaRutaLocal;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  final bool isSynced;
  const ModeloDb({
    required this.uid,
    required this.claveCatalogo,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.tipo,
    required this.transmision,
    required this.descripcion,
    required this.activo,
    required this.precioBase,
    required this.fichaRutaRemota,
    required this.fichaRutaLocal,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['clave_catalogo'] = Variable<String>(claveCatalogo);
    map['marca'] = Variable<String>(marca);
    map['modelo'] = Variable<String>(modelo);
    map['anio'] = Variable<int>(anio);
    map['tipo'] = Variable<String>(tipo);
    map['transmision'] = Variable<String>(transmision);
    map['descripcion'] = Variable<String>(descripcion);
    map['activo'] = Variable<bool>(activo);
    map['precio_base'] = Variable<double>(precioBase);
    map['ficha_ruta_remota'] = Variable<String>(fichaRutaRemota);
    map['ficha_ruta_local'] = Variable<String>(fichaRutaLocal);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  ModelosCompanion toCompanion(bool nullToAbsent) {
    return ModelosCompanion(
      uid: Value(uid),
      claveCatalogo: Value(claveCatalogo),
      marca: Value(marca),
      modelo: Value(modelo),
      anio: Value(anio),
      tipo: Value(tipo),
      transmision: Value(transmision),
      descripcion: Value(descripcion),
      activo: Value(activo),
      precioBase: Value(precioBase),
      fichaRutaRemota: Value(fichaRutaRemota),
      fichaRutaLocal: Value(fichaRutaLocal),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      isSynced: Value(isSynced),
    );
  }

  factory ModeloDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModeloDb(
      uid: serializer.fromJson<String>(json['uid']),
      claveCatalogo: serializer.fromJson<String>(json['claveCatalogo']),
      marca: serializer.fromJson<String>(json['marca']),
      modelo: serializer.fromJson<String>(json['modelo']),
      anio: serializer.fromJson<int>(json['anio']),
      tipo: serializer.fromJson<String>(json['tipo']),
      transmision: serializer.fromJson<String>(json['transmision']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      activo: serializer.fromJson<bool>(json['activo']),
      precioBase: serializer.fromJson<double>(json['precioBase']),
      fichaRutaRemota: serializer.fromJson<String>(json['fichaRutaRemota']),
      fichaRutaLocal: serializer.fromJson<String>(json['fichaRutaLocal']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
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
      'claveCatalogo': serializer.toJson<String>(claveCatalogo),
      'marca': serializer.toJson<String>(marca),
      'modelo': serializer.toJson<String>(modelo),
      'anio': serializer.toJson<int>(anio),
      'tipo': serializer.toJson<String>(tipo),
      'transmision': serializer.toJson<String>(transmision),
      'descripcion': serializer.toJson<String>(descripcion),
      'activo': serializer.toJson<bool>(activo),
      'precioBase': serializer.toJson<double>(precioBase),
      'fichaRutaRemota': serializer.toJson<String>(fichaRutaRemota),
      'fichaRutaLocal': serializer.toJson<String>(fichaRutaLocal),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  ModeloDb copyWith({
    String? uid,
    String? claveCatalogo,
    String? marca,
    String? modelo,
    int? anio,
    String? tipo,
    String? transmision,
    String? descripcion,
    bool? activo,
    double? precioBase,
    String? fichaRutaRemota,
    String? fichaRutaLocal,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
    bool? isSynced,
  }) => ModeloDb(
    uid: uid ?? this.uid,
    claveCatalogo: claveCatalogo ?? this.claveCatalogo,
    marca: marca ?? this.marca,
    modelo: modelo ?? this.modelo,
    anio: anio ?? this.anio,
    tipo: tipo ?? this.tipo,
    transmision: transmision ?? this.transmision,
    descripcion: descripcion ?? this.descripcion,
    activo: activo ?? this.activo,
    precioBase: precioBase ?? this.precioBase,
    fichaRutaRemota: fichaRutaRemota ?? this.fichaRutaRemota,
    fichaRutaLocal: fichaRutaLocal ?? this.fichaRutaLocal,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    isSynced: isSynced ?? this.isSynced,
  );
  ModeloDb copyWithCompanion(ModelosCompanion data) {
    return ModeloDb(
      uid: data.uid.present ? data.uid.value : this.uid,
      claveCatalogo: data.claveCatalogo.present
          ? data.claveCatalogo.value
          : this.claveCatalogo,
      marca: data.marca.present ? data.marca.value : this.marca,
      modelo: data.modelo.present ? data.modelo.value : this.modelo,
      anio: data.anio.present ? data.anio.value : this.anio,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      transmision: data.transmision.present
          ? data.transmision.value
          : this.transmision,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      activo: data.activo.present ? data.activo.value : this.activo,
      precioBase: data.precioBase.present
          ? data.precioBase.value
          : this.precioBase,
      fichaRutaRemota: data.fichaRutaRemota.present
          ? data.fichaRutaRemota.value
          : this.fichaRutaRemota,
      fichaRutaLocal: data.fichaRutaLocal.present
          ? data.fichaRutaLocal.value
          : this.fichaRutaLocal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModeloDb(')
          ..write('uid: $uid, ')
          ..write('claveCatalogo: $claveCatalogo, ')
          ..write('marca: $marca, ')
          ..write('modelo: $modelo, ')
          ..write('anio: $anio, ')
          ..write('tipo: $tipo, ')
          ..write('transmision: $transmision, ')
          ..write('descripcion: $descripcion, ')
          ..write('activo: $activo, ')
          ..write('precioBase: $precioBase, ')
          ..write('fichaRutaRemota: $fichaRutaRemota, ')
          ..write('fichaRutaLocal: $fichaRutaLocal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uid,
    claveCatalogo,
    marca,
    modelo,
    anio,
    tipo,
    transmision,
    descripcion,
    activo,
    precioBase,
    fichaRutaRemota,
    fichaRutaLocal,
    createdAt,
    updatedAt,
    deleted,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModeloDb &&
          other.uid == this.uid &&
          other.claveCatalogo == this.claveCatalogo &&
          other.marca == this.marca &&
          other.modelo == this.modelo &&
          other.anio == this.anio &&
          other.tipo == this.tipo &&
          other.transmision == this.transmision &&
          other.descripcion == this.descripcion &&
          other.activo == this.activo &&
          other.precioBase == this.precioBase &&
          other.fichaRutaRemota == this.fichaRutaRemota &&
          other.fichaRutaLocal == this.fichaRutaLocal &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.isSynced == this.isSynced);
}

class ModelosCompanion extends UpdateCompanion<ModeloDb> {
  final Value<String> uid;
  final Value<String> claveCatalogo;
  final Value<String> marca;
  final Value<String> modelo;
  final Value<int> anio;
  final Value<String> tipo;
  final Value<String> transmision;
  final Value<String> descripcion;
  final Value<bool> activo;
  final Value<double> precioBase;
  final Value<String> fichaRutaRemota;
  final Value<String> fichaRutaLocal;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const ModelosCompanion({
    this.uid = const Value.absent(),
    this.claveCatalogo = const Value.absent(),
    this.marca = const Value.absent(),
    this.modelo = const Value.absent(),
    this.anio = const Value.absent(),
    this.tipo = const Value.absent(),
    this.transmision = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.activo = const Value.absent(),
    this.precioBase = const Value.absent(),
    this.fichaRutaRemota = const Value.absent(),
    this.fichaRutaLocal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModelosCompanion.insert({
    required String uid,
    this.claveCatalogo = const Value.absent(),
    this.marca = const Value.absent(),
    this.modelo = const Value.absent(),
    required int anio,
    this.tipo = const Value.absent(),
    this.transmision = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.activo = const Value.absent(),
    this.precioBase = const Value.absent(),
    this.fichaRutaRemota = const Value.absent(),
    this.fichaRutaLocal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       anio = Value(anio);
  static Insertable<ModeloDb> custom({
    Expression<String>? uid,
    Expression<String>? claveCatalogo,
    Expression<String>? marca,
    Expression<String>? modelo,
    Expression<int>? anio,
    Expression<String>? tipo,
    Expression<String>? transmision,
    Expression<String>? descripcion,
    Expression<bool>? activo,
    Expression<double>? precioBase,
    Expression<String>? fichaRutaRemota,
    Expression<String>? fichaRutaLocal,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (claveCatalogo != null) 'clave_catalogo': claveCatalogo,
      if (marca != null) 'marca': marca,
      if (modelo != null) 'modelo': modelo,
      if (anio != null) 'anio': anio,
      if (tipo != null) 'tipo': tipo,
      if (transmision != null) 'transmision': transmision,
      if (descripcion != null) 'descripcion': descripcion,
      if (activo != null) 'activo': activo,
      if (precioBase != null) 'precio_base': precioBase,
      if (fichaRutaRemota != null) 'ficha_ruta_remota': fichaRutaRemota,
      if (fichaRutaLocal != null) 'ficha_ruta_local': fichaRutaLocal,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModelosCompanion copyWith({
    Value<String>? uid,
    Value<String>? claveCatalogo,
    Value<String>? marca,
    Value<String>? modelo,
    Value<int>? anio,
    Value<String>? tipo,
    Value<String>? transmision,
    Value<String>? descripcion,
    Value<bool>? activo,
    Value<double>? precioBase,
    Value<String>? fichaRutaRemota,
    Value<String>? fichaRutaLocal,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return ModelosCompanion(
      uid: uid ?? this.uid,
      claveCatalogo: claveCatalogo ?? this.claveCatalogo,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      anio: anio ?? this.anio,
      tipo: tipo ?? this.tipo,
      transmision: transmision ?? this.transmision,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      precioBase: precioBase ?? this.precioBase,
      fichaRutaRemota: fichaRutaRemota ?? this.fichaRutaRemota,
      fichaRutaLocal: fichaRutaLocal ?? this.fichaRutaLocal,
      createdAt: createdAt ?? this.createdAt,
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
    if (claveCatalogo.present) {
      map['clave_catalogo'] = Variable<String>(claveCatalogo.value);
    }
    if (marca.present) {
      map['marca'] = Variable<String>(marca.value);
    }
    if (modelo.present) {
      map['modelo'] = Variable<String>(modelo.value);
    }
    if (anio.present) {
      map['anio'] = Variable<int>(anio.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (transmision.present) {
      map['transmision'] = Variable<String>(transmision.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (precioBase.present) {
      map['precio_base'] = Variable<double>(precioBase.value);
    }
    if (fichaRutaRemota.present) {
      map['ficha_ruta_remota'] = Variable<String>(fichaRutaRemota.value);
    }
    if (fichaRutaLocal.present) {
      map['ficha_ruta_local'] = Variable<String>(fichaRutaLocal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('ModelosCompanion(')
          ..write('uid: $uid, ')
          ..write('claveCatalogo: $claveCatalogo, ')
          ..write('marca: $marca, ')
          ..write('modelo: $modelo, ')
          ..write('anio: $anio, ')
          ..write('tipo: $tipo, ')
          ..write('transmision: $transmision, ')
          ..write('descripcion: $descripcion, ')
          ..write('activo: $activo, ')
          ..write('precioBase: $precioBase, ')
          ..write('fichaRutaRemota: $fichaRutaRemota, ')
          ..write('fichaRutaLocal: $fichaRutaLocal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModeloImagenesTable extends ModeloImagenes
    with TableInfo<$ModeloImagenesTable, ModeloImagenDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModeloImagenesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeloUidMeta = const VerificationMeta(
    'modeloUid',
  );
  @override
  late final GeneratedColumn<String> modeloUid = GeneratedColumn<String>(
    'modelo_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rutaRemotaMeta = const VerificationMeta(
    'rutaRemota',
  );
  @override
  late final GeneratedColumn<String> rutaRemota = GeneratedColumn<String>(
    'ruta_remota',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _rutaLocalMeta = const VerificationMeta(
    'rutaLocal',
  );
  @override
  late final GeneratedColumn<String> rutaLocal = GeneratedColumn<String>(
    'ruta_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    modeloUid,
    rutaRemota,
    rutaLocal,
    updatedAt,
    deleted,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'modelo_imagenes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModeloImagenDb> instance, {
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
    if (data.containsKey('modelo_uid')) {
      context.handle(
        _modeloUidMeta,
        modeloUid.isAcceptableOrUnknown(data['modelo_uid']!, _modeloUidMeta),
      );
    } else if (isInserting) {
      context.missing(_modeloUidMeta);
    }
    if (data.containsKey('ruta_remota')) {
      context.handle(
        _rutaRemotaMeta,
        rutaRemota.isAcceptableOrUnknown(data['ruta_remota']!, _rutaRemotaMeta),
      );
    }
    if (data.containsKey('ruta_local')) {
      context.handle(
        _rutaLocalMeta,
        rutaLocal.isAcceptableOrUnknown(data['ruta_local']!, _rutaLocalMeta),
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
  ModeloImagenDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModeloImagenDb(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      modeloUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modelo_uid'],
      )!,
      rutaRemota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruta_remota'],
      )!,
      rutaLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruta_local'],
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
  $ModeloImagenesTable createAlias(String alias) {
    return $ModeloImagenesTable(attachedDatabase, alias);
  }
}

class ModeloImagenDb extends DataClass implements Insertable<ModeloImagenDb> {
  final String uid;
  final String modeloUid;
  final String rutaRemota;
  final String rutaLocal;
  final DateTime updatedAt;
  final bool deleted;
  final bool isSynced;
  const ModeloImagenDb({
    required this.uid,
    required this.modeloUid,
    required this.rutaRemota,
    required this.rutaLocal,
    required this.updatedAt,
    required this.deleted,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['modelo_uid'] = Variable<String>(modeloUid);
    map['ruta_remota'] = Variable<String>(rutaRemota);
    map['ruta_local'] = Variable<String>(rutaLocal);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  ModeloImagenesCompanion toCompanion(bool nullToAbsent) {
    return ModeloImagenesCompanion(
      uid: Value(uid),
      modeloUid: Value(modeloUid),
      rutaRemota: Value(rutaRemota),
      rutaLocal: Value(rutaLocal),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      isSynced: Value(isSynced),
    );
  }

  factory ModeloImagenDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModeloImagenDb(
      uid: serializer.fromJson<String>(json['uid']),
      modeloUid: serializer.fromJson<String>(json['modeloUid']),
      rutaRemota: serializer.fromJson<String>(json['rutaRemota']),
      rutaLocal: serializer.fromJson<String>(json['rutaLocal']),
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
      'modeloUid': serializer.toJson<String>(modeloUid),
      'rutaRemota': serializer.toJson<String>(rutaRemota),
      'rutaLocal': serializer.toJson<String>(rutaLocal),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  ModeloImagenDb copyWith({
    String? uid,
    String? modeloUid,
    String? rutaRemota,
    String? rutaLocal,
    DateTime? updatedAt,
    bool? deleted,
    bool? isSynced,
  }) => ModeloImagenDb(
    uid: uid ?? this.uid,
    modeloUid: modeloUid ?? this.modeloUid,
    rutaRemota: rutaRemota ?? this.rutaRemota,
    rutaLocal: rutaLocal ?? this.rutaLocal,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    isSynced: isSynced ?? this.isSynced,
  );
  ModeloImagenDb copyWithCompanion(ModeloImagenesCompanion data) {
    return ModeloImagenDb(
      uid: data.uid.present ? data.uid.value : this.uid,
      modeloUid: data.modeloUid.present ? data.modeloUid.value : this.modeloUid,
      rutaRemota: data.rutaRemota.present
          ? data.rutaRemota.value
          : this.rutaRemota,
      rutaLocal: data.rutaLocal.present ? data.rutaLocal.value : this.rutaLocal,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModeloImagenDb(')
          ..write('uid: $uid, ')
          ..write('modeloUid: $modeloUid, ')
          ..write('rutaRemota: $rutaRemota, ')
          ..write('rutaLocal: $rutaLocal, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uid,
    modeloUid,
    rutaRemota,
    rutaLocal,
    updatedAt,
    deleted,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModeloImagenDb &&
          other.uid == this.uid &&
          other.modeloUid == this.modeloUid &&
          other.rutaRemota == this.rutaRemota &&
          other.rutaLocal == this.rutaLocal &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.isSynced == this.isSynced);
}

class ModeloImagenesCompanion extends UpdateCompanion<ModeloImagenDb> {
  final Value<String> uid;
  final Value<String> modeloUid;
  final Value<String> rutaRemota;
  final Value<String> rutaLocal;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const ModeloImagenesCompanion({
    this.uid = const Value.absent(),
    this.modeloUid = const Value.absent(),
    this.rutaRemota = const Value.absent(),
    this.rutaLocal = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModeloImagenesCompanion.insert({
    required String uid,
    required String modeloUid,
    this.rutaRemota = const Value.absent(),
    this.rutaLocal = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       modeloUid = Value(modeloUid);
  static Insertable<ModeloImagenDb> custom({
    Expression<String>? uid,
    Expression<String>? modeloUid,
    Expression<String>? rutaRemota,
    Expression<String>? rutaLocal,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (modeloUid != null) 'modelo_uid': modeloUid,
      if (rutaRemota != null) 'ruta_remota': rutaRemota,
      if (rutaLocal != null) 'ruta_local': rutaLocal,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModeloImagenesCompanion copyWith({
    Value<String>? uid,
    Value<String>? modeloUid,
    Value<String>? rutaRemota,
    Value<String>? rutaLocal,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return ModeloImagenesCompanion(
      uid: uid ?? this.uid,
      modeloUid: modeloUid ?? this.modeloUid,
      rutaRemota: rutaRemota ?? this.rutaRemota,
      rutaLocal: rutaLocal ?? this.rutaLocal,
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
    if (modeloUid.present) {
      map['modelo_uid'] = Variable<String>(modeloUid.value);
    }
    if (rutaRemota.present) {
      map['ruta_remota'] = Variable<String>(rutaRemota.value);
    }
    if (rutaLocal.present) {
      map['ruta_local'] = Variable<String>(rutaLocal.value);
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
    return (StringBuffer('ModeloImagenesCompanion(')
          ..write('uid: $uid, ')
          ..write('modeloUid: $modeloUid, ')
          ..write('rutaRemota: $rutaRemota, ')
          ..write('rutaLocal: $rutaLocal, ')
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
  late final $ReportesTable reportes = $ReportesTable(this);
  late final $ModelosTable modelos = $ModelosTable(this);
  late final $ModeloImagenesTable modeloImagenes = $ModeloImagenesTable(this);
  late final UsuariosDao usuariosDao = UsuariosDao(this as AppDatabase);
  late final DistribuidoresDao distribuidoresDao = DistribuidoresDao(
    this as AppDatabase,
  );
  late final ReportesDao reportesDao = ReportesDao(this as AppDatabase);
  late final ModelosDao modelosDao = ModelosDao(this as AppDatabase);
  late final ModeloImagenesDao modeloImagenesDao = ModeloImagenesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    usuarios,
    distribuidores,
    reportes,
    modelos,
    modeloImagenes,
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
typedef $$ReportesTableCreateCompanionBuilder =
    ReportesCompanion Function({
      required String uid,
      Value<String> nombre,
      Value<DateTime> fecha,
      Value<String> rutaRemota,
      Value<String> rutaLocal,
      Value<String> tipo,
      Value<DateTime> updatedAt,
      Value<bool> isSynced,
      Value<bool> deleted,
      Value<int> rowid,
    });
typedef $$ReportesTableUpdateCompanionBuilder =
    ReportesCompanion Function({
      Value<String> uid,
      Value<String> nombre,
      Value<DateTime> fecha,
      Value<String> rutaRemota,
      Value<String> rutaLocal,
      Value<String> tipo,
      Value<DateTime> updatedAt,
      Value<bool> isSynced,
      Value<bool> deleted,
      Value<int> rowid,
    });

class $$ReportesTableFilterComposer
    extends Composer<_$AppDatabase, $ReportesTable> {
  $$ReportesTableFilterComposer({
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

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rutaRemota => $composableBuilder(
    column: $table.rutaRemota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rutaLocal => $composableBuilder(
    column: $table.rutaLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReportesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReportesTable> {
  $$ReportesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rutaRemota => $composableBuilder(
    column: $table.rutaRemota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rutaLocal => $composableBuilder(
    column: $table.rutaLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReportesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReportesTable> {
  $$ReportesTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get rutaRemota => $composableBuilder(
    column: $table.rutaRemota,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rutaLocal =>
      $composableBuilder(column: $table.rutaLocal, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$ReportesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReportesTable,
          ReportesDb,
          $$ReportesTableFilterComposer,
          $$ReportesTableOrderingComposer,
          $$ReportesTableAnnotationComposer,
          $$ReportesTableCreateCompanionBuilder,
          $$ReportesTableUpdateCompanionBuilder,
          (
            ReportesDb,
            BaseReferences<_$AppDatabase, $ReportesTable, ReportesDb>,
          ),
          ReportesDb,
          PrefetchHooks Function()
        > {
  $$ReportesTableTableManager(_$AppDatabase db, $ReportesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReportesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReportesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReportesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String> rutaRemota = const Value.absent(),
                Value<String> rutaLocal = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportesCompanion(
                uid: uid,
                nombre: nombre,
                fecha: fecha,
                rutaRemota: rutaRemota,
                rutaLocal: rutaLocal,
                tipo: tipo,
                updatedAt: updatedAt,
                isSynced: isSynced,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                Value<String> nombre = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String> rutaRemota = const Value.absent(),
                Value<String> rutaLocal = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportesCompanion.insert(
                uid: uid,
                nombre: nombre,
                fecha: fecha,
                rutaRemota: rutaRemota,
                rutaLocal: rutaLocal,
                tipo: tipo,
                updatedAt: updatedAt,
                isSynced: isSynced,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReportesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReportesTable,
      ReportesDb,
      $$ReportesTableFilterComposer,
      $$ReportesTableOrderingComposer,
      $$ReportesTableAnnotationComposer,
      $$ReportesTableCreateCompanionBuilder,
      $$ReportesTableUpdateCompanionBuilder,
      (ReportesDb, BaseReferences<_$AppDatabase, $ReportesTable, ReportesDb>),
      ReportesDb,
      PrefetchHooks Function()
    >;
typedef $$ModelosTableCreateCompanionBuilder =
    ModelosCompanion Function({
      required String uid,
      Value<String> claveCatalogo,
      Value<String> marca,
      Value<String> modelo,
      required int anio,
      Value<String> tipo,
      Value<String> transmision,
      Value<String> descripcion,
      Value<bool> activo,
      Value<double> precioBase,
      Value<String> fichaRutaRemota,
      Value<String> fichaRutaLocal,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$ModelosTableUpdateCompanionBuilder =
    ModelosCompanion Function({
      Value<String> uid,
      Value<String> claveCatalogo,
      Value<String> marca,
      Value<String> modelo,
      Value<int> anio,
      Value<String> tipo,
      Value<String> transmision,
      Value<String> descripcion,
      Value<bool> activo,
      Value<double> precioBase,
      Value<String> fichaRutaRemota,
      Value<String> fichaRutaLocal,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$ModelosTableFilterComposer
    extends Composer<_$AppDatabase, $ModelosTable> {
  $$ModelosTableFilterComposer({
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

  ColumnFilters<String> get claveCatalogo => $composableBuilder(
    column: $table.claveCatalogo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marca => $composableBuilder(
    column: $table.marca,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelo => $composableBuilder(
    column: $table.modelo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anio => $composableBuilder(
    column: $table.anio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transmision => $composableBuilder(
    column: $table.transmision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precioBase => $composableBuilder(
    column: $table.precioBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fichaRutaRemota => $composableBuilder(
    column: $table.fichaRutaRemota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fichaRutaLocal => $composableBuilder(
    column: $table.fichaRutaLocal,
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

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ModelosTableOrderingComposer
    extends Composer<_$AppDatabase, $ModelosTable> {
  $$ModelosTableOrderingComposer({
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

  ColumnOrderings<String> get claveCatalogo => $composableBuilder(
    column: $table.claveCatalogo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marca => $composableBuilder(
    column: $table.marca,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelo => $composableBuilder(
    column: $table.modelo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anio => $composableBuilder(
    column: $table.anio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transmision => $composableBuilder(
    column: $table.transmision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precioBase => $composableBuilder(
    column: $table.precioBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fichaRutaRemota => $composableBuilder(
    column: $table.fichaRutaRemota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fichaRutaLocal => $composableBuilder(
    column: $table.fichaRutaLocal,
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

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModelosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModelosTable> {
  $$ModelosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get claveCatalogo => $composableBuilder(
    column: $table.claveCatalogo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get marca =>
      $composableBuilder(column: $table.marca, builder: (column) => column);

  GeneratedColumn<String> get modelo =>
      $composableBuilder(column: $table.modelo, builder: (column) => column);

  GeneratedColumn<int> get anio =>
      $composableBuilder(column: $table.anio, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get transmision => $composableBuilder(
    column: $table.transmision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<double> get precioBase => $composableBuilder(
    column: $table.precioBase,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fichaRutaRemota => $composableBuilder(
    column: $table.fichaRutaRemota,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fichaRutaLocal => $composableBuilder(
    column: $table.fichaRutaLocal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$ModelosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModelosTable,
          ModeloDb,
          $$ModelosTableFilterComposer,
          $$ModelosTableOrderingComposer,
          $$ModelosTableAnnotationComposer,
          $$ModelosTableCreateCompanionBuilder,
          $$ModelosTableUpdateCompanionBuilder,
          (ModeloDb, BaseReferences<_$AppDatabase, $ModelosTable, ModeloDb>),
          ModeloDb,
          PrefetchHooks Function()
        > {
  $$ModelosTableTableManager(_$AppDatabase db, $ModelosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModelosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModelosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModelosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> claveCatalogo = const Value.absent(),
                Value<String> marca = const Value.absent(),
                Value<String> modelo = const Value.absent(),
                Value<int> anio = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> transmision = const Value.absent(),
                Value<String> descripcion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<double> precioBase = const Value.absent(),
                Value<String> fichaRutaRemota = const Value.absent(),
                Value<String> fichaRutaLocal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModelosCompanion(
                uid: uid,
                claveCatalogo: claveCatalogo,
                marca: marca,
                modelo: modelo,
                anio: anio,
                tipo: tipo,
                transmision: transmision,
                descripcion: descripcion,
                activo: activo,
                precioBase: precioBase,
                fichaRutaRemota: fichaRutaRemota,
                fichaRutaLocal: fichaRutaLocal,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deleted: deleted,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                Value<String> claveCatalogo = const Value.absent(),
                Value<String> marca = const Value.absent(),
                Value<String> modelo = const Value.absent(),
                required int anio,
                Value<String> tipo = const Value.absent(),
                Value<String> transmision = const Value.absent(),
                Value<String> descripcion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<double> precioBase = const Value.absent(),
                Value<String> fichaRutaRemota = const Value.absent(),
                Value<String> fichaRutaLocal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModelosCompanion.insert(
                uid: uid,
                claveCatalogo: claveCatalogo,
                marca: marca,
                modelo: modelo,
                anio: anio,
                tipo: tipo,
                transmision: transmision,
                descripcion: descripcion,
                activo: activo,
                precioBase: precioBase,
                fichaRutaRemota: fichaRutaRemota,
                fichaRutaLocal: fichaRutaLocal,
                createdAt: createdAt,
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

typedef $$ModelosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModelosTable,
      ModeloDb,
      $$ModelosTableFilterComposer,
      $$ModelosTableOrderingComposer,
      $$ModelosTableAnnotationComposer,
      $$ModelosTableCreateCompanionBuilder,
      $$ModelosTableUpdateCompanionBuilder,
      (ModeloDb, BaseReferences<_$AppDatabase, $ModelosTable, ModeloDb>),
      ModeloDb,
      PrefetchHooks Function()
    >;
typedef $$ModeloImagenesTableCreateCompanionBuilder =
    ModeloImagenesCompanion Function({
      required String uid,
      required String modeloUid,
      Value<String> rutaRemota,
      Value<String> rutaLocal,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$ModeloImagenesTableUpdateCompanionBuilder =
    ModeloImagenesCompanion Function({
      Value<String> uid,
      Value<String> modeloUid,
      Value<String> rutaRemota,
      Value<String> rutaLocal,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$ModeloImagenesTableFilterComposer
    extends Composer<_$AppDatabase, $ModeloImagenesTable> {
  $$ModeloImagenesTableFilterComposer({
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

  ColumnFilters<String> get modeloUid => $composableBuilder(
    column: $table.modeloUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rutaRemota => $composableBuilder(
    column: $table.rutaRemota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rutaLocal => $composableBuilder(
    column: $table.rutaLocal,
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

class $$ModeloImagenesTableOrderingComposer
    extends Composer<_$AppDatabase, $ModeloImagenesTable> {
  $$ModeloImagenesTableOrderingComposer({
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

  ColumnOrderings<String> get modeloUid => $composableBuilder(
    column: $table.modeloUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rutaRemota => $composableBuilder(
    column: $table.rutaRemota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rutaLocal => $composableBuilder(
    column: $table.rutaLocal,
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

class $$ModeloImagenesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModeloImagenesTable> {
  $$ModeloImagenesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get modeloUid =>
      $composableBuilder(column: $table.modeloUid, builder: (column) => column);

  GeneratedColumn<String> get rutaRemota => $composableBuilder(
    column: $table.rutaRemota,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rutaLocal =>
      $composableBuilder(column: $table.rutaLocal, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$ModeloImagenesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModeloImagenesTable,
          ModeloImagenDb,
          $$ModeloImagenesTableFilterComposer,
          $$ModeloImagenesTableOrderingComposer,
          $$ModeloImagenesTableAnnotationComposer,
          $$ModeloImagenesTableCreateCompanionBuilder,
          $$ModeloImagenesTableUpdateCompanionBuilder,
          (
            ModeloImagenDb,
            BaseReferences<_$AppDatabase, $ModeloImagenesTable, ModeloImagenDb>,
          ),
          ModeloImagenDb,
          PrefetchHooks Function()
        > {
  $$ModeloImagenesTableTableManager(
    _$AppDatabase db,
    $ModeloImagenesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModeloImagenesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModeloImagenesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModeloImagenesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> modeloUid = const Value.absent(),
                Value<String> rutaRemota = const Value.absent(),
                Value<String> rutaLocal = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModeloImagenesCompanion(
                uid: uid,
                modeloUid: modeloUid,
                rutaRemota: rutaRemota,
                rutaLocal: rutaLocal,
                updatedAt: updatedAt,
                deleted: deleted,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String modeloUid,
                Value<String> rutaRemota = const Value.absent(),
                Value<String> rutaLocal = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModeloImagenesCompanion.insert(
                uid: uid,
                modeloUid: modeloUid,
                rutaRemota: rutaRemota,
                rutaLocal: rutaLocal,
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

typedef $$ModeloImagenesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModeloImagenesTable,
      ModeloImagenDb,
      $$ModeloImagenesTableFilterComposer,
      $$ModeloImagenesTableOrderingComposer,
      $$ModeloImagenesTableAnnotationComposer,
      $$ModeloImagenesTableCreateCompanionBuilder,
      $$ModeloImagenesTableUpdateCompanionBuilder,
      (
        ModeloImagenDb,
        BaseReferences<_$AppDatabase, $ModeloImagenesTable, ModeloImagenDb>,
      ),
      ModeloImagenDb,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsuariosTableTableManager get usuarios =>
      $$UsuariosTableTableManager(_db, _db.usuarios);
  $$DistribuidoresTableTableManager get distribuidores =>
      $$DistribuidoresTableTableManager(_db, _db.distribuidores);
  $$ReportesTableTableManager get reportes =>
      $$ReportesTableTableManager(_db, _db.reportes);
  $$ModelosTableTableManager get modelos =>
      $$ModelosTableTableManager(_db, _db.modelos);
  $$ModeloImagenesTableTableManager get modeloImagenes =>
      $$ModeloImagenesTableTableManager(_db, _db.modeloImagenes);
}
