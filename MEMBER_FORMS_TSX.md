# ACTIV Member Registration Forms - TSX/React Format

This document contains the Flutter Dart screens converted to TypeScript React (TSX) format for web implementation.

---

## 1. Personal Details Form (Step 1 of 4)

### PersonalDetailsForm.tsx

**Based on**: `personal_details_form.dart`

**Features**:
- Auto-save with 2-second debounce
- Form locking after successful save
- Password change functionality (optional)
- Demographic details always editable
- Progress indicator (Step 1 of 4)
- Backend data loading and synchronization

```tsx
import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { debounce } from 'lodash';
import { ApiService } from '../../services/ApiService';

interface UserData {
  email?: string;
  memberId?: string;
  fullName?: string;
  phoneNumber?: string;
  state?: string;
  district?: string;
  block?: string;
  city?: string;
  registrationForm?: {
    fullName?: string;
    phoneNumber?: string;
    email?: string;
    state?: string;
    district?: string;
    block?: string;
    city?: string;
    aadhaarNumber?: string;
    streetName?: string;
    educationalQualification?: string;
    religion?: string;
    socialCategory?: string;
  };
}

interface PersonalDetailsFormProps {
  userData: UserData;
}

const PersonalDetailsForm: React.FC<PersonalDetailsFormProps> = ({ userData }) => {
  const navigate = useNavigate();

  // Form State - Personal Information
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phoneNumber: '',
    state: '',
    district: '',
    block: '',
    city: '',
    password: '',
    confirmPassword: '',
  });

  // Form State - Demographic Details
  const [demographicData, setDemographicData] = useState({
    religion: '',
    socialCategory: '',
  });

  const [obscurePassword, setObscurePassword] = useState(true);
  const [obscureConfirmPassword, setObscureConfirmPassword] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [isFormLocked, setIsFormLocked] = useState(false);
  const [saveStatus, setSaveStatus] = useState<'idle' | 'saving' | 'saved'>('idle');

  const socialCategories = ['Christian SC', 'ST', 'Christian ST', 'Other'];

  // Load member data from backend
  const loadMemberFromBackend = async () => {
    try {
      const email = userData.email || userData.registrationForm?.email;
      if (!email) return userData;

      const response = await ApiService.getMemberByEmail(email);
      if (response.success && response.data) {
        const member = response.data;
        return {
          email,
          memberId: member.memberId || member.id || member._id,
          registrationForm: {
            fullName: member.fullName || '',
            phoneNumber: member.phoneNumber || '',
            email: member.email || '',
            state: member.state || '',
            district: member.district || '',
            block: member.block || '',
            city: member.city || '',
            aadhaarNumber: member.aadhaarNumber || '',
            streetName: member.streetName || '',
            educationalQualification: member.educationalQualification || '',
            religion: member.religion || '',
            socialCategory: member.socialCategory || '',
          },
        };
      }
      return userData;
    } catch (error) {
      console.error('Error loading member data:', error);
      return userData;
    }
  };

  // Check if form is already locked (data exists in backend)
  const checkIfFormIsLocked = async () => {
    try {
      const memberData = await loadMemberFromBackend();
      const regForm = memberData.registrationForm;

      const hasAadhaar = regForm?.aadhaarNumber?.trim().length > 0;
      const hasStreet = regForm?.streetName?.trim().length > 0;
      const hasEducation = regForm?.educationalQualification?.trim().length > 0;

      if (hasAadhaar || hasStreet || hasEducation) {
        setIsFormLocked(true);
        console.log('🔒 Personal details form is locked (already saved)');
      }
    } catch (error) {
      console.error('Error checking form lock status:', error);
    }
  };

  // Populate fields from userData
  useEffect(() => {
    const regForm = userData.registrationForm;
    const member = userData;

    setFormData({
      fullName: regForm?.fullName || member.fullName || '',
      email: member.email || regForm?.email || '',
      phoneNumber: regForm?.phoneNumber || member.phoneNumber || '',
      state: regForm?.state || member.state || '',
      district: regForm?.district || member.district || '',
      block: regForm?.block || member.block || '',
      city: regForm?.city || member.city || '',
      password: '',
      confirmPassword: '',
    });

    setDemographicData({
      religion: regForm?.religion || '',
      socialCategory: regForm?.socialCategory || '',
    });

    checkIfFormIsLocked();
  }, [userData]);

  // Auto-save function with debounce
  const autoSaveData = useCallback(
    debounce(async () => {
      if (isSaving) return;

      setIsSaving(true);
      setSaveStatus('saving');

      try {
        let memberId = userData.memberId;

        // Try to get member ID from backend if not available
        if (!memberId) {
          const email = userData.email;
          if (email) {
            const response = await ApiService.getMemberByEmail(email);
            if (response.success && response.data) {
              memberId = response.data.memberId || response.data.id || response.data._id;
            }
          }
        }

        if (!memberId) {
          console.warn('Auto-save skipped: Member ID not found');
          return;
        }

        // Prepare update data (combining personal and demographic)
        const updateData = {
          fullName: formData.fullName.trim(),
          email: formData.email.trim(),
          phoneNumber: formData.phoneNumber.trim(),
          state: formData.state.trim(),
          district: formData.district.trim(),
          block: formData.block.trim(),
          city: formData.city.trim(),
          religion: demographicData.religion.trim(),
          socialCategory: demographicData.socialCategory,
        };

        // Save to backend
        await ApiService.updateMemberDetails(memberId, updateData);
        setSaveStatus('saved');
        setTimeout(() => setSaveStatus('idle'), 2000);
      } catch (error) {
        console.error('Auto-save error:', error);
      } finally {
        setIsSaving(false);
      }
    }, 2000),
    [formData, demographicData, userData, isSaving]
  );

  // Trigger auto-save on field changes
  useEffect(() => {
    autoSaveData();
  }, [formData, demographicData]);

  // Handle input changes - Personal Details
  const handleInputChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  // Handle input changes - Demographic Details
  const handleDemographicChange = (field: string, value: string) => {
    setDemographicData((prev) => ({ ...prev, [field]: value }));
  };

  // Handle Save Personal Details
  const handleSavePersonalDetails = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validate passwords if provided
    if (formData.password || formData.confirmPassword) {
      if (formData.password !== formData.confirmPassword) {
        alert('Passwords do not match');
        return;
      }
    }

    try {
      let memberId = userData.memberId;

      if (!memberId) {
        const response = await ApiService.getMemberByEmail(userData.email || '');
        if (response.success && response.data) {
          memberId = response.data.memberId || response.data.id || response.data._id;
        }
      }

      if (!memberId) {
        console.error('Member ID not found');
        return;
      }

      const updateData: any = {
        fullName: formData.fullName,
        email: formData.email,
        phoneNumber: formData.phoneNumber,
        state: formData.state,
        district: formData.district,
        block: formData.block,
        city: formData.city,
      };

      if (formData.password) {
        updateData.password = formData.password;
      }

      const response = await ApiService.updateMemberDetails(memberId, updateData);

      if (response.success) {
        setFormData((prev) => ({ ...prev, password: '', confirmPassword: '' }));
        setIsFormLocked(true);
        alert('Personal details saved successfully. Form is now locked.');
      }
    } catch (error) {
      console.error('Error saving personal details:', error);
      alert('Error saving personal details');
    }
  };

  // Navigate to next step
  const handleNext = async () => {
    try {
      // Save data before navigation
      let memberId = userData.memberId;

      if (!memberId) {
        const backendData = await loadMemberFromBackend();
        memberId = backendData?.memberId;
      }

      if (memberId) {
        const updates = {
          religion: demographicData.religion,
          socialCategory: demographicData.socialCategory,
          fullName: formData.fullName,
          email: formData.email,
          phoneNumber: formData.phoneNumber,
          city: formData.city,
          state: formData.state,
          district: formData.district,
          block: formData.block,
        };

        await ApiService.updateMember(memberId, updates);
      }

      // Update userData and navigate
      const updatedUserData = {
        ...userData,
        registrationForm: {
          ...userData.registrationForm,
          religion: demographicData.religion,
          socialCategory: demographicData.socialCategory,
          fullName: formData.fullName,
          phoneNumber: formData.phoneNumber,
          state: formData.state,
          district: formData.district,
          block: formData.block,
          city: formData.city,
        },
        email: formData.email,
        memberId: memberId,
      };

      navigate('/business-information', { state: { userData: updatedUserData } });
    } catch (error) {
      console.error('Error proceeding to next step:', error);
      alert('Error: ' + error);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-100 to-purple-100">
      {/* Header */}
      <div className="bg-blue-600 text-white py-4 text-center">
        <h1 className="text-2xl font-bold">ACTIV</h1>
      </div>

      <div className="max-w-4xl mx-auto px-5 py-8">
        {/* Title */}
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold text-gray-800 mb-2">
            Additional Details Form
          </h2>
          <p className="text-gray-600">Member Registration</p>
        </div>

        {/* Progress Indicator */}
        <div className="flex justify-center items-center mb-8">
          {[1, 2, 3, 4].map((step, index) => (
            <div key={step} className="flex items-center">
              <div
                className={`w-10 h-10 rounded-full flex items-center justify-center font-bold ${
                  step <= 1
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-300 text-gray-600'
                }`}
              >
                {step}
              </div>
              {index < 3 && (
                <div className="w-10 h-0.5 bg-gray-300 mx-1"></div>
              )}
            </div>
          ))}
        </div>
        
        <div className="flex items-center justify-center gap-3 mb-8">
          <p className="text-gray-600">Step 1 of 4</p>
          {saveStatus !== 'idle' && (
            <span
              className={`text-sm ${
                saveStatus === 'saving' ? 'text-blue-600' : 'text-green-600'
              }`}
            >
              {saveStatus === 'saving' ? '💾 Saving...' : '✓ Saved'}
            </span>
          )}
        </div>

        {/* Form Locked Message */}
        {isFormLocked && (
          <div className="mb-6 p-4 bg-green-50 border border-green-200 rounded-lg">
            <div className="flex items-center">
              <span className="text-2xl mr-3">🔒</span>
              <div>
                <p className="font-semibold text-green-800">Form Locked</p>
                <p className="text-sm text-green-700">
                  Personal details have been saved and cannot be edited. Contact
                  support if you need to make changes.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Personal Details Section */}
        <form onSubmit={handleSavePersonalDetails}>
          <div className="bg-white rounded-2xl shadow-lg p-6 mb-8">
            <h3 className="text-xl font-bold text-gray-800 mb-6">
              Personal details
            </h3>

            {/* Name */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Name
              </label>
              <input
                type="text"
                value={formData.fullName}
                onChange={(e) => handleInputChange('fullName', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter your full name"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              />
            </div>

            {/* Block */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Block
              </label>
              <input
                type="text"
                value={formData.block}
                onChange={(e) => handleInputChange('block', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter block"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              />
            </div>

            {/* State */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                State
              </label>
              <input
                type="text"
                value={formData.state}
                onChange={(e) => handleInputChange('state', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter state"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              />
            </div>

            {/* District */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                District
              </label>
              <input
                type="text"
                value={formData.district}
                onChange={(e) => handleInputChange('district', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter district"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              />
            </div>

            {/* City */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                City
              </label>
              <input
                type="text"
                value={formData.city}
                onChange={(e) => handleInputChange('city', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter city"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              />
            </div>

            {/* Phone Number */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Phone Number
              </label>
              <input
                type="tel"
                value={formData.phoneNumber}
                onChange={(e) => handleInputChange('phoneNumber', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter phone number"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              />
            </div>

            {/* Email ID */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Email ID
              </label>
              <input
                type="email"
                value={formData.email}
                onChange={(e) => handleInputChange('email', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter email"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              />
            </div>

            {/* Password */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Password
              </label>
              <div className="relative">
                <input
                  type={obscurePassword ? 'password' : 'text'}
                  value={formData.password}
                  onChange={(e) => handleInputChange('password', e.target.value)}
                  disabled={isFormLocked}
                  placeholder="Enter new password (optional)"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed pr-12"
                />
                <button
                  type="button"
                  onClick={() => setObscurePassword(!obscurePassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500"
                >
                  {obscurePassword ? '👁️' : '👁️‍🗨️'}
                </button>
              </div>
            </div>

            {/* Confirm Password */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Confirm Password
              </label>
              <div className="relative">
                <input
                  type={obscureConfirmPassword ? 'password' : 'text'}
                  value={formData.confirmPassword}
                  onChange={(e) =>
                    handleInputChange('confirmPassword', e.target.value)
                  }
                  disabled={isFormLocked}
                  placeholder="Confirm new password"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed pr-12"
                />
                <button
                  type="button"
                  onClick={() =>
                    setObscureConfirmPassword(!obscureConfirmPassword)
                  }
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500"
                >
                  {obscureConfirmPassword ? '👁️' : '👁️‍🗨️'}
                </button>
              </div>
            </div>

            {/* Save Button (only if not locked) */}
            {!isFormLocked && (
              <button
                type="submit"
                className="w-full h-12 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors"
              >
                Save Personal Details
              </button>
            )}
          </div>
        </form>

        {/* Demographic Details Section (Always Editable) */}
        <div className="bg-white rounded-2xl shadow-lg p-6 mb-8">
          <h3 className="text-xl font-bold text-gray-800 mb-6">
            Demographic Details
          </h3>

          {/* Religion */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Religion
            </label>
            <input
              type="text"
              value={demographicData.religion}
              onChange={(e) => handleDemographicChange('religion', e.target.value)}
              placeholder="Enter religion"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          {/* Social Category */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Social Category
            </label>
            <select
              value={demographicData.socialCategory}
              onChange={(e) =>
                handleDemographicChange('socialCategory', e.target.value)
              }
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">Select category</option>
              {socialCategories.map((category) => (
                <option key={category} value={category}>
                  {category}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Next Button */}
        <button
          type="button"
          onClick={handleNext}
          className="w-full h-12 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors"
        >
          Next &gt;
        </button>
      </div>
    </div>
  );
};

export default PersonalDetailsForm;
    fullName: '',
    email: '',
    phoneNumber: '',
    state: '',
    district: '',
    block: '',
    city: '',
    aadhaarNumber: '',
    streetName: '',
    educationalQualification: '',
    religion: '',
    socialCategory: '',
    password: '',
    confirmPassword: '',
  });

  const [obscurePassword, setObscurePassword] = useState(true);
  const [obscureConfirmPassword, setObscureConfirmPassword] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [isFormLocked, setIsFormLocked] = useState(false);
  const [saveStatus, setSaveStatus] = useState<'idle' | 'saving' | 'saved'>('idle');

  const socialCategories = ['Christian SC', 'ST', 'Christian ST', 'Other'];

  // Load member data from backend
  const loadMemberFromBackend = async () => {
    try {
      const email = userData.email || userData.registrationForm?.email;
      if (!email) return userData;

      const response = await ApiService.getMemberByEmail(email);
      if (response.success && response.data) {
        const member = response.data;
        return {
          email,
          memberId: member.memberId || member.id || member._id,
          registrationForm: {
            fullName: member.fullName || '',
            phoneNumber: member.phoneNumber || '',
            email: member.email || '',
            state: member.state || '',
            district: member.district || '',
            block: member.block || '',
            city: member.city || '',
            aadhaarNumber: member.aadhaarNumber || '',
            streetName: member.streetName || '',
            educationalQualification: member.educationalQualification || '',
            religion: member.religion || '',
            socialCategory: member.socialCategory || '',
          },
        };
      }
      return userData;
    } catch (error) {
      console.error('Error loading member data:', error);
      return userData;
    }
  };

  // Check if form is already locked
  const checkIfFormIsLocked = async () => {
    try {
      const memberData = await loadMemberFromBackend();
      const regForm = memberData.registrationForm;

      const hasAadhaar = regForm?.aadhaarNumber?.trim().length > 0;
      const hasStreet = regForm?.streetName?.trim().length > 0;
      const hasEducation = regForm?.educationalQualification?.trim().length > 0;

      if (hasAadhaar || hasStreet || hasEducation) {
        setIsFormLocked(true);
        console.log('🔒 Personal details form is locked (already saved)');
      }
    } catch (error) {
      console.error('Error checking form lock status:', error);
    }
  };

  // Populate fields from userData
  useEffect(() => {
    const regForm = userData.registrationForm;
    const member = userData;

    setFormData({
      fullName: regForm?.fullName || member.fullName || '',
      email: member.email || regForm?.email || '',
      phoneNumber: regForm?.phoneNumber || member.phoneNumber || '',
      state: regForm?.state || member.state || '',
      district: regForm?.district || member.district || '',
      block: regForm?.block || member.block || '',
      city: regForm?.city || member.city || '',
      aadhaarNumber: regForm?.aadhaarNumber || '',
      streetName: regForm?.streetName || '',
      educationalQualification: regForm?.educationalQualification || '',
      religion: regForm?.religion || '',
      socialCategory: regForm?.socialCategory || '',
      password: '',
      confirmPassword: '',
    });

    checkIfFormIsLocked();
  }, [userData]);

  // Auto-save function with debounce
  const autoSaveData = useCallback(
    debounce(async () => {
      if (isSaving) return;

      setIsSaving(true);
      setSaveStatus('saving');

      try {
        let memberId = userData.memberId;

        // Try to get member ID from backend if not available
        if (!memberId) {
          const email = userData.email;
          if (email) {
            const response = await ApiService.getMemberByEmail(email);
            if (response.success && response.data) {
              memberId = response.data.memberId || response.data.id || response.data._id;
            }
          }
        }

        if (!memberId) {
          console.warn('Auto-save skipped: Member ID not found');
          return;
        }

        // Prepare update data
        const updateData = {
          fullName: formData.fullName.trim(),
          email: formData.email.trim(),
          phoneNumber: formData.phoneNumber.trim(),
          state: formData.state.trim(),
          district: formData.district.trim(),
          block: formData.block.trim(),
          city: formData.city.trim(),
          aadhaarNumber: formData.aadhaarNumber.trim(),
          streetName: formData.streetName.trim(),
          educationalQualification: formData.educationalQualification.trim(),
          religion: formData.religion.trim(),
          socialCategory: formData.socialCategory,
        };

        // Save to backend
        await ApiService.updateMemberDetails(memberId, updateData);
        setSaveStatus('saved');
        setTimeout(() => setSaveStatus('idle'), 2000);
      } catch (error) {
        console.error('Auto-save error:', error);
      } finally {
        setIsSaving(false);
      }
    }, 2000),
    [formData, userData, isSaving]
  );

  // Handle input changes
  const handleInputChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
    autoSaveData();
  };

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validate passwords if provided
    if (formData.password || formData.confirmPassword) {
      if (formData.password !== formData.confirmPassword) {
        alert('Passwords do not match');
        return;
      }
    }

    try {
      let memberId = userData.memberId;

      if (!memberId) {
        const response = await ApiService.getMemberByEmail(userData.email || '');
        if (response.success && response.data) {
          memberId = response.data.memberId || response.data.id || response.data._id;
        }
      }

      if (!memberId) {
        console.error('Member ID not found');
        return;
      }

      const updateData: any = {
        fullName: formData.fullName,
        email: formData.email,
        phoneNumber: formData.phoneNumber,
        state: formData.state,
        district: formData.district,
        block: formData.block,
        city: formData.city,
        aadhaarNumber: formData.aadhaarNumber,
        streetName: formData.streetName,
        educationalQualification: formData.educationalQualification,
        religion: formData.religion,
        socialCategory: formData.socialCategory,
      };

      if (formData.password) {
        updateData.password = formData.password;
      }

      const response = await ApiService.updateMemberDetails(memberId, updateData);

      if (response.success) {
        setFormData((prev) => ({ ...prev, password: '', confirmPassword: '' }));
        setIsFormLocked(true);
        alert('Personal details saved successfully. Form is now locked.');
      }
    } catch (error) {
      console.error('Error saving personal details:', error);
      alert('Error saving personal details');
    }
  };

  // Navigate to next step
  const handleNext = () => {
    navigate('/business-information', { state: { userData } });
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-100 to-purple-100">
      {/* Header */}
      <div className="bg-blue-600 text-white py-4 text-center">
        <h1 className="text-2xl font-bold">ACTIV</h1>
      </div>

      <div className="max-w-4xl mx-auto px-5 py-8">
        {/* Title */}
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold text-gray-800 mb-2">
            Additional Details Form
          </h2>
          <p className="text-gray-600">Member Registration</p>
        </div>

        {/* Progress Indicator */}
        <div className="flex justify-center items-center mb-8">
          {[1, 2, 3, 4].map((step, index) => (
            <div key={step} className="flex items-center">
              <div
                className={`w-10 h-10 rounded-full flex items-center justify-center font-bold ${
                  step <= 1
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-300 text-gray-600'
                }`}
              >
                {step}
              </div>
              {index < 3 && (
                <div className="w-10 h-0.5 bg-gray-300 mx-1"></div>
              )}
            </div>
          ))}
        </div>
        <p className="text-center text-gray-600 mb-8">Step 1 of 4</p>

        {/* Auto-save indicator */}
        {saveStatus !== 'idle' && (
          <div className="mb-4 text-center">
            <span
              className={`text-sm ${
                saveStatus === 'saving' ? 'text-blue-600' : 'text-green-600'
              }`}
            >
              {saveStatus === 'saving' ? '💾 Saving...' : '✓ Saved'}
            </span>
          </div>
        )}

        {/* Form Locked Message */}
        {isFormLocked && (
          <div className="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <div className="flex items-center">
              <span className="text-2xl mr-3">🔒</span>
              <div>
                <p className="font-semibold text-yellow-800">Form Locked</p>
                <p className="text-sm text-yellow-700">
                  Personal details have been saved and cannot be edited. Contact
                  support if you need to make changes.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Form Container */}
        <form onSubmit={handleSubmit}>
          <div className="bg-white rounded-2xl shadow-lg p-6 mb-8">
            <h3 className="text-xl font-bold text-gray-800 mb-6">
              Personal Information
            </h3>

            {/* Full Name */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Full Name *
              </label>
              <input
                type="text"
                value={formData.fullName}
                onChange={(e) => handleInputChange('fullName', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter your full name"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
                required
              />
            </div>

            {/* Email */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Email *
              </label>
              <input
                type="email"
                value={formData.email}
                onChange={(e) => handleInputChange('email', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter your email"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
                required
              />
            </div>

            {/* Phone Number */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Phone Number *
              </label>
              <input
                type="tel"
                value={formData.phoneNumber}
                onChange={(e) => handleInputChange('phoneNumber', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter your phone number"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
                required
              />
            </div>

            {/* State */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                State *
              </label>
              <input
                type="text"
                value={formData.state}
                onChange={(e) => handleInputChange('state', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter your state"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
                required
              />
            </div>

            {/* District */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                District *
              </label>
              <input
                type="text"
                value={formData.district}
                onChange={(e) => handleInputChange('district', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter your district"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
                required
              />
            </div>

            {/* Block */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Block *
              </label>
              <input
                type="text"
                value={formData.block}
                onChange={(e) => handleInputChange('block', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter your block"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
                required
              />
            </div>

            {/* City */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                City
              </label>
              <input
                type="text"
                value={formData.city}
                onChange={(e) => handleInputChange('city', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter your city"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              />
            </div>

            {/* Aadhaar Number */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Aadhaar Number *
              </label>
              <input
                type="text"
                value={formData.aadhaarNumber}
                onChange={(e) => handleInputChange('aadhaarNumber', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter 12-digit Aadhaar number"
                maxLength={12}
                pattern="[0-9]{12}"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
                required
              />
              <p className="text-xs text-gray-500 mt-1">12 digits only</p>
            </div>

            {/* Street Name */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Street Name / Address
              </label>
              <input
                type="text"
                value={formData.streetName}
                onChange={(e) => handleInputChange('streetName', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter your street name or address"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              />
            </div>

            {/* Educational Qualification */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Educational Qualification
              </label>
              <input
                type="text"
                value={formData.educationalQualification}
                onChange={(e) =>
                  handleInputChange('educationalQualification', e.target.value)
                }
                disabled={isFormLocked}
                placeholder="Enter your educational qualification"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              />
            </div>

            {/* Religion */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Religion
              </label>
              <input
                type="text"
                value={formData.religion}
                onChange={(e) => handleInputChange('religion', e.target.value)}
                disabled={isFormLocked}
                placeholder="Enter your religion"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              />
            </div>

            {/* Social Category */}
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Social Category
              </label>
              <select
                value={formData.socialCategory}
                onChange={(e) =>
                  handleInputChange('socialCategory', e.target.value)
                }
                disabled={isFormLocked}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              >
                <option value="">Select social category</option>
                {socialCategories.map((category) => (
                  <option key={category} value={category}>
                    {category}
                  </option>
                ))}
              </select>
            </div>

            {/* Password Section */}
            <div className="mt-8 pt-6 border-t border-gray-200">
              <h4 className="text-lg font-semibold text-gray-800 mb-4">
                Change Password (Optional)
              </h4>

              {/* Password */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  New Password
                </label>
                <div className="relative">
                  <input
                    type={obscurePassword ? 'password' : 'text'}
                    value={formData.password}
                    onChange={(e) => handleInputChange('password', e.target.value)}
                    disabled={isFormLocked}
                    placeholder="Enter new password (optional)"
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed pr-12"
                  />
                  <button
                    type="button"
                    onClick={() => setObscurePassword(!obscurePassword)}
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500"
                  >
                    {obscurePassword ? '👁️' : '👁️‍🗨️'}
                  </button>
                </div>
              </div>

              {/* Confirm Password */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Confirm New Password
                </label>
                <div className="relative">
                  <input
                    type={obscureConfirmPassword ? 'password' : 'text'}
                    value={formData.confirmPassword}
                    onChange={(e) =>
                      handleInputChange('confirmPassword', e.target.value)
                    }
                    disabled={isFormLocked}
                    placeholder="Confirm new password"
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100 disabled:cursor-not-allowed pr-12"
                  />
                  <button
                    type="button"
                    onClick={() =>
                      setObscureConfirmPassword(!obscureConfirmPassword)
                    }
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500"
                  >
                    {obscureConfirmPassword ? '👁️' : '👁️‍🗨️'}
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Navigation Buttons */}
          <div className="flex gap-4">
            <button
              type="button"
              onClick={() => navigate(-1)}
              className="flex-1 h-12 border-2 border-purple-600 text-purple-600 rounded-lg font-semibold hover:bg-purple-50 transition-colors"
            >
              Previous
            </button>
            <button
              type="button"
              onClick={handleNext}
              className="flex-1 h-12 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors"
            >
              Next &gt;
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default PersonalDetailsForm;
```

---

## 2. Business Information Form (Step 2 of 4)

### BusinessInformationForm.tsx

```tsx
import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { debounce } from 'lodash';
import { ApiService } from '../../services/ApiService';

interface UserData {
  email?: string;
  memberId?: string;
  registrationForm?: {
    doingBusiness?: boolean;
    organizationName?: string;
    constitutionType?: string;
    businessTypes?: string[];
    businessActivities?: string;
    businessCommencementYear?: string;
    numberOfEmployees?: string;
    memberOfOtherChamber?: boolean;
    otherChamber?: string;
    govtOrganizations?: string[];
  };
}

interface BusinessInformationFormProps {}

const BusinessInformationForm: React.FC<BusinessInformationFormProps> = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const userData = (location.state as any)?.userData || {};

  // Form State
  const [doingBusiness, setDoingBusiness] = useState<boolean | null>(null);
  const [organizationName, setOrganizationName] = useState('');
  const [selectedConstitution, setSelectedConstitution] = useState('');
  const [selectedBusinessTypes, setSelectedBusinessTypes] = useState<Set<string>>(
    new Set()
  );
  const [businessActivities, setBusinessActivities] = useState('');
  const [selectedYear, setSelectedYear] = useState('');
  const [numberOfEmployees, setNumberOfEmployees] = useState('');
  const [memberOfOtherChamber, setMemberOfOtherChamber] = useState<boolean | null>(
    null
  );
  const [otherChamber, setOtherChamber] = useState('');
  const [selectedGovtOrganizations, setSelectedGovtOrganizations] = useState<
    Set<string>
  >(new Set());

  const [isSaving, setIsSaving] = useState(false);
  const [saveStatus, setSaveStatus] = useState<'idle' | 'saving' | 'saved'>('idle');

  // Constants
  const constitutionTypes = ['OPC', 'TRUST', 'SOCIETY'];
  const years = Array.from({ length: 50 }, (_, i) => (2024 - i).toString());
  const businessTypes = ['Manufacturing', 'Trader', 'Service Provider', 'Others'];
  const govtOrganizations = ['MSME', 'KVIC', 'NABARD', 'None', 'Others'];

  // Populate fields from userData
  useEffect(() => {
    const regForm = userData.registrationForm;
    if (regForm) {
      setDoingBusiness(regForm.doingBusiness ?? null);
      setOrganizationName(regForm.organizationName || '');
      setSelectedConstitution(regForm.constitutionType || '');
      setBusinessActivities(regForm.businessActivities || '');
      setSelectedYear(regForm.businessCommencementYear || '');
      setNumberOfEmployees(regForm.numberOfEmployees || '');
      setMemberOfOtherChamber(regForm.memberOfOtherChamber ?? null);
      setOtherChamber(regForm.otherChamber || '');

      if (regForm.businessTypes) {
        setSelectedBusinessTypes(new Set(regForm.businessTypes));
      }
      if (regForm.govtOrganizations) {
        setSelectedGovtOrganizations(new Set(regForm.govtOrganizations));
      }
    }
  }, [userData]);

  // Auto-save function with debounce
  const autoSaveData = useCallback(
    debounce(async () => {
      if (isSaving) return;

      setIsSaving(true);
      setSaveStatus('saving');

      try {
        let memberId = userData.memberId;

        if (!memberId) {
          const email = userData.email;
          if (email) {
            const response = await ApiService.getMemberByEmail(email);
            if (response.success && response.data) {
              memberId = response.data.memberId || response.data.id || response.data._id;
            }
          }
        }

        if (!memberId) {
          console.warn('Auto-save skipped: Member ID not found');
          return;
        }

        const businessData = {
          doingBusiness,
          organizationName: organizationName.trim(),
          constitutionType: selectedConstitution,
          businessTypes: Array.from(selectedBusinessTypes),
          businessActivities: businessActivities.trim(),
          businessCommencementYear: selectedYear,
          numberOfEmployees: numberOfEmployees.trim(),
          memberOfOtherChamber,
          otherChamber: otherChamber.trim(),
          govtOrganizations: Array.from(selectedGovtOrganizations),
        };

        await ApiService.saveBusinessInfo(memberId, businessData);
        setSaveStatus('saved');
        setTimeout(() => setSaveStatus('idle'), 2000);
      } catch (error) {
        console.error('Auto-save error:', error);
      } finally {
        setIsSaving(false);
      }
    }, 2000),
    [
      doingBusiness,
      organizationName,
      selectedConstitution,
      selectedBusinessTypes,
      businessActivities,
      selectedYear,
      numberOfEmployees,
      memberOfOtherChamber,
      otherChamber,
      selectedGovtOrganizations,
      userData,
      isSaving,
    ]
  );

  // Trigger auto-save on field changes
  useEffect(() => {
    autoSaveData();
  }, [
    doingBusiness,
    organizationName,
    selectedConstitution,
    selectedBusinessTypes,
    businessActivities,
    selectedYear,
    numberOfEmployees,
    memberOfOtherChamber,
    otherChamber,
    selectedGovtOrganizations,
  ]);

  // Handle checkbox toggle
  const toggleBusinessType = (type: string) => {
    setSelectedBusinessTypes((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(type)) {
        newSet.delete(type);
      } else {
        newSet.add(type);
      }
      return newSet;
    });
  };

  const toggleGovtOrganization = (org: string) => {
    setSelectedGovtOrganizations((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(org)) {
        newSet.delete(org);
      } else {
        newSet.add(org);
      }
      return newSet;
    });
  };

  // Handle navigation
  const handlePrevious = () => {
    navigate('/personal-details', { state: { userData } });
  };

  const handleNext = () => {
    if (doingBusiness === false) {
      // Aspirant - Submit application directly
      handleAspirantSubmit();
    } else {
      // Company member - Continue to financial form
      navigate('/financial-compliance', { state: { userData } });
    }
  };

  const handleAspirantSubmit = async () => {
    try {
      // Submit as Aspirant (no business)
      const applicationData = {
        ...userData,
        registrationForm: {
          ...userData.registrationForm,
          doingBusiness: false,
          memberType: 'ASPIRANT',
        },
      };

      // Call application submission API
      await ApiService.submitApplication(applicationData);

      // Navigate to success screen
      navigate('/application-submitted', { state: { memberType: 'ASPIRANT' } });
    } catch (error) {
      console.error('Error submitting aspirant application:', error);
      alert('Error submitting application. Please try again.');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-100 to-purple-100">
      {/* Header */}
      <div className="bg-blue-600 text-white py-4 text-center">
        <h1 className="text-2xl font-bold">ACTIV</h1>
      </div>

      <div className="max-w-4xl mx-auto px-5 py-8">
        {/* Title */}
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold text-gray-800 mb-2">
            Additional Details Form
          </h2>
          <p className="text-gray-600">Member Registration</p>
        </div>

        {/* Progress Indicator */}
        <div className="flex justify-center items-center mb-8">
          {[1, 2, 3, 4].map((step, index) => (
            <div key={step} className="flex items-center">
              <div
                className={`w-10 h-10 rounded-full flex items-center justify-center font-bold ${
                  step <= 2
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-300 text-gray-600'
                }`}
              >
                {step}
              </div>
              {index < 3 && (
                <div className="w-10 h-0.5 bg-gray-300 mx-1"></div>
              )}
            </div>
          ))}
        </div>
        <p className="text-center text-gray-600 mb-8">Step 2 of 4</p>

        {/* Auto-save indicator */}
        {saveStatus !== 'idle' && (
          <div className="mb-4 text-center">
            <span
              className={`text-sm ${
                saveStatus === 'saving' ? 'text-blue-600' : 'text-green-600'
              }`}
            >
              {saveStatus === 'saving' ? '💾 Saving...' : '✓ Saved'}
            </span>
          </div>
        )}

        {/* Form Container */}
        <div className="bg-white rounded-2xl shadow-lg p-6 mb-8">
          <h3 className="text-xl font-bold text-gray-800 text-center mb-6">
            Business Information
          </h3>

          {/* Doing Business */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-3">
              Doing Business *
            </label>
            <div className="flex gap-4">
              <button
                type="button"
                onClick={() => setDoingBusiness(true)}
                className={`flex-1 py-3 px-4 rounded-lg border-2 font-medium transition-colors ${
                  doingBusiness === true
                    ? 'bg-blue-600 text-white border-blue-600'
                    : 'bg-white text-gray-700 border-gray-300 hover:border-blue-400'
                }`}
              >
                Yes
              </button>
              <button
                type="button"
                onClick={() => setDoingBusiness(false)}
                className={`flex-1 py-3 px-4 rounded-lg border-2 font-medium transition-colors ${
                  doingBusiness === false
                    ? 'bg-blue-600 text-white border-blue-600'
                    : 'bg-white text-gray-700 border-gray-300 hover:border-blue-400'
                }`}
              >
                No
              </button>
            </div>
          </div>

          {/* Show business fields only if doing business */}
          {doingBusiness === true && (
            <>
              {/* Organization Name */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Name of the Organization *
                </label>
                <input
                  type="text"
                  value={organizationName}
                  onChange={(e) => setOrganizationName(e.target.value)}
                  placeholder="Enter organization name"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>

              {/* Constitution Type */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Constitution of the Company *
                </label>
                <select
                  value={selectedConstitution}
                  onChange={(e) => setSelectedConstitution(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select constitution type</option>
                  {constitutionTypes.map((type) => (
                    <option key={type} value={type}>
                      {type}
                    </option>
                  ))}
                </select>
              </div>

              {/* Business Types */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-3">
                  Type of Business
                </label>
                <div className="space-y-2">
                  {businessTypes.map((type) => (
                    <label
                      key={type}
                      className="flex items-center p-3 border border-gray-300 rounded-lg hover:bg-gray-50 cursor-pointer"
                    >
                      <input
                        type="checkbox"
                        checked={selectedBusinessTypes.has(type)}
                        onChange={() => toggleBusinessType(type)}
                        className="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                      />
                      <span className="ml-3 text-gray-700">{type}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Business Activities */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Business Activities
                </label>
                <textarea
                  value={businessActivities}
                  onChange={(e) => setBusinessActivities(e.target.value)}
                  placeholder="Enter business activities"
                  rows={3}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>

              {/* Commencement Year */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Business Commencement Year
                </label>
                <select
                  value={selectedYear}
                  onChange={(e) => setSelectedYear(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select year</option>
                  {years.map((year) => (
                    <option key={year} value={year}>
                      {year}
                    </option>
                  ))}
                </select>
              </div>

              {/* Number of Employees */}
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Number of Employees
                </label>
                <input
                  type="text"
                  value={numberOfEmployees}
                  onChange={(e) => setNumberOfEmployees(e.target.value)}
                  placeholder="Enter number of employees"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
            </>
          )}

          {/* Member of other Chamber */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-3">
              Member of any other Chamber/Association
            </label>
            <div className="flex gap-4">
              <button
                type="button"
                onClick={() => setMemberOfOtherChamber(true)}
                className={`flex-1 py-3 px-4 rounded-lg border-2 font-medium transition-colors ${
                  memberOfOtherChamber === true
                    ? 'bg-blue-600 text-white border-blue-600'
                    : 'bg-white text-gray-700 border-gray-300 hover:border-blue-400'
                }`}
              >
                Yes
              </button>
              <button
                type="button"
                onClick={() => setMemberOfOtherChamber(false)}
                className={`flex-1 py-3 px-4 rounded-lg border-2 font-medium transition-colors ${
                  memberOfOtherChamber === false
                    ? 'bg-blue-600 text-white border-blue-600'
                    : 'bg-white text-gray-700 border-gray-300 hover:border-blue-400'
                }`}
              >
                No
              </button>
            </div>
          </div>

          {memberOfOtherChamber === true && (
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Name of Chamber/Association
              </label>
              <input
                type="text"
                value={otherChamber}
                onChange={(e) => setOtherChamber(e.target.value)}
                placeholder="Enter chamber/association name"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          )}

          {/* Government Organizations */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-3">
              Registered with Govt. Organization
            </label>
            <div className="space-y-2">
              {govtOrganizations.map((org) => (
                <label
                  key={org}
                  className="flex items-center p-3 border border-gray-300 rounded-lg hover:bg-gray-50 cursor-pointer"
                >
                  <input
                    type="checkbox"
                    checked={selectedGovtOrganizations.has(org)}
                    onChange={() => toggleGovtOrganization(org)}
                    className="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                  />
                  <span className="ml-3 text-gray-700">{org}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Aspirant Summary */}
          {doingBusiness === false && (
            <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex items-start">
                <span className="text-2xl mr-3">🎓</span>
                <div>
                  <p className="font-semibold text-blue-900 mb-1">
                    Registering as Aspirant
                  </p>
                  <p className="text-sm text-blue-700">
                    You are registering as an Aspirant (Student / Non-business
                    member). Steps 3 and 4 are not required.
                  </p>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Navigation Buttons */}
        <div className="flex gap-4">
          <button
            type="button"
            onClick={handlePrevious}
            className="flex-1 h-12 border-2 border-purple-600 text-purple-600 rounded-lg font-semibold hover:bg-purple-50 transition-colors"
          >
            Previous
          </button>
          <button
            type="button"
            onClick={handleNext}
            className="flex-1 h-12 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors"
          >
            {doingBusiness === false ? '✓ Submit' : 'Next >'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default BusinessInformationForm;
```

---

## Key Features Implemented

### Common Features (Both Forms)

1. **Auto-save Functionality**
   - Debounced auto-save (2 seconds after typing stops)
   - Visual indicator for save status
   - Automatic member ID resolution

2. **Responsive Design**
   - Mobile-first approach with Tailwind CSS
   - Clean, modern UI matching Flutter design
   - Gradient backgrounds
   - Shadow effects and rounded corners

3. **Form Validation**
   - Required field validation
   - Pattern matching (Aadhaar: 12 digits)
   - Password confirmation
   - Real-time feedback

4. **Navigation**
   - Progress indicator (4 steps)
   - Previous/Next buttons
   - React Router for navigation
   - State passing between routes

5. **API Integration**
   - `ApiService` for backend calls
   - Member data loading by email
   - Auto-save to backend
   - Error handling

### Personal Details Form Specific

- Form lock after successful save
- Password change functionality
- Toggle password visibility
- Social category dropdown
- Aadhaar validation (12 digits)

### Business Information Form Specific

- Conditional form fields (show/hide based on "Doing Business")
- Checkbox groups for multiple selections
- Business types multi-select
- Government organizations multi-select
- Aspirant vs Company member flow
- Direct submission for Aspirant members

---

## Installation & Usage

### Prerequisites

```bash
npm install react react-dom react-router-dom
npm install -D typescript @types/react @types/react-dom
npm install lodash
npm install -D @types/lodash
npm install tailwindcss
```

### API Service Example

```typescript
// services/ApiService.ts
export class ApiService {
  static baseUrl = 'http://10.42.208.174:3000/api';

  static async getMemberByEmail(email: string) {
    const response = await fetch(`${this.baseUrl}/members/email/${email}`);
    return response.json();
  }

  static async updateMemberDetails(memberId: string, data: any) {
    const response = await fetch(`${this.baseUrl}/members/${memberId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return response.json();
  }

  static async saveBusinessInfo(memberId: string, data: any) {
    const response = await fetch(`${this.baseUrl}/business/${memberId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return response.json();
  }

  static async submitApplication(data: any) {
    const response = await fetch(`${this.baseUrl}/applications/submit`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return response.json();
  }
}
```

### Router Setup

```typescript
// App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import PersonalDetailsForm from './screens/PersonalDetailsForm';
import BusinessInformationForm from './screens/BusinessInformationForm';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/personal-details" element={<PersonalDetailsForm userData={{}} />} />
        <Route path="/business-information" element={<BusinessInformationForm />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
```

---

## Differences from Flutter Implementation

1. **State Management**: Uses React hooks instead of StatefulWidget
2. **Navigation**: React Router instead of Navigator.push
3. **Styling**: Tailwind CSS instead of Flutter widgets
4. **Debouncing**: lodash.debounce instead of Timer
5. **Form Handling**: Controlled components instead of TextEditingController

---

## Next Steps

To complete the conversion, you would need:

3. **Financial Compliance Form** (Step 3)
4. **Declaration Form** (Step 4)

---

## 3. Financial Compliance Form (Step 3 of 4)

### FinancialComplianceForm.tsx

```tsx
import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { debounce } from 'lodash';
import { ApiService } from '../../services/ApiService';

interface UserData {
  email?: string;
  memberId?: string;
  registrationForm?: {
    panNumber?: string;
    gstNumber?: string;
    udyamNumber?: string;
    filedITR?: boolean;
    itrYears?: string;
    turnoverRange?: string;
    turnover?: string;
    fy2021?: string;
    fy2020?: string;
    fy2019?: string;
    govtSchemeBenefit?: boolean;
    scheme1?: string;
    scheme2?: string;
    scheme3?: string;
  };
}

interface FinancialComplianceFormProps {}

const FinancialComplianceForm: React.FC<FinancialComplianceFormProps> = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const userData = (location.state as any)?.userData || {};

  // Form State
  const [formData, setFormData] = useState({
    panNumber: '',
    gstNumber: '',
    udyamNumber: '',
    itrYears: '',
    turnover: '',
    fy2021: '',
    fy2020: '',
    fy2019: '',
    scheme1: '',
    scheme2: '',
    scheme3: '',
  });

  const [filedITR, setFiledITR] = useState<boolean | null>(null);
  const [govtSchemeBenefit, setGovtSchemeBenefit] = useState<boolean | null>(null);
  const [selectedTurnoverRange, setSelectedTurnoverRange] = useState<string>('');
  const [isSaving, setIsSaving] = useState(false);
  const [saveStatus, setSaveStatus] = useState<'idle' | 'saving' | 'saved'>('idle');

  const turnoverRanges = [
    'Less than 25 Lakhs',
    '25 Lakhs - 50 Lakhs',
    '50 Lakhs - 1 Crore',
    '1 Crore - 5 Crores',
    '5 Crores - 10 Crores',
    'More than 10 Crores',
  ];

  // Validation helpers
  const isValidPan = (input: string): boolean => {
    const value = input.trim().toUpperCase();
    return /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(value);
  };

  const isValidGst = (input: string): boolean => {
    const value = input.trim().toUpperCase();
    return /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/.test(value);
  };

  // Populate fields from userData
  useEffect(() => {
    const regForm = userData.registrationForm;
    if (regForm) {
      setFormData({
        panNumber: regForm.panNumber || '',
        gstNumber: regForm.gstNumber || '',
        udyamNumber: regForm.udyamNumber || '',
        itrYears: regForm.itrYears || '',
        turnover: regForm.turnover || '',
        fy2021: regForm.fy2021 || '',
        fy2020: regForm.fy2020 || '',
        fy2019: regForm.fy2019 || '',
        scheme1: regForm.scheme1 || '',
        scheme2: regForm.scheme2 || '',
        scheme3: regForm.scheme3 || '',
      });
      setFiledITR(regForm.filedITR ?? null);
      setGovtSchemeBenefit(regForm.govtSchemeBenefit ?? null);
      setSelectedTurnoverRange(regForm.turnoverRange || '');
    }
  }, [userData]);

  // Auto-save function with debounce
  const autoSaveData = useCallback(
    debounce(async () => {
      if (isSaving) return;

      setIsSaving(true);
      setSaveStatus('saving');

      try {
        let memberId = userData.memberId;

        if (!memberId) {
          const email = userData.email;
          if (email) {
            const response = await ApiService.getMemberByEmail(email);
            if (response.success && response.data) {
              memberId = response.data.memberId || response.data.id || response.data._id;
            }
          }
        }

        if (!memberId) {
          console.warn('Auto-save skipped: Member ID not found');
          return;
        }

        const financialData = {
          panNumber: formData.panNumber.trim(),
          gstNumber: formData.gstNumber.trim(),
          udyamNumber: formData.udyamNumber.trim(),
          filedITR,
          itrYears: formData.itrYears.trim(),
          turnoverRange: selectedTurnoverRange,
          turnover: formData.turnover.trim(),
          fy2021: formData.fy2021.trim(),
          fy2020: formData.fy2020.trim(),
          fy2019: formData.fy2019.trim(),
          govtSchemeBenefit,
          scheme1: formData.scheme1.trim(),
          scheme2: formData.scheme2.trim(),
          scheme3: formData.scheme3.trim(),
        };

        await ApiService.saveFinancialInfo(memberId, financialData);
        setSaveStatus('saved');
        setTimeout(() => setSaveStatus('idle'), 2000);
      } catch (error) {
        console.error('Auto-save error:', error);
      } finally {
        setIsSaving(false);
      }
    }, 2000),
    [formData, filedITR, govtSchemeBenefit, selectedTurnoverRange, userData, isSaving]
  );

  // Trigger auto-save on field changes
  useEffect(() => {
    autoSaveData();
  }, [
    formData,
    filedITR,
    govtSchemeBenefit,
    selectedTurnoverRange,
  ]);

  // Handle input changes
  const handleInputChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  // Handle navigation
  const handlePrevious = () => {
    navigate('/business-information', { state: { userData } });
  };

  const handleNext = async () => {
    // Optional PAN/GST validation
    const pan = formData.panNumber.trim().toUpperCase();
    if (pan && !isValidPan(pan)) {
      alert('Invalid PAN format. Example: ABCDE1234F');
      return;
    }

    const gst = formData.gstNumber.trim().toUpperCase();
    if (gst && !isValidGst(gst)) {
      alert('Invalid GST format. Must be 15 characters (##ABCDE1234F1Z5)');
      return;
    }

    // Save to backend before navigating
    try {
      let memberId = userData.memberId;

      if (!memberId) {
        const response = await ApiService.getMemberByEmail(userData.email || '');
        if (response.success && response.data) {
          memberId = response.data.memberId || response.data.id || response.data._id;
        }
      }

      if (memberId) {
        const financialData = {
          panNumber: pan,
          gstNumber: gst,
          udyamNumber: formData.udyamNumber.trim(),
          filedITR,
          itrYears: filedITR ? formData.itrYears.trim() : '',
          turnoverRange: selectedTurnoverRange,
          fy2021: formData.fy2021.trim(),
          fy2020: formData.fy2020.trim(),
          fy2019: formData.fy2019.trim(),
          govtSchemeBenefit,
          scheme1: govtSchemeBenefit ? formData.scheme1.trim() : '',
          scheme2: govtSchemeBenefit ? formData.scheme2.trim() : '',
          scheme3: govtSchemeBenefit ? formData.scheme3.trim() : '',
        };

        await ApiService.saveFinancialInfo(memberId, financialData);
      }
    } catch (error) {
      console.error('Error saving financial info:', error);
    }

    // Update userData and navigate
    const updatedUserData = {
      ...userData,
      registrationForm: {
        ...userData.registrationForm,
        panNumber: pan,
        gstNumber: gst,
        udyamNumber: formData.udyamNumber.trim(),
        filedITR,
        itrYears: filedITR ? formData.itrYears.trim() : '',
        turnoverRange: selectedTurnoverRange,
        fy2021: formData.fy2021.trim(),
        fy2020: formData.fy2020.trim(),
        fy2019: formData.fy2019.trim(),
        govtSchemeBenefit,
        scheme1: govtSchemeBenefit ? formData.scheme1.trim() : '',
        scheme2: govtSchemeBenefit ? formData.scheme2.trim() : '',
        scheme3: govtSchemeBenefit ? formData.scheme3.trim() : '',
      },
    };

    navigate('/declaration', { state: { userData: updatedUserData } });
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-100 to-purple-100">
      {/* Header */}
      <div className="bg-blue-600 text-white py-4 text-center">
        <h1 className="text-2xl font-bold">ACTIV</h1>
      </div>

      <div className="max-w-4xl mx-auto px-5 py-8">
        {/* Title */}
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold text-gray-800 mb-2">
            Additional Details Form
          </h2>
          <p className="text-gray-600">Member Registration</p>
        </div>

        {/* Progress Indicator */}
        <div className="flex justify-center items-center mb-8">
          {[1, 2, 3, 4].map((step, index) => (
            <div key={step} className="flex items-center">
              <div
                className={`w-10 h-10 rounded-full flex items-center justify-center font-bold ${
                  step <= 3
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-300 text-gray-600'
                }`}
              >
                {step}
              </div>
              {index < 3 && (
                <div className="w-10 h-0.5 bg-gray-300 mx-1"></div>
              )}
            </div>
          ))}
        </div>
        <p className="text-center text-gray-600 mb-8">Step 3 of 4</p>

        {/* Auto-save indicator */}
        {saveStatus !== 'idle' && (
          <div className="mb-4 text-center">
            <span
              className={`text-sm ${
                saveStatus === 'saving' ? 'text-blue-600' : 'text-green-600'
              }`}
            >
              {saveStatus === 'saving' ? '💾 Saving...' : '✓ Saved'}
            </span>
          </div>
        )}

        {/* Form Container */}
        <div className="bg-white rounded-2xl shadow-lg p-6 mb-8">
          <h3 className="text-xl font-bold text-gray-800 mb-6">
            Financial & Compliance Information
          </h3>

          {/* PAN Number */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              PAN Number
            </label>
            <input
              type="text"
              value={formData.panNumber}
              onChange={(e) => handleInputChange('panNumber', e.target.value.toUpperCase())}
              placeholder="Enter PAN number"
              maxLength={10}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
            <p className="text-xs text-gray-500 mt-1">
              Validate PAN Number (10 chars alphanumeric, e.g., ABCDE1234F)
            </p>
          </div>

          {/* GST Number */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              GST Number
            </label>
            <input
              type="text"
              value={formData.gstNumber}
              onChange={(e) => handleInputChange('gstNumber', e.target.value.toUpperCase())}
              placeholder="Enter GST number"
              maxLength={15}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
            <p className="text-xs text-gray-500 mt-1">
              Validate GST Number (15 chars)
            </p>
          </div>

          {/* Udyam Number */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Udyam Number
            </label>
            <input
              type="text"
              value={formData.udyamNumber}
              onChange={(e) => handleInputChange('udyamNumber', e.target.value)}
              placeholder="Enter Udyam number"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
            <p className="text-xs text-gray-500 mt-1">Optional</p>
          </div>

          {/* Filed Income Tax Returns */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-3">
              Filed Income Tax Returns
            </label>
            <div className="flex gap-4">
              <button
                type="button"
                onClick={() => setFiledITR(true)}
                className={`flex-1 py-3 px-4 rounded-lg border-2 font-medium transition-colors ${
                  filedITR === true
                    ? 'bg-blue-600 text-white border-blue-600'
                    : 'bg-white text-gray-700 border-gray-300 hover:border-blue-400'
                }`}
              >
                Yes
              </button>
              <button
                type="button"
                onClick={() => setFiledITR(false)}
                className={`flex-1 py-3 px-4 rounded-lg border-2 font-medium transition-colors ${
                  filedITR === false
                    ? 'bg-blue-600 text-white border-blue-600'
                    : 'bg-white text-gray-700 border-gray-300 hover:border-blue-400'
                }`}
              >
                No
              </button>
            </div>
          </div>

          {/* ITR Years (conditional) */}
          {filedITR === true && (
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                How many continuous years have you filed ITR?
              </label>
              <input
                type="text"
                value={formData.itrYears}
                onChange={(e) => handleInputChange('itrYears', e.target.value)}
                placeholder="Enter number of years"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          )}

          {/* Turnover Range */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Turnover
            </label>
            <select
              value={selectedTurnoverRange}
              onChange={(e) => setSelectedTurnoverRange(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">Select turnover range</option>
              {turnoverRanges.map((range) => (
                <option key={range} value={range}>
                  {range}
                </option>
              ))}
            </select>
          </div>

          {/* Turnover for Last 3 FYs */}
          <h4 className="text-lg font-semibold text-gray-800 mb-4 mt-6">
            Turnover for Last 3 Financial Years
          </h4>

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              FY 2021-22
            </label>
            <input
              type="text"
              value={formData.fy2021}
              onChange={(e) => handleInputChange('fy2021', e.target.value)}
              placeholder="Enter turnover amount"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              FY 2020-21
            </label>
            <input
              type="text"
              value={formData.fy2020}
              onChange={(e) => handleInputChange('fy2020', e.target.value)}
              placeholder="Enter turnover amount"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              FY 2019-20
            </label>
            <input
              type="text"
              value={formData.fy2019}
              onChange={(e) => handleInputChange('fy2019', e.target.value)}
              placeholder="Enter turnover amount"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          {/* Government Schemes Benefit */}
          <div className="mb-6 mt-6">
            <label className="block text-sm font-medium text-gray-700 mb-3">
              Have you got benefited through any Govt. schemes in your Business?
            </label>
            <div className="flex gap-4">
              <button
                type="button"
                onClick={() => setGovtSchemeBenefit(true)}
                className={`flex-1 py-3 px-4 rounded-lg border-2 font-medium transition-colors ${
                  govtSchemeBenefit === true
                    ? 'bg-blue-600 text-white border-blue-600'
                    : 'bg-white text-gray-700 border-gray-300 hover:border-blue-400'
                }`}
              >
                Yes
              </button>
              <button
                type="button"
                onClick={() => setGovtSchemeBenefit(false)}
                className={`flex-1 py-3 px-4 rounded-lg border-2 font-medium transition-colors ${
                  govtSchemeBenefit === false
                    ? 'bg-blue-600 text-white border-blue-600'
                    : 'bg-white text-gray-700 border-gray-300 hover:border-blue-400'
                }`}
              >
                No
              </button>
            </div>
          </div>

          {/* Government Schemes (conditional) */}
          {govtSchemeBenefit === true && (
            <>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Scheme 1
                </label>
                <input
                  type="text"
                  value={formData.scheme1}
                  onChange={(e) => handleInputChange('scheme1', e.target.value)}
                  placeholder="Enter scheme name"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>

              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Scheme 2
                </label>
                <input
                  type="text"
                  value={formData.scheme2}
                  onChange={(e) => handleInputChange('scheme2', e.target.value)}
                  placeholder="Enter scheme name"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>

              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Scheme 3
                </label>
                <input
                  type="text"
                  value={formData.scheme3}
                  onChange={(e) => handleInputChange('scheme3', e.target.value)}
                  placeholder="Enter scheme name"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
            </>
          )}
        </div>

        {/* Navigation Buttons */}
        <div className="flex gap-4">
          <button
            type="button"
            onClick={handlePrevious}
            className="flex-1 h-12 border-2 border-purple-600 text-purple-600 rounded-lg font-semibold hover:bg-purple-50 transition-colors"
          >
            Previous
          </button>
          <button
            type="button"
            onClick={handleNext}
            className="flex-1 h-12 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors"
          >
            Next &gt;
          </button>
        </div>
      </div>
    </div>
  );
};

export default FinancialComplianceForm;
```

---

## 4. Declaration Form (Step 4 of 4)

### DeclarationForm.tsx

```tsx
import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { ApiService } from '../../services/ApiService';
import { ApplicationService } from '../../services/ApplicationService';
import { AuthService } from '../../services/AuthService';

interface UserData {
  email?: string;
  memberId?: string;
  userId?: string;
  fullName?: string;
  phone?: string;
  state?: string;
  district?: string;
  block?: string;
  registrationForm?: {
    sisterConcerns?: string;
    companyNames?: string;
    showOneFieldPerName?: boolean;
    agreeToDeclaration?: boolean;
  };
}

interface DeclarationFormProps {}

const DeclarationForm: React.FC<DeclarationFormProps> = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const userData = (location.state as any)?.userData || {};

  // Form State
  const [sisterConcerns, setSisterConcerns] = useState('');
  const [companyNames, setCompanyNames] = useState('');
  const [showOneFieldPerName, setShowOneFieldPerName] = useState(false);
  const [agreeToDeclaration, setAgreeToDeclaration] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  // Populate fields from userData
  useEffect(() => {
    const regForm = userData.registrationForm;
    if (regForm) {
      setSisterConcerns(regForm.sisterConcerns || '');
      setCompanyNames(regForm.companyNames || '');
      setShowOneFieldPerName(regForm.showOneFieldPerName || false);
      setAgreeToDeclaration(regForm.agreeToDeclaration || false);
    }
  }, [userData]);

  // Handle add another company
  const handleAddCompany = () => {
    setCompanyNames((prev) => prev + '\n');
  };

  // Handle form submission
  const handleSubmit = async () => {
    // Validate declaration agreement
    if (!agreeToDeclaration) {
      alert('Please agree to the declaration to submit your application');
      return;
    }

    // Optional validation: if sister concerns is filled, validate it's a positive integer
    if (sisterConcerns.trim() !== '') {
      const num = parseInt(sisterConcerns);
      if (isNaN(num) || num <= 0) {
        alert('Please enter a valid positive number for sister concerns');
        return;
      }
    }

    setSubmitting(true);

    try {
      // Get member ID
      let memberId = userData.memberId || userData.userId;

      if (!memberId) {
        const response = await ApiService.getMemberByEmail(userData.email || '');
        if (response.success && response.data) {
          memberId = response.data.memberId || response.data.id || response.data._id;
        }
      }

      if (!memberId) {
        throw new Error('Member ID not found');
      }

      // Get auth token
      const token = await AuthService.getToken();
      if (!token) {
        alert('Session expired. Please log in again.');
        return;
      }

      // Parse sister concerns
      const sisterConcernsNum = parseInt(sisterConcerns) || 0;

      // Parse company names into array
      const companyNamesArray = companyNames
        .split('\n')
        .map((name) => name.trim())
        .filter((name) => name.length > 0);

      // Save declaration to backend
      const declarationPayload = {
        sisterConcerns: sisterConcernsNum,
        companyNames: companyNamesArray,
        showOneFieldPerName,
        agreeToDeclaration,
        profileCompleted: true,
        submissionDate: new Date().toISOString(),
      };

      await ApiService.saveDeclaration(memberId, declarationPayload);

      // Submit application
      const applicationService = new ApplicationService(ApiService.baseUrl, token);

      const fullName =
        userData.fullName || userData.registrationForm?.fullName || '';
      const email = userData.email || '';
      const phone = userData.phone || userData.registrationForm?.phoneNumber || '';
      const state = userData.state || userData.registrationForm?.state || '';
      const district = userData.district || userData.registrationForm?.district || '';
      const block = userData.block || userData.registrationForm?.block || '';

      const result = await applicationService.submitApplication(
        memberId,
        fullName,
        email,
        phone,
        state,
        district,
        block,
        {
          sisterConcerns: sisterConcernsNum,
          companyNames: companyNamesArray,
          showOneFieldPerName,
          agreeToDeclaration,
          personalDetails: userData.registrationForm,
        }
      );

      if (result.success) {
        // Navigate to success screen
        navigate('/application-submitted', { state: { userData } });
      } else {
        alert(result.message || 'Failed to submit application');
      }
    } catch (error) {
      console.error('Error submitting application:', error);
      alert(`Failed to submit application: ${error}`);
    } finally {
      setSubmitting(false);
    }
  };

  // Handle navigation
  const handlePrevious = () => {
    navigate('/financial-compliance', { state: { userData } });
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-100 to-purple-100">
      {/* Header */}
      <div className="bg-blue-600 text-white py-4 text-center">
        <h1 className="text-2xl font-bold">ACTIV</h1>
      </div>

      <div className="max-w-4xl mx-auto px-5 py-8">
        {/* Title */}
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold text-gray-800 mb-2">
            Additional Details Form
          </h2>
          <p className="text-gray-600">Member Registration</p>
        </div>

        {/* Progress Indicator */}
        <div className="flex justify-center items-center mb-8">
          {[1, 2, 3, 4].map((step, index) => (
            <div key={step} className="flex items-center">
              <div className="w-10 h-10 rounded-full flex items-center justify-center font-bold bg-blue-600 text-white">
                {step}
              </div>
              {index < 3 && (
                <div className="w-10 h-0.5 bg-gray-300 mx-1"></div>
              )}
            </div>
          ))}
        </div>
        <p className="text-center text-gray-600 mb-8">Step 4 of 4</p>

        {/* Form Container */}
        <div className="bg-white rounded-2xl shadow-lg p-6 mb-8">
          <h3 className="text-xl font-bold text-gray-800 mb-6">Declaration</h3>

          {/* No. of Sister Concerns */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              No. of Sister Concerns
            </label>
            <input
              type="text"
              value={sisterConcerns}
              onChange={(e) => setSisterConcerns(e.target.value)}
              placeholder="Enter number"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
            <p className="text-xs text-gray-500 mt-1">Positive integers only</p>
          </div>

          {/* Name(s) of Company */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Name(s) of Company
            </label>
            <textarea
              value={companyNames}
              onChange={(e) => setCompanyNames(e.target.value)}
              placeholder="Enter company name (one per line)"
              rows={4}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          {/* Add Another Company Button */}
          <button
            type="button"
            onClick={handleAddCompany}
            className="w-full h-10 mb-4 border-2 border-gray-400 text-gray-600 rounded-lg font-medium hover:bg-gray-50 transition-colors"
          >
            Add Another Company
          </button>

          {/* Show one field per name checkbox */}
          <label className="flex items-center mb-6 cursor-pointer">
            <input
              type="checkbox"
              checked={showOneFieldPerName}
              onChange={(e) => setShowOneFieldPerName(e.target.checked)}
              className="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <span className="ml-3 text-sm text-gray-700">
              Show one field per name entered above
            </span>
          </label>

          {/* Declaration Text */}
          <div className="mb-6">
            <h4 className="text-lg font-semibold text-gray-800 mb-3">
              Declaration
            </h4>
            <p className="text-sm text-gray-700 leading-relaxed">
              This application is under the Verification and Screening Process. We
              have every right to ACCEPT or REJECT this application according to our
              membership policy. I confirm the above information is true and correct.
            </p>
          </div>

          {/* Agreement Checkbox */}
          <label className="flex items-start cursor-pointer">
            <input
              type="checkbox"
              checked={agreeToDeclaration}
              onChange={(e) => setAgreeToDeclaration(e.target.checked)}
              className="w-5 h-5 mt-0.5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <span className="ml-3 text-sm text-gray-700">
              I agree to the above declaration and confirm that all information
              provided is accurate
            </span>
          </label>
        </div>

        {/* Navigation Buttons */}
        <div className="space-y-4">
          <button
            type="button"
            onClick={handlePrevious}
            disabled={submitting}
            className="w-full h-12 border-2 border-purple-600 text-purple-600 rounded-lg font-semibold hover:bg-purple-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>

          <button
            type="button"
            onClick={handleSubmit}
            disabled={submitting}
            className="w-full h-12 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {submitting ? (
              <>
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                <span>Submitting...</span>
              </>
            ) : (
              'Submit Application'
            )}
          </button>
        </div>
      </div>
    </div>
  );
};

export default DeclarationForm;
```

---

## Complete API Service Integration

### ApiService.ts (Extended)

```typescript
// services/ApiService.ts
export class ApiService {
  static baseUrl = 'http://10.42.208.174:3000/api';

  static async getMemberByEmail(email: string) {
    const response = await fetch(`${this.baseUrl}/members/email/${email}`);
    return response.json();
  }

  static async updateMemberDetails(memberId: string, data: any) {
    const response = await fetch(`${this.baseUrl}/members/${memberId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return response.json();
  }

  static async saveBusinessInfo(memberId: string, data: any) {
    const response = await fetch(`${this.baseUrl}/members/${memberId}/business`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return response.json();
  }

  static async saveFinancialInfo(memberId: string, data: any) {
    const response = await fetch(`${this.baseUrl}/members/${memberId}/financial`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return response.json();
  }

  static async saveDeclaration(memberId: string, data: any) {
    const response = await fetch(`${this.baseUrl}/members/${memberId}/declaration`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return response.json();
  }

  static async submitApplication(data: any) {
    const response = await fetch(`${this.baseUrl}/applications/submit`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return response.json();
  }
}
```

### ApplicationService.ts

```typescript
// services/ApplicationService.ts
export class ApplicationService {
  constructor(private baseUrl: string, private token?: string) {}

  async submitApplication(
    userId: string,
    fullName: string,
    email: string,
    phone: string,
    state: string,
    district: string,
    block: string,
    formData: any
  ) {
    const response = await fetch(`${this.baseUrl}/applications/submit`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.token}`,
      },
      body: JSON.stringify({
        userId,
        fullName,
        email,
        phone,
        state,
        district,
        block,
        formData,
      }),
    });
    return response.json();
  }
}
```

### AuthService.ts

```typescript
// services/AuthService.ts
export class AuthService {
  static async getToken(): Promise<string | null> {
    // Get token from localStorage or session storage
    return localStorage.getItem('authToken');
  }

  static async setToken(token: string): Promise<void> {
    localStorage.setItem('authToken', token);
  }

  static async clearToken(): Promise<void> {
    localStorage.removeItem('authToken');
  }
}
```

---

## TypeScript Interfaces

### types.ts

```typescript
// types/index.ts

export interface UserData {
  memberId?: string;
  userId?: string;
  email?: string;
  fullName?: string;
  phoneNumber?: string;
  state?: string;
  district?: string;
  block?: string;
  city?: string;
  registrationForm?: RegistrationForm;
}

export interface RegistrationForm {
  // Personal Details
  fullName?: string;
  email?: string;
  phoneNumber?: string;
  state?: string;
  district?: string;
  block?: string;
  city?: string;
  aadhaarNumber?: string;
  streetName?: string;
  educationalQualification?: string;
  religion?: string;
  socialCategory?: string;

  // Business Information
  doingBusiness?: boolean;
  organizationName?: string;
  constitutionType?: string;
  businessTypes?: string[];
  businessActivities?: string;
  businessCommencementYear?: string;
  numberOfEmployees?: string;
  memberOfOtherChamber?: boolean;
  otherChamber?: string;
  govtOrganizations?: string[];

  // Financial Compliance
  panNumber?: string;
  gstNumber?: string;
  udyamNumber?: string;
  filedITR?: boolean;
  itrYears?: string;
  turnoverRange?: string;
  turnover?: string;
  fy2021?: string;
  fy2020?: string;
  fy2019?: string;
  govtSchemeBenefit?: boolean;
  scheme1?: string;
  scheme2?: string;
  scheme3?: string;

  // Declaration
  sisterConcerns?: string;
  companyNames?: string;
  showOneFieldPerName?: boolean;
  agreeToDeclaration?: boolean;
  profileCompleted?: boolean;
  submissionDate?: string;
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
}
```

---

## Complete Router Configuration



### App.tsx

```typescript
// App.tsx
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import PersonalDetailsForm from './screens/PersonalDetailsForm';
import BusinessInformationForm from './screens/BusinessInformationForm';
import FinancialComplianceForm from './screens/FinancialComplianceForm';
import DeclarationForm from './screens/DeclarationForm';
import ApplicationSubmitted from './screens/ApplicationSubmitted';
import ApplicationStatusScreen from './screens/ApplicationStatusScreen';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/personal-details" replace />} />
        <Route path="/personal-details" element={<PersonalDetailsForm userData={{}} />} />
        <Route path="/business-information" element={<BusinessInformationForm />} />
        <Route path="/financial-compliance" element={<FinancialComplianceForm />} />
        <Route path="/declaration" element={<DeclarationForm />} />
        <Route path="/application-submitted" element={<ApplicationSubmitted />} />
        <Route path="/application-status" element={<ApplicationStatusScreen />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
```

---

## 5. Application Status Screen

### ApplicationStatusScreen.tsx

**Based on**: `lib/screens/Application Status/application_status_screen.dart`

**Features**:
- Multi-stage approval tracking (Block → District → State → Payment)
- Real-time status updates with progress visualization
- Dynamic stage rendering based on backend status
- Admin assignment information
- Review timestamps and messages
- Rejection handling with reason display
- Payment registration when fully approved
- Refresh functionality

```tsx
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ApiService } from '../../services/ApiService';

// ==================== TYPES & INTERFACES ====================

interface AdminData {
  id: string;
  fullName: string;
  email: string;
}

interface ReviewedBy {
  blockAdmin?: string;
  districtAdmin?: string;
  stateAdmin?: string;
}

interface ApplicationData {
  id: string;
  userId: string;
  fullName: string;
  email: string;
  phone: string;
  state: string;
  district: string;
  block: string;
  formData: Record<string, any>;
  status: 'Pending-Block' | 'Pending-District' | 'Pending-State' | 'Approved' | 'Rejected';
  assignedBlockAdmin?: AdminData;
  assignedDistrictAdmin?: AdminData;
  assignedStateAdmin?: AdminData;
  rejectionReason?: string;
  blockApprovedAt?: Date;
  districtApprovedAt?: Date;
  stateApprovedAt?: Date;
  reviewedBy?: ReviewedBy;
  createdAt: Date;
  updatedAt: Date;
  // Helper flags
  isBlockApproved: boolean;
  isDistrictApproved: boolean;
  isStateApproved: boolean;
  isRejected: boolean;
}

interface ApplicationStage {
  name: string;
  displayName: string;
  status: 'pending' | 'in_progress' | 'approved' | 'rejected';
  reviewer?: string;
  reviewDate?: Date;
  message?: string;
  statusColor: string;
  icon: string;
  isCompleted: boolean;
  isActive: boolean;
}

// ==================== MAIN COMPONENT ====================

const ApplicationStatusScreen: React.FC = () => {
  const navigate = useNavigate();

  const [applicationData, setApplicationData] = useState<ApplicationData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [stages, setStages] = useState<ApplicationStage[]>([]);

  useEffect(() => {
    fetchApplicationStatus();
  }, []);

  // ==================== API FUNCTIONS ====================

  const fetchApplicationStatus = async () => {
    try {
      setIsLoading(true);
      setErrorMessage(null);

      const userData = await ApiService.getUserData();
      if (!userData) {
        throw new Error('User not logged in');
      }

      const userId = userData.id || userData.memberId || userData._id;
      if (!userId) {
        throw new Error('User ID not found');
      }

      const response = await ApiService.get(`/applications/user/${userId}`);

      console.log('🔍 DEBUG: Fetched', response.applications.length, 'application(s)');
      
      if (response.applications && response.applications.length > 0) {
        const app = response.applications[0];
        console.log('📊 DEBUG Application Data:');
        console.log('  - Status:', app.status);
        console.log('  - Block Approved:', app.isBlockApproved);
        console.log('  - District Approved:', app.isDistrictApproved);
        console.log('  - State Approved:', app.isStateApproved);

        setApplicationData(app);
        setStages(buildStagesFromData(app));
      } else {
        setErrorMessage('No application found');
      }
    } catch (error) {
      console.error('❌ DEBUG Error fetching application:', error);
      setErrorMessage(`Failed to load application status: ${error}`);
    } finally {
      setIsLoading(false);
    }
  };

  // ==================== STAGE BUILDING ====================

  const buildStagesFromData = (data: ApplicationData): ApplicationStage[] => {
    return [
      // Block Admin Review Stage
      {
        name: 'block_admin',
        displayName: 'Block Admin Review',
        status: getStageStatus('block', data),
        reviewer: data.assignedBlockAdmin?.fullName || 'Block Admin',
        reviewDate: data.blockApprovedAt,
        message: getStageMessage('block', data),
        statusColor: getStageColor('block', data),
        icon: getStageIcon('block', data),
        isCompleted: data.isBlockApproved,
        isActive: data.status === 'Pending-Block',
      },
      // District Admin Review Stage
      {
        name: 'district_admin',
        displayName: 'District Admin Review',
        status: getStageStatus('district', data),
        reviewer: data.assignedDistrictAdmin?.fullName || 'District Admin',
        reviewDate: data.districtApprovedAt,
        message: getStageMessage('district', data),
        statusColor: getStageColor('district', data),
        icon: getStageIcon('district', data),
        isCompleted: data.isDistrictApproved,
        isActive: data.status === 'Pending-District',
      },
      // State Admin Review Stage
      {
        name: 'state_admin',
        displayName: 'State Admin Review',
        status: getStageStatus('state', data),
        reviewer: data.assignedStateAdmin?.fullName || 'State Admin',
        reviewDate: data.stateApprovedAt,
        message: getStageMessage('state', data),
        statusColor: getStageColor('state', data),
        icon: getStageIcon('state', data),
        isCompleted: data.isStateApproved,
        isActive: data.status === 'Pending-State',
      },
      // Payment Stage
      {
        name: 'payment',
        displayName: 'Ready for Payment',
        status: data.status === 'Approved' ? 'approved' : 'pending',
        reviewer: 'ACTIV Super Admin',
        reviewDate: undefined,
        message:
          data.status === 'Approved'
            ? 'Your application has been approved. Please proceed to payment.'
            : '',
        statusColor: data.status === 'Approved' ? '#4CAF50' : '#90CAF9',
        icon: data.status === 'Approved' ? '✓' : '💳',
        isCompleted: data.status === 'Approved',
        isActive: false,
      },
    ];
  };

  // ==================== HELPER FUNCTIONS ====================

  const getStageStatus = (
    stageType: string,
    data: ApplicationData
  ): 'pending' | 'in_progress' | 'approved' | 'rejected' => {
    if (data.isRejected) return 'rejected';

    switch (stageType) {
      case 'block':
        if (data.isBlockApproved) return 'approved';
        if (data.status === 'Pending-Block') return 'in_progress';
        return 'pending';
      case 'district':
        if (data.isDistrictApproved) return 'approved';
        if (data.status === 'Pending-District') return 'in_progress';
        return 'pending';
      case 'state':
        if (data.isStateApproved) return 'approved';
        if (data.status === 'Pending-State') return 'in_progress';
        return 'pending';
      default:
        return 'pending';
    }
  };

  const getStageColor = (stageType: string, data: ApplicationData): string => {
    const status = getStageStatus(stageType, data);
    switch (status) {
      case 'approved':
        return '#4CAF50'; // Green
      case 'in_progress':
        return '#2196F3'; // Blue
      case 'rejected':
        return '#F44336'; // Red
      default:
        return '#90CAF9'; // Light blue
    }
  };

  const getStageIcon = (stageType: string, data: ApplicationData): string => {
    const status = getStageStatus(stageType, data);
    switch (status) {
      case 'approved':
        return '✓';
      case 'in_progress':
        return '⏳';
      case 'rejected':
        return '✕';
      default:
        return '○';
    }
  };

  const getStageMessage = (stageType: string, data: ApplicationData): string => {
    const status = getStageStatus(stageType, data);

    switch (status) {
      case 'approved':
        switch (stageType) {
          case 'block':
            return 'All documents verified. Profile looks good.';
          case 'district':
            return 'District level verification completed.';
          case 'state':
            return 'State level verification completed.';
          default:
            return 'Stage completed successfully.';
        }
      case 'in_progress':
        return 'Your application is currently being reviewed. You will be notified once this stage is complete.';
      case 'rejected':
        return data.rejectionReason || 'Application rejected at this stage.';
      default:
        return '';
    }
  };

  const getDynamicProgressPercentage = (): number => {
    if (!applicationData || applicationData.isRejected) return 0;
    if (stages.length === 0) return 0;

    const completedStages = stages.filter((stage) => stage.isCompleted).length;
    return Math.min(Math.max(completedStages / stages.length, 0), 1);
  };

  const getDynamicProgressText = (): string => {
    if (!applicationData) return 'Loading...';
    if (applicationData.isRejected) return 'Application rejected';
    if (stages.length === 0) return 'No stages available';

    const completedStages = stages.filter((stage) => stage.isCompleted).length;
    return `${completedStages} of ${stages.length} stages completed`;
  };

  const isAllStagesApproved = (): boolean => {
    if (!applicationData) return false;
    return (
      applicationData.isBlockApproved &&
      applicationData.isDistrictApproved &&
      applicationData.isStateApproved &&
      !applicationData.isRejected
    );
  };

  const formatDate = (date: Date): string => {
    const d = new Date(date);
    return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()}`;
  };

  const formatDateTime = (date: Date): string => {
    return formatDate(date);
  };

  // ==================== EVENT HANDLERS ====================

  const handlePaymentRegistration = () => {
    if (window.confirm('You are about to proceed with the payment registration process. Continue?')) {
      navigate('/complete-membership');
    }
  };

  const handleBackToDashboard = () => {
    navigate('/dashboard');
  };

  // ==================== RENDER FUNCTIONS ====================

  const renderStatusStep = (stage: ApplicationStage) => {
    const shortName = stage.displayName
      .replace('Admin Review', 'Admin')
      .replace('Ready for Payment', 'Ready for\nPayment');

    let stepColor: string;
    if (stage.isCompleted) {
      stepColor = '#4CAF50'; // Green
    } else if (stage.isActive) {
      stepColor = '#2196F3'; // Blue
    } else if (stage.status === 'rejected') {
      stepColor = '#F44336'; // Red
    } else {
      stepColor = '#E0E0E0'; // Grey
    }

    return (
      <div key={stage.name} className="flex-1 flex flex-col items-center">
        <div
          className="w-8 h-8 rounded-full flex items-center justify-center text-white font-semibold"
          style={{
            backgroundColor: stepColor,
            boxShadow:
              stage.isCompleted || stage.isActive
                ? `0 2px 4px ${stepColor}4D`
                : 'none',
          }}
        >
          {stage.status === 'rejected' ? (
            <span>✕</span>
          ) : stage.isCompleted ? (
            <span>✓</span>
          ) : stage.isActive ? (
            <span>⏳</span>
          ) : (
            <span className="text-xs">○</span>
          )}
        </div>
        <p
          className="text-xs font-medium mt-2 text-center"
          style={{
            color:
              stage.isCompleted || stage.isActive ? '#1A1A1A' : '#757575',
          }}
        >
          {shortName}
        </p>
      </div>
    );
  };

  const renderStatusCard = (stage: ApplicationStage) => {
    let statusColor: string;
    let backgroundColor: string;
    let statusText: string;

    switch (stage.status) {
      case 'approved':
        statusColor = '#2E7D32'; // Dark green
        backgroundColor = '#E8F5E8'; // Light green
        statusText = 'Approved';
        break;
      case 'in_progress':
        statusColor = '#1565C0'; // Dark blue
        backgroundColor = '#E3F2FD'; // Light blue
        statusText = 'In Progress';
        break;
      case 'rejected':
        statusColor = '#FFFFFF';
        backgroundColor = '#F44336'; // Red
        statusText = 'Rejected';
        break;
      default:
        statusColor = '#5D4037'; // Dark brown
        backgroundColor = '#F3E5F5'; // Light purple
        statusText = 'Pending';
    }

    return (
      <div
        key={stage.name}
        className="w-full mb-4 mx-4 bg-white rounded-2xl shadow-lg p-5"
      >
        {/* Card Header */}
        <div className="flex justify-between items-start">
          <div className="flex-1">
            <h3 className="text-lg font-semibold text-gray-900 mb-1.5">
              {stage.displayName}
            </h3>
            {stage.reviewer && (
              <p className="text-sm text-gray-600">{stage.reviewer}</p>
            )}
            {stage.reviewDate && (
              <p className="text-xs text-gray-400 mt-1">
                Review Date: {formatDateTime(stage.reviewDate)}
              </p>
            )}
          </div>
          <span
            className="px-3.5 py-2 rounded-full text-xs font-semibold whitespace-nowrap ml-4"
            style={{
              backgroundColor,
              color: statusColor,
              border:
                stage.status === 'rejected'
                  ? 'none'
                  : `1px solid ${statusColor}33`,
            }}
          >
            {statusText}
          </span>
        </div>

        {/* Message Box */}
        {stage.message && (
          <div
            className="mt-4 p-4 rounded-xl border flex items-start"
            style={{
              backgroundColor:
                stage.status === 'approved'
                  ? '#E8F5E8'
                  : stage.status === 'rejected'
                  ? '#FFEBEE'
                  : '#FEF3C7',
              borderColor:
                stage.status === 'approved'
                  ? '#4CAF504D'
                  : stage.status === 'rejected'
                  ? '#E53E3E4D'
                  : '#F59E0B4D',
            }}
          >
            <span className="text-lg mr-3">
              {stage.status === 'rejected'
                ? '⚠️'
                : stage.status === 'approved'
                ? '✓'
                : 'ℹ️'}
            </span>
            <p
              className="text-sm leading-relaxed"
              style={{
                color:
                  stage.status === 'approved'
                    ? '#2E7D32'
                    : stage.status === 'rejected'
                    ? '#D32F2F'
                    : '#F59E0B',
              }}
            >
              {stage.message}
            </p>
          </div>
        )}
      </div>
    );
  };

  const renderWaitingSection = () => (
    <div className="w-full mx-4 mb-5 bg-white rounded-2xl shadow-lg p-4">
      <div className="bg-blue-50 rounded-2xl p-5">
        <h3 className="text-lg font-bold text-blue-700 mb-3">
          Waiting for Approval
        </h3>
        <p className="text-sm text-gray-700 leading-relaxed">
          Your application is currently under review. Once all approval stages are
          complete, you'll be redirected to the payment section to complete your
          membership.
        </p>
      </div>
    </div>
  );

  const renderRejectionSection = () => (
    <div className="w-full mx-4 mb-5 bg-red-50 rounded-xl border border-red-200 p-4">
      <div className="flex items-center mb-2">
        <span className="text-red-600 mr-2">⚠️</span>
        <h3 className="text-base font-semibold text-red-800">
          Application Rejected
        </h3>
      </div>
      <p className="text-sm text-red-700 leading-relaxed">
        {applicationData?.rejectionReason ||
          'Your application has been rejected. Please contact support for more information.'}
      </p>
    </div>
  );

  // ==================== MAIN RENDER ====================

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-blue-100 to-purple-100 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-t-4 border-blue-600 mx-auto mb-4"></div>
          <p className="text-base text-gray-600">Loading application status...</p>
        </div>
      </div>
    );
  }

  if (errorMessage) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-blue-100 to-purple-100 flex items-center justify-center">
        <div className="text-center px-8">
          <span className="text-6xl text-red-400 mb-4 block">⚠️</span>
          <h2 className="text-xl font-semibold text-red-700 mb-2">
            Error Loading Status
          </h2>
          <p className="text-sm text-gray-600 mb-6">{errorMessage}</p>
          <button
            onClick={fetchApplicationStatus}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (!applicationData) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-blue-100 to-purple-100 flex items-center justify-center">
        <p className="text-base text-gray-600">No application data found</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-100 to-purple-100">
      <div className="max-w-4xl mx-auto px-5 py-8">
        {/* Header */}
        <div className="text-center mb-6">
          <h1 className="text-2xl font-bold text-gray-900 mb-2">
            Application Status
          </h1>
          <p className="text-base text-gray-700">
            Track your membership approval progress
          </p>
        </div>

        {/* Overall Progress Section */}
        <div className="bg-white rounded-2xl shadow-lg p-5 mb-5 mx-4">
          <div className="bg-white rounded-lg p-4">
            <h2 className="text-lg font-semibold text-center text-gray-900 mb-3">
              Overall Progress
            </h2>
            <p className="text-sm text-center text-gray-800 mb-4">
              {getDynamicProgressText()}
            </p>

            {/* Progress Bar */}
            <div className="w-full h-2.5 bg-indigo-100 rounded-full mb-4">
              <div
                className="h-full rounded-full transition-all duration-500"
                style={{
                  width: `${getDynamicProgressPercentage() * 100}%`,
                  background: applicationData.isRejected
                    ? 'linear-gradient(90deg, #E53E3E, #C53030)'
                    : 'linear-gradient(90deg, #3182CE, #2B6CB0)',
                  boxShadow: applicationData.isRejected
                    ? '0 2px 4px #E53E3E4D'
                    : '0 2px 4px #3182CE4D',
                }}
              ></div>
            </div>

            {/* Status Steps */}
            <div className="flex justify-between items-center">
              {stages.map((stage) => renderStatusStep(stage))}
            </div>
          </div>
        </div>

        {/* Stage Cards */}
        {stages.map((stage) => renderStatusCard(stage))}

        {/* Waiting/Rejection Sections */}
        {!applicationData.isRejected && applicationData.status !== 'Approved' && (
          renderWaitingSection()
        )}
        {applicationData.isRejected && renderRejectionSection()}

        {/* Payment Button */}
        {isAllStagesApproved() && (
          <div className="mx-4 mb-4">
            <button
              onClick={handlePaymentRegistration}
              className="w-full py-4 bg-blue-600 text-white rounded-xl font-semibold hover:bg-blue-700 transition-colors flex items-center justify-center"
            >
              <span className="mr-2">💳</span>
              Register for Payment
            </button>
          </div>
        )}

        {/* Back to Dashboard */}
        <div className="mx-4">
          <button
            onClick={handleBackToDashboard}
            className="w-full py-4 bg-white text-blue-600 border border-blue-600 rounded-xl font-semibold hover:bg-blue-50 transition-colors"
          >
            Back to Dashboard
          </button>
        </div>
      </div>
    </div>
  );
};

export default ApplicationStatusScreen;
```

### ApplicationStatusService.ts

```typescript
import { ApiService } from './ApiService';

export interface AdminData {
  id: string;
  fullName: string;
  email: string;
}

export interface ReviewedBy {
  blockAdmin?: string;
  districtAdmin?: string;
  stateAdmin?: string;
}

export interface ApplicationData {
  id: string;
  userId: string;
  fullName: string;
  email: string;
  phone: string;
  state: string;
  district: string;
  block: string;
  formData: Record<string, any>;
  status: 'Pending-Block' | 'Pending-District' | 'Pending-State' | 'Approved' | 'Rejected';
  assignedBlockAdmin?: AdminData;
  assignedDistrictAdmin?: AdminData;
  assignedStateAdmin?: AdminData;
  rejectionReason?: string;
  blockApprovedAt?: Date;
  districtApprovedAt?: Date;
  stateApprovedAt?: Date;
  reviewedBy?: ReviewedBy;
  createdAt: Date;
  updatedAt: Date;
  // Helper computed properties
  isBlockApproved: boolean;
  isDistrictApproved: boolean;
  isStateApproved: boolean;
  isRejected: boolean;
}

export interface ApplicationStatusResponse {
  success: boolean;
  applications: ApplicationData[];
  count: number;
}

export class ApplicationStatusService {
  static async fetchApplicationStatus(): Promise<ApplicationStatusResponse> {
    const userData = await ApiService.getUserData();
    if (!userData) {
      throw new Error('User not logged in');
    }

    const userId = userData.id || userData.memberId || userData._id;
    if (!userId) {
      throw new Error('User ID not found');
    }

    const response = await ApiService.get<ApplicationStatusResponse>(
      `/applications/user/${userId}`
    );

    // Transform response to include helper flags
    response.applications = response.applications.map((app) => ({
      ...app,
      isBlockApproved: !!app.blockApprovedAt,
      isDistrictApproved: !!app.districtApprovedAt,
      isStateApproved: !!app.stateApprovedAt,
      isRejected: app.status === 'Rejected',
    }));

    return response;
  }
}
```

---

## Summary of All Four Forms

### Form Features Comparison

| Feature | Personal | Business | Financial | Declaration |
|---------|----------|----------|-----------|-------------|
| **Auto-save** | ✅ | ✅ | ✅ | ❌ |
| **Form Lock** | ✅ | ❌ | ❌ | ❌ |
| **Conditional Fields** | ❌ | ✅ | ✅ | ❌ |
| **Multi-select** | ❌ | ✅ | ❌ | ❌ |
| **Validation** | ✅ (Aadhaar, Password) | ❌ | ✅ (PAN, GST) | ✅ (Agreement) |
| **Dynamic Content** | ❌ | ✅ (Aspirant mode) | ✅ (ITR/Schemes) | ✅ (Add companies) |
| **Final Submit** | ❌ | ✅ (Aspirants) | ❌ | ✅ (All members) |

### Screen Counts

- **Personal Details**: 13 fields (including password fields)
- **Business Information**: 11 fields + multi-selects
- **Financial Compliance**: 13 fields (with conditional fields)
- **Declaration**: 4 fields + agreement checkbox
- **Application Status**: Multi-stage tracking screen

### Total Implementation

- **5 Complete Screens**: All converted from Flutter Dart to React TSX
- **Auto-save**: Implemented with debounce timer (2 seconds)
- **Progress Tracking**: 4-step progress indicator + multi-stage approval
- **Conditional Logic**: Company vs Aspirant flows
- **Validation**: PAN, GST, Aadhaar, agreements
- **API Integration**: Complete service layer
- **TypeScript Types**: Full type safety
- **Responsive Design**: Tailwind CSS styling
- **Approval Workflow**: Block → District → State → Payment

This completes the full conversion of all member registration forms and application status tracking from Flutter Dart to React TypeScript (TSX) format!

