// lib/pages/admin_page.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/auth_service.dart';
import '../services/quiz_service.dart';
import '../theme.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final AuthService auth = AuthService();
  final QuizService quizService = QuizService();

  bool loading = true;
  int tabIndex = 0;

  // Questions
  List<Map<String, dynamic>> questions = [];
  bool questionsLoading = true;
  final _questionFormKey = GlobalKey<FormState>();
  final TextEditingController _qText = TextEditingController();
  final TextEditingController _optA = TextEditingController();
  final TextEditingController _optB = TextEditingController();
  final TextEditingController _optC = TextEditingController();
  final TextEditingController _optD = TextEditingController();
  String _correctOpt = 'A';
  String _difficulty = 'easy';
  String? _editingQuestionId;

  // Users
  List<Map<String, dynamic>> users = [];
  bool usersLoading = true;

  // Leaderboard
  List<Map<String, dynamic>> leaderboard = [];
  bool leaderboardLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadQuestions(), _loadUsers(), _loadLeaderboard()]);
    setState(() => loading = false);
  }

  // ---------------- Questions ----------------
  Future<void> _loadQuestions() async {
    setState(() => questionsLoading = true);
    final List res = await quizService.supabase.from('questions').select().order('created_at', ascending: false);
    questions = List<Map<String, dynamic>>.from(res);
    setState(() => questionsLoading = false);
  }

  Future<void> _createOrUpdateQuestion() async {
    if (!_questionFormKey.currentState!.validate()) return;

    final options = [
      _optA.text.trim(),
      _optB.text.trim(),
      _optC.text.trim(),
      _optD.text.trim(),
    ];
    final correct = {
      'A': options[0],
      'B': options[1],
      'C': options[2],
      'D': options[3],
    }[_correctOpt]!;

    final payload = {
      'text': _qText.text.trim(),
      'options': options,
      'answer': correct,
      'difficulty': _difficulty,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (_editingQuestionId == null) {
      // insert
      await quizService.supabase.from('questions').insert(payload);
    } else {
      // update
      await quizService.supabase.from('questions').update(payload).eq('id', _editingQuestionId);
    }

    // reset form
    _clearQuestionForm();
    await _loadQuestions();
  }

  void _clearQuestionForm() {
    _qText.clear();
    _optA.clear();
    _optB.clear();
    _optC.clear();
    _optD.clear();
    _correctOpt = 'A';
    _difficulty = 'easy';
    _editingQuestionId = null;
    setState(() {});
  }

  Future<void> _editQuestion(Map<String, dynamic> q) async {
    _editingQuestionId = q['id'] as String?;
    _qText.text = q['text'] ?? '';
    final opts = List<String>.from(q['options'] ?? []);
    _optA.text = opts.length > 0 ? opts[0] : '';
    _optB.text = opts.length > 1 ? opts[1] : '';
    _optC.text = opts.length > 2 ? opts[2] : '';
    _optD.text = opts.length > 3 ? opts[3] : '';
    _correctOpt = {'A': opts.isNotEmpty && q['answer'] == opts[0], 'B': opts.length>1 && q['answer']==opts[1],
                   'C': opts.length>2 && q['answer']==opts[2], 'D': opts.length>3 && q['answer']==opts[3]}
                  .entries.firstWhere((e) => e.value, orElse: ()=>MapEntry('A', true)).key;
    _difficulty = q['difficulty'] ?? 'easy';
    setState(() {});
  }

  Future<void> _deleteQuestion(String id) async {
    await quizService.supabase.from('questions').delete().eq('id', id);
    await _loadQuestions();
  }

  // ---------------- Users ----------------
  Future<void> _loadUsers() async {
    setState(() => usersLoading = true);
    final List res = await auth.supabase.from('users').select('id,username,created_at,role').order('created_at', ascending: false).limit(200);
    users = List<Map<String, dynamic>>.from(res);
    setState(() => usersLoading = false);
  }

  Future<void> _setUserRole(String userId, String role) async {
    await auth.setUserRole(userId: userId, role: role);
    await _loadUsers();
  }

  // ---------------- Leaderboard ----------------
  Future<void> _loadLeaderboard() async {
    setState(() => leaderboardLoading = true);
    final List res = await quizService.supabase.from('leaderboard').select('id,user_id,score,level,time_ms,users(username)').order('time_ms', ascending: true).limit(200);
    leaderboard = List<Map<String, dynamic>>.from(res);
    setState(() => leaderboardLoading = false);
  }

  Future<void> _deleteLeaderboardEntry(String id) async {
    await quizService.supabase.from('leaderboard').delete().eq('id', id);
    await _loadLeaderboard();
  }

  Future<void> _deleteAllForUser(String userId) async {
    await quizService.supabase.from('leaderboard').delete().eq('user_id', userId);
    await _loadLeaderboard();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(tabs: [
            Tab(text: 'Questions'),
            Tab(text: 'Users'),
            Tab(text: 'Leaderboard'),
          ]),
        ),
        body: TabBarView(children: [
          _questionsTab(),
          _usersTab(),
          _leaderboardAdminTab(),
        ]),
      ),
    );
  }

  Widget _questionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // left: form
          Expanded(
            flex: 2,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _questionFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_editingQuestionId == null ? 'Create Question' : 'Edit Question', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      const SizedBox(height: 12),
                      TextFormField(controller: _qText, maxLines: 3, decoration: const InputDecoration(labelText: 'Question text'), validator: (v) => v==null||v.trim().isEmpty ? 'Required' : null),
                      const SizedBox(height: 8),
                      TextFormField(controller: _optA, decoration: const InputDecoration(labelText: 'Option A'), validator: (v) => v==null||v.trim().isEmpty ? 'Required' : null),
                      const SizedBox(height: 6),
                      TextFormField(controller: _optB, decoration: const InputDecoration(labelText: 'Option B'), validator: (v) => v==null||v.trim().isEmpty ? 'Required' : null),
                      const SizedBox(height: 6),
                      TextFormField(controller: _optC, decoration: const InputDecoration(labelText: 'Option C'), validator: (v) => v==null||v.trim().isEmpty ? 'Required' : null),
                      const SizedBox(height: 6),
                      TextFormField(controller: _optD, decoration: const InputDecoration(labelText: 'Option D'), validator: (v) => v==null||v.trim().isEmpty ? 'Required' : null),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Correct: '),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _correctOpt,
                            items: const [DropdownMenuItem(value: 'A', child: Text('A')), DropdownMenuItem(value: 'B', child: Text('B')), DropdownMenuItem(value: 'C', child: Text('C')), DropdownMenuItem(value: 'D', child: Text('D'))],
                            onChanged: (v) => setState(() => _correctOpt = v ?? 'A'),
                          ),
                          const SizedBox(width: 24),
                          const Text('Difficulty: '),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _difficulty,
                            items: const [
                              DropdownMenuItem(value: 'easy', child: Text('Easy')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'hard', child: Text('Hard')),
                            ],
                            onChanged: (v) => setState(() => _difficulty = v ?? 'easy'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _createOrUpdateQuestion,
                            child: Text(_editingQuestionId == null ? 'Create' : 'Save'),
                          ),
                          const SizedBox(width: 12),
                          TextButton(onPressed: _clearQuestionForm, child: const Text('Clear')),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // right: list
          Expanded(
            flex: 3,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: questionsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        separatorBuilder: (_, __) => const Divider(),
                        itemCount: questions.length,
                        itemBuilder: (_, i) {
                          final q = questions[i];
                          final opts = List<String>.from(q['options'] ?? []);
                          return ListTile(
                            title: Text(q['text'] ?? ''),
                            subtitle: Text('Difficulty: ${q['difficulty'] ?? 'unknown'}'),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editQuestion(q)),
                                IconButton(icon: const Icon(Icons.delete), onPressed: () async {
                                  final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                                    title: const Text('Delete question?'),
                                    content: const Text('This will delete the question but will NOT modify existing leaderboard entries.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('Delete')),
                                    ],
                                  ));
                                  if (ok == true) await _deleteQuestion(q['id'] as String);
                                }),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _usersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: usersLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              separatorBuilder: (_, __) => const Divider(),
              itemCount: users.length,
              itemBuilder: (_, i) {
                final u = users[i];
                final role = u['role'] ?? 'user';
                return ListTile(
                  title: Text(u['username'] ?? 'Unknown'),
                  subtitle: Text('Role: $role'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (choice) async {
                      if (choice == 'delete') {
                        final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                          title: const Text('Delete user?'),
                          content: const Text('This will remove the user record (this action cannot be undone).'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('Delete')),
                          ],
                        ));
                        if (ok == true) {
                          await auth.supabase.from('users').delete().eq('id', u['id']);
                          await _loadUsers();
                        }
                        return;
                      }

                      // set role choices
                      await _setUserRole(u['id'] as String, choice);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'user', child: Text('Set user')),
                      const PopupMenuItem(value: 'admin', child: Text('Set admin')),
                      const PopupMenuItem(value: 'blocked', child: Text('Set blocked (cannot play)')),
                      const PopupMenuItem(value: 'blocked_lb', child: Text('Set blocked_lb (no leaderboard)')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete user', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _leaderboardAdminTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: leaderboardLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              separatorBuilder: (_, __) => const Divider(),
              itemCount: leaderboard.length,
              itemBuilder: (_, i) {
                final e = leaderboard[i];
                final username = e['users']?['username'] ?? 'Unknown';
                final timeText = e['time_ms'] != null ? '${(e['time_ms'] / 1000).toStringAsFixed(2)}s' : '--';
                return ListTile(
                  leading: CircleAvatar(child: Text('${i+1}')),
                  title: Text(username),
                  subtitle: Text('Level: ${e['level']}  •  Score: ${e['score']}'),
                  trailing: Wrap(
                    children: [
                      IconButton(icon: const Icon(Icons.delete_forever), onPressed: () async {
                        final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                          title: const Text('Delete leaderboard entry?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('Delete')),
                          ],
                        ));
                        if (ok == true) await _deleteLeaderboardEntry(e['id'] as String);
                      }),
                      IconButton(icon: const Icon(Icons.person_remove), onPressed: () async {
                        final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                          title: const Text('Delete all entries for this user?'),
                          content: Text('Remove all leaderboard records for $username'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('Delete All')),
                          ],
                        ));
                        if (ok == true) await _deleteAllForUser(e['user_id'] as String);
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
