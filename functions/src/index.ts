// Import necessary modules
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Stripe from "stripe";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Initialize Stripe with your secret key
const stripe = new Stripe(
  "sk_live_51QCMpwBHRb13El22fsnpDLwaMY2pIek284kmPhlwzY" +
  "ORRi53CYYP1NvLACEbVuhCEgWX5jI2yNfdt1EO37wX3ngT00FxWI98Tk",
  {
    apiVersion: "2024-09-30.acacia",
  }
);

// Firebase Callable Function to create a PaymentIntent
export const createPaymentIntent = functions.https.onCall(
  async (data, context) => {
    // Check if the user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    try {
      // Extract amount and currency from data
      const {amount, currency} = data;

      // Validate inputs
      if (typeof amount !== "number" || amount <= 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "'amount' must be a positive number."
        );
      }

      if (typeof currency !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "'currency' must be a valid ISO string."
        );
      }

      // Create a PaymentIntent with the provided amount and currency
      const paymentIntent = await stripe.paymentIntents.create({
        amount: amount, // Amount in smallest currency unit (e.g., cents)
        currency: currency.toLowerCase(),
      });

      // Return the client secret
      return {clientSecret: paymentIntent.client_secret};
    } catch (error: unknown) {
      if (error instanceof functions.https.HttpsError) {
        console.error("Error creating PaymentIntent:", error);
        throw error;
      }

      console.error("Error creating PaymentIntent:", error);

      throw new functions.https.HttpsError(
        "internal",
        "Internal server error."
      );
    }
  }
);

// Firebase Cloud Function to send a follow notification
export const sendUserNotification = functions.firestore
  .document("users/{userId}/notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    const userId = context.params.userId;

    // Get the FCM token for the user
    const userDoc = await admin.firestore()
      .collection("users")
      .doc(userId)
      .get();
    const fcmToken = userDoc.get("fcmToken");

    if (!fcmToken) {
      console.log("No FCM token for user, cannot send notification");
      return null;
    }

    const notificationType = notificationData.type;
    const title: string = (() => {
      switch (notificationType) {
      case "follow":
        return "New Follower";
      case "like":
        return "New Like";
      case "comment":
        return "New Comment";
      default:
        return "Notification";
      }
    })();
    const body = notificationData.message || "";

    const payload = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      // Send the notification to the user's device
      const response = await admin.messaging().sendToDevice(fcmToken, payload);
      console.log("Successfully sent message:", response);
    } catch (error) {
      console.error("Error sending message:", error);
    }

    return null;
  });
