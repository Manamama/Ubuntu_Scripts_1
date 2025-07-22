### **Cleanup Plan for `Ubuntu_Scripts_1` Repository**

**Overall Goal:** To streamline, organize, and improve the maintainability, usability, and clarity of the scripts within the `Ubuntu_Scripts_1` repository.

---

#### **Phase 1: Initial Repository Housekeeping & Incompatible File Removal**

1.  **Remove Incompatible Files:**
    *   **Action:** Delete `tesseract_to_pdf.bat`. **[DONE]**
    *   **Rationale:** This is a Windows Batch script (`.bat` extension) and is entirely incompatible with the Linux/Ubuntu/Termux environment that the rest of the repository targets. It serves no functional purpose here and adds clutter.

2.  **Update Repository `README.md`:**
    *   **Action:** Revise `README.md` to focus on the purpose and usage of the *scripts* in the repository. **[DONE]**
    *   **Rationale:** The current `README.md` primarily contains general Bash and Terminator shortcuts, which are not directly related to the scripts' functionality.
    *   **Sub-Action:** Create a new Markdown file (e.g., `docs/shell_shortcuts.md` or `shortcuts.md`) and move the general shell/Terminator/X11 shortcuts there. **[DONE]**

---

#### **Phase 2: Script Consolidation & Refactoring**

1.  **Image Description & HTML Generation Scripts:**
    *   **Scripts Involved:** `describe_images_in_folder.sh`, `describe_images_in_subfolders.sh`, `describe_image_to_exif.sh`.
    *   **Proposed Action:** Consolidate `describe_images_in_folder.sh` into `describe_images_in_subfolders.sh`. Rename the resulting script to `image_html_generator.sh` (or similar). **[DONE]**
    *   **Rationale:** `describe_images_in_subfolders.sh` is the most feature-rich (recursive traversal, HTML generation, PDF conversion, TTS). The functionality of `describe_images_in_folder.sh` is a subset. `describe_image_to_exif.sh` can either be integrated as a function within `image_html_generator.sh` (e.g., `--add-exif-description <image_path>`) or remain a standalone, clearly documented utility for single-image EXIF manipulation if a lightweight option is desired.
    *   **Key Improvements:**
        *   Address the TTS "racing condition" and commented-out TTS lines for robustness.
        *   Make LLM model paths (`/storage/emulated/0/LLMs/...`) configurable via command-line arguments or a configuration file.

2.  **Docling Processing Scripts:**
    *   **Scripts Involved:** `docling_me.sh`, `docling_me.2.sh`.
    *   **Proposed Action:** Consolidate `docling_me.sh` into `docling_me.2.sh`. Rename the resulting script to `docling_processor.sh`. **[DONE]**
    *   **Rationale:** `docling_me.2.sh` appears to be the more advanced version. Any unique, valuable logic or comments from `docling_me.sh` should be carefully merged.
    *   **Key Improvements:**
        *   Remove extensive commented-out code blocks.
        *   Refine error handling for external tools (`exiftool`, `pdfcpu`, `qpdf`, `docling`).
        *   Make hardcoded paths (e.g., `~/.cache/docling/models`) configurable.
        *   Improve overall clarity and modularity by breaking down large sections into smaller functions.

3.  **Specialized OCR Scripts:**
    *   **Scripts Involved:** `easyocr_pdf_to_txt.sh`, `tesseract_pdf.sh`, `Tesseract_to_txt.sh`.
    *   **Proposed Action:** Assess the unique value of these scripts compared to the consolidated `docling_processor.sh`.
        *   **Option A (Preferred for consolidation):** Integrate their core OCR engine-specific logic as options within `docling_processor.sh` if `docling`'s API allows for such fine-grained control. This would reduce redundancy.
        *   **Option B (If integration is complex/unnecessary):** Keep them as standalone scripts, but clearly document their specific use cases (e.g., "Use `easyocr_pdf_to_txt.sh` for quick EasyOCR PDF extraction when `docling_processor.sh` is overkill or not installed").
    *   **Key Improvements (if kept standalone):**
        *   Improve error handling for `pdftoppm`, `easyocr`, `tesseract`.
        *   Add explicit dependency checks for `pdftoppm`, `easyocr`, `tesseract`, `ttok`.
        *   Make hardcoded audio paths (`play /home/zezen/Music/...`) configurable or remove them.
        *   Remove cosmetic dependencies like `lolcat` or make them optional. **[DONE - deleted scripts, integrated bells and whistles into `docling_processor.sh`]**

---

#### **Phase 3: Cross-Cutting Improvements & Standardization**

1.  **Configuration Management:**
    *   **Action:** Introduce a centralized method for managing common configurations (e.g., a `config.sh` file sourced by other scripts, or environment variables). **[DONE]**
    *   **Rationale:** Reduce hardcoded paths and values across multiple scripts, making them more portable and easier to manage.

2.  **Error Handling & Robustness:**
    *   **Action:** Standardize and enhance error checking for external command execution. **[DONE]**
    *   **Rationale:** Ensure scripts fail gracefully and provide informative messages when dependencies are missing or commands fail.

3.  **Dependency Checks:**
    *   **Action:** Implement explicit checks at the beginning of each script for all required external tools (e.g., `command -v jq || { echo "Error: jq not found..."; exit 1; }`). **[DONE]**
    *   **Rationale:** Provide clear guidance to the user on missing dependencies.

4.  **Code Style & Readability:**
    *   **Action:** Apply consistent formatting, naming conventions, and commenting practices across all scripts. **[DONE - image_html_generator.sh completed, docling_processor.sh skipped for precise formatting]**
    *   **Rationale:** Improve maintainability and make it easier for others (and future self) to understand the code.

5.  **User Feedback & Debugging:**
    *   **Action:** Remove or make conditional any debugging `echo` statements. **[DONE]**
    *   **Rationale:** Provide clean output during normal execution, with verbose debugging available via a flag if needed.

6.  **Python Script Enhancements:**
    *   **Scripts Involved:** `unhyphenate.py`, `wiki_feed_html_renderer.py`.
    *   **Action:** Add `requirements.txt` files to specify Python dependencies (`dehyphen`, `requests`). **[DONE]**
    *   **Action:** For `unhyphenate.py`, make the language (`lang="pl"`) a command-line argument. **[DONE]**
    *   **Action:** For `wiki_feed_html_renderer.py`, make the browser configurable and consider using `argparse` for more robust command-line argument parsing. **[DONE]**

7.  **Installation Scripts (`install_basic_ubuntu_set_1.sh`, `install_xfce_google_RDP.sh`):**
    *   **Action:** Refactor into more modular functions (e.g., `install_core_tools`, `configure_rdp`). **[DONE]**
    *   **Action:** Remove redundant `apt` commands. **[DONE]**
    *   **Action:** Review and potentially automate steps requiring manual user interaction (e.g., `adduser`).
    *   **Action:** Make hardcoded download URLs variables. **[DONE]**

8.  **X11 Script (`X11.sh`):**
    *   **Action:** Add error handling for `pkill`, `termux-x11`, and `am start`. **[DONE]**
    *   **Action:** Improve comments and potentially add a clear header. **[DONE]**

---

#### **Phase 4: Final Review & Documentation**

1.  **Comprehensive `README.md`:**
    *   **Action:** Ensure the main `README.md` provides a clear, concise overview of the repository's purpose, a list of all available scripts (with brief descriptions), and instructions on how to use them. **[DONE]**
    *   **Action:** Include a "Dependencies" section with a link to a central dependency list or instructions. **[DONE]**

2.  **Individual Script Documentation:**
    *   **Action:** Ensure each script has a clear header (purpose, usage, version, author, dependencies). **[DONE]**
