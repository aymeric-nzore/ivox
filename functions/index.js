const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onChatMessageCreated = onDocumentCreated(
  "chat_rooms/{chatRoomId}/message/{messageId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const data = snapshot.data() || {};
    const receiverId = data.receiverID;
    const senderId = data.senderID;
    const senderEmail = data.senderEmail || "Nouveau message";
    const message = data.message || "Nouveau message";

    if (!receiverId || !senderId) {
      return;
    }

    if (receiverId === senderId) {
      return;
    }

    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(receiverId)
      .get();

    const userData = userDoc.data() || {};
    const token = userData.fcmToken;

    if (!token) {
      return;
    }

    const payload = {
      token,
      notification: {
        title: `Nouveau message de ${senderEmail}`,
        body: message,
      },
      data: {
        senderId: String(senderId),
        receiverId: String(receiverId),
        chatRoomId: String(event.params.chatRoomId),
      },
      android: {
        priority: "high",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    };

    try {
      await admin.messaging().send(payload);
    } catch (error) {
      console.error("FCM send error:", error);
    }
  }
);
