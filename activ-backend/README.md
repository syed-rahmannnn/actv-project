# ACTIV Backend API

This is the backend API for the ACTIV member management system built with Node.js, Express.js, and MongoDB.

## Features

- Member registration and authentication
- Firebase integration for user validation
- MongoDB database with multiple collections for different data types
- RESTful API endpoints
- Data validation and error handling
- Security middleware (Helmet, CORS, Rate limiting)

## Database Collections

The system uses the following MongoDB collections:

1. **membersdetails** - Basic member information (name, email, phone, address, etc.)
2. **membersauth** - Authentication data (email, password, Firebase UID)
3. **membersbusinessinfo** - Business and personal details
4. **membersfinancialinfo** - Financial and compliance information
5. **membersdeclaration** - Declaration and final submission data

## Installation

1. Navigate to the backend directory:
   ```bash
   cd activ-backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up environment variables:
   - Copy `config.env` and update with your actual values
   - Set your MongoDB connection string
   - Configure Firebase credentials
   - Set JWT secret

4. Start the server:
   ```bash
   # Development mode
   npm run dev
   
   # Production mode
   npm start
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new member
- `POST /api/auth/firebase-validate` - Validate Firebase user
- `GET /api/auth/member/:firebaseUid` - Get member by Firebase UID

### Members
- `GET /api/members` - Get all members (with pagination)
- `GET /api/members/:id` - Get member by ID
- `PUT /api/members/:id` - Update member
- `DELETE /api/members/:id` - Delete member
- `GET /api/members/search/:query` - Search members

### Profile
- `GET /api/profile/:firebaseUid` - Get complete member profile
- `POST /api/profile/business-info` - Save business information
- `POST /api/profile/financial-info` - Save financial information
- `POST /api/profile/declaration` - Save declaration
- `PUT /api/profile/complete-profile/:firebaseUid` - Mark profile as complete

### Health Check
- `GET /api/health` - API health status

## Environment Variables

Create a `config.env` file with the following variables:

```env
# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017/membersdb

# JWT Configuration
JWT_SECRET=your_jwt_secret_key_here

# Firebase Configuration
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_PRIVATE_KEY=your_firebase_private_key
FIREBASE_CLIENT_EMAIL=your_firebase_client_email

# Server Configuration
PORT=3000
NODE_ENV=development
```

## Data Flow

1. **Registration**: User registers through Flutter app → Data stored in `membersdetails` and `membersauth` collections
2. **Login**: Firebase authentication → Backend validation → Member data retrieval
3. **Profile Completion**: Multi-step form → Data stored in respective collections based on form type
4. **Dashboard**: Member data displayed from various collections

## Security Features

- Password hashing with bcrypt
- JWT token authentication
- Rate limiting
- CORS protection
- Input validation
- Error handling

## Development

The server runs on port 3000 by default. Make sure MongoDB is running and accessible at the configured URI.

For development, use `npm run dev` which uses nodemon for automatic restarts on file changes.

## Testing

You can test the API endpoints using tools like Postman or curl. The health check endpoint is available at `http://localhost:3000/api/health`.
