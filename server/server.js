const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const path = require('path');
const Database = require('./database');

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'mightylink-super-secret-key-2026';

// Middleware
app.use(cors({
  origin: '*', // Allow Flutter Web, Chrome Extension, Flutter App, and any client
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Auth Middleware
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
}

// ==================== AUTH ROUTES ====================

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString() });
});

// Register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, name } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const existing = Database.findUserByEmail(email);
    if (existing) {
      return res.status(409).json({ error: 'User with this email already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = 'usr_' + Date.now();
    const newUser = {
      id: userId,
      email: email.toLowerCase().trim(),
      name: name || email.split('@')[0],
      password: hashedPassword,
      createdAt: new Date().toISOString()
    };

    Database.createUser(newUser);

    // Create starter links
    Database.addLink({
      id: 'bm_' + Date.now(),
      userId,
      title: 'MightyLink Documentation',
      url: 'https://github.com/jasirro/mightylink',
      workspace: 'General',
      isFavorite: true,
      notes: 'Welcome to your unified 1-account link manager!',
      savedAt: new Date().toISOString()
    });

    const token = jwt.sign({ id: userId, email: newUser.email, name: newUser.name }, JWT_SECRET, { expiresIn: '30d' });

    res.status(201).json({
      message: 'Account created successfully',
      token,
      user: { id: userId, email: newUser.email, name: newUser.name }
    });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const user = Database.findUserByEmail(email);
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = jwt.sign({ id: user.id, email: user.email, name: user.name }, JWT_SECRET, { expiresIn: '30d' });

    res.json({
      message: 'Login successful',
      token,
      user: { id: user.id, email: user.email, name: user.name }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Current User Profile & Stats
app.get('/api/auth/me', authenticateToken, (req, res) => {
  const user = Database.findUserById(req.user.id);
  if (!user) return res.status(404).json({ error: 'User not found' });
  
  const links = Database.getLinks(user.id);
  res.json({
    user: { id: user.id, email: user.email, name: user.name, createdAt: user.createdAt },
    stats: {
      totalLinks: links.length,
      favorites: links.filter(l => l.isFavorite).length,
      workspaces: [...new Set(links.map(l => l.workspace || 'General'))]
    }
  });
});

// ==================== LINKS (CRUD) ====================

// Get all links for user
app.get('/api/links', authenticateToken, (req, res) => {
  const { workspace } = req.query;
  let links = Database.getLinks(req.user.id);
  if (workspace) {
    links = links.filter(l => l.workspace && l.workspace.toLowerCase() === workspace.toLowerCase());
  }
  res.json({ links });
});

// Add new link
app.post('/api/links', authenticateToken, (req, res) => {
  const { title, url, workspace, notes, isFavorite, isReminder, isVault, favicon } = req.body;
  if (!url) {
    return res.status(400).json({ error: 'URL is required' });
  }

  const newLink = {
    id: req.body.id || 'bm_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5),
    userId: req.user.id,
    title: title || url,
    url,
    workspace: workspace || 'General',
    notes: notes || '',
    isFavorite: !!isFavorite,
    isReminder: !!isReminder,
    isVault: !!isVault,
    favicon: favicon || '',
    savedAt: req.body.savedAt || new Date().toISOString()
  };

  Database.addLink(newLink);
  res.status(201).json({ message: 'Link saved successfully', link: newLink });
});

// Update link
app.put('/api/links/:id', authenticateToken, (req, res) => {
  const updated = Database.updateLink(req.user.id, req.params.id, req.body);
  if (!updated) {
    return res.status(404).json({ error: 'Link not found' });
  }
  res.json({ message: 'Link updated', link: updated });
});

// Delete link
app.delete('/api/links/:id', authenticateToken, (req, res) => {
  const deleted = Database.deleteLink(req.user.id, req.params.id);
  if (!deleted) {
    return res.status(404).json({ error: 'Link not found' });
  }
  res.json({ message: 'Link deleted successfully' });
});

// Batch Sync (Bi-directional sync between App, Extension, and Web)
app.post('/api/sync', authenticateToken, (req, res) => {
  const incomingLinks = req.body.links || [];
  const mergedLinks = Database.syncBatch(req.user.id, incomingLinks);
  res.json({
    message: 'Sync completed successfully',
    syncedCount: mergedLinks.length,
    links: mergedLinks
  });
});

// Start Server
app.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(`🚀 MightyLink Unified Backend is running!`);
  console.log(`📍 URL: http://localhost:${PORT}`);
  console.log(`🌐 Web Portal: http://localhost:${PORT}`);
  console.log(`📡 API Endpoints: http://localhost:${PORT}/api/...`);
  console.log(`====================================================`);
});
