import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Map<String, dynamic>>> _futureCashiers;

  @override
  void initState() {
    super.initState();
    _futureCashiers = _fetchCashiers();
  }

  Future<List<Map<String, dynamic>>> _fetchCashiers() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('Cashiers')
          .get();

      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['cashierId'] = doc.id; // Adiciona o ID do documento
        return data;
      }).toList();
    } catch (e) {
      print("Erro ao buscar cashiers: $e");
      return [];
    }
  }

  Future<void> _deleteCashier(String cashierId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('Cashiers')
          .doc(cashierId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cashier excluído com sucesso!')),
      );

      _refreshData();
    } catch (e) {
      print("Erro ao excluir cashier: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir cashier.')),
      );
    }
  }

  void _refreshData() {
    setState(() {
      _futureCashiers = _fetchCashiers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: const Color(0xFF07063a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureCashiers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Nenhum cashier cadastrado."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var cashier = snapshot.data![index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.person, color:  const Color(0xFF07063a)),
                  title: Text(cashier['name'] ?? 'Nome não disponível'),
                  subtitle: Text("ID: ${cashier['cashierId']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCashier(cashier['cashierId']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
