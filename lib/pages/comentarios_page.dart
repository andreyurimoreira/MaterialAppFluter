import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/publicacao_service.dart';
class ComentariosPage extends StatefulWidget {
  final String publicacaoId;
  final String tituloPublicacao;
  const ComentariosPage({
    super.key,
    required this.publicacaoId,
    required this.tituloPublicacao,
  });
  @override
  State<ComentariosPage> createState() =>
      _ComentariosPageState();
}
class _ComentariosPageState extends State<ComentariosPage> {
  final controller = TextEditingController();
  final service = PublicacaoService();
  bool enviando = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  // Envia um comentário para o Firebase.
  Future<void> enviarComentario() async {
    final mensagem = controller.text.trim();
    if (mensagem.isEmpty || enviando) return;
    setState(() {
      enviando = true;
    });
    try {
      await service.comentar(
        widget.publicacaoId,
        mensagem,
      );
      if (!mounted) return;
      controller.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar comentário: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentários'),
      ),
      body: Column(
        children: [
          // Mostra a publicação original.
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Publicação',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.tituloPublicacao),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista os comentários em tempo real.
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: service.acompanharComentarios(
                widget.publicacaoId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Erro ao carregar os comentários.',
                    ),
                  );
                }
                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final comentarios =
                    snapshot.data?.docs ?? [];
                if (comentarios.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mode_comment_outlined,
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text('Nenhum comentário ainda.'),
                        Text('Seja o primeiro a comentar!'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  itemCount: comentarios.length,
                  itemBuilder: (context, index) {
                    final comentario =
                        comentarios[index].data();
                    final nome =
                        comentario['autorNome'] ?? 'Usuário';
                    final texto =
                        comentario['texto'] ?? '';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(nome),
                        subtitle: Text(texto),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Campo para escrever e enviar comentários.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 280,
                      decoration: const InputDecoration(
                        hintText: 'Escreva um comentário...',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      onSubmitted: (_) {
                        enviarComentario();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Enviar comentário',
                    onPressed:
                        enviando ? null : enviarComentario,
                    icon: enviando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}