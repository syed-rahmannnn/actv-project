# ACTIV Backend Server Management

## Quick Start Commands

### Development (Recommended)
```bash
npm run dev
```
- Uses nodemon for auto-restart on file changes
- Perfect for development workflow

### Production
```bash
npm start
```
- Uses node directly
- For production deployment

## Server Management Commands

### Stop Server
```bash
npm run stop
```
- Kills all Node.js processes
- Use when you get "port already in use" error

### Restart Server
```bash
npm run restart
```
- Stops and starts the server with npm start

### Restart Development Server
```bash
npm run restart:dev
```
- Stops and starts the server with npm run dev

## Troubleshooting

### Port Already in Use Error
If you get `EADDRINUSE: address already in use :::3000`:

1. **Quick Fix:**
   ```bash
   npm run stop
   npm run dev
   ```

2. **Manual Fix:**
   ```bash
   # Find the process using port 3000
   netstat -ano | findstr :3000
   
   # Kill the process (replace <PID> with actual process ID)
   taskkill /PID <PID> /F
   
   # Start the server
   npm run dev
   ```

3. **Use Different Port:**
   ```bash
   # Set PORT environment variable
   set PORT=3001
   npm start
   ```

## Server Status
- **Health Check:** http://192.168.29.130:3000/api/health
- **Default Port:** 3000
- **Environment:** development

## API Endpoints
- `GET /api/health` - Health check
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `GET /api/auth/member/:id` - Get member by ID
- `GET /api/profile/:id` - Get member profile

## Database
- **MongoDB:** Connected to cloud cluster
- **Collections:** membersdetails, memberauth, memberbusinessinfo, etc.
