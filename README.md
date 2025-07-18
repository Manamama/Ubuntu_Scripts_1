# Ubuntu_Scripts_1
Semi-private scripts, mostly for bash jobs in brand new GitHub, Google, Microsoft platforms; some Remote Desktop shells or configurations; or system info for LLMs. 


Tip for myself: 


* **Bash shell shortcuts**
* **Terminator-specific shortcuts**
* **X11/terminal emulator conventions**


---

## 📜 **Core Bash shortcuts (work in any terminal)**

**Ctrl + A** → Move to beginning of line

**Ctrl + E** → Move to end of line

**Ctrl + U** → Delete from cursor to start of line

**Ctrl + K** → Delete from cursor to end of line

**Ctrl + W** → Delete the word before cursor

**Ctrl + Y** → Yank (paste) what you just cut with `Ctrl+U/K/W`

**Ctrl + L** → Clear screen (same as `clear`)

**Ctrl + C** → Send SIGINT to stop current command/process

**Ctrl + Z** → Send SIGTSTP to suspend current process to background

**Ctrl + R** → Reverse search through command history

**Ctrl + D** → Log out of terminal (or send EOF)

**Ctrl + T** → Transpose (swap) two characters around cursor

**Ctrl + \_** → Undo (only one level in Bash)

**Alt + B** → Move back one word

**Alt + F** → Move forward one word

**Alt + D** → Delete word after cursor

**Alt + .** → Insert last argument of previous command

**Alt + U** → Uppercase word from cursor

**Alt + L** → Lowercase word from cursor

**Alt + T** → Transpose words

---

## 🖥️ **Terminator-specific shortcuts**

Terminator binds some `Ctrl + Shift` combos instead of plain `Ctrl`, to avoid clashing with Bash.

**Ctrl + Shift + T** → Open new tab

**Ctrl + Shift + N** → Open new window

**Ctrl + Shift + O** → Split terminal horizontally

**Ctrl + Shift + E** → Split terminal vertically

**Ctrl + Shift + W** → Close current terminal pane

**Ctrl + Shift + Q** → Quit Terminator

**Alt + Arrow Key** → Move focus between split panes

**Ctrl + Shift + ↑ / ↓ / ← / →** → Resize split panes


---

## ⚙️ **GNOME terminal conventions**

GNOME doesn’t hijack your terminal keys much, but system-level shortcuts can interfere:

* **Alt + F2** → Opens GNOME run dialog (outside the terminal)

* **Alt + Tab** → Window switcher (global)

---

## 🧩 **X11 note**

On X11, `Alt` is handled as `Meta` — so these should Just Work unless you remap keys or the window manager grabs them. Mutter generally won’t override typical Bash `Alt` shortcuts inside the terminal.

---

## ⚡ **One hidden gotcha**

If you’re using `terminator` inside GNOME with `gdm3` and Mutter, remember that `Alt` shortcuts sometimes get grabbed by the window manager. If a shortcut isn’t working, it’s usually the window manager, not Bash.

---

### **TL;DR**

**`Ctrl` = line editing and control.**

**`Alt` = word-level editing and argument reuse.**

**`Ctrl + Shift` = terminal pane/tab management in `terminator`.**

---
