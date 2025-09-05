# TamaHelper
<img width="128" height="128" alt="favicon" src="https://github.com/user-attachments/assets/2c0e726a-60df-4a48-ba92-f44fdb26e7d1" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/50d5e4eb-8c52-4e3a-99b2-3eb6191cce46" />



## Introduction
TamaHelper is a simple Quality-of-Life companion app for UmaMusume that automatically shows you the effects of each choice while playing, so you don't have to search them yourself.
It also adds a timeline where you can see incoming G1 races and events such as: Beach Vacation, Inspirations, Skill-Ups. Hovering over them will provide additional information.
<img width="1107" height="491" alt="image" src="https://github.com/user-attachments/assets/aea97896-9b0a-404a-bb53-8ced244e714e" />

This app is up-do-date with the game as of August 10, 2025.

<img width="1110" height="391" alt="image" src="https://github.com/user-attachments/assets/88d42942-1ceb-454b-a349-4b2aade1e0c2" />

## Is it safe to use?
I designed this app for myself, and I'm going hard at the game. That's why not getting banned is my top priority. Going back and forth between the game and my browser to check what each event choice rewards got really tiring.

This app was made with this in mind "never interact with the game". The only thing this app does is capture your screen so it can read specific pixels, and if it detects choices, will read the name of the event and provide the information in real time. The game itself has no way of knowing this app exist while you play, so you're safe to use it.

All of the images and the information used by this app is stored locally inside the executable file, so it doesn't need connection to the internet. This also means I will need to update it whenever a new character or card is released, which I intend to do at least for the time being.

## Important Considerations
This app was designed to work on PC with a screen size of 1920x1080 and the game on full-screen. I've tested other screen configurations and resolutions and it works on those as well, at least for 16/9. I've added fallbacks for special resolutions such as WUXGA, but can't guarantee it working.

IMPORTANT!!! - Make sure the horseshoes at the left of each choice are not obscured by your cursor or any other window, as this app looks for exact pixel colors in those icons. This also applies for the event name at the top left.

<img width="213" height="281" alt="image" src="https://github.com/user-attachments/assets/512acef9-fdff-4533-90c1-c35d175e7f11" />
<img width="500" height="185" alt="image" src="https://github.com/user-attachments/assets/258c6b73-87ea-4f09-8dae-071d3418c4c4" />


Lastly, I'll be updating it as I use it. Right now it only detects multiple choices of 2 and 3 buttons only. It won't work with 4 or more choices, I'll update the application as these cases appear on my playthroughs.
</br>
</br>


## How to use:
1) Grab the app from [Releases](https://github.com/Wartificer/TamaHelper/releases) uncompress and run TamaHelper.exe. Then, click the "start" button.
2) Use the small preview on the bottom-left to make sure your correct screen is being captured, if not, open the settings menu at the top-right and switch screens.
<img width="376" height="84" alt="image" src="https://github.com/user-attachments/assets/9b280be0-d7cd-4684-9aed-7e30a4ec7aba" />
</br>
If you'd like, you can change the default font or the bottom mascot by changing the files in the "assets" folder.
</br>
</br>

## NEW: Notes and Update tabs
Added a new tab to get updates on data without needing to download the whole app again. Whenever new characters, supports are added to the game, after they are processed for the app, you can get them using this tab.
Also added Notes, where you can paste any text or images to keep track of important stuff in a quickly accessible manner.

<img width="400" height="600" alt="485357258-cbc44b7f-a1af-47cf-a7e1-e18a67819a4f" src="https://github.com/user-attachments/assets/b40dcff0-c4dc-4b3c-9930-825116dc240a" />


## Troubleshooting:
First before anything, make sure tha app reads the correct screen, next to the mascot there should be a miniature of your screen:

<img width="400" height="96" alt="477323243-d9205553-6dd5-4399-9057-98c3c4c966a4" src="https://github.com/user-attachments/assets/2abcbf11-b609-4826-a885-fb83e478f2bd" />

If the issue persists, try downloading the debug build on the lattest [Release](https://github.com/Wartificer/TamaHelper/releases) and opening the "console.exe" file, then, click "start" with "loop" OFF and the game visible. This way, the images it tries to read from the screen will be saved next to the app in folder "temp_images", you should have something like this:

<img width="3000" height="300" alt="477322843-cf4432ab-aabf-46ef-ac7c-92258de91069" src="https://github.com/user-attachments/assets/9e6fae02-4aa4-49ac-801b-9fd4438d8ad7" />

Also, on the console that opens next to the app, there will be some logs like this:

<img width="316" height="91" alt="477322922-9894f173-54ba-4991-9f92-9d8024fe8fce" src="https://github.com/user-attachments/assets/592e86c7-0072-4069-9766-8f2e0599dc38" />

Note: "No choices on screen" should instead show the name of the event if there is one on screen.</br>
If you're not seeing text from the in-game date and the date is currently visible at the top left on your career, then something might be wrong in the "tesseract" folder. Those files come from an Open Source project on this website and are safe, but just in case, confirm that all the files there are present by comparing the amount of files with the ones inside the zip.

If you are having issues create a new issue or contact me with this information and I'll do what I can to fix it.

</br>
</br>
</br>



## License:
**MIT License**

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software.

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

**UmaMusume Content and Assets**

IMPORTANT NOTICE: All UmaMusume game data, including but not limited to:

Character names, descriptions, and biographical information
Card data, statistics, and gameplay mechanics
Images, artwork, sprites, and visual assets
Audio files, music, and sound effects
Game logos, trademarks, and branding materials

Are the exclusive property of Cygames, Inc. and are protected by copyright, trademark, and other intellectual property laws.
This application is a fan-made, non-commercial tool created for informational and educational purposes only. The inclusion of UmaMusume content in this application:

Does not constitute a claim of ownership over any Cygames property
Is intended to fall under fair use provisions for informational purposes
Should be considered as referencing publicly available game information
Is not endorsed by or affiliated with Cygames, Inc.
