import { getCurrentUser } from "@/lib/auth";
import { query, queryOne } from "@/lib/db";
import { redirect } from "next/navigation";
import UserDetailClient from "./UserDetailClient";
import { getRoleFromId } from "@/lib/user-id-generator";

type PatientProfile = {
  pesel: string | null;
  date_of_birth: string | null;
  gender: string | null;
  pesel_status: string | null;
  child_number: string | null;
  nfz_branch: string | null;
  insurance_entitlement: string | null;
  insurance_confirmation_status: string | null;
  insurance_additional_entitlements: string | null;
  eku_number: string | null;
  eu_patient_number: string | null;
  maiden_name: string | null;
  father_name: string | null;
  mother_name: string | null;
  authorized_person: string | null;
  documents_info: string | null;
  consent_accepted: boolean | null;
  allergies: string | null;
  asthma: boolean | null;
  jaundice: string | null;
  hypertension: string | null;
  heart_diseases: boolean | null;
  kidney_diseases: boolean | null;
  diabetes: boolean | null;
  tuberculosis: boolean | null;
  rheumatic_disease: boolean | null;
  blood_clotting_disorders: boolean | null;
  hormonal_disorders: boolean | null;
  porphyria: boolean | null;
  thyroid_diseases: boolean | null;
  other_diseases: string | null;
  current_medications: string | null;
  treatment_consent: boolean | null;
};

type User = {
  id: string;
  email: string;
  display_name: string;
  first_name: string | null;
  last_name: string | null;
  patient_number: string | null;
  phone: string | null;
  role: string;
  active: boolean;
  email_verified: boolean;
  phone_verified: boolean;
  created_at: Date;
  last_login_at: Date | null;
  patientProfile: PatientProfile | null;
};

export default async function UserDetailPage({ params }: { params: { id: string } }) {
  const currentUser = await getCurrentUser();

  if (!currentUser || (currentUser.role !== "admin" && currentUser.role !== "owner")) {
    redirect(`/${currentUser?.id || ""}`);
  }

  // First, try to find user in users table
  let user = await queryOne<{
    id: string;
    email: string;
    display_name: string;
    first_name: string | null;
    last_name: string | null;
    patient_number: string | null;
    phone: string | null;
    role: string;
    active: boolean;
    email_verified: boolean;
    phone_verified: boolean;
    created_at: Date;
    last_login_at: Date | null;
    pesel: string | null;
    date_of_birth: string | null;
  }>(
    `SELECT 
      u.id, u.email, u.display_name, u.first_name, u.last_name,
      get_patient_number(u.id) as patient_number, get_user_phone(u.id) as phone,
      u.active, u.email_verified, get_user_phone_verified(u.id) as phone_verified, u.created_at, u.last_login_at,
      get_user_text_field(u.id, 'pesel') as pesel,
      get_user_text_field(u.id, 'date_of_birth') as date_of_birth
     FROM users u
     WHERE u.id::text = $1`,
    [params.id]
  );
  
  // Add role from ID prefix
  if (user) {
    user.role = getRoleFromId(user.id) || "user";
  }

  let patientProfile: PatientProfile | null = null;
  
  if (user) {
    try {
      // Fetch patient profile if exists - use LEFT JOIN to ensure we get all data
      // Ensure params.id is treated as UUID
      const profileResult = await queryOne<PatientProfile & { pesel: string | null; date_of_birth: string | null }>(
        `SELECT 
          pp.pesel_status,
          pp.child_number,
          pp.gender,
          pp.nfz_branch,
          pp.insurance_entitlement,
          pp.insurance_confirmation_status,
          pp.insurance_additional_entitlements,
          pp.eku_number,
          pp.eu_patient_number,
          pp.maiden_name,
          pp.father_name,
          pp.mother_name,
          pp.authorized_person,
          pp.documents_info,
          pp.consent_accepted,
          pp.allergies,
          pp.asthma,
          pp.jaundice,
          pp.hypertension,
          pp.heart_diseases,
          pp.kidney_diseases,
          pp.diabetes,
          pp.tuberculosis,
          pp.rheumatic_disease,
          pp.blood_clotting_disorders,
          pp.hormonal_disorders,
          pp.porphyria,
          pp.thyroid_diseases,
          pp.other_diseases,
          pp.current_medications,
          pp.treatment_consent,
          get_user_text_field(u.id, 'pesel') as pesel,
          get_user_text_field(u.id, 'date_of_birth') as date_of_birth
         FROM users u
         LEFT JOIN patient_profiles pp ON pp.user_id = u.id
         WHERE u.id::text = $1`,
        [params.id]
      );

      if (profileResult) {
        patientProfile = {
          pesel: profileResult.pesel,
          date_of_birth: profileResult.date_of_birth,
          gender: profileResult.gender,
          pesel_status: profileResult.pesel_status,
          child_number: profileResult.child_number,
          nfz_branch: profileResult.nfz_branch,
          insurance_entitlement: profileResult.insurance_entitlement,
          insurance_confirmation_status: profileResult.insurance_confirmation_status,
          insurance_additional_entitlements: profileResult.insurance_additional_entitlements,
          eku_number: profileResult.eku_number,
          eu_patient_number: profileResult.eu_patient_number,
          maiden_name: profileResult.maiden_name,
          father_name: profileResult.father_name,
          mother_name: profileResult.mother_name,
          authorized_person: profileResult.authorized_person,
          documents_info: profileResult.documents_info,
          consent_accepted: profileResult.consent_accepted,
          allergies: profileResult.allergies,
          asthma: profileResult.asthma,
          jaundice: profileResult.jaundice,
          hypertension: profileResult.hypertension,
          heart_diseases: profileResult.heart_diseases,
          kidney_diseases: profileResult.kidney_diseases,
          diabetes: profileResult.diabetes,
          tuberculosis: profileResult.tuberculosis,
          rheumatic_disease: profileResult.rheumatic_disease,
          blood_clotting_disorders: profileResult.blood_clotting_disorders,
          hormonal_disorders: profileResult.hormonal_disorders,
          porphyria: profileResult.porphyria,
          thyroid_diseases: profileResult.thyroid_diseases,
          other_diseases: profileResult.other_diseases,
          current_medications: profileResult.current_medications,
          treatment_consent: profileResult.treatment_consent,
        };
      } else {
        // Create empty profile if none exists
        patientProfile = {
          pesel: user.pesel,
          date_of_birth: user.date_of_birth,
          gender: null,
          pesel_status: null,
          child_number: null,
          nfz_branch: null,
          insurance_entitlement: null,
          insurance_confirmation_status: null,
          insurance_additional_entitlements: null,
          eku_number: null,
          eu_patient_number: null,
          maiden_name: null,
          father_name: null,
          mother_name: null,
          authorized_person: null,
          documents_info: null,
          consent_accepted: null,
          allergies: null,
          asthma: false,
          jaundice: null,
          hypertension: null,
          heart_diseases: false,
          kidney_diseases: false,
          diabetes: false,
          tuberculosis: false,
          rheumatic_disease: false,
          blood_clotting_disorders: false,
          hormonal_disorders: false,
          porphyria: false,
          thyroid_diseases: false,
          other_diseases: null,
          current_medications: null,
          treatment_consent: false,
        };
      }
    } catch (error) {
      console.error("Error fetching patient profile:", error);
      // Create empty profile on error
      patientProfile = {
        pesel: user.pesel,
        date_of_birth: user.date_of_birth,
        gender: null,
        pesel_status: null,
        child_number: null,
        nfz_branch: null,
        insurance_entitlement: null,
        insurance_confirmation_status: null,
        insurance_additional_entitlements: null,
        eku_number: null,
        eu_patient_number: null,
        maiden_name: null,
        father_name: null,
        mother_name: null,
        authorized_person: null,
        documents_info: null,
        consent_accepted: null,
        allergies: null,
        asthma: false,
        jaundice: null,
        hypertension: null,
        heart_diseases: false,
        kidney_diseases: false,
        diabetes: false,
        tuberculosis: false,
        rheumatic_disease: false,
        blood_clotting_disorders: false,
        hormonal_disorders: false,
        porphyria: false,
        thyroid_diseases: false,
        other_diseases: null,
        current_medications: null,
        treatment_consent: false,
      };
    }
  }

  // If not found in users table, try to find in patients table
  if (!user) {
    const patient = await queryOne<{
      id: string;
      email: string | null;
      first_name: string;
      last_name: string;
      patient_number: string;
      phone: string | null;
      active: boolean;
      created_at: Date;
    }>(
      `SELECT 
        p.id::text as id,
        p.email,
        p.first_name,
        p.last_name,
        p.patient_number,
        p.phone,
        p.active,
        p.created_at
       FROM patients p
       WHERE p.id = $1`,
      [params.id]
    );

    if (patient) {
      // Convert patient to user format
      user = {
        id: patient.id,
        email: patient.email || "",
        display_name: `${patient.first_name} ${patient.last_name}`,
        first_name: patient.first_name,
        last_name: patient.last_name,
        patient_number: patient.patient_number,
        phone: patient.phone,
        role: "patient",
        active: patient.active,
        email_verified: false,
        phone_verified: false,
        created_at: patient.created_at,
        last_login_at: null,
        pesel: null,
        date_of_birth: null,
      };
    }
  }

  if (!user) {
    redirect(`/${currentUser.username}/users`);
  }

  // Combine user data with patient profile
  const userWithProfile: User = {
    ...user,
    patientProfile,
  };

  const isOwnerUser = currentUser.role === "owner";

  return <UserDetailClient currentUserId={currentUser.id} user={userWithProfile} isSuperadmin={isOwnerUser} />;
}

