// MightyLink Background Service Worker (Manifest V3)

chrome.runtime.onInstalled.addListener(() => {
  // Initialize default storage
  chrome.storage.local.get(["pairingKey", "workspaces", "savedLinks", "apiUrl"], (data) => {
    if (!data.apiUrl) {
      chrome.storage.local.set({ apiUrl: "http://localhost:5000" });
    }
    if (!data.pairingKey) {
      chrome.storage.local.set({ pairingKey: "ML-8942-SYNC" });
    }
    if (!data.workspaces) {
      chrome.storage.local.set({
        workspaces: ["General", "Design System", "Development", "Marketing", "Read Later"],
      });
    }
    if (!data.savedLinks) {
      chrome.storage.local.set({ savedLinks: [] });
    }
  });

  // Setup Context Menus
  chrome.contextMenus.create({
    id: "mightylink-save-page",
    title: "Save page to MightyLink",
    contexts: ["page"],
  });

  chrome.contextMenus.create({
    id: "mightylink-save-link",
    title: "Save this link to MightyLink",
    contexts: ["link"],
  });
});

// Handle Context Menu clicks
chrome.contextMenus.onClicked.addListener((info, tab) => {
  let title = tab ? tab.title : "Bookmark";
  let url = tab ? tab.url : "";

  if (info.menuItemId === "mightylink-save-link" && info.linkUrl) {
    url = info.linkUrl;
    title = info.selectionText || info.linkUrl;
  }

  saveBookmarkFromBackground(title, url, tab ? tab.favIconUrl : "");
});

// Handle Keyboard Shortcuts
chrome.commands.onCommand.addListener(async (command) => {
  if (command === "quick-save") {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tab && tab.url) {
      saveBookmarkFromBackground(tab.title || "Untitled", tab.url, tab.favIconUrl || "");
    }
  }
});

function saveBookmarkFromBackground(title, url, favicon) {
  chrome.storage.local.get(["savedLinks", "defaultWorkspace", "userEmail", "authToken", "apiUrl"], async (result) => {
    const links = result.savedLinks || [];
    const workspace = result.defaultWorkspace || "General";
    const userEmail = result.userEmail || "alex@mightylink.io";
    const token = result.authToken;
    const apiUrl = result.apiUrl || "http://localhost:5000";

    const newBookmark = {
      id: "bm_" + Date.now(),
      userEmail,
      title,
      url,
      workspace,
      isFavorite: false,
      isReminder: false,
      isVault: false,
      notes: "Saved via shortcut / context menu",
      favicon,
      savedAt: new Date().toISOString(),
    };

    // Post to unified cloud API
    if (token) {
      try {
        await fetch(`${apiUrl}/api/links`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${token}`
          },
          body: JSON.stringify(newBookmark)
        });
      } catch (err) {
        console.warn("Could not post to cloud API from background:", err);
      }
    }

    links.unshift(newBookmark);
    chrome.storage.local.set({ savedLinks: links }, () => {
      // Set visual badge confirmation
      chrome.action.setBadgeText({ text: "✓" });
      chrome.action.setBadgeBackgroundColor({ color: "#15CA91" });

      setTimeout(() => {
        chrome.action.setBadgeText({ text: "" });
      }, 2500);
    });
  });
}
