const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const MemberDetails = require('../models/MemberDetails');
const Connection = require('../models/Connection');
const Notification = require('../models/Notification');
const MemberBusinessInfo = require('../models/MemberBusinessInfo');

// GET /api/browse-members - Get all approved members with completed payment
router.get('/', async(req, res) => {
    try {
        const { state, district, block, search, page = 1, limit = 10, exclude_user_id } = req.query;

        console.log('\n🔍 === BROWSE MEMBERS REQUEST ===');
        console.log('Query params:', { state, district, block, search, page, limit, exclude_user_id });

        // Build query for approved and payment completed members
        const query = {
            approvedBy: { $ne: null }, // Must be approved by someone (state admin)
            membershipStatus: 'active', // Must have active membership (payment completed)
            profileCompleted: true // Profile must be completed
        };

        // Exclude current user from results
        if (exclude_user_id) {
            // Convert string to ObjectId for proper MongoDB comparison
            query._id = { $ne: new mongoose.Types.ObjectId(exclude_user_id) };
            console.log('🚫 Excluding current user:', exclude_user_id);
        }

        // Add location filters if provided
        if (state) query.state = new RegExp(state, 'i');
        if (district) query.district = new RegExp(district, 'i');
        if (block) query.block = new RegExp(block, 'i');

        // Search by name if provided
        if (search) {
            query.fullName = new RegExp(search, 'i');
        }

        const skip = (page - 1) * limit;

        console.log('📋 Database Query:', JSON.stringify(query, null, 2));
        console.log('🔍 Filtering Criteria:');
        console.log('   ✓ approvedBy != null (approved by state admin)');
        console.log('   ✓ membershipStatus = "active" (payment completed)');
        console.log('   ✓ profileCompleted = true');

        // ✅ OPTIMIZED: Run member fetch and connection check in parallel
        const membersPromise = MemberDetails.find(query)
            .select('fullName email phoneNumber gender state district block city profileCompleted approvedBy approvedAt membershipType membershipStatus')
            .skip(skip)
            .limit(parseInt(limit))
            .sort({ createdAt: -1 })
            .lean()
            .maxTimeMS(1000); // ✅ OPTIMIZED: Timeout for large queries

        let existingConnectionsPromise = Promise.resolve([]);
        if (exclude_user_id) {
            const currentUserId = new mongoose.Types.ObjectId(exclude_user_id);
            existingConnectionsPromise = Connection.find({
                status: { $in: ['accepted', 'pending'] },
                $or: [
                    { senderId: currentUserId },
                    { recipientId: currentUserId }
                ]
            }).select('senderId recipientId status').lean();
        }

        // Wait for both queries to complete
        const [members, existingConnections] = await Promise.all([membersPromise, existingConnectionsPromise]);

        console.log(`📊 Database returned: ${members.length} members`);

        // Filter out members who are already connected OR have pending connection requests
        let filteredMembers = members;
        if (exclude_user_id && existingConnections.length > 0) {

            // Get list of connected/pending member IDs
            const connectedMemberIds = new Set();
            const pendingMemberIds = new Set();

            existingConnections.forEach(conn => {
                const otherId = conn.senderId.toString() === exclude_user_id ?
                    conn.recipientId.toString() :
                    conn.senderId.toString();

                if (conn.status === 'accepted') {
                    connectedMemberIds.add(otherId);
                } else if (conn.status === 'pending') {
                    pendingMemberIds.add(otherId);
                }
            });

            // Filter out connected and pending members
            const beforeFilter = filteredMembers.length;
            filteredMembers = filteredMembers.filter(m => {
                const memberId = m._id.toString();
                return !connectedMemberIds.has(memberId) && !pendingMemberIds.has(memberId);
            });

            const filteredCount = beforeFilter - filteredMembers.length;
            if (filteredCount > 0) {
                console.log(`🔗 Filtered out ${connectedMemberIds.size} already-connected members`);
                console.log(`⏳ Filtered out ${pendingMemberIds.size} members with pending requests`);
                console.log(`📊 Total filtered: ${filteredCount} members`);
            }
        }

        console.log(`📊 After filtering connections: ${filteredMembers.length} members`);

        if (filteredMembers.length === 0) {
            console.log('⚠️  No members found matching criteria!');
            console.log('   Possible reasons:');
            console.log('   - No users have been approved (approvedBy is null)');
            console.log('   - No users have active membership (payment not completed)');
            console.log('   - No users have completed profiles');
            console.log('   - Location filters too restrictive');
        } else {
            console.log('✅ Sample member data:');
            filteredMembers.slice(0, 2).forEach(m => {
                console.log(`   - ${m.fullName}: approved=${!!m.approvedBy}, status=${m.membershipStatus}, profile=${m.profileCompleted}`);
            });
        }

        // ✅ OPTIMIZED: Fetch business info and total count in parallel
        const memberEmails = filteredMembers.map(m => m.email);

        const [businessInfos, total] = await Promise.all([
            MemberBusinessInfo.find({
                email: { $in: memberEmails }
            }).select('email organizationName').lean(),
            MemberDetails.countDocuments(query)
        ]);

        // Map business info
        const businessInfoMap = {};
        businessInfos.forEach(bi => {
            businessInfoMap[bi.email] = bi.organizationName;
        });

        // Format response with approved and paid members
        const formattedMembers = filteredMembers.map(member => ({
            id: member._id,
            name: member.fullName,
            email: member.email,
            phone: member.phoneNumber,
            gender: member.gender,
            role: 'Member', // Can be enhanced based on membershipType
            organization: businessInfoMap[member.email] || 'N/A',
            location: {
                state: member.state,
                district: member.district,
                block: member.block,
                city: member.city
            },
            isActive: true,
            profileCompleted: member.profileCompleted,
            approvalStatus: 'approved_by_state_admin',
            paymentStatus: 'completed',
            membershipType: member.membershipType
        }));

        console.log(`✅ Sending response: ${formattedMembers.length} members`);
        console.log('='.repeat(50));

        res.json({
            success: true,
            data: formattedMembers,
            pagination: {
                currentPage: parseInt(page),
                totalPages: Math.ceil(total / limit),
                totalMembers: formattedMembers.length,
                totalCount: total
            }
        });

    } catch (error) {
        console.error('❌ Error fetching browse members:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch members',
            error: error.message
        });
    }
});

// POST /api/browse-members/connect - Send connection request
router.post('/connect', async(req, res) => {
    try {
        const { senderId, recipientId, message } = req.body;

        if (!senderId || !recipientId) {
            return res.status(400).json({
                success: false,
                message: 'Sender ID and Recipient ID are required'
            });
        }

        // Check if connection already exists
        const existingConnection = await Connection.findOne({
            senderId,
            recipientId
        }).select('status').lean().maxTimeMS(500);

        if (existingConnection) {
            return res.status(400).json({
                success: false,
                message: 'Connection request already exists',
                status: existingConnection.status
            });
        }

        // Create connection request
        const connection = new Connection({
            senderId,
            recipientId,
            message: message || 'Wants to connect with you',
            status: 'pending'
        });

        await connection.save();

        // Get sender details
        const sender = await MemberDetails.findById(senderId)
            .select('fullName email')
            .lean()
            .maxTimeMS(500);

        // Create notification for recipient
        const notification = new Notification({
            recipientId,
            senderId,
            type: 'connection_request',
            title: 'New Connection Request',
            message: `${sender.fullName} has requested to connect with you`,
            connectionId: connection._id,
            isRead: false
        });

        await notification.save();

        res.status(201).json({
            success: true,
            message: 'Connection request sent successfully',
            data: {
                connectionId: connection._id,
                status: connection.status
            }
        });

    } catch (error) {
        console.error('Error sending connection request:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to send connection request',
            error: error.message
        });
    }
});

// GET /api/browse-members/connection-status/:senderId/:recipientId
router.get('/connection-status/:senderId/:recipientId', async(req, res) => {
    try {
        const { senderId, recipientId } = req.params;

        const connection = await Connection.findOne({
            senderId,
            recipientId
        }).select('status createdAt').lean().maxTimeMS(500);

        if (!connection) {
            return res.json({
                success: true,
                data: {
                    hasConnection: false,
                    status: null
                }
            });
        }

        res.json({
            success: true,
            data: {
                hasConnection: true,
                status: connection.status,
                requestedAt: connection.createdAt
            }
        });

    } catch (error) {
        console.error('Error checking connection status:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to check connection status',
            error: error.message
        });
    }
});

// GET /api/browse-members/connection/:connectionId/status - Get connection status by ID
router.get('/connection/:connectionId/status', async(req, res) => {
    try {
        const { connectionId } = req.params;

        const connection = await Connection.findById(connectionId)
            .select('status senderId recipientId createdAt updatedAt')
            .lean()
            .maxTimeMS(500);

        if (!connection) {
            return res.status(404).json({
                success: false,
                message: 'Connection not found',
                data: { status: null }
            });
        }

        res.json({
            success: true,
            data: {
                status: connection.status,
                senderId: connection.senderId,
                recipientId: connection.recipientId,
                createdAt: connection.createdAt,
                updatedAt: connection.updatedAt
            }
        });

    } catch (error) {
        console.error('Error getting connection status:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get connection status',
            error: error.message
        });
    }
});

// PUT /api/browse-members/connection/:connectionId/respond
router.put('/connection/:connectionId/respond', async(req, res) => {
    try {
        const { connectionId } = req.params;
        const { action } = req.body; // 'accept' or 'decline'

        if (!['accept', 'decline'].includes(action)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid action. Must be "accept" or "decline"'
            });
        }

        const connection = await Connection.findById(connectionId);

        if (!connection) {
            return res.status(404).json({
                success: false,
                message: 'Connection request not found'
            });
        }

        if (connection.status !== 'pending') {
            console.log(`⚠️ Connection already ${connection.status}`);
            return res.status(409).json({
                success: false,
                message: `Connection request already ${connection.status}`,
                status: connection.status,
                alreadyProcessed: true
            });
        }

        // Update connection status
        connection.status = action === 'accept' ? 'accepted' : 'declined';
        connection.updatedAt = Date.now();
        await connection.save();

        // Get recipient (who is responding) details
        const recipient = await MemberDetails.findById(connection.recipientId)
            .select('fullName email')
            .lean()
            .maxTimeMS(500);

        // Create notification for sender
        const notificationType = action === 'accept' ? 'connection_accepted' : 'connection_declined';
        const notificationMessage = action === 'accept' ?
            `${recipient.fullName} accepted your connection request` :
            `${recipient.fullName} declined your connection request`;

        const notification = new Notification({
            recipientId: connection.senderId,
            senderId: connection.recipientId,
            type: notificationType,
            title: action === 'accept' ? 'Connection Accepted' : 'Connection Declined',
            message: notificationMessage,
            connectionId: connection._id,
            isRead: false
        });

        await notification.save();

        res.json({
            success: true,
            message: `Connection request ${action === 'accept' ? 'accepted' : 'declined'} successfully`,
            data: {
                connectionId: connection._id,
                status: connection.status
            }
        });

    } catch (error) {
        console.error('Error responding to connection request:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to respond to connection request',
            error: error.message
        });
    }
});

// GET /api/browse-members/member/:memberId - Get member details by ID
router.get('/member/:memberId', async(req, res) => {
    try {
        const { memberId } = req.params;

        console.log('\n👤 === FETCHING MEMBER DETAILS ===');
        console.log('Member ID:', memberId);

        const personalDetails = await MemberDetails.findById(memberId)
            .select('-password')
            .lean()
            .maxTimeMS(500);

        if (!personalDetails) {
            return res.status(404).json({
                success: false,
                message: 'Member not found'
            });
        }

        // Get related documents
        const businessInfo = await MemberBusinessInfo.findOne({ memberId: memberId }).lean();
        const MemberFinancialInfo = require('../models/MemberFinancialInfo');
        const MemberDeclaration = require('../models/MemberDeclaration');
        const financialInfo = await MemberFinancialInfo.findOne({ memberId: memberId }).lean();
        const declaration = await MemberDeclaration.findOne({ memberId: memberId }).lean();

        console.log('✅ Found member:', personalDetails.fullName);
        console.log('- businessInfo:', businessInfo ? 'FOUND ✅' : 'NOT FOUND ❌');
        if (businessInfo) {
            console.log('  - Organization Name:', businessInfo.organizationName || '(empty)');
            console.log('  - Doing Business:', businessInfo.doingBusiness);
            console.log('  - Business Type:', businessInfo.businessType || '(empty)');
            console.log('  - PAN:', businessInfo.panNumber || '(empty)');
            console.log('  - GST:', businessInfo.gstNumber || '(empty)');
        }
        console.log('- financialInfo:', financialInfo ? 'FOUND ✅' : 'NOT FOUND ❌');
        if (financialInfo) {
            console.log('  - Annual Turnover:', financialInfo.annualTurnover || '(empty)');
            console.log('  - Account Holder:', financialInfo.accountHolderName || '(empty)');
        }
        console.log('- declaration:', declaration ? 'FOUND ✅' : 'NOT FOUND ❌');
        if (declaration) {
            console.log('  - Agree Terms:', declaration.agreeToTerms);
            console.log('  - Submitted At:', declaration.submittedAt || '(empty)');
        }

        // Construct response in same format as /members/:email/details
        const memberData = {
            _id: personalDetails._id,
            personal_and_demographic_details: {
                full_name: personalDetails.fullName || '',
                email: personalDetails.email || '',
                phone: personalDetails.phoneNumber || '',
                address: personalDetails.streetName || '',
                state: personalDetails.state || '',
                district: personalDetails.district || '',
                block: personalDetails.block || '',
                city: personalDetails.city || '',
                aadhar_number: personalDetails.aadhaarNumber || '',
                category: personalDetails.socialCategory || '',
                education: personalDetails.educationalQualification || '',
                religion: personalDetails.religion || '',
            },

            business_information: businessInfo ? {
                doing_business: businessInfo.doingBusiness || false,
                organization_name: businessInfo.organizationName || '',
                constitution_type: businessInfo.constitutionType || '',
                business_type: businessInfo.businessType || '',
                activities: businessInfo.businessActivities || '',
                commencement_year: businessInfo.businessCommencementYear || '',
                number_of_employees: businessInfo.numberOfEmployees || '',
                member_of_other_chamber: businessInfo.memberOfOtherChamber || false,
                other_chamber: businessInfo.otherChamber || '',
                govt_registrations: businessInfo.registeredWithGovtOrganization || [],
            } : {
                doing_business: false,
                organization_name: '',
                constitution_type: '',
                business_type: '',
                activities: '',
                commencement_year: '',
                number_of_employees: '',
                member_of_other_chamber: false,
                other_chamber: '',
                govt_registrations: [],
            },

            financial_information: financialInfo ? {
                pan_number: financialInfo.panNumber || '',
                gst_number: financialInfo.gstNumber || '',
                udyam_number: financialInfo.udyamNumber || '',
                filed_itr: financialInfo.filedITR || false,
                itr_years: financialInfo.itrYears || '',
                turnover_range: financialInfo.turnoverRange || '',
                fy_2021: financialInfo.fy2021 || '',
                fy_2020: financialInfo.fy2020 || '',
                fy_2019: financialInfo.fy2019 || '',
                govt_scheme_benefit: financialInfo.govtSchemeBenefit || false,
                scheme_1: financialInfo.scheme1 || '',
                scheme_2: financialInfo.scheme2 || '',
                scheme_3: financialInfo.scheme3 || '',
            } : {},

            declaration: declaration ? {
                agree_terms: declaration.agreeToTerms || false,
                submitted_at: declaration.submittedAt || null
            } : {}
        };

        console.log('📤 Sending response with data:');
        console.log(JSON.stringify(memberData, null, 2));

        res.json({
            success: true,
            data: memberData
        });

    } catch (error) {
        console.error('❌ Error fetching member details:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch member details',
            error: error.message
        });
    }
});

// GET /api/browse-members/notifications/:memberId
router.get('/notifications/:memberId', async(req, res) => {
    try {
        const { memberId } = req.params;
        const { page = 1, limit = 20, unreadOnly = false } = req.query;

        const query = { recipientId: memberId };
        if (unreadOnly === 'true') {
            query.isRead = false;
        }

        const skip = (page - 1) * limit;

        const notifications = await Notification.find(query)
            .select('senderId connectionId type title message isRead createdAt')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(parseInt(limit))
            .lean()
            .maxTimeMS(1000);

        const total = await Notification.countDocuments(query);
        const unreadCount = await Notification.countDocuments({
            recipientId: memberId,
            isRead: false
        });

        res.json({
            success: true,
            data: notifications,
            unreadCount,
            pagination: {
                currentPage: parseInt(page),
                totalPages: Math.ceil(total / limit),
                total
            }
        });

    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch notifications',
            error: error.message
        });
    }
});

// PUT /api/browse-members/notifications/:notificationId/read
router.put('/notifications/:notificationId/read', async(req, res) => {
    try {
        const { notificationId } = req.params;

        const notification = await Notification.findByIdAndUpdate(
            notificationId, { isRead: true }, { new: true, lean: true }
        );

        if (!notification) {
            return res.status(404).json({
                success: false,
                message: 'Notification not found'
            });
        }

        res.json({
            success: true,
            message: 'Notification marked as read',
            data: notification
        });

    } catch (error) {
        console.error('Error marking notification as read:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to mark notification as read',
            error: error.message
        });
    }
});

module.exports = router;