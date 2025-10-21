// FILE: lib/pages/admin_page.dart
// Admin UI page with three tabs: Questions, Users, Leaderboard management


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
questions = await admin.fetchQuestions();
setState(() => qLoading = false);
}


Future<void> _loadUsers() async {
setState(() => uLoading = true);
users = await admin.fetchUsers();
setState(() => uLoading = false);
}


Future<void> _loadLeaderboard() async {
setState(() => lLoading = true);
// fetch top 200 for admin view (includes user join)
final res = await admin.supabase.from('leaderboard').select('id, score, time_ms, level, users(username, id)').order('time_ms', ascending: true).limit(200);
leaderboard = List<Map<String, dynamic>>.from(res as List);
setState(() => lLoading = false);
}
}
