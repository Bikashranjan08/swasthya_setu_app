import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {RtcTokenBuilder, RtcRole} from "agora-token";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Define environment variables for type safety
const appID = process.env.AGORA_APPID;
const appCertificate = process.env.AGORA_APPCERTIFICATE;

export const generateAgoraToken = functions.https.onCall(async (data, context) => {
  // Check for authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }

  // Validate required data from the client
  const channelName = data.channelName;
  if (!channelName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a \"channelName\" argument.",
    );
  }
  
  // Ensure server environment variables are set
  if (!appID || !appCertificate) {
    throw new functions.https.HttpsError(
      "internal",
      "Agora credentials are not set in the server environment.",
    );
  }

  const uid = context.auth.uid;
  const role = RtcRole.PUBLISHER;
  const expirationTimeInSeconds = 3600; // Token is valid for 1 hour
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  // Generate the Agora token
  const token = RtcTokenBuilder.buildTokenWithUid(
    appID,
    appCertificate,
    channelName,
    uid,
    role,
    privilegeExpiredTs,
  );

  return {token: token};
});