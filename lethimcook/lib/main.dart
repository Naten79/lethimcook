import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_recipe_page.dart';
import 'recipe_view_page.dart';   // ✅ bon import
import 'database.dart';
import 'recipe.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://srysgkonajcpddbtjczi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNyeXNna29uYWpjcGRkYnRqY3ppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2Mjg2ODEsImV4cCI6MjA5MDIwNDY4MX0.coGk83rmvqWbI__0nlbt-ZAvwGwEfguxTrNoQ2pSi_Q',
  );
  runApp(LetHimCookApp());
}

class LetHimCookApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LetHimCook',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.red.shade50,
      ),
      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  final _recipeListKey = GlobalKey<_RecipeListPageState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          RecipeListPage(key: _recipeListKey),
          AboutPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.red,
        onTap: (index) => setState(() => currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Mes recettes'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
        ],
      ),
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.red,
              child: Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddRecipePage()),
                );
                if (result == true) _recipeListKey.currentState?.loadRecipes();
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({Key? key}) : super(key: key);

  @override
  _RecipeListPageState createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  List<Recipe> recipes = [];
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    loadRecipes();
  }

  Future<void> loadRecipes() async {
    final data = await RecipeDatabase.instance.getAllRecipes();
    if (mounted) setState(() => recipes = data);
  }

  @override
  Widget build(BuildContext context) {
    List<Recipe> filteredRecipes = selectedFilter == 'all'
        ? recipes
        : recipes.where((r) => r.type.toLowerCase() == selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Mes recettes'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              filterButton('all', 'Toutes'),
              filterButton('entrée', 'Entrée'),
              filterButton('plat', 'Plat'),
              filterButton('dessert', 'Dessert'),
              filterButton('autre', 'Autre'),
            ],
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredRecipes.length,
        itemBuilder: (context, index) {
          final recipe = filteredRecipes[index];
          return ListTile(
            title: Text(recipe.title),
            subtitle: Text(
              recipe.type[0].toUpperCase() + recipe.type.substring(1),
              style: TextStyle(color: Colors.red.shade300),
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: recipe.imagePath != null
                  ? Image.file(File(recipe.imagePath!), width: 50, height: 50, fit: BoxFit.cover)
                  : Image.asset('assets/default_recipe.jpg', width: 50, height: 50, fit: BoxFit.cover),
            ),
            // ✅ Ouvre RecipeViewPage (mode lecture)
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RecipeViewPage(recipe: recipe)),
              );
              if (result == true) loadRecipes();
            },
          );
        },
      ),
    );
  }

  Widget filterButton(String value, String label) {
    bool isSelected = selectedFilter == value;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.red : Colors.red.shade100,
      ),
      onPressed: () => setState(() => selectedFilter = value),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
    );
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About')),
      body: Center(
        child: Text(
          'LetHimCook\nVersion 1',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
