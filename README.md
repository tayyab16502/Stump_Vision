Stump Vision 

Title: Stump Vision  

Cricket Scoring App with AI DRS & Match Sharing 

Developer: Tayyab Khan 

1. Overview Stump Vision is a modern cricket scoring app made for local tournaments. It solves two big problems: it allows scoring without the internet, and it brings "Third Umpire" technology (DRS) to street cricket using AI. 

A unique feature of this app is that you can share a match file with a friend, and they can continue scoring from their own phone. 

2. Key Features 

Share Match Data (JSON Feature): 

You can save the current match as a file. 

Send this file via WhatsApp to another scorer. 

They can load this file into their app and resume scoring exactly where you left off. This is great for switching devices. 

Works Offline (No Internet): 

The app uses a local database (SQLite). You can score unlimited matches even on grounds with zero internet signals. 

AI-Powered DRS: 

Players can upload a video of a ball delivery. 

The app uses a YOLOv8 model to track the ball and stump impact (Out/Not Out). 

This heavy AI runs on a laptop and connects to the phone via Ngrok. 

Professional Reports: 

PDF: Download a full match scorecard as a PDF. 

Image Summary: Generate a match summary image to share on social media. 

Live Scores: 

The app also shows live international match scores using the Cricbuzz API. 

3. How It Works (Technical Logic) 

The app uses a "Hybrid" approach to give the best performance: 

Scoring: Happens locally on the phone (using SQLite) so it is very fast. 

Sharing: Converts the match data into a JSON text format to share easily. 

AI: Uses Python and Ngrok to process videos without making the app heavy. 

4. Tech Stack (Tools Used) 

Frontend: Flutter (Dart) 

Local Database: SQLite (for offline scoring) 

Cloud Database: Firebase Auth (for login only) 

AI Engine: YOLOv8 (Python) 

API Tool: Ngrok (Secure tunnel for AI) & Cricbuzz API (for live scores) 

5. Future Plans 

Add a feature to sync local data to the cloud for backup. 

Create a leaderboard for local players. 
