import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/http_exception.dart';
import 'product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  String _authToken;
  String _userId;

  Products(
    this._authToken,
    this._userId,
    this._items,
  );

//https://expertphotography.b-cdn.net/wp-content/uploads/2022/03/apps-to-change-background-smartphone-table.jpeg
  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUSer = false]) async {
    print('fetchAndSetProducts');

    final filterString =
        filterByUSer ? 'orderBy="creatorId"&equalTo="$_userId"' : '';
    final url =
        'https://flutter-itt-default-rtdb.firebaseio.com/products.json?auth=$_authToken&$filterString';
    try {
      print(url);
      final response = await http.get(Uri.parse(url));
      if (response.body == 'null') {
        return;
      }

      final extractedData = json.decode(response.body) as Map<String, dynamic>;

      final favoriteResponse = await http.get(Uri.parse(
          'https://flutter-itt-default-rtdb.firebaseio.com/userFavorites/$_userId.json?auth=$_authToken'));
      var favoriteData = null;
      if (favoriteResponse.body != 'null') {
        favoriteData = json.decode(favoriteResponse.body);
      }

      final List<Product> loadedProducts = [];
      extractedData.forEach((prodId, prodData) {
        print(prodId);
        print(prodData);

        loadedProducts.add(
          Product(
            id: prodId,
            title: prodData['title'],
            description: prodData['description'],
            price: prodData['price'],
            imageUrl: prodData['imageUrl'],
            userId: _userId,
            isFavorite:
                favoriteData == null ? false : favoriteData[prodId] ?? false,
          ),
        );
      });

      _items = loadedProducts;

      //print(json.decode(response.body));
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://flutter-itt-default-rtdb.firebaseio.com/products.json?auth=$_authToken'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': _userId,
          // 'isFavorite': product.isFavorite,
        }),
      );

      print(response);
      print(json.decode(response.body));

      final newProduct = Product(
        id: json.decode(response.body)['name'],
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        userId: _userId,
      );

      _items.add(newProduct);
      //_items.insert(0, newProduct);
      notifyListeners();
    } catch (error) {
      print("error: " + error.toString());
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    print(id);
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      await http.patch(
        Uri.parse(
            'https://flutter-itt-default-rtdb.firebaseio.com/products/$id.json?auth=$_authToken'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'title': newProduct.title,
          'description': newProduct.description,
          'imageUrl': newProduct.imageUrl,
          'price': newProduct.price,
          'userId': _userId,
          //'isFavorite': newProduct.isFavorite,
        }),
      );

      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('error');
    }
  }

  Future<void> deleteProduct(String id) async {
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    Product? existingProduct = _items[existingProductIndex];

    _items.removeWhere((prod) => prod.id == id);
    notifyListeners();

    final response = await http.delete(Uri.parse(
        'https://flutter-itt-default-rtdb.firebaseio.com/products/$id.json?auth=$_authToken'));
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProduct = null;
  }
}
