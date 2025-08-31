### **Action Plan for Current Session**

**Overall Goal:** To organize the repository structure, refactor the core installation scripts, and then use them to set up the current OS environment.

---

### **Phase 1: Repository Organization**

**1. Create Folder Structure:**
    *   **Action:** Create 4 to 6 new folders to categorize the scripts and files based on their function (e.g., `setup`, `ai_ml`, `doc_processing`, `utils`, `terminal_fx`).

**2. Move and Rename Files:**
    *   **Action:** Move the existing scripts and files into the newly created folders.
    *   **Action:** Rename files as needed to better reflect their function.

---

### **Phase 2: Core Script Refactoring**

**1. Refactor Installation Scripts (now in the `setup` folder):**
    *   **Action:** Refactor `install_basic_ubuntu_set_1.sh` and `install_xfce_google_RDP.sh` into more modular functions.
    *   **Action:** Remove redundant commands and make hardcoded URLs into variables.
    *   **Action:** Add essential dependency checks (especially for Node.js).
    *   **Note:** Keep debugging `echo` statements for verification.

---

### **Phase 3: Documentation and Final Review**

**1. Update Documentation:**
    *   **Action:** Update `README.md` and other documentation to reflect the new file structure.
    *   **Action:** Ensure each script has a clear header.

---

### **Future Goals (Post-Session)**

*   Consolidate and refactor other scripts (Image/Docling processors).
*   Implement a centralized configuration management system.
*   Enhance error handling and code style across all scripts.
*   Perform Python script enhancements.