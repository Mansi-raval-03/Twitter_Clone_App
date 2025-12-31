#!/bin/bash

echo "========================================"
echo " Twitter Clone - Push Notifications Setup"
echo "========================================"
echo ""

echo "Step 1: Installing Cloud Function dependencies..."
cd functions
npm install
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install dependencies"
    exit 1
fi
cd ..

echo ""
echo "Step 2: Deploying Cloud Functions to Firebase..."
firebase deploy --only functions
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to deploy functions"
    echo "Make sure you are logged in: firebase login"
    exit 1
fi

echo ""
echo "========================================"
echo " SUCCESS! Push notifications are now enabled!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Run the Flutter app: flutter run"
echo "2. Log in with a user"
echo "3. Test notifications with another user"
echo ""
echo "Check PUSH_NOTIFICATIONS_SETUP.md for detailed guide"
echo ""
