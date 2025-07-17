import 'package:flutter/material.dart';
import 'package:myafmzd/screens/contrato_screen.dart';
import 'package:myafmzd/screens/distribuidores_screen.dart';
import 'package:myafmzd/screens/reportes/reportes_screen.dart';
import 'package:myafmzd/widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ContratoScreen(),
    ReportesScreen(),
    DistribuidoresScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Contrato'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
    BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Distribuidores'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: AppDrawer(),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: colorScheme.surface,
      ),
    );
  }
}
