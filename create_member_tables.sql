-- Create MemberRegistration table
CREATE TABLE "public"."MemberRegistration" (
    "id" TEXT NOT NULL,
    "fullName" TEXT NOT NULL,
    "phoneNumber" TEXT NOT NULL,
    "dateOfBirth" TIMESTAMP(3) NOT NULL,
    "gender" "public"."Gender" NOT NULL,
    "profilePicture" TEXT,
    "address" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "district" TEXT NOT NULL,
    "pincode" TEXT NOT NULL,
    "country" TEXT NOT NULL DEFAULT 'India',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "memberType" TEXT,
    "membershipNumber" TEXT,
    "registrationDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastLoginDate" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "userId" TEXT NOT NULL,

    CONSTRAINT "MemberRegistration_pkey" PRIMARY KEY ("id")
);

-- Create MemberProfileCompletion table
CREATE TABLE "public"."MemberProfileCompletion" (
    "id" TEXT NOT NULL,
    "aadhaarNumber" TEXT,
    "streetName" TEXT,
    "educationalQualification" TEXT,
    "religion" TEXT,
    "socialCategory" TEXT,
    "maritalStatus" TEXT,
    "fatherName" TEXT,
    "motherName" TEXT,
    "spouseName" TEXT,
    "businessName" TEXT,
    "businessType" TEXT,
    "businessCategory" TEXT,
    "businessDescription" TEXT,
    "businessAddress" TEXT,
    "businessCity" TEXT,
    "businessState" TEXT,
    "businessPincode" TEXT,
    "businessPhone" TEXT,
    "businessEmail" TEXT,
    "businessWebsite" TEXT,
    "businessRegistrationNumber" TEXT,
    "gstNumber" TEXT,
    "panNumber" TEXT,
    "businessLicenseNumber" TEXT,
    "yearsInBusiness" INTEGER,
    "numberOfEmployees" INTEGER,
    "annualRevenue" DOUBLE PRECISION,
    "businessOwnership" TEXT,
    "bankName" TEXT,
    "accountNumber" TEXT,
    "ifscCode" TEXT,
    "accountHolderName" TEXT,
    "taxId" TEXT,
    "taxFilingStatus" TEXT,
    "gstRegistered" BOOLEAN NOT NULL DEFAULT false,
    "creditScore" INTEGER,
    "annualIncome" DOUBLE PRECISION,
    "sourceOfIncome" TEXT,
    "otherIncomeSources" TEXT,
    "liabilities" TEXT,
    "assets" TEXT,
    "emergencyContactName" TEXT,
    "emergencyContactPhone" TEXT,
    "emergencyContactRelation" TEXT,
    "preferredLanguage" TEXT,
    "communicationPreference" TEXT,
    "marketingConsent" BOOLEAN NOT NULL DEFAULT false,
    "termsAccepted" BOOLEAN NOT NULL DEFAULT false,
    "privacyPolicyAccepted" BOOLEAN NOT NULL DEFAULT false,
    "additionalNotes" TEXT,
    "documents" TEXT,
    "stage1Completed" BOOLEAN NOT NULL DEFAULT false,
    "stage2Completed" BOOLEAN NOT NULL DEFAULT false,
    "stage3Completed" BOOLEAN NOT NULL DEFAULT false,
    "stage4Completed" BOOLEAN NOT NULL DEFAULT false,
    "isProfileComplete" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "userId" TEXT NOT NULL,
    "memberRegistrationId" TEXT NOT NULL,

    CONSTRAINT "MemberProfileCompletion_pkey" PRIMARY KEY ("id")
);

-- Create indexes
CREATE UNIQUE INDEX "MemberRegistration_phoneNumber_key" ON "public"."MemberRegistration"("phoneNumber");
CREATE UNIQUE INDEX "MemberRegistration_membershipNumber_key" ON "public"."MemberRegistration"("membershipNumber");
CREATE UNIQUE INDEX "MemberRegistration_userId_key" ON "public"."MemberRegistration"("userId");
CREATE UNIQUE INDEX "MemberProfileCompletion_aadhaarNumber_key" ON "public"."MemberProfileCompletion"("aadhaarNumber");
CREATE UNIQUE INDEX "MemberProfileCompletion_userId_key" ON "public"."MemberProfileCompletion"("userId");
CREATE UNIQUE INDEX "MemberProfileCompletion_memberRegistrationId_key" ON "public"."MemberProfileCompletion"("memberRegistrationId");

-- Add foreign keys
ALTER TABLE "public"."MemberRegistration" ADD CONSTRAINT "MemberRegistration_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "public"."MemberProfileCompletion" ADD CONSTRAINT "MemberProfileCompletion_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "public"."MemberProfileCompletion" ADD CONSTRAINT "MemberProfileCompletion_memberRegistrationId_fkey" FOREIGN KEY ("memberRegistrationId") REFERENCES "public"."MemberRegistration"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

