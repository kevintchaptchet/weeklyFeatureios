import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StripePaymentService {
  // Initialize Stripe with your publishable key
  StripePaymentService() {
    Stripe.publishableKey = 'pk_live_51QCMpwBHRb13El22QmJYjJRowoscrfiSxquA4OjrViVBhTBb7eMfkxQERTayrkVX86SlXVWPWsZGDUfAjUBsm2OK00g0S0e1Sh';  // Replace with your Stripe publishable key
  }

  // Function to handle payment
  Future<bool> makePayment(BuildContext context, String userId) async {
    try {
      // Call the Firebase Cloud Function to create a PaymentIntent
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createPaymentIntent');
      final response = await callable.call(<String, dynamic>{
        'amount': 1000,  // Amount in cents (e.g., $10)
        'currency': 'usd',
      });

      // Get the client secret from the response
      final clientSecret = response.data['clientSecret'];

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.light, // Or dark depending on your app theme
          merchantDisplayName: 'Weekly Features',
        ),
      );

      // Display the payment sheet
      await Stripe.instance.presentPaymentSheet();


      // Handle successful payment
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful!')),
      );
      return true;
    } catch (e) {
      // Handle payment error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}')),
      );
    }
    return false;
  }
}
