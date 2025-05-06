const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Cloud function to clean up expired pairing codes every minute
exports.cleanupExpiredPairingCodes = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    
    try {
      // Query for expired codes
      const snapshot = await admin.firestore()
        .collection('pairing_codes')
        .where('expiryTime', '<', now)
        .get();
      
      if (snapshot.empty) {
        console.log('No expired pairing codes found');
        return null;
      }
      
      // Delete expired codes in a batch
      const batch = admin.firestore().batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      await batch.commit();
      console.log(`Deleted ${snapshot.size} expired pairing codes`);
      
      return null;
    } catch (error) {
      console.error('Error cleaning up expired pairing codes:', error);
      return null;
    }
  });

// Cloud function to verify a pairing code - can be called from watch app
exports.verifyPairingCode = functions.https.onCall(async (data, context) => {
  // Ensure the code parameter is provided
  if (!data.code || typeof data.code !== 'string' || data.code.length !== 6) {
    throw new functions.https.HttpsError(
      'invalid-argument', 
      'The function must be called with a valid 6-digit code'
    );
  }
  
  try {
    const now = admin.firestore.Timestamp.now();
    
    // Find the pairing code
    const codeQuery = await admin.firestore()
      .collection('pairing_codes')
      .where('code', '==', data.code)
      .where('expiryTime', '>', now)
      .limit(1)
      .get();
    
    if (codeQuery.empty) {
      return { valid: false, message: 'Invalid or expired code' };
    }
    
    const codeDoc = codeQuery.docs[0];
    const codeData = codeDoc.data();
    const userId = codeData.userId;
    
    // Get user data
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();
    
    if (!userDoc.exists) {
      return { valid: false, message: 'User not found' };
    }
    
    // Create a custom token for this user that the watch can use
    const customToken = await admin.auth().createCustomToken(userId);
    
    // Delete the used pairing code
    await codeDoc.ref.delete();
    
    // Return success
    return { 
      valid: true, 
      token: customToken,
      userId: userId,
      displayName: userDoc.data().displayName || 'User'
    };
  } catch (error) {
    console.error('Error verifying pairing code:', error);
    throw new functions.https.HttpsError('internal', 'Error processing request');
  }
});
