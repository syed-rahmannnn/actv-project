# Browse Members & Connection API Documentation

## Overview
This API implements a connection system similar to Instagram's follow requests, allowing members to connect with each other after approval.

**Important Filters:**
- Only members **approved by state admin** (`approvedBy` field is not null)
- Only members with **active membership** (`membershipStatus = 'active'`)
- Only members with **completed profile** (`profileCompleted = true`)

These conditions ensure that only verified, payment-completed members appear in the browse list.

## Base URL
```
http://10.201.103.174:3000/api/browse-members
```

## Endpoints

### 1. Get Approved Members
**GET** `/api/browse-members`

Fetches all approved members who have completed payment.

**Query Parameters:**
- `state` (optional): Filter by state
- `district` (optional): Filter by district
- `block` (optional): Filter by block
- `search` (optional): Search by member name
- `page` (optional, default: 1): Page number
- `limit` (optional, default: 10): Items per page

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "member_id",
      "name": "Full Name",
      "email": "email@example.com",
      "phone": "1234567890",
      "gender": "Male/Female",
      "role": "Member",
      "organization": "Company Name",
      "location": {
        "state": "State Name",
        "district": "District Name",
        "block": "Block Name",
        "city": "City Name"
      },
      "isActive": true,
      "profileCompleted": true,
      "approvalStatus": "approved_by_state_admin",
      "paymentStatus": "completed",
      "membershipType": "lifetime"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 5,
    "totalMembers": 45,
    "totalCount": 50
  }
}
```

### 2. Send Connection Request
**POST** `/api/browse-members/connect`

Sends a connection request from one member to another.

**Request Body:**
```json
{
  "senderId": "sender_member_id",
  "recipientId": "recipient_member_id",
  "message": "Wants to connect with you"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Connection request sent successfully",
  "data": {
    "connectionId": "connection_id",
    "status": "pending"
  }
}
```

### 3. Check Connection Status
**GET** `/api/browse-members/connection-status/:senderId/:recipientId`

Checks if a connection exists between two members.

**Response:**
```json
{
  "success": true,
  "data": {
    "hasConnection": true,
    "status": "pending|accepted|declined",
    "requestedAt": "2025-11-19T10:30:00.000Z"
  }
}
```

### 4. Respond to Connection Request
**PUT** `/api/browse-members/connection/:connectionId/respond`

Accept or decline a connection request.

**Request Body:**
```json
{
  "action": "accept"  // or "decline"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Connection request accepted successfully",
  "data": {
    "connectionId": "connection_id",
    "status": "accepted"
  }
}
```

### 5. Get Notifications
**GET** `/api/browse-members/notifications/:memberId`

Fetches notifications for a member.

**Query Parameters:**
- `page` (optional, default: 1): Page number
- `limit` (optional, default: 20): Items per page
- `unreadOnly` (optional, default: false): Show only unread notifications

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "notification_id",
      "recipientId": "recipient_member_id",
      "senderId": {
        "_id": "sender_id",
        "fullName": "Sender Name",
        "email": "sender@example.com",
        "phoneNumber": "1234567890"
      },
      "type": "connection_request",
      "title": "New Connection Request",
      "message": "Sender Name has requested to connect with you",
      "connectionId": {
        "_id": "connection_id",
        "status": "pending",
        "message": "Wants to connect with you"
      },
      "isRead": false,
      "createdAt": "2025-11-19T10:30:00.000Z"
    }
  ],
  "unreadCount": 5,
  "pagination": {
    "currentPage": 1,
    "totalPages": 2,
    "total": 25
  }
}
```

### 6. Mark Notification as Read
**PUT** `/api/browse-members/notifications/:notificationId/read`

Marks a notification as read.

**Response:**
```json
{
  "success": true,
  "message": "Notification marked as read",
  "data": {
    "_id": "notification_id",
    "isRead": true
  }
}
```

## Notification Types

- `connection_request`: When someone sends a connection request
- `connection_accepted`: When someone accepts your connection request
- `connection_declined`: When someone declines your connection request
- `general`: General notifications

## Connection Status Flow

1. **pending**: Initial state when request is sent
2. **accepted**: When recipient accepts the request
3. **declined**: When recipient declines the request

## Database Models

### Connection Schema
```javascript
{
  senderId: ObjectId (ref: MemberDetails),
  recipientId: ObjectId (ref: MemberDetails),
  status: 'pending' | 'accepted' | 'declined',
  message: String,
  createdAt: Date,
  updatedAt: Date
}
```

### Notification Schema
```javascript
{
  recipientId: ObjectId (ref: MemberDetails),
  senderId: ObjectId (ref: MemberDetails),
  type: 'connection_request' | 'connection_accepted' | 'connection_declined' | 'general',
  title: String,
  message: String,
  connectionId: ObjectId (ref: Connection),
  isRead: Boolean,
  createdAt: Date
}
```

## Usage Flow

1. **Browse Members**: User views list of approved members with completed payments
2. **Send Connection**: User clicks "Connect" button to send a request
3. **Notification**: Recipient receives a notification in their dashboard
4. **Respond**: Recipient can accept or decline the request
5. **Status Update**: Both users get notified of the response
6. **Connection Established**: If accepted, users are now connected

## Error Responses

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

Common error codes:
- 400: Bad Request (invalid parameters)
- 404: Not Found (resource doesn't exist)
- 500: Internal Server Error

## Testing

Test the endpoints using:
- Postman
- cURL
- Flutter app

Example cURL:
```bash
# Get approved members
curl http://10.201.103.174:3000/api/browse-members?page=1&limit=10

# Send connection request
curl -X POST http://10.201.103.174:3000/api/browse-members/connect \
  -H "Content-Type: application/json" \
  -d '{"senderId":"123","recipientId":"456","message":"Hello"}'
```
