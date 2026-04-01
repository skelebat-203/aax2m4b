This document explains how to set up an Ubuntu‑based system to use the `aax2m4b_batch.sh` script to convert Audible `.aax` audiobooks into `.m4b` files, with cleaned metadata and sane filenames.
## Table of Contents
### [[How to convert AAX2M4B#Document notes|Document notes]]

### [[How to convert AAX2M4B#System Setup|System Setup]]:
1. Install required tools (Python, `ffmpeg`, and optionally `git`).
2. Create a Python virtual environment.
3. Use the `audible-cli` tool to log into your Audible account and obtain your **activation bytes** (an 8‑character code).
4. Edit the `aax2m4b_batch.sh` script to insert your activation bytes and confirm input/output folders.
5. Run the script to convert `.aax` files in `~/Music/audiobooks/aax` into `.m4b` files in `~/Music/audiobooks/need_to_zip`.
### [[How to convert AAX2M4B#Prepare and run conversion script|Prepare and run conversion script]]
1. Place `aax2m4b_batch.sh` and Prepare Folders
2. Create a Virtual Environment for Audible Tools
3. Make the Script Executable
4. Run the Batch Conversion
### [[How to convert AAX2M4B#Basic Troubleshooting|Basic Troubleshooting]]
- “command not found: ffmpeg”
- “python: command not found” or `ModuleNotFoundError` for audible_cli
- Script says “No such file or directory” for `.aax`
- Filenames still too long

---
## Document notes
- **Target systems:** Ubuntu, Pop!_OS, Linux Mint, and similar.
- **Filesystem:** default `ext4` (255‑character per‑component filename limit).
- The script itself is provided separately; this guide assumes you already have `aax2m4b_batch.sh`.
- [[How to convert AAX2M4B#System Setup|System Setup]] steps take place primarily in the Terminal app. 
- The "***bash***" heading proceeds a command(s) you need to run in your terminal.
## Download Audible files (.aax)
1. From your computer, ***Not your phone***, login to your audible account.
2. In the top navigation bar select "Library"
3. In the tab list, below the "Library" heading, select "Audiobooks".
4. Each audiobook has a list of links. If you have purchased the book there will be a "Download" link. Select "Download"
	- If the book is a single file it will now download as an .aax file. 
	- For vary large books or book series displayed as a single title "Download" will open a popup listing files (Full book, Part - 1, Part - 2, etc.).
		- Select Full book to download the book as a single file.
		- If Full book is not an option you will need to select each part file in turn to download the book.
## System Setup
### 1. Install Required Packages
#### bash
`sudo apt update sudo apt install -y ffmpeg python3 python3-venv python3-pip git`
#### What these are for:
- `ffmpeg`: does the actual AAX → M4B conversion.
- `python3`, `python3-venv`, `python3-pip`: needed to run `audible-cli` in an isolated environment.
- `git`: used if you later want to fetch other helper scripts or repositories (not strictly required by `aax2m4b_batch.sh`, but commonly useful).

---

### 2. Create a Virtual Environment for Audible Tools
A virtual environment (“venv”) keeps Python packages isolated from the rest of your system. From your home directory, normally named "/home", run the commands in this step.
#### bash
`cd ~ mkdir -p audible-tools cd audible-tools python3 -m venv venv source venv/bin/activate`
#### Expected result
After `source venv/bin/activate`, your shell prompt should start with `(venv)` to show the environment is active.
#### Note for future use of audible-cli
 Whenever you open a new terminal and need to use `audible-cli` again, you must re‑activate this environment with:
##### bash
`cd ~/audible-tools source venv/bin/activate`

---

### 3. Install `audible-cli` Inside the Virtual Environment
This will install the Audible command‑line helper only inside this venv.
#### bash: make sure `(venv)` is visible in your prompt
`pip install --upgrade pip pip install audible-cli`

---

### 4. Run `audible-cli quickstart` and Log In
Still inside the venv (`(venv)` prompt), run:
#### bash
`python -m audible_cli quickstart`
#### Once angular-cli is running
You will be asked several questions. Recommended answers:
1. **“Please enter a name for your primary profile [audible]”**
    - Press Enter to accept the default `audible`, or type a simple nickname like `main`.
    - This is just a profile name stored locally; it is _not_ your email.
2. **“Enter a country code for the profile”**
    - Enter `us` if your Audible account is for the United States.
    - You can find all country code at [iban.com/country-codes](https://www.iban.com/country-codes)
3. **“Please enter a name for the auth file”**
    - This is the base name of a JSON file stored under `~/.audible/`.
    - You can type `default` or press Enter to accept the suggested name.
4. **"Do you want to encrypt the file?  [y/N]"**
	- This is optional. 
	- If you select y, you should see question 5.
	- If you choose N, you should see question 6.
5. **“Please enter a password for the auth file”**
    - This is a new password **only for encrypting the auth file on your disk**.
    - It is _not_ your Audible or Amazon password.
    - Choose a password you can remember, type it, and then confirm it when asked.
6. **“Do you want to login with external browser? [y/N]”**
    - Type `y` and press Enter.
    - The tool will either open your browser or provide a URL.
7. **Browser login step**
    - If a browser tab opens automatically, log in to your Audible/Amazon account as usual.
    - If a URL is printed in the terminal, copy it (Ctrl+Shift+C) and paste it into your browser’s address bar (Ctrl+V), then log in.
		- I ran into an issue where the provided link could be copied, but not paste it into my browser. If you face this, paste the link in an app that allows you to click on links. Then, click on the link to open it in the browser.
    - After login, confirm any prompts until the page tells you that authorization is complete, then return to the terminal.
8. **“Do you want to login with a pre-amazon Audible account? [y/N]”**
    - For almost all modern accounts the answer is **No**.
    - Just press Enter (or type `N` then Enter).

When `quickstart` finishes successfully, it stores your login configuration in `~/.audible`.

---

### 5. Get Your Activation Bytes
#### bash: with the `(venv)` still active
`python -m audible_cli activation-bytes`
#### Expected result
This should print an 8‑character hexadecimal code, for example:

> `2adc3435`

Write this code down somewhere safe; it is your **activation bytes** and will be reused for all your Audible audiobooks.

Once you have the code, you are done with `audible-cli`. If you want, you can leave the venv by running:
#### bash: to leave audible-cli
`deactivate`

---

## Prepare and run conversion script
### 1. Place `aax2m4b_batch.sh` and Prepare Folders
1. Copy the `aax2m4b_batch.sh` script file into: `~/Music/audiobooks`
    - You can create the folder if it doesn’t exist    
2. Create the **input** folder for AAX files: `~/Music/audiobooks/aax`
3. Create the **output** folder for M4B files (the script will also do this, but it’s good to confirm): `~/Music/audiobooks/need_to_zip`
4. Move your `.aax` files into the `aax` folder

---

### 2. Configure the Script (Activation Bytes and Paths)
Open `aax2m4b_batch.sh` in a text editor

#### bash:  example uses Nano
`cd ~/Music/audiobooks nano aax2m4b_batch.sh`

At the top of the file you will see configuration variables similar to:

`ACT="1abc2345" 
`SRC_DIR="$HOME/Music/audiobooks/aax"` `DST_DIR="$HOME/Music/audiobooks/need_to_zip"`

1. **ACT**    
    - Replace `1abc2345` with your own 8‑character activation bytes from [[How to convert AAX2M4B#5. Get Your Activation Bytes|System Setup - Get Your Activation Bytes]].
2. **SRC_DIR** (input folder)
    - If you want to keep the default `~/Music/audiobooks/aax`, leave this unchanged.
    - To change it, point it to any directory where you store your `.aax` files, for example:  `SRC_DIR="$HOME/AudioBooks/raw_aax"`
3. **DST_DIR** (output folder)
    - Default is `~/Music/audiobooks/need_to_zip`.
    - You can change this to another folder if you prefer, for example: `DST_DIR="$HOME/AudioBooks/clean_m4b"`
4. When you’re done editing:
	- In Nano, press `Ctrl+O` then Enter to save, and `Ctrl+X` to exit.
	- In most other editors (Atom, VS Code, etc.) just save the file.

---

### 3. Make the Script Executable
#### bash: navigate to directory the script is in and make the script exicutable
`cd ~/Music/audiobooks chmod +x ./aax2m4b_batch.sh`

---

### 4. Run the Batch Conversion
#### bash: From `~/Music/audiobooks`
`./aax2m4b_batch.sh`

#### Expected results:
- Scan the input directory (`SRC_DIR`) for `.aax` files.
- For each file:
    - Read metadata (author, series, title).
    - Build a reasonably short filename from those tags, falling back to the original filename if needed.
    - Use `ffmpeg` with your activation bytes to decrypt and repackage audio into `.m4b`.
    - Strip all non‑book metadata (no machine name, no Amazon‑specific or personal data), and write back only author, title, and series tags.

When it finishes, look in your output directory (`DST_DIR`, by default `~/Music/audiobooks/need_to_zip`) for the `.m4b` files.

---

## Basic Troubleshooting
###  “command not found: ffmpeg”
Re‑check the installation:
####  bash
`sudo apt install -y ffmpeg`

---

### “python: command not found” or `ModuleNotFoundError` for audible_cli
Make sure the virtual environment is active before running the Audible commands:    
#### bash  
`cd ~/audible-tools source venv/bin/activate`

Then rerun:
#### bash
`python -m audible_cli quickstart python -m audible_cli activation-bytes`

---

###  Script says “No such file or directory” for `.aax`
 Verify that your `.aax` files are actually in the folder pointed to by `SRC_DIR`.
#### bash
`ls "$SRC_DIR"`

---

### Filenames still too long
You can reduce `MAX_NAME_LEN` at the top of the script to a smaller number (for example 160).