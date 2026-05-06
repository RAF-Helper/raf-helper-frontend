import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/quick_action_card.dart';

// ── helpers ────────────────────────────────────────────────────────────────

String _mimeFromExtension(String? ext) {
  switch (ext?.toLowerCase()) {
    case 'pdf':
      return 'application/pdf';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'pptx':
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    default:
      return 'application/octet-stream';
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes Б';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} МБ';
}

IconData _iconFromMime(String mime) {
  if (mime.contains('pdf')) return Icons.picture_as_pdf;
  if (mime.contains('word') || mime.contains('document')) return Icons.description;
  if (mime.contains('presentation')) return Icons.slideshow;
  return Icons.insert_drive_file;
}

// ── ChatScreen ──────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _contextFiles = [];
  int? _currentChatId;
  bool _isLoading = false;
  bool _isSending = false;
  bool _showChatList = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final auth = context.read<AuthService>();
    try {
      final chats = await auth.api.getChats();
      setState(() {
        _chats = List<Map<String, dynamic>>.from(chats);
      });
    } catch (e) {
      debugPrint('Failed to load chats: $e');
    }
  }

  Future<void> _createChat({String title = 'Новый чат'}) async {
    final auth = context.read<AuthService>();
    try {
      final chat = await auth.api.createChat(title: title);
      final chatId = chat['id'] as int;
      await _loadChats();
      _selectChat(chatId);
    } catch (e) {
      _showError('Не удалось создать чат: $e');
    }
  }

  Future<void> _deleteChat(int chatId) async {
    final auth = context.read<AuthService>();
    try {
      await auth.api.deleteChat(chatId);
      if (_currentChatId == chatId) {
        setState(() {
          _currentChatId = null;
          _messages = [];
          _contextFiles = [];
        });
      }
      await _loadChats();
    } catch (e) {
      _showError('Не удалось удалить чат: $e');
    }
  }

  void _selectChat(int chatId) {
    setState(() {
      _currentChatId = chatId;
      _messages = [];
      _contextFiles = [];
      _showChatList = false;
    });
    _loadMessages(chatId);
    _loadContextFiles(chatId);
  }

  Future<void> _loadMessages(int chatId) async {
    final auth = context.read<AuthService>();
    setState(() => _isLoading = true);
    try {
      final msgs = await auth.api.getChatMessages(chatId);
      setState(() {
        _messages = List<Map<String, dynamic>>.from(msgs);
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Failed to load messages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadContextFiles(int chatId) async {
    final auth = context.read<AuthService>();
    try {
      final files = await auth.api.getContextFiles(chatId);
      setState(() {
        _contextFiles = List<Map<String, dynamic>>.from(files);
      });
    } catch (e) {
      debugPrint('Failed to load context files: $e');
    }
  }

  Future<void> _sendMessage(String text, {String? agent}) async {
    if (text.trim().isEmpty) return;

    final auth = context.read<AuthService>();

    if (_currentChatId == null) {
      await _createChat(title: text.length > 40 ? '${text.substring(0, 40)}...' : text);
      if (_currentChatId == null) return;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await auth.api.sendMessage(
        chatId: _currentChatId!,
        message: text,
        agent: agent,
      );
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response['content'] ?? 'Нет ответа',
          'agent_used': response['agent_used'],
        });
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Ошибка: не удалось получить ответ. $e',
        });
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'qa':
        _sendMessage('Помоги разобраться с материалами', agent: 'qa');
        break;
      case 'events':
        _sendMessage('Какие мероприятия сейчас актуальны?', agent: 'events');
        break;
      case 'staff':
        _sendMessage('Подскажи, к кому обратиться', agent: 'staff');
        break;
      case 'summarizer':
        _sendMessage('Сделай конспект по материалам', agent: 'summarizer');
        break;
      case 'abstract':
        _sendMessage('Помоги составить реферат', agent: 'abstract');
        break;
      case 'presentation':
        _sendMessage('Сделай презентацию по теме', agent: 'presentation');
        break;
    }
  }

  void _showFilesPanel() {
    if (_currentChatId == null) {
      _showError('Сначала создайте или выберите чат');
      return;
    }
    final auth = context.read<AuthService>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilesSheet(
        chatId: _currentChatId!,
        initialContextIds: _contextFiles.map((f) => f['id'] as int).toSet(),
        api: auth.api,
        onContextToggled: (file, added) {
          setState(() {
            if (added) {
              _contextFiles.add(file);
            } else {
              _contextFiles.removeWhere((f) => f['id'] == file['id']);
            }
          });
        },
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showChatList && _currentChatId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showChatList) {
          setState(() => _showChatList = false);
        } else if (_currentChatId != null) {
          setState(() {
            _currentChatId = null;
            _messages = [];
            _contextFiles = [];
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1C1E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => setState(() => _showChatList = !_showChatList),
          ),
          title: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'RAF Helper',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'Новый чат',
              onPressed: () => _createChat(),
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildChatArea(),
            if (_showChatList) ...[
              GestureDetector(
                onTap: () => setState(() => _showChatList = false),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black38),
              ),
              _buildChatList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2E),
        border: Border(right: BorderSide(color: Color(0xFF3C3C3E))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Чаты',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _createChat(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF3C3C3E)),
          Expanded(
            child: _chats.isEmpty
                ? const Center(
                    child: Text('Нет чатов', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final chatId = chat['id'] as int;
                      final isSelected = chatId == _currentChatId;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor:
                            const Color(0xFF0A84FF).withValues(alpha: 0.15),
                        title: Text(
                          chat['title'] ?? 'Чат #$chatId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _deleteChat(chatId),
                        ),
                        onTap: () => _selectChat(chatId),
                      );
                    },
                  ),
          ),
          const Divider(height: 1, color: Color(0xFF3C3C3E)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            title: const Text(
              'Выйти из аккаунта',
              style: TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
            onTap: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Column(
      children: [
        if (_currentChatId == null && _messages.isEmpty)
          Expanded(child: _buildWelcome())
        else if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isSending) {
                  return const ChatBubble(
                    message: '...',
                    isUser: false,
                    isLoading: true,
                  );
                }
                final message = _messages[index];
                return ChatBubble(
                  message: message['content'] ?? '',
                  isUser: message['role'] == 'user',
                );
              },
            ),
          ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.school, size: 48, color: Color(0xFF0A84FF)),
                SizedBox(height: 12),
                Text(
                  'Привет! Я RAF Helper — ассистент для студентов БГУ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Задай вопрос или выбери тему ниже.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              QuickActionCard(
                title: 'Вопросы\nпо материалам',
                subtitle: 'Ответы на основе загруженных лекций и книг',
                icon: Icons.menu_book,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
                ),
                onTap: () => _handleQuickAction('qa'),
              ),
              QuickActionCard(
                title: 'Мероприятия',
                subtitle: 'Актуальные события, даты, условия участия',
                icon: Icons.event,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFE91E63)],
                ),
                onTap: () => _handleQuickAction('events'),
              ),
              QuickActionCard(
                title: 'Преподаватели',
                subtitle: 'Кто ведёт, где найти, к кому обратиться',
                icon: Icons.people,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                ),
                onTap: () => _handleQuickAction('staff'),
              ),
              QuickActionCard(
                title: 'Конспект',
                subtitle: 'Краткое, обычное или глубокое резюме',
                icon: Icons.summarize,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                ),
                onTap: () => _handleQuickAction('summarizer'),
              ),
              QuickActionCard(
                title: 'Реферат',
                subtitle: 'Составление реферата по материалам',
                icon: Icons.article,
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                ),
                onTap: () => _handleQuickAction('abstract'),
              ),
              QuickActionCard(
                title: 'Презентация',
                subtitle: 'Генерация слайдов по теме',
                icon: Icons.slideshow,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                ),
                onTap: () => _handleQuickAction('presentation'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final hasContext = _contextFiles.isNotEmpty && _currentChatId != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2E),
        border: Border(top: BorderSide(color: Color(0xFF3C3C3E), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasContext) ...[
              _buildContextChips(),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.attach_file,
                    color: hasContext ? const Color(0xFF0A84FF) : Colors.grey,
                  ),
                  tooltip: 'Файлы в контексте',
                  onPressed: _showFilesPanel,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Напишите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF3C3C3E),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (text) => _sendMessage(text),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A84FF),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isSending
                        ? null
                        : () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextChips() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _contextFiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final file = _contextFiles[i];
          final fileId = file['id'] as int;
          final name = file['original_name'] as String? ?? 'Файл';
          final label = name.length > 20 ? '${name.substring(0, 20)}…' : name;
          return Chip(
            label: Text(label, style: const TextStyle(fontSize: 11)),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () async {
              final auth = context.read<AuthService>();
              try {
                await auth.api.removeContextFile(_currentChatId!, fileId);
                setState(() {
                  _contextFiles.removeWhere((f) => f['id'] == fileId);
                });
              } catch (e) {
                _showError('Ошибка: $e');
              }
            },
            backgroundColor: const Color(0xFF0A84FF).withValues(alpha: 0.15),
            side: const BorderSide(color: Color(0xFF0A84FF), width: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ── _FilesSheet ──────────────────────────────────────────────────────────────

class _FilesSheet extends StatefulWidget {
  final int chatId;
  final Set<int> initialContextIds;
  final ApiService api;
  final void Function(Map<String, dynamic> file, bool added) onContextToggled;

  const _FilesSheet({
    required this.chatId,
    required this.initialContextIds,
    required this.api,
    required this.onContextToggled,
  });

  @override
  State<_FilesSheet> createState() => _FilesSheetState();
}

class _FilesSheetState extends State<_FilesSheet> {
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;
  bool _isUploading = false;
  late Set<int> _contextIds;

  @override
  void initState() {
    super.initState();
    _contextIds = Set<int>.from(widget.initialContextIds);
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files = await widget.api.getFiles();
      if (mounted) {
        setState(() {
          _files = List<Map<String, dynamic>>.from(files);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'pptx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.bytes == null) return;

    setState(() => _isUploading = true);
    try {
      final mime = _mimeFromExtension(picked.extension);
      final resp =
          await widget.api.uploadFileBytes(picked.bytes!, picked.name, mime);
      final newFile = Map<String, dynamic>.from(resp['file'] as Map);
      if (mounted) {
        setState(() {
          _files.add(newFile);
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _toggle(Map<String, dynamic> file, bool toAdd) async {
    final fileId = file['id'] as int;
    try {
      if (toAdd) {
        await widget.api.addContextFile(widget.chatId, fileId);
        setState(() => _contextIds.add(fileId));
      } else {
        await widget.api.removeContextFile(widget.chatId, fileId);
        setState(() => _contextIds.remove(fileId));
      }
      widget.onContextToggled(file, toAdd);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Файлы',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton.icon(
                        onPressed: _pickAndUpload,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Загрузить'),
                      ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF3C3C3E)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Нет загруженных файлов',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'PDF, DOCX, PPTX — до 50 МБ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (_, i) {
                          final file = _files[i];
                          final fileId = file['id'] as int;
                          final inContext = _contextIds.contains(fileId);
                          final name =
                              file['original_name'] as String? ?? 'Файл';
                          final size = file['size'] as int? ?? 0;
                          final isIndexed =
                              file['is_indexed'] as bool? ?? false;
                          final mime = file['mime_type'] as String? ?? '';

                          return CheckboxListTile(
                            value: inContext,
                            secondary: Icon(_iconFromMime(mime),
                                color: Colors.grey),
                            title: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  _formatSize(size),
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                                if (!isIndexed) ...[
                                  const SizedBox(width: 8),
                                  const Text(
                                    '⏳ индексируется...',
                                    style: TextStyle(
                                        color: Colors.orange, fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                            onChanged: isIndexed
                                ? (val) => _toggle(file, val ?? false)
                                : null,
                            activeColor: const Color(0xFF0A84FF),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
