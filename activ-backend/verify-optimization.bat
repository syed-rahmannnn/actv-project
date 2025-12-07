@echo off
setlocal enabledelayedexpansion

echo ================================================================================
echo API Optimization Verification
echo ================================================================================
echo.

set ERRORS=0

echo Checking files...
echo.

:: Check middleware files
if exist "middleware\cache.js" (
    echo ✓ middleware\cache.js
) else (
    echo ✗ middleware\cache.js MISSING
    set /a ERRORS+=1
)

if exist "middleware\compression.js" (
    echo ✓ middleware\compression.js
) else (
    echo ✗ middleware\compression.js MISSING
    set /a ERRORS+=1
)

if exist "middleware\performance.js" (
    echo ✓ middleware\performance.js
) else (
    echo ✗ middleware\performance.js MISSING
    set /a ERRORS+=1
)

:: Check utils
if exist "utils\queryOptimizer.js" (
    echo ✓ utils\queryOptimizer.js
) else (
    echo ✗ utils\queryOptimizer.js MISSING
    set /a ERRORS+=1
)

:: Check test files
if exist "test\load-test.js" (
    echo ✓ test\load-test.js
) else (
    echo ✗ test\load-test.js MISSING
    set /a ERRORS+=1
)

if exist "test\README.md" (
    echo ✓ test\README.md
) else (
    echo ✗ test\README.md MISSING
    set /a ERRORS+=1
)

:: Check documentation
if exist "OPTIMIZATION_GUIDE.md" (
    echo ✓ OPTIMIZATION_GUIDE.md
) else (
    echo ✗ OPTIMIZATION_GUIDE.md MISSING
    set /a ERRORS+=1
)

if exist "OPTIMIZATION_SUMMARY.md" (
    echo ✓ OPTIMIZATION_SUMMARY.md
) else (
    echo ✗ OPTIMIZATION_SUMMARY.md MISSING
    set /a ERRORS+=1
)

if exist "QUICKSTART.md" (
    echo ✓ QUICKSTART.md
) else (
    echo ✗ QUICKSTART.md MISSING
    set /a ERRORS+=1
)

echo.
echo Checking package.json...
findstr /C:"node-cache" package.json >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ node-cache listed in package.json
) else (
    echo ✗ node-cache NOT in package.json
    set /a ERRORS+=1
)

findstr /C:"compression" package.json >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ compression listed in package.json
) else (
    echo ✗ compression NOT in package.json
    set /a ERRORS+=1
)

findstr /C:"axios" package.json >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ axios listed in package.json
) else (
    echo ✗ axios NOT in package.json
    set /a ERRORS+=1
)

echo.
echo ================================================================================

if %ERRORS% equ 0 (
    echo ✅ ALL CHECKS PASSED!
    echo.
    echo Optimization setup is complete and ready to use.
    echo.
    echo Next steps:
    echo 1. Run: npm install
    echo 2. Run: npm run dev
    echo 3. Run: npm run load-test
    echo.
) else (
    echo ❌ %ERRORS% ISSUE(S) FOUND!
    echo.
    echo Some files or configurations are missing.
    echo Please run setup-optimization.bat to fix.
    echo.
)

echo ================================================================================
pause
