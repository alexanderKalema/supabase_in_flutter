import 'package:flutter/material.dart';
import 'package:flutter_supabase/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _user = Supabase.instance.client.auth.currentUser;
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('items')
          .select();

      setState(() {
        _data = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addItem(String title, String description) async {
    try {
      await Supabase.instance.client
          .from('items')
          .insert({
        'title': title,
        'description': description,
        'user_id': _user?.id, // Optional: associate item with user
      });

      // Refresh the list after adding a new item
      _fetchData();
    } catch (error) {
      print(error.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
  Future<void> callFunction() async {
    try{
      final response = await Supabase.instance.client
          .rpc('function_name', params: {'param1': 'value'});
    } catch(e){
      // handle error
    }
  }
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _showAddItemDialog() {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty) {
                _addItem(
                  _titleController.text.trim(),
                  _descriptionController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home - ${_user?.email ?? "User"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
          ? const Center(child: Text('No items found'))
          : ListView.builder(
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final item = _data[index];
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: ListTile(
              title: Text(item['title'] ?? ''),
              subtitle: Text(item['description'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  try {
                    await Supabase.instance.client
                        .from('items')
                        .delete()
                        .match({'id': item['id']});
                    _fetchData();
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.toString())),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}