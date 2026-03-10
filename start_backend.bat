@echo off
echo Starting WAF Backend Server...
echo.
cd /d "c:\Users\sanja\project\transformer-waf"
echo Current directory: %CD%
echo.
echo Activating virtual environment...
call venv\Scripts\activate.bat
echo.
echo Starting uvicorn server on port 8000...
echo Press Ctrl+C to stop the server
echo.
python -m uvicorn api.waf_api:app --reload --port 8000
pause
