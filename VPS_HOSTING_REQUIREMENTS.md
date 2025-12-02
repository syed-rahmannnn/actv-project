# VPS Hosting Requirements - ACTV Project

## Quick Reference Answers for Excel Sheet

| S.No | Requirement Info | Details |
|------|-----------------|---------|
| 1 | Application Name | ACTV Business Chamber Platform |
| 2 | Application version | v1.0.0 (Current Development) |
| 3 | Application Type | Both (Web Backend + Mobile App) |
| 4 | Environment Required | Both (Development + Production) |
| 5 | Minimum Server Instance Type | VPS with 2 vCPU, 2GB RAM, 20GB SSD |
| 6 | Server Compute Size | 2 vCPU cores minimum, 4 vCPU recommended |
| 7 | Database Instance Required | Yes |
| 8 | Database Engine (Required - Instance Required) | MongoDB v6.0+ (NoSQL) |
| 9 | Database version | MongoDB 6.0 or 7.0 |
| 10 | App Used Languages | Dart (Flutter), JavaScript (Node.js) |
| 11 | Domain Name required | Yes (e.g., actv-project.com) |
| 12 | New Domain Name | Your choice (e.g., actvbusiness.com) |
| 13 | Domain SSL required | Yes (HTTPS mandatory) |
| 14 | Application VCS managed | Yes (GitHub) |
| 15 | Application VCS | GitHub - https://github.com/syed-rahmannnn/actv-project |
| 16 | Deployment via | Git Clone + PM2 (or Docker/CI-CD) |

## Application Overview
- **Application Name**: ACTV Business Chamber Platform
- **Application Type**: Full Stack Web + Mobile App (Flutter + Node.js)
- **Environment**: Both Development & Production

## Server Requirements

### Minimum Server Specifications
- **CPU**: 2 vCPU cores (minimum)
- **RAM**: 2 GB (minimum), 4 GB recommended
- **Storage**: 20 GB SSD
- **Bandwidth**: 1 TB/month
- **Operating System**: Ubuntu 22.04 LTS or Ubuntu 20.04 LTS

### Recommended Server Specifications (for better performance)
- **CPU**: 4 vCPU cores
- **RAM**: 4-8 GB
- **Storage**: 40-50 GB SSD
- **Bandwidth**: Unlimited or 2+ TB/month

## Software Stack Requirements

### Runtime Environment
- **Node.js**: v18.x or v20.x (LTS version)
- **npm**: v9.x or higher
- **PM2**: Latest version (for process management)

### Database
- **MongoDB**: v6.0 or v7.0
- **Database Instance**: Required - YES
- **Database Engine**: MongoDB (NoSQL)
- **Database Version**: 6.0+
- **Database Location**: Can be on same VPS or external (MongoDB Atlas recommended for production)

### Web Server & Reverse Proxy
- **Nginx**: v1.18+ (recommended for production)
- **Alternative**: Apache 2.4+
- **Purpose**: 
  - Reverse proxy for Node.js backend
  - SSL/TLS termination
  - Static file serving
  - Load balancing (if needed)

### SSL/TLS Certificate
- **Domain SSL Required**: YES
- **Certificate Type**: Let's Encrypt (free) or commercial SSL
- **Auto-renewal**: Certbot for Let's Encrypt

## Domain & DNS Requirements

### Domain Name
- **Domain Required**: YES
- **Example**: actv-project.com or yourdomain.com
- **Subdomains needed**:
  - `api.yourdomain.com` (for backend API)
  - `www.yourdomain.com` (for future web app)

### DNS Configuration
- **A Record**: Point to VPS IP address
- **CNAME Records**: For subdomains

## Network & Security Requirements

### Ports to be Opened
- **22**: SSH (for server management)
- **80**: HTTP (redirect to HTTPS)
- **443**: HTTPS (SSL/TLS)
- **3000**: Node.js backend (internal, proxied by Nginx)
- **27017**: MongoDB (if on same VPS, restrict to localhost)

### Firewall (UFW - Ubuntu)
```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp  # Optional, if direct access needed
ufw enable
```

### Security Features Required
- SSH key-based authentication (disable password login)
- Fail2ban (brute force protection)
- Regular security updates
- SSL/TLS certificate (HTTPS only)
- MongoDB authentication enabled
- Firewall enabled (UFW or iptables)

## Application Deployment Requirements

### Version Control System (VCS)
- **Application VCS Managed**: YES
- **VCS Platform**: GitHub
- **Repository**: https://github.com/syed-rahmannnn/actv-project
- **Branch for Production**: main
- **Branch for Development**: day-17

### Deployment Method
**Option 1: Manual Deployment via Git**
1. Clone repository on VPS
2. Install dependencies (`npm install`)
3. Configure environment variables
4. Start with PM2

**Option 2: CI/CD Pipeline** (Recommended)
- GitHub Actions workflow
- Auto-deploy on push to main branch
- Automated testing before deployment

**Option 3: Docker** (Advanced)
- Containerized deployment
- Docker Compose for multi-service setup
- Easy scaling and management

## Environment Configuration

### Required Environment Variables (.env file)
```env
# Server Configuration
NODE_ENV=production
PORT=3000

# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017/actv-db
# OR for MongoDB Atlas:
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/actv-db

# JWT Secret
JWT_SECRET=your-super-secret-jwt-key-change-this

# API Configuration
API_VERSION=v1

# CORS Configuration
CORS_ORIGIN=https://yourdomain.com

# Razorpay Payment Gateway
RAZORPAY_KEY_ID=your_key_id
RAZORPAY_KEY_SECRET=your_key_secret

# Email Configuration (if needed)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# Cloudinary (for image uploads, if needed)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

## Programming Languages & Frameworks

### Backend
- **Language**: JavaScript (Node.js)
- **Framework**: Express.js v4.x
- **Key Dependencies**:
  - mongoose (MongoDB ODM)
  - jsonwebtoken (JWT authentication)
  - bcryptjs (password hashing)
  - razorpay (payment gateway)
  - cors (cross-origin requests)
  - dotenv (environment variables)

### Frontend (Mobile App)
- **Language**: Dart
- **Framework**: Flutter 3.x
- **Build Output**: APK/AAB (Android), IPA (iOS)
- **Hosting**: Not required on VPS (distributed via app stores)

## Backup Requirements

### Database Backup
- **Frequency**: Daily automated backups
- **Retention**: 7-30 days
- **Method**: mongodump or MongoDB Atlas automated backups

### Application Backup
- **Frequency**: Before each deployment
- **Method**: Git repository + VPS snapshot

## Monitoring & Logging

### Required Monitoring Tools
- **Application Monitoring**: PM2 monitoring dashboard
- **Server Monitoring**: 
  - htop (resource usage)
  - netdata (real-time monitoring)
  - New Relic or Datadog (optional, paid)

### Logging
- **Application Logs**: PM2 logs (`~/.pm2/logs/`)
- **Nginx Logs**: `/var/log/nginx/access.log` & `error.log`
- **MongoDB Logs**: `/var/log/mongodb/mongod.log`
- **Log Rotation**: logrotate configured

## VPS Provider Recommendations

### Budget-Friendly Options ($5-10/month)
1. **DigitalOcean** - Droplet 2GB RAM ($12/month)
2. **Linode** - Shared 2GB RAM ($10/month)
3. **Vultr** - High Frequency 2GB RAM ($12/month)
4. **Hetzner** - CX21 2vCPU 4GB RAM (~€5/month, best value)

### Premium Options ($15-50/month)
1. **AWS EC2** - t3.small or t3.medium
2. **Google Cloud Platform** - e2-small or e2-medium
3. **Microsoft Azure** - B1s or B2s

### Indian VPS Providers
1. **HostGator India** - Cloud VPS
2. **BigRock** - VPS Hosting
3. **Hostinger** - VPS plans

## Initial Setup Checklist

### Step 1: Server Provisioning
- [ ] Purchase VPS plan (2GB+ RAM recommended)
- [ ] Choose Ubuntu 22.04 LTS as OS
- [ ] Note down IP address and root password

### Step 2: Initial Server Configuration
- [ ] SSH into server as root
- [ ] Create new sudo user (don't use root)
- [ ] Set up SSH key authentication
- [ ] Disable root login
- [ ] Configure firewall (UFW)
- [ ] Update system packages

### Step 3: Install Software Stack
- [ ] Install Node.js (v18 or v20 LTS)
- [ ] Install MongoDB or configure MongoDB Atlas
- [ ] Install Nginx
- [ ] Install PM2 globally
- [ ] Install Git

### Step 4: Domain Configuration
- [ ] Purchase domain or use existing
- [ ] Point A record to VPS IP
- [ ] Wait for DNS propagation (24-48 hours max)

### Step 5: SSL Certificate
- [ ] Install Certbot
- [ ] Obtain Let's Encrypt SSL certificate
- [ ] Configure Nginx for HTTPS
- [ ] Set up auto-renewal

### Step 6: Application Deployment
- [ ] Clone GitHub repository
- [ ] Install dependencies (`npm install`)
- [ ] Create .env file with production values
- [ ] Configure MongoDB connection
- [ ] Test backend locally
- [ ] Start with PM2

### Step 7: Nginx Configuration
- [ ] Create Nginx server block for API
- [ ] Configure reverse proxy to Node.js (port 3000)
- [ ] Enable SSL/HTTPS
- [ ] Test Nginx configuration
- [ ] Restart Nginx

### Step 8: Testing & Verification
- [ ] Test API endpoints via Postman or curl
- [ ] Verify database connections
- [ ] Test Flutter app with production API
- [ ] Monitor logs for errors
- [ ] Verify SSL certificate is working

### Step 9: Ongoing Maintenance
- [ ] Set up automated backups
- [ ] Configure monitoring alerts
- [ ] Plan regular security updates
- [ ] Monitor resource usage
- [ ] Review logs periodically

## Cost Estimation

### Monthly Operating Costs
- **VPS Hosting**: $5-20/month (depending on provider/specs)
- **Domain Name**: $10-15/year (~$1/month)
- **SSL Certificate**: FREE (Let's Encrypt)
- **MongoDB Atlas** (if external): FREE tier (512MB) or $9+/month
- **Monitoring Tools**: FREE (basic) or $15+/month (premium)

**Total Minimum**: ~$6-10/month
**Total Recommended**: ~$20-30/month

## Support & Maintenance

### Skills Required
- Basic Linux server administration
- SSH and command line proficiency
- Understanding of Node.js deployment
- Basic Nginx configuration
- MongoDB database management

### Time Commitment
- Initial Setup: 4-6 hours
- Weekly Monitoring: 30 minutes
- Monthly Updates: 1 hour

## Additional Notes

### Current Stack
- **Current Hosting**: Render.com (Free tier)
- **Database**: MongoDB Atlas (Shared cluster)
- **Limitation**: Free tier cold starts, slow performance

### Benefits of VPS Migration
- Full control over server configuration
- Better performance (no cold starts)
- Custom domain with SSL
- Ability to scale resources
- Better debugging capabilities
- No platform limitations

### Migration Strategy
1. Set up VPS completely
2. Test thoroughly with development branch
3. Deploy production to VPS
4. Update Flutter app API URL
5. Monitor for 24-48 hours
6. Keep Render.com as backup initially
7. Decommission Render.com after stability confirmed
