import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product.dart';
import '../providers/products.dart';

class EditProductScreen extends StatefulWidget {
  static const routeName = '/edit-product';
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _imageUrlFocusNode = FocusNode();

  final _imageUrlController = TextEditingController();

  final _form = GlobalKey<FormState>();

  var _editedProduct = Product(
    id: '',
    title: '',
    price: 0,
    description: '',
    imageUrl: '',
    userId: '',
    isFavorite: false,
  );

  var _initValues = {
    'id': '',
    'title': '',
    'price': '',
    'description': '',
    'imageUrl': '',
    'isFavorite': '',
  };

  var _isInit = true;
  var _isLoading = false;

  @override
  void dispose() {
    _imageUrlFocusNode.removeListener(_updateImageUrl);
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _imageUrlFocusNode.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _imageUrlFocusNode.addListener(_updateImageUrl);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      if (ModalRoute.of(context)?.settings.arguments != null) {
        final productId = ModalRoute.of(context)?.settings.arguments as String;
        _editedProduct =
            Provider.of<Products>(context, listen: false).findById(productId);

        _initValues = {
          'id': _editedProduct.id,
          'title': _editedProduct.title,
          'price': _editedProduct.price.toString(),
          'description': _editedProduct.description,
          'imageUrl': '',
          'userId': '',
          'isFavorite': _editedProduct.isFavorite.toString(),
        };
        _imageUrlController.text = _editedProduct.imageUrl;
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  void _updateImageUrl() {
    if (!_imageUrlFocusNode.hasFocus) {
      print(_imageUrlController.text);
      if (_imageUrlController == null) return;
      if (_imageUrlController.text.isEmpty) return;
      if (!_imageUrlController.text.startsWith('http') &&
          !_imageUrlController.text.startsWith('https')) {
        print('not http or https');
        return;
      }
      if (!_imageUrlController.text.endsWith('jpg') &&
          !_imageUrlController.text.endsWith('jpeg') &&
          !_imageUrlController.text.endsWith('png')) {
        print('not jpg, jpeg or png');
        return;
      }
      setState(() {});
    }
  }

  Future<void> _saveForm() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      print('Form is not valid!');
      return;
    }

    _form.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    print('Save form');
    print(_editedProduct.id);
    print(_editedProduct.title);
    print(_editedProduct.price);
    print(_editedProduct.description);
    print(_editedProduct.imageUrl);
    print(_editedProduct.isFavorite);

    if (_editedProduct.id.isEmpty) {
      print('new product');

      try {
        await Provider.of<Products>(context, listen: false)
            .addProduct(_editedProduct);
      } catch (error) {
        print("error****" + error.toString());
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('An error occurred!'),
            content: Text('Something went wrong.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  //            throw error;
                },
                child: Text('Okay'),
              ),
            ],
          ),
        );
      }
      /* finally {
        print('fffffdffdf');
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();
      }*/
    } else {
      print('update product');
      await Provider.of<Products>(context, listen: false)
          .updateProduct(_editedProduct.id, _editedProduct);
    }
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
        actions: [
          IconButton(
            onPressed: _saveForm,
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _form,
                child: ListView(children: [
                  TextFormField(
                    initialValue: _initValues['title'],
                    decoration: InputDecoration(labelText: 'Title'),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_priceFocusNode);
                    },
                    validator: (value) {
                      if (value == null) return 'Please provide a title.';
                      if (value.isEmpty) return 'Please provide a title.';
                      return null;
                    },
                    onSaved: ((newValue) => _editedProduct = Product(
                          id: _editedProduct.id,
                          title: newValue.toString(),
                          description: _editedProduct.description,
                          price: _editedProduct.price,
                          imageUrl: _editedProduct.imageUrl,
                          userId: _editedProduct.userId,
                          isFavorite: _editedProduct.isFavorite,
                        )),
                  ),
                  TextFormField(
                    initialValue: _initValues['price'],
                    decoration: const InputDecoration(labelText: 'Price'),
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    focusNode: _priceFocusNode,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context)
                          .requestFocus(_descriptionFocusNode);
                    },
                    validator: (value) {
                      if (value == null) return 'Please provide a price.';
                      if (value.isEmpty) return 'Please provide a price.';
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number.';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Please enter a number greater than zero.';
                      }

                      return null;
                    },
                    onSaved: ((newValue) => _editedProduct = Product(
                          id: _editedProduct.id,
                          title: _editedProduct.title,
                          description: _editedProduct.description,
                          price: double.parse(newValue.toString()),
                          imageUrl: _editedProduct.imageUrl,
                          userId: _editedProduct.userId,
                          isFavorite: _editedProduct.isFavorite,
                        )),
                  ),
                  TextFormField(
                    initialValue: _initValues['description'],
                    decoration: InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    //textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.multiline,
                    focusNode: _descriptionFocusNode,
                    validator: (value) {
                      if (value == null) return 'Please provide a description.';
                      if (value.isEmpty) return 'Please provide a description.';
                      if (value.length < 10) {
                        return 'Should be at least 10 characters long.';
                      }
                      return null;
                    },
                    onSaved: ((newValue) => _editedProduct = Product(
                          id: _editedProduct.id,
                          title: _editedProduct.title,
                          description: newValue.toString(),
                          price: _editedProduct.price,
                          imageUrl: _editedProduct.imageUrl,
                          userId: _editedProduct.userId,
                          isFavorite: _editedProduct.isFavorite,
                        )),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: EdgeInsets.only(top: 8, right: 10),
                        decoration: BoxDecoration(
                          border: Border.all(width: 1, color: Colors.grey),
                        ),
                        child: _imageUrlController.text.isEmpty
                            ? Text('Enter a URL')
                            : FittedBox(
                                child: Image.network(
                                  _imageUrlController.text,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      Expanded(
                        child: TextFormField(
                          //  initialValue: _initValues['imageUrl'],
                          decoration: InputDecoration(labelText: 'Image URL'),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          controller: _imageUrlController,
                          focusNode: _imageUrlFocusNode,
                          onFieldSubmitted: (_) => _saveForm,
                          validator: (value) {
                            if (value == null)
                              return 'Please provide a image URL.';
                            if (value.isEmpty)
                              return 'Please provide a image URL.';
                            if (!value.startsWith('http') &&
                                !value.startsWith('https')) {
                              return 'Please enter a valid URL.';
                            }
                            if (!value.endsWith('jpg') &&
                                !value.endsWith('jpeg') &&
                                !value.endsWith('png')) {
                              return 'Please enter a valid URL.';
                            }
                            return null;
                          },
                          onSaved: ((newValue) => _editedProduct = Product(
                                id: _editedProduct.id,
                                title: _editedProduct.title,
                                description: _editedProduct.description,
                                price: _editedProduct.price,
                                imageUrl: newValue.toString(),
                                userId: _editedProduct.userId,
                                isFavorite: _editedProduct.isFavorite,
                              )),
                          /* onEditingComplete: () {
                      setState(() {});
                    },*/
                        ),
                      ),
                    ],
                  ),
                  /*   Expanded(
              child: TextFormField(
                decoration: InputDecoration(labelText: 'Image URL'),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                //  controller: _imageUrlController,
                onEditingComplete: () {
                  setState(() {});
                },
              ),
            ),*/
                ]),
              ),
            ),
    );
  }
}
