import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/secure_storage.dart';
import '../services/api_service.dart';
import '../models/item.dart';
import 'auth_screen.dart';


// ------------------- HOME SCREEN -------------------
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoggedIn = false;
  List<Item> items = [];

  @override
  void initState() {
    super.initState();
    checkLoginStatusAndFetchItems();
  }

  void checkLoginStatusAndFetchItems() async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      final api = ApiService(token);
      try {
        final itemsData = await api.fetchItems();
        setState(() {
          isLoggedIn = true;
          items = itemsData;
        });
      } catch (e) {
        print("Failed to fetch items: $e");
      }
    } else {
      setState(() {
        isLoggedIn = false;
      });
    }
  }

  void _logout() async {
    await SecureStorage.clearToken();
    Navigator.pushReplacementNamed(context,'/auth');
      // MaterialPageRoute(builder: (_) => AuthScreen()),
  }

  void _showItemDetails(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.imageUrl != null)
              Image.network(item.imageUrl!, height: 200, fit: BoxFit.cover)
            else if (item.localImagePath != null)
              Image.file(File(item.localImagePath!), height: 200, fit: BoxFit.cover),
            SizedBox(height: 10),
            Text('Price: ₹${item.price.toStringAsFixed(2)}'),
            if (item.description != null) Text(item.description!),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  void _navigateToAddItemPage() async {
    final newItem = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddItemScreen()),
    );

    if (newItem != null && newItem is Item) {
      setState(() {
        items.add(newItem);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("E-Store")),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: Text('🛒', style: TextStyle(fontSize: 24)),
          onPressed: () {},
        ),
        actions: [
          isLoggedIn
              ? PopupMenuButton(
                  icon: Icon(Icons.account_circle, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'logout') _logout();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'logout', child: Text('Logout')),
                  ],
                )
              : Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
                      child: Text("Login", style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
                      child: Text("Signup", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
        ],
      ),
      body: items.isEmpty
          ? Center(child: Text("Welcome to the store"))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 4,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return GestureDetector(
                    onTap: () => _showItemDetails(item),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 6,
                                child: item.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                        child: Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.grey[300],
                                            child: Icon(Icons.broken_image, size: 80, color: Colors.grey[700]),
                                          ),
                                        ),
                                      )
                                    : item.localImagePath != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                            child: Image.file(
                                              File(item.localImagePath!),
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                            child: Icon(Icons.image, size: 80, color: Colors.grey[700]),
                                          ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '₹${item.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[700],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final token = await SecureStorage.getToken();
                                if (token == null) return;
                                final api = ApiService(token);
                                try {
                                  await api.deleteItem(item.id);
                                  setState(() {
                                    items.removeWhere((element) => element.id == item.id);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Item deleted')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Delete failed: $e')),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: isLoggedIn
          ? BottomAppBar(
              color: Colors.teal,
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: _navigateToAddItemPage,
              ),
            )
          : null,
    );
  }
}

// ------------------- ADD ITEM SCREEN -------------------
class AddItemScreen extends StatefulWidget {
  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final token = await SecureStorage.getToken();
      if (token == null) return;

      final api = ApiService(token);

      try {
        String? imageUrl;
        if (_image != null) {
          imageUrl = await api.uploadImage(_image!);
        }

        await api.createItem(
          name: _nameController.text.trim(),
          price: double.tryParse(_priceController.text.trim()) ?? 0,
          description: _descController.text.trim(),
          imageUrl: imageUrl,
        );

        final tempItem = Item(
          id: 'temp',
          name: _nameController.text.trim(),
          price: double.tryParse(_priceController.text.trim()) ?? 0,
          description: _descController.text.trim(),
          imageUrl: imageUrl,
          localImagePath: _image?.path,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Item added successfully")),
        );

        Navigator.pop(context, tempItem);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add item: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Item'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) => value!.isEmpty ? 'Enter item name' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter price' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              SizedBox(height: 10),
              _image != null ? Image.file(_image!, height: 150) : SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text('Pick Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text('Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
