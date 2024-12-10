import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Get collection reference
  final CollectionReference notes =
  FirebaseFirestore.instance.collection('Data Mahasiswa');

  // Create Data Mahasiswa
  Future<void> AddData(String nama, String nim, String jk, String jurusan) {
    return notes.add({
      'nama': nama,
      'nim': nim,
      'jenis_kelamin': jk,
      'jurusan': jurusan,
      'timestamp': Timestamp.now(), // Tambahkan timestamp untuk sorting
    });
  }

  // Read Data Mahasiswa
  Stream<QuerySnapshot> getDataStream() {
    // Mengembalikan stream dari Firestore
    return notes.orderBy('timestamp', descending: true).snapshots();
  }

  // Update Data Mahasiswa (Opsional, tambahkan jika diperlukan)
  Future<void> updateData(String docID, Map<String, dynamic> newData) {
    return notes.doc(docID).update(newData);
  }

  // Delete Data Mahasiswa
  Future<void> deleteData(String docID) {
    return notes.doc(docID).delete();
  }
}
