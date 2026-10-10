# Terminal Basics

A terminal (also called the command line or shell) is a text-based interface where you type commands and press Enter to run them. Unlike clicking icons in a file manager, you interact with your computer by typing — which makes it fast and scriptable.

## Opening a Terminal

**macOS**
1. Press `Cmd + Space` to open Spotlight Search.
2. Type `terminal` and press `Enter`.
3. A Terminal window opens. You're ready to type commands.

**Windows**
1. Press `Win + R` to open the Run dialog.
2. Type `cmd` and press `Enter` to open Command Prompt. (Alternatively, search for "PowerShell" in the Start menu for a more capable shell.)
3. A black window with a prompt appears.

**Linux**
- Most desktop environments have a keyboard shortcut like `Ctrl + Alt + T`.
- Or right-click the desktop and choose "Open Terminal".
- If you installed qData system-wide, make sure the install directory is on your `PATH` (the installer will tell you how).

---

## Navigating Directories

Your terminal always has a "current directory" — the folder it is currently looking at.

**See where you are**
```
pwd
```
Prints the full path of your current directory, for example `/home/alice/projects`.

**List files in the current directory**

On macOS/Linux:
```
ls
```
On Windows:
```
dir
```

**Change directory**
```
cd folder_name
```
Move into `folder_name` inside your current directory.

```
cd ..
```
Move up one level to the parent directory.

```
cd /home/alice/projects
```
Move to an absolute path (works from anywhere).

---

## Running a Command

Type the command, then press `Enter`. The terminal does nothing until you press `Enter`.

Example:
```
qdata run sql
```
Type that, press `Enter`, and qData starts the pipeline.

---

## Understanding Paths

A path tells the computer where a file or folder lives.

**Absolute path** — starts from the root of your file system. Always works no matter where you are.
- macOS/Linux: starts with `/`, e.g. `/home/alice/demo/sql`
- Windows: starts with a drive letter, e.g. `C:\Users\Alice\demo\sql`

**Relative path** — starts from your current directory.
- `sql` means the `sql` folder inside wherever you are now.
- `./sql` means the same thing (`.` is shorthand for "current directory").
- `../other` means go up one level, then into `other`.

When in doubt, use `pwd` to check where you are, then build your path from there.

---

## Common Beginner Mistakes

**Spaces in file or folder names**

A path with a space confuses the terminal unless you quote it:
```
cd "My Projects"   # correct
cd My Projects     # wrong — the shell sees two arguments
```
Tip: avoid spaces in project folder names. Use underscores or hyphens instead (`my_project`, `my-project`).

**Forgetting to press Enter**

Nothing runs until you press `Enter`. If a command seems to do nothing, check that you actually pressed it.

**Wrong directory**

If qData says it cannot find your SQL files, you are probably in the wrong folder. Run `pwd` to see where you are, then `cd` to the right place.

**Capital letters on Linux/macOS**

File names are case-sensitive on Linux and macOS. `SQL` and `sql` are different directories. Windows is usually case-insensitive, so this catches people who switch between systems.

---

Now that you are comfortable with the terminal, head back to the [Quick Start](../README.md#quickstart) to run your first pipeline.
