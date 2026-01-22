import 'package:fiscagis/core/theme/app_colors.dart';
import 'package:fiscagis/features/fiscalizacion/fiscalizacion_screen.dart';
import 'package:fiscagis/features/fiscalizacion/fiscalizaciones_list_screen.dart'; // Fixed import
// New Imports
import 'package:fiscagis/features/sync/sync_screen.dart';
import 'package:fiscagis/features/search/search_predio_screen.dart';
import 'package:fiscagis/features/map/map_screen.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("Administrador"),
              accountEmail: Text("admin@fiscagis.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.white,
                child: Text("A", style: TextStyle(fontSize: 24.0, color: AppColors.primary)),
              ),
              decoration: BoxDecoration(color: AppColors.primary),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.of(context).pop(); // Go back to login
              },
            ),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.white, Colors.grey.shade100],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bienvenido, Admin',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seleccione una opción para comenzar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    icon: Icons.home_work,
                    title: 'Datos del Predio',
                    color: Colors.blueAccent,
                    onTap: () => _navigateToFiscalizacion(context, 0),
                  ),
                  _DashboardCard(
                    icon: Icons.construction,
                    title: 'Construcciones',
                    color: Colors.orangeAccent,
                    onTap: () => _navigateToFiscalizacion(context, 1),
                  ),
                  _DashboardCard(
                    icon: Icons.camera_alt,
                    title: 'Fotografía',
                    color: Colors.purpleAccent,
                    onTap: () => _navigateToFiscalizacion(context, 2),
                  ),
                   _DashboardCard(
                    icon: Icons.map,
                    title: 'Mapa General',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
                    },
                  ),
                   _DashboardCard(
                    icon: Icons.search,
                    title: 'Buscar Predio',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPredioScreen()));
                    },
                  ),
                   _DashboardCard(
                    icon: Icons.sync,
                    title: 'Sincronizar Data',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncScreen()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFiscalizacion(BuildContext context, int initialIndex) {
    // Now we redirect to List Screen effectively acting as the main entry
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FiscalizacionesListScreen(),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
