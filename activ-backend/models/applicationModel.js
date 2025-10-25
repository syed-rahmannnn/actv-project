const mongoose = require("mongoose");

const applicationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  fullName: { type: String, required: true },
  email: { type: String, required: true },
  phone: { type: String, required: true },
  state: { type: String, required: true },
  district: { type: String, required: true },
  block: { type: String, required: true },
  formData: { type: Object, required: true }, // all data submitted from declaration form
  status: {
    type: String,
    enum: ["Pending-Block", "Pending-District", "Pending-State", "Approved", "Rejected"],
    default: "Pending-Block",
  },
  assignedBlockAdmin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "BlockAdmin",
  },
  assignedDistrictAdmin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "DistrictAdmin",
  },
  assignedStateAdmin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "StateAdmin",
  },
  rejectionReason: { type: String, default: null },
  blockApprovedAt: { type: Date, default: null },
  districtApprovedAt: { type: Date, default: null },
  stateApprovedAt: { type: Date, default: null },
  reviewedBy: {
    blockAdmin: { type: mongoose.Schema.Types.ObjectId, ref: "BlockAdmin" },
    districtAdmin: { type: mongoose.Schema.Types.ObjectId, ref: "DistrictAdmin" },
    stateAdmin: { type: mongoose.Schema.Types.ObjectId, ref: "StateAdmin" }
  }
}, {
  timestamps: true // automatically adds createdAt and updatedAt
});

// Add indexes for better query performance
applicationSchema.index({ userId: 1 });
applicationSchema.index({ assignedBlockAdmin: 1, status: 1 });
applicationSchema.index({ assignedDistrictAdmin: 1, status: 1 });
applicationSchema.index({ assignedStateAdmin: 1, status: 1 });
applicationSchema.index({ status: 1 });

module.exports = mongoose.model("Application", applicationSchema);