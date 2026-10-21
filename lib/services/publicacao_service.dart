import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublicacaoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> acompanharMural() {
    return _db
        .collection('publicacoes')
        .orderBy('data', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> acompanharMinhas() {
    return _db
        .collection('publicacoes')
        .where('autorId', isEqualTo: _auth.currentUser!.uid)
        .snapshots();
  }

  Future<void> publicar(String texto) async {
    final usuario = _auth.currentUser!;
    final perfil = await _db.collection('usuarios').doc(usuario.uid).get();
    if (!perfil.exists) {
      throw Exception('Perfil não encontrado. Faça login novamente.');
    }
    final nome = (perfil.data()?['nome'] as String?) ?? 'Usuário';
    await _db.collection('publicacoes').add({
      'texto': texto.trim(),
      'autorId': usuario.uid,
      'autorNome': nome,
      'data': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluir(String id) =>
      _db.collection('publicacoes').doc(id).delete();

  // --- Movidas para dentro da classe ---

  Stream<QuerySnapshot<Map<String, dynamic>>> acompanharComentarios(String publicacaoId) {
    return _db
        .collection('publicacoes')
        .doc(publicacaoId)
        .collection('comentarios')
        .orderBy('data')
        .snapshots();
  }

  // Salva um comentário no Firestore.
  Future<void> comentar(
    String publicacaoId,
    String texto,
  ) async {
    final usuario = _auth.currentUser;
    if (usuario == null) {
      throw Exception(
        'Você precisa estar logado para comentar.',
      );
    }
    final textoLimpo = texto.trim();
    if (textoLimpo.isEmpty) {
      throw Exception('Digite um comentário.');
    }
    final perfil = await _db
        .collection('usuarios')
        .doc(usuario.uid)
        .get();
    final nome =
        (perfil.data()?['nome'] as String?) ??
        usuario.email ??
        'Usuário';
    await _db
        .collection('publicacoes')
        .doc(publicacaoId)
        .collection('comentarios')
        .add({
      'texto': textoLimpo,
      'autorId': usuario.uid,
      'autorNome': nome,
      'data': FieldValue.serverTimestamp(),
    });
  }
}