document.addEventListener("DOMContentLoaded", () => {
  const displayEmail = document.getElementById("displayEmail");
  const badgeAvatar = document.getElementById("badgeAvatar");
  const switchAccountBtn = document.getElementById("switchAccountBtn");
  const emailEditArea = document.getElementById("emailEditArea");
  const emailInput = document.getElementById("emailInput");
  const saveEmailBtn = document.getElementById("saveEmailBtn");
  const toast = document.getElementById("toast");
  const linksBody = document.getElementById("linksBody");
  const linkCountDesc = document.getElementById("linkCountDesc");

  // Load Account
  chrome.storage.local.get(["userEmail", "savedLinks"], (data) => {
    const email = data.userEmail || "alex@mightylink.io";
    displayEmail.textContent = email;
    emailInput.value = email;
    badgeAvatar.textContent = email[0].toUpperCase();

    renderLinks(data.savedLinks || [], email);
  });

  switchAccountBtn.addEventListener("click", () => {
    emailEditArea.style.display = emailEditArea.style.display === "none" ? "block" : "none";
    emailInput.focus();
  });

  saveEmailBtn.addEventListener("click", () => {
    const newEmail = emailInput.value.trim().toLowerCase();
    if (newEmail && newEmail.includes("@")) {
      const name = newEmail.split("@")[0];
      chrome.storage.local.set({
        userEmail: newEmail,
        userName: name.charAt(0).toUpperCase() + name.slice(1),
      }, () => {
        displayEmail.textContent = newEmail;
        badgeAvatar.textContent = newEmail[0].toUpperCase();
        emailEditArea.style.display = "none";

        toast.style.display = "block";
        setTimeout(() => {
          toast.style.display = "none";
        }, 2500);

        chrome.storage.local.get(["savedLinks"], (d) => {
          renderLinks(d.savedLinks || [], newEmail);
        });
      });
    }
  });

  function renderLinks(links, currentEmail) {
    linkCountDesc.textContent = `${links.length} bookmarks synced with account`;
    if (links.length === 0) return;

    linksBody.innerHTML = "";
    links.slice(0, 25).forEach((link) => {
      const tr = document.createElement("tr");

      const tdTitle = document.createElement("td");
      const a = document.createElement("a");
      a.href = link.url;
      a.target = "_blank";
      a.textContent = link.title || link.url;
      a.style.color = "#5619F6";
      a.style.textDecoration = "none";
      a.style.fontWeight = "600";
      tdTitle.appendChild(a);

      const tdWorkspace = document.createElement("td");
      tdWorkspace.textContent = link.workspace || "General";

      const tdAccount = document.createElement("td");
      tdAccount.textContent = link.userEmail || currentEmail;
      tdAccount.style.color = "#64748B";

      const tdDate = document.createElement("td");
      const d = new Date(link.savedAt);
      tdDate.textContent = isNaN(d) ? "Recently" : d.toLocaleDateString();
      tdDate.style.color = "#64748B";

      tr.appendChild(tdTitle);
      tr.appendChild(tdWorkspace);
      tr.appendChild(tdAccount);
      tr.appendChild(tdDate);
      linksBody.appendChild(tr);
    });
  }
});
