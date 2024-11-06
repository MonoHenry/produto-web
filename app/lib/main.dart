import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

Future<http.Response> createProduct(
    String description, String price, String quantity, DateTime date) {
  return http.post(
    Uri.parse('http://localhost:12345/produtos'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      "descricao": description,
      "preco": double.parse(price),
      "estoque": int.parse(quantity),
      "data": date.toIso8601String(),
    }),
  );
}

Future<http.Response> editProduct(
    int id, String description, String price, String quantity, DateTime date) {
  String idString = id.toString();
  return http.put(
    Uri.parse("http://localhost:12345/produto/$idString"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      "descricao": description,
      "preco": double.parse(price),
      "estoque": int.parse(quantity),
      "data": date.toIso8601String(),
    }),
  );
}

Future<http.Response> deleteProduct(int id) {
  String idString = id.toString();
  return http.delete(Uri.parse("http://localhost:12345/produto/$idString"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      });
}

class Product {
  final int productId;
  final String description;
  final int quantity;
  final String price;
  final DateTime date;

  const Product({
    required this.productId,
    required this.description,
    required this.quantity,
    required this.price,
    required this.date,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['id'] as int,
      description: json['descricao'] as String,
      quantity: json['estoque'] as int,
      price: json['preco'] as String, // Converte preço para double
      date: DateTime.parse(
          json['data'] as String), // Converte data de String para DateTime
    );
  }
}

Future<List<Product>> fetchProducts() async {
  try {
    final response =
        await http.get(Uri.parse('http://localhost:12345/produtos'));

    if (response.statusCode == 200) {
      var productList = jsonDecode(response.body) as List;
      print('Decoded products: $productList'); // Debugging log

      return productList
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load products, status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching products: $e');
    rethrow; // Rethrow to propagate error
  }
}

void main() {
  runApp(const MyApp());
}

class SinglePeriodEnforcer extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    if ('.'.allMatches(newText).length <= 1) {
      return newValue;
    }

    return oldValue;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 71, 8, 180)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Produto-API'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Product>> futureProducts;

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts(); // Fetch the list of products
  }

  void atualizar() {
    setState(() {
      futureProducts = fetchProducts(); // Fetch the list of products
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
              onPressed: () {
                atualizar();
              },
              icon: const Icon(Icons.refresh))
        ],
      ),
      body: Center(
        child: FutureBuilder<List<Product>>(
          future: futureProducts, // Fetch the list of products
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              var products = snapshot.data!;
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  var product = products[index];
                  return ListTile(
                    title: Text(product.description),
                    subtitle: Text('Preço: ${product.price}'),
                    trailing: Text('Qtd: ${product.quantity}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyEditForm(product: product),
                        ),
                      ).then((value) {
                        atualizar();
                      });
                    },
                  );
                },
              );
            } else {
              return const Text('No data available');
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyCustomForm()),
          ).then((value) {
            atualizar();
          });
        },
        tooltip: 'Adicionar Produto',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  State<MyCustomForm> createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  late FocusNode myFocusNode;
  final myControllerDescription = TextEditingController();
  final myControllerPrice = TextEditingController();
  final myControllerQuantity = TextEditingController();
  final myControllerDate = TextEditingController();
  DateTime selectedDate = DateTime.now();

  final bool _isShown = true;

  void _create(BuildContext ctx) async {
    showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Por favor confirme'),
            content: const Text('Você realmente quer adicionar um produto?'),
            actions: [
              // The "Yes" button
              TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    if (myControllerDescription.text == '' ||
                        myControllerPrice.text == '' ||
                        myControllerQuantity.text == '') {
                      showError(context);
                    } else {
                      createProduct(
                        myControllerDescription.text,
                        myControllerPrice.text,
                        myControllerQuantity.text,
                        selectedDate,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Yes')),
              TextButton(
                  onPressed: () {
                    // Close the dialog
                    Navigator.of(context).pop();
                  },
                  child: const Text('No'))
            ],
          );
        });
  }

  Future<void> _selectedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    myFocusNode = FocusNode();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    myControllerDescription.dispose(); // Dispose of the controller
    myControllerPrice.dispose(); // Dispose of the controller
    myControllerQuantity.dispose();
    myControllerDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: "Descrição",
              ),
              controller: myControllerDescription,
              autofocus: true,
            ), // Add a comma here
            TextField(
              decoration: const InputDecoration(
                hintText: "Preço",
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                SinglePeriodEnforcer(),
                FilteringTextInputFormatter.allow(RegExp("[.0-9]")),
              ],
              controller: myControllerPrice,
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: "Quantidade",
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp("[0-9]")),
              ],
              controller: myControllerQuantity,
            ),
            TextField(
              controller: myControllerDate,
              readOnly: true,
              decoration: InputDecoration(
                  hintText:
                      "${selectedDate.year.toString()}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}"),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _selectedDate(context),
                  style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll<Color>(
                          Color.fromARGB(146, 131, 10, 187))),
                  child: const Text('Selecionar data',
                      style:
                          TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                ),
                ElevatedButton(
                  onPressed: _isShown ? () => _create(context) : null,
                  style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll<Color>(
                          Color.fromARGB(109, 14, 173, 14))),
                  child: const Text('Criar',
                      style:
                          TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MyEditForm extends StatefulWidget {
  final Product product;

  const MyEditForm({super.key, required this.product});
  @override
  State<MyEditForm> createState() => _MyEditFormState();
}

void showError(BuildContext context) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Algum parâmetro não foi preenchido'),
          actions: <Widget>[
            TextButton(
                child: const Text("Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                })
          ],
        );
      });
}

class _MyEditFormState extends State<MyEditForm> {
  late FocusNode myFocusNode;
  late int id;
  final myControllerDescription = TextEditingController();
  final myControllerPrice = TextEditingController();
  final myControllerQuantity = TextEditingController();
  final myControllerDate = TextEditingController();
  DateTime selectedDate = DateTime.now();

  final bool _isShown = true;
  final bool _deleted = true;

  void _edit(BuildContext ctx) {
    showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Por favor confirme'),
            content: const Text('Você realmente quer editar esse produto?'),
            actions: [
              // The "Yes" button
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (myControllerDescription.text == '' ||
                        myControllerPrice.text == '' ||
                        myControllerQuantity.text == '') {
                      showError(context);
                    } else {
                      editProduct(
                        id,
                        myControllerDescription.text,
                        myControllerPrice.text,
                        myControllerQuantity.text,
                        selectedDate,
                      );
                    }
                  },
                  child: const Text('Yes')),
              TextButton(
                  onPressed: () {
                    // Close the dialog
                    Navigator.of(context).pop();
                  },
                  child: const Text('No'))
            ],
          );
        });
  }

  void _delete(BuildContext ctx) {
    showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Por favor confirme'),
            content: const Text('Você realmente quer deletar esse produto?'),
            actions: [
              // The "Yes" button
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    deleteProduct(id);
                    Navigator.pop(context);
                  },
                  child: const Text('Yes')),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('No'))
            ],
          );
        });
  }

  Future<void> _selectedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    myFocusNode = FocusNode();
    id = widget.product.productId;
    myControllerDescription.text = widget.product.description;
    myControllerPrice.text =
        widget.product.price.toString().replaceAll(RegExp(r'[^\d.]'), '');
    myControllerQuantity.text = widget.product.quantity.toString();
    selectedDate = widget.product.date;
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    myControllerDescription.dispose(); // Dispose of the controller
    myControllerPrice.dispose(); // Dispose of the controller
    myControllerQuantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: myControllerDescription,
              decoration: const InputDecoration(hintText: "Descrição"),
            ),
            TextField(
              controller: myControllerPrice,
              decoration: const InputDecoration(hintText: "Preço"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: myControllerQuantity,
              decoration: const InputDecoration(hintText: "Quantidade"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: myControllerDate,
              readOnly: true,
              decoration: InputDecoration(
                  hintText:
                      "${selectedDate.year.toString()}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}"),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _selectedDate(context),
                  style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll<Color>(
                          Color.fromARGB(146, 131, 10, 187))),
                  child: const Text('Selecionar data',
                      style:
                          TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                ),
                ElevatedButton(
                  onPressed: _isShown ? () => _edit(context) : null,
                  style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll<Color>(
                          Color.fromARGB(109, 14, 173, 14))),
                  child: const Text('Editar',
                      style:
                          TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                ),
                ElevatedButton(
                  onPressed: _deleted ? () => _delete(context) : null,
                  style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll<Color>(
                          Color.fromARGB(141, 173, 15, 15))),
                  child: const Text('Deletar',
                      style:
                          TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
