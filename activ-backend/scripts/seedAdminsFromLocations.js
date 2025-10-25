// node scripts/seedAdminsFromLocations.js
require('dotenv').config({ path: './config.env' });
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const getAdminModels = require('../models/adminModels'); // returns models bound to adminsdb

// ----- config you can tweak -----
const DEFAULT_TEMP_PASSWORD = process.env.ADMIN_TEMP_PASSWORD || 'ChangeMe@123';
const SALT_ROUNDS = 10;
// email pattern: role-sanitized.location@activ.com
const EMAIL_DOMAIN = 'activ.com';

// helpers
const slug = (s) =>
  (s || '')
    .toString()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9]+/g, '.')
    .replace(/\.+/g, '.')
    .replace(/^\.|\.$/g, '')
    .toLowerCase();

const pad = (n, w=3) => String(n).padStart(w, '0');

// deterministic ID builders so re-runs are idempotent
const mkDistrictId = (stateIdx, distIdx) => `DA${pad(stateIdx,2)}${pad(distIdx,3)}`;
const mkBlockId = (stateIdx, distIdx, blockIdx) => `BA${pad(stateIdx,2)}${pad(distIdx,3)}${pad(blockIdx,3)}`;

(async () => {
  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/Cluster1';
  await mongoose.connect(mongoUri, {});

  const { BlockAdmin, DistrictAdmin } = getAdminModels(mongoose.connection); // bound to adminsdb
  // Super/State admins can be seeded separately if you like.

  const locPath = path.join(__dirname, '..', '..', 'assets', 'data', 'locations_nested.json');
  const data = JSON.parse(fs.readFileSync(locPath, 'utf8'));
  const hash = await bcrypt.hash(DEFAULT_TEMP_PASSWORD, SALT_ROUNDS);

  let created = 0, updated = 0, skipped = 0;

  for (let s = 0; s < (data.states || []).length; s++) {
    const state = data.states[s];
    const stateName = state.state;

    const districts = state.districts || [];
    for (let d = 0; d < districts.length; d++) {
      const dist = districts[d];
      const distName = dist.district;

      // --- District Admin ---
      const daId = mkDistrictId(s+1, d+1);
      const daEmail = `district.${slug(distName)}.${slug(stateName)}@${EMAIL_DOMAIN}`;
      const daFilter = { adminId: daId };
      const daDoc = {
        adminId: daId,
        email: daEmail,
        passwordHash: hash,
        fullName: `${distName} District Admin`,
        role: 'DistrictAdmin',
        active: true,
        meta: {
          state: stateName,
          district: distName,
          mustResetPassword: true
        }
      };

      const daRes = await DistrictAdmin.updateOne(daFilter, { $setOnInsert: daDoc }, { upsert: true });
      if (daRes.upsertedCount) created++; else skipped++;

      // --- Block Admins (if blocks exist) ---
      const blocks = Array.isArray(dist.block) ? dist.block : [];
      for (let b = 0; b < blocks.length; b++) {
        const blockName = (blocks[b] || '').trim();
        if (!blockName || blockName === '-') continue; // ignore placeholders

        const baId = mkBlockId(s+1, d+1, b+1);
        const baEmail = `block.${slug(blockName)}.${slug(distName)}.${slug(stateName)}@${EMAIL_DOMAIN}`;
        const baFilter = { adminId: baId };
        const baDoc = {
          adminId: baId,
          email: baEmail,
          passwordHash: hash,
          fullName: `${blockName} Block Admin`,
          role: 'BlockAdmin',
          active: true,
          meta: {
            state: stateName,
            district: distName,
            block: blockName,
            mustResetPassword: true
          }
        };
        const baRes = await BlockAdmin.updateOne(baFilter, { $setOnInsert: baDoc }, { upsert: true });
        if (baRes.upsertedCount) created++; else skipped++;
      }
    }
  }

  console.log({ created, skipped, updated });
  await mongoose.disconnect();
})().catch(err => {
  console.error(err);
  process.exit(1);
});