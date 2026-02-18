--
-- PostgreSQL database dump
--

\restrict mr2ZrFJiAgGpMVnHxUMGGyCpQ2J0ksvI8hrmmtGNWBbp5QwsVB3cfiHDdTtemgN

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: generate_appointment_number(); Type: FUNCTION; Schema: public; Owner: ceramix_user
--

CREATE FUNCTION public.generate_appointment_number() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.appointment_number IS NULL OR NEW.appointment_number = '' THEN
        NEW.appointment_number := 'APT-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(NEXTVAL('appointment_number_seq')::TEXT, 4, '0');
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.generate_appointment_number() OWNER TO ceramix_user;

--
-- Name: generate_invoice_number(); Type: FUNCTION; Schema: public; Owner: ceramix_user
--

CREATE FUNCTION public.generate_invoice_number() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
        NEW.invoice_number := 'FV-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(NEXTVAL('invoice_number_seq')::TEXT, 4, '0');
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.generate_invoice_number() OWNER TO ceramix_user;

--
-- Name: generate_patient_number(); Type: FUNCTION; Schema: public; Owner: ceramix_user
--

CREATE FUNCTION public.generate_patient_number() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.patient_number IS NULL OR NEW.patient_number = '' THEN
        NEW.patient_number := 'PAT-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(NEXTVAL('patient_number_seq')::TEXT, 4, '0');
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.generate_patient_number() OWNER TO ceramix_user;

--
-- Name: get_patient_number(uuid); Type: FUNCTION; Schema: public; Owner: ceramix_user
--

CREATE FUNCTION public.get_patient_number(user_uuid uuid) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
        DECLARE
          result TEXT;
          has_users_patient_number BOOLEAN;
          has_patients_table BOOLEAN;
          has_patients_user_id BOOLEAN;
          has_patients_patient_number BOOLEAN;
        BEGIN
          SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'patient_number'
          ) INTO has_users_patient_number;

          IF has_users_patient_number THEN
            SELECT patient_number INTO result FROM users WHERE id = user_uuid LIMIT 1;
            IF result IS NOT NULL THEN
              RETURN result;
            END IF;
          END IF;

          SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'patients'
          ) INTO has_patients_table;

          IF has_patients_table THEN
            SELECT EXISTS (
              SELECT 1 FROM information_schema.columns 
              WHERE table_schema = 'public' AND table_name = 'patients' AND column_name = 'patient_number'
            ) INTO has_patients_patient_number;

            IF has_patients_patient_number THEN
              SELECT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'public' AND table_name = 'patients' AND column_name = 'user_id'
              ) INTO has_patients_user_id;

              IF has_patients_user_id THEN
                SELECT patient_number
                INTO result
                FROM patients
                WHERE user_id = user_uuid
                ORDER BY created_at DESC
                LIMIT 1;
                IF result IS NOT NULL THEN
                  RETURN result;
                END IF;
              END IF;

              -- Fallback: match by primary id if schemas shared UUIDs
              SELECT patient_number
              INTO result
              FROM patients
              WHERE id = user_uuid
              ORDER BY created_at DESC
              LIMIT 1;
              IF result IS NOT NULL THEN
                RETURN result;
              END IF;
            END IF;
          END IF;

          RETURN NULL;
        END;
        $$;


ALTER FUNCTION public.get_patient_number(user_uuid uuid) OWNER TO ceramix_user;

--
-- Name: get_user_phone(uuid); Type: FUNCTION; Schema: public; Owner: ceramix_user
--

CREATE FUNCTION public.get_user_phone(user_uuid uuid) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
        DECLARE
          result TEXT;
          has_users_phone BOOLEAN;
          has_patients_table BOOLEAN;
          has_patients_user_id BOOLEAN;
          has_patients_phone BOOLEAN;
        BEGIN
          SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'phone'
          ) INTO has_users_phone;

          IF has_users_phone THEN
            SELECT phone INTO result FROM users WHERE id = user_uuid LIMIT 1;
            IF result IS NOT NULL THEN
              RETURN result;
            END IF;
          END IF;

          SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'patients'
          ) INTO has_patients_table;

          IF has_patients_table THEN
            SELECT EXISTS (
              SELECT 1 FROM information_schema.columns 
              WHERE table_schema = 'public' AND table_name = 'patients' AND column_name = 'phone'
            ) INTO has_patients_phone;

            IF has_patients_phone THEN
              SELECT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'public' AND table_name = 'patients' AND column_name = 'user_id'
              ) INTO has_patients_user_id;

              IF has_patients_user_id THEN
                SELECT phone
                INTO result
                FROM patients
                WHERE user_id = user_uuid
                ORDER BY created_at DESC
                LIMIT 1;
                IF result IS NOT NULL THEN
                  RETURN result;
                END IF;
              END IF;

              -- Fallback: match by patient primary id
              SELECT phone
              INTO result
              FROM patients
              WHERE id = user_uuid
              ORDER BY created_at DESC
              LIMIT 1;
              IF result IS NOT NULL THEN
                RETURN result;
              END IF;
            END IF;
          END IF;

          RETURN NULL;
        END;
        $$;


ALTER FUNCTION public.get_user_phone(user_uuid uuid) OWNER TO ceramix_user;

--
-- Name: get_user_phone_verified(uuid); Type: FUNCTION; Schema: public; Owner: ceramix_user
--

CREATE FUNCTION public.get_user_phone_verified(user_uuid uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
        DECLARE
          result BOOLEAN;
          column_exists BOOLEAN;
        BEGIN
          -- Check if phone_verified column exists
          SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'users' 
            AND column_name = 'phone_verified'
          ) INTO column_exists;

          IF NOT column_exists THEN
            RETURN false;
          END IF;

          -- Get phone_verified value
          SELECT COALESCE(phone_verified, false)
          INTO result
          FROM users
          WHERE id = user_uuid
          LIMIT 1;

          RETURN COALESCE(result, false);
        EXCEPTION
          WHEN undefined_column THEN
            RETURN false;
        END;
        $$;


ALTER FUNCTION public.get_user_phone_verified(user_uuid uuid) OWNER TO ceramix_user;

--
-- Name: get_user_text_field(uuid, text); Type: FUNCTION; Schema: public; Owner: ceramix_user
--

CREATE FUNCTION public.get_user_text_field(user_uuid uuid, target_column text) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $_$
        DECLARE
          result TEXT;
          column_exists BOOLEAN;
        BEGIN
          EXECUTE $sql$
            SELECT EXISTS (
              SELECT 1 FROM information_schema.columns 
              WHERE table_schema = 'public' AND table_name = 'users' AND column_name = $1
            )
          $sql$
          INTO column_exists
          USING target_column;

          IF NOT column_exists THEN
            RETURN NULL;
          END IF;

          EXECUTE format('SELECT %I::TEXT FROM users WHERE id = $1 LIMIT 1', target_column)
          INTO result
          USING user_uuid;

          RETURN result;
        EXCEPTION
          WHEN undefined_column THEN
            RETURN NULL;
        END;
        $_$;


ALTER FUNCTION public.get_user_text_field(user_uuid uuid, target_column text) OWNER TO ceramix_user;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

--
-- Name: appointment_number_seq; Type: SEQUENCE; Schema: public; Owner: ceramix_user
--

CREATE SEQUENCE public.appointment_number_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.appointment_number_seq OWNER TO ceramix_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: appointments; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.appointments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    appointment_number character varying(50) NOT NULL,
    patient_id uuid NOT NULL,
    dentist_id uuid NOT NULL,
    appointment_date date NOT NULL,
    appointment_time time without time zone NOT NULL,
    duration_minutes integer DEFAULT 30,
    status character varying(50) DEFAULT 'scheduled'::character varying,
    treatment_type character varying(100),
    treatment_description text,
    notes text,
    price numeric(10,2),
    paid boolean DEFAULT false,
    payment_method character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);


ALTER TABLE public.appointments OWNER TO ceramix_user;

--
-- Name: calendar_settings; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.calendar_settings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    setting_key character varying(100) NOT NULL,
    setting_value text,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.calendar_settings OWNER TO ceramix_user;

--
-- Name: day_doctor_assignments; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.day_doctor_assignments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    appointment_date date NOT NULL,
    dentist_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.day_doctor_assignments OWNER TO ceramix_user;

--
-- Name: day_doctors; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.day_doctors (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    date date NOT NULL,
    dentist_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    start_time time without time zone,
    end_time time without time zone
);


ALTER TABLE public.day_doctors OWNER TO ceramix_user;

--
-- Name: dental_chart_custom_entries; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.dental_chart_custom_entries (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    visit_id uuid,
    patient_id uuid NOT NULL,
    tooth_number integer NOT NULL,
    custom_text text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid,
    CONSTRAINT dental_chart_custom_entries_tooth_number_check CHECK (((tooth_number >= 11) AND (tooth_number <= 48)))
);


ALTER TABLE public.dental_chart_custom_entries OWNER TO ceramix_user;

--
-- Name: dental_chart_entries; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.dental_chart_entries (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    visit_id uuid,
    patient_id uuid NOT NULL,
    tooth_number integer NOT NULL,
    surface character varying(10),
    category character varying(50) NOT NULL,
    condition_type character varying(100) NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid,
    CONSTRAINT dental_chart_entries_tooth_number_check CHECK (((tooth_number >= 11) AND (tooth_number <= 48)))
);


ALTER TABLE public.dental_chart_entries OWNER TO ceramix_user;

--
-- Name: dental_visits; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.dental_visits (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    patient_id uuid NOT NULL,
    visit_date date DEFAULT CURRENT_DATE NOT NULL,
    visit_time time without time zone,
    dentist_id uuid,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);


ALTER TABLE public.dental_visits OWNER TO ceramix_user;

--
-- Name: dentists; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.dentists (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    license_number character varying(50) NOT NULL,
    user_id uuid,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(255),
    phone character varying(20),
    specialization text[],
    clinic_location character varying(50) DEFAULT 'ceramix'::character varying,
    bio text,
    hourly_rate numeric(10,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    active boolean DEFAULT true
);


ALTER TABLE public.dentists OWNER TO ceramix_user;

--
-- Name: invoice_number_seq; Type: SEQUENCE; Schema: public; Owner: ceramix_user
--

CREATE SEQUENCE public.invoice_number_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_number_seq OWNER TO ceramix_user;

--
-- Name: invoices; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.invoices (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    invoice_number character varying(50) NOT NULL,
    patient_id uuid NOT NULL,
    issue_date date DEFAULT CURRENT_DATE NOT NULL,
    due_date date NOT NULL,
    total_amount numeric(10,2) DEFAULT 0 NOT NULL,
    tax_amount numeric(10,2) DEFAULT 0,
    status character varying(50) DEFAULT 'draft'::character varying,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);


ALTER TABLE public.invoices OWNER TO ceramix_user;

--
-- Name: mfa_backup_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mfa_backup_codes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    code character varying(255) NOT NULL,
    used boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.mfa_backup_codes OWNER TO postgres;

--
-- Name: oauth_accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_accounts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    provider character varying(50) NOT NULL,
    provider_id character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    display_name character varying(255),
    avatar_url text,
    access_token text,
    refresh_token text,
    expires_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.oauth_accounts OWNER TO postgres;

--
-- Name: patient_number_seq; Type: SEQUENCE; Schema: public; Owner: ceramix_user
--

CREATE SEQUENCE public.patient_number_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.patient_number_seq OWNER TO ceramix_user;

--
-- Name: patient_profiles; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.patient_profiles (
    user_id uuid NOT NULL,
    pesel_status character varying(50),
    child_number character varying(50),
    gender character varying(20),
    nfz_branch character varying(150),
    insurance_entitlement character varying(150),
    insurance_confirmation_status character varying(50),
    insurance_additional_entitlements character varying(150),
    eku_number character varying(150),
    eu_patient_number character varying(150),
    documents_info text,
    maiden_name character varying(150),
    father_name character varying(150),
    mother_name character varying(150),
    authorized_person character varying(200),
    consent_accepted boolean DEFAULT false,
    allergies text,
    asthma boolean DEFAULT false,
    jaundice character varying(100),
    hypertension character varying(100),
    heart_diseases boolean DEFAULT false,
    kidney_diseases boolean DEFAULT false,
    diabetes boolean DEFAULT false,
    tuberculosis boolean DEFAULT false,
    rheumatic_disease boolean DEFAULT false,
    blood_clotting_disorders boolean DEFAULT false,
    hormonal_disorders boolean DEFAULT false,
    porphyria boolean DEFAULT false,
    thyroid_diseases boolean DEFAULT false,
    other_diseases text,
    current_medications text,
    treatment_consent boolean DEFAULT false,
    raw_payload jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.patient_profiles OWNER TO ceramix_user;

--
-- Name: patients; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.patients (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    patient_number character varying(50) NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(255),
    phone character varying(20),
    date_of_birth date,
    pesel character varying(11),
    address text,
    city character varying(100),
    postal_code character varying(10),
    country character varying(100) DEFAULT 'Polska'::character varying,
    notes text,
    insurance_number character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    active boolean DEFAULT true
);


ALTER TABLE public.patients OWNER TO ceramix_user;

--
-- Name: payments; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.payments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    invoice_id uuid,
    patient_id uuid NOT NULL,
    appointment_id uuid,
    amount numeric(10,2) NOT NULL,
    payment_method character varying(50) NOT NULL,
    payment_date date DEFAULT CURRENT_DATE NOT NULL,
    paid_at timestamp without time zone,
    reference_number character varying(100),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid
);


ALTER TABLE public.payments OWNER TO ceramix_user;

--
-- Name: role_groups; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.role_groups (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    role_key character varying(50) NOT NULL,
    label character varying(100) NOT NULL,
    description text,
    color_class character varying(120) DEFAULT 'bg-white/10 text-ivory-100'::character varying,
    sort_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.role_groups OWNER TO ceramix_user;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    session_token character varying(255) NOT NULL,
    refresh_token character varying(255) NOT NULL,
    session_type character varying(50) NOT NULL,
    client_info text,
    ip_address inet,
    user_agent text,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_activity timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    revoked boolean DEFAULT false
);


ALTER TABLE public.sessions OWNER TO postgres;

--
-- Name: staff_schedules; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.staff_schedules (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    staff_type character varying(20) NOT NULL,
    staff_id uuid NOT NULL,
    day_of_week integer NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    location character varying(100),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT staff_schedules_day_of_week_check CHECK (((day_of_week >= 0) AND (day_of_week <= 6))),
    CONSTRAINT staff_schedules_staff_type_check CHECK (((staff_type)::text = ANY ((ARRAY['dentist'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.staff_schedules OWNER TO ceramix_user;

--
-- Name: treatment_types; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.treatment_types (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    default_duration_minutes integer DEFAULT 30,
    default_price numeric(10,2),
    category character varying(100),
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.treatment_types OWNER TO ceramix_user;

--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    role character varying(50) NOT NULL,
    granted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    granted_by uuid
);


ALTER TABLE public.user_roles OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255),
    display_name character varying(255) NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    avatar_url text,
    timezone character varying(50) DEFAULT 'UTC'::character varying,
    preferred_language character varying(10) DEFAULT 'pl'::character varying,
    account_state character varying(50) DEFAULT 'ACTIVE'::character varying,
    active boolean DEFAULT true,
    email_verified boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_login_at timestamp without time zone,
    last_login_ip inet,
    last_login_location jsonb,
    metadata jsonb DEFAULT '{}'::jsonb,
    two_factor_enabled boolean DEFAULT false,
    two_factor_secret character varying(255)
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: verification_codes; Type: TABLE; Schema: public; Owner: ceramix_user
--

CREATE TABLE public.verification_codes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    code character varying(10) NOT NULL,
    type character varying(20) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT verification_codes_type_check CHECK (((type)::text = ANY ((ARRAY['email'::character varying, 'sms'::character varying])::text[])))
);


ALTER TABLE public.verification_codes OWNER TO ceramix_user;

--
-- Data for Name: appointments; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.appointments (id, appointment_number, patient_id, dentist_id, appointment_date, appointment_time, duration_minutes, status, treatment_type, treatment_description, notes, price, paid, payment_method, created_at, updated_at, created_by) FROM stdin;
548ff406-b4f8-4184-b1da-1e682cfc1bcc	APT-20251121-0005	00000000-0000-0000-0000-000000000004	56f4f20d-2c6a-485e-b255-be5533f571af	2025-11-21	14:30:00	120	scheduled	5c7d8749-e952-4d46-8e20-ea8d92b37617	\N	\N	\N	f	\N	2025-11-21 11:10:16.939334	2025-11-21 11:29:22.05871	00000000-0000-0000-0000-000000000001
\.


--
-- Data for Name: calendar_settings; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.calendar_settings (id, setting_key, setting_value, updated_at) FROM stdin;
13db3e35-44b4-4b22-89ca-fe3ffd92682f	working_hours_start	12:00	2025-11-20 19:44:15.3792
323ead23-3b8d-4543-9e82-44b06d45d87a	working_hours_end	11:59	2025-11-20 19:44:15.384206
\.


--
-- Data for Name: day_doctor_assignments; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.day_doctor_assignments (id, appointment_date, dentist_id, created_at) FROM stdin;
f5df8912-3a9b-4dd8-a1c4-c8c42a30203e	2025-10-25	00000000-0000-0000-0000-000000000003	2025-11-19 22:34:40.821326
1c066bdc-af7c-49bd-b0ed-c9950fb483b2	2025-11-20	00000000-0000-0000-0000-000000000003	2025-11-19 23:11:09.869976
\.


--
-- Data for Name: day_doctors; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.day_doctors (id, date, dentist_id, created_at, start_time, end_time) FROM stdin;
31026115-146e-4434-acf8-e799b84307db	2025-11-30	00000000-0000-0000-0000-000000000003	2025-11-20 01:15:59.684465	\N	\N
5356bdf4-a4d7-42e8-a007-b77da8120954	2025-11-24	00000000-0000-0000-0000-000000000003	2025-11-20 11:49:23.628391	\N	\N
3a6c33df-b021-44d7-b858-5a959b3cabe0	2025-11-20	00000000-0000-0000-0000-000000000003	2025-11-20 19:43:16.421246	\N	\N
841e6b6b-8755-4a47-87eb-d90280ec0240	2025-11-21	56f4f20d-2c6a-485e-b255-be5533f571af	2025-11-21 10:11:14.106431	00:00:00	23:59:00
\.


--
-- Data for Name: dental_chart_custom_entries; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.dental_chart_custom_entries (id, visit_id, patient_id, tooth_number, custom_text, created_at, updated_at, created_by) FROM stdin;
\.


--
-- Data for Name: dental_chart_entries; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.dental_chart_entries (id, visit_id, patient_id, tooth_number, surface, category, condition_type, notes, created_at, updated_at, created_by) FROM stdin;
641953d7-606c-437d-a583-6b8111926e86	2b6b7897-964a-4d8a-8d94-b8266f139bfe	ef7e37c7-1c95-4ddd-a698-4521ab42b4d1	17	PW	conservative	caries	\N	2025-11-22 10:38:06.077875	2025-11-22 10:38:06.077875	00000000-0000-0000-0000-000000000001
0bf787f2-b681-4f05-a3f8-a347f0276992	2b6b7897-964a-4d8a-8d94-b8266f139bfe	ef7e37c7-1c95-4ddd-a698-4521ab42b4d1	17	PW	conservative	caries	\N	2025-11-22 10:38:06.536107	2025-11-22 10:38:06.536107	00000000-0000-0000-0000-000000000001
15b31956-41bc-428f-b0b3-b475304a95e3	2b6b7897-964a-4d8a-8d94-b8266f139bfe	ef7e37c7-1c95-4ddd-a698-4521ab42b4d1	17	PZ	conservative	dressing	\N	2025-11-22 10:40:47.348446	2025-11-22 10:40:47.348446	00000000-0000-0000-0000-000000000001
\.


--
-- Data for Name: dental_visits; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.dental_visits (id, patient_id, visit_date, visit_time, dentist_id, notes, created_at, updated_at, created_by) FROM stdin;
2b6b7897-964a-4d8a-8d94-b8266f139bfe	ef7e37c7-1c95-4ddd-a698-4521ab42b4d1	2025-11-22	\N	\N	\N	2025-11-22 10:38:05.692142	2025-11-22 10:38:05.692142	00000000-0000-0000-0000-000000000001
\.


--
-- Data for Name: dentists; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.dentists (id, license_number, user_id, first_name, last_name, email, phone, specialization, clinic_location, bio, hourly_rate, created_at, updated_at, active) FROM stdin;
56f4f20d-2c6a-485e-b255-be5533f571af	AUTO-00000000	00000000-0000-0000-0000-000000000003	Piotr	Wiśniewski	lekarz@ceramix.pl	\N	\N	ceramix	\N	\N	2025-11-21 10:02:08.5672	2025-11-21 10:02:08.5672	t
\.


--
-- Data for Name: invoices; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.invoices (id, invoice_number, patient_id, issue_date, due_date, total_amount, tax_amount, status, notes, created_at, updated_at, created_by) FROM stdin;
\.


--
-- Data for Name: mfa_backup_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mfa_backup_codes (id, user_id, code, used, created_at) FROM stdin;
\.


--
-- Data for Name: oauth_accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.oauth_accounts (id, user_id, provider, provider_id, email, display_name, avatar_url, access_token, refresh_token, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: patient_profiles; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.patient_profiles (user_id, pesel_status, child_number, gender, nfz_branch, insurance_entitlement, insurance_confirmation_status, insurance_additional_entitlements, eku_number, eu_patient_number, documents_info, maiden_name, father_name, mother_name, authorized_person, consent_accepted, allergies, asthma, jaundice, hypertension, heart_diseases, kidney_diseases, diabetes, tuberculosis, rheumatic_disease, blood_clotting_disorders, hormonal_disorders, porphyria, thyroid_diseases, other_diseases, current_medications, treatment_consent, raw_payload, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: patients; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.patients (id, patient_number, first_name, last_name, email, phone, date_of_birth, pesel, address, city, postal_code, country, notes, insurance_number, created_at, updated_at, active) FROM stdin;
7f16d0e0-7348-4d50-9da0-d1befaf7d443	PAT-20251119-0001	Tulipan	Kwitnący	dlajustyny@app.pl	537 635 936	2025-11-21	92041813017	Jana Pierdole 13	Rybnik	44-200	Polska	Testowa kur	\N	2025-11-19 10:16:47.354496	2025-11-19 10:16:47.354496	t
ef7e37c7-1c95-4ddd-a698-4521ab42b4d1	PAT-20251119-0002	Jan	Pierdole	jan.piedo@app.pl	536423657	2025-11-03	92041813046	Jana Pirdole 13	Rukasz	35-200	Polska	\N	\N	2025-11-19 10:26:09.421702	2025-11-19 10:26:09.421702	t
00000000-0000-0000-0000-000000000004	PAT-DEV-0001	Jan	Pacjent	user@ceramix.pl	500-000-000	\N	\N	\N	\N	\N	Polska	\N	\N	2025-11-21 11:08:20.545051	2025-11-21 11:08:20.545051	t
798689b7-2ad6-4de6-94fe-e767a0de6792	PAT-DEV-0002	Jan	Pacjent	user@ceramix.pl	500-000-000	\N	\N	\N	\N	\N	Polska	\N	\N	2025-11-21 11:08:44.087871	2025-11-21 11:08:44.087871	t
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.payments (id, invoice_id, patient_id, appointment_id, amount, payment_method, payment_date, paid_at, reference_number, notes, created_at, created_by) FROM stdin;
\.


--
-- Data for Name: role_groups; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.role_groups (id, role_key, label, description, color_class, sort_order, created_at, updated_at) FROM stdin;
1d41d78f-73d2-410c-9b0e-4c2c72c38ae6	user	Pacjent	Standardowy dostęp pacjenta	bg-white/10 text-ivory-100	10	2025-11-20 12:44:29.130526	2025-11-23 23:16:18.620141
70ea3e5c-b82e-4621-a3a1-c8d840355100	dentist	Lekarz	Dostęp do widoków gabinetu	bg-green-500/20 text-green-400	20	2025-11-20 12:44:29.130607	2025-11-23 23:16:18.620215
49b77ced-4d75-40df-a2a6-f660b88ee154	admin	Administrator	Zarządzanie placówką	bg-blue-500/20 text-blue-400	30	2025-11-20 12:44:29.142075	2025-11-23 23:16:18.620295
419d14c9-a226-490b-b3d0-d2b59b52f555	superadmin	Superadministrator	Pełny dostęp i kontrola ról	bg-purple-500/20 text-purple-400	40	2025-11-20 12:44:29.142535	2025-11-23 23:16:18.62037
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sessions (id, user_id, session_token, refresh_token, session_type, client_info, ip_address, user_agent, expires_at, created_at, last_activity, revoked) FROM stdin;
1e2657fc-c055-4aeb-aaa3-33207b8d1749	00000000-0000-0000-0000-000000000001	0f193a74743c11a5d78a214e08eacc5dff854a71d45f4af54e302cb4300a087f	c237d111407eb4a27cbd4162087416087318b58f6387c5ddb4bb0a3d8aadae0f	web	\N	\N	\N	2025-12-18 14:52:08.645	2025-11-18 13:52:08.646216	2025-11-18 13:52:08.646216	f
aaebbad3-76a7-4e56-bfce-5fccc908468d	00000000-0000-0000-0000-000000000001	b15748738520afa671c1530238688d4fdf4c48bbc6895e7a3ec9ac81be848635	c0cb3e0fe5f2f0d14bb00a4b43ef286aa11ff14126f41a65a813540cdc31b0f3	web	\N	\N	\N	2025-11-19 23:59:59.999	2025-11-19 15:44:40.730293	2025-11-19 15:49:51.563381	t
3db8c071-6f4e-4c88-93d9-b99487f0f26b	00000000-0000-0000-0000-000000000001	37bf947f1a1895e7241773b6effc36aab56eb3f74573266e810f2c8d9c634cf5	2e0f49688365e74cdc622b098097263d0a02d8dc908890814160221afd8a1c4c	web	\N	\N	\N	2025-11-24 23:59:59.999	2025-11-23 23:00:45.231704	2025-11-23 23:22:52.493258	f
30b7226a-7239-4894-b10d-07902096ff64	00000000-0000-0000-0000-000000000001	2f3f8f355ce3620308308988f15bf0f6cf7fc4a70dc4be9a48b34b76b9683233	e3e9476e207b3a143a9a31d30ed9b05b66fbdbbf475a24f1d4a7010ad14b6564	web	\N	\N	\N	2025-11-22 23:59:59.999	2025-11-22 09:22:30.344632	2025-11-22 21:39:32.565438	f
9335cad9-241f-4542-91df-62d381cbbab1	00000000-0000-0000-0000-000000000001	6a1a42aa625bfd9866d2bff4d4a4b0405653946cafc91a96e76d76b32818f1c5	f4e63eeb1eba04b114acd10ba86ec2d3b21b3c786bad3f531c5ebf6e2ab41f16	web	\N	\N	\N	2025-12-18 18:34:38.217	2025-11-18 17:34:38.217707	2025-11-18 17:35:38.757114	t
815c5c0c-77b8-404f-9764-a9438e84c4e9	00000000-0000-0000-0000-000000000001	46ce745017c36b6e100f3a4609dd68d7c3f9fee514007039fa1b7449cb88d1dd	ae0e7b691f2fa6808c3ff502665445250b0dad896200675045320ba3079c9af2	web	\N	\N	\N	2025-11-19 23:59:59.999	2025-11-19 15:50:53.522995	2025-11-19 15:55:59.40326	t
55e4f421-ed95-4324-ae17-318615cc99ba	00000000-0000-0000-0000-000000000001	2662cb0e7ec2eeb931f5931ce5b01762b20a1cf4d726681487afd274bac7e931	00673a171bb0b6a659a8d54550cbaf28dcb336a57b94f3da4c6136268ee49b7b	web	\N	\N	\N	2025-11-23 23:59:59.999	2025-11-23 09:37:34.684386	2025-11-23 22:59:33.528177	f
a295995b-111c-4f70-95c4-21cd9690720b	00000000-0000-0000-0000-000000000001	0d9e2f2d850b45e5eeb3a08affbc5425634289434d734c4a48a57eea5fad168c	dd3f3f9aaa8d1dcb22449c2d1c1f90e316daee2a4d669c50df12d3675184ffdf	web	\N	\N	\N	2025-11-19 23:59:59.999	2025-11-19 10:13:57.762582	2025-11-19 15:40:12.030558	t
66464e42-1fd9-48c5-8a79-68ab5430e12c	00000000-0000-0000-0000-000000000001	1e7f8cf8496333edaa9de38777d20f19a6f81b881d317b1c4f2036ce83aa8e09	aba14f6aa21a8b01e43b100abd07974a652858cbcb3729eda2f013264f9f7bf5	web	\N	\N	\N	2025-11-20 23:59:59.999	2025-11-19 23:03:22.584598	2025-11-20 22:31:07.297831	f
d9c7d63c-4ba1-442b-bc07-7ce3e025927b	00000000-0000-0000-0000-000000000001	ad05d80de2040a3ab7b26b1651d6635d8458c0446fd32c637a4fadf47b2ab9ee	32d9e174373bc06181b72a7e5427ab63864e634432cc2061b7906f3e8a849ba8	web	\N	\N	\N	2025-12-18 15:00:19.859	2025-11-18 14:00:19.859678	2025-11-18 17:25:33.751258	t
859c8fca-7f9f-4424-88e7-612dc069e7c3	00000000-0000-0000-0000-000000000001	fb274cb12ab3f90f8105893014f3d3d5eace71356178520bc12d702745373bc4	c51798910f5987dce2c6fe452d0a0130464284ab809c15ead0e4758b24094339	web	\N	\N	\N	2025-11-19 23:59:59.999	2025-11-19 16:03:19.979244	2025-11-19 16:09:22.45876	t
2c36f23b-b465-400e-83af-d84abac10c24	00000000-0000-0000-0000-000000000001	820cd87844b5dc316cbd02f6bbcab8770bab1d264b9749c3a7de4ce0d01d1140	5f442b7bdbc37ab061923d13dbf802d9f6a8b390f205ceba9165d473d9669f39	web	\N	\N	\N	2025-11-19 23:59:59.999	2025-11-19 16:13:19.582481	2025-11-19 22:59:42.486993	f
bea43bc5-58c9-4372-89a9-e2098c462f07	00000000-0000-0000-0000-000000000001	b182f830f2c3f0108d88d34d3a9bbcf4ae386c0d4bfad751fc73f005b99839a0	58fae803837e8577b404e81ddd8943ecc0244220f0aa61bde0feb0de0891c53c	web	\N	\N	\N	2025-11-21 23:59:59.999	2025-11-21 10:01:30.074402	2025-11-21 20:30:31.054683	f
\.


--
-- Data for Name: staff_schedules; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.staff_schedules (id, staff_type, staff_id, day_of_week, start_time, end_time, location, notes, created_at) FROM stdin;
\.


--
-- Data for Name: treatment_types; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.treatment_types (id, code, name, description, default_duration_minutes, default_price, category, active, created_at) FROM stdin;
de0d511a-85bf-43e1-a079-89aab0e38365	KONSULTACJA	Konsultacja	Wstępna konsultacja stomatologiczna	30	200.00	zachowawcza	t	2025-11-18 15:08:45.210987
1837c6df-b8fd-496a-bddf-844a765dcd14	CZYSZCZENIE	Czyszczenie zębów	Profesjonalne czyszczenie i piaskowanie	45	150.00	zachowawcza	t	2025-11-18 15:08:45.210987
0e5c79c8-3bcb-401b-a970-97c094cf9d64	PLOMBA	Plomba	Wypełnienie ubytku	60	300.00	zachowawcza	t	2025-11-18 15:08:45.210987
5c7d8749-e952-4d46-8e20-ea8d92b37617	KORONA	Korona ceramiczna	Korona protetyczna	120	2000.00	protetyka	t	2025-11-18 15:08:45.210987
0457d66d-97c9-4df1-aa8d-cbbaa1d5666d	IMPLANT	Implant zębowy	Wszczepienie implantu	180	5000.00	implantologia	t	2025-11-18 15:08:45.210987
50766b9a-a5c9-4afb-a3ed-9f22cb06f4a1	WYBIELANIE	Wybielanie zębów	Zabieg wybielania	90	1500.00	zachowawcza	t	2025-11-18 15:08:45.210987
57227a99-7e74-4bdc-96d6-85120b7b01a9	APARAT	Aparat ortodontyczny	Konsultacja i założenie aparatu	60	3000.00	ortodoncja	t	2025-11-18 15:08:45.210987
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (id, user_id, role, granted_at, granted_by) FROM stdin;
b77dd521-be23-433e-a776-432c419f57eb	00000000-0000-0000-0000-000000000001	superadmin	2025-11-18 12:39:12.706394	\N
35a5159e-d483-4386-ab0f-bc79519d8f5c	00000000-0000-0000-0000-000000000002	admin	2025-11-18 12:39:12.716779	\N
5787d354-4677-430b-a0a9-0022b4e7c2dd	00000000-0000-0000-0000-000000000003	dentist	2025-11-18 12:39:12.722728	\N
cbfd8230-46ff-44d9-adb6-d054f465ca68	00000000-0000-0000-0000-000000000004	user	2025-11-20 12:54:04.538332	00000000-0000-0000-0000-000000000001
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password_hash, display_name, first_name, last_name, avatar_url, timezone, preferred_language, account_state, active, email_verified, created_at, updated_at, last_login_at, last_login_ip, last_login_location, metadata, two_factor_enabled, two_factor_secret) FROM stdin;
00000000-0000-0000-0000-000000000002	admin@ceramix.pl	$2a$12$tCe.gmoxU.a36oR5XGvj7eCr/r.xXLcBlHI7LW2NnywdyedcNh5su	Administrator	Anna	Nowak	\N	UTC	pl	ACTIVE	t	t	2025-11-18 12:39:12.712924	2025-11-18 13:33:32.453419	\N	\N	\N	{}	f	\N
00000000-0000-0000-0000-000000000003	lekarz@ceramix.pl	$2a$12$tCe.gmoxU.a36oR5XGvj7eCr/r.xXLcBlHI7LW2NnywdyedcNh5su	Dr. Piotr Wiśniewski	Piotr	Wiśniewski	\N	UTC	pl	ACTIVE	t	t	2025-11-18 12:39:12.720593	2025-11-18 13:33:32.453419	\N	\N	\N	{}	f	\N
00000000-0000-0000-0000-000000000004	user@ceramix.pl	$2a$12$tCe.gmoxU.a36oR5XGvj7eCr/r.xXLcBlHI7LW2NnywdyedcNh5su	Jan Pacjent	Jan	Pacjent	\N	UTC	pl	ACTIVE	t	t	2025-11-18 12:39:12.725025	2025-11-20 22:16:20.714167	\N	\N	\N	{}	f	\N
00000000-0000-0000-0000-000000000001	superadmin@ceramix.pl	$2a$12$tCe.gmoxU.a36oR5XGvj7eCr/r.xXLcBlHI7LW2NnywdyedcNh5su	Super Administrator	Jan	Kowalski	\N	UTC	pl	ACTIVE	t	t	2025-11-18 12:39:12.699392	2025-11-23 23:00:45.239662	2025-11-23 23:00:45.239662	\N	\N	{}	f	\N
\.


--
-- Data for Name: verification_codes; Type: TABLE DATA; Schema: public; Owner: ceramix_user
--

COPY public.verification_codes (id, user_id, code, type, expires_at, created_at) FROM stdin;
\.


--
-- Name: appointment_number_seq; Type: SEQUENCE SET; Schema: public; Owner: ceramix_user
--

SELECT pg_catalog.setval('public.appointment_number_seq', 5, true);


--
-- Name: invoice_number_seq; Type: SEQUENCE SET; Schema: public; Owner: ceramix_user
--

SELECT pg_catalog.setval('public.invoice_number_seq', 1, false);


--
-- Name: patient_number_seq; Type: SEQUENCE SET; Schema: public; Owner: ceramix_user
--

SELECT pg_catalog.setval('public.patient_number_seq', 2, true);


--
-- Name: appointments appointments_appointment_number_key; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_appointment_number_key UNIQUE (appointment_number);


--
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- Name: calendar_settings calendar_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.calendar_settings
    ADD CONSTRAINT calendar_settings_pkey PRIMARY KEY (id);


--
-- Name: calendar_settings calendar_settings_setting_key_key; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.calendar_settings
    ADD CONSTRAINT calendar_settings_setting_key_key UNIQUE (setting_key);


--
-- Name: day_doctor_assignments day_doctor_assignments_appointment_date_dentist_id_key; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.day_doctor_assignments
    ADD CONSTRAINT day_doctor_assignments_appointment_date_dentist_id_key UNIQUE (appointment_date, dentist_id);


--
-- Name: day_doctor_assignments day_doctor_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.day_doctor_assignments
    ADD CONSTRAINT day_doctor_assignments_pkey PRIMARY KEY (id);


--
-- Name: day_doctors day_doctors_date_dentist_id_key; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.day_doctors
    ADD CONSTRAINT day_doctors_date_dentist_id_key UNIQUE (date, dentist_id);


--
-- Name: day_doctors day_doctors_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.day_doctors
    ADD CONSTRAINT day_doctors_pkey PRIMARY KEY (id);


--
-- Name: dental_chart_custom_entries dental_chart_custom_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.dental_chart_custom_entries
    ADD CONSTRAINT dental_chart_custom_entries_pkey PRIMARY KEY (id);


--
-- Name: dental_chart_entries dental_chart_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.dental_chart_entries
    ADD CONSTRAINT dental_chart_entries_pkey PRIMARY KEY (id);


--
-- Name: dental_visits dental_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.dental_visits
    ADD CONSTRAINT dental_visits_pkey PRIMARY KEY (id);


--
-- Name: dentists dentists_license_number_key; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.dentists
    ADD CONSTRAINT dentists_license_number_key UNIQUE (license_number);


--
-- Name: dentists dentists_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.dentists
    ADD CONSTRAINT dentists_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_invoice_number_key; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_invoice_number_key UNIQUE (invoice_number);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: mfa_backup_codes mfa_backup_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mfa_backup_codes
    ADD CONSTRAINT mfa_backup_codes_pkey PRIMARY KEY (id);


--
-- Name: mfa_backup_codes mfa_backup_codes_user_id_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mfa_backup_codes
    ADD CONSTRAINT mfa_backup_codes_user_id_code_key UNIQUE (user_id, code);


--
-- Name: oauth_accounts oauth_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_accounts
    ADD CONSTRAINT oauth_accounts_pkey PRIMARY KEY (id);


--
-- Name: oauth_accounts oauth_accounts_provider_provider_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_accounts
    ADD CONSTRAINT oauth_accounts_provider_provider_id_key UNIQUE (provider, provider_id);


--
-- Name: patient_profiles patient_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.patient_profiles
    ADD CONSTRAINT patient_profiles_pkey PRIMARY KEY (user_id);


--
-- Name: patients patients_patient_number_key; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_patient_number_key UNIQUE (patient_number);


--
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: role_groups role_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.role_groups
    ADD CONSTRAINT role_groups_pkey PRIMARY KEY (id);


--
-- Name: role_groups role_groups_role_key_key; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.role_groups
    ADD CONSTRAINT role_groups_role_key_key UNIQUE (role_key);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_refresh_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_refresh_token_key UNIQUE (refresh_token);


--
-- Name: sessions sessions_session_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_session_token_key UNIQUE (session_token);


--
-- Name: staff_schedules staff_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.staff_schedules
    ADD CONSTRAINT staff_schedules_pkey PRIMARY KEY (id);


--
-- Name: treatment_types treatment_types_code_key; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.treatment_types
    ADD CONSTRAINT treatment_types_code_key UNIQUE (code);


--
-- Name: treatment_types treatment_types_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.treatment_types
    ADD CONSTRAINT treatment_types_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_user_id_role_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_role_key UNIQUE (user_id, role);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: verification_codes verification_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.verification_codes
    ADD CONSTRAINT verification_codes_pkey PRIMARY KEY (id);


--
-- Name: verification_codes verification_codes_user_id_type_key; Type: CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.verification_codes
    ADD CONSTRAINT verification_codes_user_id_type_key UNIQUE (user_id, type);


--
-- Name: idx_appointments_date; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_appointments_date ON public.appointments USING btree (appointment_date);


--
-- Name: idx_appointments_dentist; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_appointments_dentist ON public.appointments USING btree (dentist_id);


--
-- Name: idx_appointments_number; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_appointments_number ON public.appointments USING btree (appointment_number);


--
-- Name: idx_appointments_patient; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_appointments_patient ON public.appointments USING btree (patient_id);


--
-- Name: idx_appointments_status; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_appointments_status ON public.appointments USING btree (status);


--
-- Name: idx_day_doctor_assignments_date; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_day_doctor_assignments_date ON public.day_doctor_assignments USING btree (appointment_date);


--
-- Name: idx_day_doctor_assignments_dentist; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_day_doctor_assignments_dentist ON public.day_doctor_assignments USING btree (dentist_id);


--
-- Name: idx_day_doctors_date; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_day_doctors_date ON public.day_doctors USING btree (date);


--
-- Name: idx_day_doctors_dentist_id; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_day_doctors_dentist_id ON public.day_doctors USING btree (dentist_id);


--
-- Name: idx_dental_chart_custom_patient; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_dental_chart_custom_patient ON public.dental_chart_custom_entries USING btree (patient_id);


--
-- Name: idx_dental_chart_custom_tooth; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_dental_chart_custom_tooth ON public.dental_chart_custom_entries USING btree (tooth_number);


--
-- Name: idx_dental_chart_custom_visit; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_dental_chart_custom_visit ON public.dental_chart_custom_entries USING btree (visit_id);


--
-- Name: idx_dental_chart_entries_patient; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_dental_chart_entries_patient ON public.dental_chart_entries USING btree (patient_id);


--
-- Name: idx_dental_chart_entries_tooth; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_dental_chart_entries_tooth ON public.dental_chart_entries USING btree (tooth_number);


--
-- Name: idx_dental_chart_entries_visit; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_dental_chart_entries_visit ON public.dental_chart_entries USING btree (visit_id);


--
-- Name: idx_dental_visits_date; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_dental_visits_date ON public.dental_visits USING btree (visit_date);


--
-- Name: idx_dental_visits_patient; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_dental_visits_patient ON public.dental_visits USING btree (patient_id);


--
-- Name: idx_dentists_license; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_dentists_license ON public.dentists USING btree (license_number);


--
-- Name: idx_dentists_user_id; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_dentists_user_id ON public.dentists USING btree (user_id);


--
-- Name: idx_invoices_issue_date; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_invoices_issue_date ON public.invoices USING btree (issue_date);


--
-- Name: idx_invoices_number; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_invoices_number ON public.invoices USING btree (invoice_number);


--
-- Name: idx_invoices_patient; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_invoices_patient ON public.invoices USING btree (patient_id);


--
-- Name: idx_invoices_status; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_invoices_status ON public.invoices USING btree (status);


--
-- Name: idx_mfa_backup_codes_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mfa_backup_codes_user_id ON public.mfa_backup_codes USING btree (user_id);


--
-- Name: idx_oauth_accounts_provider; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_oauth_accounts_provider ON public.oauth_accounts USING btree (provider, provider_id);


--
-- Name: idx_oauth_accounts_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_oauth_accounts_user_id ON public.oauth_accounts USING btree (user_id);


--
-- Name: idx_patient_profiles_user_id; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_patient_profiles_user_id ON public.patient_profiles USING btree (user_id);


--
-- Name: idx_patients_email; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_patients_email ON public.patients USING btree (email);


--
-- Name: idx_patients_patient_number; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_patients_patient_number ON public.patients USING btree (patient_number);


--
-- Name: idx_patients_phone; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_patients_phone ON public.patients USING btree (phone);


--
-- Name: idx_payments_date; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_payments_date ON public.payments USING btree (payment_date);


--
-- Name: idx_payments_invoice; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_payments_invoice ON public.payments USING btree (invoice_id);


--
-- Name: idx_payments_paid_at; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_payments_paid_at ON public.payments USING btree (paid_at);


--
-- Name: idx_payments_patient; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_payments_patient ON public.payments USING btree (patient_id);


--
-- Name: idx_role_groups_role_key; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE UNIQUE INDEX idx_role_groups_role_key ON public.role_groups USING btree (role_key);


--
-- Name: idx_sessions_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_expires ON public.sessions USING btree (expires_at);


--
-- Name: idx_sessions_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_token ON public.sessions USING btree (session_token);


--
-- Name: idx_sessions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_user_id ON public.sessions USING btree (user_id);


--
-- Name: idx_staff_schedules_staff_id; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_staff_schedules_staff_id ON public.staff_schedules USING btree (staff_id);


--
-- Name: idx_users_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_active ON public.users USING btree (active);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_verification_codes_expires_at; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_verification_codes_expires_at ON public.verification_codes USING btree (expires_at);


--
-- Name: idx_verification_codes_user_id; Type: INDEX; Schema: public; Owner: ceramix_user
--

CREATE INDEX idx_verification_codes_user_id ON public.verification_codes USING btree (user_id);


--
-- Name: appointments generate_appointment_number_trigger; Type: TRIGGER; Schema: public; Owner: ceramix_user
--

CREATE TRIGGER generate_appointment_number_trigger BEFORE INSERT ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.generate_appointment_number();


--
-- Name: invoices generate_invoice_number_trigger; Type: TRIGGER; Schema: public; Owner: ceramix_user
--

CREATE TRIGGER generate_invoice_number_trigger BEFORE INSERT ON public.invoices FOR EACH ROW EXECUTE FUNCTION public.generate_invoice_number();


--
-- Name: patients generate_patient_number_trigger; Type: TRIGGER; Schema: public; Owner: ceramix_user
--

CREATE TRIGGER generate_patient_number_trigger BEFORE INSERT ON public.patients FOR EACH ROW EXECUTE FUNCTION public.generate_patient_number();


--
-- Name: appointments update_appointments_updated_at; Type: TRIGGER; Schema: public; Owner: ceramix_user
--

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: dentists update_dentists_updated_at; Type: TRIGGER; Schema: public; Owner: ceramix_user
--

CREATE TRIGGER update_dentists_updated_at BEFORE UPDATE ON public.dentists FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: invoices update_invoices_updated_at; Type: TRIGGER; Schema: public; Owner: ceramix_user
--

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: oauth_accounts update_oauth_accounts_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_oauth_accounts_updated_at BEFORE UPDATE ON public.oauth_accounts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: patients update_patients_updated_at; Type: TRIGGER; Schema: public; Owner: ceramix_user
--

CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON public.patients FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: appointments appointments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: appointments appointments_dentist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_dentist_id_fkey FOREIGN KEY (dentist_id) REFERENCES public.dentists(id) ON DELETE CASCADE;


--
-- Name: appointments appointments_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: dental_chart_custom_entries dental_chart_custom_entries_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.dental_chart_custom_entries
    ADD CONSTRAINT dental_chart_custom_entries_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: dental_chart_custom_entries dental_chart_custom_entries_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.dental_chart_custom_entries
    ADD CONSTRAINT dental_chart_custom_entries_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.dental_visits(id) ON DELETE CASCADE;


--
-- Name: dental_chart_entries dental_chart_entries_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.dental_chart_entries
    ADD CONSTRAINT dental_chart_entries_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: dental_chart_entries dental_chart_entries_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.dental_chart_entries
    ADD CONSTRAINT dental_chart_entries_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.dental_visits(id) ON DELETE CASCADE;


--
-- Name: dental_visits dental_visits_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.dental_visits
    ADD CONSTRAINT dental_visits_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: dental_visits dental_visits_dentist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.dental_visits
    ADD CONSTRAINT dental_visits_dentist_id_fkey FOREIGN KEY (dentist_id) REFERENCES public.dentists(id);


--
-- Name: dentists dentists_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.dentists
    ADD CONSTRAINT dentists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: invoices invoices_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: invoices invoices_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: mfa_backup_codes mfa_backup_codes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mfa_backup_codes
    ADD CONSTRAINT mfa_backup_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: oauth_accounts oauth_accounts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_accounts
    ADD CONSTRAINT oauth_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: payments payments_appointment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE SET NULL;


--
-- Name: payments payments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: payments payments_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(id) ON DELETE SET NULL;


--
-- Name: payments payments_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id);


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: verification_codes verification_codes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ceramix_user
--

ALTER TABLE ONLY public.verification_codes
    ADD CONSTRAINT verification_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO ceramix_user;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea) TO ceramix_user;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea, text[], text[]) TO ceramix_user;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.crypt(text, text) TO ceramix_user;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dearmor(text) TO ceramix_user;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt(bytea, bytea, text) TO ceramix_user;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt_iv(bytea, bytea, bytea, text) TO ceramix_user;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(bytea, text) TO ceramix_user;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(text, text) TO ceramix_user;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt(bytea, bytea, text) TO ceramix_user;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt_iv(bytea, bytea, bytea, text) TO ceramix_user;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_bytes(integer) TO ceramix_user;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_uuid() TO ceramix_user;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text) TO ceramix_user;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text, integer) TO ceramix_user;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(bytea, bytea, text) TO ceramix_user;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(text, text, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_armor_headers(text, OUT key text, OUT value text) TO ceramix_user;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_key_id(bytea) TO ceramix_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea) TO ceramix_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea) TO ceramix_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea) TO ceramix_user;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea) TO ceramix_user;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text) TO ceramix_user;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text, text) TO ceramix_user;


--
-- Name: FUNCTION update_updated_at_column(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_updated_at_column() TO ceramix_user;


--
-- Name: FUNCTION uuid_generate_v1(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v1() TO ceramix_user;


--
-- Name: FUNCTION uuid_generate_v1mc(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v1mc() TO ceramix_user;


--
-- Name: FUNCTION uuid_generate_v3(namespace uuid, name text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v3(namespace uuid, name text) TO ceramix_user;


--
-- Name: FUNCTION uuid_generate_v4(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v4() TO ceramix_user;


--
-- Name: FUNCTION uuid_generate_v5(namespace uuid, name text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v5(namespace uuid, name text) TO ceramix_user;


--
-- Name: FUNCTION uuid_nil(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_nil() TO ceramix_user;


--
-- Name: FUNCTION uuid_ns_dns(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_ns_dns() TO ceramix_user;


--
-- Name: FUNCTION uuid_ns_oid(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_ns_oid() TO ceramix_user;


--
-- Name: FUNCTION uuid_ns_url(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_ns_url() TO ceramix_user;


--
-- Name: FUNCTION uuid_ns_x500(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_ns_x500() TO ceramix_user;


--
-- Name: TABLE mfa_backup_codes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.mfa_backup_codes TO ceramix_user;


--
-- Name: TABLE oauth_accounts; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.oauth_accounts TO ceramix_user;


--
-- Name: TABLE sessions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.sessions TO ceramix_user;


--
-- Name: TABLE user_roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_roles TO ceramix_user;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.users TO ceramix_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO ceramix_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO ceramix_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO ceramix_user;


--
-- PostgreSQL database dump complete
--

\unrestrict mr2ZrFJiAgGpMVnHxUMGGyCpQ2J0ksvI8hrmmtGNWBbp5QwsVB3cfiHDdTtemgN

