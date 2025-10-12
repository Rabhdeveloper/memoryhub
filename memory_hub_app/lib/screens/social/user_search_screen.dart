import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../config/api_config.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  bool _isLoading = false;

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _users = []);
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/social/users/search?query=$query'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _users = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e')),
      );
    }
  }

  Future<void> _toggleFollow(String userId, bool isFollowing) async {
    try {
      final headers = await _authService.getAuthHeaders();
      if (isFollowing) {
        await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/social/users/$userId/follow'),
          headers: headers,
        );
      } else {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/social/users/$userId/follow'),
          headers: headers,
        );
      }
      if (!mounted) return;
      _searchUsers(_searchController.text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _users = []);
                        },
                      )
                    : null,
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Search for users'
                              : 'No users found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              backgroundImage: user['avatar_url'] != null
                                  ? NetworkImage(ApiConfig.getAssetUrl(user['avatar_url']))
                                  : null,
                              child: user['avatar_url'] == null
                                  ? Text(
                                      (user['full_name'] ?? user['email'])[0]
                                          .toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    )
                                  : null,
                            ),
                            title: Text(user['full_name'] ?? user['email']),
                            subtitle: Text(
                              [
                                user['bio'],
                                user['city'],
                                user['country']
                              ].where((e) => e != null).join(' • '),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _toggleFollow(
                                user['id'],
                                user['is_following'] ?? false,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: user['is_following'] == true
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              child: Text(
                                user['is_following'] == true
                                    ? 'Unfollow'
                                    : 'Follow',
                              ),
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/profile/view',
                                arguments: user['id'],
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
