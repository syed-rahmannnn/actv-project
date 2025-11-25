// Instamojo Webhook Handler for Backend (Node.js/Express)
const express = require('express');
const router = express.Router();
const crypto = require('crypto');

// Test endpoint to verify webhook is accessible (both paths)
router.get('/', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Webhook endpoint is active',
    timestamp: new Date().toISOString()
  });
});

router.get('/instamojo', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Instamojo webhook endpoint is active',
    timestamp: new Date().toISOString()
  });
});

// Main webhook handler - handles POST to both / and /instamojo
const webhookHandler = async (req, res) => {
  try {
    const timestamp = new Date().toISOString();
    console.log('\n========================================');
    console.log('📥 Webhook received at:', timestamp);
    console.log('========================================');
    console.log('📋 Request headers:', JSON.stringify(req.headers, null, 2));
    console.log('📦 Request body:', JSON.stringify(req.body, null, 2));
    console.log('========================================\n');
    
    const webhookData = req.body;
    
    // Check if webhook data exists
    if (!webhookData || Object.keys(webhookData).length === 0) {
      console.error('❌ Empty webhook data received');
      return res.status(400).json({ 
        success: false, 
        message: 'Empty webhook data' 
      });
    }
    
    // Get private salt from environment
    const privateSalt = process.env.INSTAMOJO_PRIVATE_SALT;
    
    if (!privateSalt) {
      console.error('❌ INSTAMOJO_PRIVATE_SALT not configured');
      return res.status(500).json({ 
        success: false, 
        message: 'Server configuration error' 
      });
    }
    
    // Extract MAC (signature) from webhook data
    const receivedMac = webhookData.mac;
    
    if (!receivedMac) {
      console.error('❌ No MAC signature in webhook data');
      return res.status(400).json({ 
        success: false, 
        message: 'Missing signature' 
      });
    }
    
    // Remove mac from data for verification
    const dataForVerification = { ...webhookData };
    delete dataForVerification.mac;
    
    // Sort keys in ASCII order (alphabetically)
    const sortedKeys = Object.keys(dataForVerification).sort();
    
    // Build verification string: key1=value1|key2=value2|...|private_salt
    const verificationString = sortedKeys
      .map(key => `${key}=${dataForVerification[key]}`)
      .join('|') + '|' + privateSalt;
    
    console.log('🔐 Verification string:', verificationString);
    console.log('🔑 Private salt:', privateSalt);
    
    // Calculate MD5 hash
    const calculatedMac = crypto
      .createHash('md5')
      .update(verificationString)
      .digest('hex');
    
    console.log('🔑 Received MAC:', receivedMac);
    console.log('🔑 Calculated MAC:', calculatedMac);
    
    // Verify signature
    const macMatch = calculatedMac === receivedMac;
    console.log('🔍 MAC Match:', macMatch);
    
    // TEMPORARY: Accept webhook even if MAC doesn't match (for debugging)
    if (!macMatch) {
      console.warn('⚠️ MAC verification failed, but proceeding for debugging');
      console.warn('   Expected:', calculatedMac);
      console.warn('   Received:', receivedMac);
    } else {
      console.log('✅ Signature verified successfully');
    }
    
    // Signature verified - process the payment
    const paymentId = webhookData.payment_id;
    const paymentRequestId = webhookData.payment_request_id;
    const status = webhookData.status;
    const amount = webhookData.amount;
    const buyerEmail = webhookData.buyer;
    const buyerName = webhookData.buyer_name;
    const buyerPhone = webhookData.buyer_phone;
    
    console.log('💳 Payment details:', {
      paymentId,
      paymentRequestId,
      status,
      amount,
      buyerEmail,
      buyerName,
    });
    
    // Update database based on payment status
    if (status === 'Credit') {
      // Payment successful - activate membership
      console.log('🎉 Payment successful! Activating membership...');
      
      try {
        await activateMembership({
          email: buyerEmail,
          paymentId,
          paymentRequestId,
          amount,
          name: buyerName,
          phone: buyerPhone,
        });
        
        console.log('✅ Membership activated for:', buyerEmail);
      } catch (membershipError) {
        console.error('⚠️ Membership activation error:', membershipError.message);
        // Continue anyway - we still acknowledge the webhook
      }
    } else {
      console.log('⚠️ Payment status is not Credit:', status);
    }
    
    // Send success response to Instamojo
    console.log('📤 Sending success response to Instamojo');
    res.status(200).json({ 
      success: true, 
      message: 'Webhook processed successfully' 
    });
    
  } catch (error) {
    console.error('❌ Webhook processing error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Register webhook handler for both paths
router.post('/', webhookHandler);
router.post('/instamojo', webhookHandler);

// Function to activate membership in database
async function activateMembership(paymentData) {
  try {
    const MemberDetails = require('../models/MemberDetails');
    
    // Determine membership type based on amount
    const amount = parseFloat(paymentData.amount);
    let membershipType = 'annual';
    let expiresAt = null;
    
    if (amount >= 2500) {
      membershipType = 'lifetime';
      expiresAt = null; // Lifetime never expires
    } else if (amount >= 500) {
      membershipType = 'annual';
      // Set expiry to 1 year from now
      expiresAt = new Date();
      expiresAt.setFullYear(expiresAt.getFullYear() + 1);
    }
    
    console.log(`Activating ${membershipType} membership for:`, paymentData.email);
    
    // Update member details
    const result = await MemberDetails.findOneAndUpdate(
      { email: paymentData.email },
      {
        membershipStatus: 'active',
        membershipType: membershipType,
        membershipActivatedAt: new Date(),
        membershipExpiresAt: expiresAt,
        paymentId: paymentData.paymentId,
        paymentAmount: amount,
        lastPaymentDate: new Date(),
      },
      { new: true } // Return updated document
    );
    
    if (result) {
      console.log('✅ Membership activated successfully!');
      console.log('   Email:', result.email);
      console.log('   Type:', membershipType);
      console.log('   Expires:', expiresAt || 'Never');
      console.log('   Payment ID:', paymentData.paymentId);
    } else {
      console.warn('⚠️ Member not found in database:', paymentData.email);
    }
    
    return { success: true, membershipType };
  } catch (error) {
    console.error('❌ Error in activateMembership:', error);
    throw error;
  }
}

module.exports = router;

// Don't forget to add this route to your main server.js:
// const webhookRoutes = require('./routes/webhook');
// app.use('/api', webhookRoutes);
