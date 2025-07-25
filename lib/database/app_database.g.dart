// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsuariosTable extends Usuarios with TableInfo<$UsuariosTable, Usuario> {
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
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usuarios';
  @override
  VerificationContext validateIntegrity(
    Insertable<Usuario> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  Usuario map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Usuario(
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
      ),
    );
  }

  @override
  $UsuariosTable createAlias(String alias) {
    return $UsuariosTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, bool>, String> $converterpermisos =
      const PermisosConverter();
}

class Usuario extends DataClass implements Insertable<Usuario> {
  final String uid;
  final String nombre;
  final String correo;
  final String rol;
  final String uuidDistribuidora;

  /// Guardamos el Map<String,bool> como JSON
  final Map<String, bool> permisos;

  /// 🆕 Nuevo campo para sincronización incremental
  final DateTime? updatedAt;
  const Usuario({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.uuidDistribuidora,
    required this.permisos,
    this.updatedAt,
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
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
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
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Usuario.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Usuario(
      uid: serializer.fromJson<String>(json['uid']),
      nombre: serializer.fromJson<String>(json['nombre']),
      correo: serializer.fromJson<String>(json['correo']),
      rol: serializer.fromJson<String>(json['rol']),
      uuidDistribuidora: serializer.fromJson<String>(json['uuidDistribuidora']),
      permisos: serializer.fromJson<Map<String, bool>>(json['permisos']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
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
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Usuario copyWith({
    String? uid,
    String? nombre,
    String? correo,
    String? rol,
    String? uuidDistribuidora,
    Map<String, bool>? permisos,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => Usuario(
    uid: uid ?? this.uid,
    nombre: nombre ?? this.nombre,
    correo: correo ?? this.correo,
    rol: rol ?? this.rol,
    uuidDistribuidora: uuidDistribuidora ?? this.uuidDistribuidora,
    permisos: permisos ?? this.permisos,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  Usuario copyWithCompanion(UsuariosCompanion data) {
    return Usuario(
      uid: data.uid.present ? data.uid.value : this.uid,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      correo: data.correo.present ? data.correo.value : this.correo,
      rol: data.rol.present ? data.rol.value : this.rol,
      uuidDistribuidora: data.uuidDistribuidora.present
          ? data.uuidDistribuidora.value
          : this.uuidDistribuidora,
      permisos: data.permisos.present ? data.permisos.value : this.permisos,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Usuario(')
          ..write('uid: $uid, ')
          ..write('nombre: $nombre, ')
          ..write('correo: $correo, ')
          ..write('rol: $rol, ')
          ..write('uuidDistribuidora: $uuidDistribuidora, ')
          ..write('permisos: $permisos, ')
          ..write('updatedAt: $updatedAt')
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
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Usuario &&
          other.uid == this.uid &&
          other.nombre == this.nombre &&
          other.correo == this.correo &&
          other.rol == this.rol &&
          other.uuidDistribuidora == this.uuidDistribuidora &&
          other.permisos == this.permisos &&
          other.updatedAt == this.updatedAt);
}

class UsuariosCompanion extends UpdateCompanion<Usuario> {
  final Value<String> uid;
  final Value<String> nombre;
  final Value<String> correo;
  final Value<String> rol;
  final Value<String> uuidDistribuidora;
  final Value<Map<String, bool>> permisos;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const UsuariosCompanion({
    this.uid = const Value.absent(),
    this.nombre = const Value.absent(),
    this.correo = const Value.absent(),
    this.rol = const Value.absent(),
    this.uuidDistribuidora = const Value.absent(),
    this.permisos = const Value.absent(),
    this.updatedAt = const Value.absent(),
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
    this.rowid = const Value.absent(),
  }) : uid = Value(uid);
  static Insertable<Usuario> custom({
    Expression<String>? uid,
    Expression<String>? nombre,
    Expression<String>? correo,
    Expression<String>? rol,
    Expression<String>? uuidDistribuidora,
    Expression<String>? permisos,
    Expression<DateTime>? updatedAt,
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
    Value<DateTime?>? updatedAt,
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
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActualizacionesTable extends Actualizaciones
    with TableInfo<$ActualizacionesTable, Actualizacion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActualizacionesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _coleccionMeta = const VerificationMeta(
    'coleccion',
  );
  @override
  late final GeneratedColumn<String> coleccion = GeneratedColumn<String>(
    'coleccion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ultimaSyncMeta = const VerificationMeta(
    'ultimaSync',
  );
  @override
  late final GeneratedColumn<DateTime> ultimaSync = GeneratedColumn<DateTime>(
    'ultima_sync',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [coleccion, ultimaSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'actualizaciones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Actualizacion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('coleccion')) {
      context.handle(
        _coleccionMeta,
        coleccion.isAcceptableOrUnknown(data['coleccion']!, _coleccionMeta),
      );
    } else if (isInserting) {
      context.missing(_coleccionMeta);
    }
    if (data.containsKey('ultima_sync')) {
      context.handle(
        _ultimaSyncMeta,
        ultimaSync.isAcceptableOrUnknown(data['ultima_sync']!, _ultimaSyncMeta),
      );
    } else if (isInserting) {
      context.missing(_ultimaSyncMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {coleccion};
  @override
  Actualizacion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Actualizacion(
      coleccion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coleccion'],
      )!,
      ultimaSync: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultima_sync'],
      )!,
    );
  }

  @override
  $ActualizacionesTable createAlias(String alias) {
    return $ActualizacionesTable(attachedDatabase, alias);
  }
}

class Actualizacion extends DataClass implements Insertable<Actualizacion> {
  final String coleccion;
  final DateTime ultimaSync;
  const Actualizacion({required this.coleccion, required this.ultimaSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['coleccion'] = Variable<String>(coleccion);
    map['ultima_sync'] = Variable<DateTime>(ultimaSync);
    return map;
  }

  ActualizacionesCompanion toCompanion(bool nullToAbsent) {
    return ActualizacionesCompanion(
      coleccion: Value(coleccion),
      ultimaSync: Value(ultimaSync),
    );
  }

  factory Actualizacion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Actualizacion(
      coleccion: serializer.fromJson<String>(json['coleccion']),
      ultimaSync: serializer.fromJson<DateTime>(json['ultimaSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'coleccion': serializer.toJson<String>(coleccion),
      'ultimaSync': serializer.toJson<DateTime>(ultimaSync),
    };
  }

  Actualizacion copyWith({String? coleccion, DateTime? ultimaSync}) =>
      Actualizacion(
        coleccion: coleccion ?? this.coleccion,
        ultimaSync: ultimaSync ?? this.ultimaSync,
      );
  Actualizacion copyWithCompanion(ActualizacionesCompanion data) {
    return Actualizacion(
      coleccion: data.coleccion.present ? data.coleccion.value : this.coleccion,
      ultimaSync: data.ultimaSync.present
          ? data.ultimaSync.value
          : this.ultimaSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Actualizacion(')
          ..write('coleccion: $coleccion, ')
          ..write('ultimaSync: $ultimaSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(coleccion, ultimaSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Actualizacion &&
          other.coleccion == this.coleccion &&
          other.ultimaSync == this.ultimaSync);
}

class ActualizacionesCompanion extends UpdateCompanion<Actualizacion> {
  final Value<String> coleccion;
  final Value<DateTime> ultimaSync;
  final Value<int> rowid;
  const ActualizacionesCompanion({
    this.coleccion = const Value.absent(),
    this.ultimaSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActualizacionesCompanion.insert({
    required String coleccion,
    required DateTime ultimaSync,
    this.rowid = const Value.absent(),
  }) : coleccion = Value(coleccion),
       ultimaSync = Value(ultimaSync);
  static Insertable<Actualizacion> custom({
    Expression<String>? coleccion,
    Expression<DateTime>? ultimaSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (coleccion != null) 'coleccion': coleccion,
      if (ultimaSync != null) 'ultima_sync': ultimaSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActualizacionesCompanion copyWith({
    Value<String>? coleccion,
    Value<DateTime>? ultimaSync,
    Value<int>? rowid,
  }) {
    return ActualizacionesCompanion(
      coleccion: coleccion ?? this.coleccion,
      ultimaSync: ultimaSync ?? this.ultimaSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (coleccion.present) {
      map['coleccion'] = Variable<String>(coleccion.value);
    }
    if (ultimaSync.present) {
      map['ultima_sync'] = Variable<DateTime>(ultimaSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActualizacionesCompanion(')
          ..write('coleccion: $coleccion, ')
          ..write('ultimaSync: $ultimaSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsuariosTable usuarios = $UsuariosTable(this);
  late final $ActualizacionesTable actualizaciones = $ActualizacionesTable(
    this,
  );
  late final UsuariosDao usuariosDao = UsuariosDao(this as AppDatabase);
  late final ActualizacionesDao actualizacionesDao = ActualizacionesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    usuarios,
    actualizaciones,
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
      Value<DateTime?> updatedAt,
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
      Value<DateTime?> updatedAt,
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
}

class $$UsuariosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsuariosTable,
          Usuario,
          $$UsuariosTableFilterComposer,
          $$UsuariosTableOrderingComposer,
          $$UsuariosTableAnnotationComposer,
          $$UsuariosTableCreateCompanionBuilder,
          $$UsuariosTableUpdateCompanionBuilder,
          (Usuario, BaseReferences<_$AppDatabase, $UsuariosTable, Usuario>),
          Usuario,
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
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion(
                uid: uid,
                nombre: nombre,
                correo: correo,
                rol: rol,
                uuidDistribuidora: uuidDistribuidora,
                permisos: permisos,
                updatedAt: updatedAt,
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
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion.insert(
                uid: uid,
                nombre: nombre,
                correo: correo,
                rol: rol,
                uuidDistribuidora: uuidDistribuidora,
                permisos: permisos,
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

typedef $$UsuariosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsuariosTable,
      Usuario,
      $$UsuariosTableFilterComposer,
      $$UsuariosTableOrderingComposer,
      $$UsuariosTableAnnotationComposer,
      $$UsuariosTableCreateCompanionBuilder,
      $$UsuariosTableUpdateCompanionBuilder,
      (Usuario, BaseReferences<_$AppDatabase, $UsuariosTable, Usuario>),
      Usuario,
      PrefetchHooks Function()
    >;
typedef $$ActualizacionesTableCreateCompanionBuilder =
    ActualizacionesCompanion Function({
      required String coleccion,
      required DateTime ultimaSync,
      Value<int> rowid,
    });
typedef $$ActualizacionesTableUpdateCompanionBuilder =
    ActualizacionesCompanion Function({
      Value<String> coleccion,
      Value<DateTime> ultimaSync,
      Value<int> rowid,
    });

class $$ActualizacionesTableFilterComposer
    extends Composer<_$AppDatabase, $ActualizacionesTable> {
  $$ActualizacionesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get coleccion => $composableBuilder(
    column: $table.coleccion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ultimaSync => $composableBuilder(
    column: $table.ultimaSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActualizacionesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActualizacionesTable> {
  $$ActualizacionesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get coleccion => $composableBuilder(
    column: $table.coleccion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ultimaSync => $composableBuilder(
    column: $table.ultimaSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActualizacionesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActualizacionesTable> {
  $$ActualizacionesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get coleccion =>
      $composableBuilder(column: $table.coleccion, builder: (column) => column);

  GeneratedColumn<DateTime> get ultimaSync => $composableBuilder(
    column: $table.ultimaSync,
    builder: (column) => column,
  );
}

class $$ActualizacionesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActualizacionesTable,
          Actualizacion,
          $$ActualizacionesTableFilterComposer,
          $$ActualizacionesTableOrderingComposer,
          $$ActualizacionesTableAnnotationComposer,
          $$ActualizacionesTableCreateCompanionBuilder,
          $$ActualizacionesTableUpdateCompanionBuilder,
          (
            Actualizacion,
            BaseReferences<_$AppDatabase, $ActualizacionesTable, Actualizacion>,
          ),
          Actualizacion,
          PrefetchHooks Function()
        > {
  $$ActualizacionesTableTableManager(
    _$AppDatabase db,
    $ActualizacionesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActualizacionesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActualizacionesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActualizacionesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> coleccion = const Value.absent(),
                Value<DateTime> ultimaSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActualizacionesCompanion(
                coleccion: coleccion,
                ultimaSync: ultimaSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String coleccion,
                required DateTime ultimaSync,
                Value<int> rowid = const Value.absent(),
              }) => ActualizacionesCompanion.insert(
                coleccion: coleccion,
                ultimaSync: ultimaSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActualizacionesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActualizacionesTable,
      Actualizacion,
      $$ActualizacionesTableFilterComposer,
      $$ActualizacionesTableOrderingComposer,
      $$ActualizacionesTableAnnotationComposer,
      $$ActualizacionesTableCreateCompanionBuilder,
      $$ActualizacionesTableUpdateCompanionBuilder,
      (
        Actualizacion,
        BaseReferences<_$AppDatabase, $ActualizacionesTable, Actualizacion>,
      ),
      Actualizacion,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsuariosTableTableManager get usuarios =>
      $$UsuariosTableTableManager(_db, _db.usuarios);
  $$ActualizacionesTableTableManager get actualizaciones =>
      $$ActualizacionesTableTableManager(_db, _db.actualizaciones);
}
