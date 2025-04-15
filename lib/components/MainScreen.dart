import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../Product/product_list_screen.dart';
import '../home_screen.dart';
import '../profile/profile_screen.dart';
import '../Product/scanner_screen.dart';
import '../Product/product_form_screen.dart';
import '../Product/productViewScreen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String userEmail = "Carregando...";
  String? userId;
  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  void _getUserEmail() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email ?? "Email não disponível";
        userId = user.uid;

        // Inicializando a lista _screens após capturar userId
        _screens = [
          HomeScreen(userId: userId!),
          ProfileScreen(),
          ScannerScreen(),
          ProductFormScreen(),
          ProductViewScreen(),
        ];
      });
    } else {
      setState(() {
        userEmail = "Usuário não autenticado";
        userId = null;

        // Adicionando uma tela de fallback caso não tenha usuário autenticado
        _screens = [
          Center(child: Text("Faça login para acessar o conteúdo")),
        ];
      });
    }
  }

  void _openMenu() {
    showModalBottomSheet(
      context: this.context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/images/user.jpg'),
                ),
                const SizedBox(height: 10),
                Text(userEmail, style: const TextStyle(color: Colors.grey)),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text("Produtos com código de barras"),
                  onTap: () => _navigateToScreen(ProductViewScreen(), modalContext),
                ),
                ListTile(
                  leading: const Icon(Icons.insights_outlined),
                  title: const Text("Mais vendido"),
                  onTap: () => _navigateTo(1, modalContext),
                ),
                ListTile(
                  leading: const Icon(Icons.home_work_rounded),
                  title: const Text("Estoque"),
                  onTap: () => _navigateTo(2, modalContext),
                ),
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text("Histórico de Atividade"),
                  onTap: () => _navigateTo(3, modalContext),
                ),
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text("Lista de Produtos"),
                  onTap: () => _navigateToScreen(ProductListScreen(), modalContext),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout", style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(modalContext).pop();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateTo(int index, BuildContext modalContext) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.of(modalContext).pop();
  }

  void _navigateToScreen(Widget screen, BuildContext modalContext) {
    Navigator.of(modalContext).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens.isNotEmpty
          ? IndexedStack(
        index: _selectedIndex,
        children: _screens,
      )
          : Center(child: CircularProgressIndicator()), // Indicador de carregamento
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: GNav(
            backgroundColor: Colors.white,
            color: const Color(0xFF07063a),
            gap: 10,
            activeColor: Colors.white,
            tabBackgroundColor: Color(0xFF07063a),
            padding: const EdgeInsets.all(16),
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            tabs: const [
              GButton(icon: Icons.home, text: 'Casa'),
              GButton(icon: Icons.person, text: 'Usuários'),
              GButton(icon: Icons.qr_code, text: 'Produtos'),
              GButton(icon: Icons.add_shopping_cart, text: 'Adicionar'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openMenu,
        backgroundColor: Color(0xFF07063a),
        child: const Icon(Icons.menu, color: Colors.white),
      ),
    );
  }
}
