import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _generatePDF(BuildContext context, Map<String, dynamic> invoiceData) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(76 * PdfPageFormat.mm, double.infinity), // Formato para 76mm de largura
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Nome da Empresa", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text("Data: ${invoiceData['timestamp'].toDate()}"),
              pw.Text("Número da Fatura: ${invoiceData['invoiceId']}"),
              pw.Text("Nome do Cliente: ${invoiceData['customerName']}"),
              pw.SizedBox(height: 10),
              pw.Text("Produtos Comprados:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.ListView.builder(
                itemCount: (invoiceData['products'] as List).length,
                itemBuilder: (context, index) {
                  final product = invoiceData['products'][index];
                  return pw.Text(
                    "${product['name']} - ${product['quantity']} x Kz ${product['price']}",
                    style: pw.TextStyle(fontSize: 8),
                  );
                },
              ),
              pw.SizedBox(height: 10),
              pw.Text("Total: Kz ${invoiceData['total']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    // Baixa e imprime o PDF
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Center(child: Text("Erro: Usuário não autenticado."));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Faturas")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('Users')
            .doc(user.uid)
            .collection('Invoices')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar faturas!"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Nenhuma fatura encontrada."));
          }

          final invoices = snapshot.data!.docs;

          return ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              final invoiceData = invoice.data() as Map<String, dynamic>;

              return ListTile(
                title: Text("Fatura: ${invoice.id}"),
                subtitle: Text("Cliente: ${invoiceData['customerName']}"),
                trailing: ElevatedButton(
                  onPressed: () => _generatePDF(context, {...invoiceData, 'invoiceId': invoice.id}),
                  child: Text("Baixar PDF"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
