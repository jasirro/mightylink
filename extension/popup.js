document.addEventListener("DOMContentLoaded", async () => {
  // Navigation / Views
  const loginView = document.getElementById("loginView");
  const saveFormView = document.getElementById("saveFormView");
  const successView = document.getElementById("successView");
  const accountModalView = document.getElementById("accountModalView");
  const appFooter = document.getElementById("appFooter");

  // Header Elements
  const accountPill = document.getElementById("accountPill");
  const headerUserEmail = document.getElementById("headerUserEmail");
  const openSettingsBtn = document.getElementById("openSettingsBtn");

  // Auth View Elements
  const loginEmailInput = document.getElementById("loginEmailInput");
  const emailLoginBtn = document.getElementById("emailLoginBtn");

  // Bookmark Form Elements
  const tabFavicon = document.getElementById("tabFavicon");
  const tabDomain = document.getElementById("tabDomain");
  const tabUrl = document.getElementById("tabUrl");
  const linkTitleInput = document.getElementById("linkTitleInput");
  const workspaceSelect = document.getElementById("workspaceSelect");
  const favoriteCheck = document.getElementById("favoriteCheck");
  const reminderCheck = document.getElementById("reminderCheck");
  const vaultCheck = document.getElementById("vaultCheck");
  const linkNotesInput = document.getElementById("linkNotesInput");
  const saveLinkBtn = document.getElementById("saveLinkBtn");

  // Success Elements
  const successSubtitle = document.getElementById("successSubtitle");
  const copySavedUrlBtn = document.getElementById("copySavedUrlBtn");
  const doneBtn = document.getElementById("doneBtn");

  // Account Modal Elements
  const accountAvatarLetter = document.getElementById("accountAvatarLetter");
  const accountDisplayName = document.getElementById("accountDisplayName");
  const accountModalEmail = document.getElementById("accountModalEmail");
  const logoutBtn = document.getElementById("logoutBtn");
  const closeAccountModalBtn = document.getElementById("closeAccountModalBtn");
  const viewAllLinksLink = document.getElementById("viewAllLinksLink");

  let currentTab = null;
  let currentUser = null;

  // 1. Detect Active Browser Tab
  try {
    const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tabs && tabs.length > 0) {
      currentTab = tabs[0];
      const urlObj = new URL(currentTab.url);

      linkTitleInput.value = currentTab.title || "";
      tabDomain.textContent = urlObj.hostname || "Webpage";
      tabUrl.textContent = currentTab.url;

      if (currentTab.favIconUrl) {
        tabFavicon.src = currentTab.favIconUrl;
      }
    }
  } catch (err) {
    console.error("Tab query error:", err);
  }

  // 2. Check Auth Session
  chrome.storage.local.get(["userEmail", "userName", "workspaces"], (data) => {
    if (data.userEmail) {
      currentUser = {
        email: data.userEmail,
        name: data.userName || data.userEmail.split("@")[0],
      };
      setupLoggedInUI(currentUser);
    } else {
      setupLoggedOutUI();
    }

    // Load account workspaces
    if (data.workspaces && Array.isArray(data.workspaces)) {
      workspaceSelect.innerHTML = "";
      data.workspaces.forEach((ws) => {
        const opt = document.createElement("option");
        opt.value = ws;
        opt.textContent = `📁 ${ws}`;
        workspaceSelect.appendChild(opt);
      });
    }
  });

  function setupLoggedInUI(user) {
    headerUserEmail.textContent = user.email;
    accountPill.style.display = "flex";
    accountDisplayName.textContent = user.name;
    accountModalEmail.textContent = user.email;
    accountAvatarLetter.textContent = (user.name || user.email)[0].toUpperCase();

    loginView.classList.remove("active");
    accountModalView.classList.remove("active");
    successView.classList.remove("active");
    saveFormView.classList.add("active");
    appFooter.style.display = "flex";
  }

  function setupLoggedOutUI() {
    accountPill.style.display = "none";
    saveFormView.classList.remove("active");
    accountModalView.classList.remove("active");
    successView.classList.remove("active");
    loginView.classList.add("active");
    appFooter.style.display = "none";
  }

  // 3. Email Sign-In Action
  function performEmailLogin() {
    const email = loginEmailInput.value.trim().toLowerCase();
    if (!email || !email.includes("@")) {
      loginEmailInput.focus();
      return;
    }

    const name = email.split("@")[0];
    const initialWorkspaces = ["General", "Design System", "Development", "Marketing", "Read Later"];

    chrome.storage.local.set({
      userEmail: email,
      userName: name.charAt(0).toUpperCase() + name.slice(1),
      workspaces: initialWorkspaces,
      pairingKey: "ML-ACCOUNT-SYNC",
    }, () => {
      currentUser = { email, name };
      setupLoggedInUI(currentUser);
    });
  }

  emailLoginBtn.addEventListener("click", performEmailLogin);
  loginEmailInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") performEmailLogin();
  });

  // 4. Save Bookmark Action
  async function saveBookmark() {
    if (!currentTab || !currentUser) return;

    const title = linkTitleInput.value.trim() || currentTab.title || "Untitled";
    const url = currentTab.url;
    const workspace = workspaceSelect.value;
    const isFavorite = favoriteCheck.checked;
    const isReminder = reminderCheck.checked;
    const isVault = vaultCheck.checked;
    const notes = linkNotesInput.value.trim();

    const newBookmark = {
      id: "bm_" + Date.now(),
      userEmail: currentUser.email,
      title,
      url,
      workspace,
      isFavorite,
      isReminder,
      isVault,
      notes,
      favicon: currentTab.favIconUrl || "",
      savedAt: new Date().toISOString(),
    };

    chrome.storage.local.get(["savedLinks"], (result) => {
      const links = result.savedLinks || [];
      links.unshift(newBookmark);
      chrome.storage.local.set({ savedLinks: links }, () => {
        saveFormView.classList.remove("active");
        successView.classList.add("active");
        successSubtitle.textContent = `Synced to ${currentUser.email} under "${workspace}".`;
      });
    });
  }

  saveLinkBtn.addEventListener("click", saveBookmark);

  [linkTitleInput, linkNotesInput].forEach((input) => {
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") saveBookmark();
    });
  });

  // 5. Account Pill & Modals
  accountPill.addEventListener("click", () => {
    saveFormView.classList.remove("active");
    successView.classList.remove("active");
    accountModalView.classList.add("active");
  });

  closeAccountModalBtn.addEventListener("click", () => {
    accountModalView.classList.remove("active");
    saveFormView.classList.add("active");
  });

  logoutBtn.addEventListener("click", () => {
    chrome.storage.local.remove(["userEmail", "userName"], () => {
      currentUser = null;
      setupLoggedOutUI();
    });
  });

  // 6. Copy URL & Done Actions
  copySavedUrlBtn.addEventListener("click", () => {
    if (currentTab && currentTab.url) {
      navigator.clipboard.writeText(currentTab.url).then(() => {
        copySavedUrlBtn.innerHTML = "✓ Copied!";
        setTimeout(() => {
          copySavedUrlBtn.innerHTML = `
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
            Copy URL
          `;
        }, 2000);
      });
    }
  });

  doneBtn.addEventListener("click", () => {
    window.close();
  });

  openSettingsBtn.addEventListener("click", () => {
    if (chrome.runtime.openOptionsPage) {
      chrome.runtime.openOptionsPage();
    } else {
      window.open(chrome.runtime.getURL("options.html"));
    }
  });

  viewAllLinksLink.addEventListener("click", (e) => {
    e.preventDefault();
    if (chrome.runtime.openOptionsPage) {
      chrome.runtime.openOptionsPage();
    } else {
      window.open(chrome.runtime.getURL("options.html"));
    }
  });
});
