@echo off
echo ========================================
echo  Twitter Clone - Push Notifications Setup
echo ========================================
echo.

echo Step 1: Installing Cloud Function dependencies...
cd functions
call npm install
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)
cd ..

echo.
echo Step 2: Deploying Cloud Functions to Firebase...
call firebase deploy --only functions
if errorlevel 1 (
    echo ERROR: Failed to deploy functions
    echo Make sure you are logged in: firebase login
    pause
    exit /b 1
)

echo.
echo ========================================
echo  SUCCESS! Push notifications are now enabled!
echo ========================================
echo.
echo Next steps:
echo 1. Run the Flutter app: flutter run
echo 2. Log in with a user
echo 3. Test notifications with another user
echo.
echo Check PUSH_NOTIFICATIONS_SETUP.md for detailed guide
echo.
pause
