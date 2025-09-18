// lib/widgets/colaboradores_fab.dart
import 'package:flutter/material.dart';

/// FAB con menú contextual (MenuAnchor) para acciones rápidas.
/// - Ideal en desktop/web/tablet (pero funciona bien en móvil).
/// - Soporta textos e íconos personalizados.
/// - Cierra el menú automáticamente al elegir una acción.
/// - Desactiva ítems sin onPressed.
/// Requiere ThemeData(useMaterial3: true).
class FabConMenuAnchor extends StatefulWidget {
  const FabConMenuAnchor({
    super.key,
    this.onAgregar,
    this.onImportar,
    this.onExportar,
    // Textos personalizables (ES por defecto)
    this.txtAgregar = 'Nuevo colaborador',
    this.txtImportar = 'Importar CSV',
    this.txtExportar = 'Exportar CSV',
    // Íconos personalizables
    this.iconMain = Icons.menu,
    this.iconAgregar = Icons.person_add_alt_1,
    this.iconImportar = Icons.upload_file,
    this.iconExportar = Icons.download,
    // Tooltip del FAB
    this.fabTooltip = 'Abrir menú',
  });

  final VoidCallback? onAgregar;
  final VoidCallback? onImportar;
  final VoidCallback? onExportar;

  final String txtAgregar;
  final String txtImportar;
  final String txtExportar;

  final IconData iconMain;
  final IconData iconAgregar;
  final IconData iconImportar;
  final IconData iconExportar;

  final String fabTooltip;

  @override
  State<FabConMenuAnchor> createState() => _FabConMenuAnchorState();
}

class _FabConMenuAnchorState extends State<FabConMenuAnchor> {
  final MenuController _menuCtrl = MenuController();

  void _selectAndClose(VoidCallback? action) {
    // Cierra primero para que la UI sea inmediata (sobre todo en móvil)
    if (_menuCtrl.isOpen) _menuCtrl.close();
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Estilo base para los items del menú (Material 3)
    final ButtonStyle itemStyle = MenuItemButton.styleFrom(
      // Altos lo suficiente para ser “clicables” en desktop y táctiles en móvil
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      foregroundColor: cs.onSurface,
      textStyle: tt.bodyMedium,
      // Realce sutil al pasar mouse (desktop/web)
      overlayColor: cs.primary,
    );

    // Estilo de ítems destacados (ej. Agregar)
    final ButtonStyle primaryItemStyle = itemStyle.merge(
      MenuItemButton.styleFrom(foregroundColor: cs.primary),
    );

    return MenuAnchor(
      controller: _menuCtrl,
      // Desplaza el menú un poquito hacia arriba para no tapar el FAB
      alignmentOffset: const Offset(0, -12),
      // Builder del ancla (nuestro FAB)
      builder: (context, controller, child) {
        return Tooltip(
          message: widget.fabTooltip,
          preferBelow: false,
          child: FloatingActionButton(
            heroTag: 'fab_menu_colaboradores',
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            child: Icon(widget.iconMain),
          ),
        );
      },
      // Contenido del menú (MenuItemButton/SubmenuButton/etc.)
      menuChildren: [
        // Agregar (resaltado)
        MenuItemButton(
          leadingIcon: Icon(widget.iconAgregar),
          style: primaryItemStyle,
          onPressed: widget.onAgregar == null
              ? null
              : () => _selectAndClose(widget.onAgregar),
          child: Text(widget.txtAgregar),
        ),

        // Importar
        MenuItemButton(
          leadingIcon: Icon(widget.iconImportar),
          style: itemStyle,
          onPressed: widget.onImportar == null
              ? null
              : () => _selectAndClose(widget.onImportar),
          child: Text(widget.txtImportar),
        ),

        // Exportar
        MenuItemButton(
          leadingIcon: Icon(widget.iconExportar),
          style: itemStyle,
          onPressed: widget.onExportar == null
              ? null
              : () => _selectAndClose(widget.onExportar),
          child: Text(widget.txtExportar),
        ),
      ],
    );
  }
}
