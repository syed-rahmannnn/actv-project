import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../models/product_model.dart';
import '../../../models/discover_product.dart';

class AddProductNewScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String companyId;
  final Product? product; // For edit mode
  final DiscoverProduct? discoverProduct; // For viewing from Discover
  final bool isEdit; // Flag to indicate edit mode

  const AddProductNewScreen({
    super.key,
    required this.userData,
    required this.companyId,
    this.product,
    this.discoverProduct,
    this.isEdit = false,
  });

  @override
  State<AddProductNewScreen> createState() => _AddProductNewScreenState();
}

class _AddProductNewScreenState extends State<AddProductNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _skuController = TextEditingController();

  String? _selectedCategory;
  final List<String> _categories = [
    'Software',
    'Services',
    'Education',
    'Product',
    'Other',
  ];

  File? _productImage;
  bool _isSaving = false;

  // Helper to check if we're in view-only mode (from Discover)
  bool get _isViewOnly => widget.discoverProduct != null;

  @override
  void initState() {
    super.initState();
    // Prefill form fields if in edit mode or viewing from Discover
    if (widget.discoverProduct != null) {
      // Use discover product data
      _productNameController.text = widget.discoverProduct!.name;
      _descriptionController.text = widget.discoverProduct!.description ?? '';
      _selectedCategory = widget.discoverProduct!.category;
      _priceController.text = widget.discoverProduct!.price.toString();
    } else if (widget.isEdit && widget.product != null) {
      // Use existing product data
      _productNameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _selectedCategory = widget.product!.category;
      _priceController.text = widget.product!.price.toString();
      // Note: stock and sku are not in current Product model
      // If you need them, add to model and backend first
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _pickProductImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _productImage = File(image.path);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Parse price value
        final priceValue = double.tryParse(_priceController.text) ?? 0.0;

        // Create product data JSON
        final productData = {
          'companyId': widget.companyId,
          'name': _productNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory ?? 'Other',
          'price': priceValue,
          'priceUnit': 'one-time',
          'currency': 'INR',
          'featured': false,
          'imageUrl': null,
        };

        final baseUrl = 'http://10.42.208.174:3000/api/products';
        http.Response response;

        if (widget.isEdit && widget.product != null) {
          // UPDATE existing product
          print('📦 Updating product ${widget.product!.id}');
          print('📦 Update payload: ${jsonEncode(productData)}');

          response = await http
              .put(
                Uri.parse('$baseUrl/${widget.product!.id}'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(productData),
              )
              .timeout(const Duration(seconds: 10));

          print('📦 Update status: ${response.statusCode}');
          print('📦 Update response: ${response.body}');
        } else {
          // CREATE new product
          print('📦 Creating new product');
          print('📦 Create payload: ${jsonEncode(productData)}');

          response = await http
              .post(
                Uri.parse(baseUrl),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(productData),
              )
              .timeout(const Duration(seconds: 10));

          print('📦 Create status: ${response.statusCode}');
          print('📦 Create response: ${response.body}');
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Success
          if (mounted) {
            Navigator.pop(context, true); // Return true to reload list
          }
        } else {
          // API returned error
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Failed to save product';

          if (mounted) {
            setState(() {
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Error in _saveProduct: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving product: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB3D4FF), Color(0xFFE6D8FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        _isViewOnly
                            ? 'Product Details'
                            : (widget.isEdit ? 'Edit Product' : 'Add Product'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // WHITE CARD with ALL FORM FIELDS
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Upload Image
                                Center(
                                  child: GestureDetector(
                                    onTap: _isViewOnly
                                        ? null
                                        : _pickProductImage,
                                    child: Container(
                                      width: double.infinity,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F7FA),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: _productImage != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.file(
                                                _productImage!,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.inventory_2_outlined,
                                                  size: 50,
                                                  color: Colors.grey.shade400,
                                                ),
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.blue,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.upload_outlined,
                                                    size: 24,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Product Name
                                const Text(
                                  'Product Name',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _productNameController,
                                  readOnly: _isViewOnly,
                                  decoration: InputDecoration(
                                    hintText: 'Enter product name',
                                    filled: true,
                                    fillColor: const Color(0xFFF5F7FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                // Description
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _descriptionController,
                                  readOnly: _isViewOnly,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: 'Describe your product...',
                                    filled: true,
                                    fillColor: const Color(0xFFF5F7FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                // Category
                                const Text(
                                  'Category',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: InputDecoration(
                                    hintText: 'Select category',
                                    filled: true,
                                    fillColor: const Color(0xFFF5F7FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: _categories.map((String category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                  onChanged: _isViewOnly
                                      ? null
                                      : (String? newValue) {
                                          setState(() {
                                            _selectedCategory = newValue;
                                          });
                                        },
                                  validator: (value) =>
                                      value == null ? 'Required' : null,
                                ),
                                const SizedBox(height: 20),

                                // Price
                                const Text(
                                  'Price',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _priceController,
                                  readOnly: _isViewOnly,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Enter price',
                                    filled: true,
                                    fillColor: const Color(0xFFF5F7FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                // Stock
                                const Text(
                                  'Stock',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _stockController,
                                  readOnly: _isViewOnly,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Enter stock quantity',
                                    filled: true,
                                    fillColor: const Color(0xFFF5F7FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // SKU
                                const Text(
                                  'SKU',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _skuController,
                                  readOnly: _isViewOnly,
                                  decoration: InputDecoration(
                                    hintText: 'Enter SKU',
                                    filled: true,
                                    fillColor: const Color(0xFFF5F7FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Save and Cancel Buttons (hidden in view-only mode)
                                if (!_isViewOnly)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _isSaving
                                              ? null
                                              : () => Navigator.pop(context),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey.shade400,
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isSaving
                                              ? null
                                              : _saveProduct,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            backgroundColor: const Color(
                                              0xFF2196F3,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: _isSaving
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : Text(
                                                  widget.isEdit
                                                      ? 'Update Product'
                                                      : 'Save Product',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
