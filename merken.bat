@echo off

title Merken
echo Welcome to Merken!
cd D:\Programs\Flask\Merken
start .\venv\Scripts\activate
call set FLASK_APP=run.py
call set FLASK_ENV=development
call flask run
pause