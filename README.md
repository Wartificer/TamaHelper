# TamaHelper
<img width="300" height="200" alt="Image" src="https://github.com/user-attachments/assets/06d1e8e8-2d2d-4f45-8d71-292f69e7b345" />


## Introduction
TamaHelper is a simple Quality-of-Life tool that allows you to see event rewards for each option in the game UmaMusume.

This app is up to date with information from Gametora up to August 6, 2025.

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/76529af7-201a-49e0-a8cd-492e03e09e48" />

## Is it safe to use?
I designed this app for myself, and I'm going hard at the game. That's why going back and forth between the game and my browser to check what each event choice rewards got tiring.

The app was made with this in mind "never interact with the game". The only thing this app does is capture your entire screen so it can read specific pixels, and if it detects choices, will read the name of the event and provide you the correct information in real time.

All of the images and the information used by this app is stored locally inside the executable file, so it doesn't need connection to the internet. This also means I will need to update it whenever a new character or card is released, which I intend to do but can't promise I'll keep it going forever.

## Important Considerations
This app was designed to work on PC with a screen size of 1920x1080 and the game on full-screen. I have tested and it works with 1366x768 but I can't guarantee it'll work for any other screen sizes. This app needs to take precise colored pixels from the screen in order to detect choices appearing in-game since it doesn't interact with it in any way. Make sure the horseshoes at the left of each choice is not obscured by your cursor or any other window, as this app looks for exact pixel colors in those icons.

Use the small preview on the bottom-left to make sure your correct screen is being captured, if not, open the settings menu at the top-right and switch screens.

Lastly, I'll be updating it as I use it. Right now it only detects multiple choices of 2 and 3 buttons only. It won't work with 4 or more choices, I'll update the application as these cases appear on my playthroughs.

## How to use:
1) Install [Tesseract OCR](https://github.com/tesseract-ocr/tesseract?tab=readme-ov-file#installing-tesseract) (This is required for the app to extract texts from the screen capture. You might also have to add the installation folder to PATH, see image below)
2) Grab the app from [Releases](https://github.com/Wartificer/TamaHelper/releases) and run it. Then, click start.

(Adding Tesseract OCR to Path)
<img width="1576" height="600" alt="image" src="https://github.com/user-attachments/assets/17a2958c-f978-4d69-8916-24a7123ff6a8" />


## License:
The entire Godot 4 project and all data is free to download from this repository. You are free to use, modify and distribute.
