import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/publicacao_service.dart';
import 'perfil_page.dart';
import 'comentarios_page.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final texto = TextEditingController();
  final service = PublicacaoService();
  bool enviando = false;
  @override
  void dispose() {
    texto.dispose();
    super.dispose();
  }
  // Publica uma mensagem no mural.
  Future<void> publicar() async {
    if (texto.text.trim().isEmpty || enviando) return;
    setState(() => enviando = true);
    try {
      await service.publicar(texto.text);
      if (!mounted) return;
      texto.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao publicar: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => enviando = false);
      }
    }
  }
  // Abre a tela de comentários da publicação escolhida.
  void abrirComentarios(
    String publicacaoId,
    String textoPublicacao,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComentariosPage(
          publicacaoId: publicacaoId,
          tituloPublicacao: textoPublicacao,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mural da Turma'),
        actions: [
          IconButton(
            tooltip: 'Meu perfil',
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PerfilPage(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().sair();
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            children: [
              // Área de criação de publicações.
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: AuthService().acompanharPerfil(),
                      builder: (context, snapshot) {
                        final nome =
                            snapshot.data?.data()?['nome'] ??
                            FirebaseAuth.instance.currentUser?.email ??
                            'Aluno';
                        return Text(
                          'Olá, $nome!',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: texto,
                      maxLines: 2,
                      maxLength: 280,
                      decoration: const InputDecoration(
                        labelText: 'O que você está pensando?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: enviando ? null : publicar,
                        child: enviando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Publicar'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Lista de publicações do mural.
              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: service.acompanharMural(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erro ao carregar mural: ${snapshot.error}',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final posts = snapshot.data!.docs;
                    if (posts.isEmpty) {
                      return const Center(
                        child: Text(
                          'Ninguém publicou ainda. Seja o primeiro!',
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final documento = posts[index];
                        final post = documento.data();
                        final nome =
                            post['autorNome'] ?? 'Usuário';
                        final mensagem =
                            post['texto'] ?? '';
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(nome),
                            subtitle: Text(mensagem),
                            trailing: IconButton(
                              tooltip: 'Comentar',
                              icon: const Icon(
                                Icons.mode_comment_outlined,
                              ),
                              onPressed: () {
                                abrirComentarios(
                                  documento.id,
                                  mensagem,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}