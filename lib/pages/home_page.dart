import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:app_mahasiswa/services/firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();

  // Daftar controller untuk input field
  final List<TextEditingController> controllers = List.generate(
    3, // Field: Nama, NIM, Jurusan
        (_) => TextEditingController(),
  );

  // Opsi dropdown untuk jenis kelamin
  final List<String> genderOptions = ['Laki-Laki', 'Perempuan'];
  String selectedGender = 'Laki-Laki'; // Default pilihan dropdown

  final List<String> fieldLabels = [
    'Nama',
    'NIM',
    'Jurusan',
  ];

  // Dialog untuk Tambah/Edit Data
  void openDialog({String? docID, Map<String, dynamic>? currentData}) {
    // Jika edit data, isi controller dengan data saat ini
    if (currentData != null) {
      controllers[0].text = currentData['nama'];
      controllers[1].text = currentData['nim'];
      controllers[2].text = currentData['jurusan'];
      selectedGender = currentData['jenis_kelamin'] ?? 'Laki-Laki';
    } else {
      // Bersihkan controller jika menambah data baru
      for (var controller in controllers) {
        controller.clear();
      }
      selectedGender = 'Laki-Laki'; // Reset dropdown ke default
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docID == null ? 'Tambah Data' : 'Edit Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(
                fieldLabels.length,
                    (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      labelText: fieldLabels[index],
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButtonFormField<String>(
              value: genderOptions.contains(selectedGender) ? selectedGender : genderOptions.first,
              items: genderOptions
                  .map((gender) => DropdownMenuItem(
                value: gender,
                child: Text(gender),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedGender = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Jenis Kelamin',
                border: OutlineInputBorder(),
              ),
            ),
          ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (docID == null) {
                // Tambah data baru
                await firestoreService.AddData(
                  controllers[0].text,
                  controllers[1].text,
                  selectedGender,
                  controllers[2].text,
                );
              } else {
                // Update data
                await firestoreService.updateData(docID, {
                  'nama': controllers[0].text,
                  'nim': controllers[1].text,
                  'jenis_kelamin': selectedGender,
                  'jurusan': controllers[2].text,
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text("Simpan"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Batal"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Mahasiswa")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openDialog(), // Tambah data baru
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getDataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Tidak ada Data Mahasiswa"));
          }

          List<DocumentSnapshot> dataList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: dataList.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = dataList[index];
              String docID = document.id;

              Map<String, dynamic> data = document.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 4,
                child: ListTile(
                  title: Text(data['nama'] ?? "Tidak ada nama"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("NIM: ${data['nim']}"),
                      Text("Jenis Kelamin: ${data['jenis_kelamin']}"),
                      Text("Jurusan: ${data['jurusan']}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => openDialog(docID: docID, currentData: data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Konfirmasi sebelum menghapus data
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Hapus Data"),
                              content: const Text("Apakah Anda yakin ingin menghapus data ini?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text("Batal"),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text("Hapus"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await firestoreService.deleteData(docID);
                          }
                        },
                      ),
                    ],
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
