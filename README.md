# AAX to M4B Batch Converter

Batch-convert Audible `.aax` files to `.m4b` on Ubuntu-based Linux distributions using `ffmpeg` and a one-time Audible activation code. The script is designed for local use, strips identifying metadata, keeps book metadata, and writes clean `.m4b` files with safer filenames.

## What it does

- Converts Audible `.aax` files to `.m4b`.
- Uses `ffmpeg` with your Audible activation bytes.
- Reads metadata from each source file and uses it to build cleaner filenames.
- Falls back to the original `.aax` filename when metadata is missing or the generated filename would be too long.
- Removes non-book metadata and writes back only book-related metadata such as title, author, and series.
- Looks for source files in `~/Music/audiobooks/aax` by default.
- Writes output files to `~/Music/audiobooks/need_to_zip` by default.

## Target systems

This project is intended for Ubuntu-based Linux distributions, including:

- Ubuntu
- Pop!_OS
- Linux Mint
- Similar Debian/Ubuntu derivatives

It assumes a typical `ext4` filesystem, where a single filename component has a practical limit of 255 bytes.

## Repository contents

- `aax2m4b_batch.sh` — the conversion script
- `How to convert AAX2M4B.md` — detailed setup and usage guide
- `requirements.txt` — quick dependency and setup summary

## Requirements

You need the following installed on your system:

- `ffmpeg`
- `python3`
- `python3-venv`
- `python3-pip`
- `git` (optional for this script itself, but useful for distribution and setup)

### Install requirements with:
```bash
sudo apt update
sudo apt install -y ffmpeg python3 python3-venv python3-pip git
```

## Setup overview

The full walkthrough is in `How-to-convert-AAX2M4B.md`. At a high level, the process is:

1. Install system dependencies.
2. Create a Python virtual environment.
3. Install `audible-cli` in that virtual environment.
4. Run `python -m audible_cli quickstart` and complete browser login.
5. Run `python -m audible_cli activation-bytes` to get your 8-character activation code.
6. Edit `aax2m4b_batch.sh` and replace the placeholder activation code with your real one.
7. Put your `.aax` files in the input folder.
8. Run the script.

## Default paths

By default, the script uses:

- Input folder: `~/Music/audiobooks/aax`
- Output folder: `~/Music/audiobooks/need_to_zip`

These can be changed in the configuration block near the top of `aax2m4b_batch.sh`.

## Quick start

### Create the default folders:
```bash
mkdir -p ~/Music/audiobooks/aax
mkdir -p ~/Music/audiobooks/need_to_zip
```

### Make the script executable:
```bash
cd ~/Music/audiobooks
chmod +x ./aax2m4b_batch.sh
```

### Run the script:
```bash
./aax2m4b_batch.sh
```

## Activation bytes

This script requires your Audible activation bytes. These are obtained once using `audible-cli`, then pasted into the script.

The setup guide documents the full process, including the `audible-cli` questions and suggested answers.

## Metadata behavior

The script is intentionally opinionated about metadata hygiene:

- Removes all metadata from the output first.
- Re-adds only book-relevant metadata extracted from the source file.
- Drops non-audio streams such as cover images or extra data streams.

This helps remove device- or account-related metadata while keeping useful audiobook fields.

## Filename behavior

The script tries to name output files using available metadata in this priority order:

1. author + series + title
2. author + title
3. series + title
4. author + series + original filename
5. author + original filename
6. series + original filename
7. title only
8. original filename

If the generated name is too long, it truncates or falls back to the sanitized original filename.

## Documentation

For full instructions, see:

- `How-to-convert-AAX2M4B.md`
- `requirements.md`

## Notes

- This project is meant for personal backup and format-shifting of audiobooks you already own.
- You must supply your own activation bytes.
- No cloud conversion or external upload is required for the script itself.

## License

If you plan to publish this repository, add a license file such as MIT or Apache-2.0 so others can clearly reuse the script.
