const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { Storage } = require("@google-cloud/storage");

admin.initializeApp();
const storage = new Storage();

exports.getSignedUrl = functions.https.onRequest(async (req, res) => {
  const authHeader = req.headers.authorization || "";
  const match = authHeader.match(/^Bearer (.*)$/);

  if (!match) {
    console.log("❌ No Bearer token in Authorization header");
    return res.status(401).send("Unauthorized");
  }

  const idToken = match[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    console.log("✅ Authenticated user:", decodedToken.uid);
  } catch (err) {
    console.error("❌ Invalid ID token:", err);
    return res.status(401).send("Unauthorized");
  }

  //const bucketName = "vasis-beats.appspot.com"; 
  const bucketName = "vasis-beats.firebasestorage.app"// ✅ NOT firebasestorage.app
  const filePath = "vasis-sounds-paid.zip";
  const expiresAt = Date.now() + 5 * 60 * 1000;

  try {
    const [url] = await storage
      .bucket(bucketName)
      .file(filePath)
      .getSignedUrl({
        version: "v4",
        action: "read",
        expires: expiresAt,
      });

    return res.status(200).json({ url });
  } catch (error) {
    console.error("❌ Error generating signed URL:", error);
    return res.status(500).send("Internal Server Error");
  }
});

