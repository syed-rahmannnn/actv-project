# Backend Setup Guide for ACTIV App

## Option 1: Node.js + Express + Prisma (Recommended)

### 1. Create Backend Folder
```bash
mkdir activ-backend
cd activ-backend
npm init -y
```

### 2. Install Dependencies
```bash
npm install express cors dotenv bcryptjs jsonwebtoken
npm install prisma @prisma/client
npm install -D nodemon
```

### 3. Setup Prisma
```bash
npx prisma init
```

### 4. Copy your schema.prisma to activ-backend/prisma/schema.prisma

### 5. Create .env file
```
DATABASE_URL="postgresql://username:password@localhost:5432/activ_db"
JWT_SECRET="your-secret-key-here"
```

### 6. Create server.js
```javascript
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

const app = express();
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());

// Register endpoint
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, registrationForm } = req.body;
    
    // Check if user exists
    const existingUser = await prisma.user.findUnique({
      where: { email }
    });
    
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Create user with registration form
    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        registrationForm: {
          create: {
            fullName: registrationForm.fullName,
            phoneNumber: registrationForm.phoneNumber,
            dateOfBirth: new Date(registrationForm.dateOfBirth),
            gender: registrationForm.gender,
            state: registrationForm.state,
            district: registrationForm.district,
            block: registrationForm.block,
            completeAddress: registrationForm.completeAddress,
          }
        }
      },
      include: {
        registrationForm: true
      }
    });
    
    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET);
    
    res.status(201).json({
      message: 'User registered successfully',
      user: {
        id: user.id,
        email: user.email,
        registrationForm: user.registrationForm
      },
      token
    });
  } catch (error) {
    res.status(500).json({ message: 'Registration failed', error: error.message });
  }
});

// Login endpoint
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const user = await prisma.user.findUnique({
      where: { email },
      include: { registrationForm: true }
    });
    
    if (!user || !await bcrypt.compare(password, user.password)) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET);
    
    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        fullName: user.registrationForm?.fullName,
        registrationForm: user.registrationForm
      },
      token
    });
  } catch (error) {
    res.status(500).json({ message: 'Login failed', error: error.message });
  }
});

// Check email exists
app.get('/api/auth/check-email', async (req, res) => {
  try {
    const { email } = req.query;
    const user = await prisma.user.findUnique({
      where: { email }
    });
    res.json({ exists: !!user });
  } catch (error) {
    res.status(500).json({ message: 'Error checking email' });
  }
});

// Check phone exists
app.get('/api/auth/check-phone', async (req, res) => {
  try {
    const { phoneNumber } = req.query;
    const registration = await prisma.userRegistrationForm.findUnique({
      where: { phoneNumber }
    });
    res.json({ exists: !!registration });
  } catch (error) {
    res.status(500).json({ message: 'Error checking phone' });
  }
});

// Get user profile
app.get('/api/user/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const user = await prisma.user.findUnique({
      where: { id },
      include: { registrationForm: true }
    });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json({
      id: user.id,
      email: user.email,
      registrationForm: user.registrationForm
    });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching user' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
```

### 7. Update package.json scripts
```json
{
  "scripts": {
    "dev": "nodemon server.js",
    "start": "node server.js"
  }
}
```

### 8. Run Database Setup
```bash
npx prisma migrate dev --name init
npx prisma generate
```

### 9. Start Server
```bash
npm run dev
```

**Your API URL will be: `http://localhost:3000`**

## Option 2: Cloud Services (Easier)

### Supabase (PostgreSQL + Auto APIs)
1. Go to https://supabase.com
2. Create new project
3. Copy your database schema to Supabase
4. Use Supabase client in Flutter
5. URL: `https://your-project.supabase.co`

### Railway/Render (Deploy Node.js)
1. Push your backend code to GitHub
2. Connect to Railway/Render
3. Deploy automatically
4. URL: `https://your-app.railway.app`

## Option 3: Local Development
- **URL**: `http://localhost:3000` (Node.js)
- **URL**: `http://10.0.2.2:3000` (Android Emulator)
- **URL**: `http://YOUR_IP:3000` (Physical device)

## Update Flutter API URL

Once your backend is running, update in `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:3000/api'; // Local
// OR
static const String baseUrl = 'https://your-app.railway.app/api'; // Production
```

## Testing
Test your endpoints using Postman or curl:
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```
