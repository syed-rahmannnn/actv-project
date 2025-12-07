const express = require("express");
const router = express.Router();
const Application = require("../models/applicationModel");
const MemberDetails = require("../models/MemberDetails");
const getAdminModels = require("../models/adminModels");

module.exports = (mongooseConnection) => {
    const { BlockAdmin, DistrictAdmin, StateAdmin } = getAdminModels(mongooseConnection || require("mongoose").connection);

    const isHex24 = (s) => typeof s === 'string' && /^[0-9a-fA-F]{24}$/.test(s);

    // Resolve a provided id to the Mongo _id of the admin document.
    // Accepts a Mongo _id string OR the human code (BA..., DA..., SA...).
    async function resolveAdminObjectId(role, id, Models) {
        const { BlockAdmin, DistrictAdmin, StateAdmin } = Models;
        if (!id) {
            console.warn(`resolveAdminObjectId: No id provided for role: ${role}`);
            return null;
        }

        if (isHex24(id)) return id; // already an ObjectId string

        const map = { block: BlockAdmin, district: DistrictAdmin, state: StateAdmin };
        const Model = map[role];
        if (!Model) {
            console.warn(`resolveAdminObjectId: Invalid role: ${role}`);
            return null;
        }

        try {
            // try by adminId code, then by email (nice-to-have)
            const emailQuery = (typeof id.toLowerCase === 'function') ? id.toLowerCase() : id;
            const doc = await Model.findOne({ $or: [{ adminId: id }, { email: emailQuery }] }, { _id: 1 }).lean();
            if (!doc) {
                console.warn(`resolveAdminObjectId: No ${role} record found for id: ${id}`);
                return null;
            }
            return doc._id.toString();
        } catch (error) {
            console.error(`resolveAdminObjectId: Database error for role ${role}, id ${id}:`, error);
            return null;
        }
    }

    // ---------- USER SUBMITS APPLICATION ----------
    router.post("/submit", async(req, res) => {
        try {
            const { userId, fullName, email, phone, state, district, block, formData } = req.body;

            // Validate required fields
            if (!userId || !fullName || !email || !phone || !state || !district || !block || !formData) {
                return res.status(400).json({
                    success: false,
                    message: "All fields are required: userId, fullName, email, phone, state, district, block, formData"
                });
            }

            // Normalize input
            const norm = (s) => (typeof s === 'string' ? s.trim() : s);
            const S = norm(state);
            const D = norm(district);
            const B = norm(block);

            // helpers
            const escapeRx = (v) => v.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            const rx = (v) => new RegExp(`^${escapeRx(norm(v))}$`, 'i');

            // Prefer *_lc fields when present (new seeder will add these)
            const blockAdmin = await BlockAdmin.findOne({
                $or: [
                    { "meta.stateLc": S.toLowerCase(), "meta.districtLc": D.toLowerCase(), "meta.blockLc": B.toLowerCase() },
                    { "meta.state": rx(S), "meta.district": rx(D), "meta.block": rx(B) }
                ],
                active: true
            });

            const districtAdmin = await DistrictAdmin.findOne({
                $or: [
                    { "meta.stateLc": S.toLowerCase(), "meta.districtLc": D.toLowerCase() },
                    { "meta.state": rx(S), "meta.district": rx(D) }
                ],
                active: true
            });

            const stateAdmin = await StateAdmin.findOne({
                $or: [
                    { "meta.stateLc": S.toLowerCase() },
                    { "meta.state": rx(S) }
                ],
                active: true
            });

            if (!blockAdmin || !districtAdmin || !stateAdmin) {
                return res.status(404).json({
                    success: false,
                    message: "No matching admins found for this location",
                    details: {
                        blockAdminFound: !!blockAdmin,
                        districtAdminFound: !!districtAdmin,
                        stateAdminFound: !!stateAdmin
                    }
                });
            }

            // Check if user already has a pending application
            const existingApp = await Application.findOne({
                userId,
                status: { $in: ["Pending-Block", "Pending-District", "Pending-State"] }
            });

            if (existingApp) {
                return res.status(409).json({
                    success: false,
                    message: "You already have a pending application",
                    application: existingApp
                });
            }

            const newApp = await Application.create({
                userId,
                fullName,
                email,
                phone,
                state: S,
                district: D,
                block: B,
                formData,
                assignedBlockAdmin: blockAdmin._id,
                assignedDistrictAdmin: districtAdmin._id,
                assignedStateAdmin: stateAdmin._id,
                status: "Pending-Block",
            });

            res.status(201).json({
                success: true,
                message: "Application submitted successfully",
                application: newApp
            });
        } catch (err) {
            console.error("Application submission error:", err);
            res.status(500).json({ success: false, message: "Server Error" });
        }
    });

    // ---------- BLOCK ADMIN REVIEW ----------
    router.post("/block-review/:appId", async(req, res) => {
        try {
            const { action, reason, adminId } = req.body; // action = "approve" or "reject"

            if (!action || !adminId) {
                return res.status(400).json({
                    success: false,
                    message: "Action and adminId are required"
                });
            }

            const app = await Application.findById(req.params.appId)
                .select('status reviewedBy userId assignedBlockAdmin')
                .maxTimeMS(500); // ✅ OPTIMIZED - Removed .lean() to allow .save()
            if (!app) {
                return res.status(404).json({
                    success: false,
                    message: "Application not found"
                });
            }

            if (app.status !== "Pending-Block") {
                return res.status(400).json({
                    success: false,
                    message: "Application is not in Pending-Block status"
                });
            }

            // Verify the admin is authorized to review this application
            const resolved = await resolveAdminObjectId('block', adminId, { BlockAdmin, DistrictAdmin, StateAdmin });
            if (!resolved) {
                console.error("resolveAdminObjectId failed for block admin:", adminId);
                return res.status(400).json({
                    success: false,
                    message: `Admin not found for role 'block' and ID '${adminId}'`
                });
            }

            if (app.assignedBlockAdmin.toString() !== resolved) {
                return res.status(403).json({
                    success: false,
                    message: "You are not authorized to review this application"
                });
            }

            if (action === "approve") {
                app.status = "Pending-District";
                app.blockApprovedAt = new Date();
                app.reviewedBy.blockAdmin = resolved;
            } else if (action === "reject") {
                app.status = "Rejected";
                app.rejectionReason = reason || "No reason provided";
                app.reviewedBy.blockAdmin = resolved;
            } else {
                return res.status(400).json({
                    success: false,
                    message: "Invalid action. Must be 'approve' or 'reject'"
                });
            }

            await app.save();
            res.json({
                success: true,
                message: `Application ${action}d successfully`,
                status: app.status
            });
        } catch (err) {
            console.error("Block review error:", err);
            res.status(500).json({ success: false, message: "Server error" });
        }
    });

    // ---------- DISTRICT ADMIN REVIEW ----------
    router.post("/district-review/:appId", async(req, res) => {
        try {
            const { action, reason, adminId } = req.body;

            if (!action || !adminId) {
                return res.status(400).json({
                    success: false,
                    message: "Action and adminId are required"
                });
            }

            const app = await Application.findById(req.params.appId)
                .select('status reviewedBy userId assignedDistrictAdmin')
                .maxTimeMS(500); // ✅ OPTIMIZED - Removed .lean() to allow .save()
            if (!app) {
                return res.status(404).json({
                    success: false,
                    message: "Application not found"
                });
            }

            if (app.status !== "Pending-District") {
                return res.status(400).json({
                    success: false,
                    message: "Application is not in Pending-District status"
                });
            }

            // Verify the admin is authorized to review this application
            const resolved = await resolveAdminObjectId('district', adminId, { BlockAdmin, DistrictAdmin, StateAdmin });
            if (!resolved) {
                console.error("resolveAdminObjectId failed for district admin:", adminId);
                return res.status(400).json({
                    success: false,
                    message: `Admin not found for role 'district' and ID '${adminId}'`
                });
            }

            if (app.assignedDistrictAdmin.toString() !== resolved) {
                return res.status(403).json({
                    success: false,
                    message: "You are not authorized to review this application"
                });
            }

            if (action === "approve") {
                app.status = "Pending-State";
                app.districtApprovedAt = new Date();
                app.reviewedBy.districtAdmin = resolved;
            } else if (action === "reject") {
                app.status = "Rejected";
                app.rejectionReason = reason || "No reason provided";
                app.reviewedBy.districtAdmin = resolved;
            } else {
                return res.status(400).json({
                    success: false,
                    message: "Invalid action. Must be 'approve' or 'reject'"
                });
            }

            await app.save();
            res.json({
                success: true,
                message: `Application ${action}d successfully`,
                status: app.status
            });
        } catch (err) {
            console.error("District review error:", err);
            res.status(500).json({ success: false, message: "Server error" });
        }
    });

    // ---------- GET APPLICATIONS FOR BLOCK ADMIN ----------
    // Get ALL applications for Block Admin (for Members page - shows history)
    router.get("/block-all/:blockAdminId", async(req, res) => {
        try {
            const _id = await resolveAdminObjectId('block', req.params.blockAdminId, { BlockAdmin, DistrictAdmin, StateAdmin });
            if (!_id) {
                console.error("resolveAdminObjectId failed for block admin:", req.params.blockAdminId);
                return res.status(400).json({
                    success: false,
                    message: `Admin not found for role 'block' and ID '${req.params.blockAdminId}'`
                });
            }

            // Get ALL applications for this block admin (all statuses)
            const apps = await Application.find({
                assignedBlockAdmin: _id,
            }).sort({ createdAt: -1 });

            // Enhance applications with member approval information and reviewedBy details
            const enhancedApps = await Promise.all(apps.map(async(app) => {
                const appObj = app.toObject();

                console.log(`[ENRICHMENT DEBUG] Processing app ${appObj._id}, current gender:`, appObj.gender);

                // If gender is missing, try to fetch from MemberDetails
                if (!appObj.gender) {
                    try {
                        const memberDetails = await MemberDetails.findOne({
                            email: app.email.toLowerCase().trim()
                        }, 'gender');

                        if (memberDetails && memberDetails.gender) {
                            console.log(`[ENRICHMENT DEBUG] Found gender in MemberDetails for ${app.email}:`, memberDetails.gender);
                            appObj.gender = memberDetails.gender;
                        } else {
                            console.log(`[ENRICHMENT DEBUG] No gender found in MemberDetails for ${app.email}`);
                        }
                    } catch (memberError) {
                        console.error(`[ENRICHMENT DEBUG] Error fetching gender from MemberDetails for ${app.email}:`, memberError);
                    }
                } else {
                    console.log(`[ENRICHMENT DEBUG] App ${appObj._id} already has gender:`, appObj.gender);
                }

                // For approved applications, get member approval details
                if (app.status === 'Approved') {
                    try {
                        const memberDetails = await MemberDetails.findOne({
                            email: app.email.toLowerCase().trim()
                        });

                        if (memberDetails) {
                            appObj.approvedBy = memberDetails.approvedBy;
                            appObj.approvedBlock = memberDetails.approvedBlock;
                            appObj.approvedAt = memberDetails.approvedAt;
                        }
                    } catch (memberError) {
                        console.error("Error fetching member details for app:", app._id, memberError);
                        // Continue without member details if there's an error
                    }
                }

                // Fetch reviewedBy admin data
                if (appObj.reviewedBy) {
                    console.log('Processing reviewedBy for app:', appObj._id, 'reviewedBy:', JSON.stringify(appObj.reviewedBy, null, 2));

                    if (appObj.reviewedBy.blockAdmin) {
                        try {
                            const blockAdmin = await BlockAdmin.findById(appObj.reviewedBy.blockAdmin, 'fullName email adminId meta').lean();
                            console.log('Found block admin:', blockAdmin);
                            if (blockAdmin) {
                                appObj.reviewedBy.blockAdmin = {
                                    fullName: blockAdmin.fullName,
                                    email: blockAdmin.email,
                                    adminId: blockAdmin.adminId,
                                    meta: {
                                        blockName: (blockAdmin.meta && blockAdmin.meta.block) || (blockAdmin.meta && blockAdmin.meta.blockLc) || 'Unknown Block',
                                        districtName: (blockAdmin.meta && blockAdmin.meta.district) || (blockAdmin.meta && blockAdmin.meta.districtLc) || 'Unknown District',
                                        stateName: (blockAdmin.meta && blockAdmin.meta.state) || (blockAdmin.meta && blockAdmin.meta.stateLc) || 'Unknown State'
                                    }
                                };
                                console.log('Enhanced blockAdmin:', JSON.stringify(appObj.reviewedBy.blockAdmin, null, 2));
                            } else {
                                console.log('Block admin not found for ID:', appObj.reviewedBy.blockAdmin);
                                appObj.reviewedBy.blockAdmin = null;
                            }
                        } catch (err) {
                            console.error('Error fetching reviewed by block admin:', err);
                            appObj.reviewedBy.blockAdmin = null;
                        }
                    }

                    if (appObj.reviewedBy.districtAdmin) {
                        try {
                            const districtAdmin = await DistrictAdmin.findById(appObj.reviewedBy.districtAdmin, 'fullName email adminId meta').lean();
                            if (districtAdmin) {
                                appObj.reviewedBy.districtAdmin = {
                                    fullName: districtAdmin.fullName,
                                    email: districtAdmin.email,
                                    adminId: districtAdmin.adminId,
                                    meta: {
                                        districtName: (districtAdmin.meta && districtAdmin.meta.district) || (districtAdmin.meta && districtAdmin.meta.districtLc) || 'Unknown District',
                                        stateName: (districtAdmin.meta && districtAdmin.meta.state) || (districtAdmin.meta && districtAdmin.meta.stateLc) || 'Unknown State'
                                    }
                                };
                            } else {
                                appObj.reviewedBy.districtAdmin = null;
                            }
                        } catch (err) {
                            console.error('Error fetching reviewed by district admin:', err);
                            appObj.reviewedBy.districtAdmin = null;
                        }
                    }

                    if (appObj.reviewedBy.stateAdmin) {
                        try {
                            const stateAdmin = await StateAdmin.findById(appObj.reviewedBy.stateAdmin, 'fullName email adminId meta').lean();
                            if (stateAdmin) {
                                appObj.reviewedBy.stateAdmin = {
                                    fullName: stateAdmin.fullName,
                                    email: stateAdmin.email,
                                    adminId: stateAdmin.adminId,
                                    meta: {
                                        stateName: (stateAdmin.meta && stateAdmin.meta.state) || (stateAdmin.meta && stateAdmin.meta.stateLc) || 'Unknown State'
                                    }
                                };
                            } else {
                                appObj.reviewedBy.stateAdmin = null;
                            }
                        } catch (err) {
                            console.error('Error fetching reviewed by state admin:', err);
                            appObj.reviewedBy.stateAdmin = null;
                        }
                    }
                }

                // Keep original status for Members page
                appObj.status = String(app.status || 'Pending');

                console.log('Final enhanced app for ID:', appObj._id, 'reviewedBy:', JSON.stringify(appObj.reviewedBy, null, 2));
                return appObj;
            }));

            res.json(enhancedApps);
        } catch (err) {
            console.error("Get all block applications error:", err);
            res.status(500).json({ success: false, message: "Server error" });
        }
    });

    // Get PENDING applications for Block Admin (for Approvals page - only needs action)
    router.get("/block/:blockAdminId", async(req, res) => {
        try {
            const _id = await resolveAdminObjectId('block', req.params.blockAdminId, { BlockAdmin, DistrictAdmin, StateAdmin });
            if (!_id) {
                console.error("resolveAdminObjectId failed for block admin:", req.params.blockAdminId);
                return res.status(400).json({
                    success: false,
                    message: `Admin not found for role 'block' and ID '${req.params.blockAdminId}'`
                });
            }

            // Get only applications that need Block Admin action (Pending-Block status)
            const apps = await Application.find({
                assignedBlockAdmin: _id,
                status: 'Pending-Block'
            }).sort({ createdAt: -1 });

            // Enhance applications with member approval information and reviewedBy details
            const enhancedApps = await Promise.all(apps.map(async(app) => {
                const appObj = app.toObject();

                console.log(`[ENRICHMENT DEBUG] Processing app ${appObj._id}, current gender:`, appObj.gender);

                // If gender is missing, try to fetch from MemberDetails
                if (!appObj.gender) {
                    try {
                        const memberDetails = await MemberDetails.findOne({
                            email: app.email.toLowerCase().trim()
                        }, 'gender');

                        if (memberDetails && memberDetails.gender) {
                            console.log(`[ENRICHMENT DEBUG] Found gender in MemberDetails for ${app.email}:`, memberDetails.gender);
                            appObj.gender = memberDetails.gender;
                        } else {
                            console.log(`[ENRICHMENT DEBUG] No gender found in MemberDetails for ${app.email}`);
                        }
                    } catch (memberError) {
                        console.error(`[ENRICHMENT DEBUG] Error fetching gender from MemberDetails for ${app.email}:`, memberError);
                    }
                } else {
                    console.log(`[ENRICHMENT DEBUG] App ${appObj._id} already has gender:`, appObj.gender);
                }

                // For approved applications, get member approval details
                if (app.status === 'Approved') {
                    try {
                        const memberDetails = await MemberDetails.findOne({
                            email: app.email.toLowerCase().trim()
                        });

                        if (memberDetails) {
                            appObj.approvedBy = memberDetails.approvedBy;
                            appObj.approvedBlock = memberDetails.approvedBlock;
                            appObj.approvedAt = memberDetails.approvedAt;
                        }
                    } catch (memberError) {
                        console.error("Error fetching member details for app:", app._id, memberError);
                        // Continue without member details if there's an error
                    }
                }

                // Fetch reviewedBy admin data
                if (appObj.reviewedBy) {
                    console.log('Processing reviewedBy for app:', appObj._id, 'reviewedBy:', JSON.stringify(appObj.reviewedBy, null, 2));

                    if (appObj.reviewedBy.blockAdmin) {
                        try {
                            const blockAdmin = await BlockAdmin.findById(appObj.reviewedBy.blockAdmin, 'fullName email adminId meta').lean();
                            console.log('Found block admin:', blockAdmin);
                            if (blockAdmin) {
                                appObj.reviewedBy.blockAdmin = {
                                    fullName: blockAdmin.fullName,
                                    email: blockAdmin.email,
                                    adminId: blockAdmin.adminId,
                                    meta: {
                                        blockName: (blockAdmin.meta && blockAdmin.meta.block) || (blockAdmin.meta && blockAdmin.meta.blockLc) || 'Unknown Block',
                                        districtName: (blockAdmin.meta && blockAdmin.meta.district) || (blockAdmin.meta && blockAdmin.meta.districtLc) || 'Unknown District',
                                        stateName: (blockAdmin.meta && blockAdmin.meta.state) || (blockAdmin.meta && blockAdmin.meta.stateLc) || 'Unknown State'
                                    }
                                };
                                console.log('Enhanced blockAdmin:', JSON.stringify(appObj.reviewedBy.blockAdmin, null, 2));
                            } else {
                                console.log('Block admin not found for ID:', appObj.reviewedBy.blockAdmin);
                                appObj.reviewedBy.blockAdmin = null;
                            }
                        } catch (err) {
                            console.error('Error fetching reviewed by block admin:', err);
                            appObj.reviewedBy.blockAdmin = null;
                        }
                    }

                    if (appObj.reviewedBy.districtAdmin) {
                        try {
                            const districtAdmin = await DistrictAdmin.findById(appObj.reviewedBy.districtAdmin, 'fullName email adminId meta').lean();
                            if (districtAdmin) {
                                appObj.reviewedBy.districtAdmin = {
                                    fullName: districtAdmin.fullName,
                                    email: districtAdmin.email,
                                    adminId: districtAdmin.adminId,
                                    meta: {
                                        districtName: (districtAdmin.meta && districtAdmin.meta.district) || (districtAdmin.meta && districtAdmin.meta.districtLc) || 'Unknown District',
                                        stateName: (districtAdmin.meta && districtAdmin.meta.state) || (districtAdmin.meta && districtAdmin.meta.stateLc) || 'Unknown State'
                                    }
                                };
                            } else {
                                appObj.reviewedBy.districtAdmin = null;
                            }
                        } catch (err) {
                            console.error('Error fetching reviewed by district admin:', err);
                            appObj.reviewedBy.districtAdmin = null;
                        }
                    }

                    if (appObj.reviewedBy.stateAdmin) {
                        try {
                            const stateAdmin = await StateAdmin.findById(appObj.reviewedBy.stateAdmin, 'fullName email adminId meta').lean();
                            if (stateAdmin) {
                                appObj.reviewedBy.stateAdmin = {
                                    fullName: stateAdmin.fullName,
                                    email: stateAdmin.email,
                                    adminId: stateAdmin.adminId,
                                    meta: {
                                        stateName: (stateAdmin.meta && stateAdmin.meta.state) || (stateAdmin.meta && stateAdmin.meta.stateLc) || 'Unknown State'
                                    }
                                };
                            } else {
                                appObj.reviewedBy.stateAdmin = null;
                            }
                        } catch (err) {
                            console.error('Error fetching reviewed by state admin:', err);
                            appObj.reviewedBy.stateAdmin = null;
                        }
                    }
                }

                // Block-level status display for Block Admin UI
                // Only show "Pending" if block admin hasn't reviewed yet
                // Show "Approved" only if fully approved, otherwise show original status
                try {
                    const rb = appObj.reviewedBy || {};
                    const hasBlockReview = !!rb.blockAdmin;
                    const originalStatus = String(app.status || '');

                    if (!hasBlockReview && originalStatus === 'Pending-Block') {
                        // Not reviewed by block admin yet - show as Pending
                        appObj.status = 'Pending';
                    } else {
                        // Block admin has already reviewed - keep original status
                        // This will show: Pending-District, Pending-State, Approved, or Rejected
                        appObj.status = originalStatus;
                    }
                } catch (e) {
                    console.error('Status normalization error:', e);
                    // Fallback: keep original status
                    appObj.status = String(app.status || 'Pending');
                }

                console.log('Final enhanced app for ID:', appObj._id, 'reviewedBy:', JSON.stringify(appObj.reviewedBy, null, 2));
                return appObj;
            }));

            // Support optional wrapped response with top-level adminMeta, without breaking existing array shape
            const includeMetaParam = String(req.query.includeMeta || '').toLowerCase();
            const includeMeta = includeMetaParam === '1' || includeMetaParam === 'true' || includeMetaParam === 'yes';

            if (includeMeta) {
                let adminMeta = {};
                try {
                    const ba = await BlockAdmin.findById(_id, 'fullName email adminId meta').lean();
                    if (ba) {
                        adminMeta = {
                            fullName: ba.fullName,
                            email: ba.email,
                            adminId: ba.adminId,
                            blockName: (ba.meta && ba.meta.block) || (ba.meta && ba.meta.blockLc) || 'Unknown Block',
                            districtName: (ba.meta && ba.meta.district) || (ba.meta && ba.meta.districtLc) || 'Unknown District',
                            stateName: (ba.meta && ba.meta.state) || (ba.meta && ba.meta.stateLc) || 'Unknown State',
                        };
                    } else {
                        adminMeta = { blockName: 'Unknown Block' };
                    }
                } catch (e) {
                    console.error('Error fetching block admin meta:', e);
                    adminMeta = { blockName: 'Unknown Block' };
                }
                return res.json({ applications: enhancedApps, count: enhancedApps.length, adminMeta });
            }

            // Default: return array for backward compatibility
            res.json(enhancedApps); // Return enhanced applications with member approval info
        } catch (err) {
            console.error("Fetch block applications error:", err);
            res.status(500).json({ success: false, message: "Server error" });
        }
    });

    // ---------- GET APPLICATIONS FOR DISTRICT ADMIN ----------
    // Return ALL applications assigned to the district admin (not only Pending-District),
    // mirroring the behavior of the block admin route.
    router.get("/district/:districtAdminId", async(req, res) => {
        try {
            const _id = await resolveAdminObjectId('district', req.params.districtAdminId, { BlockAdmin, DistrictAdmin, StateAdmin });
            if (!_id) {
                console.error("resolveAdminObjectId failed for district admin:", req.params.districtAdminId);
                return res.status(400).json({
                    success: false,
                    message: `Admin not found for role 'district' and ID '${req.params.districtAdminId}'`
                });
            }

            // Fetch only PENDING applications for district admin (Approvals page)
            const apps = await Application.find({
                assignedDistrictAdmin: _id,
                status: 'Pending-District'
            }).sort({ createdAt: -1 });

            // Enhance applications similarly to the block admin route with reviewedBy and member info
            const enhancedApps = await Promise.all(apps.map(async(app) => {
                const appObj = app.toObject();

                console.log(`[DISTRICT ENRICHMENT DEBUG] Processing app ${appObj._id}, current gender:`, appObj.gender);

                // If gender is missing, try to fetch from MemberDetails
                if (!appObj.gender) {
                    try {
                        const memberDetails = await MemberDetails.findOne({
                            email: app.email.toLowerCase().trim()
                        }, 'gender');

                        if (memberDetails && memberDetails.gender) {
                            console.log(`[DISTRICT ENRICHMENT DEBUG] Found gender in MemberDetails for ${app.email}:`, memberDetails.gender);
                            appObj.gender = memberDetails.gender;
                        } else {
                            console.log(`[DISTRICT ENRICHMENT DEBUG] No gender found in MemberDetails for ${app.email}`);
                        }
                    } catch (memberError) {
                        console.error(`[DISTRICT ENRICHMENT DEBUG] Error fetching gender from MemberDetails for ${app.email}:`, memberError);
                    }
                } else {
                    console.log(`[DISTRICT ENRICHMENT DEBUG] App ${appObj._id} already has gender:`, appObj.gender);
                }

                // ReviewedBy safety checks are handled in the GET /:appId route, but we add basic references here
                // (Keep lightweight to avoid extra DB calls unless necessary)
                // You can expand with DistrictAdmin/StateAdmin hydration if needed, matching the GET /:appId behavior.

                // Attach simple member approval info if present
                try {
                    const member = await MemberDetails.findOne({ userId: appObj.userId }).lean();
                    if (member && member.approvedBy) {
                        appObj.memberApprovedBy = {
                            blockAdmin: member.approvedBy.blockAdmin || null,
                            districtAdmin: member.approvedBy.districtAdmin || null,
                            stateAdmin: member.approvedBy.stateAdmin || null,
                        };
                        appObj.memberApprovedAt = member.approvedAt || null;
                    }
                } catch (err) {
                    console.error('Error fetching member details for app', appObj._id, err);
                }

                return appObj;
            }));

            res.json({
                success: true,
                applications: enhancedApps,
                count: enhancedApps.length
            });
        } catch (err) {
            console.error("Fetch district applications error:", err);
            res.status(500).json({ success: false, message: "Server error" });
        }
    });

    // Get ALL applications for District Admin (for Members page)
    router.get("/district-all/:districtAdminId", async(req, res) => {
        try {
            const _id = await resolveAdminObjectId('district', req.params.districtAdminId, { BlockAdmin, DistrictAdmin, StateAdmin });
            if (!_id) {
                console.error("resolveAdminObjectId failed for district admin:", req.params.districtAdminId);
                return res.status(400).json({
                    success: false,
                    message: `Admin not found for role 'district' and ID '${req.params.districtAdminId}'`
                });
            }

            // Get ALL applications (no status filter)
            const apps = await Application.find({
                assignedDistrictAdmin: _id,
            }).sort({ createdAt: -1 });

            const enhancedApps = apps.map(app => {
                const appObj = app.toObject();
                appObj.status = String(app.status || 'Pending');
                return appObj;
            });

            res.json(enhancedApps);
        } catch (err) {
            console.error("Get all district applications error:", err);
            res.status(500).json({ success: false, message: "Server error" });
        }
    });

    // Get ALL applications for State Admin (for Members page)
    router.get("/state-all/:stateAdminId", async(req, res) => {
        try {
            const _id = await resolveAdminObjectId('state', req.params.stateAdminId, { BlockAdmin, DistrictAdmin, StateAdmin });
            if (!_id) {
                console.error("resolveAdminObjectId failed for state admin:", req.params.stateAdminId);
                return res.status(400).json({
                    success: false,
                    message: `Admin not found for role 'state' and ID '${req.params.stateAdminId}'`
                });
            }

            // Get ALL applications (no status filter)
            const apps = await Application.find({
                assignedStateAdmin: _id,
            }).sort({ createdAt: -1 });

            const enhancedApps = apps.map(app => {
                const appObj = app.toObject();
                appObj.status = String(app.status || 'Pending');
                return appObj;
            });

            res.json(enhancedApps);
        } catch (err) {
            console.error("Get all state applications error:", err);
            res.status(500).json({ success: false, message: "Server error" });
        }
    });

    // ---------- GET APPLICATIONS FOR STATE ADMIN ----------
    router.get("/state/:stateAdminId", async(req, res) => {
        try {
            const _id = await resolveAdminObjectId('state', req.params.stateAdminId, { BlockAdmin, DistrictAdmin, StateAdmin });
            if (!_id) {
                console.error("resolveAdminObjectId failed for state admin:", req.params.stateAdminId);
                return res.status(400).json({
                    success: false,
                    message: `Admin not found for role 'state' and ID '${req.params.stateAdminId}'`
                });
            }

            // Only fetch applications relevant to State Admin members page:
            // - Pending at state level ("Pending-State")
            // - Approved by state ("Approved")
            // - Rejected ("Rejected")
            // Excludes block-pending and district-pending applications.
            const statusParam = (req.query.status || '').toString().trim();
            let statusFilter;
            if (statusParam) {
                // Optional filtering by a single status when provided
                const allowed = ["Pending-State", "Approved", "Rejected"];
                if (allowed.includes(statusParam)) {
                    statusFilter = statusParam;
                } else {
                    // If an unsupported status is requested, default to allowed set
                    statusFilter = { $in: allowed };
                }
            } else {
                statusFilter = { $in: ["Pending-State", "Approved", "Rejected"] };
            }

            const apps = await Application.find({
                assignedStateAdmin: _id,
                status: statusFilter,
            }).sort({ createdAt: -1 });

            // Enhance applications similarly to the district admin route with member info
            const enhancedApps = await Promise.all(apps.map(async(app) => {
                const appObj = app.toObject();

                console.log(`[STATE ENRICHMENT DEBUG] Processing app ${appObj._id}, current gender:`, appObj.gender);

                // If gender is missing, try to fetch from MemberDetails
                if (!appObj.gender) {
                    try {
                        const memberDetails = await MemberDetails.findOne({
                            email: app.email.toLowerCase().trim()
                        }, 'gender');

                        if (memberDetails && memberDetails.gender) {
                            console.log(`[STATE ENRICHMENT DEBUG] Found gender in MemberDetails for ${app.email}:`, memberDetails.gender);
                            appObj.gender = memberDetails.gender;
                        } else {
                            console.log(`[STATE ENRICHMENT DEBUG] No gender found in MemberDetails for ${app.email}`);
                        }
                    } catch (memberError) {
                        console.error(`[STATE ENRICHMENT DEBUG] Error fetching gender from MemberDetails for ${app.email}:`, memberError);
                    }
                } else {
                    console.log(`[STATE ENRICHMENT DEBUG] App ${appObj._id} already has gender:`, appObj.gender);
                }

                // Attach simple member approval info if present
                try {
                    const member = await MemberDetails.findOne({ userId: appObj.userId }).lean();
                    if (member && member.approvedBy) {
                        appObj.memberApprovedBy = {
                            blockAdmin: member.approvedBy.blockAdmin || null,
                            districtAdmin: member.approvedBy.districtAdmin || null,
                            stateAdmin: member.approvedBy.stateAdmin || null,
                        };
                        appObj.memberApprovedAt = member.approvedAt || null;
                    }
                } catch (err) {
                    console.error('Error fetching member details for app', appObj._id, err);
                }

                return appObj;
            }));

            res.json({ success: true, applications: enhancedApps, count: enhancedApps.length });
        } catch (err) {
            console.error("Fetch state applications error:", err);
            res.status(500).json({ success: false, message: "Server error" });
        }
    });

    // ---------- STATE ADMIN REVIEW ----------
    router.post("/state-review/:appId", async(req, res) => {
        try {
            const { action, reason, adminId } = req.body; // "approve" | "reject"
            if (!action || !adminId) {
                return res.status(400).json({ success: false, message: "Action and adminId are required" });
            }

            const app = await Application.findById(req.params.appId)
                .maxTimeMS(500); // ✅ OPTIMIZED - Removed .lean() to allow .save()
            if (!app) return res.status(404).json({ success: false, message: "Application not found" });

            if (app.status !== "Pending-State") {
                return res.status(400).json({ success: false, message: "Application is not in Pending-State status" });
            }

            const resolved = await resolveAdminObjectId('state', adminId, { BlockAdmin, DistrictAdmin, StateAdmin });
            if (!resolved) {
                console.error("resolveAdminObjectId failed for state admin:", adminId);
                return res.status(400).json({
                    success: false,
                    message: `Admin not found for role 'state' and ID '${adminId}'`
                });
            }

            if (app.assignedStateAdmin.toString() !== resolved) {
                return res.status(403).json({
                    success: false,
                    message: "You are not authorized to review this application"
                });
            }

            if (action === "approve") {
                app.status = "Approved";
                app.stateApprovedAt = new Date();
                app.reviewedBy.stateAdmin = resolved;

                // Update member approval information
                try {
                    // Get the block admin who initially approved this application
                    const blockAdmin = await BlockAdmin.findById(app.reviewedBy.blockAdmin)
                        .select('name email')
                        .lean()
                        .maxTimeMS(500); // ✅ OPTIMIZED
                    if (blockAdmin) {
                        await MemberDetails.findOneAndUpdate({ email: app.email.toLowerCase().trim() }, {
                            approvedBy: blockAdmin.fullName,
                            approvedBlock: app.block,
                            approvedAt: new Date()
                        });
                    }
                } catch (memberUpdateError) {
                    console.error("Error updating member approval info:", memberUpdateError);
                    // Don't fail the application approval if member update fails
                }
            } else if (action === "reject") {
                app.status = "Rejected";
                app.rejectionReason = reason || "No reason provided";
                app.reviewedBy.stateAdmin = resolved;
            } else {
                return res.status(400).json({ success: false, message: "Invalid action. Must be 'approve' or 'reject'" });
            }

            await app.save();
            res.json({ success: true, message: `Application ${action}d successfully`, status: app.status });
        } catch (err) {
            console.error("State review error:", err);
            res.status(500).json({ success: false, message: "Server error" });
        }
    });

    // ---------- GET APPLICATION STATUS FOR USER ----------
    router.get("/user/:userId", async(req, res) => {
        try {
            const apps = await Application.find({ userId: req.params.userId })
                .lean() // ✅ OPTIMIZED
                .maxTimeMS(500)
                .sort({ createdAt: -1 });

            // Manually fetch admin data for each application
            const appsWithAdminData = await Promise.all(apps.map(async(app) => {
                const appObj = app;

                // Fetch block admin data
                if (appObj.assignedBlockAdmin) {
                    try {
                        const blockAdmin = await BlockAdmin.findById(appObj.assignedBlockAdmin, 'fullName email').lean();
                        appObj.assignedBlockAdmin = blockAdmin;
                    } catch (err) {
                        console.error('Error fetching block admin:', err);
                        appObj.assignedBlockAdmin = null;
                    }
                }

                // Fetch district admin data
                if (appObj.assignedDistrictAdmin) {
                    try {
                        const districtAdmin = await DistrictAdmin.findById(appObj.assignedDistrictAdmin, 'fullName email').lean();
                        appObj.assignedDistrictAdmin = districtAdmin;
                    } catch (err) {
                        console.error('Error fetching district admin:', err);
                        appObj.assignedDistrictAdmin = null;
                    }
                }

                // Fetch state admin data
                if (appObj.assignedStateAdmin) {
                    try {
                        const stateAdmin = await StateAdmin.findById(appObj.assignedStateAdmin, 'fullName email').lean();
                        appObj.assignedStateAdmin = stateAdmin;
                    } catch (err) {
                        console.error('Error fetching state admin:', err);
                        appObj.assignedStateAdmin = null;
                    }
                }

                return appObj;
            }));

            res.json({
                success: true,
                applications: appsWithAdminData,
                count: appsWithAdminData.length
            });
        } catch (err) {
            console.error("Fetch user applications error:", err);
            res.status(500).json({ success: false, message: "Server error" });
        }
    });

    // ---------- GET APPLICATIONS BY ADMIN (for stats) ----------
    router.get("/by-admin/:adminId", async(req, res) => {
        try {
            const { role, status } = req.query;
            let adminObjId = await resolveAdminObjectId(role, req.params.adminId, { BlockAdmin, DistrictAdmin, StateAdmin });

            if (!role || !status) {
                return res.status(400).json({
                    success: false,
                    message: "Role and status query parameters are required"
                });
            }

            if (!adminObjId) {
                console.error("resolveAdminObjectId failed for:", role, req.params.adminId);
                return res.status(400).json({
                    success: false,
                    message: `Admin not found for role '${role}' and ID '${req.params.adminId}'`
                });
            }

            const q = {};
            if (role === 'block') q.assignedBlockAdmin = adminObjId;
            if (role === 'district') q.assignedDistrictAdmin = adminObjId;
            if (role === 'state') q.assignedStateAdmin = adminObjId;

            if (status === 'Approved') {
                if (role === 'block') q.status = { $in: ['Pending-District', 'Pending-State', 'Approved'] }, q['reviewedBy.blockAdmin'] = { $exists: true };
                if (role === 'district') q.status = { $in: ['Pending-State', 'Approved'] }, q['reviewedBy.districtAdmin'] = { $exists: true };
                if (role === 'state') q.status = 'Approved', q['reviewedBy.stateAdmin'] = { $exists: true };
            } else if (status === 'Rejected') {
                q.status = 'Rejected';
                if (role === 'block') q['reviewedBy.blockAdmin'] = { $exists: true };
                if (role === 'district') q['reviewedBy.districtAdmin'] = { $exists: true };
                if (role === 'state') q['reviewedBy.stateAdmin'] = { $exists: true };
            }

            const count = await Application.countDocuments(q);
            res.json({ success: true, count, role, status });
        } catch (err) {
            console.error("Get applications by admin error:", err);
            res.status(500).json({ success: false, message: "Server error" });
        }
    });

    // ---------- GET APPLICATION DETAILS ----------
    router.get("/:appId", async(req, res) => {
        try {
            const app = await Application.findById(req.params.appId)
                .lean()
                .maxTimeMS(500); // ✅ OPTIMIZED

            if (!app) {
                return res.status(404).json({
                    success: false,
                    message: "Application not found"
                });
            }

            const appObj = app; // Already a plain object from .lean()

            // Manually fetch admin data
            if (appObj.assignedBlockAdmin) {
                try {
                    const blockAdmin = await BlockAdmin.findById(appObj.assignedBlockAdmin, 'fullName email adminId').lean();
                    appObj.assignedBlockAdmin = blockAdmin;
                } catch (err) {
                    console.error('Error fetching block admin:', err);
                    appObj.assignedBlockAdmin = null;
                }
            }

            if (appObj.assignedDistrictAdmin) {
                try {
                    const districtAdmin = await DistrictAdmin.findById(appObj.assignedDistrictAdmin, 'fullName email adminId').lean();
                    appObj.assignedDistrictAdmin = districtAdmin;
                } catch (err) {
                    console.error('Error fetching district admin:', err);
                    appObj.assignedDistrictAdmin = null;
                }
            }

            if (appObj.assignedStateAdmin) {
                try {
                    const stateAdmin = await StateAdmin.findById(appObj.assignedStateAdmin, 'fullName email adminId').lean();
                    appObj.assignedStateAdmin = stateAdmin;
                } catch (err) {
                    console.error('Error fetching state admin:', err);
                    appObj.assignedStateAdmin = null;
                }
            }

            // Fetch reviewedBy admin data
            if (appObj.reviewedBy) {
                if (appObj.reviewedBy.blockAdmin) {
                    try {
                        const blockAdmin = await BlockAdmin.findById(appObj.reviewedBy.blockAdmin, 'fullName email adminId meta').lean();
                        if (blockAdmin) {
                            appObj.reviewedBy.blockAdmin = {
                                fullName: blockAdmin.fullName,
                                email: blockAdmin.email,
                                adminId: blockAdmin.adminId,
                                blockName: (blockAdmin.meta && blockAdmin.meta.block) || (blockAdmin.meta && blockAdmin.meta.blockLc) || 'Unknown Block',
                                districtName: (blockAdmin.meta && blockAdmin.meta.district) || (blockAdmin.meta && blockAdmin.meta.districtLc) || 'Unknown District',
                                stateName: (blockAdmin.meta && blockAdmin.meta.state) || (blockAdmin.meta && blockAdmin.meta.stateLc) || 'Unknown State'
                            };
                        } else {
                            appObj.reviewedBy.blockAdmin = null;
                        }
                    } catch (err) {
                        console.error('Error fetching reviewed by block admin:', err);
                        appObj.reviewedBy.blockAdmin = null;
                    }
                }

                if (appObj.reviewedBy.districtAdmin) {
                    try {
                        const districtAdmin = await DistrictAdmin.findById(appObj.reviewedBy.districtAdmin, 'fullName email adminId meta').lean();
                        if (districtAdmin) {
                            appObj.reviewedBy.districtAdmin = {
                                fullName: districtAdmin.fullName,
                                email: districtAdmin.email,
                                adminId: districtAdmin.adminId,
                                districtName: (districtAdmin.meta && districtAdmin.meta.district) || (districtAdmin.meta && districtAdmin.meta.districtLc) || 'Unknown District',
                                stateName: (districtAdmin.meta && districtAdmin.meta.state) || (districtAdmin.meta && districtAdmin.meta.stateLc) || 'Unknown State'
                            };
                        } else {
                            appObj.reviewedBy.districtAdmin = null;
                        }
                    } catch (err) {
                        console.error('Error fetching reviewed by district admin:', err);
                        appObj.reviewedBy.districtAdmin = null;
                    }
                }

                if (appObj.reviewedBy.stateAdmin) {
                    try {
                        const stateAdmin = await StateAdmin.findById(appObj.reviewedBy.stateAdmin, 'fullName email adminId meta').lean();
                        if (stateAdmin) {
                            appObj.reviewedBy.stateAdmin = {
                                fullName: stateAdmin.fullName,
                                email: stateAdmin.email,
                                adminId: stateAdmin.adminId,
                                stateName: (stateAdmin.meta && stateAdmin.meta.state) || (stateAdmin.meta && stateAdmin.meta.stateLc) || 'Unknown State'
                            };
                        } else {
                            appObj.reviewedBy.stateAdmin = null;
                        }
                    } catch (err) {
                        console.error('Error fetching reviewed by state admin:', err);
                        appObj.reviewedBy.stateAdmin = null;
                    }
                }
            }

            res.json({
                success: true,
                application: appObj
            });
        } catch (err) {
            console.error("Fetch application details error:", err);
            res.status(500).json({ success: false, message: "Server error" });
        }
    });

    return router;
};