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
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isCoverMeta = const VerificationMeta(
    'isCover',
  );
  @override
  late final GeneratedColumn<bool> isCover = GeneratedColumn<bool>(
    'is_cover',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cover" IN (0, 1))',
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
    sha256,
    isCover,
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
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('is_cover')) {
      context.handle(
        _isCoverMeta,
        isCover.isAcceptableOrUnknown(data['is_cover']!, _isCoverMeta),
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
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      isCover: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_cover'],
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
  final String sha256;
  final bool isCover;
  final DateTime updatedAt;
  final bool deleted;
  final bool isSynced;
  const ModeloImagenDb({
    required this.uid,
    required this.modeloUid,
    required this.rutaRemota,
    required this.rutaLocal,
    required this.sha256,
    required this.isCover,
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
    map['sha256'] = Variable<String>(sha256);
    map['is_cover'] = Variable<bool>(isCover);
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
      sha256: Value(sha256),
      isCover: Value(isCover),
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
      sha256: serializer.fromJson<String>(json['sha256']),
      isCover: serializer.fromJson<bool>(json['isCover']),
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
      'sha256': serializer.toJson<String>(sha256),
      'isCover': serializer.toJson<bool>(isCover),
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
    String? sha256,
    bool? isCover,
    DateTime? updatedAt,
    bool? deleted,
    bool? isSynced,
  }) => ModeloImagenDb(
    uid: uid ?? this.uid,
    modeloUid: modeloUid ?? this.modeloUid,
    rutaRemota: rutaRemota ?? this.rutaRemota,
    rutaLocal: rutaLocal ?? this.rutaLocal,
    sha256: sha256 ?? this.sha256,
    isCover: isCover ?? this.isCover,
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
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      isCover: data.isCover.present ? data.isCover.value : this.isCover,
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
          ..write('sha256: $sha256, ')
          ..write('isCover: $isCover, ')
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
    sha256,
    isCover,
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
          other.sha256 == this.sha256 &&
          other.isCover == this.isCover &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.isSynced == this.isSynced);
}

class ModeloImagenesCompanion extends UpdateCompanion<ModeloImagenDb> {
  final Value<String> uid;
  final Value<String> modeloUid;
  final Value<String> rutaRemota;
  final Value<String> rutaLocal;
  final Value<String> sha256;
  final Value<bool> isCover;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const ModeloImagenesCompanion({
    this.uid = const Value.absent(),
    this.modeloUid = const Value.absent(),
    this.rutaRemota = const Value.absent(),
    this.rutaLocal = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.isCover = const Value.absent(),
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
    this.sha256 = const Value.absent(),
    this.isCover = const Value.absent(),
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
    Expression<String>? sha256,
    Expression<bool>? isCover,
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
      if (sha256 != null) 'sha256': sha256,
      if (isCover != null) 'is_cover': isCover,
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
    Value<String>? sha256,
    Value<bool>? isCover,
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
      sha256: sha256 ?? this.sha256,
      isCover: isCover ?? this.isCover,
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
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (isCover.present) {
      map['is_cover'] = Variable<bool>(isCover.value);
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
          ..write('sha256: $sha256, ')
          ..write('isCover: $isCover, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductosTable extends Productos
    with TableInfo<$ProductosTable, ProductoDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductosTable(this.attachedDatabase, [this._alias]);
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
    defaultValue: const Constant('Autofinanciamiento Puro'),
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
  static const VerificationMeta _plazoMesesMeta = const VerificationMeta(
    'plazoMeses',
  );
  @override
  late final GeneratedColumn<int> plazoMeses = GeneratedColumn<int>(
    'plazo_meses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _factorIntegranteMeta = const VerificationMeta(
    'factorIntegrante',
  );
  @override
  late final GeneratedColumn<double> factorIntegrante = GeneratedColumn<double>(
    'factor_integrante',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.01667),
  );
  static const VerificationMeta _factorPropietarioMeta = const VerificationMeta(
    'factorPropietario',
  );
  @override
  late final GeneratedColumn<double> factorPropietario =
      GeneratedColumn<double>(
        'factor_propietario',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0206),
      );
  static const VerificationMeta _cuotaInscripcionPctMeta =
      const VerificationMeta('cuotaInscripcionPct');
  @override
  late final GeneratedColumn<double> cuotaInscripcionPct =
      GeneratedColumn<double>(
        'cuota_inscripcion_pct',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.005),
      );
  static const VerificationMeta _cuotaAdministracionPctMeta =
      const VerificationMeta('cuotaAdministracionPct');
  @override
  late final GeneratedColumn<double> cuotaAdministracionPct =
      GeneratedColumn<double>(
        'cuota_administracion_pct',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.002),
      );
  static const VerificationMeta _ivaCuotaAdministracionPctMeta =
      const VerificationMeta('ivaCuotaAdministracionPct');
  @override
  late final GeneratedColumn<double> ivaCuotaAdministracionPct =
      GeneratedColumn<double>(
        'iva_cuota_administracion_pct',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.16),
      );
  static const VerificationMeta _cuotaSeguroVidaPctMeta =
      const VerificationMeta('cuotaSeguroVidaPct');
  @override
  late final GeneratedColumn<double> cuotaSeguroVidaPct =
      GeneratedColumn<double>(
        'cuota_seguro_vida_pct',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.00065),
      );
  static const VerificationMeta _adelantoMinMensMeta = const VerificationMeta(
    'adelantoMinMens',
  );
  @override
  late final GeneratedColumn<int> adelantoMinMens = GeneratedColumn<int>(
    'adelanto_min_mens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _adelantoMaxMensMeta = const VerificationMeta(
    'adelantoMaxMens',
  );
  @override
  late final GeneratedColumn<int> adelantoMaxMens = GeneratedColumn<int>(
    'adelanto_max_mens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(59),
  );
  static const VerificationMeta _mesEntregaMinMeta = const VerificationMeta(
    'mesEntregaMin',
  );
  @override
  late final GeneratedColumn<int> mesEntregaMin = GeneratedColumn<int>(
    'mes_entrega_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _mesEntregaMaxMeta = const VerificationMeta(
    'mesEntregaMax',
  );
  @override
  late final GeneratedColumn<int> mesEntregaMax = GeneratedColumn<int>(
    'mes_entrega_max',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _prioridadMeta = const VerificationMeta(
    'prioridad',
  );
  @override
  late final GeneratedColumn<int> prioridad = GeneratedColumn<int>(
    'prioridad',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _vigenteDesdeMeta = const VerificationMeta(
    'vigenteDesde',
  );
  @override
  late final GeneratedColumn<DateTime> vigenteDesde = GeneratedColumn<DateTime>(
    'vigente_desde',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vigenteHastaMeta = const VerificationMeta(
    'vigenteHasta',
  );
  @override
  late final GeneratedColumn<DateTime> vigenteHasta = GeneratedColumn<DateTime>(
    'vigente_hasta',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
    nombre,
    activo,
    plazoMeses,
    factorIntegrante,
    factorPropietario,
    cuotaInscripcionPct,
    cuotaAdministracionPct,
    ivaCuotaAdministracionPct,
    cuotaSeguroVidaPct,
    adelantoMinMens,
    adelantoMaxMens,
    mesEntregaMin,
    mesEntregaMax,
    prioridad,
    notas,
    vigenteDesde,
    vigenteHasta,
    createdAt,
    updatedAt,
    deleted,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'productos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductoDb> instance, {
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
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('plazo_meses')) {
      context.handle(
        _plazoMesesMeta,
        plazoMeses.isAcceptableOrUnknown(data['plazo_meses']!, _plazoMesesMeta),
      );
    }
    if (data.containsKey('factor_integrante')) {
      context.handle(
        _factorIntegranteMeta,
        factorIntegrante.isAcceptableOrUnknown(
          data['factor_integrante']!,
          _factorIntegranteMeta,
        ),
      );
    }
    if (data.containsKey('factor_propietario')) {
      context.handle(
        _factorPropietarioMeta,
        factorPropietario.isAcceptableOrUnknown(
          data['factor_propietario']!,
          _factorPropietarioMeta,
        ),
      );
    }
    if (data.containsKey('cuota_inscripcion_pct')) {
      context.handle(
        _cuotaInscripcionPctMeta,
        cuotaInscripcionPct.isAcceptableOrUnknown(
          data['cuota_inscripcion_pct']!,
          _cuotaInscripcionPctMeta,
        ),
      );
    }
    if (data.containsKey('cuota_administracion_pct')) {
      context.handle(
        _cuotaAdministracionPctMeta,
        cuotaAdministracionPct.isAcceptableOrUnknown(
          data['cuota_administracion_pct']!,
          _cuotaAdministracionPctMeta,
        ),
      );
    }
    if (data.containsKey('iva_cuota_administracion_pct')) {
      context.handle(
        _ivaCuotaAdministracionPctMeta,
        ivaCuotaAdministracionPct.isAcceptableOrUnknown(
          data['iva_cuota_administracion_pct']!,
          _ivaCuotaAdministracionPctMeta,
        ),
      );
    }
    if (data.containsKey('cuota_seguro_vida_pct')) {
      context.handle(
        _cuotaSeguroVidaPctMeta,
        cuotaSeguroVidaPct.isAcceptableOrUnknown(
          data['cuota_seguro_vida_pct']!,
          _cuotaSeguroVidaPctMeta,
        ),
      );
    }
    if (data.containsKey('adelanto_min_mens')) {
      context.handle(
        _adelantoMinMensMeta,
        adelantoMinMens.isAcceptableOrUnknown(
          data['adelanto_min_mens']!,
          _adelantoMinMensMeta,
        ),
      );
    }
    if (data.containsKey('adelanto_max_mens')) {
      context.handle(
        _adelantoMaxMensMeta,
        adelantoMaxMens.isAcceptableOrUnknown(
          data['adelanto_max_mens']!,
          _adelantoMaxMensMeta,
        ),
      );
    }
    if (data.containsKey('mes_entrega_min')) {
      context.handle(
        _mesEntregaMinMeta,
        mesEntregaMin.isAcceptableOrUnknown(
          data['mes_entrega_min']!,
          _mesEntregaMinMeta,
        ),
      );
    }
    if (data.containsKey('mes_entrega_max')) {
      context.handle(
        _mesEntregaMaxMeta,
        mesEntregaMax.isAcceptableOrUnknown(
          data['mes_entrega_max']!,
          _mesEntregaMaxMeta,
        ),
      );
    }
    if (data.containsKey('prioridad')) {
      context.handle(
        _prioridadMeta,
        prioridad.isAcceptableOrUnknown(data['prioridad']!, _prioridadMeta),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('vigente_desde')) {
      context.handle(
        _vigenteDesdeMeta,
        vigenteDesde.isAcceptableOrUnknown(
          data['vigente_desde']!,
          _vigenteDesdeMeta,
        ),
      );
    }
    if (data.containsKey('vigente_hasta')) {
      context.handle(
        _vigenteHastaMeta,
        vigenteHasta.isAcceptableOrUnknown(
          data['vigente_hasta']!,
          _vigenteHastaMeta,
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
  ProductoDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductoDb(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      plazoMeses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plazo_meses'],
      )!,
      factorIntegrante: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}factor_integrante'],
      )!,
      factorPropietario: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}factor_propietario'],
      )!,
      cuotaInscripcionPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cuota_inscripcion_pct'],
      )!,
      cuotaAdministracionPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cuota_administracion_pct'],
      )!,
      ivaCuotaAdministracionPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}iva_cuota_administracion_pct'],
      )!,
      cuotaSeguroVidaPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cuota_seguro_vida_pct'],
      )!,
      adelantoMinMens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}adelanto_min_mens'],
      )!,
      adelantoMaxMens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}adelanto_max_mens'],
      )!,
      mesEntregaMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mes_entrega_min'],
      )!,
      mesEntregaMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mes_entrega_max'],
      )!,
      prioridad: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prioridad'],
      )!,
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      )!,
      vigenteDesde: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}vigente_desde'],
      ),
      vigenteHasta: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}vigente_hasta'],
      ),
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
  $ProductosTable createAlias(String alias) {
    return $ProductosTable(attachedDatabase, alias);
  }
}

class ProductoDb extends DataClass implements Insertable<ProductoDb> {
  final String uid;
  final String nombre;
  final bool activo;
  final int plazoMeses;
  final double factorIntegrante;
  final double factorPropietario;
  final double cuotaInscripcionPct;
  final double cuotaAdministracionPct;
  final double ivaCuotaAdministracionPct;
  final double cuotaSeguroVidaPct;
  final int adelantoMinMens;
  final int adelantoMaxMens;
  final int mesEntregaMin;
  final int mesEntregaMax;
  final int prioridad;
  final String notas;
  final DateTime? vigenteDesde;
  final DateTime? vigenteHasta;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  final bool isSynced;
  const ProductoDb({
    required this.uid,
    required this.nombre,
    required this.activo,
    required this.plazoMeses,
    required this.factorIntegrante,
    required this.factorPropietario,
    required this.cuotaInscripcionPct,
    required this.cuotaAdministracionPct,
    required this.ivaCuotaAdministracionPct,
    required this.cuotaSeguroVidaPct,
    required this.adelantoMinMens,
    required this.adelantoMaxMens,
    required this.mesEntregaMin,
    required this.mesEntregaMax,
    required this.prioridad,
    required this.notas,
    this.vigenteDesde,
    this.vigenteHasta,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['nombre'] = Variable<String>(nombre);
    map['activo'] = Variable<bool>(activo);
    map['plazo_meses'] = Variable<int>(plazoMeses);
    map['factor_integrante'] = Variable<double>(factorIntegrante);
    map['factor_propietario'] = Variable<double>(factorPropietario);
    map['cuota_inscripcion_pct'] = Variable<double>(cuotaInscripcionPct);
    map['cuota_administracion_pct'] = Variable<double>(cuotaAdministracionPct);
    map['iva_cuota_administracion_pct'] = Variable<double>(
      ivaCuotaAdministracionPct,
    );
    map['cuota_seguro_vida_pct'] = Variable<double>(cuotaSeguroVidaPct);
    map['adelanto_min_mens'] = Variable<int>(adelantoMinMens);
    map['adelanto_max_mens'] = Variable<int>(adelantoMaxMens);
    map['mes_entrega_min'] = Variable<int>(mesEntregaMin);
    map['mes_entrega_max'] = Variable<int>(mesEntregaMax);
    map['prioridad'] = Variable<int>(prioridad);
    map['notas'] = Variable<String>(notas);
    if (!nullToAbsent || vigenteDesde != null) {
      map['vigente_desde'] = Variable<DateTime>(vigenteDesde);
    }
    if (!nullToAbsent || vigenteHasta != null) {
      map['vigente_hasta'] = Variable<DateTime>(vigenteHasta);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  ProductosCompanion toCompanion(bool nullToAbsent) {
    return ProductosCompanion(
      uid: Value(uid),
      nombre: Value(nombre),
      activo: Value(activo),
      plazoMeses: Value(plazoMeses),
      factorIntegrante: Value(factorIntegrante),
      factorPropietario: Value(factorPropietario),
      cuotaInscripcionPct: Value(cuotaInscripcionPct),
      cuotaAdministracionPct: Value(cuotaAdministracionPct),
      ivaCuotaAdministracionPct: Value(ivaCuotaAdministracionPct),
      cuotaSeguroVidaPct: Value(cuotaSeguroVidaPct),
      adelantoMinMens: Value(adelantoMinMens),
      adelantoMaxMens: Value(adelantoMaxMens),
      mesEntregaMin: Value(mesEntregaMin),
      mesEntregaMax: Value(mesEntregaMax),
      prioridad: Value(prioridad),
      notas: Value(notas),
      vigenteDesde: vigenteDesde == null && nullToAbsent
          ? const Value.absent()
          : Value(vigenteDesde),
      vigenteHasta: vigenteHasta == null && nullToAbsent
          ? const Value.absent()
          : Value(vigenteHasta),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      isSynced: Value(isSynced),
    );
  }

  factory ProductoDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductoDb(
      uid: serializer.fromJson<String>(json['uid']),
      nombre: serializer.fromJson<String>(json['nombre']),
      activo: serializer.fromJson<bool>(json['activo']),
      plazoMeses: serializer.fromJson<int>(json['plazoMeses']),
      factorIntegrante: serializer.fromJson<double>(json['factorIntegrante']),
      factorPropietario: serializer.fromJson<double>(json['factorPropietario']),
      cuotaInscripcionPct: serializer.fromJson<double>(
        json['cuotaInscripcionPct'],
      ),
      cuotaAdministracionPct: serializer.fromJson<double>(
        json['cuotaAdministracionPct'],
      ),
      ivaCuotaAdministracionPct: serializer.fromJson<double>(
        json['ivaCuotaAdministracionPct'],
      ),
      cuotaSeguroVidaPct: serializer.fromJson<double>(
        json['cuotaSeguroVidaPct'],
      ),
      adelantoMinMens: serializer.fromJson<int>(json['adelantoMinMens']),
      adelantoMaxMens: serializer.fromJson<int>(json['adelantoMaxMens']),
      mesEntregaMin: serializer.fromJson<int>(json['mesEntregaMin']),
      mesEntregaMax: serializer.fromJson<int>(json['mesEntregaMax']),
      prioridad: serializer.fromJson<int>(json['prioridad']),
      notas: serializer.fromJson<String>(json['notas']),
      vigenteDesde: serializer.fromJson<DateTime?>(json['vigenteDesde']),
      vigenteHasta: serializer.fromJson<DateTime?>(json['vigenteHasta']),
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
      'nombre': serializer.toJson<String>(nombre),
      'activo': serializer.toJson<bool>(activo),
      'plazoMeses': serializer.toJson<int>(plazoMeses),
      'factorIntegrante': serializer.toJson<double>(factorIntegrante),
      'factorPropietario': serializer.toJson<double>(factorPropietario),
      'cuotaInscripcionPct': serializer.toJson<double>(cuotaInscripcionPct),
      'cuotaAdministracionPct': serializer.toJson<double>(
        cuotaAdministracionPct,
      ),
      'ivaCuotaAdministracionPct': serializer.toJson<double>(
        ivaCuotaAdministracionPct,
      ),
      'cuotaSeguroVidaPct': serializer.toJson<double>(cuotaSeguroVidaPct),
      'adelantoMinMens': serializer.toJson<int>(adelantoMinMens),
      'adelantoMaxMens': serializer.toJson<int>(adelantoMaxMens),
      'mesEntregaMin': serializer.toJson<int>(mesEntregaMin),
      'mesEntregaMax': serializer.toJson<int>(mesEntregaMax),
      'prioridad': serializer.toJson<int>(prioridad),
      'notas': serializer.toJson<String>(notas),
      'vigenteDesde': serializer.toJson<DateTime?>(vigenteDesde),
      'vigenteHasta': serializer.toJson<DateTime?>(vigenteHasta),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  ProductoDb copyWith({
    String? uid,
    String? nombre,
    bool? activo,
    int? plazoMeses,
    double? factorIntegrante,
    double? factorPropietario,
    double? cuotaInscripcionPct,
    double? cuotaAdministracionPct,
    double? ivaCuotaAdministracionPct,
    double? cuotaSeguroVidaPct,
    int? adelantoMinMens,
    int? adelantoMaxMens,
    int? mesEntregaMin,
    int? mesEntregaMax,
    int? prioridad,
    String? notas,
    Value<DateTime?> vigenteDesde = const Value.absent(),
    Value<DateTime?> vigenteHasta = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
    bool? isSynced,
  }) => ProductoDb(
    uid: uid ?? this.uid,
    nombre: nombre ?? this.nombre,
    activo: activo ?? this.activo,
    plazoMeses: plazoMeses ?? this.plazoMeses,
    factorIntegrante: factorIntegrante ?? this.factorIntegrante,
    factorPropietario: factorPropietario ?? this.factorPropietario,
    cuotaInscripcionPct: cuotaInscripcionPct ?? this.cuotaInscripcionPct,
    cuotaAdministracionPct:
        cuotaAdministracionPct ?? this.cuotaAdministracionPct,
    ivaCuotaAdministracionPct:
        ivaCuotaAdministracionPct ?? this.ivaCuotaAdministracionPct,
    cuotaSeguroVidaPct: cuotaSeguroVidaPct ?? this.cuotaSeguroVidaPct,
    adelantoMinMens: adelantoMinMens ?? this.adelantoMinMens,
    adelantoMaxMens: adelantoMaxMens ?? this.adelantoMaxMens,
    mesEntregaMin: mesEntregaMin ?? this.mesEntregaMin,
    mesEntregaMax: mesEntregaMax ?? this.mesEntregaMax,
    prioridad: prioridad ?? this.prioridad,
    notas: notas ?? this.notas,
    vigenteDesde: vigenteDesde.present ? vigenteDesde.value : this.vigenteDesde,
    vigenteHasta: vigenteHasta.present ? vigenteHasta.value : this.vigenteHasta,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    isSynced: isSynced ?? this.isSynced,
  );
  ProductoDb copyWithCompanion(ProductosCompanion data) {
    return ProductoDb(
      uid: data.uid.present ? data.uid.value : this.uid,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      activo: data.activo.present ? data.activo.value : this.activo,
      plazoMeses: data.plazoMeses.present
          ? data.plazoMeses.value
          : this.plazoMeses,
      factorIntegrante: data.factorIntegrante.present
          ? data.factorIntegrante.value
          : this.factorIntegrante,
      factorPropietario: data.factorPropietario.present
          ? data.factorPropietario.value
          : this.factorPropietario,
      cuotaInscripcionPct: data.cuotaInscripcionPct.present
          ? data.cuotaInscripcionPct.value
          : this.cuotaInscripcionPct,
      cuotaAdministracionPct: data.cuotaAdministracionPct.present
          ? data.cuotaAdministracionPct.value
          : this.cuotaAdministracionPct,
      ivaCuotaAdministracionPct: data.ivaCuotaAdministracionPct.present
          ? data.ivaCuotaAdministracionPct.value
          : this.ivaCuotaAdministracionPct,
      cuotaSeguroVidaPct: data.cuotaSeguroVidaPct.present
          ? data.cuotaSeguroVidaPct.value
          : this.cuotaSeguroVidaPct,
      adelantoMinMens: data.adelantoMinMens.present
          ? data.adelantoMinMens.value
          : this.adelantoMinMens,
      adelantoMaxMens: data.adelantoMaxMens.present
          ? data.adelantoMaxMens.value
          : this.adelantoMaxMens,
      mesEntregaMin: data.mesEntregaMin.present
          ? data.mesEntregaMin.value
          : this.mesEntregaMin,
      mesEntregaMax: data.mesEntregaMax.present
          ? data.mesEntregaMax.value
          : this.mesEntregaMax,
      prioridad: data.prioridad.present ? data.prioridad.value : this.prioridad,
      notas: data.notas.present ? data.notas.value : this.notas,
      vigenteDesde: data.vigenteDesde.present
          ? data.vigenteDesde.value
          : this.vigenteDesde,
      vigenteHasta: data.vigenteHasta.present
          ? data.vigenteHasta.value
          : this.vigenteHasta,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductoDb(')
          ..write('uid: $uid, ')
          ..write('nombre: $nombre, ')
          ..write('activo: $activo, ')
          ..write('plazoMeses: $plazoMeses, ')
          ..write('factorIntegrante: $factorIntegrante, ')
          ..write('factorPropietario: $factorPropietario, ')
          ..write('cuotaInscripcionPct: $cuotaInscripcionPct, ')
          ..write('cuotaAdministracionPct: $cuotaAdministracionPct, ')
          ..write('ivaCuotaAdministracionPct: $ivaCuotaAdministracionPct, ')
          ..write('cuotaSeguroVidaPct: $cuotaSeguroVidaPct, ')
          ..write('adelantoMinMens: $adelantoMinMens, ')
          ..write('adelantoMaxMens: $adelantoMaxMens, ')
          ..write('mesEntregaMin: $mesEntregaMin, ')
          ..write('mesEntregaMax: $mesEntregaMax, ')
          ..write('prioridad: $prioridad, ')
          ..write('notas: $notas, ')
          ..write('vigenteDesde: $vigenteDesde, ')
          ..write('vigenteHasta: $vigenteHasta, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    uid,
    nombre,
    activo,
    plazoMeses,
    factorIntegrante,
    factorPropietario,
    cuotaInscripcionPct,
    cuotaAdministracionPct,
    ivaCuotaAdministracionPct,
    cuotaSeguroVidaPct,
    adelantoMinMens,
    adelantoMaxMens,
    mesEntregaMin,
    mesEntregaMax,
    prioridad,
    notas,
    vigenteDesde,
    vigenteHasta,
    createdAt,
    updatedAt,
    deleted,
    isSynced,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductoDb &&
          other.uid == this.uid &&
          other.nombre == this.nombre &&
          other.activo == this.activo &&
          other.plazoMeses == this.plazoMeses &&
          other.factorIntegrante == this.factorIntegrante &&
          other.factorPropietario == this.factorPropietario &&
          other.cuotaInscripcionPct == this.cuotaInscripcionPct &&
          other.cuotaAdministracionPct == this.cuotaAdministracionPct &&
          other.ivaCuotaAdministracionPct == this.ivaCuotaAdministracionPct &&
          other.cuotaSeguroVidaPct == this.cuotaSeguroVidaPct &&
          other.adelantoMinMens == this.adelantoMinMens &&
          other.adelantoMaxMens == this.adelantoMaxMens &&
          other.mesEntregaMin == this.mesEntregaMin &&
          other.mesEntregaMax == this.mesEntregaMax &&
          other.prioridad == this.prioridad &&
          other.notas == this.notas &&
          other.vigenteDesde == this.vigenteDesde &&
          other.vigenteHasta == this.vigenteHasta &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.isSynced == this.isSynced);
}

class ProductosCompanion extends UpdateCompanion<ProductoDb> {
  final Value<String> uid;
  final Value<String> nombre;
  final Value<bool> activo;
  final Value<int> plazoMeses;
  final Value<double> factorIntegrante;
  final Value<double> factorPropietario;
  final Value<double> cuotaInscripcionPct;
  final Value<double> cuotaAdministracionPct;
  final Value<double> ivaCuotaAdministracionPct;
  final Value<double> cuotaSeguroVidaPct;
  final Value<int> adelantoMinMens;
  final Value<int> adelantoMaxMens;
  final Value<int> mesEntregaMin;
  final Value<int> mesEntregaMax;
  final Value<int> prioridad;
  final Value<String> notas;
  final Value<DateTime?> vigenteDesde;
  final Value<DateTime?> vigenteHasta;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const ProductosCompanion({
    this.uid = const Value.absent(),
    this.nombre = const Value.absent(),
    this.activo = const Value.absent(),
    this.plazoMeses = const Value.absent(),
    this.factorIntegrante = const Value.absent(),
    this.factorPropietario = const Value.absent(),
    this.cuotaInscripcionPct = const Value.absent(),
    this.cuotaAdministracionPct = const Value.absent(),
    this.ivaCuotaAdministracionPct = const Value.absent(),
    this.cuotaSeguroVidaPct = const Value.absent(),
    this.adelantoMinMens = const Value.absent(),
    this.adelantoMaxMens = const Value.absent(),
    this.mesEntregaMin = const Value.absent(),
    this.mesEntregaMax = const Value.absent(),
    this.prioridad = const Value.absent(),
    this.notas = const Value.absent(),
    this.vigenteDesde = const Value.absent(),
    this.vigenteHasta = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductosCompanion.insert({
    required String uid,
    this.nombre = const Value.absent(),
    this.activo = const Value.absent(),
    this.plazoMeses = const Value.absent(),
    this.factorIntegrante = const Value.absent(),
    this.factorPropietario = const Value.absent(),
    this.cuotaInscripcionPct = const Value.absent(),
    this.cuotaAdministracionPct = const Value.absent(),
    this.ivaCuotaAdministracionPct = const Value.absent(),
    this.cuotaSeguroVidaPct = const Value.absent(),
    this.adelantoMinMens = const Value.absent(),
    this.adelantoMaxMens = const Value.absent(),
    this.mesEntregaMin = const Value.absent(),
    this.mesEntregaMax = const Value.absent(),
    this.prioridad = const Value.absent(),
    this.notas = const Value.absent(),
    this.vigenteDesde = const Value.absent(),
    this.vigenteHasta = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid);
  static Insertable<ProductoDb> custom({
    Expression<String>? uid,
    Expression<String>? nombre,
    Expression<bool>? activo,
    Expression<int>? plazoMeses,
    Expression<double>? factorIntegrante,
    Expression<double>? factorPropietario,
    Expression<double>? cuotaInscripcionPct,
    Expression<double>? cuotaAdministracionPct,
    Expression<double>? ivaCuotaAdministracionPct,
    Expression<double>? cuotaSeguroVidaPct,
    Expression<int>? adelantoMinMens,
    Expression<int>? adelantoMaxMens,
    Expression<int>? mesEntregaMin,
    Expression<int>? mesEntregaMax,
    Expression<int>? prioridad,
    Expression<String>? notas,
    Expression<DateTime>? vigenteDesde,
    Expression<DateTime>? vigenteHasta,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (nombre != null) 'nombre': nombre,
      if (activo != null) 'activo': activo,
      if (plazoMeses != null) 'plazo_meses': plazoMeses,
      if (factorIntegrante != null) 'factor_integrante': factorIntegrante,
      if (factorPropietario != null) 'factor_propietario': factorPropietario,
      if (cuotaInscripcionPct != null)
        'cuota_inscripcion_pct': cuotaInscripcionPct,
      if (cuotaAdministracionPct != null)
        'cuota_administracion_pct': cuotaAdministracionPct,
      if (ivaCuotaAdministracionPct != null)
        'iva_cuota_administracion_pct': ivaCuotaAdministracionPct,
      if (cuotaSeguroVidaPct != null)
        'cuota_seguro_vida_pct': cuotaSeguroVidaPct,
      if (adelantoMinMens != null) 'adelanto_min_mens': adelantoMinMens,
      if (adelantoMaxMens != null) 'adelanto_max_mens': adelantoMaxMens,
      if (mesEntregaMin != null) 'mes_entrega_min': mesEntregaMin,
      if (mesEntregaMax != null) 'mes_entrega_max': mesEntregaMax,
      if (prioridad != null) 'prioridad': prioridad,
      if (notas != null) 'notas': notas,
      if (vigenteDesde != null) 'vigente_desde': vigenteDesde,
      if (vigenteHasta != null) 'vigente_hasta': vigenteHasta,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductosCompanion copyWith({
    Value<String>? uid,
    Value<String>? nombre,
    Value<bool>? activo,
    Value<int>? plazoMeses,
    Value<double>? factorIntegrante,
    Value<double>? factorPropietario,
    Value<double>? cuotaInscripcionPct,
    Value<double>? cuotaAdministracionPct,
    Value<double>? ivaCuotaAdministracionPct,
    Value<double>? cuotaSeguroVidaPct,
    Value<int>? adelantoMinMens,
    Value<int>? adelantoMaxMens,
    Value<int>? mesEntregaMin,
    Value<int>? mesEntregaMax,
    Value<int>? prioridad,
    Value<String>? notas,
    Value<DateTime?>? vigenteDesde,
    Value<DateTime?>? vigenteHasta,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return ProductosCompanion(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      activo: activo ?? this.activo,
      plazoMeses: plazoMeses ?? this.plazoMeses,
      factorIntegrante: factorIntegrante ?? this.factorIntegrante,
      factorPropietario: factorPropietario ?? this.factorPropietario,
      cuotaInscripcionPct: cuotaInscripcionPct ?? this.cuotaInscripcionPct,
      cuotaAdministracionPct:
          cuotaAdministracionPct ?? this.cuotaAdministracionPct,
      ivaCuotaAdministracionPct:
          ivaCuotaAdministracionPct ?? this.ivaCuotaAdministracionPct,
      cuotaSeguroVidaPct: cuotaSeguroVidaPct ?? this.cuotaSeguroVidaPct,
      adelantoMinMens: adelantoMinMens ?? this.adelantoMinMens,
      adelantoMaxMens: adelantoMaxMens ?? this.adelantoMaxMens,
      mesEntregaMin: mesEntregaMin ?? this.mesEntregaMin,
      mesEntregaMax: mesEntregaMax ?? this.mesEntregaMax,
      prioridad: prioridad ?? this.prioridad,
      notas: notas ?? this.notas,
      vigenteDesde: vigenteDesde ?? this.vigenteDesde,
      vigenteHasta: vigenteHasta ?? this.vigenteHasta,
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
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (plazoMeses.present) {
      map['plazo_meses'] = Variable<int>(plazoMeses.value);
    }
    if (factorIntegrante.present) {
      map['factor_integrante'] = Variable<double>(factorIntegrante.value);
    }
    if (factorPropietario.present) {
      map['factor_propietario'] = Variable<double>(factorPropietario.value);
    }
    if (cuotaInscripcionPct.present) {
      map['cuota_inscripcion_pct'] = Variable<double>(
        cuotaInscripcionPct.value,
      );
    }
    if (cuotaAdministracionPct.present) {
      map['cuota_administracion_pct'] = Variable<double>(
        cuotaAdministracionPct.value,
      );
    }
    if (ivaCuotaAdministracionPct.present) {
      map['iva_cuota_administracion_pct'] = Variable<double>(
        ivaCuotaAdministracionPct.value,
      );
    }
    if (cuotaSeguroVidaPct.present) {
      map['cuota_seguro_vida_pct'] = Variable<double>(cuotaSeguroVidaPct.value);
    }
    if (adelantoMinMens.present) {
      map['adelanto_min_mens'] = Variable<int>(adelantoMinMens.value);
    }
    if (adelantoMaxMens.present) {
      map['adelanto_max_mens'] = Variable<int>(adelantoMaxMens.value);
    }
    if (mesEntregaMin.present) {
      map['mes_entrega_min'] = Variable<int>(mesEntregaMin.value);
    }
    if (mesEntregaMax.present) {
      map['mes_entrega_max'] = Variable<int>(mesEntregaMax.value);
    }
    if (prioridad.present) {
      map['prioridad'] = Variable<int>(prioridad.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (vigenteDesde.present) {
      map['vigente_desde'] = Variable<DateTime>(vigenteDesde.value);
    }
    if (vigenteHasta.present) {
      map['vigente_hasta'] = Variable<DateTime>(vigenteHasta.value);
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
    return (StringBuffer('ProductosCompanion(')
          ..write('uid: $uid, ')
          ..write('nombre: $nombre, ')
          ..write('activo: $activo, ')
          ..write('plazoMeses: $plazoMeses, ')
          ..write('factorIntegrante: $factorIntegrante, ')
          ..write('factorPropietario: $factorPropietario, ')
          ..write('cuotaInscripcionPct: $cuotaInscripcionPct, ')
          ..write('cuotaAdministracionPct: $cuotaAdministracionPct, ')
          ..write('ivaCuotaAdministracionPct: $ivaCuotaAdministracionPct, ')
          ..write('cuotaSeguroVidaPct: $cuotaSeguroVidaPct, ')
          ..write('adelantoMinMens: $adelantoMinMens, ')
          ..write('adelantoMaxMens: $adelantoMaxMens, ')
          ..write('mesEntregaMin: $mesEntregaMin, ')
          ..write('mesEntregaMax: $mesEntregaMax, ')
          ..write('prioridad: $prioridad, ')
          ..write('notas: $notas, ')
          ..write('vigenteDesde: $vigenteDesde, ')
          ..write('vigenteHasta: $vigenteHasta, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ColaboradoresTable extends Colaboradores
    with TableInfo<$ColaboradoresTable, ColaboradorDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ColaboradoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombresMeta = const VerificationMeta(
    'nombres',
  );
  @override
  late final GeneratedColumn<String> nombres = GeneratedColumn<String>(
    'nombres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apellidoPaternoMeta = const VerificationMeta(
    'apellidoPaterno',
  );
  @override
  late final GeneratedColumn<String> apellidoPaterno = GeneratedColumn<String>(
    'apellido_paterno',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _apellidoMaternoMeta = const VerificationMeta(
    'apellidoMaterno',
  );
  @override
  late final GeneratedColumn<String> apellidoMaterno = GeneratedColumn<String>(
    'apellido_materno',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fechaNacimientoMeta = const VerificationMeta(
    'fechaNacimiento',
  );
  @override
  late final GeneratedColumn<DateTime> fechaNacimiento =
      GeneratedColumn<DateTime>(
        'fecha_nacimiento',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _curpMeta = const VerificationMeta('curp');
  @override
  late final GeneratedColumn<String> curp = GeneratedColumn<String>(
    'curp',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rfcMeta = const VerificationMeta('rfc');
  @override
  late final GeneratedColumn<String> rfc = GeneratedColumn<String>(
    'rfc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telefonoMovilMeta = const VerificationMeta(
    'telefonoMovil',
  );
  @override
  late final GeneratedColumn<String> telefonoMovil = GeneratedColumn<String>(
    'telefono_movil',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailPersonalMeta = const VerificationMeta(
    'emailPersonal',
  );
  @override
  late final GeneratedColumn<String> emailPersonal = GeneratedColumn<String>(
    'email_personal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fotoRutaLocalMeta = const VerificationMeta(
    'fotoRutaLocal',
  );
  @override
  late final GeneratedColumn<String> fotoRutaLocal = GeneratedColumn<String>(
    'foto_ruta_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fotoRutaRemotaMeta = const VerificationMeta(
    'fotoRutaRemota',
  );
  @override
  late final GeneratedColumn<String> fotoRutaRemota = GeneratedColumn<String>(
    'foto_ruta_remota',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _generoMeta = const VerificationMeta('genero');
  @override
  late final GeneratedColumn<String> genero = GeneratedColumn<String>(
    'genero',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
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
    nombres,
    apellidoPaterno,
    apellidoMaterno,
    fechaNacimiento,
    curp,
    rfc,
    telefonoMovil,
    emailPersonal,
    fotoRutaLocal,
    fotoRutaRemota,
    genero,
    notas,
    createdAt,
    updatedAt,
    deleted,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'colaboradores';
  @override
  VerificationContext validateIntegrity(
    Insertable<ColaboradorDb> instance, {
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
    if (data.containsKey('nombres')) {
      context.handle(
        _nombresMeta,
        nombres.isAcceptableOrUnknown(data['nombres']!, _nombresMeta),
      );
    } else if (isInserting) {
      context.missing(_nombresMeta);
    }
    if (data.containsKey('apellido_paterno')) {
      context.handle(
        _apellidoPaternoMeta,
        apellidoPaterno.isAcceptableOrUnknown(
          data['apellido_paterno']!,
          _apellidoPaternoMeta,
        ),
      );
    }
    if (data.containsKey('apellido_materno')) {
      context.handle(
        _apellidoMaternoMeta,
        apellidoMaterno.isAcceptableOrUnknown(
          data['apellido_materno']!,
          _apellidoMaternoMeta,
        ),
      );
    }
    if (data.containsKey('fecha_nacimiento')) {
      context.handle(
        _fechaNacimientoMeta,
        fechaNacimiento.isAcceptableOrUnknown(
          data['fecha_nacimiento']!,
          _fechaNacimientoMeta,
        ),
      );
    }
    if (data.containsKey('curp')) {
      context.handle(
        _curpMeta,
        curp.isAcceptableOrUnknown(data['curp']!, _curpMeta),
      );
    }
    if (data.containsKey('rfc')) {
      context.handle(
        _rfcMeta,
        rfc.isAcceptableOrUnknown(data['rfc']!, _rfcMeta),
      );
    }
    if (data.containsKey('telefono_movil')) {
      context.handle(
        _telefonoMovilMeta,
        telefonoMovil.isAcceptableOrUnknown(
          data['telefono_movil']!,
          _telefonoMovilMeta,
        ),
      );
    }
    if (data.containsKey('email_personal')) {
      context.handle(
        _emailPersonalMeta,
        emailPersonal.isAcceptableOrUnknown(
          data['email_personal']!,
          _emailPersonalMeta,
        ),
      );
    }
    if (data.containsKey('foto_ruta_local')) {
      context.handle(
        _fotoRutaLocalMeta,
        fotoRutaLocal.isAcceptableOrUnknown(
          data['foto_ruta_local']!,
          _fotoRutaLocalMeta,
        ),
      );
    }
    if (data.containsKey('foto_ruta_remota')) {
      context.handle(
        _fotoRutaRemotaMeta,
        fotoRutaRemota.isAcceptableOrUnknown(
          data['foto_ruta_remota']!,
          _fotoRutaRemotaMeta,
        ),
      );
    }
    if (data.containsKey('genero')) {
      context.handle(
        _generoMeta,
        genero.isAcceptableOrUnknown(data['genero']!, _generoMeta),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
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
  ColaboradorDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ColaboradorDb(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      nombres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombres'],
      )!,
      apellidoPaterno: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apellido_paterno'],
      )!,
      apellidoMaterno: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apellido_materno'],
      )!,
      fechaNacimiento: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_nacimiento'],
      ),
      curp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}curp'],
      ),
      rfc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rfc'],
      ),
      telefonoMovil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono_movil'],
      )!,
      emailPersonal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email_personal'],
      )!,
      fotoRutaLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_ruta_local'],
      )!,
      fotoRutaRemota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_ruta_remota'],
      )!,
      genero: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genero'],
      ),
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
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
  $ColaboradoresTable createAlias(String alias) {
    return $ColaboradoresTable(attachedDatabase, alias);
  }
}

class ColaboradorDb extends DataClass implements Insertable<ColaboradorDb> {
  final String uid;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final DateTime? fechaNacimiento;
  final String? curp;
  final String? rfc;
  final String telefonoMovil;
  final String emailPersonal;
  final String fotoRutaLocal;
  final String fotoRutaRemota;
  final String? genero;
  final String notas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  final bool isSynced;
  const ColaboradorDb({
    required this.uid,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    this.fechaNacimiento,
    this.curp,
    this.rfc,
    required this.telefonoMovil,
    required this.emailPersonal,
    required this.fotoRutaLocal,
    required this.fotoRutaRemota,
    this.genero,
    required this.notas,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['nombres'] = Variable<String>(nombres);
    map['apellido_paterno'] = Variable<String>(apellidoPaterno);
    map['apellido_materno'] = Variable<String>(apellidoMaterno);
    if (!nullToAbsent || fechaNacimiento != null) {
      map['fecha_nacimiento'] = Variable<DateTime>(fechaNacimiento);
    }
    if (!nullToAbsent || curp != null) {
      map['curp'] = Variable<String>(curp);
    }
    if (!nullToAbsent || rfc != null) {
      map['rfc'] = Variable<String>(rfc);
    }
    map['telefono_movil'] = Variable<String>(telefonoMovil);
    map['email_personal'] = Variable<String>(emailPersonal);
    map['foto_ruta_local'] = Variable<String>(fotoRutaLocal);
    map['foto_ruta_remota'] = Variable<String>(fotoRutaRemota);
    if (!nullToAbsent || genero != null) {
      map['genero'] = Variable<String>(genero);
    }
    map['notas'] = Variable<String>(notas);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  ColaboradoresCompanion toCompanion(bool nullToAbsent) {
    return ColaboradoresCompanion(
      uid: Value(uid),
      nombres: Value(nombres),
      apellidoPaterno: Value(apellidoPaterno),
      apellidoMaterno: Value(apellidoMaterno),
      fechaNacimiento: fechaNacimiento == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaNacimiento),
      curp: curp == null && nullToAbsent ? const Value.absent() : Value(curp),
      rfc: rfc == null && nullToAbsent ? const Value.absent() : Value(rfc),
      telefonoMovil: Value(telefonoMovil),
      emailPersonal: Value(emailPersonal),
      fotoRutaLocal: Value(fotoRutaLocal),
      fotoRutaRemota: Value(fotoRutaRemota),
      genero: genero == null && nullToAbsent
          ? const Value.absent()
          : Value(genero),
      notas: Value(notas),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      isSynced: Value(isSynced),
    );
  }

  factory ColaboradorDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ColaboradorDb(
      uid: serializer.fromJson<String>(json['uid']),
      nombres: serializer.fromJson<String>(json['nombres']),
      apellidoPaterno: serializer.fromJson<String>(json['apellidoPaterno']),
      apellidoMaterno: serializer.fromJson<String>(json['apellidoMaterno']),
      fechaNacimiento: serializer.fromJson<DateTime?>(json['fechaNacimiento']),
      curp: serializer.fromJson<String?>(json['curp']),
      rfc: serializer.fromJson<String?>(json['rfc']),
      telefonoMovil: serializer.fromJson<String>(json['telefonoMovil']),
      emailPersonal: serializer.fromJson<String>(json['emailPersonal']),
      fotoRutaLocal: serializer.fromJson<String>(json['fotoRutaLocal']),
      fotoRutaRemota: serializer.fromJson<String>(json['fotoRutaRemota']),
      genero: serializer.fromJson<String?>(json['genero']),
      notas: serializer.fromJson<String>(json['notas']),
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
      'nombres': serializer.toJson<String>(nombres),
      'apellidoPaterno': serializer.toJson<String>(apellidoPaterno),
      'apellidoMaterno': serializer.toJson<String>(apellidoMaterno),
      'fechaNacimiento': serializer.toJson<DateTime?>(fechaNacimiento),
      'curp': serializer.toJson<String?>(curp),
      'rfc': serializer.toJson<String?>(rfc),
      'telefonoMovil': serializer.toJson<String>(telefonoMovil),
      'emailPersonal': serializer.toJson<String>(emailPersonal),
      'fotoRutaLocal': serializer.toJson<String>(fotoRutaLocal),
      'fotoRutaRemota': serializer.toJson<String>(fotoRutaRemota),
      'genero': serializer.toJson<String?>(genero),
      'notas': serializer.toJson<String>(notas),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  ColaboradorDb copyWith({
    String? uid,
    String? nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
    Value<DateTime?> fechaNacimiento = const Value.absent(),
    Value<String?> curp = const Value.absent(),
    Value<String?> rfc = const Value.absent(),
    String? telefonoMovil,
    String? emailPersonal,
    String? fotoRutaLocal,
    String? fotoRutaRemota,
    Value<String?> genero = const Value.absent(),
    String? notas,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
    bool? isSynced,
  }) => ColaboradorDb(
    uid: uid ?? this.uid,
    nombres: nombres ?? this.nombres,
    apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
    apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
    fechaNacimiento: fechaNacimiento.present
        ? fechaNacimiento.value
        : this.fechaNacimiento,
    curp: curp.present ? curp.value : this.curp,
    rfc: rfc.present ? rfc.value : this.rfc,
    telefonoMovil: telefonoMovil ?? this.telefonoMovil,
    emailPersonal: emailPersonal ?? this.emailPersonal,
    fotoRutaLocal: fotoRutaLocal ?? this.fotoRutaLocal,
    fotoRutaRemota: fotoRutaRemota ?? this.fotoRutaRemota,
    genero: genero.present ? genero.value : this.genero,
    notas: notas ?? this.notas,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    isSynced: isSynced ?? this.isSynced,
  );
  ColaboradorDb copyWithCompanion(ColaboradoresCompanion data) {
    return ColaboradorDb(
      uid: data.uid.present ? data.uid.value : this.uid,
      nombres: data.nombres.present ? data.nombres.value : this.nombres,
      apellidoPaterno: data.apellidoPaterno.present
          ? data.apellidoPaterno.value
          : this.apellidoPaterno,
      apellidoMaterno: data.apellidoMaterno.present
          ? data.apellidoMaterno.value
          : this.apellidoMaterno,
      fechaNacimiento: data.fechaNacimiento.present
          ? data.fechaNacimiento.value
          : this.fechaNacimiento,
      curp: data.curp.present ? data.curp.value : this.curp,
      rfc: data.rfc.present ? data.rfc.value : this.rfc,
      telefonoMovil: data.telefonoMovil.present
          ? data.telefonoMovil.value
          : this.telefonoMovil,
      emailPersonal: data.emailPersonal.present
          ? data.emailPersonal.value
          : this.emailPersonal,
      fotoRutaLocal: data.fotoRutaLocal.present
          ? data.fotoRutaLocal.value
          : this.fotoRutaLocal,
      fotoRutaRemota: data.fotoRutaRemota.present
          ? data.fotoRutaRemota.value
          : this.fotoRutaRemota,
      genero: data.genero.present ? data.genero.value : this.genero,
      notas: data.notas.present ? data.notas.value : this.notas,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ColaboradorDb(')
          ..write('uid: $uid, ')
          ..write('nombres: $nombres, ')
          ..write('apellidoPaterno: $apellidoPaterno, ')
          ..write('apellidoMaterno: $apellidoMaterno, ')
          ..write('fechaNacimiento: $fechaNacimiento, ')
          ..write('curp: $curp, ')
          ..write('rfc: $rfc, ')
          ..write('telefonoMovil: $telefonoMovil, ')
          ..write('emailPersonal: $emailPersonal, ')
          ..write('fotoRutaLocal: $fotoRutaLocal, ')
          ..write('fotoRutaRemota: $fotoRutaRemota, ')
          ..write('genero: $genero, ')
          ..write('notas: $notas, ')
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
    nombres,
    apellidoPaterno,
    apellidoMaterno,
    fechaNacimiento,
    curp,
    rfc,
    telefonoMovil,
    emailPersonal,
    fotoRutaLocal,
    fotoRutaRemota,
    genero,
    notas,
    createdAt,
    updatedAt,
    deleted,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ColaboradorDb &&
          other.uid == this.uid &&
          other.nombres == this.nombres &&
          other.apellidoPaterno == this.apellidoPaterno &&
          other.apellidoMaterno == this.apellidoMaterno &&
          other.fechaNacimiento == this.fechaNacimiento &&
          other.curp == this.curp &&
          other.rfc == this.rfc &&
          other.telefonoMovil == this.telefonoMovil &&
          other.emailPersonal == this.emailPersonal &&
          other.fotoRutaLocal == this.fotoRutaLocal &&
          other.fotoRutaRemota == this.fotoRutaRemota &&
          other.genero == this.genero &&
          other.notas == this.notas &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.isSynced == this.isSynced);
}

class ColaboradoresCompanion extends UpdateCompanion<ColaboradorDb> {
  final Value<String> uid;
  final Value<String> nombres;
  final Value<String> apellidoPaterno;
  final Value<String> apellidoMaterno;
  final Value<DateTime?> fechaNacimiento;
  final Value<String?> curp;
  final Value<String?> rfc;
  final Value<String> telefonoMovil;
  final Value<String> emailPersonal;
  final Value<String> fotoRutaLocal;
  final Value<String> fotoRutaRemota;
  final Value<String?> genero;
  final Value<String> notas;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const ColaboradoresCompanion({
    this.uid = const Value.absent(),
    this.nombres = const Value.absent(),
    this.apellidoPaterno = const Value.absent(),
    this.apellidoMaterno = const Value.absent(),
    this.fechaNacimiento = const Value.absent(),
    this.curp = const Value.absent(),
    this.rfc = const Value.absent(),
    this.telefonoMovil = const Value.absent(),
    this.emailPersonal = const Value.absent(),
    this.fotoRutaLocal = const Value.absent(),
    this.fotoRutaRemota = const Value.absent(),
    this.genero = const Value.absent(),
    this.notas = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ColaboradoresCompanion.insert({
    required String uid,
    required String nombres,
    this.apellidoPaterno = const Value.absent(),
    this.apellidoMaterno = const Value.absent(),
    this.fechaNacimiento = const Value.absent(),
    this.curp = const Value.absent(),
    this.rfc = const Value.absent(),
    this.telefonoMovil = const Value.absent(),
    this.emailPersonal = const Value.absent(),
    this.fotoRutaLocal = const Value.absent(),
    this.fotoRutaRemota = const Value.absent(),
    this.genero = const Value.absent(),
    this.notas = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       nombres = Value(nombres);
  static Insertable<ColaboradorDb> custom({
    Expression<String>? uid,
    Expression<String>? nombres,
    Expression<String>? apellidoPaterno,
    Expression<String>? apellidoMaterno,
    Expression<DateTime>? fechaNacimiento,
    Expression<String>? curp,
    Expression<String>? rfc,
    Expression<String>? telefonoMovil,
    Expression<String>? emailPersonal,
    Expression<String>? fotoRutaLocal,
    Expression<String>? fotoRutaRemota,
    Expression<String>? genero,
    Expression<String>? notas,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (nombres != null) 'nombres': nombres,
      if (apellidoPaterno != null) 'apellido_paterno': apellidoPaterno,
      if (apellidoMaterno != null) 'apellido_materno': apellidoMaterno,
      if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento,
      if (curp != null) 'curp': curp,
      if (rfc != null) 'rfc': rfc,
      if (telefonoMovil != null) 'telefono_movil': telefonoMovil,
      if (emailPersonal != null) 'email_personal': emailPersonal,
      if (fotoRutaLocal != null) 'foto_ruta_local': fotoRutaLocal,
      if (fotoRutaRemota != null) 'foto_ruta_remota': fotoRutaRemota,
      if (genero != null) 'genero': genero,
      if (notas != null) 'notas': notas,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ColaboradoresCompanion copyWith({
    Value<String>? uid,
    Value<String>? nombres,
    Value<String>? apellidoPaterno,
    Value<String>? apellidoMaterno,
    Value<DateTime?>? fechaNacimiento,
    Value<String?>? curp,
    Value<String?>? rfc,
    Value<String>? telefonoMovil,
    Value<String>? emailPersonal,
    Value<String>? fotoRutaLocal,
    Value<String>? fotoRutaRemota,
    Value<String?>? genero,
    Value<String>? notas,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return ColaboradoresCompanion(
      uid: uid ?? this.uid,
      nombres: nombres ?? this.nombres,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      curp: curp ?? this.curp,
      rfc: rfc ?? this.rfc,
      telefonoMovil: telefonoMovil ?? this.telefonoMovil,
      emailPersonal: emailPersonal ?? this.emailPersonal,
      fotoRutaLocal: fotoRutaLocal ?? this.fotoRutaLocal,
      fotoRutaRemota: fotoRutaRemota ?? this.fotoRutaRemota,
      genero: genero ?? this.genero,
      notas: notas ?? this.notas,
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
    if (nombres.present) {
      map['nombres'] = Variable<String>(nombres.value);
    }
    if (apellidoPaterno.present) {
      map['apellido_paterno'] = Variable<String>(apellidoPaterno.value);
    }
    if (apellidoMaterno.present) {
      map['apellido_materno'] = Variable<String>(apellidoMaterno.value);
    }
    if (fechaNacimiento.present) {
      map['fecha_nacimiento'] = Variable<DateTime>(fechaNacimiento.value);
    }
    if (curp.present) {
      map['curp'] = Variable<String>(curp.value);
    }
    if (rfc.present) {
      map['rfc'] = Variable<String>(rfc.value);
    }
    if (telefonoMovil.present) {
      map['telefono_movil'] = Variable<String>(telefonoMovil.value);
    }
    if (emailPersonal.present) {
      map['email_personal'] = Variable<String>(emailPersonal.value);
    }
    if (fotoRutaLocal.present) {
      map['foto_ruta_local'] = Variable<String>(fotoRutaLocal.value);
    }
    if (fotoRutaRemota.present) {
      map['foto_ruta_remota'] = Variable<String>(fotoRutaRemota.value);
    }
    if (genero.present) {
      map['genero'] = Variable<String>(genero.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
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
    return (StringBuffer('ColaboradoresCompanion(')
          ..write('uid: $uid, ')
          ..write('nombres: $nombres, ')
          ..write('apellidoPaterno: $apellidoPaterno, ')
          ..write('apellidoMaterno: $apellidoMaterno, ')
          ..write('fechaNacimiento: $fechaNacimiento, ')
          ..write('curp: $curp, ')
          ..write('rfc: $rfc, ')
          ..write('telefonoMovil: $telefonoMovil, ')
          ..write('emailPersonal: $emailPersonal, ')
          ..write('fotoRutaLocal: $fotoRutaLocal, ')
          ..write('fotoRutaRemota: $fotoRutaRemota, ')
          ..write('genero: $genero, ')
          ..write('notas: $notas, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AsignacionesLaboralesTable extends AsignacionesLaborales
    with TableInfo<$AsignacionesLaboralesTable, AsignacionLaboralDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AsignacionesLaboralesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colaboradorUidMeta = const VerificationMeta(
    'colaboradorUid',
  );
  @override
  late final GeneratedColumn<String> colaboradorUid = GeneratedColumn<String>(
    'colaborador_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distribuidorUidMeta = const VerificationMeta(
    'distribuidorUid',
  );
  @override
  late final GeneratedColumn<String> distribuidorUid = GeneratedColumn<String>(
    'distribuidor_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _managerColaboradorUidMeta =
      const VerificationMeta('managerColaboradorUid');
  @override
  late final GeneratedColumn<String> managerColaboradorUid =
      GeneratedColumn<String>(
        'manager_colaborador_uid',
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
    defaultValue: const Constant('vendedor'),
  );
  static const VerificationMeta _puestoMeta = const VerificationMeta('puesto');
  @override
  late final GeneratedColumn<String> puesto = GeneratedColumn<String>(
    'puesto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nivelMeta = const VerificationMeta('nivel');
  @override
  late final GeneratedColumn<String> nivel = GeneratedColumn<String>(
    'nivel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fechaInicioMeta = const VerificationMeta(
    'fechaInicio',
  );
  @override
  late final GeneratedColumn<DateTime> fechaInicio = GeneratedColumn<DateTime>(
    'fecha_inicio',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaFinMeta = const VerificationMeta(
    'fechaFin',
  );
  @override
  late final GeneratedColumn<DateTime> fechaFin = GeneratedColumn<DateTime>(
    'fecha_fin',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByUsuarioUidMeta =
      const VerificationMeta('createdByUsuarioUid');
  @override
  late final GeneratedColumn<String> createdByUsuarioUid =
      GeneratedColumn<String>(
        'created_by_usuario_uid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _closedByUsuarioUidMeta =
      const VerificationMeta('closedByUsuarioUid');
  @override
  late final GeneratedColumn<String> closedByUsuarioUid =
      GeneratedColumn<String>(
        'closed_by_usuario_uid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
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
    colaboradorUid,
    distribuidorUid,
    managerColaboradorUid,
    rol,
    puesto,
    nivel,
    fechaInicio,
    fechaFin,
    createdByUsuarioUid,
    closedByUsuarioUid,
    notas,
    createdAt,
    updatedAt,
    deleted,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asignaciones_laborales';
  @override
  VerificationContext validateIntegrity(
    Insertable<AsignacionLaboralDb> instance, {
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
    if (data.containsKey('colaborador_uid')) {
      context.handle(
        _colaboradorUidMeta,
        colaboradorUid.isAcceptableOrUnknown(
          data['colaborador_uid']!,
          _colaboradorUidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_colaboradorUidMeta);
    }
    if (data.containsKey('distribuidor_uid')) {
      context.handle(
        _distribuidorUidMeta,
        distribuidorUid.isAcceptableOrUnknown(
          data['distribuidor_uid']!,
          _distribuidorUidMeta,
        ),
      );
    }
    if (data.containsKey('manager_colaborador_uid')) {
      context.handle(
        _managerColaboradorUidMeta,
        managerColaboradorUid.isAcceptableOrUnknown(
          data['manager_colaborador_uid']!,
          _managerColaboradorUidMeta,
        ),
      );
    }
    if (data.containsKey('rol')) {
      context.handle(
        _rolMeta,
        rol.isAcceptableOrUnknown(data['rol']!, _rolMeta),
      );
    }
    if (data.containsKey('puesto')) {
      context.handle(
        _puestoMeta,
        puesto.isAcceptableOrUnknown(data['puesto']!, _puestoMeta),
      );
    }
    if (data.containsKey('nivel')) {
      context.handle(
        _nivelMeta,
        nivel.isAcceptableOrUnknown(data['nivel']!, _nivelMeta),
      );
    }
    if (data.containsKey('fecha_inicio')) {
      context.handle(
        _fechaInicioMeta,
        fechaInicio.isAcceptableOrUnknown(
          data['fecha_inicio']!,
          _fechaInicioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaInicioMeta);
    }
    if (data.containsKey('fecha_fin')) {
      context.handle(
        _fechaFinMeta,
        fechaFin.isAcceptableOrUnknown(data['fecha_fin']!, _fechaFinMeta),
      );
    }
    if (data.containsKey('created_by_usuario_uid')) {
      context.handle(
        _createdByUsuarioUidMeta,
        createdByUsuarioUid.isAcceptableOrUnknown(
          data['created_by_usuario_uid']!,
          _createdByUsuarioUidMeta,
        ),
      );
    }
    if (data.containsKey('closed_by_usuario_uid')) {
      context.handle(
        _closedByUsuarioUidMeta,
        closedByUsuarioUid.isAcceptableOrUnknown(
          data['closed_by_usuario_uid']!,
          _closedByUsuarioUidMeta,
        ),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
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
  AsignacionLaboralDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AsignacionLaboralDb(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      colaboradorUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}colaborador_uid'],
      )!,
      distribuidorUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distribuidor_uid'],
      )!,
      managerColaboradorUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manager_colaborador_uid'],
      )!,
      rol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rol'],
      )!,
      puesto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puesto'],
      )!,
      nivel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nivel'],
      )!,
      fechaInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_inicio'],
      )!,
      fechaFin: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_fin'],
      ),
      createdByUsuarioUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_usuario_uid'],
      )!,
      closedByUsuarioUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closed_by_usuario_uid'],
      )!,
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
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
  $AsignacionesLaboralesTable createAlias(String alias) {
    return $AsignacionesLaboralesTable(attachedDatabase, alias);
  }
}

class AsignacionLaboralDb extends DataClass
    implements Insertable<AsignacionLaboralDb> {
  final String uid;
  final String colaboradorUid;
  final String distribuidorUid;
  final String managerColaboradorUid;
  final String rol;
  final String puesto;
  final String nivel;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String createdByUsuarioUid;
  final String closedByUsuarioUid;
  final String notas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  final bool isSynced;
  const AsignacionLaboralDb({
    required this.uid,
    required this.colaboradorUid,
    required this.distribuidorUid,
    required this.managerColaboradorUid,
    required this.rol,
    required this.puesto,
    required this.nivel,
    required this.fechaInicio,
    this.fechaFin,
    required this.createdByUsuarioUid,
    required this.closedByUsuarioUid,
    required this.notas,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['colaborador_uid'] = Variable<String>(colaboradorUid);
    map['distribuidor_uid'] = Variable<String>(distribuidorUid);
    map['manager_colaborador_uid'] = Variable<String>(managerColaboradorUid);
    map['rol'] = Variable<String>(rol);
    map['puesto'] = Variable<String>(puesto);
    map['nivel'] = Variable<String>(nivel);
    map['fecha_inicio'] = Variable<DateTime>(fechaInicio);
    if (!nullToAbsent || fechaFin != null) {
      map['fecha_fin'] = Variable<DateTime>(fechaFin);
    }
    map['created_by_usuario_uid'] = Variable<String>(createdByUsuarioUid);
    map['closed_by_usuario_uid'] = Variable<String>(closedByUsuarioUid);
    map['notas'] = Variable<String>(notas);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  AsignacionesLaboralesCompanion toCompanion(bool nullToAbsent) {
    return AsignacionesLaboralesCompanion(
      uid: Value(uid),
      colaboradorUid: Value(colaboradorUid),
      distribuidorUid: Value(distribuidorUid),
      managerColaboradorUid: Value(managerColaboradorUid),
      rol: Value(rol),
      puesto: Value(puesto),
      nivel: Value(nivel),
      fechaInicio: Value(fechaInicio),
      fechaFin: fechaFin == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaFin),
      createdByUsuarioUid: Value(createdByUsuarioUid),
      closedByUsuarioUid: Value(closedByUsuarioUid),
      notas: Value(notas),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      isSynced: Value(isSynced),
    );
  }

  factory AsignacionLaboralDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AsignacionLaboralDb(
      uid: serializer.fromJson<String>(json['uid']),
      colaboradorUid: serializer.fromJson<String>(json['colaboradorUid']),
      distribuidorUid: serializer.fromJson<String>(json['distribuidorUid']),
      managerColaboradorUid: serializer.fromJson<String>(
        json['managerColaboradorUid'],
      ),
      rol: serializer.fromJson<String>(json['rol']),
      puesto: serializer.fromJson<String>(json['puesto']),
      nivel: serializer.fromJson<String>(json['nivel']),
      fechaInicio: serializer.fromJson<DateTime>(json['fechaInicio']),
      fechaFin: serializer.fromJson<DateTime?>(json['fechaFin']),
      createdByUsuarioUid: serializer.fromJson<String>(
        json['createdByUsuarioUid'],
      ),
      closedByUsuarioUid: serializer.fromJson<String>(
        json['closedByUsuarioUid'],
      ),
      notas: serializer.fromJson<String>(json['notas']),
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
      'colaboradorUid': serializer.toJson<String>(colaboradorUid),
      'distribuidorUid': serializer.toJson<String>(distribuidorUid),
      'managerColaboradorUid': serializer.toJson<String>(managerColaboradorUid),
      'rol': serializer.toJson<String>(rol),
      'puesto': serializer.toJson<String>(puesto),
      'nivel': serializer.toJson<String>(nivel),
      'fechaInicio': serializer.toJson<DateTime>(fechaInicio),
      'fechaFin': serializer.toJson<DateTime?>(fechaFin),
      'createdByUsuarioUid': serializer.toJson<String>(createdByUsuarioUid),
      'closedByUsuarioUid': serializer.toJson<String>(closedByUsuarioUid),
      'notas': serializer.toJson<String>(notas),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  AsignacionLaboralDb copyWith({
    String? uid,
    String? colaboradorUid,
    String? distribuidorUid,
    String? managerColaboradorUid,
    String? rol,
    String? puesto,
    String? nivel,
    DateTime? fechaInicio,
    Value<DateTime?> fechaFin = const Value.absent(),
    String? createdByUsuarioUid,
    String? closedByUsuarioUid,
    String? notas,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
    bool? isSynced,
  }) => AsignacionLaboralDb(
    uid: uid ?? this.uid,
    colaboradorUid: colaboradorUid ?? this.colaboradorUid,
    distribuidorUid: distribuidorUid ?? this.distribuidorUid,
    managerColaboradorUid: managerColaboradorUid ?? this.managerColaboradorUid,
    rol: rol ?? this.rol,
    puesto: puesto ?? this.puesto,
    nivel: nivel ?? this.nivel,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin.present ? fechaFin.value : this.fechaFin,
    createdByUsuarioUid: createdByUsuarioUid ?? this.createdByUsuarioUid,
    closedByUsuarioUid: closedByUsuarioUid ?? this.closedByUsuarioUid,
    notas: notas ?? this.notas,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    isSynced: isSynced ?? this.isSynced,
  );
  AsignacionLaboralDb copyWithCompanion(AsignacionesLaboralesCompanion data) {
    return AsignacionLaboralDb(
      uid: data.uid.present ? data.uid.value : this.uid,
      colaboradorUid: data.colaboradorUid.present
          ? data.colaboradorUid.value
          : this.colaboradorUid,
      distribuidorUid: data.distribuidorUid.present
          ? data.distribuidorUid.value
          : this.distribuidorUid,
      managerColaboradorUid: data.managerColaboradorUid.present
          ? data.managerColaboradorUid.value
          : this.managerColaboradorUid,
      rol: data.rol.present ? data.rol.value : this.rol,
      puesto: data.puesto.present ? data.puesto.value : this.puesto,
      nivel: data.nivel.present ? data.nivel.value : this.nivel,
      fechaInicio: data.fechaInicio.present
          ? data.fechaInicio.value
          : this.fechaInicio,
      fechaFin: data.fechaFin.present ? data.fechaFin.value : this.fechaFin,
      createdByUsuarioUid: data.createdByUsuarioUid.present
          ? data.createdByUsuarioUid.value
          : this.createdByUsuarioUid,
      closedByUsuarioUid: data.closedByUsuarioUid.present
          ? data.closedByUsuarioUid.value
          : this.closedByUsuarioUid,
      notas: data.notas.present ? data.notas.value : this.notas,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AsignacionLaboralDb(')
          ..write('uid: $uid, ')
          ..write('colaboradorUid: $colaboradorUid, ')
          ..write('distribuidorUid: $distribuidorUid, ')
          ..write('managerColaboradorUid: $managerColaboradorUid, ')
          ..write('rol: $rol, ')
          ..write('puesto: $puesto, ')
          ..write('nivel: $nivel, ')
          ..write('fechaInicio: $fechaInicio, ')
          ..write('fechaFin: $fechaFin, ')
          ..write('createdByUsuarioUid: $createdByUsuarioUid, ')
          ..write('closedByUsuarioUid: $closedByUsuarioUid, ')
          ..write('notas: $notas, ')
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
    colaboradorUid,
    distribuidorUid,
    managerColaboradorUid,
    rol,
    puesto,
    nivel,
    fechaInicio,
    fechaFin,
    createdByUsuarioUid,
    closedByUsuarioUid,
    notas,
    createdAt,
    updatedAt,
    deleted,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsignacionLaboralDb &&
          other.uid == this.uid &&
          other.colaboradorUid == this.colaboradorUid &&
          other.distribuidorUid == this.distribuidorUid &&
          other.managerColaboradorUid == this.managerColaboradorUid &&
          other.rol == this.rol &&
          other.puesto == this.puesto &&
          other.nivel == this.nivel &&
          other.fechaInicio == this.fechaInicio &&
          other.fechaFin == this.fechaFin &&
          other.createdByUsuarioUid == this.createdByUsuarioUid &&
          other.closedByUsuarioUid == this.closedByUsuarioUid &&
          other.notas == this.notas &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.isSynced == this.isSynced);
}

class AsignacionesLaboralesCompanion
    extends UpdateCompanion<AsignacionLaboralDb> {
  final Value<String> uid;
  final Value<String> colaboradorUid;
  final Value<String> distribuidorUid;
  final Value<String> managerColaboradorUid;
  final Value<String> rol;
  final Value<String> puesto;
  final Value<String> nivel;
  final Value<DateTime> fechaInicio;
  final Value<DateTime?> fechaFin;
  final Value<String> createdByUsuarioUid;
  final Value<String> closedByUsuarioUid;
  final Value<String> notas;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const AsignacionesLaboralesCompanion({
    this.uid = const Value.absent(),
    this.colaboradorUid = const Value.absent(),
    this.distribuidorUid = const Value.absent(),
    this.managerColaboradorUid = const Value.absent(),
    this.rol = const Value.absent(),
    this.puesto = const Value.absent(),
    this.nivel = const Value.absent(),
    this.fechaInicio = const Value.absent(),
    this.fechaFin = const Value.absent(),
    this.createdByUsuarioUid = const Value.absent(),
    this.closedByUsuarioUid = const Value.absent(),
    this.notas = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AsignacionesLaboralesCompanion.insert({
    required String uid,
    required String colaboradorUid,
    this.distribuidorUid = const Value.absent(),
    this.managerColaboradorUid = const Value.absent(),
    this.rol = const Value.absent(),
    this.puesto = const Value.absent(),
    this.nivel = const Value.absent(),
    required DateTime fechaInicio,
    this.fechaFin = const Value.absent(),
    this.createdByUsuarioUid = const Value.absent(),
    this.closedByUsuarioUid = const Value.absent(),
    this.notas = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       colaboradorUid = Value(colaboradorUid),
       fechaInicio = Value(fechaInicio);
  static Insertable<AsignacionLaboralDb> custom({
    Expression<String>? uid,
    Expression<String>? colaboradorUid,
    Expression<String>? distribuidorUid,
    Expression<String>? managerColaboradorUid,
    Expression<String>? rol,
    Expression<String>? puesto,
    Expression<String>? nivel,
    Expression<DateTime>? fechaInicio,
    Expression<DateTime>? fechaFin,
    Expression<String>? createdByUsuarioUid,
    Expression<String>? closedByUsuarioUid,
    Expression<String>? notas,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (colaboradorUid != null) 'colaborador_uid': colaboradorUid,
      if (distribuidorUid != null) 'distribuidor_uid': distribuidorUid,
      if (managerColaboradorUid != null)
        'manager_colaborador_uid': managerColaboradorUid,
      if (rol != null) 'rol': rol,
      if (puesto != null) 'puesto': puesto,
      if (nivel != null) 'nivel': nivel,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio,
      if (fechaFin != null) 'fecha_fin': fechaFin,
      if (createdByUsuarioUid != null)
        'created_by_usuario_uid': createdByUsuarioUid,
      if (closedByUsuarioUid != null)
        'closed_by_usuario_uid': closedByUsuarioUid,
      if (notas != null) 'notas': notas,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AsignacionesLaboralesCompanion copyWith({
    Value<String>? uid,
    Value<String>? colaboradorUid,
    Value<String>? distribuidorUid,
    Value<String>? managerColaboradorUid,
    Value<String>? rol,
    Value<String>? puesto,
    Value<String>? nivel,
    Value<DateTime>? fechaInicio,
    Value<DateTime?>? fechaFin,
    Value<String>? createdByUsuarioUid,
    Value<String>? closedByUsuarioUid,
    Value<String>? notas,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return AsignacionesLaboralesCompanion(
      uid: uid ?? this.uid,
      colaboradorUid: colaboradorUid ?? this.colaboradorUid,
      distribuidorUid: distribuidorUid ?? this.distribuidorUid,
      managerColaboradorUid:
          managerColaboradorUid ?? this.managerColaboradorUid,
      rol: rol ?? this.rol,
      puesto: puesto ?? this.puesto,
      nivel: nivel ?? this.nivel,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      createdByUsuarioUid: createdByUsuarioUid ?? this.createdByUsuarioUid,
      closedByUsuarioUid: closedByUsuarioUid ?? this.closedByUsuarioUid,
      notas: notas ?? this.notas,
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
    if (colaboradorUid.present) {
      map['colaborador_uid'] = Variable<String>(colaboradorUid.value);
    }
    if (distribuidorUid.present) {
      map['distribuidor_uid'] = Variable<String>(distribuidorUid.value);
    }
    if (managerColaboradorUid.present) {
      map['manager_colaborador_uid'] = Variable<String>(
        managerColaboradorUid.value,
      );
    }
    if (rol.present) {
      map['rol'] = Variable<String>(rol.value);
    }
    if (puesto.present) {
      map['puesto'] = Variable<String>(puesto.value);
    }
    if (nivel.present) {
      map['nivel'] = Variable<String>(nivel.value);
    }
    if (fechaInicio.present) {
      map['fecha_inicio'] = Variable<DateTime>(fechaInicio.value);
    }
    if (fechaFin.present) {
      map['fecha_fin'] = Variable<DateTime>(fechaFin.value);
    }
    if (createdByUsuarioUid.present) {
      map['created_by_usuario_uid'] = Variable<String>(
        createdByUsuarioUid.value,
      );
    }
    if (closedByUsuarioUid.present) {
      map['closed_by_usuario_uid'] = Variable<String>(closedByUsuarioUid.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
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
    return (StringBuffer('AsignacionesLaboralesCompanion(')
          ..write('uid: $uid, ')
          ..write('colaboradorUid: $colaboradorUid, ')
          ..write('distribuidorUid: $distribuidorUid, ')
          ..write('managerColaboradorUid: $managerColaboradorUid, ')
          ..write('rol: $rol, ')
          ..write('puesto: $puesto, ')
          ..write('nivel: $nivel, ')
          ..write('fechaInicio: $fechaInicio, ')
          ..write('fechaFin: $fechaFin, ')
          ..write('createdByUsuarioUid: $createdByUsuarioUid, ')
          ..write('closedByUsuarioUid: $closedByUsuarioUid, ')
          ..write('notas: $notas, ')
          ..write('createdAt: $createdAt, ')
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
  late final $ProductosTable productos = $ProductosTable(this);
  late final $ColaboradoresTable colaboradores = $ColaboradoresTable(this);
  late final $AsignacionesLaboralesTable asignacionesLaborales =
      $AsignacionesLaboralesTable(this);
  late final UsuariosDao usuariosDao = UsuariosDao(this as AppDatabase);
  late final DistribuidoresDao distribuidoresDao = DistribuidoresDao(
    this as AppDatabase,
  );
  late final ReportesDao reportesDao = ReportesDao(this as AppDatabase);
  late final ModelosDao modelosDao = ModelosDao(this as AppDatabase);
  late final ModeloImagenesDao modeloImagenesDao = ModeloImagenesDao(
    this as AppDatabase,
  );
  late final ProductosDao productosDao = ProductosDao(this as AppDatabase);
  late final ColaboradoresDao colaboradoresDao = ColaboradoresDao(
    this as AppDatabase,
  );
  late final AsignacionesLaboralesDao asignacionesLaboralesDao =
      AsignacionesLaboralesDao(this as AppDatabase);
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
    productos,
    colaboradores,
    asignacionesLaborales,
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
      Value<String> sha256,
      Value<bool> isCover,
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
      Value<String> sha256,
      Value<bool> isCover,
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

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCover => $composableBuilder(
    column: $table.isCover,
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

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCover => $composableBuilder(
    column: $table.isCover,
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

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<bool> get isCover =>
      $composableBuilder(column: $table.isCover, builder: (column) => column);

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
                Value<String> sha256 = const Value.absent(),
                Value<bool> isCover = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModeloImagenesCompanion(
                uid: uid,
                modeloUid: modeloUid,
                rutaRemota: rutaRemota,
                rutaLocal: rutaLocal,
                sha256: sha256,
                isCover: isCover,
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
                Value<String> sha256 = const Value.absent(),
                Value<bool> isCover = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModeloImagenesCompanion.insert(
                uid: uid,
                modeloUid: modeloUid,
                rutaRemota: rutaRemota,
                rutaLocal: rutaLocal,
                sha256: sha256,
                isCover: isCover,
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
typedef $$ProductosTableCreateCompanionBuilder =
    ProductosCompanion Function({
      required String uid,
      Value<String> nombre,
      Value<bool> activo,
      Value<int> plazoMeses,
      Value<double> factorIntegrante,
      Value<double> factorPropietario,
      Value<double> cuotaInscripcionPct,
      Value<double> cuotaAdministracionPct,
      Value<double> ivaCuotaAdministracionPct,
      Value<double> cuotaSeguroVidaPct,
      Value<int> adelantoMinMens,
      Value<int> adelantoMaxMens,
      Value<int> mesEntregaMin,
      Value<int> mesEntregaMax,
      Value<int> prioridad,
      Value<String> notas,
      Value<DateTime?> vigenteDesde,
      Value<DateTime?> vigenteHasta,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$ProductosTableUpdateCompanionBuilder =
    ProductosCompanion Function({
      Value<String> uid,
      Value<String> nombre,
      Value<bool> activo,
      Value<int> plazoMeses,
      Value<double> factorIntegrante,
      Value<double> factorPropietario,
      Value<double> cuotaInscripcionPct,
      Value<double> cuotaAdministracionPct,
      Value<double> ivaCuotaAdministracionPct,
      Value<double> cuotaSeguroVidaPct,
      Value<int> adelantoMinMens,
      Value<int> adelantoMaxMens,
      Value<int> mesEntregaMin,
      Value<int> mesEntregaMax,
      Value<int> prioridad,
      Value<String> notas,
      Value<DateTime?> vigenteDesde,
      Value<DateTime?> vigenteHasta,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$ProductosTableFilterComposer
    extends Composer<_$AppDatabase, $ProductosTable> {
  $$ProductosTableFilterComposer({
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

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plazoMeses => $composableBuilder(
    column: $table.plazoMeses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get factorIntegrante => $composableBuilder(
    column: $table.factorIntegrante,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get factorPropietario => $composableBuilder(
    column: $table.factorPropietario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cuotaInscripcionPct => $composableBuilder(
    column: $table.cuotaInscripcionPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cuotaAdministracionPct => $composableBuilder(
    column: $table.cuotaAdministracionPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ivaCuotaAdministracionPct => $composableBuilder(
    column: $table.ivaCuotaAdministracionPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cuotaSeguroVidaPct => $composableBuilder(
    column: $table.cuotaSeguroVidaPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get adelantoMinMens => $composableBuilder(
    column: $table.adelantoMinMens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get adelantoMaxMens => $composableBuilder(
    column: $table.adelantoMaxMens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mesEntregaMin => $composableBuilder(
    column: $table.mesEntregaMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mesEntregaMax => $composableBuilder(
    column: $table.mesEntregaMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prioridad => $composableBuilder(
    column: $table.prioridad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get vigenteDesde => $composableBuilder(
    column: $table.vigenteDesde,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get vigenteHasta => $composableBuilder(
    column: $table.vigenteHasta,
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

class $$ProductosTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductosTable> {
  $$ProductosTableOrderingComposer({
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

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plazoMeses => $composableBuilder(
    column: $table.plazoMeses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get factorIntegrante => $composableBuilder(
    column: $table.factorIntegrante,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get factorPropietario => $composableBuilder(
    column: $table.factorPropietario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cuotaInscripcionPct => $composableBuilder(
    column: $table.cuotaInscripcionPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cuotaAdministracionPct => $composableBuilder(
    column: $table.cuotaAdministracionPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ivaCuotaAdministracionPct => $composableBuilder(
    column: $table.ivaCuotaAdministracionPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cuotaSeguroVidaPct => $composableBuilder(
    column: $table.cuotaSeguroVidaPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get adelantoMinMens => $composableBuilder(
    column: $table.adelantoMinMens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get adelantoMaxMens => $composableBuilder(
    column: $table.adelantoMaxMens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mesEntregaMin => $composableBuilder(
    column: $table.mesEntregaMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mesEntregaMax => $composableBuilder(
    column: $table.mesEntregaMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prioridad => $composableBuilder(
    column: $table.prioridad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get vigenteDesde => $composableBuilder(
    column: $table.vigenteDesde,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get vigenteHasta => $composableBuilder(
    column: $table.vigenteHasta,
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

class $$ProductosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductosTable> {
  $$ProductosTableAnnotationComposer({
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

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<int> get plazoMeses => $composableBuilder(
    column: $table.plazoMeses,
    builder: (column) => column,
  );

  GeneratedColumn<double> get factorIntegrante => $composableBuilder(
    column: $table.factorIntegrante,
    builder: (column) => column,
  );

  GeneratedColumn<double> get factorPropietario => $composableBuilder(
    column: $table.factorPropietario,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cuotaInscripcionPct => $composableBuilder(
    column: $table.cuotaInscripcionPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cuotaAdministracionPct => $composableBuilder(
    column: $table.cuotaAdministracionPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ivaCuotaAdministracionPct => $composableBuilder(
    column: $table.ivaCuotaAdministracionPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cuotaSeguroVidaPct => $composableBuilder(
    column: $table.cuotaSeguroVidaPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get adelantoMinMens => $composableBuilder(
    column: $table.adelantoMinMens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get adelantoMaxMens => $composableBuilder(
    column: $table.adelantoMaxMens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mesEntregaMin => $composableBuilder(
    column: $table.mesEntregaMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mesEntregaMax => $composableBuilder(
    column: $table.mesEntregaMax,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prioridad =>
      $composableBuilder(column: $table.prioridad, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<DateTime> get vigenteDesde => $composableBuilder(
    column: $table.vigenteDesde,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get vigenteHasta => $composableBuilder(
    column: $table.vigenteHasta,
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

class $$ProductosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductosTable,
          ProductoDb,
          $$ProductosTableFilterComposer,
          $$ProductosTableOrderingComposer,
          $$ProductosTableAnnotationComposer,
          $$ProductosTableCreateCompanionBuilder,
          $$ProductosTableUpdateCompanionBuilder,
          (
            ProductoDb,
            BaseReferences<_$AppDatabase, $ProductosTable, ProductoDb>,
          ),
          ProductoDb,
          PrefetchHooks Function()
        > {
  $$ProductosTableTableManager(_$AppDatabase db, $ProductosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> plazoMeses = const Value.absent(),
                Value<double> factorIntegrante = const Value.absent(),
                Value<double> factorPropietario = const Value.absent(),
                Value<double> cuotaInscripcionPct = const Value.absent(),
                Value<double> cuotaAdministracionPct = const Value.absent(),
                Value<double> ivaCuotaAdministracionPct = const Value.absent(),
                Value<double> cuotaSeguroVidaPct = const Value.absent(),
                Value<int> adelantoMinMens = const Value.absent(),
                Value<int> adelantoMaxMens = const Value.absent(),
                Value<int> mesEntregaMin = const Value.absent(),
                Value<int> mesEntregaMax = const Value.absent(),
                Value<int> prioridad = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<DateTime?> vigenteDesde = const Value.absent(),
                Value<DateTime?> vigenteHasta = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductosCompanion(
                uid: uid,
                nombre: nombre,
                activo: activo,
                plazoMeses: plazoMeses,
                factorIntegrante: factorIntegrante,
                factorPropietario: factorPropietario,
                cuotaInscripcionPct: cuotaInscripcionPct,
                cuotaAdministracionPct: cuotaAdministracionPct,
                ivaCuotaAdministracionPct: ivaCuotaAdministracionPct,
                cuotaSeguroVidaPct: cuotaSeguroVidaPct,
                adelantoMinMens: adelantoMinMens,
                adelantoMaxMens: adelantoMaxMens,
                mesEntregaMin: mesEntregaMin,
                mesEntregaMax: mesEntregaMax,
                prioridad: prioridad,
                notas: notas,
                vigenteDesde: vigenteDesde,
                vigenteHasta: vigenteHasta,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deleted: deleted,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                Value<String> nombre = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> plazoMeses = const Value.absent(),
                Value<double> factorIntegrante = const Value.absent(),
                Value<double> factorPropietario = const Value.absent(),
                Value<double> cuotaInscripcionPct = const Value.absent(),
                Value<double> cuotaAdministracionPct = const Value.absent(),
                Value<double> ivaCuotaAdministracionPct = const Value.absent(),
                Value<double> cuotaSeguroVidaPct = const Value.absent(),
                Value<int> adelantoMinMens = const Value.absent(),
                Value<int> adelantoMaxMens = const Value.absent(),
                Value<int> mesEntregaMin = const Value.absent(),
                Value<int> mesEntregaMax = const Value.absent(),
                Value<int> prioridad = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<DateTime?> vigenteDesde = const Value.absent(),
                Value<DateTime?> vigenteHasta = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductosCompanion.insert(
                uid: uid,
                nombre: nombre,
                activo: activo,
                plazoMeses: plazoMeses,
                factorIntegrante: factorIntegrante,
                factorPropietario: factorPropietario,
                cuotaInscripcionPct: cuotaInscripcionPct,
                cuotaAdministracionPct: cuotaAdministracionPct,
                ivaCuotaAdministracionPct: ivaCuotaAdministracionPct,
                cuotaSeguroVidaPct: cuotaSeguroVidaPct,
                adelantoMinMens: adelantoMinMens,
                adelantoMaxMens: adelantoMaxMens,
                mesEntregaMin: mesEntregaMin,
                mesEntregaMax: mesEntregaMax,
                prioridad: prioridad,
                notas: notas,
                vigenteDesde: vigenteDesde,
                vigenteHasta: vigenteHasta,
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

typedef $$ProductosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductosTable,
      ProductoDb,
      $$ProductosTableFilterComposer,
      $$ProductosTableOrderingComposer,
      $$ProductosTableAnnotationComposer,
      $$ProductosTableCreateCompanionBuilder,
      $$ProductosTableUpdateCompanionBuilder,
      (ProductoDb, BaseReferences<_$AppDatabase, $ProductosTable, ProductoDb>),
      ProductoDb,
      PrefetchHooks Function()
    >;
typedef $$ColaboradoresTableCreateCompanionBuilder =
    ColaboradoresCompanion Function({
      required String uid,
      required String nombres,
      Value<String> apellidoPaterno,
      Value<String> apellidoMaterno,
      Value<DateTime?> fechaNacimiento,
      Value<String?> curp,
      Value<String?> rfc,
      Value<String> telefonoMovil,
      Value<String> emailPersonal,
      Value<String> fotoRutaLocal,
      Value<String> fotoRutaRemota,
      Value<String?> genero,
      Value<String> notas,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$ColaboradoresTableUpdateCompanionBuilder =
    ColaboradoresCompanion Function({
      Value<String> uid,
      Value<String> nombres,
      Value<String> apellidoPaterno,
      Value<String> apellidoMaterno,
      Value<DateTime?> fechaNacimiento,
      Value<String?> curp,
      Value<String?> rfc,
      Value<String> telefonoMovil,
      Value<String> emailPersonal,
      Value<String> fotoRutaLocal,
      Value<String> fotoRutaRemota,
      Value<String?> genero,
      Value<String> notas,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$ColaboradoresTableFilterComposer
    extends Composer<_$AppDatabase, $ColaboradoresTable> {
  $$ColaboradoresTableFilterComposer({
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

  ColumnFilters<String> get nombres => $composableBuilder(
    column: $table.nombres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apellidoPaterno => $composableBuilder(
    column: $table.apellidoPaterno,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apellidoMaterno => $composableBuilder(
    column: $table.apellidoMaterno,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaNacimiento => $composableBuilder(
    column: $table.fechaNacimiento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get curp => $composableBuilder(
    column: $table.curp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rfc => $composableBuilder(
    column: $table.rfc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefonoMovil => $composableBuilder(
    column: $table.telefonoMovil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emailPersonal => $composableBuilder(
    column: $table.emailPersonal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoRutaLocal => $composableBuilder(
    column: $table.fotoRutaLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoRutaRemota => $composableBuilder(
    column: $table.fotoRutaRemota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genero => $composableBuilder(
    column: $table.genero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
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

class $$ColaboradoresTableOrderingComposer
    extends Composer<_$AppDatabase, $ColaboradoresTable> {
  $$ColaboradoresTableOrderingComposer({
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

  ColumnOrderings<String> get nombres => $composableBuilder(
    column: $table.nombres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apellidoPaterno => $composableBuilder(
    column: $table.apellidoPaterno,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apellidoMaterno => $composableBuilder(
    column: $table.apellidoMaterno,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaNacimiento => $composableBuilder(
    column: $table.fechaNacimiento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get curp => $composableBuilder(
    column: $table.curp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rfc => $composableBuilder(
    column: $table.rfc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefonoMovil => $composableBuilder(
    column: $table.telefonoMovil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emailPersonal => $composableBuilder(
    column: $table.emailPersonal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoRutaLocal => $composableBuilder(
    column: $table.fotoRutaLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoRutaRemota => $composableBuilder(
    column: $table.fotoRutaRemota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genero => $composableBuilder(
    column: $table.genero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
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

class $$ColaboradoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ColaboradoresTable> {
  $$ColaboradoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get nombres =>
      $composableBuilder(column: $table.nombres, builder: (column) => column);

  GeneratedColumn<String> get apellidoPaterno => $composableBuilder(
    column: $table.apellidoPaterno,
    builder: (column) => column,
  );

  GeneratedColumn<String> get apellidoMaterno => $composableBuilder(
    column: $table.apellidoMaterno,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaNacimiento => $composableBuilder(
    column: $table.fechaNacimiento,
    builder: (column) => column,
  );

  GeneratedColumn<String> get curp =>
      $composableBuilder(column: $table.curp, builder: (column) => column);

  GeneratedColumn<String> get rfc =>
      $composableBuilder(column: $table.rfc, builder: (column) => column);

  GeneratedColumn<String> get telefonoMovil => $composableBuilder(
    column: $table.telefonoMovil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emailPersonal => $composableBuilder(
    column: $table.emailPersonal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fotoRutaLocal => $composableBuilder(
    column: $table.fotoRutaLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fotoRutaRemota => $composableBuilder(
    column: $table.fotoRutaRemota,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genero =>
      $composableBuilder(column: $table.genero, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$ColaboradoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ColaboradoresTable,
          ColaboradorDb,
          $$ColaboradoresTableFilterComposer,
          $$ColaboradoresTableOrderingComposer,
          $$ColaboradoresTableAnnotationComposer,
          $$ColaboradoresTableCreateCompanionBuilder,
          $$ColaboradoresTableUpdateCompanionBuilder,
          (
            ColaboradorDb,
            BaseReferences<_$AppDatabase, $ColaboradoresTable, ColaboradorDb>,
          ),
          ColaboradorDb,
          PrefetchHooks Function()
        > {
  $$ColaboradoresTableTableManager(_$AppDatabase db, $ColaboradoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ColaboradoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ColaboradoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ColaboradoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> nombres = const Value.absent(),
                Value<String> apellidoPaterno = const Value.absent(),
                Value<String> apellidoMaterno = const Value.absent(),
                Value<DateTime?> fechaNacimiento = const Value.absent(),
                Value<String?> curp = const Value.absent(),
                Value<String?> rfc = const Value.absent(),
                Value<String> telefonoMovil = const Value.absent(),
                Value<String> emailPersonal = const Value.absent(),
                Value<String> fotoRutaLocal = const Value.absent(),
                Value<String> fotoRutaRemota = const Value.absent(),
                Value<String?> genero = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ColaboradoresCompanion(
                uid: uid,
                nombres: nombres,
                apellidoPaterno: apellidoPaterno,
                apellidoMaterno: apellidoMaterno,
                fechaNacimiento: fechaNacimiento,
                curp: curp,
                rfc: rfc,
                telefonoMovil: telefonoMovil,
                emailPersonal: emailPersonal,
                fotoRutaLocal: fotoRutaLocal,
                fotoRutaRemota: fotoRutaRemota,
                genero: genero,
                notas: notas,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deleted: deleted,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String nombres,
                Value<String> apellidoPaterno = const Value.absent(),
                Value<String> apellidoMaterno = const Value.absent(),
                Value<DateTime?> fechaNacimiento = const Value.absent(),
                Value<String?> curp = const Value.absent(),
                Value<String?> rfc = const Value.absent(),
                Value<String> telefonoMovil = const Value.absent(),
                Value<String> emailPersonal = const Value.absent(),
                Value<String> fotoRutaLocal = const Value.absent(),
                Value<String> fotoRutaRemota = const Value.absent(),
                Value<String?> genero = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ColaboradoresCompanion.insert(
                uid: uid,
                nombres: nombres,
                apellidoPaterno: apellidoPaterno,
                apellidoMaterno: apellidoMaterno,
                fechaNacimiento: fechaNacimiento,
                curp: curp,
                rfc: rfc,
                telefonoMovil: telefonoMovil,
                emailPersonal: emailPersonal,
                fotoRutaLocal: fotoRutaLocal,
                fotoRutaRemota: fotoRutaRemota,
                genero: genero,
                notas: notas,
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

typedef $$ColaboradoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ColaboradoresTable,
      ColaboradorDb,
      $$ColaboradoresTableFilterComposer,
      $$ColaboradoresTableOrderingComposer,
      $$ColaboradoresTableAnnotationComposer,
      $$ColaboradoresTableCreateCompanionBuilder,
      $$ColaboradoresTableUpdateCompanionBuilder,
      (
        ColaboradorDb,
        BaseReferences<_$AppDatabase, $ColaboradoresTable, ColaboradorDb>,
      ),
      ColaboradorDb,
      PrefetchHooks Function()
    >;
typedef $$AsignacionesLaboralesTableCreateCompanionBuilder =
    AsignacionesLaboralesCompanion Function({
      required String uid,
      required String colaboradorUid,
      Value<String> distribuidorUid,
      Value<String> managerColaboradorUid,
      Value<String> rol,
      Value<String> puesto,
      Value<String> nivel,
      required DateTime fechaInicio,
      Value<DateTime?> fechaFin,
      Value<String> createdByUsuarioUid,
      Value<String> closedByUsuarioUid,
      Value<String> notas,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$AsignacionesLaboralesTableUpdateCompanionBuilder =
    AsignacionesLaboralesCompanion Function({
      Value<String> uid,
      Value<String> colaboradorUid,
      Value<String> distribuidorUid,
      Value<String> managerColaboradorUid,
      Value<String> rol,
      Value<String> puesto,
      Value<String> nivel,
      Value<DateTime> fechaInicio,
      Value<DateTime?> fechaFin,
      Value<String> createdByUsuarioUid,
      Value<String> closedByUsuarioUid,
      Value<String> notas,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$AsignacionesLaboralesTableFilterComposer
    extends Composer<_$AppDatabase, $AsignacionesLaboralesTable> {
  $$AsignacionesLaboralesTableFilterComposer({
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

  ColumnFilters<String> get colaboradorUid => $composableBuilder(
    column: $table.colaboradorUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distribuidorUid => $composableBuilder(
    column: $table.distribuidorUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managerColaboradorUid => $composableBuilder(
    column: $table.managerColaboradorUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get puesto => $composableBuilder(
    column: $table.puesto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nivel => $composableBuilder(
    column: $table.nivel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaFin => $composableBuilder(
    column: $table.fechaFin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdByUsuarioUid => $composableBuilder(
    column: $table.createdByUsuarioUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closedByUsuarioUid => $composableBuilder(
    column: $table.closedByUsuarioUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
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

class $$AsignacionesLaboralesTableOrderingComposer
    extends Composer<_$AppDatabase, $AsignacionesLaboralesTable> {
  $$AsignacionesLaboralesTableOrderingComposer({
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

  ColumnOrderings<String> get colaboradorUid => $composableBuilder(
    column: $table.colaboradorUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distribuidorUid => $composableBuilder(
    column: $table.distribuidorUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managerColaboradorUid => $composableBuilder(
    column: $table.managerColaboradorUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get puesto => $composableBuilder(
    column: $table.puesto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nivel => $composableBuilder(
    column: $table.nivel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaFin => $composableBuilder(
    column: $table.fechaFin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdByUsuarioUid => $composableBuilder(
    column: $table.createdByUsuarioUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closedByUsuarioUid => $composableBuilder(
    column: $table.closedByUsuarioUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
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

class $$AsignacionesLaboralesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AsignacionesLaboralesTable> {
  $$AsignacionesLaboralesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get colaboradorUid => $composableBuilder(
    column: $table.colaboradorUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get distribuidorUid => $composableBuilder(
    column: $table.distribuidorUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get managerColaboradorUid => $composableBuilder(
    column: $table.managerColaboradorUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rol =>
      $composableBuilder(column: $table.rol, builder: (column) => column);

  GeneratedColumn<String> get puesto =>
      $composableBuilder(column: $table.puesto, builder: (column) => column);

  GeneratedColumn<String> get nivel =>
      $composableBuilder(column: $table.nivel, builder: (column) => column);

  GeneratedColumn<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaFin =>
      $composableBuilder(column: $table.fechaFin, builder: (column) => column);

  GeneratedColumn<String> get createdByUsuarioUid => $composableBuilder(
    column: $table.createdByUsuarioUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get closedByUsuarioUid => $composableBuilder(
    column: $table.closedByUsuarioUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$AsignacionesLaboralesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AsignacionesLaboralesTable,
          AsignacionLaboralDb,
          $$AsignacionesLaboralesTableFilterComposer,
          $$AsignacionesLaboralesTableOrderingComposer,
          $$AsignacionesLaboralesTableAnnotationComposer,
          $$AsignacionesLaboralesTableCreateCompanionBuilder,
          $$AsignacionesLaboralesTableUpdateCompanionBuilder,
          (
            AsignacionLaboralDb,
            BaseReferences<
              _$AppDatabase,
              $AsignacionesLaboralesTable,
              AsignacionLaboralDb
            >,
          ),
          AsignacionLaboralDb,
          PrefetchHooks Function()
        > {
  $$AsignacionesLaboralesTableTableManager(
    _$AppDatabase db,
    $AsignacionesLaboralesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AsignacionesLaboralesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AsignacionesLaboralesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AsignacionesLaboralesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> colaboradorUid = const Value.absent(),
                Value<String> distribuidorUid = const Value.absent(),
                Value<String> managerColaboradorUid = const Value.absent(),
                Value<String> rol = const Value.absent(),
                Value<String> puesto = const Value.absent(),
                Value<String> nivel = const Value.absent(),
                Value<DateTime> fechaInicio = const Value.absent(),
                Value<DateTime?> fechaFin = const Value.absent(),
                Value<String> createdByUsuarioUid = const Value.absent(),
                Value<String> closedByUsuarioUid = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AsignacionesLaboralesCompanion(
                uid: uid,
                colaboradorUid: colaboradorUid,
                distribuidorUid: distribuidorUid,
                managerColaboradorUid: managerColaboradorUid,
                rol: rol,
                puesto: puesto,
                nivel: nivel,
                fechaInicio: fechaInicio,
                fechaFin: fechaFin,
                createdByUsuarioUid: createdByUsuarioUid,
                closedByUsuarioUid: closedByUsuarioUid,
                notas: notas,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deleted: deleted,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String colaboradorUid,
                Value<String> distribuidorUid = const Value.absent(),
                Value<String> managerColaboradorUid = const Value.absent(),
                Value<String> rol = const Value.absent(),
                Value<String> puesto = const Value.absent(),
                Value<String> nivel = const Value.absent(),
                required DateTime fechaInicio,
                Value<DateTime?> fechaFin = const Value.absent(),
                Value<String> createdByUsuarioUid = const Value.absent(),
                Value<String> closedByUsuarioUid = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AsignacionesLaboralesCompanion.insert(
                uid: uid,
                colaboradorUid: colaboradorUid,
                distribuidorUid: distribuidorUid,
                managerColaboradorUid: managerColaboradorUid,
                rol: rol,
                puesto: puesto,
                nivel: nivel,
                fechaInicio: fechaInicio,
                fechaFin: fechaFin,
                createdByUsuarioUid: createdByUsuarioUid,
                closedByUsuarioUid: closedByUsuarioUid,
                notas: notas,
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

typedef $$AsignacionesLaboralesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AsignacionesLaboralesTable,
      AsignacionLaboralDb,
      $$AsignacionesLaboralesTableFilterComposer,
      $$AsignacionesLaboralesTableOrderingComposer,
      $$AsignacionesLaboralesTableAnnotationComposer,
      $$AsignacionesLaboralesTableCreateCompanionBuilder,
      $$AsignacionesLaboralesTableUpdateCompanionBuilder,
      (
        AsignacionLaboralDb,
        BaseReferences<
          _$AppDatabase,
          $AsignacionesLaboralesTable,
          AsignacionLaboralDb
        >,
      ),
      AsignacionLaboralDb,
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
  $$ProductosTableTableManager get productos =>
      $$ProductosTableTableManager(_db, _db.productos);
  $$ColaboradoresTableTableManager get colaboradores =>
      $$ColaboradoresTableTableManager(_db, _db.colaboradores);
  $$AsignacionesLaboralesTableTableManager get asignacionesLaborales =>
      $$AsignacionesLaboralesTableTableManager(_db, _db.asignacionesLaborales);
}
