Okay, let’s lay this out clearly and technically, no euphemisms:

---

### **1. Overlay filesystem basics**

An **overlay filesystem** is a union mount: it merges two (or more) filesystems into a single view:

* **Lowerdir** – the “base” read-only layer. Think of this as the original filesystem you’re not supposed to touch.
* **Upperdir** – the “writable” layer. All changes (file creations, modifications, deletions) go here.
* **Workdir** – an internal scratch area that the overlay filesystem uses to manage copy-on-write operations.

The overlay filesystem presents a **merged view** to the user. When you `ls` or `du` the mount point, you see all files from both layers combined.

---

### **2. Copy-on-write (COW) principle**

The overlay uses **copy-on-write** for modifications:

* If a file exists in `lowerdir` and you modify it, the system first **copies it to `upperdir`**, then applies your changes there.
* If a file exists only in `upperdir`, it is already “live.”
* The original `lowerdir` remains untouched — that’s why it can be read-only and shared among multiple overlay mounts.

So the “real” space consumption isn’t just what you see in the merged view. It’s mostly in:

1. The `upperdir` (where modifications live)
2. Any extra COW copies for files you’ve changed

This is why `du` on the overlay mount can **underreport or mislead** if you don’t look at the `upperdir`. The `upperdir` is where the actual disk blocks are being consumed.

---

### **3. Practical effect in your Codespaces example**

From your ncdu output:

```
19.3 GiB /tmp
9.0 GiB /opt
7.3 GiB /usr
6.3 GiB /.codespaces
6.1 GiB /vscode
5.6 GiB /home
```

* The overlay mount (`/`) shows 32 GB used.
* Most of that is **COW writes in upperdir** plus “real” usage in `/tmp`, `/opt`, `/usr`, etc.
* `df` shows **apparent used space** on the overlay, which includes the merged layers.
* `du` on the overlay will see the merged files but **can’t distinguish which ones are in `upperdir` vs `lowerdir`**, which is why your experiments with `upperdir` inspection were necessary.

---

**In short:**

* `overlay upperdir` = actual writable storage where your changes accumulate.
* COW layers = copies made of files from the read-only lower layer when you modify them.
* The merged mount is a **view**, not the real physical usage; the physical space is almost entirely in `upperdir` + any new files you created.

---




Got it — you want a real text-based diagram (ASCII/graph style) showing the overlay filesystem, the layers, and the copy-on-write mechanism. Here’s a detailed one:

┌───────────────────────┐ │ Overlay │ │ (merged view /) │ └─────────┬────────────┘ │ ┌─────────────────┴─────────────────┐ │ │ ┌──────▼───────┐ ┌───────▼───────┐ │ Upperdir │ │ Lowerdir │ │ (writable) │ │ (read-only) │ └──────┬────────┘ └──────┬────────┘ │ │ ┌─────────▼─────────┐ ┌───────▼─────────┐ │ New / Modified │ │ Original files │ │ files go │ │ unchanged │ │ here (COW) │ └─────────────────┘ └─────────┬─────────┘ │ ┌─────────▼─────────┐ │ Workdir │ │ (internal scratch │ │ for COW ops) │ └───────────────────┘ 

How it works (step by step)

Lowerdir contains the original read-only filesystem (e.g., system libraries, /usr, /opt in Codespaces).

Upperdir is writable: any new files or modifications go here.

Workdir is an internal workspace used by the overlay system to track COW changes (not directly visible to users).

Overlay mount combines upperdir + lowerdir into a single view — this is what df and du usually show.

Copy-on-write (COW) happens when a file in lowerdir is modified: the file is copied to upperdir first, then changed. lowerdir stays unchanged.

