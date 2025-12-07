@echo off
echo ================================================================================
echo ACTV Backend - API Optimization Setup
echo ================================================================================
echo.

echo [1/3] Installing new dependencies...
call npm install axios compression node-cache --save

echo.
echo [2/3] Verifying installation...
call npm list axios compression node-cache

echo.
echo [3/3] Testing server startup...
echo.
echo Starting server in test mode...
echo Press Ctrl+C to stop after verification
echo.

timeout /t 3 /nobreak >nul
start "ACTV Test Server" cmd /c "npm run dev"

echo.
echo ================================================================================
echo Setup Complete!
echo ================================================================================
echo.
echo Next steps:
echo 1. Wait for server to start (check the new window)
echo 2. Run load tests: npm run load-test
echo 3. Review OPTIMIZATION_GUIDE.md for details
echo.
echo Server should be running at: http://localhost:3000
echo Health check: http://localhost:3000/api/health
echo.
pause
