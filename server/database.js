const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, 'data');
const USERS_FILE = path.join(DATA_DIR, 'users.json');
const LINKS_FILE = path.join(DATA_DIR, 'links.json');

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

function readJSON(filePath, defaultValue) {
  try {
    if (!fs.existsSync(filePath)) {
      fs.writeFileSync(filePath, JSON.stringify(defaultValue, null, 2));
      return defaultValue;
    }
    const raw = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(raw);
  } catch (err) {
    console.error(`Error reading ${filePath}:`, err);
    return defaultValue;
  }
}

function writeJSON(filePath, data) {
  try {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
  } catch (err) {
    console.error(`Error writing ${filePath}:`, err);
  }
}

class Database {
  // Users
  static getUsers() {
    return readJSON(USERS_FILE, []);
  }

  static findUserByEmail(email) {
    const users = this.getUsers();
    return users.find(u => u.email.toLowerCase() === email.toLowerCase());
  }

  static findUserById(id) {
    const users = this.getUsers();
    return users.find(u => u.id === id);
  }

  static createUser(user) {
    const users = this.getUsers();
    users.push(user);
    writeJSON(USERS_FILE, users);
    return user;
  }

  // Links / Bookmarks
  static getLinks(userId) {
    const allLinks = readJSON(LINKS_FILE, []);
    return allLinks.filter(l => l.userId === userId);
  }

  static getAllLinks() {
    return readJSON(LINKS_FILE, []);
  }

  static addLink(link) {
    const allLinks = readJSON(LINKS_FILE, []);
    allLinks.unshift(link);
    writeJSON(LINKS_FILE, allLinks);
    return link;
  }

  static updateLink(userId, linkId, updates) {
    const allLinks = readJSON(LINKS_FILE, []);
    const idx = allLinks.findIndex(l => l.id === linkId && l.userId === userId);
    if (idx === -1) return null;
    allLinks[idx] = { ...allLinks[idx], ...updates, updatedAt: new Date().toISOString() };
    writeJSON(LINKS_FILE, allLinks);
    return allLinks[idx];
  }

  static deleteLink(userId, linkId) {
    let allLinks = readJSON(LINKS_FILE, []);
    const initialLen = allLinks.length;
    allLinks = allLinks.filter(l => !(l.id === linkId && l.userId === userId));
    if (allLinks.length !== initialLen) {
      writeJSON(LINKS_FILE, allLinks);
      return true;
    }
    return false;
  }

  static syncBatch(userId, incomingLinks) {
    let allLinks = readJSON(LINKS_FILE, []);
    const userLinksMap = new Map();
    
    // Existing user links
    allLinks.filter(l => l.userId === userId).forEach(l => {
      userLinksMap.set(l.id || l.url, l);
    });

    // Merge incoming
    incomingLinks.forEach(item => {
      const key = item.id || item.url;
      const existing = userLinksMap.get(key);
      if (!existing) {
        userLinksMap.set(key, {
          ...item,
          id: item.id || 'bm_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6),
          userId,
          savedAt: item.savedAt || new Date().toISOString()
        });
      } else {
        // keep latest
        userLinksMap.set(key, { ...existing, ...item, userId });
      }
    });

    // Replace in allLinks
    const otherLinks = allLinks.filter(l => l.userId !== userId);
    const updatedUserLinks = Array.from(userLinksMap.values());
    allLinks = [...updatedUserLinks, ...otherLinks];
    writeJSON(LINKS_FILE, allLinks);

    return updatedUserLinks;
  }
}

module.exports = Database;
