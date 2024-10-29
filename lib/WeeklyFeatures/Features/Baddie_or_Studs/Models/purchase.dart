import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PurchaseULScreen extends StatefulWidget {
  @override
  _PurchaseULScreenState createState() => _PurchaseULScreenState();
}

class _PurchaseULScreenState extends State<PurchaseULScreen> {
  List<ProductDetails> _availableProducts = [];

  @override
  void initState() {
    super.initState();
    InAppPurchase.instance.purchaseStream.listen(_onPurchaseUpdated);
    _getAvailableProducts();
  }

  Future<void> _getAvailableProducts() async {
    const Set<String> _productIds = {'ul_100_pack'};
    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) {
      // Handle product not found
    }
    setState(() {
      _availableProducts = response.productDetails;
    });
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        _deliverProduct(purchaseDetails);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == 'ul_100_pack') {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(userRef);
          int currentUL = snapshot.get('ul') ?? 0;
          transaction.update(userRef, {'ul': currentUL + 100});
        });
      }
    }
  }

  Future<void> _buyULPack(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Buy Uploads Left"),
      ),
      body: _availableProducts.isNotEmpty
          ? ListView.builder(
        itemCount: _availableProducts.length,
        itemBuilder: (context, index) {
          final product = _availableProducts[index];
          return ListTile(
            title: Text(product.title),
            subtitle: Text(product.price),
            trailing: ElevatedButton(
              onPressed: () => _buyULPack(product),
              child: Text("Buy"),
            ),
          );
        },
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
