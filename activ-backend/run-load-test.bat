@echo off
echo ================================================================================
echo ACTV Backend - Load Testing
echo ================================================================================
echo.

echo Checking if server is running...
curl -s http://localhost:3000/api/health >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Server is not running!
    echo.
    echo Please start the server first:
    echo   npm run dev
    echo.
    echo Or run in new window:
    echo   start cmd /k "npm run dev"
    echo.
    pause
    exit /b 1
)

echo ✓ Server is running
echo.

echo Starting load tests...
echo.
node test/load-test.js

echo.
echo ================================================================================
echo Load Testing Complete!
echo ================================================================================
echo.
echo Review the results above to assess API performance.
echo See test/README.md for interpretation guide.
echo.
pause
