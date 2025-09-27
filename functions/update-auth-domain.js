const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK using environment variables
// Set these environment variables before running the script:
// FIREBASE_PROJECT_ID=vasis-beats
// FIREBASE_CLIENT_EMAIL=your-service-account-email
// FIREBASE_PRIVATE_KEY=your-service-account-private-key

const serviceAccount = {
  projectId: process.env.FIREBASE_PROJECT_ID || 'vasis-beats',
  clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n')
};

if (!serviceAccount.clientEmail || !serviceAccount.privateKey) {
  console.error('❌ Missing required environment variables:');
  console.error('Please set FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY');
  console.error('You can get these from Firebase Console > Project Settings > Service Accounts');
  process.exit(1);
}

initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function updateAuthDomain() {
  try {
    const auth = getAuth();
    
    // Update the project configuration to use custom domain
    const updateRequest = {
      mobileLinksConfig: {
        domain: 'HOSTING_DOMAIN' // Use the constant for Firebase Hosting
      }
    };
    
    const projectConfigManager = auth.projectConfigManager();
    const result = await projectConfigManager.updateProjectConfig(updateRequest);
    
    console.log('✅ Successfully updated Firebase project configuration:');
    console.log(JSON.stringify(result, null, 2));
    
  } catch (error) {
    console.error('❌ Error updating Firebase project configuration:');
    console.error(error);
  }
}

updateAuthDomain();
