// lib/pages/admin_page.dart
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  final AdminService admin = AdminService();
  late TabController _tabs;

  // Questions
  List<Map<String, dynamic>> questions = [];
  bool qLoading = true;

  // Users
  List<Map<String, dynamic>> users = [];
  bool uLoading = true;

  // Leaderboard
  List<Map<String, dynamic>> leaderboard = [];
  bool lLoading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadQuestions(), _loadUsers(), _loadLeaderboard()]);
  }

  Future<void> _loadQuestions() async {
    setState(() => qLoading = true);
    try {
      questions = await admin.fetchQuestions();
    } catch (e) {
      questions = [];
    } finally {
      setState(() => qLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => uLoading = true);
    try {
      users = await admin.fetchUsers();
    } catch (e) {
      users = [];
    } finally {
      setState(() => uLoading = false);
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => lLoading = true);
    try {
      final res = await admin.supabase
          .from('leaderboard')
          .select('id, score, time_ms, level, users(username, id)')
          .order('time_ms', ascending: true)
          .limit(200);
      leaderboard = List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      leaderboard = [];
    } finally {
      setState(() => lLoading = false);
    }
  }

  // Add question dialog
  Future<void> _showAddQuestion() async {
    final _formKey = GlobalKey<FormState>();
    final textCtrl = TextEditingController();
    final opt1 = TextEditingController();
    final opt2 = TextEditingController();
    final opt3 = TextEditingController();
    final opt4 = TextEditingController();
    String difficulty = 'easy';
    String? answer;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Question'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: textCtrl, decoration: const InputDecoration(labelText: 'Question')),
                const SizedBox(height: 8),
                TextFormField(controller: opt1, decoration: const InputDecoration(labelText: 'Option 1')),
                TextFormField(controller: opt2, decoration: const InputDecoration(labelText: 'Option 2')),
                TextFormField(controller: opt3, decoration: const InputDecoration(labelText: 'Option 3')),
                TextFormField(controller: opt4, decoration: const InputDecoration(labelText: 'Option 4')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: difficulty,
                  items: ['easy', 'medium', 'hard'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                  onChanged: (v) => difficulty = v ?? difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                ),
                const SizedBox(height: 8),
                // simple answer selector: pick option index
                DropdownButtonFormField<int>(
                  value: null,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Option 1')),
                    DropdownMenuItem(value: 2, child: Text('Option 2')),
                    DropdownMenuItem(value: 3, child: Text('Option 3')),
                    DropdownMenuItem(value: 4, child: Text('Option 4')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    answer = v == 1
                        ? opt1.text
                        : v == 2
                            ? opt2.text
                            : v == 3
                                ? opt3.text
                                : opt4.text;
                  },
                  hint: const Text('Select correct option'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final opts = [opt1.text, opt2.text, opt3.text, opt4.text].where((s) => s.trim().isNotEmpty).toList();
              if (textCtrl.text.trim().isEmpty || opts.length < 2) {
                // basic validation
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide question text and at least 2 options.')));
                return;
              }
              final corr = answer ?? (opts.isNotEmpty ? opts.first : '');
              await admin.addQuestion(text: textCtrl.text.trim(), options: opts, answer: corr, difficulty: difficulty);
              Navigator.pop(context);
              await _loadQuestions();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _questionsView() {
    if (qLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Questions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _showAddQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: questions.length,
            itemBuilder: (_, i) {
              final q = questions[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(q['text'] ?? ''),
                  subtitle: Text('Difficulty: ${q['difficulty'] ?? 'unknown'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_forever),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Confirm'),
                              content: const Text('Delete this question? This action cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await admin.deleteQuestion(q['id']);
                            await _loadQuestions();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _usersView() {
    if (uLoading) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u = users[i];
        final role = u['role'] ?? 'user';
        final bannedFromLeaderboard = u['banned_from_leaderboard'] ?? false;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(u['username'] ?? 'Unknown'),
            subtitle: Text('Role: $role'),
            trailing: Wrap(
              spacing: 6,
              children: [
                IconButton(
                  icon: Icon(bannedFromLeaderboard ? Icons.lock_open : Icons.block),
                  tooltip: bannedFromLeaderboard ? 'Unban from leaderboard' : 'Ban from leaderboard',
                  onPressed: () async {
                    await admin.setLeaderboardBan(u['id'], !(bannedFromLeaderboard as bool));
                    await _loadUsers();
                    await _loadLeaderboard();
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'delete') {
                      // make the user role = 'banned' (soft server-side ban)
                      await admin.updateUserRole(u['id'], 'banned');
                    } else {
                      await admin.updateUserRole(u['id'], val);
                    }
                    await _loadUsers();
                    await _loadLeaderboard();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'user', child: Text('Set as USER')),
                    PopupMenuItem(value: 'admin', child: Text('Set as ADMIN')),
                    PopupMenuItem(value: 'soft_blocked', child: Text('Set as SOFT_BLOCKED')),
                    PopupMenuItem(value: 'banned', child: Text('Set as BANNED')),
                    PopupMenuItem(value: 'delete', child: Text('Ban (set role = BANNED)')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _leaderboardView() {
    if (lLoading) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      itemCount: leaderboard.length,
      itemBuilder: (_, i) {
        final e = leaderboard[i];
        final username = e['users']?['username'] ?? 'Unknown';
        final entryId = e['id'];
        final timeMs = e['time_ms'] as int?;
        final displayTime = timeMs != null ? '${(timeMs / 1000).toStringAsFixed(2)}s' : '--';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text('#${i + 1} — $username'),
            subtitle: Text('Level: ${e['level']}  •  Score: ${e['score']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(displayTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Confirm'),
                        content: const Text('Delete this leaderboard entry?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await admin.deleteLeaderboardEntry(entryId);
                      await _loadLeaderboard();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provide a roomy layout so lists have enough space
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Questions'), Tab(text: 'Users'), Tab(text: 'Leaderboard')],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: TabBarView(
          controller: _tabs,
          children: [
            // Each view expects to take available height
            SizedBox(
              height: double.infinity,
              child: _questionsView(),
            ),
            SizedBox(
              height: double.infinity,
              child: _usersView(),
            ),
            SizedBox(
              height: double.infinity,
              child: _leaderboardView(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.refresh),
        onPressed: _refreshAll,
      ),
    );
  }
}
