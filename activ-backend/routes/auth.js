const express = require('express');
const jwt = require('jsonwebtoken');
const MemberDetails = require('../models/MemberDetails');
const MemberAuth = require('../models/MemberAuth');
const { validateLogin } = require('../middleware/validation');

const router = express.Router();

// Login endpoint - OPTIMIZED with validation and detailed logging
router.post('/login', validateLogin, async(req, res) => {
    const startTime = Date.now();
    console.time('🔐 LOGIN_API');

    try {
        const { email, password } = req.body;
        console.log(`📧 Login attempt: ${email}`);

        if (!email || !password) {
            console.timeEnd('🔐 LOGIN_API');
            return res.status(400).json({
                success: false,
                message: 'Email and password are required'
            });
        }

        const normalizedEmail = email.toLowerCase();

        // ✅ OPTIMIZED: Parallel queries with timing
        const dbStart = Date.now();
        const [member, memberAuth] = await Promise.all([
            MemberDetails.findOne({ email: normalizedEmail })
            .select('_id fullName email phoneNumber state district block city profileCompleted')
            .lean(),
            MemberAuth.findOne({ email: normalizedEmail })
            .select('email password isActive')
            .lean(false)
        ]);
        console.log(`⏱️  DB Query: ${Date.now() - dbStart}ms`);

        // Check if member exists
        if (!member) {
            console.log(`❌ Member not found: ${normalizedEmail}`);
            console.timeEnd('🔐 LOGIN_API');
            return res.status(404).json({
                success: false,
                message: 'Member not found'
            });
        }

        // Check authentication
        if (!memberAuth || !memberAuth.isActive) {
            console.log(`❌ Auth not found or inactive: ${normalizedEmail}`);
            console.timeEnd('🔐 LOGIN_API');
            return res.status(403).json({
                success: false,
                message: 'Account is inactive or not found'
            });
        }

        // Verify password with timing
        const passwordStart = Date.now();
        const isPasswordValid = await memberAuth.comparePassword(password);
        console.log(`⏱️  Password Check: ${Date.now() - passwordStart}ms`);

        if (!isPasswordValid) {
            console.log(`❌ Invalid password: ${normalizedEmail}`);
            console.timeEnd('🔐 LOGIN_API');
            return res.status(401).json({
                success: false,
                message: 'Invalid password'
            });
        }

        // Generate JWT
        const jwtStart = Date.now();
        const token = jwt.sign({
                userId: member._id,
                email: member.email
            },
            process.env.JWTSECRET, { expiresIn: '24h' }
        );
        console.log(`⏱️  JWT Generation: ${Date.now() - jwtStart}ms`);

        // Update last login asynchronously
        memberAuth.updateLastLogin().catch(err =>
            console.error('Failed to update last login:', err)
        );

        const totalTime = Date.now() - startTime;
        console.log(`✅ Login successful: ${normalizedEmail} (Total: ${totalTime}ms)`);
        console.timeEnd('🔐 LOGIN_API');

        return res.status(200).json({
            success: true,
            message: 'Login successful',
            data: {
                token: token,
                member: {
                    id: member._id,
                    memberId: member._id,
                    fullName: member.fullName,
                    email: member.email,
                    phoneNumber: member.phoneNumber,
                    state: member.state,
                    district: member.district,
                    block: member.block,
                    city: member.city,
                    profileCompleted: member.profileCompleted
                }
            }
        });

    } catch (error) {
        console.error('❌ Login error:', error);
        console.timeEnd('🔐 LOGIN_API');
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// Register new member
router.post('/register', async(req, res) => {
    try {
        console.log('📥 Registration request received');
        console.log('📋 Request body:', JSON.stringify(req.body, null, 2));

        const {
            fullName,
            phoneNumber,
            email,
            password,
            block,
            city,
            district,
            state,
            pincode,
            profilePicture,
            memberType
        } = req.body;

        // Log what we received
        console.log('📝 Extracted fields:');
        console.log('   fullName:', fullName || '(empty)');
        console.log('   email:', email || '(empty)');
        console.log('   phoneNumber:', phoneNumber || '(empty)');
        console.log('   password:', password ? '***' : '(empty)');
        console.log('   state:', state || '(empty)');
        console.log('   district:', district || '(empty)');
        console.log('   city:', city || '(empty)');
        console.log('   block:', block || '(empty)');

        // Check if member already exists (only if email is provided)
        if (email && email.trim() !== '') {
            const existingMember = await MemberDetails.findOne({ email: email.toLowerCase() });
            if (existingMember) {
                return res.status(409).json({
                    success: false,
                    message: 'Member with this email already exists'
                });
            }
        }

        // Generate a unique email if not provided to avoid conflicts
        const finalEmail = (email && email.trim() !== '') ?
            email.toLowerCase() :
            `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}@temp.local`;

        // Generate a temporary fullName if not provided
        const finalFullName = (fullName && fullName.trim() !== '') ?
            fullName :
            `Member_${Date.now()}`;

        console.log('✅ Using email:', finalEmail);
        console.log('✅ Using fullName:', finalFullName);

        // Create member details with optional fields
        const memberDetails = new MemberDetails({
            fullName: finalFullName,
            email: finalEmail,
            phoneNumber: phoneNumber || '',
            state: state || '',
            district: district || '',
            block: block || '',
            city: city || ''
        });

        await memberDetails.save({ validateBeforeSave: false });
        console.log('✅ Member saved with ID:', memberDetails._id);

        // Create member auth only if password is provided
        if (password && password.trim() !== '') {
            const memberAuth = new MemberAuth({
                email: finalEmail,
                password
            });
            await memberAuth.save({ validateBeforeSave: false });
            console.log('✅ Member auth created');
        } else {
            console.log('⚠️ No password provided, skipping auth creation');
        }

        // Generate JWT token
        // JWT secret logging removed for security
        const token = jwt.sign({
                userId: memberDetails._id,
                email: memberDetails.email
            },
            process.env.JWTSECRET, { expiresIn: '24h' }
        );

        return res.status(201).json({
            success: true,
            message: 'Member registered successfully',
            data: {
                token: token,
                member: {
                    id: memberDetails._id,
                    memberId: memberDetails._id, // Add memberId for frontend clarity
                    fullName: memberDetails.fullName,
                    email: memberDetails.email,
                    phoneNumber: memberDetails.phoneNumber,
                    state: memberDetails.state,
                    district: memberDetails.district,
                    block: memberDetails.block,
                    city: memberDetails.city,
                    profileCompleted: memberDetails.profileCompleted
                }
            }
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// Get member by ID
router.get('/member/:memberId', async(req, res) => {
    try {
        const { memberId } = req.params;

        const member = await MemberDetails.findById(memberId);

        if (!member) {
            return res.status(404).json({
                success: false,
                message: 'Member not found'
            });
        }

        return res.status(200).json({
            success: true,
            data: {
                member: {
                    id: member._id,
                    memberId: member._id, // Add memberId for frontend clarity
                    fullName: member.fullName,
                    email: member.email,
                    phoneNumber: member.phoneNumber,
                    state: member.state,
                    district: member.district,
                    block: member.block,
                    city: member.city,
                    profileCompleted: member.profileCompleted
                }
            }
        });

    } catch (error) {
        console.error('Get member error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// Get member by email
router.get('/member-by-email/:email', async(req, res) => {
    try {
        const { email } = req.params;

        const member = await MemberDetails.findOne({ email: email.toLowerCase() });

        if (!member) {
            return res.status(404).json({
                success: false,
                message: 'Member not found'
            });
        }

        return res.status(200).json({
            success: true,
            data: {
                member: {
                    id: member._id,
                    fullName: member.fullName,
                    email: member.email,
                    phoneNumber: member.phoneNumber,
                    state: member.state,
                    district: member.district,
                    block: member.block,
                    city: member.city,
                    profileCompleted: member.profileCompleted
                }
            }
        });

    } catch (error) {
        console.error('Get member by email error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

module.exports = router;