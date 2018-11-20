--
-- PostgreSQL database dump
--

-- Dumped from database version 11.1
-- Dumped by pg_dump version 11.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: stb; Type: DATABASE; Schema: -; Owner: _developer
--

CREATE DATABASE stb WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'C' LC_CTYPE = 'C';


ALTER DATABASE stb OWNER TO _developer;

\connect stb

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: infra; Type: SCHEMA; Schema: -; Owner: _developer
--

CREATE SCHEMA infra;


ALTER SCHEMA infra OWNER TO _developer;

--
-- Name: translate; Type: SCHEMA; Schema: -; Owner: _developer
--

CREATE SCHEMA translate;


ALTER SCHEMA translate OWNER TO _developer;

--
-- Name: sysreferenceorg_seq; Type: SEQUENCE; Schema: infra; Owner: _developer
--

CREATE SEQUENCE infra.sysreferenceorg_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE infra.sysreferenceorg_seq OWNER TO _developer;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: sysreferenceorg; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.sysreferenceorg (
    rfo_seq bigint DEFAULT nextval('infra.sysreferenceorg_seq'::regclass) NOT NULL,
    rfo_class character varying(15) NOT NULL,
    rfo_value character varying(15) NOT NULL,
    rfo_desc character varying(100) NOT NULL,
    rfo_order smallint,
    rfo_active smallint,
    rfo_char text,
    rfo_int bigint,
    rfo_number double precision,
    rfo_date date,
    rfo_bin bytea,
    rfo_time time without time zone,
    rfo_effective date,
    rfo_expires date,
    rfo_json jsonb,
    rfo_go_ref bigint NOT NULL,
    rfo_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    rfo_cby character varying(15) NOT NULL,
    rfo_mwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    rfo_mby character varying(15) NOT NULL,
    rfo_mcount integer DEFAULT 0 NOT NULL,
    rfo_inherit smallint DEFAULT 0 NOT NULL
);


ALTER TABLE infra.sysreferenceorg OWNER TO _developer;

--
-- Name: COLUMN sysreferenceorg.rfo_seq; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceorg.rfo_seq IS 'primary key';


--
-- Name: COLUMN sysreferenceorg.rfo_class; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceorg.rfo_class IS 'classification column';


--
-- Name: COLUMN sysreferenceorg.rfo_value; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceorg.rfo_value IS 'specific reference value';


--
-- Name: COLUMN sysreferenceorg.rfo_desc; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceorg.rfo_desc IS 'description';


--
-- Name: COLUMN sysreferenceorg.rfo_order; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceorg.rfo_order IS 'ordering column';


--
-- Name: COLUMN sysreferenceorg.rfo_active; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceorg.rfo_active IS '1 means an active lookup/reference entry';


--
-- Name: COLUMN sysreferenceorg.rfo_char; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceorg.rfo_char IS 'big character column';


--
-- Name: COLUMN sysreferenceorg.rfo_int; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceorg.rfo_int IS 'integer value';


--
-- Name: COLUMN sysreferenceorg.rfo_number; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceorg.rfo_number IS 'floating number value';


--
-- Name: COLUMN sysreferenceorg.rfo_date; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceorg.rfo_date IS 'date column';


--
-- Name: COLUMN sysreferenceorg.rfo_bin; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceorg.rfo_bin IS 'binary value';


--
-- Name: initinherited(text, text, integer); Type: FUNCTION; Schema: infra; Owner: _developer
--

CREATE FUNCTION infra.initinherited(pclass text, pvalue text DEFAULT ''::text, pgoref integer DEFAULT 0) RETURNS SETOF infra.sysreferenceorg
    LANGUAGE plpgsql
    AS $_$
/*******************************************************************************************
Purpose:    to offer the functionality of Omnis oValues.$initInherited returning one row
Created:    2016-08-31 Graham Stevens
Revisions:  2017-06-08 GRS reworked to return a full set of records for pClass when pValue is empty
            2018-01-29 GRS bug fix: added rfo_active to the order by clause 
                                    added check for pValue is null
            2018-02-08 GRS added to include/exclude records according to rfo/rfl_inherit
            2018-08-16 GRS reverted the rfo_inherit change above
			2018-08-17 GRS properly (I hpoe) incorporated xxx_inherit
			2018-08-20 GRS fixed: rows were missing when rfo_active = 1 but rfg_active = 0 
*******************************************************************************************/
declare
    rfoRow  infra.sysreferenceorg%rowtype;
    
begin
    if pClass is null or pClass = '' then
        raise invalid_parameter_value using message = 'Class must have a value';
    end if;
    
    
    if pValue = '' or pValue is null then
    	for rfoRow in
			-- select all relevant columns from the result set
			-- for the first row only in each partition
			-- ignoring inactive records
			select rfo_seq, rfo_class, rfo_value, rfo_desc, rfo_order, rfo_active, rfo_char, rfo_int, rfo_number, rfo_date, rfo_bin, rfo_time, rfo_effective, rfo_expires, rfo_json
			from
			(
			-- partition the results by class and value ordering each partition by its _active value desc and priority
			-- and numbering each row
			select *, row_number()
			over (partition by rfo_class, rfo_value order by rfo_active, priority)
			from
			(
			-- fetch all matching rows from all tables incl. ACTIVE = 0
			-- priority is used to order the rows in the outer windowing clause
			with rfo as ( -- get all the relevant refOrg records
			select 1 as priority, rfo_seq, rfo_class, rfo_value, rfo_desc, rfo_order, rfo_active, rfo_char, rfo_int, rfo_number, rfo_date, rfo_bin, rfo_time, rfo_effective, rfo_expires, rfo_json
			from infra.sysreferenceorg rfo
			where rfo_class = pClass
			and rfo_go_ref = pgoref 
			and not (rfo_active= 0 and rfo_inherit = 1) -- inherit overrides the deactivation as though the record did not exist
			), 
			rfl as ( -- get the relevant refLocal records and override rfl_active if rfo_active = 1
			select 2, rfl_seq, rfl_class, rfl_value, rfl_desc, rfl_order
			, case when rfo_active = 1 then rfo_active else rfl_active end, rfl_char, rfl_int, rfl_number, rfl_date, rfl_bin, rfl_time, rfl_effective, rfl_expires, rfl_json
			from infra.sysreferencelocal
			left join rfo on rfo_value = rfl_value
			where rfl_class = pClass
			and not (rfl_active= 0 and rfl_inherit = 1) -- inherit overrides the deactivation as though the record did not exist
			), 
			rfg as ( --get the relevant refGlobal records and override rfg_active if rfo_active = 1 or rfl_active = 1
			select 3 as priority, rfg_seq, rfg_class, rfg_value, rfg_desc, rfg_order
			, case when rfo_active = 1 then rfo_active when rfl_active = 1 then rfl_active else rfg_active end, rfg_char, rfg_int, rfg_number, rfg_date, rfg_bin, rfg_time, rfg_effective, rfg_expires, rfg_json
			from infra.sysreferenceglobal
			left join rfl on rfl_value = rfg_value
			left join rfo on rfo_value = rfg_value
			where rfg_class = pClass
			)
			-- put all of the above together
			select * from rfo union select * from rfl union select * from rfg
			) x 
			) y
			where row_number = 1 and rfo_active = 1
		
		loop
			return next rfoRow;
		end loop;
		
	else
		for rfoRow in
			-- select all relevant columns from the result set
			-- for the first row only in each partition
			-- ignoring inactive records
            select rfo_seq, rfo_class, rfo_value, rfo_desc, rfo_order, rfo_active, rfo_char, rfo_int, rfo_number, rfo_date, rfo_bin, rfo_time, rfo_effective, rfo_expires, rfo_json
			from
			(
			-- partition the results by class and value ordering each partition by its priority
			-- priority is used to order the rows in the outer windowing clause
			select *, row_number()
			over (partition by rfo_class, rfo_value order by rfo_active, priority)
			from
			(
			-- fetch all matching rows from all tables incl. ACTIVE = 0
			-- priority is used to order the rows in the outer windowing clause
			with rfo as ( -- get all the relevant refOrg records
			select 1 as priority, rfo_seq, rfo_class, rfo_value, rfo_desc, rfo_order, rfo_active, rfo_char, rfo_int, rfo_number, rfo_date, rfo_bin, rfo_time, rfo_effective, rfo_expires, rfo_json
			from infra.sysreferenceorg rfo
			where rfo_class = pClass and rfo_value = pValue
			and rfo_go_ref = pgoref 
			and not (rfo_active= 0 and rfo_inherit = 1) -- inherit overrides the deactivation as though the record did not exist
			), 
			rfl as ( -- get the relevant refLocal records and override rfl_active if rfo_active = 1
			select 2, rfl_seq, rfl_class, rfl_value, rfl_desc, rfl_order
			, case when rfo_active = 1 then rfo_active else rfl_active end, rfl_char, rfl_int, rfl_number, rfl_date, rfl_bin, rfl_time, rfl_effective, rfl_expires, rfl_json
			from infra.sysreferencelocal
			left join rfo on rfo_value = rfl_value
			where rfl_class = pClass and rfl_value = pValue
			and not (rfl_active= 0 and rfl_inherit = 1) -- inherit overrides the deactivation as though the record did not exist
			), 
			rfg as ( --get the relevant refGlobal records and override rfg_active if rfo_active = 1 or rfl_active = 1
			select 3 as priority, rfg_seq, rfg_class, rfg_value, rfg_desc, rfg_order
			, case when rfo_active = 1 then rfo_active when rfl_active = 1 then rfl_active else rfg_active end, rfg_char, rfg_int, rfg_number, rfg_date, rfg_bin, rfg_time, rfg_effective, rfg_expires, rfg_json
			from infra.sysreferenceglobal
			left join rfl on rfl_value = rfg_value
			left join rfo on rfo_value = rfg_value
			where rfg_class = pClass and rfg_value = pValue
			)
			-- put all of the above together
			select * from rfo union select * from rfl union select * from rfg
			) x
			) y
			where row_number = 1 and rfo_active = 1

		loop
			return next rfoRow;
		end loop;
		
	end if;	
	
    return;
    
end;
$_$;


ALTER FUNCTION infra.initinherited(pclass text, pvalue text, pgoref integer) OWNER TO _developer;

--
-- Name: entgrouporganisations_seq; Type: SEQUENCE; Schema: infra; Owner: _developer
--

CREATE SEQUENCE infra.entgrouporganisations_seq
    START WITH 21
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE infra.entgrouporganisations_seq OWNER TO _developer;

--
-- Name: entgrouporganisations; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.entgrouporganisations (
    go_seq bigint DEFAULT nextval('infra.entgrouporganisations_seq'::regclass) NOT NULL,
    go_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone NOT NULL,
    go_cby character varying(15) NOT NULL,
    go_mwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone NOT NULL,
    go_mby character varying(15) NOT NULL,
    go_mcount integer DEFAULT 0 NOT NULL,
    go_name_full character varying(255),
    go_name_short character varying(10) NOT NULL,
    go_addr_building character varying(100),
    go_addr_street character varying(100),
    go_addr_locality character varying(100),
    go_addr_town character varying(100),
    go_addr_state character varying(50),
    go_addr_postcode character varying(20),
    go_addr_country character varying(50),
    go_comm_ph character varying(20),
    go_comm_mob character varying(20),
    go_comm_email character varying(100),
    go_company_no character varying(20),
    go_vat_no character varying(15),
    go_currency character varying(3),
    go_mec_id character varying(20),
    go_mec_type smallint,
    go_rrs character varying(255),
    go_ddn_ap1 character varying(255),
    go_ddn_ap2 character varying(255),
    go_surname character varying(30),
    go_firstnames character varying(60),
    go_name_ltbc character varying(15),
    go_dob date,
    go_sex character varying(1),
    go_mmn character varying(15),
    go_id_type character varying(15),
    go_id_code character varying(20),
    go_mc_listid character varying(16),
    go_report_to_go_ref integer,
    go_report_to_percent numeric(5,4) DEFAULT 0,
    CONSTRAINT go_report_to_percent_check CHECK (((go_report_to_percent >= (0)::numeric) AND (go_report_to_percent <= (1)::numeric)))
);


ALTER TABLE infra.entgrouporganisations OWNER TO _developer;

--
-- Name: COLUMN entgrouporganisations.go_seq; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.entgrouporganisations.go_seq IS 'primary key';


--
-- Name: COLUMN entgrouporganisations.go_mc_listid; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.entgrouporganisations.go_mc_listid IS 'MailChimp default list id';


--
-- Name: entgrouporgnames_seq; Type: SEQUENCE; Schema: infra; Owner: _developer
--

CREATE SEQUENCE infra.entgrouporgnames_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE infra.entgrouporgnames_seq OWNER TO _developer;

--
-- Name: entgrouporgnames; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.entgrouporgnames (
    gon_seq bigint DEFAULT nextval('infra.entgrouporgnames_seq'::regclass) NOT NULL,
    gon_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    gon_cby character varying(15) NOT NULL,
    gon_mwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    gon_mby character varying(15) NOT NULL,
    gon_mcount integer DEFAULT 0 NOT NULL,
    gon_go_ref bigint NOT NULL,
    gon_name_full character varying(255) NOT NULL,
    gon_type character varying(1),
    CONSTRAINT gon_type_chk CHECK (((gon_type IS NULL) OR ((gon_type)::text = 'I'::text) OR ((gon_type)::text = 'E'::text)))
);


ALTER TABLE infra.entgrouporgnames OWNER TO _developer;

--
-- Name: COLUMN entgrouporgnames.gon_seq; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.entgrouporgnames.gon_seq IS 'primary key';


--
-- Name: COLUMN entgrouporgnames.gon_cwhen; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.entgrouporgnames.gon_cwhen IS 'creation timestamp';


--
-- Name: COLUMN entgrouporgnames.gon_cby; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.entgrouporgnames.gon_cby IS 'created by';


--
-- Name: COLUMN entgrouporgnames.gon_mwhen; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.entgrouporgnames.gon_mwhen IS 'modification timestamp';


--
-- Name: COLUMN entgrouporgnames.gon_mby; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.entgrouporgnames.gon_mby IS 'modified by';


--
-- Name: COLUMN entgrouporgnames.gon_mcount; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.entgrouporgnames.gon_mcount IS 'modification count';


--
-- Name: COLUMN entgrouporgnames.gon_go_ref; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.entgrouporgnames.gon_go_ref IS 'foreign key to entgrouporganisations';


--
-- Name: COLUMN entgrouporgnames.gon_name_full; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.entgrouporgnames.gon_name_full IS 'organisation name in referenced language';


--
-- Name: COLUMN entgrouporgnames.gon_type; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.entgrouporgnames.gon_type IS 'I = internal use, E = default for export, null';


--
-- Name: sysasyncemails_seq; Type: SEQUENCE; Schema: infra; Owner: _developer
--

CREATE SEQUENCE infra.sysasyncemails_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE infra.sysasyncemails_seq OWNER TO _developer;

--
-- Name: sysasyncemails; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.sysasyncemails (
    ae_seq bigint DEFAULT nextval('infra.sysasyncemails_seq'::regclass) NOT NULL,
    ae_to jsonb,
    ae_subject character varying(255),
    ae_message text,
    ae_cc jsonb,
    ae_bcc jsonb,
    ae_priority smallint,
    ae_encl jsonb,
    ae_html text,
    ae_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    ae_go_ref integer,
    ae_fail_count smallint,
    ae_fail_dialogue text,
    ae_fail_status integer,
    ae_from jsonb,
    ae_extraheaders jsonb,
    ae_sendercode character varying(15)
);


ALTER TABLE infra.sysasyncemails OWNER TO _developer;

--
-- Name: COLUMN sysasyncemails.ae_seq; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysasyncemails.ae_seq IS 'primary key';


--
-- Name: COLUMN sysasyncemails.ae_to; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysasyncemails.ae_to IS 'list of email addressees';


--
-- Name: COLUMN sysasyncemails.ae_subject; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysasyncemails.ae_subject IS 'subject line of email';


--
-- Name: COLUMN sysasyncemails.ae_message; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysasyncemails.ae_message IS 'email content';


--
-- Name: COLUMN sysasyncemails.ae_cc; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysasyncemails.ae_cc IS 'list of email addressees';


--
-- Name: COLUMN sysasyncemails.ae_bcc; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysasyncemails.ae_bcc IS 'list of email addressees';


--
-- Name: COLUMN sysasyncemails.ae_priority; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysasyncemails.ae_priority IS 'priority - 0 to 3';


--
-- Name: COLUMN sysasyncemails.ae_encl; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysasyncemails.ae_encl IS 'attachments';


--
-- Name: COLUMN sysasyncemails.ae_html; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysasyncemails.ae_html IS 'HTML version of email message';


--
-- Name: COLUMN sysasyncemails.ae_cwhen; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysasyncemails.ae_cwhen IS 'creation timestamp';


--
-- Name: syslogerrors; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.syslogerrors (
    sle_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    sle_code character varying(15),
    sle_subcode character varying(15),
    sle_message character varying(1000),
    sle_vhost_ref integer,
    sle_server_ip character varying(45),
    sle_server_port integer
);


ALTER TABLE infra.syslogerrors OWNER TO _developer;

--
-- Name: COLUMN syslogerrors.sle_cwhen; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.syslogerrors.sle_cwhen IS 'creation timestamp';


--
-- Name: COLUMN syslogerrors.sle_code; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.syslogerrors.sle_code IS 'primary grouping category';


--
-- Name: COLUMN syslogerrors.sle_subcode; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.syslogerrors.sle_subcode IS 'secondary grouping category';


--
-- Name: COLUMN syslogerrors.sle_message; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.syslogerrors.sle_message IS 'message';


--
-- Name: syslogevents; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.syslogevents (
    slv_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    slv_code character varying(15),
    slv_subcode character varying(15),
    slv_message character varying(1000),
    slv_vhost_ref integer,
    slv_server_ip character varying(45),
    slv_server_port integer
);


ALTER TABLE infra.syslogevents OWNER TO _developer;

--
-- Name: COLUMN syslogevents.slv_cwhen; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.syslogevents.slv_cwhen IS 'creation timestamp';


--
-- Name: COLUMN syslogevents.slv_code; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.syslogevents.slv_code IS 'primary grouping category';


--
-- Name: COLUMN syslogevents.slv_subcode; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.syslogevents.slv_subcode IS 'secondary grouping category';


--
-- Name: COLUMN syslogevents.slv_message; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.syslogevents.slv_message IS 'message';


--
-- Name: sysreferenceglobal_seq; Type: SEQUENCE; Schema: infra; Owner: _developer
--

CREATE SEQUENCE infra.sysreferenceglobal_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE infra.sysreferenceglobal_seq OWNER TO _developer;

--
-- Name: sysreferenceglobal; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.sysreferenceglobal (
    rfg_seq bigint DEFAULT nextval('infra.sysreferenceglobal_seq'::regclass) NOT NULL,
    rfg_class character varying(15) NOT NULL,
    rfg_value character varying(15) NOT NULL,
    rfg_desc character varying(100) NOT NULL,
    rfg_order smallint,
    rfg_active smallint,
    rfg_char text,
    rfg_int bigint,
    rfg_number double precision,
    rfg_date date,
    rfg_bin bytea,
    rfg_time time without time zone,
    rfg_effective date,
    rfg_expires date,
    rfg_json jsonb,
    rfg_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    rfg_cby character varying(15) NOT NULL,
    rfg_mwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    rfg_mby character varying(15) NOT NULL,
    rfg_mcount integer DEFAULT 0 NOT NULL
);


ALTER TABLE infra.sysreferenceglobal OWNER TO _developer;

--
-- Name: COLUMN sysreferenceglobal.rfg_seq; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceglobal.rfg_seq IS 'primary key';


--
-- Name: COLUMN sysreferenceglobal.rfg_class; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceglobal.rfg_class IS 'classification column';


--
-- Name: COLUMN sysreferenceglobal.rfg_value; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceglobal.rfg_value IS 'specific reference value';


--
-- Name: COLUMN sysreferenceglobal.rfg_desc; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceglobal.rfg_desc IS 'description';


--
-- Name: COLUMN sysreferenceglobal.rfg_order; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceglobal.rfg_order IS 'ordering column';


--
-- Name: COLUMN sysreferenceglobal.rfg_active; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceglobal.rfg_active IS '1 means an active lookup/reference entry';


--
-- Name: COLUMN sysreferenceglobal.rfg_char; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceglobal.rfg_char IS 'big character column';


--
-- Name: COLUMN sysreferenceglobal.rfg_int; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceglobal.rfg_int IS 'integer value';


--
-- Name: COLUMN sysreferenceglobal.rfg_number; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceglobal.rfg_number IS 'floating number value';


--
-- Name: COLUMN sysreferenceglobal.rfg_date; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceglobal.rfg_date IS 'date column';


--
-- Name: COLUMN sysreferenceglobal.rfg_bin; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceglobal.rfg_bin IS 'binary value';


--
-- Name: sysreferencelocal_seq; Type: SEQUENCE; Schema: infra; Owner: _developer
--

CREATE SEQUENCE infra.sysreferencelocal_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE infra.sysreferencelocal_seq OWNER TO _developer;

--
-- Name: sysreferencelocal; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.sysreferencelocal (
    rfl_seq bigint DEFAULT nextval('infra.sysreferencelocal_seq'::regclass) NOT NULL,
    rfl_class character varying(15) NOT NULL,
    rfl_value character varying(15) NOT NULL,
    rfl_desc character varying(100) NOT NULL,
    rfl_order smallint,
    rfl_active smallint,
    rfl_char text,
    rfl_int bigint,
    rfl_number double precision,
    rfl_date date,
    rfl_bin bytea,
    rfl_time time without time zone,
    rfl_effective date,
    rfl_expires date,
    rfl_json jsonb,
    rfl_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    rfl_cby character varying(15) NOT NULL,
    rfl_mwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    rfl_mby character varying(15) NOT NULL,
    rfl_mcount integer DEFAULT 0 NOT NULL,
    rfl_inherit smallint DEFAULT 0 NOT NULL
);


ALTER TABLE infra.sysreferencelocal OWNER TO _developer;

--
-- Name: COLUMN sysreferencelocal.rfl_seq; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferencelocal.rfl_seq IS 'primary key';


--
-- Name: COLUMN sysreferencelocal.rfl_class; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferencelocal.rfl_class IS 'classification column';


--
-- Name: COLUMN sysreferencelocal.rfl_value; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferencelocal.rfl_value IS 'specific reference value';


--
-- Name: COLUMN sysreferencelocal.rfl_desc; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferencelocal.rfl_desc IS 'description';


--
-- Name: COLUMN sysreferencelocal.rfl_order; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferencelocal.rfl_order IS 'ordering column';


--
-- Name: COLUMN sysreferencelocal.rfl_active; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferencelocal.rfl_active IS '1 means an active lookup/reference entry';


--
-- Name: COLUMN sysreferencelocal.rfl_char; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferencelocal.rfl_char IS 'big character column';


--
-- Name: COLUMN sysreferencelocal.rfl_int; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferencelocal.rfl_int IS 'integer value';


--
-- Name: COLUMN sysreferencelocal.rfl_number; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferencelocal.rfl_number IS 'floating number value';


--
-- Name: COLUMN sysreferencelocal.rfl_date; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferencelocal.rfl_date IS 'date column';


--
-- Name: COLUMN sysreferencelocal.rfl_bin; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferencelocal.rfl_bin IS 'binary value';


--
-- Name: sysreferenceuser_seq; Type: SEQUENCE; Schema: infra; Owner: _developer
--

CREATE SEQUENCE infra.sysreferenceuser_seq
    START WITH 45
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE infra.sysreferenceuser_seq OWNER TO _developer;

--
-- Name: sysreferenceuser; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.sysreferenceuser (
    rfu_seq bigint DEFAULT nextval('infra.sysreferenceuser_seq'::regclass) NOT NULL,
    rfu_class character varying(15) NOT NULL,
    rfu_value character varying(15) NOT NULL,
    rfu_desc character varying(100) NOT NULL,
    rfu_order smallint,
    rfu_active smallint,
    rfu_char character varying(1000),
    rfu_int bigint,
    rfu_number double precision,
    rfu_date date,
    rfu_bin bytea,
    rfu_time time without time zone,
    rfu_effective date,
    rfu_expires date,
    rfu_json jsonb,
    rfu_go_ref bigint NOT NULL,
    rfu_usr_ref bigint NOT NULL,
    rfu_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    rfu_cby character varying(15) NOT NULL,
    rfu_mwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    rfu_mby character varying(15) NOT NULL,
    rfu_mcount integer DEFAULT 0 NOT NULL
);


ALTER TABLE infra.sysreferenceuser OWNER TO _developer;

--
-- Name: COLUMN sysreferenceuser.rfu_seq; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceuser.rfu_seq IS 'primary key';


--
-- Name: COLUMN sysreferenceuser.rfu_class; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceuser.rfu_class IS 'classification column';


--
-- Name: COLUMN sysreferenceuser.rfu_value; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceuser.rfu_value IS 'specific reference value';


--
-- Name: COLUMN sysreferenceuser.rfu_desc; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceuser.rfu_desc IS 'description';


--
-- Name: COLUMN sysreferenceuser.rfu_order; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceuser.rfu_order IS 'ordering column';


--
-- Name: COLUMN sysreferenceuser.rfu_active; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceuser.rfu_active IS '1 means an active lookup/reference entry';


--
-- Name: COLUMN sysreferenceuser.rfu_char; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceuser.rfu_char IS 'big character column';


--
-- Name: COLUMN sysreferenceuser.rfu_int; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceuser.rfu_int IS 'integer value';


--
-- Name: COLUMN sysreferenceuser.rfu_number; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceuser.rfu_number IS 'floating number value';


--
-- Name: COLUMN sysreferenceuser.rfu_date; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceuser.rfu_date IS 'date column';


--
-- Name: COLUMN sysreferenceuser.rfu_bin; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.sysreferenceuser.rfu_bin IS 'binary value';


--
-- Name: systaskstats_seq; Type: SEQUENCE; Schema: infra; Owner: _developer
--

CREATE SEQUENCE infra.systaskstats_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE infra.systaskstats_seq OWNER TO _developer;

--
-- Name: systaskstats; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.systaskstats (
    sts_seq bigint DEFAULT nextval('infra.systaskstats_seq'::regclass) NOT NULL,
    sts_start timestamp without time zone,
    sts_count_start smallint,
    sts_end timestamp without time zone,
    sts_count_end smallint,
    sts_last_response timestamp without time zone,
    sts_go_ref integer,
    sts_bytes_reqcursent bigint,
    sts_bytes_reqcurrecd bigint,
    sts_bytes_reqmaxsent bigint,
    sts_bytes_reqmaxrecd bigint,
    sts_bytes_reqtotsent bigint,
    sts_bytes_reqtotrecd bigint,
    sts_tot_events integer,
    sts_ula_ref integer,
    sts_ip4 character varying(16),
    sts_type character varying(1) DEFAULT 'R'::character varying NOT NULL,
    sts_db_requests integer DEFAULT 0,
    sts_fetches integer DEFAULT 0,
    sts_inserts integer DEFAULT 0,
    sts_updates integer DEFAULT 0,
    sts_deletes integer DEFAULT 0,
    sts_device_size character varying(255),
    sts_init_class character varying(100),
    sts_gl_ref bigint,
    sts_browser text,
    sts_ws_name character varying(255),
    sts_table_name character varying(50),
    sts_table_method character varying(50),
    sts_params text,
    sts_table_list text,
    CONSTRAINT sts_type_chk CHECK ((((sts_type)::text = 'F'::text) OR ((sts_type)::text = 'R'::text) OR ((sts_type)::text = 'U'::text) OR ((sts_type)::text = 'J'::text) OR ((sts_type)::text = 'S'::text) OR ((sts_type)::text = '?'::text)))
);


ALTER TABLE infra.systaskstats OWNER TO _developer;

--
-- Name: COLUMN systaskstats.sts_type; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.systaskstats.sts_type IS '(S)tartup Task, (R)emoteTask';


--
-- Name: COLUMN systaskstats.sts_db_requests; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.systaskstats.sts_db_requests IS 'total number of DB calls';


--
-- Name: COLUMN systaskstats.sts_fetches; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.systaskstats.sts_fetches IS 'total number of rows fetched from the DB';


--
-- Name: COLUMN systaskstats.sts_inserts; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.systaskstats.sts_inserts IS 'total number of rows inserted into the DB';


--
-- Name: COLUMN systaskstats.sts_updates; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.systaskstats.sts_updates IS 'total number of rows updated in the DB';


--
-- Name: COLUMN systaskstats.sts_deletes; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.systaskstats.sts_deletes IS 'total number of rows deleted from the DB';


--
-- Name: COLUMN systaskstats.sts_ws_name; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.systaskstats.sts_ws_name IS 'web service name';


--
-- Name: COLUMN systaskstats.sts_table_name; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.systaskstats.sts_table_name IS 'table class name';


--
-- Name: COLUMN systaskstats.sts_table_method; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.systaskstats.sts_table_method IS 'table class method';


--
-- Name: COLUMN systaskstats.sts_params; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.systaskstats.sts_params IS 'parameters pass to table class method in JSON format';


--
-- Name: COLUMN systaskstats.sts_table_list; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.systaskstats.sts_table_list IS 'tables accessed during REST and SOAP service calls';


--
-- Name: uagrouporglinks_seq; Type: SEQUENCE; Schema: infra; Owner: _developer
--

CREATE SEQUENCE infra.uagrouporglinks_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE infra.uagrouporglinks_seq OWNER TO _developer;

--
-- Name: uagrouporglinks; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.uagrouporglinks (
    ugo_seq bigint DEFAULT nextval('infra.uagrouporglinks_seq'::regclass) NOT NULL,
    ugo_go_ref bigint NOT NULL,
    ugo_usr_ref bigint NOT NULL,
    ugo_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone NOT NULL,
    ugo_cby character varying(15) NOT NULL
);


ALTER TABLE infra.uagrouporglinks OWNER TO _developer;

--
-- Name: COLUMN uagrouporglinks.ugo_seq; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uagrouporglinks.ugo_seq IS 'primary key';


--
-- Name: COLUMN uagrouporglinks.ugo_go_ref; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uagrouporglinks.ugo_go_ref IS 'foreign key to entGroupOrganisations';


--
-- Name: COLUMN uagrouporglinks.ugo_usr_ref; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uagrouporglinks.ugo_usr_ref IS 'foreign key to uaUsers';


--
-- Name: COLUMN uagrouporglinks.ugo_cwhen; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uagrouporglinks.ugo_cwhen IS 'creation date';


--
-- Name: COLUMN uagrouporglinks.ugo_cby; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uagrouporglinks.ugo_cby IS 'created by';


--
-- Name: ualogaccess_seq; Type: SEQUENCE; Schema: infra; Owner: _developer
--

CREATE SEQUENCE infra.ualogaccess_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE infra.ualogaccess_seq OWNER TO _developer;

--
-- Name: ualogaccess; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.ualogaccess (
    ula_seq bigint DEFAULT nextval('infra.ualogaccess_seq'::regclass) NOT NULL,
    ula_usr_ref bigint,
    ula_login timestamp without time zone,
    ula_logout timestamp without time zone,
    ula_forms_visited character varying(255),
    ula_ip_address character varying(50),
    ula_go_name character varying(10),
    ula_connect_time timestamp without time zone,
    ula_bytes_connect bigint,
    ula_bytes_total_sent bigint,
    ula_bytes_total_recd bigint,
    ula_bytes_max_sent bigint,
    ula_bytes_max_recd bigint,
    ula_requests bigint,
    ula_comment character varying(1000),
    ula_last_hit timestamp without time zone,
    ula_dg_ref bigint
);


ALTER TABLE infra.ualogaccess OWNER TO _developer;

--
-- Name: COLUMN ualogaccess.ula_go_name; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.ualogaccess.ula_go_name IS 'group organisation short name';


--
-- Name: COLUMN ualogaccess.ula_dg_ref; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.ualogaccess.ula_dg_ref IS 'foreign key to delegates (for specific applications only)';


--
-- Name: uausers_seq; Type: SEQUENCE; Schema: infra; Owner: _developer
--

CREATE SEQUENCE infra.uausers_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE infra.uausers_seq OWNER TO _developer;

--
-- Name: uausers; Type: TABLE; Schema: infra; Owner: _developer
--

CREATE TABLE infra.uausers (
    usr_seq bigint DEFAULT nextval('infra.uausers_seq'::regclass) NOT NULL,
    usr_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    usr_cby character varying(15),
    usr_mwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    usr_mby character varying(15),
    usr_mcount integer,
    usr_usr_ref bigint,
    usr_name character varying(15),
    usr_real_name character varying(30),
    usr_salt character varying(40),
    usr_hashpass character varying(100),
    usr_extn character varying(15),
    usr_mobile character varying(20),
    usr_email character varying(100),
    usr_pw_expires date,
    usr_ac_expires date,
    usr_initials character varying(5),
    usr_job_title character varying(50),
    usr_team character varying(15),
    usr_startdate date,
    usr_active smallint DEFAULT 1 NOT NULL,
    CONSTRAINT usr_usr_ref_chk CHECK ((usr_usr_ref <> usr_seq))
);


ALTER TABLE infra.uausers OWNER TO _developer;

--
-- Name: COLUMN uausers.usr_seq; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_seq IS 'primary key';


--
-- Name: COLUMN uausers.usr_cwhen; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_cwhen IS 'created timestamp';


--
-- Name: COLUMN uausers.usr_cby; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_cby IS 'created by';


--
-- Name: COLUMN uausers.usr_mwhen; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_mwhen IS 'last modified';


--
-- Name: COLUMN uausers.usr_mby; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_mby IS 'modified by';


--
-- Name: COLUMN uausers.usr_mcount; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_mcount IS 'update count';


--
-- Name: COLUMN uausers.usr_usr_ref; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_usr_ref IS 'manager key';


--
-- Name: COLUMN uausers.usr_name; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_name IS 'user login name';


--
-- Name: COLUMN uausers.usr_real_name; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_real_name IS 'user full name';


--
-- Name: COLUMN uausers.usr_salt; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_salt IS 'hash salt for password';


--
-- Name: COLUMN uausers.usr_hashpass; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_hashpass IS 'user password hashed';


--
-- Name: COLUMN uausers.usr_extn; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_extn IS 'phone extension';


--
-- Name: COLUMN uausers.usr_mobile; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_mobile IS 'mobile number';


--
-- Name: COLUMN uausers.usr_email; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_email IS 'email address';


--
-- Name: COLUMN uausers.usr_pw_expires; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_pw_expires IS 'password expiry date';


--
-- Name: COLUMN uausers.usr_ac_expires; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_ac_expires IS 'account expiry date';


--
-- Name: COLUMN uausers.usr_initials; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_initials IS 'user initials';


--
-- Name: COLUMN uausers.usr_job_title; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_job_title IS 'job title';


--
-- Name: COLUMN uausers.usr_team; Type: COMMENT; Schema: infra; Owner: _developer
--

COMMENT ON COLUMN infra.uausers.usr_team IS 'team name';


--
-- Name: omgroup_seq; Type: SEQUENCE; Schema: translate; Owner: _developer
--

CREATE SEQUENCE translate.omgroup_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE translate.omgroup_seq OWNER TO _developer;

--
-- Name: omgroup; Type: TABLE; Schema: translate; Owner: _developer
--

CREATE TABLE translate.omgroup (
    omg_seq integer DEFAULT nextval('translate.omgroup_seq'::regclass) NOT NULL,
    omg_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    omg_cby character varying(15) NOT NULL,
    omg_mwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    omg_mby character varying(15) NOT NULL,
    omg_mcount integer DEFAULT 0 NOT NULL,
    omg_class character varying(15) NOT NULL,
    omg_function character varying(50) NOT NULL
);


ALTER TABLE translate.omgroup OWNER TO _developer;

--
-- Name: COLUMN omgroup.omg_seq; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omgroup.omg_seq IS 'primary key';


--
-- Name: COLUMN omgroup.omg_cwhen; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omgroup.omg_cwhen IS 'creation timestamp';


--
-- Name: COLUMN omgroup.omg_cby; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omgroup.omg_cby IS 'created by';


--
-- Name: COLUMN omgroup.omg_mwhen; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omgroup.omg_mwhen IS 'modification timestamp';


--
-- Name: COLUMN omgroup.omg_mby; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omgroup.omg_mby IS 'modified by';


--
-- Name: COLUMN omgroup.omg_class; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omgroup.omg_class IS 'classification of strings, eg. schemas';


--
-- Name: COLUMN omgroup.omg_function; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omgroup.omg_function IS 'description of functionall grouping';


--
-- Name: omlibgrouplinks_seq; Type: SEQUENCE; Schema: translate; Owner: _developer
--

CREATE SEQUENCE translate.omlibgrouplinks_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE translate.omlibgrouplinks_seq OWNER TO _developer;

--
-- Name: omlibgrouplinks; Type: TABLE; Schema: translate; Owner: _developer
--

CREATE TABLE translate.omlibgrouplinks (
    olg_seq integer DEFAULT nextval('translate.omlibgrouplinks_seq'::regclass) NOT NULL,
    olg_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    olg_cby character varying(15) NOT NULL,
    olg_mwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    olg_mby character varying(15) NOT NULL,
    olg_mcount integer DEFAULT 0 NOT NULL,
    olg_oml_ref integer NOT NULL,
    olg_omg_ref integer NOT NULL
);


ALTER TABLE translate.omlibgrouplinks OWNER TO _developer;

--
-- Name: COLUMN omlibgrouplinks.olg_seq; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omlibgrouplinks.olg_seq IS 'primary key';


--
-- Name: COLUMN omlibgrouplinks.olg_cwhen; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omlibgrouplinks.olg_cwhen IS 'creation timestamp';


--
-- Name: COLUMN omlibgrouplinks.olg_cby; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omlibgrouplinks.olg_cby IS 'created by';


--
-- Name: COLUMN omlibgrouplinks.olg_mwhen; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omlibgrouplinks.olg_mwhen IS 'modifcation timestamp';


--
-- Name: COLUMN omlibgrouplinks.olg_mby; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omlibgrouplinks.olg_mby IS 'modified by';


--
-- Name: COLUMN omlibgrouplinks.olg_mcount; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omlibgrouplinks.olg_mcount IS 'modification count';


--
-- Name: COLUMN omlibgrouplinks.olg_oml_ref; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omlibgrouplinks.olg_oml_ref IS 'foregin key to omlibrary';


--
-- Name: omlibrary_seq; Type: SEQUENCE; Schema: translate; Owner: _developer
--

CREATE SEQUENCE translate.omlibrary_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE translate.omlibrary_seq OWNER TO _developer;

--
-- Name: omlibrary; Type: TABLE; Schema: translate; Owner: _developer
--

CREATE TABLE translate.omlibrary (
    oml_seq integer DEFAULT nextval('translate.omlibrary_seq'::regclass) NOT NULL,
    oml_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    oml_cby character varying(15) NOT NULL,
    oml_name character varying(15) NOT NULL
);


ALTER TABLE translate.omlibrary OWNER TO _developer;

--
-- Name: COLUMN omlibrary.oml_seq; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omlibrary.oml_seq IS 'primary key';


--
-- Name: COLUMN omlibrary.oml_cwhen; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omlibrary.oml_cwhen IS 'creation timestamp';


--
-- Name: COLUMN omlibrary.oml_cby; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omlibrary.oml_cby IS 'created by';


--
-- Name: COLUMN omlibrary.oml_name; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omlibrary.oml_name IS 'library name (upper case)';


--
-- Name: omstrings_seq; Type: SEQUENCE; Schema: translate; Owner: _developer
--

CREATE SEQUENCE translate.omstrings_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE translate.omstrings_seq OWNER TO _developer;

--
-- Name: omstrings; Type: TABLE; Schema: translate; Owner: _developer
--

CREATE TABLE translate.omstrings (
    oms_seq integer DEFAULT nextval('translate.omstrings_seq'::regclass) NOT NULL,
    oms_cwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    oms_cby character varying(15) NOT NULL,
    oms_mwhen timestamp without time zone DEFAULT ('now'::text)::timestamp(0) without time zone NOT NULL,
    oms_mby character varying(15) NOT NULL,
    oms_mcount integer DEFAULT 0 NOT NULL,
    oms_omg_ref integer,
    oms_cols_modified character varying(255),
    stringid character varying(50) NOT NULL,
    en text,
    de text,
    sv text,
    nl text,
    zh text,
    ca text,
    es text,
    it text,
    fr text,
    no text,
    fi text,
    da text,
    pt text,
    cy text,
    el text,
    pl text,
    hr text,
    bg text,
    tr text,
    ro text,
    cs text,
    hu text,
    ru text,
    ja text,
    ar text,
    he text
);


ALTER TABLE translate.omstrings OWNER TO _developer;

--
-- Name: COLUMN omstrings.oms_seq; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.oms_seq IS 'primary key';


--
-- Name: COLUMN omstrings.oms_cwhen; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.oms_cwhen IS 'creation timestamp';


--
-- Name: COLUMN omstrings.oms_cby; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.oms_cby IS 'created by';


--
-- Name: COLUMN omstrings.oms_mwhen; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.oms_mwhen IS 'modification timestamp';


--
-- Name: COLUMN omstrings.oms_mby; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.oms_mby IS 'modified by';


--
-- Name: COLUMN omstrings.oms_mcount; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.oms_mcount IS 'modification count';


--
-- Name: COLUMN omstrings.oms_omg_ref; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.oms_omg_ref IS 'foreign key to omgroup';


--
-- Name: COLUMN omstrings.oms_cols_modified; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.oms_cols_modified IS 'string of translation columns manually modified';


--
-- Name: COLUMN omstrings.stringid; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.stringid IS 'unique indexed string table entry identifier';


--
-- Name: COLUMN omstrings.en; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.en IS 'english';


--
-- Name: COLUMN omstrings.de; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.de IS 'german';


--
-- Name: COLUMN omstrings.sv; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.sv IS 'swedish';


--
-- Name: COLUMN omstrings.nl; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.nl IS 'dutch';


--
-- Name: COLUMN omstrings.zh; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.zh IS 'chinese';


--
-- Name: COLUMN omstrings.ca; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.ca IS 'catalan';


--
-- Name: COLUMN omstrings.es; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.es IS 'spanish';


--
-- Name: COLUMN omstrings.it; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.it IS 'italian';


--
-- Name: COLUMN omstrings.fr; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.fr IS 'french';


--
-- Name: COLUMN omstrings.no; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.no IS 'norwegian';


--
-- Name: COLUMN omstrings.fi; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.fi IS 'finnish';


--
-- Name: COLUMN omstrings.da; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.da IS 'danish';


--
-- Name: COLUMN omstrings.pt; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.pt IS 'portuguese';


--
-- Name: COLUMN omstrings.cy; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.cy IS 'welsh';


--
-- Name: COLUMN omstrings.el; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.el IS 'greek';


--
-- Name: COLUMN omstrings.pl; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.pl IS 'polish';


--
-- Name: COLUMN omstrings.hr; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.hr IS 'croatian';


--
-- Name: COLUMN omstrings.bg; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.bg IS 'bulgarian';


--
-- Name: COLUMN omstrings.tr; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.tr IS 'turkish';


--
-- Name: COLUMN omstrings.ro; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.ro IS 'romanian';


--
-- Name: COLUMN omstrings.cs; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.cs IS 'czech';


--
-- Name: COLUMN omstrings.hu; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.hu IS 'hungarian';


--
-- Name: COLUMN omstrings.ru; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.ru IS 'russian';


--
-- Name: COLUMN omstrings.ja; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.ja IS 'japanese';


--
-- Name: COLUMN omstrings.ar; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.ar IS 'arabic';


--
-- Name: COLUMN omstrings.he; Type: COMMENT; Schema: translate; Owner: _developer
--

COMMENT ON COLUMN translate.omstrings.he IS 'hebrew';


--
-- Data for Name: entgrouporganisations; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.entgrouporganisations (go_seq, go_cwhen, go_cby, go_mwhen, go_mby, go_mcount, go_name_full, go_name_short, go_addr_building, go_addr_street, go_addr_locality, go_addr_town, go_addr_state, go_addr_postcode, go_addr_country, go_comm_ph, go_comm_mob, go_comm_email, go_company_no, go_vat_no, go_currency, go_mec_id, go_mec_type, go_rrs, go_ddn_ap1, go_ddn_ap2, go_surname, go_firstnames, go_name_ltbc, go_dob, go_sex, go_mmn, go_id_type, go_id_code, go_mc_listid, go_report_to_go_ref, go_report_to_percent) FROM stdin;
2	2017-04-26 12:43:49	mostynrs	2017-04-26 12:43:49	mostynrs	0	\N	mecUK	\N	2 Kennel Cottages	Shendish	Hemel Hempstead	\N	HP3 0AB	GBR	01442 412232	\N	\N	\N	\N	£	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.0000
\.


--
-- Data for Name: entgrouporgnames; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.entgrouporgnames (gon_seq, gon_cwhen, gon_cby, gon_mwhen, gon_mby, gon_mcount, gon_go_ref, gon_name_full, gon_type) FROM stdin;
2	2017-04-26 12:47:18	stevensg	2017-04-26 12:47:18	stevensg	0	2	myEcoCost.org UK	I
\.


--
-- Data for Name: sysasyncemails; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.sysasyncemails (ae_seq, ae_to, ae_subject, ae_message, ae_cc, ae_bcc, ae_priority, ae_encl, ae_html, ae_cwhen, ae_go_ref, ae_fail_count, ae_fail_dialogue, ae_fail_status, ae_from, ae_extraheaders, ae_sendercode) FROM stdin;
\.


--
-- Data for Name: syslogerrors; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.syslogerrors (sle_cwhen, sle_code, sle_subcode, sle_message, sle_vhost_ref, sle_server_ip, sle_server_port) FROM stdin;
\.


--
-- Data for Name: syslogevents; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.syslogevents (slv_cwhen, slv_code, slv_subcode, slv_message, slv_vhost_ref, slv_server_ip, slv_server_port) FROM stdin;
\.


--
-- Data for Name: sysreferenceglobal; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.sysreferenceglobal (rfg_seq, rfg_class, rfg_value, rfg_desc, rfg_order, rfg_active, rfg_char, rfg_int, rfg_number, rfg_date, rfg_bin, rfg_time, rfg_effective, rfg_expires, rfg_json, rfg_cwhen, rfg_cby, rfg_mwhen, rfg_mby, rfg_mcount) FROM stdin;
1	EM_SRVR_FROM	DEFAULT	Default server values	0	1	\N	0	0	\N	\N	00:00:00	\N	\N	{"server": "smtp.ourdomain.net", "emailCC": [], "emailTO": ["dev@ourdomain.net", "devadmin@ourdomain.net"], "emailBCC": [], "loginName": "", "senderName": "STB Editor", "secureValue": "NotSecure", "loginPassword": "", "senderAddress": "apps@ourdomain.net", "authentication": "None"}	2017-07-17 14:27:43	CONSOLE	2017-07-17 14:27:43	CONSOLE	0
\.


--
-- Data for Name: sysreferencelocal; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.sysreferencelocal (rfl_seq, rfl_class, rfl_value, rfl_desc, rfl_order, rfl_active, rfl_char, rfl_int, rfl_number, rfl_date, rfl_bin, rfl_time, rfl_effective, rfl_expires, rfl_json, rfl_cwhen, rfl_cby, rfl_mwhen, rfl_mby, rfl_mcount, rfl_inherit) FROM stdin;
\.


--
-- Data for Name: sysreferenceorg; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.sysreferenceorg (rfo_seq, rfo_class, rfo_value, rfo_desc, rfo_order, rfo_active, rfo_char, rfo_int, rfo_number, rfo_date, rfo_bin, rfo_time, rfo_effective, rfo_expires, rfo_json, rfo_go_ref, rfo_cwhen, rfo_cby, rfo_mwhen, rfo_mby, rfo_mcount, rfo_inherit) FROM stdin;
\.


--
-- Data for Name: sysreferenceuser; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.sysreferenceuser (rfu_seq, rfu_class, rfu_value, rfu_desc, rfu_order, rfu_active, rfu_char, rfu_int, rfu_number, rfu_date, rfu_bin, rfu_time, rfu_effective, rfu_expires, rfu_json, rfu_go_ref, rfu_usr_ref, rfu_cwhen, rfu_cby, rfu_mwhen, rfu_mby, rfu_mcount) FROM stdin;
\.


--
-- Data for Name: systaskstats; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.systaskstats (sts_seq, sts_start, sts_count_start, sts_end, sts_count_end, sts_last_response, sts_go_ref, sts_bytes_reqcursent, sts_bytes_reqcurrecd, sts_bytes_reqmaxsent, sts_bytes_reqmaxrecd, sts_bytes_reqtotsent, sts_bytes_reqtotrecd, sts_tot_events, sts_ula_ref, sts_ip4, sts_type, sts_db_requests, sts_fetches, sts_inserts, sts_updates, sts_deletes, sts_device_size, sts_init_class, sts_gl_ref, sts_browser, sts_ws_name, sts_table_name, sts_table_method, sts_params, sts_table_list) FROM stdin;
\.


--
-- Data for Name: uagrouporglinks; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.uagrouporglinks (ugo_seq, ugo_go_ref, ugo_usr_ref, ugo_cwhen, ugo_cby) FROM stdin;
2	2	1	2017-04-26 12:49:34	stevensg
\.


--
-- Data for Name: ualogaccess; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.ualogaccess (ula_seq, ula_usr_ref, ula_login, ula_logout, ula_forms_visited, ula_ip_address, ula_go_name, ula_connect_time, ula_bytes_connect, ula_bytes_total_sent, ula_bytes_total_recd, ula_bytes_max_sent, ula_bytes_max_recd, ula_requests, ula_comment, ula_last_hit, ula_dg_ref) FROM stdin;
\.


--
-- Data for Name: uausers; Type: TABLE DATA; Schema: infra; Owner: _developer
--

COPY infra.uausers (usr_seq, usr_cwhen, usr_cby, usr_mwhen, usr_mby, usr_mcount, usr_usr_ref, usr_name, usr_real_name, usr_salt, usr_hashpass, usr_extn, usr_mobile, usr_email, usr_pw_expires, usr_ac_expires, usr_initials, usr_job_title, usr_team, usr_startdate, usr_active) FROM stdin;
1	2017-04-26 12:06:36	stevensg	2017-04-26 12:06:36	stevensg	0	\N	editor	STB Editor	\N	\N	\N	\N	\N	\N	\N	RSM	\N	\N	\N	1
\.


--
-- Data for Name: omgroup; Type: TABLE DATA; Schema: translate; Owner: _developer
--

COPY translate.omgroup (omg_seq, omg_cwhen, omg_cby, omg_mwhen, omg_mby, omg_mcount, omg_class, omg_function) FROM stdin;
1	2017-04-25 14:22:58	stevensg	2017-04-25 14:22:58	stevensg	0	schemas	Infrastructure
3	2017-04-26 15:02:07	stevensg	2017-04-26 15:02:07	stevensg	0	messages	All messages
19	2017-04-27 16:23:51	stevensg	2017-04-27 16:23:51	stevensg	0	schemas	CONFERENCE
42	2017-04-27 17:24:14	stevensg	2017-04-27 17:24:14	stevensg	0	labels	CONFERENCE
48	2017-05-10 13:38:21	mostynrs	2017-05-10 13:38:21	mostynrs	0	labels	REM.FORM menu entries
52	2017-06-09 14:22:58	MOSTYNRS	2017-06-09 14:22:58	MOSTYNRS	0	menus	Infrastructure
40	2017-04-27 17:24:14	stevensg	2017-04-27 17:24:14	stevensg	0	labels	Infrastructure
57	2018-09-10 15:30:00	mostynrs	2018-09-10 15:30:00	mostynrs	0	menus	CONFERENCE
\.


--
-- Data for Name: omlibgrouplinks; Type: TABLE DATA; Schema: translate; Owner: _developer
--

COPY translate.omlibgrouplinks (olg_seq, olg_cwhen, olg_cby, olg_mwhen, olg_mby, olg_mcount, olg_oml_ref, olg_omg_ref) FROM stdin;
14	2017-04-27 10:34:37	stevensg	2017-04-27 10:34:37	stevensg	0	11	1
53	2017-04-28 08:53:07	stevensg	2017-04-28 08:53:07	stevensg	0	11	40
54	2017-04-28 08:53:07	stevensg	2017-04-28 08:53:07	stevensg	0	11	42
90	2017-05-10 13:25:59	MOSTYNRS	2017-05-10 13:25:59	MOSTYNRS	0	11	19
96	2017-05-10 13:51:30	MOSTYNRS	2017-05-10 13:51:30	MOSTYNRS	0	11	48
101	2017-06-09 15:43:37	MOSTYNRS	2017-06-09 15:43:37	MOSTYNRS	0	11	3
135	2018-04-20 16:22:34	STEVENSG	2018-04-20 16:22:34	STEVENSG	0	11	52
140	2018-09-10 15:38:11	MOSTYNRS	2018-09-10 15:38:11	MOSTYNRS	0	11	57
\.


--
-- Data for Name: omlibrary; Type: TABLE DATA; Schema: translate; Owner: _developer
--

COPY translate.omlibrary (oml_seq, oml_cwhen, oml_cby, oml_name) FROM stdin;
11	2017-04-27 09:47:29	stevensg	CONFERENCE
\.


--
-- Data for Name: omstrings; Type: TABLE DATA; Schema: translate; Owner: _developer
--

COPY translate.omstrings (oms_seq, oms_cwhen, oms_cby, oms_mwhen, oms_mby, oms_mcount, oms_omg_ref, oms_cols_modified, stringid, en, de, sv, nl, zh, ca, es, it, fr, no, fi, da, pt, cy, el, pl, hr, bg, tr, ro, cs, hu, ru, ja, ar, he) FROM stdin;
667	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_ACP_REF_LBL	foreign key to accountingperiod	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
668	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_ACP_REF_TT	foreign key to accountingperiod	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
669	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
670	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
671	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_CLOSED_LBL	period closed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
672	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_CLOSED_TT	flag to indicate period is closed for posting	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
673	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_COMMENT_LBL	comment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
674	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_COMMENT_TT	reason for forecast adjustment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
675	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_CWHEN_LBL	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
676	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
677	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_FC_ADJUST_LBL	forecast adjustment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
678	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_FC_ADJUST_TT	forecast adjustment multiplier, eg. to account for seasonal differences	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
679	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_GO_REF_LBL	foreign key to entgrouporganisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
680	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_GO_REF_TT	foreign key to entgrouporganisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
681	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
682	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
683	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_MCOUNT_LBL	modication count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
684	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_MCOUNT_TT	modication count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
685	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_MWHEN_LBL	modification timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
686	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_MWHEN_TT	modification timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
687	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
688	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACL_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
689	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
690	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
691	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_CWHEN_LBL	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
692	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
693	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_FROM_LBL	from	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
694	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_FROM_TT	start date of accounting period	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
695	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
696	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
697	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_MCOUNT_LBL	modication count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
698	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_MCOUNT_TT	modication count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
699	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_MWHEN_LBL	modification timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
700	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_MWHEN_TT	modification timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
702	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
703	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_SPAN_LBL	period length	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
704	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_SPAN_TT	period length:Y=year,Q=quarter,M=month	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
705	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_TO_LBL	to	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
706	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ACP_TO_TT	end date of accounting period	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
712	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_BCC_LBL	list of email addressees	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
713	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_BCC_TT	list of email addressees	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
714	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_CC_LBL	list of email addressees	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
715	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_CC_TT	list of email addressees	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
716	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_CWHEN_LBL	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
717	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
718	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_ENCL_LBL	attachments	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
719	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_ENCL_TT	attachments	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
720	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_FROM_LBL	from	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
721	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_GO_REF_LBL	internal company	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
722	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_HTML_LBL	HTML version of email message	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
723	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_HTML_TT	HTML version of email message	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
724	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_MESSAGE_LBL	email content	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
725	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_MESSAGE_TT	email content	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
701	2017-04-27 15:20:51	stevensg	2018-03-09 12:07:00	MOSTYNRS	1	1	\N	ACP_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
726	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_PRIORITY_LBL	priority - 0 to 3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
727	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_PRIORITY_TT	priority - 0 to 3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
728	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
729	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
730	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_SUBJECT_LBL	subject	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
731	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_SUBJECT_TT	subject line of email	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
732	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_TO_LBL	to	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
733	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AE_TO_TT	list of email addressees	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
741	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARA_ARR_REF_LBL	session	Session	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
734	2017-04-27 15:20:51	stevensg	2018-01-15 11:29:00	STEVENSG	2	40	\N	ALL	all periods	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
743	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARA_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
744	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARA_COMMENTS_LBL	comment	Kommentar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
745	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARA_COMMENTS_TT	You can make a comment about your experience of the session here.	Sie können einen Kommentar zu Ihrer Erfahrung der Sitzung hier machen.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
742	2017-04-27 15:20:00	stevensg	2017-05-10 12:29:00	MOSTYNRS	2	19	\N	ARA_ARR_REF_TT	Which session (lecture, workshop etc) is being booked.	Welche Sitzung (Vorlesung, Workshop etc.) wird gebucht.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
747	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARA_DG_REF_LBL	delegate	delegieren	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
748	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARA_DG_REF_TT	Person registering for this session.	Person, die sich für diese Sitzung registriert.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
749	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARA_MBY_LBL	last modified by	Zuletzt geändert durch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
750	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARA_MCOUNT_LBL	mod. count	Mod. Graf	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
751	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARA_MWHEN_LBL	last modified	zuletzt bearbeitet	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
752	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARA_RATING_LBL	rating	Bewertung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
754	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARA_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
755	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_ALL_SPKR_TOPICS_LBL	if 1, display all topics for ARR_PSN_REF for this conference	Wenn 1, zeigen Sie alle Themen für ARR_PSN_REF für diese Konferenz an	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
756	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_ALL_SPKR_TOPICS_TT	if 1, display all topics for ARR_PSN_REF for this conference	Wenn 1, zeigen Sie alle Themen für ARR_PSN_REF für diese Konferenz an	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
757	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_BOOKING_REQD_LBL	Bookings mandatory	Buchungen obligatorisch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
759	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
760	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_CF_REF_LBL	conference	Konferenz	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
761	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_CF_REF_TT	reference to conference record	Verweis auf Konferenzaufzeichnung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
762	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_COMMENT_LBL	comment	Kommentar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
763	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
764	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_DATE_LBL	date	Datum	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
765	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_DATE_TT	Specify either an explicit date here, or a relative date using day no.	Geben Sie hier ein explizites Datum oder ein relatives Datum mit Tag nein an.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
766	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_DAYNO_LBL	day no.	Tag nein	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
768	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_ENDTIME_LBL	End time	Endzeit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
769	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_FACILITY_LBL	Override room	Override Raum	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
770	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_FACILITY_TT	If location of event does not appear in list, then explicitly set rrom or location here.	Wenn Standort des Ereignisses nicht in der Liste erscheint, dann explizit rrom oder Ort hier setzen.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
771	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_FCY_REF_LBL	Room/location	Zimmer / Lage	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
772	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_FCY_REF_TT	Initially optional but eventually required	Anfänglich optional aber eventuell erforderlich	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
773	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_FORMAT_LBL	format	Format	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
774	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_FORMAT_TT	Specify the format of the event here.	Geben Sie hier das Format der Veranstaltung an.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
775	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_LEADER_LBL	Override leader	Override Führer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
776	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_LEADER_TT	If Person does not exist in list, you can manually set the leader's name here.	Wenn die Person nicht in der Liste existiert, können Sie hier den Namen des Anbieters manuell einstellen.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
777	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_MAX_BOOKINGS_LBL	Maximum attendance	Maximale Anwesenheit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
779	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_MBY_LBL	modified by	angepasst von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
746	2017-04-27 15:20:00	stevensg	2017-05-09 11:43:00	MOSTYNRS	2	19	\N	ARA_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
801	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_BINARY_LBL	data in binary format	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
802	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_BINARY_TT	data in binary format	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
803	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
804	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
805	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_CWHEN_LBL	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
806	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
807	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_MBY_LBL	updated by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
808	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_MBY_TT	updated by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
809	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_MWHEN_LBL	latest update	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
810	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_MWHEN_TT	latest update	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
811	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_PK_LBL	primary key of associated record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
812	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_PK_TT	primary key of associated record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
813	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
814	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
815	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_TABLE_PREFIX_LBL	table identifier	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
816	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	AS_TABLE_PREFIX_TT	table identifier	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
782	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_MWHEN_LBL	modified	geändert	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
783	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_ORDER_LBL	sort order	Sortierreihenfolge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
785	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_PSN_REF_LBL	leader	Führer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
786	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_PSN_REF_TT	Reference to person who presents this topic, or leads this workshop.	Verweis auf Person, die dieses Thema präsentiert, oder führt diesen Workshop.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
787	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
788	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_SLOT_LBL	time slot	Zeitfenster	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
790	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_SPECIFIC_EQUIPT_LBL	equipment request	Ausrüstungsanfrage	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
792	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_STARTTIME_LBL	Start time	Startzeit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
793	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_STARTTIME_TT	Enter either a start time or a Time slot.	Geben Sie entweder eine Startzeit oder einen Zeitschlitz ein.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
794	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_TPC_REF_LBL	topic	Thema	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
795	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_TPC_REF_TT	Initially optional but eventually required, refers to topic / lecture / module being scheduled.	Zuerst optional, aber eventuell erforderlich, bezieht sich auf Thema / Vorlesung / Modul geplant.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
817	2017-04-27 15:20:51	stevensg	2017-09-06 12:23:00	STEVENSG	1	40	\N	Attributes_LBL	indicators	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
949	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
948	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CFP_NAME_TT	name of rule	Name der Regel	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
950	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_COMMENT_LBL	Comment	Kommentar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
952	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_CONTACT_NAME_LBL	Contact name	Kontaktname	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
953	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_CONTACT_NAME_TT	Person at venue who is handling the booking.	Person am Veranstaltungsort, der die Buchung abwickelt.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
954	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_CURRENCY_LBL	Currency symbol	Währungszeichen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
956	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
957	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_DATE_FROM_LBL	start date	Anfangsdatum	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
958	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_DATE_FROM_TT	start date of event	Startdatum der Veranstaltung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
941	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	C4StartDate_LBL	depreciation period start	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
961	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_FEATURE_LBL	Feature	Feature	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
963	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_FILTER_BRAND_LBL	brand filter	Markenfilter	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
965	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_LANG_LBL	language	Sprache	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
966	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_LANG_TT	Language of presentation	Sprache der Präsentation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
967	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_LOGO_RFO_VALUE_LBL	lookup IMAGES / cf_logo_rfo_value in sysreferenceorg for logo	Lookup IMAGES / cf_logo_rfo_value in sysreferenceorg für das Logo	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
968	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_LOGO_RFO_VALUE_TT	lookup IMAGES / cf_logo_rfo_value in sysreferenceorg for logo	Lookup IMAGES / cf_logo_rfo_value in sysreferenceorg für das Logo	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
969	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_NON_MEMBER_DELTA_LBL	non member premium	Nichtmitgliedsprämie	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
970	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_NON_MEMBER_DELTA_TT	amount added to each of the above for a non member rate	Betrag, der zu jedem der oben genannten für eine Nichtmitgliedsrate hinzugefügt wird	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
971	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE0_H_LBL	product code for full price, shared accommodation	Produkt-Code für den vollen Preis, gemeinsame Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
973	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE0_N_LBL	product code for full price, no accommodation	Produktcode für den vollen Preis, keine Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
974	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE1_H_LBL	product code for EB1 price, shared accommodation	Produktcode für EB1 Preis, geteilte Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
975	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE1_I_LBL	product code for EB1 price, single accommodation	Produktcode für EB1 Preis, Einzelunterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
976	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE1_N_LBL	product code for EB1 price, no accommodation	Produktcode für EB1 Preis, keine Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
978	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE2_I_LBL	product code for EB2 price, single accommodation	Produktcode für EB2 Preis, Einzelunterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
979	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE2_N_LBL	product code for EB2 price, no accommodation	Produktcode für EB2 Preis, keine Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
980	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE3_H_LBL	product code for EB3 price, shared accommodation	Produktcode für EB3 Preis, geteilte Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
982	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE3_N_LBL	product code for EB3 price, no accommodation	Produktcode für EB3 Preis, keine Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
983	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE4_H_LBL	product code for EB4 price, shared accommodation	Produktcode für EB4 Preis, geteilte Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
984	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE4_I_LBL	product code for EB4 price, single accommodation	Produktcode für EB4 Preis, Einzelunterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
986	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE5_H_LBL	product code for EB5 price, shared accommodation	Produktcode für EB5 Preis, geteilte Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
987	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE5_I_LBL	product code for EB5 price, single accommodation	Produktcode für EB5 Preis, Einzelunterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
988	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE5_N_LBL	product code for EB5 price, no accommodation	Produktcode für EB5 Preis, keine Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
990	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE6_I_LBL	product code for EB6 price, single accommodation	Produktcode für EB6 Preis, Einzelunterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
991	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE6_N_LBL	product code for EB6 price, no accommodation	Produktcode für EB6 Preis, keine Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
992	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE7_H_LBL	product code for EB7 price, shared accommodation	Produktcode für EB7 Preis, geteilte Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
993	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE7_I_LBL	product code for EB7 price, single accommodation	Produktcode für EB7 Preis, Einzelunterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
995	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE8_H_LBL	product code for EB8 price, shared accommodation	Produktcode für EB8 Preis, geteilte Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
996	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE8_I_LBL	product code for EB8 price, single accommodation	Produktcode für EB8 Preis, Einzelunterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
997	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE8_N_LBL	product code for EB8 price, no accommodation	Produktcode für EB8 Preis, keine Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
998	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE0_H_LBL	full rate, s H ared occupancy	Volle Rate, s h ared Belegung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1000	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE0_I_LBL	full rate, sin G le occupancy	Volle Rate, Sünde G le Belegung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1001	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE0_I_TT	full rate, sin G le occupancy	Volle Rate, Sünde G le Belegung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1002	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE0_N_LBL	full rate, N o accommodation	Voller Preis, N o Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1003	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE0_N_TT	full rate, N o accommodation	Voller Preis, N o Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1005	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE1_I_TT	one month before	Einen Monat vorher	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1006	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE2_I_LBL	two months before	Zwei Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1007	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE2_I_TT	two months before	Zwei Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1008	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE3_I_LBL	three months before	Drei Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1009	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE3_I_TT	three months before	Drei Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1010	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE4_I_LBL	four months before	Vier Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1013	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE5_I_TT	five months before	Fünf Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1014	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE6_I_LBL	six months before	Sechs Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1015	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE6_I_TT	six months before	Sechs Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1017	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE7_I_TT	seven months before	Sieben Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1018	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE8_I_LBL	eight months before	Acht Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1019	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE8_I_TT	eight months before	Acht Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1020	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1021	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_SEQ_TT	Primary key	Primärschlüssel	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1022	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_TITLE_LBL	conference name	Konferenzname	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1024	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_VEN_REF_LBL	Venue	Tagungsort	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1025	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_VEN_REF_TT	Name of venue	Name des Veranstaltungsortes	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1109	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_ACTIVE_LBL	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1110	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1111	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_CBY_TT	user who created this record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1112	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_CONTINENT_LBL	continent	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1113	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_CONTINENT_TT	used for grouping	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1114	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_CWHEN_LBL	creation date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1115	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_CWHEN_TT	creation date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1116	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_INTL_DIAL_CODE_LBL	dial code prefix	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1117	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_INTL_DIAL_CODE_TT	International dialling code for this country	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1118	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_ISO2_LBL	ISO 2 code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1119	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_ISO3_LBL	ISO 3 code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1120	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_LANGS_LBL	languages	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1121	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1122	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1123	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1125	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_MONEY_SYMB_LBL	currency symbol	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1126	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_MWHEN_LBL	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1127	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_MWHEN_TT	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1071	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	CMP_Heading	Composites	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1124	2017-04-27 15:20:51	stevensg	2018-04-10 16:01:00	STEVENSG	1	1	\N	CO_MM_OFFICE_LBL	EcoCost office exists	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1128	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_NAME_LBL	country name - english	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1129	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_NAME_LOCAL_LBL	country name - local language	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1130	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_PCODE_FORMAT_LBL	meta description of postcode formatting rules	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1131	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	CO_PCODE_FORMAT_TT	meta description of postcode formatting rules	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1148	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	CPR_Heading	ecoCost Calculation Steps	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1149	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	CPR_Intro	View the steps the the ecoCost calculator has taken to arrive at the ecoCost of a product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1275	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	CR_Heading	Categorisation Rules	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1276	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	CR_Intro	rules for assigning categorisation codes	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1293	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	CUSTOMER_LBL	customer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1294	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	CUSTOMER_TT	full name of customer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1295	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	CUST_EO_NAME_LBL	customer's name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1296	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	CUST_EO_NAME_TT	name of the customer or client	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1297	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	CUST_Heading	Customers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1250	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_CF_REF_LBL	conference	Konferenz	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1253	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_CRITERIA_LBL	criteria	Kriterien	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1257	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_DESC_LBL	description	Beschreibung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1258	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_DESC_TT	Describe the nature, performance or achievement of the certificate.	Beschreiben Sie die Art, die Leistung oder die Erfüllung des Zertifikats.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1260	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_MBY_TT	modified by	angepasst von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1263	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_MWHEN_LBL	modification timestamp	Änderungszeitstempel	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1264	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_MWHEN_TT	modification timestamp	Änderungszeitstempel	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1265	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_RULES_LBL	rules	Regeln	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1271	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_TITLE_LBL	title	Titel	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1272	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_TITLE_TT	Certificate title goes here.	Zertifikatstitel geht hier.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1273	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_TYPE_LBL	type	Art	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1274	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_TYPE_TT	What type of Certificate is this?	Welche Art von Zertifikat ist das?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1279	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CSN_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1280	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CSN_COMMENTS_LBL	comments	Bemerkungen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1282	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CSN_CRT_REF_LBL	certificate	Zertifikat	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1283	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CSN_CRT_REF_TT	Certificate being awarded	Zertifikat wird vergeben	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1284	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CSN_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1285	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CSN_DG_REF_LBL	who to	zu wem	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1286	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CSN_DG_REF_TT	Identofy the delegate being awarded this certificate.	Identifizieren Sie den Delegierten, der dieses Zertifikat verliehen hat.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1287	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CSN_MBY_LBL	last modified by	Zuletzt geändert durch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1288	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CSN_MCOUNT_LBL	mod. count	Mod. Graf	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1289	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CSN_MWHEN_LBL	last modified	zuletzt bearbeitet	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1290	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CSN_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1298	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	CUST_Intro	organisations to whom we send products and eco invoices	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1299	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Calculations_LBL	calculation(s)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1300	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Char_LBL	C	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1301	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Char_TT	character variable	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1303	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	DB_ERR	database error	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9930	2018-10-17 14:02:00	MOSTYNRS	2018-11-07 12:54:00	STEVENSG	2	57	\N	PDF_THANKS_DG_D	Sends a pdf formatted letter to the attendee thanking them for their support.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1393	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1394	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_CF_REF_LBL	foreign key to CONFERENCE	Fremdschlüssel zur KONFERENZ	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1395	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_CF_REF_TT	foreign key to CONFERENCE	Fremdschlüssel zur KONFERENZ	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1396	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_COMMENT_LBL	comment	Kommentar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1397	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_COMMENT_TT	general comment	allgemeiner Kommentar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1398	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_COMPANY_NAME_LBL	company name	Name der Firma	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1400	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_COUNTRY_LBL	copied from PSN_COUNTRY on registration for statistical integrity	Kopiert von PSN_COUNTRY bei der Registrierung zur statistischen Integrität	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1402	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1403	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_EMAIL_INVOICE_SENT_LBL	date and time when invoice was emailed through system	Datum und Uhrzeit, wenn die Rechnung per System per E-Mail gesendet wurde	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1404	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_EMAIL_INVOICE_SENT_TT	date and time when invoice was emailed through system	Datum und Uhrzeit, wenn die Rechnung per System per E-Mail gesendet wurde	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1405	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_EMAIL_TRAVEL_SENT_LBL	date and time when travel link was sent	Datum und Uhrzeit, an dem die Reiseverbindung gesendet wurde	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1407	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_EO_REF_LBL	customer	Kunde	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1408	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_EO_REF_TT	The person or company paying for attendance	Die Person oder Firma bezahlt für die Teilnahme	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1409	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_FEEDBACK_LBL	delegate comments on whole event	Delegierte Kommentare zur ganzen Veranstaltung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1410	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_FEEDBACK_TT	delegate comments on whole event	Delegierte Kommentare zur ganzen Veranstaltung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1411	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_GROUP_LBL	group name	Gruppenname	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1413	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_INT_PRODCODE_LBL	product code	Produktcode	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1414	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_INT_PRODCODE_TT	product code reflecting registration	Produktcode, der die Registrierung widerspiegelt	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1445	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	DIC_Heading	Definition of Carbon Footprint in terms of Elementary flows	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1460	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	DIM_Heading	Definition of MIPS in terms of Elementary flows	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1417	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_MBY_LBL	modified by	angepasst von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1418	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_MEMBERSHIP_DUE_LBL	membership amount	Mitgliedschaftsbetrag	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1419	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_MEMBERSHIP_DUE_TT	membership amount to be paid	Mitgliedschaftsbetrag bezahlt werden	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1420	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_MWHEN_LBL	modified when	Geändert wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1421	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_OCCUPANCY_LBL	occupancy	Belegung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1423	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_PSN_REF_LBL	attendee	Teilnehmer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1424	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_PSN_REF_TT	Person attending the event	Person, die an der Veranstaltung teilnimmt	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1425	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_RATE_LBL	rate	Preis	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1426	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_RATE_TT	which early bird rate is being applied	Welche frühe Vogelrate angewendet wird	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1427	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_REG_DATE_LBL	registration date	Registrierungsdatum	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1429	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_ROLE_LBL	DG, SPKR, KEYNOTE etc - to distinguish from DG_STATUS for payment	DG, SPKR, KEYNOTE etc - von DG_STATUS zur Zahlung zu unterscheiden	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1431	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_ROOM_ASSIGNMENT_LBL	assigned room	Zugeteilter Raum	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1432	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_ROOM_ASSIGNMENT_TT	used to communicate room requests (e.g. family) to hotel; also used to pair up shared delegates	Verwendet, um Zimmerwünsche (zB Familie) zum Hotel zu kommunizieren; Auch verwendet, um geteilte Delegierte zu paaren	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1433	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1434	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_SEQ_TT	DG record ID	DG-Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1435	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_STATUS_CHANGED_LBL	date of last change in status	Datum der letzten Änderung des Status	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1436	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_STATUS_CHANGED_TT	date of last change in status	Datum der letzten Änderung des Status	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1437	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_STATUS_LBL	status	Status	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1448	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DIL_DG_REF_LBL	foreign key to DELEGATE	Fremdschlüssel zum DELEGATE	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1449	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DIL_DG_REF_TT	foreign key to DELEGATE	Fremdschlüssel zum DELEGATE	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1450	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DIL_FOH_REF_LBL	foreign key to FinInvoiceOutH	Fremdschlüssel zu FinInvoiceOutH	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1451	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DIL_FOH_REF_TT	foreign key to FinInvoiceOutH	Fremdschlüssel zu FinInvoiceOutH	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1453	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DIL_PRIMARY_TT	when multiple delegates paid for on single invoice, DIL_PRIMARY 1 is assigned to main delegate within the group	Wenn mehrere Delegierte für eine einzelne Rechnung bezahlt werden, wird DIL_PRIMARY 1 dem Hauptdelegierten innerhalb der Gruppe zugeordnet	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1494	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DR_PX_REF_TT	foreign key to PAX	Fremdschlüssel zu PAX	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1495	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DR_REQUEST_LBL	dietary request	Diätetische Anfrage	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1497	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DR_SEQ_LBL	recvord ID	Recvord ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1556	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Description_LBL	description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1557	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Description_TT	detailed description of the item	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1579	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	ECD_REFS	reference to batch output or publication	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1757	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1602	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	ECI_REFS	reference to batch output or publication	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1613	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	ECL_REFS	reference to batch output or publication	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1619	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ECP_Heading	View ecoCost of a Product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1620	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ECP_Intro	a product can have multiple ecoCosts, calculated from different Processes over time 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1631	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	ECU_REFS	reference to batch output or publication	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1656	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	EID_REFS	reference to publication or product 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1669	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	EIH_Heading	eco Invoices Received	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1672	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	EIH_Intro	details of all eco invoices from suppliers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1746	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	EOH_Heading	eco Invoices Sent	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1748	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	EOH_Intro	details of eco Invoices sent to customers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1754	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1755	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1756	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_CWHEN_LBL	created timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1798	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_MBY_TT	Identity of person who last modified this record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1758	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_EO_REF_LBL	foreign key to external organisation - entExtOrganaisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1759	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_EO_REF_TT	foreign key to external organisation - entExtOrganaisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1760	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_FINACCT_CUID_LBL	sales ledger ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1761	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_FINACCT_CUID_TT	customer ID in financial accounting system sales ledger	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1762	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_FINACCT_SUID_LBL	purchase ledger ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1763	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_FINACCT_SUID_TT	supplier ID in financial accounting system purchase ledger	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1764	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_GO_REF_LBL	internal company	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1765	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_GO_REF_TT	reference to internal organisation - entGroupOrganisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1766	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1767	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_MBY_TT	Identity of person who last modified record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1768	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1769	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1770	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_MWHEN_LBL	modified	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1771	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_MWHEN_TT	Timestamp when record was last modified.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1772	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	EOL_REFS	either a supplier or customer code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1773	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_SEQ_LBL	record ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1774	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EOL_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1775	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_ADDR_BILL_LBL	billing address	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1776	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_ADDR_BILL_TT	organisation's address for sending the invoice to	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1777	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_ADDR_SHIP_LBL	shipping address	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1778	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_ADDR_SHIP_TT	optional address (shipping for customer records)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1779	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1780	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_CBY_TT	Identity of person who created this record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1781	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_COMMENT_LBL	comment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1782	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_COMMENT_TT	general comment such as what is supplied	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1783	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_COMPANY_NO_LBL	company registration no	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1784	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_COMPANY_NO_TT	company registration no	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1785	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_CONTACT_LBL	contact name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1786	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_CONTACT_TT	Name of person with organisation with whom to discuss accounts issues.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1787	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_CWHEN_LBL	created	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1788	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_CWHEN_TT	Timestamp of when record was created.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1789	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_EMAIL_LBL	contact email	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1790	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_EMAIL_TT	email address for the contact within the organisation with whom to discuss accounts issues	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1791	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_FAX_LBL	fax	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1792	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_FAX_TT	fax number for the named contact within the organisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1793	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	EO_Heading	Suppliers and Customers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1794	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_INSTRUCTIONS_LBL	shipping instructions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1795	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_INSTRUCTIONS_TT	other relevant information/instructions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1796	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	EO_Intro	organisations to whom we send or from whom we receive eco invoices and products	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1797	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1799	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1800	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1803	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_MWHEN_LBL	modified	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1804	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_MWHEN_TT	Timestamp of when record was last modified.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1806	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_NAME_TT	Name of company or organisation 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1807	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_PHONE_LBL	phone	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1808	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_PHONE_TT	phone number for the contact within the organisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1809	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_SEQ_LBL	record ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1810	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_SEQ_TT	Unique record number.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1811	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_VAT_NO_LBL	VAT no	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1812	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	EO_VAT_NO_TT	company VAT no	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1813	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	EO_icSearch_CT	search text here	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1805	2017-04-27 15:20:51	stevensg	2017-06-15 14:54:58	STEVENSG	1	1	\N	EO_NAME_LBL	company name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1801	2017-04-27 15:20:51	stevensg	2018-04-10 16:01:00	STEVENSG	1	1	\N	EO_MEC_ID_LBL	EcoCost ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1818	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	ERR_INVALID_VALUE	invalid value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1819	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	ERR_MAX_VAL_EXCEEDED	maximum value exceeded	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1821	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	ERR_NODEL_CHILDREN	record has associated child records, delete those first	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1866	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	FCY_LOCATION_LBL	location	Lage	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1869	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	FCY_MBY_LBL	modified by	angepasst von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1871	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	FCY_MWHEN_LBL	modified when	Geändert wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1874	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	FCY_NAME_TT	name of room where this session is held	Name des Raumes, in dem diese Sitzung abgehalten wird	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1876	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	FCY_ORDER_LBL	presentation order	Präsentationsbestellung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1822	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	ERR_OUT_OF_RANGE	value out of range	\N	\N	\N	\N	\N	Valor fuera de rango	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1820	2017-04-27 15:20:51	stevensg	2017-12-18 15:16:00	STEVENSG	1	3	\N	ERR_NODEL_CALCULATION	record has associated calculations and cannot be removed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1888	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	FEEDBACK_Heading	User feedback form - thank you	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1889	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	FEEDBACK_Intro	please make your comments below and click ‘save’ when completed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1890	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOC_FOH_REF_NEXT_LBL	next invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1891	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOC_FOH_REF_NEXT_TT	primary key of next invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1892	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOC_FOH_REF_PREV_LBL	previous invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1893	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOC_FOH_REF_PREV_TT	primary key of previous invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1894	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOC_SEQ_LBL	record ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1895	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOC_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1896	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1897	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_CBY_TT	Identity of person who created this record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1898	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_CWHEN_LBL	created	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1899	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_CWHEN_TT	timestamp when record was created	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1900	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_DESC_LBL	description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1901	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_DESC_TT	Copied from the Product record Name, this may be altered by user without changing product record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1902	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_FOH_REF_LBL	invoice header	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1903	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_FOH_REF_TT	Internal record pointer to invoice header record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1904	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1905	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_MBY_TT	Identity of person who last modified record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1906	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1907	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1908	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_MWHEN_LBL	modified	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1909	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_MWHEN_TT	Timestamp of when record was last modified.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1910	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_ORDER_LBL	line order	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1911	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_ORDER_TT	This column is used to order the detail lines within the invoice for consistent presentation.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1913	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_PRD_REF_TT	Reference to product record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1914	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	FOD_PRICE	quantity and price	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1915	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_QTY_LBL	qty	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1916	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_QTY_TT	Quantity of product ordered.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1917	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_SEQ_LBL	record ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1918	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_SEQ_TT	primary key; this table stores financial invoicing for micro businesses who don't use an accounting system	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1919	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	FOD_TAX	quantity and tax	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1920	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_UNIT_PRICE_LBL	unit price	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1921	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_UNIT_PRICE_TT	Price per unit of product.  Copied from product record, this may be altered by user.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1922	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_UNIT_TAX_LBL	VAT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1923	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOD_UNIT_TAX_TT	sales tax (VAT) applied per unit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1924	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_ADDR_BILL_LBL	billing address	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1925	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_ADDR_BILL_TT	Address of where to send invoice to.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1926	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_ADDR_SHIP_LBL	shipping address	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1927	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_ADDR_SHIP_TT	Address of where to send goods to.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1928	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1929	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_CBY_TT	Identity of persopn who created record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1930	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_CURRENCY_LBL	currency	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1931	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_CURRENCY_TT	currency of invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1932	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_CUST_NAME_LBL	customer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1933	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_CUST_NAME_TT	name of customer taken from customer records	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1885	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	FCY_STD_EQUIPT_TT	standard equipment provided with facility	Serienausstattung mit Einrichtung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1887	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	FCY_VEN_REF_LBL	foreign key to VENUE	Fremdschlüssel zu VENUE	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1912	2017-04-27 15:20:51	stevensg	2018-03-09 14:40:00	MOSTYNRS	6	1	\N	FOD_PRD_REF_LBL	product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1934	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_CUST_PO_LBL	customer PO no.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1935	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_CUST_PO_TT	Customer's Purchase Order (PO) number; helps customer reference the order they made in their system	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1936	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_CWHEN_LBL	created	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1937	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_CWHEN_TT	date and time that the invoice was created in the system, not necessarily the same as the invoice date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1938	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_DATE_LBL	date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1939	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_DATE_TT	Official date of invoice, to be shown on the invoice.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1940	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_EO_REF_LBL	customer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1941	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_EO_REF_TT	Customer to whom this invoice is being sent.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1942	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_GO_REF_LBL	internal company	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1943	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_GO_REF_TT	Internal company that is generating this invoice.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1944	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	FOH_Heading	Financial Invoices	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1945	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_INSTRUCTIONS_LBL	note to customer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1946	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_INSTRUCTIONS_TT	Note to include on invoice, eg. a message to the customer about storage or handling of goods.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1947	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_INV_NO_LBL	invoice no.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1948	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_INV_NO_TT	Unique invoice number for this company.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1949	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	FOH_Intro	details of invoices to customers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1950	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1951	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_MBY_TT	Identity of person who last modified this record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1952	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1953	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1956	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_MWHEN_LBL	modified	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1957	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_MWHEN_TT	Timestamp of when record was last modified.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1960	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_SEQ_LBL	record ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1961	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1962	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_STATUS_LBL	invoice type	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1963	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_STATUS_TT	indicates the type/status of the invoice eg. QUOTE, ALPHA, SUBSTITUTE, REFUND, etc.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1964	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_SWHEN_LBL	submitted	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1965	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	FOH_SWHEN_TT	Ttimestamp of when invoice was submitted to ecoInvoicing service.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1958	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	FOH_POS_Heading	Point of Sale Simulator	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1970	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_CONF	Conferences	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1967	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_ARR_GTD	Modules	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1971	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_CONF_GTD	Courses	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1966	2017-04-27 15:20:51	stevensg	2017-12-21 10:25:00	STEVENSG	2	48	\N	FORM_ARR	Arrangements	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1973	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_CR	Categorisation rules	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1974	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_CRT	Certificate definition	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1975	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_CUST	Customers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1976	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_DG	Delegates	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1977	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_DIC	Definition of carbon footprint	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1978	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_DIM	Definition of MIPS	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1979	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_ECP	ecoCost of product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1980	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_EIH	ecoInvoices in	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1981	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_EO	Suppliers and Customers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1982	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_EOH	ecoInvoices out	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1983	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_FOH	Financial invoices preparation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1972	2017-04-27 15:20:51	stevensg	2017-06-15 11:42:00	STEVENSG	2	48	\N	FORM_CPR	ecoCost Calculations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1986	2017-04-27 15:20:51	stevensg	2018-01-30 10:41:00	STEVENSG	2	48	\N	FORM_ICH	Input classifications	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1954	2017-04-27 15:20:51	stevensg	2018-04-10 16:02:00	STEVENSG	1	1	\N	FOH_MEC_ID_LBL	EcoCost user ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1987	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_IVM	Inventory movements	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1988	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_MEM	Members	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1989	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_MRS3	Smart readings	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1990	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_MTR	Meter readings	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1991	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_OHD	Overhead account movements	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1992	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_OHH	Overhead accounts	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1984	2017-04-27 15:20:51	stevensg	2017-06-09 14:29:00	MOSTYNRS	2	48	\N	FORM_GO	Group companies	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1985	2017-04-27 15:20:51	stevensg	2018-01-30 10:38:00	STEVENSG	2	48	\N	FORM_HELP	Help with using the system	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1955	2017-04-27 15:20:51	stevensg	2018-04-10 16:02:00	STEVENSG	1	1	\N	FOH_MEC_ID_TT	EcoCost user ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2030	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GL_CWHEN_LBL	creation date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2031	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GL_CWHEN_TT	creation date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2032	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GL_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2033	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GL_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2034	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GL_MWHEN_LBL	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2035	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GL_MWHEN_TT	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2036	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2037	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2038	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_CWHEN_LBL	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2039	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2040	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_GO_REF_LBL	foreign key to entGroupOrganisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2041	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_GO_REF_TT	foreign key to entGroupOrganisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2042	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2043	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2044	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2045	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2046	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_MWHEN_LBL	modification timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2047	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_MWHEN_TT	modification timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2048	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_NAME_FULL_LBL	full name of organisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2049	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_NAME_FULL_TT	full name of organisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2050	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2051	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2052	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_TYPE_LBL	I=Internal use, E=default value to send with ecoInvoices	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2053	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GON_TYPE_TT	I=Internal use, E=default value to send with ecoInvoices	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2054	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_BUILDING_LBL	Building name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2055	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_BUILDING_TT	Building name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1993	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_OP	Ontology hierarchy	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1994	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_ORH	Overheads Review Process	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1995	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_PC	Process calculations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1996	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_PEERS	PEERS gateway	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1997	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_PERMISSIONS	Permissions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1998	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_PM	Calculation models	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1999	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_POS	Retail Point of Sale	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_PRD	Product definitions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2001	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_PROC	Non-physical outputs	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2002	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_PSN	Person attending	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2004	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_RES	Resources	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2006	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_RFL	Group configuration	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2007	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_RFO	Company configuration	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2008	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_ROLES	Roles	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2009	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_SEQ	Sequences	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2010	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_SH	Definition of generic materials	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2011	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_SPEAKER	Speakers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2012	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_SPKR	Speakers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2013	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_SQLGEN	SQL generation aid	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2014	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_SUPP	Suppliers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2015	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_TST	Test definition	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2016	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_UOM	Units of measurement	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2017	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_UP	User preferences	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2018	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_USERS	Users	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2019	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_VEN	Venues	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2056	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_COUNTRY_LBL	Country	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2057	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_COUNTRY_TT	Country	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2058	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_LOCALITY_LBL	Locality	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2059	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_LOCALITY_TT	Locality	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2060	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_POSTCODE_LBL	Postcode	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2061	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_POSTCODE_TT	Postcode	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2062	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_STATE_LBL	State or county	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2063	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_STATE_TT	State or county	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2064	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_STREET_LBL	Number and street	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2065	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_STREET_TT	Number and street	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2066	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_TOWN_LBL	Town	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2067	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ADDR_TOWN_TT	Town	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2068	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	GO_ALL_RECORDS	All Group Companies	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2069	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2070	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2071	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_COMM_EMAIL_LBL	Email	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2072	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_COMM_EMAIL_TT	Email	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2073	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_COMM_MOB_LBL	Fax	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2074	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_COMM_MOB_TT	Fax	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2075	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_COMM_PH_LBL	Phone	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2076	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_COMM_PH_TT	Phone	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2077	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_COMPANY_NO_LBL	Company no.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2078	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_COMPANY_NO_TT	Company no.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2079	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_CURRENCY_LBL	currency symbol	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2080	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_CURRENCY_TT	currency symbol for product pricing	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2081	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_CWHEN_LBL	created timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2082	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_CWHEN_TT	created timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2084	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_DDN_AP1_TT	primary access point for the data delivery network	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2086	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_DDN_AP2_TT	fall back access point for the data delivery network	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2087	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_DOB_LBL	Individual's Date of birth	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2088	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_DOB_TT	Individual's Date of birth	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2089	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_FIRSTNAMES_LBL	All names excluding surname	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2090	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_FIRSTNAMES_TT	All names excluding surname	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2091	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	GO_Heading	Group Companies	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2092	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ID_CODE_LBL	Identification number	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2093	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ID_CODE_TT	Identification number	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2094	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ID_TYPE_LBL	Type of offical ID - passport, drivers licence, national insurance no	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2095	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_ID_TYPE_TT	Type of offical ID - passport, drivers licence, national insurance no	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2096	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	GO_Intro	at least 1 Company must be represented here	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2097	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2098	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2099	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2100	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2102	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_MEC_ID_TT	unique MEC user ID throughout the world	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2105	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_MMN_LBL	Mothers maiden name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2106	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_MMN_TT	Mothers maiden name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2107	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_MWHEN_LBL	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2108	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_MWHEN_TT	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2109	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_NAME_FULL_LBL	organisation's full name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2110	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_NAME_FULL_TT	organisation's full name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2111	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_NAME_LTBC_LBL	Name like to be called	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2112	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_NAME_LTBC_TT	Name like to be called	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2113	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_NAME_SHORT_LBL	organisation short name  	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2114	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_NAME_SHORT_TT	organisation short name  	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2115	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_RRS_LBL	URL of the relevant registration server	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2101	2017-04-27 15:20:51	stevensg	2018-04-10 16:02:00	STEVENSG	1	1	\N	GO_MEC_ID_LBL	EcoCost identifier	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2103	2017-04-27 15:20:51	stevensg	2018-04-10 16:02:00	STEVENSG	1	1	\N	GO_MEC_TYPE_LBL	EcoCost registration type	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2104	2017-04-27 15:20:51	stevensg	2018-04-10 16:02:00	STEVENSG	1	1	\N	GO_MEC_TYPE_TT	EcoCost registration type	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2116	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_RRS_TT	URL of the relevant registration server	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2117	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2118	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2119	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_SEX_LBL	Individual's gender	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2120	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_SEX_TT	Individual's gender	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2121	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_SURNAME_LBL	Individual's family name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2122	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_SURNAME_TT	Individual's family name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2123	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_VAT_NO_LBL	VAT no.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2124	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GO_VAT_NO_TT	VAT no.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2127	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2128	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2129	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_CWHEN_LBL	created timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2130	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_CWHEN_TT	created timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2131	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_DESC_LANG_LBL	translation of foreign table DESC column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2132	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_DESC_LANG_TT	translation of foreign table DESC column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2133	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_FT_PREFIX_LBL	prefix identifying foreign table this record belongs to	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2134	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_FT_PREFIX_TT	prefix identifying foreign table this record belongs to	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2135	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_FT_REF_LBL	foreign key to table identified by GT_FT_PREFIX	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2136	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_FT_REF_TT	foreign key to table identified by GT_FT_PREFIX	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2137	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_LANG_CODE_LBL	language and country code, eg. it_it	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2138	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_LANG_CODE_TT	language and country code, eg. it_it	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2139	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2140	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2141	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2142	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2143	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_MWHEN_LBL	modifed timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2144	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_MWHEN_TT	modifed timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2145	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_NAME_LANG_LBL	translation of foreign table NAME column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2146	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_NAME_LANG_TT	translation of foreign table NAME column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2147	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2148	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	GT_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2161	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Calculations_LBL	Step Calculations,Order,Description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2162	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Calculations_TT	displays all calculations for the current process step	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2165	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Descriptions_LBL	Step Descriptions,Order,Type,Comment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2167	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_EID_LBL	ecoInvoice Detail,order,product code,product name,ecocost version,quantity	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2166	2017-04-27 15:20:51	stevensg	2018-02-16 12:32:00	STEVENSG	1	40	\N	Grid_Descriptions_TT	displays all descriptive text comments for the process step	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2168	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_EID_TT	details of all items on the eco invoice, including quantity and ecocost version number	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2169	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_EOD_LBL	ecoInvoice Detail,order,product code,product name,ecoCost version,quantitiy	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2170	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_EOD_TT	details of all items on the eco invoice, including quantity and ecocost version number	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2171	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_FOD_LBL	Invoice Detail,Product code,Description,Unit price,Unit tax,Qty,Price,Tax,Total	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2172	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_FOD_TT	all financial invoice items with quantities and prices	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2173	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ForecastByDivision_LBL	Sales Forecast by Division,Division,sold last period,auto projected sales,adjusted forecast	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2174	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ForecastByDivision_TT	sales forecasts by company division with comparison to previous period sales	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2175	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ForecastByProcess_LBL	Sales Forecast by Process Model,Process Name,sold last period,auto projected sales,adjusted forecast	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2176	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ForecastByProcess_TT	sales forecasts for each process model with comparison to previous period sales	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2177	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ForecastByProduct_LBL	Sales Forecast by Product,Product code,Name,Proc.ID,last period,auto projected,adjusted forecast	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2178	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ForecastByProduct_TT	sales forecasts for each product with comparison to previous period sales	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2179	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Inputs_LBL	Inputs,Step,Description,Code,type,LCI,Qty,Unit,Scale	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2180	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Inputs_TT	list of all inputs to the selected process model Code=internal product code plus supplier code in parentheses Scale=qty is scaled when removed from inventory	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2185	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ModelSteps_LBL	Process: ,Step,Description,Inputs,Outputs,Documentation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2186	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ModelSteps_TT	currently displayed model steps with counts of the related records	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2187	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Outputs_LBL	Outputs,Step,Description,Dest.,%,Qty,Unit,Scale	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2188	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Outputs_TT	list of all outputs from the selected calculation model	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2189	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_PeriodAdjustment_LBL	Period forecast adjustment,Description,Value,Comment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2190	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_PeriodAdjustment_TT	days in current and previous periods with selected period's sales forecast factor over previous period	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2191	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Proportions_LBL	Proportional distribution of OHH_NAME by GROUP_METHOD,Code,Name,Forecast,Unit,% last,% calc,% this	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2192	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Proportions_TT	listing of all products with sales forecasts, calculated proportion of overhead and proportion to be assigned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2193	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Reactions_LBL	Step Reactions,Order,Description,Chem Reaction	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2194	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Reactions_TT	list of all reactions taking place within the selected process step	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2195	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Steps_LBL	Process Steps,Order,Description,Repeat	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2196	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_Steps_TT	all steps representing the selected process model	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2197	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilAttributes_LBL	,Indicator,Value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2198	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilAttributes_TT	list of all calculation indicators	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2199	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilCF_LBL	,Component,Indicator,Value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2200	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilCF_TT	list of all carbon footprint component and indicator values for the selected product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2201	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilCalculations_LBL	,When,Batch #,Size	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2202	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilCalculations_TT	list of all product batch calculations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2205	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilCategorisationRules_LBL	Categorisation code pairs; products matching the first pair will be assigned the second,Match Key,Match Value,Assign Key,Assign Value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2206	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilCategorisationRules_TT	categorisation rules will be applied in the order shown here; when a product matches a key/value pair in the left hand list, it will have the key/value pair in the right hand list assigned to it	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2207	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilChemCompounds_LBL	,name,InChI,CAS	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2208	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilChemCompounds_TT	list of all chemical compounds that make up the selected substance	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2209	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilChemistry_LBL	,Common name,InChI,Mol.wgt	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2203	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilCategorisationCodes_LBL	Categorisation codes,key,value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2210	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilChemistry_TT	list of chemical compounds for the selected product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2211	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilDefinition_LBL	,Description,Category,Sub category,ILCD category,class,rel.nat,cc's	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2212	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilDefinition_TT	list of all substances in the selected subcategory	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2213	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilDetails_LBL	Overhead account entries,date,source,source provider,product code,product name,vsn,quantity,comments	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2214	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilDetails_TT	the list of overhead detail items showing products utilised, where they have come from and the amounts concerned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2215	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilDocumentation_LBL	,Component,Type,Comment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2216	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilDocumentation_TT	list of all documentation included with the ecocost	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2219	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilIntegrity_LBL	,Component,Elem. flow,Generation,Count,Proportion	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2220	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilIntegrity_TT	list of all integrity values for the selected eco cost	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2221	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilLCI_LBL	,Component,Elem.flow,Service,Qty	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2222	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilLCI_TT	list of all LCI values used within the selected calculation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2223	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilLinkedProcessModels_LBL	,Calculation name,   ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2224	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilLinkedProcessModels_TT	list of all calculation models linked to the selected product but not necessarily used in production 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2227	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilMIPS_LBL	,Component,Indicator,Value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2228	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilMIPS_TT	list of components with indicators in the selected product/eco cost	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2231	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilOntology_LBL	,Tier 1,Tier 2,Tier 3,CC,Ind,op_ref	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2232	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilOntology_TT	list of ontology classifications for the selected component/elementary flow (may be filtered to show active classifications only)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2235	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilUsePhase_LBL	,Component,Service,Amount	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2236	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilUsePhase_TT	list of all elementary flows for the use phase of the selected product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2237	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Display_8	Record was not saved because XXXX was missing.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2238	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Heading_1	Application Navigation area	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2239	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Heading_10	If you see a field with a magenta border, 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2240	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Heading_11	A field with a light blue background must be a unique value.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2241	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Heading_12	Buttons represent actions you can take	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2242	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Heading_2	Record Navigation area - to the left	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2243	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Heading_3	Record Navigation - text search	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2244	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Heading_4	Record Navigation - criteria selection lists	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2245	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Heading_5	Record Navigation - result set	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2246	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Heading_6	The heading and some helpful information	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2247	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Heading_7	Within the grey area is the full information about the record you have selected on the left.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2248	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Heading_8	Any error messages are displayed at the bottom of the form.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2249	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Heading_9	If you see a field in white, you can alter the contents of that field.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2250	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Intro_1	The light yellow bar at top of screen is the Application Navigation area.  Use the drop down list to choose the function you want to access.  You will only see functions that you have been granted permission to use.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2251	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Intro_10	it will be a mandatory field and cannot be left blank	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2252	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Intro_11	more than 1 field light blue then a combination of those fields must be unique.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2253	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Intro_12	Clicking on + will create a new record;  click on pencil to write over an existing record; - will delete a record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2254	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Intro_2	All of the light green area is the record navigation area.  This area is used to find the record(s) you want to view.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2255	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Intro_3	There may or may not be a text search box in the top left corner.  If it is there you can do a text search for records.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2256	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Intro_4	There may or may not be a drop down list here.  If they are shown you can use these to locate certain groups of records.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2257	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Intro_5	The result set:  whatever criteria has been applied above will show a list of found records here.  Click a line in this list to display the full contents of the record in the light grey area.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2258	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Intro_6	will be displayed where you are seeing this text.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2259	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Intro_7	Further information may be hidden within tabs - click on a tab to see more information.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2260	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	HELP_Intro_9	If it is grey the field is display only and cannot be changed.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2319	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ICH_Heading	Incoming ecoCost Classification Rules	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2324	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ICH_Intro	assign properties to incoming ecoInvoice items using classification rules that will be applied on import	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2379	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	IMT_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2380	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	IMT_CBY_TT	user who created this record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2381	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	IMT_CWHEN_LBL	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2382	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	IMT_CWHEN_TT	creation date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2383	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	IMT_HEADER_LBL	import file has a header row	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2384	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	IMT_HEADER_TT	import file has a header row	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2385	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	IMT_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2386	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	IMT_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2387	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	IMT_MWHEN_LBL	modification timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2388	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	IMT_MWHEN_TT	modification timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2403	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	IVM_Heading	Inventory Movements	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2404	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	IVM_Intro	display all product movements into and out of inventory for a selected date range	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2417	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Inherited_LBL	Inh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2418	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Inherited_TT	ticked indicates that this variable can be inherited from a previous process	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2419	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	InitValue_TT	enter the initial value for the variable or leave empty if it will be assigned by calculation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2420	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	InitVaue_LBL	Initial value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2421	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	InputSource_LBL	source of input	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2422	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	InputSource_TT	An input can come from 4 possible sources.  Identify which source here and select the correct entry from the list below.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2423	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	InstructPM1_LBL	Clicking on the list above willl display further details here. 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2425	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	InstructPM2_LBL	Clicking on any of the first 3 columns will display the Steps.  	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2426	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	InstructPM3_LBL	Clicking on any of the remaining 5 columns will display the records associated with the cell.  For example: clicking on column 4 of line 2 will display all the Inputs associated with Step 2.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2427	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Integer_LBL	I	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2428	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Integer_TT	integer variable	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2469	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CAPITAL_ENDONYM_LBL	country capital in local language	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2470	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CAPITAL_ENDONYM_TT	country capital in local language	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2471	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CAPITAL_EXONYM_LBL	country capital in english	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2472	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CAPITAL_EXONYM_TT	country capital in english	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2473	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CAPITAL_TRANSLIT_ENDONYM_LBL	transliteration of capital	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2474	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CAPITAL_TRANSLIT_ENDONYM_TT	transliteration of capital in local language to latin text (usually english but sometimes french or others)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2475	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2476	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CBY_TT	user who created this record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2477	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_COUNTRY_TRANSLIT_ENDONYM_LBL	transliteration of country	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2424	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	InstructPM1_TT		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2478	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_COUNTRY_TRANSLIT_ENDONYM_TT	transliteration of country in local language to latin text (usually english but sometimes french or others)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2479	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CO_ENDONYM_LBL	country name in local language	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2480	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CO_ENDONYM_TT	country name in local language	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2481	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CO_EXONYM_LBL	country in english	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2482	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CO_EXONYM_TT	country in english	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2483	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CO_REF_ISO3_LBL	link to country table	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2484	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CO_REF_ISO3_TT	link to country table	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2485	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CWHEN_LBL	creation date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2486	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_CWHEN_TT	creation date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2487	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_LGREF_ISO3_LBL	link to languages table	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2488	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_LGREF_ISO3_TT	link to languages table	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2489	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_LG_REF_LBL	foreign key to language	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2490	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_LG_REF_TT	foreign key to language	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2491	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_MAINLANG_LBL	1 if this is the main language of the country	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2492	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_MAINLANG_TT	1 if this is the main language of the country	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2493	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2494	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_MBY_TT	user who last modified this record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2495	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2496	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2497	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_MWHEN_LBL	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2498	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_MWHEN_TT	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2499	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_OFFICIAL_LBL	1 if language is an official language of the country	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2500	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_OFFICIAL_TT	1 if language is an official language of the country	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2501	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2502	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LC_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2506	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_ACTIVE_LBL	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2507	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2508	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_CBY_TT	user who created this record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2509	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_CWHEN_LBL	creation date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2510	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_CWHEN_TT	creation date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2511	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_ENDONYM_LBL	endonym	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2512	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_ISO2_LBL	ISO 2 code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2513	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_ISO3_ALT_LBL	alternate ISO 3 code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2514	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_ISO3_LBL	ISO 3 code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2515	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2516	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2517	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_MWHEN_LBL	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2518	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_MWHEN_TT	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2519	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_NO_OF_SPEAKERS_LBL	No. of speakers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2520	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	LG_SEQ_LBL	record ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2533	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	LOGIN_FAILED	login failed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2534	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	LoginID_LBL	login ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2535	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	LoginID_TT	your unique login ID is entered here	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2536	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	LoginPW_LBL	password	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2546	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2547	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_CURRENCY_LBL	currency	Währung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2548	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_CURRENCY_TT	currency code - GBP, EUR	Währungscode - GBP, EUR	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2549	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2550	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_FROM_LBL	date from	stammen aus	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2551	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_FROM_TT	membership from	Mitgliedschaft von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2552	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_MBY_LBL	modified by	angepasst von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2553	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_MWHEN_LBL	modified when	Geändert wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2555	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_PSN_REF_TT	foreign key to PERSON	Fremdschlüssel für PERSON	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2556	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2557	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_TO_LBL	date to	Datum bis	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2558	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_TO_TT	membership to (valid for 1 year)	Mitgliedschaft (gültig für 1 Jahr)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2559	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_TYPE_LBL	type	Art	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2747	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ADDCRITERIATEXT	provide additional criteria in text search	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2748	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ADMINPWORD	administrator password must be at least 7 characters in length	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2749	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ALLCUSTOMERS	All customers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2750	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ALLORGSPRIVS	with privileges to select all Organisations, all records have been fetched	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2751	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ASSIGNROLESORGS	assign roles and group organisations to Users	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2752	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ATLEAST	There must be at least	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2753	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_BATCHSIZE	batch size	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2754	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CALCCOMPLETE	Calculation completed.  Do you wish to view the results?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2755	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CALCFAILED	calculation failed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2756	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CALCFAILINIT	Calculation failed to initiate.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2757	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CALCLOGREAD	calculation log read, fetching	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2758	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CALCQUEUED	Calculation queued for	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2759	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CALCRUNNING	Calculation is running.  You will be notified when it has completed.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2760	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CANCWITHOUTRETURN	cancelled without a form to return to	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2761	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CANNOTASSIGNTOPROD	cannot be assigned to product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2762	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CANNOTSUBMITECOINV	Invoice cannot be submitted to ecoInvoice because no product has a published ecoCost.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2763	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CANNOTVIEWRESULTS	Results cannot be viewed while editing data	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2764	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CHECKREGSERVER	Checking registration server...	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2765	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CLASSFIRSTCHAR	First character of Classification must be a letter of the alphabet.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2766	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CONFIRM	Are you sure?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2767	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CREATEUSERS	create new users	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2768	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_CUSTEXISTS	new Customer record already exists	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2769	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_DATAINTEGRITY	data integrity problem	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2770	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_DBCONNECTBROKEN	Connection to database is broken.  Please try again later.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2771	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_DECSEPARATOR	decimal separator	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2772	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_DEFAULTMODEL	Default model for 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2773	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_DELACL	Cannot delete link to accounting period	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2774	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_DELETEDCONTACTPLURAL	deleted contacts	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2775	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_DELETEDCONTACTSINGLE	deleted contact	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2776	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_DIALLOWOHFROMORG	you are not allowed to remove an overhead account from an organisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2777	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_DISALLOWDGFROMINV	you are not allowed to disassociate a delegate from an invoice 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2778	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_DISALLOWDGTOINV	you are not allowed to associate a delegate to an invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2779	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_DISALLOWOHTOORG	you are not allowed to connect an overhead account to an organisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2780	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ECOCOSTPUBLISHED	ecoCost for product has been published.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2781	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ECOINVSUBMIT	ecoInvoice was submitted 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2782	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_FETCHCORPPERSONFAIL	Service call to fetch corporate persons failed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2783	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_FIXERRORS	please fix the displayed errors	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2784	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_FORCECALCFAILED	forced calculation FAILED with error code 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2785	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_FORCECALCSUCCESS	forced calculation completed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2786	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_GT_MAXRETURN_e	con('>',inMaxReturnCount,' rows, please refine')	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2787	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_IMPABORT	Import aborted.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2788	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_IMPABORTERRORS	Import aborted due to excessive errors	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2789	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_IMPLCI	Imported generic LCI	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2790	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_IMPLCISUCCESS	LCI import successful	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2791	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_INFOMATCH	Information matches that on server.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2792	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_INFOMISMATCH	but information does NOT match that on server.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2794	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_INSERTPUB	Cannot create publication record for	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2795	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_INVALIDPRDREF	Invalid - value did not identify a product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2796	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_INVALIDREENTER	invalid entry - re-enter	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2797	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_INVALIDSUBMISSION	INVALID SUBMISSION	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2798	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_INVALIDTAXBAND	Tax Band has invalid value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2799	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_LOGINFAILEDCOMPANY	login failed for company	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2800	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_LOGINFAILEDRETRY	login failed - try again	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2801	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MASSEQUALONE	total mass must equal 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2802	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MEMBRECORDED	has already had membership recorded	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2803	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MICROMISMATCH	product linked to a different retail product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2804	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MINBATCH	batch quantity must be greater than zero	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2805	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MISSINGCURRENCY	You must have a currency symbol to present the correct banking details.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2806	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MISSINGPRDORCMP	No product code or substance name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2807	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MISSINGPRDSUPPCODE	product has no supplier code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2808	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MODELID	model id	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2809	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MODELNOOUTPUT	calculation model does not have a product output	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2810	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MODEL_FIRSTSTEP	Step 1 - Inputs	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2811	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MODEL_LASTSSTEP	Final Step - Product output	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2812	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MODEL_RESALESTEP1	Supplier product input	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2813	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MODEL_RESALESTEP2	Inputs	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2814	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MODEL_RESALESTEP3	Resale product output	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2815	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_MULTIGO	multiple group org links when not expected	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2816	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NAMEDCONTACT	named contact people authorised to access the registration record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2817	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NEWCONTACTPLURAL	new contacts	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2818	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NEWCONTACTSINGLE	new contact	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2819	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NEWMODELVERSION	Please indicate whether this will be a new version of the current model or a new model altogether.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2820	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NEWPWORD	new password must be at least 7 characters in length	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2821	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NOCALCSELECT	no calculation model selected	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2822	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NOEMPTYCMPNAME	composite name cannot be left blank	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2823	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NONEXIST	does not exist	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2824	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NOQUEUE	There are no records in the queue	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2825	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NORETURNFORM	there is no previous form to return to	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2826	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NOSERVCALL	No service call made.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2827	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NOSUBPROCESS	No subprocess selected	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2828	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NOTASSIGN_PROD	cannot be assigned to product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2829	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NOTFOUND	not found	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2830	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NOTVALIDPROD	is not a valid product code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2831	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_NOTXLSX	not recognised as a .xlsx file	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2832	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ONTOLOGY	Ontology	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2833	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ONTUNKNOWN	Unknown ontology	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2834	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_PREVCOMMENTS	Earlier comments	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2835	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_PROVIDEMORE	Provide more characters to reduce result set.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2836	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_PWORDCHANGED	password changed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2837	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_PWORDMIN	password must be at least 7 characters in length	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2838	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_PWORDMISMATCH	passwords do not match	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2839	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_RAWNODISP	raw - no display -	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2840	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_RECORDCOUNT	record count of	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2841	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_REFINE	please refine your search	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2842	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_REGSERVAVAILABLE	Registration server is available.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2843	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_REGSERVUNAVAILABLE	Registration server is not available.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2844	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ROWSINSERTED	records inserted	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2845	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ROWSUSINGBATCH	rows using batch id of	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2846	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_ROWSUSINGPROD	rows using product id of	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2847	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_SAVESETTINGS	If you wish to save your settings, please enter a name for the template and click ok	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2848	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_SAVESETTINGSCHANGED	The template has been changed.  If you wish to save it, click ok.  To save it under a different name, change it here first.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2849	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_SERVCALL_FAILED	Service call FAILURE ! 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2850	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_SERVCALL_SUCCESS	Service call successful	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2851	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_SERVICESTATUS	Service status 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2852	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_SUBMITCANCELLED	Submission cancelled	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2853	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_SUBMITSUCCESS	Submission successful	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2854	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_SUPPNAMECODEMISMATCH	Supplier code does not match supplier name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2855	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_SUPPNAMENOCODE	Supplier name without supplier product code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2856	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_SUPPNAMENOTFOUND	Supplier name not found:	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2857	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_SUPPNOTFOUND	Supplier not found	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2858	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_THOUSEPARATOR	thousands separator	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2859	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_TOOMANYPROD	Too many products using	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2860	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_TOOMANYROWS	too many rows returned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2861	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_TYPEMISMATCH	data type mismatch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2862	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_UNABLERECOVER	Unable to recover useful data.  Reloading from database.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2863	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_UNEXPECTEDERR	unexpected error occurred, unable to return	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2865	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_UNSPECIFIEDUSER	User type not specified	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2866	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_UNSUPPORTEDIMPORT	not supported for import	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2867	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_UPDATEBUSRECORD	updated businss record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2868	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_UPDATEDCONTACTPLURAL	updated contacts	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2869	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_UPDATEDCONTACTSINGLE	updated contact	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2871	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	MSG_VALIDEMAILMANDATORY	this must be a valid email address	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2890	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	NA_ON_FIRST_STEP	selecting output from previous step within the first step is not appropriate	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2864	2017-04-27 15:20:51	stevensg	2017-07-04 16:30:00	STEVENSG	1	3	\N	MSG_UNRECOGNISEDEOL	does not have a recognised end-of-line character sequence	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2870	2017-04-27 15:20:51	stevensg	2018-04-12 11:27:00	STEVENSG	2	3	\N	MSG_USERMANAGE	User management	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2917	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Name_LBL	name of input	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2918	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Name_TT	displays the name of the product, substance or overhead	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2919	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	NavigationList	you can access the following:	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2950	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	OHD_Heading	Overhead Account Movements	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2951	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	OHD_Intro	details of overhead account assignments	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2964	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	OHD_REFS	purchased and assigned overheads	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2967	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	OHH_ALL_RECORDS	All Overhead Accounts	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2972	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	OHH_Heading	Overhead Accounts	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2973	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	OHH_Intro	creation of overhead accounts and assignment to group organisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3061	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	OP_Heading	Ontology Classifications for Products	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3062	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	OP_Intro	view the detailed classification records	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3081	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ORH_Heading	Overheads Review	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3082	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ORH_Intro	review sales forecasts and assign overheads proportionally to products	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3091	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ORH_Period_1	Year	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3092	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ORH_Period_12	Month	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3093	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ORH_Period_13	4 weeks	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3094	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ORH_Period_4	Quarter	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3095	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ORH_Period_52	Week	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3110	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ORH_daysprev	days in previous period	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3111	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ORH_daysthis	days in selected period	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3112	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ORH_periodadj	seasonal adjustment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3159	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	OTHER	other period	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3181	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Ontology_LBL	set ontology	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3182	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Ontology_TT	display any override to the default ontology	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3183	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	OutputDestination	Destination of output	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3184	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	OutputName_LBL	name of the output	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3185	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	OutputName_TT	displays the stored name of the product, substance or by-product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3186	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Overhead_LBL	oh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3187	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Overhead_TT	overhead item	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3288	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PCL_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3291	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PCL_CODE_TT	classification system's identifying code for the product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3294	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PCL_PRD_REF_LBL	foreign key to Product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3298	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PCL_SUBCODE_LBL	classification subreferences	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3300	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PCL_TYPE_LBL	classification type, eg. ISO	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3342	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PC_Heading	Product classification	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3343	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PEERS_Heading	PEERS Gateway	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3362	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PERMISSIONS_Heading	Permissions definition	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3363	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PERMISSIONS_Intro	create new permissions, assign roles to permissions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3364	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PER_ALL_RECORDS	All Permissions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3365	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	PER_ASSIGNED_ALL_ROLES	Permission has been assigned to all Roles	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3366	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3367	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3368	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_CWHEN_LBL	created timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3369	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_CWHEN_TT	timestamp of when record was created	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3370	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_DESC_EN_LBL	description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3371	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_DESC_EN_TT	descriptive label (English) eg. create users, modify process models, etc.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3372	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_LABEL_LBL	permission code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3373	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_LABEL_TT	unique permission code used by the application to assign access	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3374	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3375	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3376	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3377	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3378	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_MWHEN_LBL	modified when	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3379	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_MWHEN_TT	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3380	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PER_NEW	Enter name of  new permission	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3381	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PER_ROLE_LIST	Roles using this Permission	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3382	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PER_ROL_ADD	Add role to Permission	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3383	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_SEQ_LBL	record ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3384	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PER_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3405	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	PF_REFS	reference to product, process ordivision	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3434	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_BUSUNIT_LBL	business unit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3435	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_BUSUNIT_TT	If this product is produced by a company organised into business units, identify the business unit here.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3436	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_CATEGORY_LBL	product category	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3437	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_CATEGORY_TT	If the company sells more than a few products it can be very useful to group similar products into categories.  It used for analysis.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3438	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3439	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_CBY_TT	Identity of person who created this record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3440	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_CMP_REF_LBL	foreign key to Composite	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3441	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_CMP_REF_TT	foreign key to Composite when product is a calculation by-product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3442	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_COSTCENTRE_LBL	cost centre	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3443	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_COSTCENTRE_TT	Larger companies will usually identify groups within the company that provide a service to a wide variety of people such as Human Resources, IT etc.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3444	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_CWHEN_LBL	created when	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3445	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_CWHEN_TT	Timestamp of when this record was created.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3446	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_DIVISION_LBL	division	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3447	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_DIVISION_TT	If this product is produced by a large company that is organised into Divisions, identify that division here.  It used to share the overheads of the company with more accuracy.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3448	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3449	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_MBY_TT	Timestamp of when record was last modified.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3450	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_MCOUNT_LBL	modifcation count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3451	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_MCOUNT_TT	modifcation count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3452	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_MWHEN_LBL	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3453	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_MWHEN_TT	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3454	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_PLANT_LBL	factory	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3455	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_PLANT_TT	If this product is produced by a large company that has more than one factory, identify that factory here.  It used to share the overheads of the company with more accuracy.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3456	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_PRD_REF_LBL	product pointer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3457	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_PRD_REF_TT	reference to product record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3458	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_PROJECT_LBL	project	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3459	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_PROJECT_TT	If this product is associated to a particular project, identify that project here.  It used to share the overheads of the company with more accuracy.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3460	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_SUPPRESS_ECOCOST_LBL	suppress ecocost	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3461	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_SUPPRESS_ECOCOST_TT	if checked, this product's ecoCost will not be transmitted to customers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3462	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_TAX_BAND_LBL	VAT band	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3463	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_TAX_BAND_TT	There may be more than one VAT tax rate.  Identify the VAT tax band here.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3464	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_UNIT_PRICE_LBL	price per unit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3465	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PID_UNIT_PRICE_TT	price per PRD_UNIT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3510	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PMS	Step	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3531	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PM_ALL_RECORDS	All Models	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3532	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PM_Heading	Calculation models	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3533	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PM_Intro	models used in the calculation of products' ecoCosts	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3552	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PRD_ALL_RECORDS	All Products	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3556	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_BRAND_TT	If this product is part of a brand (e.g. Special K) then denote that here.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3559	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_CWHEN_LBL	created	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3563	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_DESC_LBL	full description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3567	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_ECOCOST_UOS_CODE_LBL	eco cost units	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3569	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_EO_REF_LBL	supplier or customer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3570	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_EO_REF_TT	External company who provided this product.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3571	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_GO_REF_LBL	internal company	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3572	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_GO_REF_TT	reference to internal company	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3573	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PRD_Heading	Products	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3565	2017-04-27 15:20:51	stevensg	2018-03-09 14:40:00	MOSTYNRS	1	1	\N	PRD_DISCONTINUED_LBL	discontinued	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3562	2017-04-27 15:20:00	stevensg	2017-08-04 11:58:00	STEVENSG	2	1	\N	PRD_MASS_FACTOR_TT	factor to convert package size to kilograms when product is not measured in mass units	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3561	2017-04-27 15:20:00	stevensg	2017-08-04 11:58:00	STEVENSG	2	1	\N	PRD_MASS_FACTOR_LBL	mass factor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3555	2017-04-27 15:20:51	stevensg	2018-03-09 12:02:00	MOSTYNRS	4	1	\N	PRD_BRAND_LBL	brand	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3568	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_ECOCOST_UOS_CODE_TT	taken from sysunitsynonyms for the eco cost record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3566	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_DISCONTINUED_TT	date when the product will be excluded from overhead forecasts	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3564	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_DESC_TT	full description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3558	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3560	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_CWHEN_TT	created timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3557	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3554	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_BARCODE_TT	barcode alphanumeric translation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3553	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_BARCODE_LBL	barcode alphanumeric translation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3576	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PRD_Intro	all group products including package information	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3580	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3581	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_META_LBL	meta record flag	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3582	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_META_TT	meta record flag	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3585	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_MICRO_PRD_REF_LBL	foreign key to resale product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3586	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_MICRO_PRD_REF_TT	foreign key to resale product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3587	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_MWHEN_LBL	modified when	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3588	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_MWHEN_TT	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3589	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_NAME_LBL	product name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3592	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3593	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_SERVICE_UNIT_LBL	service unit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3594	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_SERVICE_UNIT_TT	service unit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3597	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_SUPP_PRODCODE_LBL	supplier's product code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3598	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_SUPP_PRODCODE_TT	This code is the one used by the supplier to identify their product when they sell it to us.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3600	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	PRD_UNIT_DIVISOR_TT	divisor to use to equate PRD_SIZE to eco invoice units	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3595	2017-04-27 15:20:51	stevensg	2017-06-15 14:41:56	STEVENSG	4	1	\N	PRD_SIZE_LBL	package size	Packungsgrösse	Paketstorlek	\N	包装尺寸	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3575	2017-04-27 15:20:51	stevensg	2018-03-09 14:33:00	MOSTYNRS	2	1	\N	PRD_INT_PRODCODE_TT	Internal product code.  This may be different from a suppliers product code.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3574	2017-04-27 15:20:51	stevensg	2018-03-09 14:39:00	MOSTYNRS	5	1	\N	PRD_INT_PRODCODE_LBL	product code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3591	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3590	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_NAME_TT	product name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3584	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_MFR_FBACK_SERVICE_TT	URL of manufacturer's feedback service	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3583	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_MFR_FBACK_SERVICE_LBL	URL of manufacturer's feedback service	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3579	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3578	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3577	2017-04-27 15:20:51	stevensg	2018-03-09 14:47:00	MOSTYNRS	1	1	\N	PRD_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3599	2017-04-27 15:20:51	stevensg	2018-03-09 14:48:00	MOSTYNRS	1	1	\N	PRD_UNIT_DIVISOR_LBL	divisor to use to equate PRD_SIZE to eco invoice units	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3647	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	PRM_DUPLICATE	cannot be used.  It is the name of an existing process model.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3602	2017-04-27 15:20:51	stevensg	2018-06-14 15:26:00	STEVENSG	3	1	\N	PRD_UOS_CODE_TT	unit of measure	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3684	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	PROPORN_MAND_ON_BYPRODUCT	Proportion of ecoCost is required when by-product is sent to inventory.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3689	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PSC	Calculation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3716	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PSD	Document	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3739	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PSI	Input	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3766	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	PSI_REFS	reference to process, product, composite or overhead	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3794	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_ACTIVE_TT	person is active particpant (or alive)	Person ist aktiv (oder lebendig)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3795	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3796	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_COMPANY_LBL	company	Unternehmen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3798	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_COUNTRY_LBL	country	Land	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3822	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PSO	Output	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3855	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	PSO_REFS	reference to product or composite	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3800	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3801	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_EMAIL_LBL	email	Email	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3802	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_EMAIL_TT	email address of person	E-Mail-Adresse der Person	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3803	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_FIRST_NAME_LBL	first name	Vorname	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3805	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_GO_REF_TT	foreign key to internal organisation	Fremdschlüssel zur internen Organisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3806	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_MBY_LBL	modified by	angepasst von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3807	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_MWHEN_LBL	modified when	Geändert wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3808	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_PHONE_LBL	phone	Telefon	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3809	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_PHONE_TT	phone number	Telefonnummer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3811	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_PHOTOID_NO_TT	<lbl>photo id no.</lbl><tt>Serial number of phot id, to be presented at course to validate person attending.</tt>	<lbl> Photo id nein </lbl> <tt>Seriennummer der Fot-ID, die zur Vorlage der Person vorgestellt werden soll.</tt>	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3812	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_PHOTOID_TYPE_LBL	<lbl>photo id type</lbl><tt>passport, drivers licence, ID card  etc</tt>	<lbl> Foto-ID-Typ </lbl> <tt>Pass, Führerschein, Ausweis usw.</tt>	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3814	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3815	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_SEX_LBL	sex	Sex	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3816	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_SEX_TT	sex is required if shared accommodation is requested	Sex ist erforderlich, wenn eine gemeinsame Unterkunft angefordert wird	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3817	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_SPEAKER_BIO_LBL	bio	Bio	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3818	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_SPEAKER_BIO_TT	speaker's biography for inclusion on website	Sprecher Biographie für die Aufnahme auf Website	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3819	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_SPOUSE_NAME_LBL	spouse name	Name des Ehepartners	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3820	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_SPOUSE_NAME_TT	first name of spouse	Vorname des Ehepartners	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3821	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_SURNAME_LBL	surname	Familien-oder Nachname	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3866	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PSP	Process	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3885	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PSR	Reaction	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3906	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PSV	Variable	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3913	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PSV_InitialValue_LBL	Initial value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3914	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PSV_InitialValue_TT	If the variable has a fixed initial value, state the value here.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3963	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_METHOD_LBL	method	Methode	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3969	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PeriodAdjDesc1_TXT	days in previous period	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3970	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PeriodAdjDesc2_TXT	days in selected period	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3971	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PeriodAdjDesc3_TXT	seasonal adjustment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3972	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PrevOutput_LBL	prev	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3973	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PrevOutput_TT	item taken from a previous step in the process	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3974	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Product_LBL	inv	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3975	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Product_TT	item from/to inventory	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3976	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ProportionTotal_LBL	proportion total %	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3940	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PX_0_DINNER_LBL	dinner	Abendessen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3942	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PX_0_NIGHT_LBL	accommodation	Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3943	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PX_AGREED_PRICE_LBL	agreed price	Vereinbarter Preis	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3944	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PX_DG_REF_LBL	delegate	delegieren	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3946	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PX_MWHEN_LBL	pax modified	Pax modifiziert	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3947	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PX_NAME_LBL	name	Name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3948	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PX_NAME_TT	name of spouse or child (when not the delegate)	Name des Ehepartners oder des Kindes (wenn nicht der Delegierte)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3949	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PX_ROLE_LBL	relationship	Beziehung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3950	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PX_ROLE_TT	which member of the party does this PAX record represent	Welches Mitglied der Partei diese PAX-Aufzeichnung repräsentiert	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3951	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PX_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3952	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_AMOUNT_LBL	amount	Menge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3953	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_AMOUNT_TT	amount received	Betrag erhalten	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3954	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3955	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_CHARGES_LBL	charges	Gebühren	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3957	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_COMMENT_LBL	comment	Kommentar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3958	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3959	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_DATE_LBL	date	Datum	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3960	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_DG_REF_LBL	delegate	delegieren	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3962	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_MBY_LBL	modified by	angepasst von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3964	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_METHOD_TT	method of payment ( paypal, bank, cc )	Zahlungsmethode (paypal, bank, cc)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3965	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_MWHEN_LBL	payment modified	Zahlung geändert	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3966	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3967	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_STMT_LBL	entry reference	Eintragsreferenz	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3968	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_STMT_TT	statment page number and line to identify payment record	Statement-Seitennummer und Zeile zur Identifizierung der Zahlungsaufzeichnung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3977	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ProportionTotal_TT	total percentage of adjusted proportions for the selected overhead account	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4056	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Qty_LBL	quantity	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4057	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Qty_TT	quantity of the substance	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4240	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_CHAR_LBL	text data	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4234	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_ACTIVE_LBL	active?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4235	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_ACTIVE_TT	If unchecked, accessing this record in the rest of the system will be suppressed.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4236	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_BIN_LBL	binary value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4237	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_BIN_TT	container for binary data	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4238	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4239	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_CBY_TT	user who created this record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4241	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_CHAR_TT	this box can hold a large volume of text	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4242	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFG_CLASSES	Glocal reference classes	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4243	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_CLASS_LBL	classification	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4244	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_CLASS_TT	classification column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4245	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_CWHEN_LBL	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4246	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4247	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_DATE_LBL	date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4248	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_DATE_TT	To refer to a date, use this field.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4249	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_DESC_LBL	description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4250	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_DESC_TT	description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4252	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_EFFECTIVE_TT	if record has a shelf life, the from and to date can be set	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4254	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_EXPIRES_TT	if record has a shelf life, the from and to date can be set	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4255	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFG_Heading	Global System Configuration	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4256	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_INT_LBL	integer value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4257	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_INT_TT	Use this field for integers.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4258	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFG_Intro	Configuration values that apply across ALL installations of the system	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4259	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_JSON_LBL	JSON	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4260	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4261	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4262	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_MWHEN_LBL	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4263	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_MWHEN_TT	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4264	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_NUMBER_LBL	floating number	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4265	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_NUMBER_TT	Use this field for real numbers.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4266	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_ORDER_LBL	ordering column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4267	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_ORDER_TT	ordering column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4268	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4269	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4270	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFG_VALUES	Global values	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4271	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_VALUE_LBL	specific reference value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4272	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFG_VALUE_TT	specific reference value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4273	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_ACTIVE_LBL	active?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4274	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_ACTIVE_TT	If unchecked, accessing this record in the rest of the system will be suppressed.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4275	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_BIN_LBL	binary value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4276	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_BIN_TT	binary content	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4277	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_CBY_LBL	creator	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4278	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_CBY_TT	creator	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4279	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_CHAR_LBL	big character column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4280	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_CHAR_TT	big character column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4281	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFL_CLASSES	Local reference classes	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4282	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_CLASS_LBL	classification	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4283	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_CLASS_TT	classification column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4284	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_CWHEN_LBL	created	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4285	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4286	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_DATE_LBL	date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4287	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_DATE_TT	To refer to a date, use this field.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4288	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_DESC_LBL	description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4289	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_DESC_TT	description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4291	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_EFFECTIVE_TT	if record has a shelf life, the from and to date can be set	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4293	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_EXPIRES_TT	if record has a shelf life, the from and to date can be set	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4294	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFL_Heading	Group Configuration	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4295	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_INT_LBL	integer value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4296	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_INT_TT	Use this field for integers.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4297	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFL_Intro	Configuration values that apply across all group companies	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4298	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_JSON_LBL	JSON	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4299	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_JSON_TT	this field will accept valid JSON only.  It can be validated with the on screen button before saving.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4300	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4301	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4302	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4303	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4304	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_MWHEN_LBL	modified	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4305	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_MWHEN_TT	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4306	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_NUMBER_LBL	floating number	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4307	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_NUMBER_TT	number value with any scale/precision	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4308	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_ORDER_LBL	ordering column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4309	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_ORDER_TT	ordering column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4310	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4311	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4312	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_TIME_LBL	time of day	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4292	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	1	\N	RFL_EXPIRES_LBL	valid to date	\N	\N	\N	\N	\N	Válido hasta la fecha	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4313	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_TIME_TT	time of day	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4314	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFL_VALUES	Local values	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4315	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_VALUE_LBL	specific reference value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4316	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFL_VALUE_TT	specific reference value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4317	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_ACTIVE_LBL	active?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4318	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_ACTIVE_TT	If unchecked, accessing this record in the rest of the system will be suppressed.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4319	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_BIN_LBL	binary value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4320	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_BIN_TT	binary value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4321	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_CBY_LBL	creator	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4322	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_CBY_TT	creator	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4323	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_CHAR_LBL	big character column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4324	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_CHAR_TT	big character column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4325	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFO_CLASSES	Company reference classes	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4326	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_CLASS_LBL	classification column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4327	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_CLASS_TT	classification column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4328	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_CWHEN_LBL	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4329	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4330	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_DATE_LBL	date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4331	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_DATE_TT	To refer to a date, use this field.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4332	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_DESC_LBL	description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4333	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_DESC_TT	description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4335	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_EFFECTIVE_TT	if record has a shelf life, the from and to date can be set	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4337	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_EXPIRES_TT	if record has a shelf life, the from and to date can be set	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4338	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_GO_REF_LBL	foreign key to GroupOrganisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4339	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_GO_REF_TT	foreign key to GroupOrganisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4340	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFO_Heading	Company Configuration	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4341	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_INT_LBL	integer value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4342	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_INT_TT	Use this field for integers.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4343	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFO_Intro	Configuration values for a specific company within the group	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4344	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_JSON_LBL	JSON	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4345	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_JSON_TT	this field will accept valid JSON only.  It can be validated with the on screen button before saving.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4346	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4347	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4348	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4349	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4350	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_MWHEN_LBL	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4351	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_MWHEN_TT	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4352	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_NUMBER_LBL	floating number	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4353	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_NUMBER_TT	number with any scale/precision	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4354	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_ORDER_LBL	ordering column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4355	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_ORDER_TT	ordering column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4356	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4357	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4358	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_TIME_LBL	time of day	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4359	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_TIME_TT	time of day	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4360	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFO_VALUES	Company configuration values	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4361	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_VALUE_LBL	specific reference value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4362	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFO_VALUE_TT	specific reference value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4363	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_ACTIVE_LBL	active?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4436	2017-04-27 15:20:51	stevensg	2018-01-18 13:01:00	MOSTYNRS	1	1	\N	ROL_ACTIVE_LBL	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4546	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_CLASS_TT	select the form to which this feedback is relevant	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4364	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_ACTIVE_TT	when ticked, indicates that the value is to be used within the system	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4365	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_BIN_LBL	binary value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4366	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_BIN_TT	binary value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4367	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_CBY_LBL	creator	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4368	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_CBY_TT	creator	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4369	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_CHAR_LBL	big character column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4370	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_CHAR_TT	big character column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4371	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFU_CLASSES	User preference classes	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4372	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_CLASS_LBL	classification column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4336	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	1	\N	RFO_EXPIRES_LBL	valid to date	\N	\N	\N	\N	\N	Válido hasta la fecha	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4373	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_CLASS_TT	classification column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4374	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_CWHEN_LBL	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4375	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4376	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_DATE_LBL	date column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4377	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_DATE_TT	date column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4378	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_DESC_LBL	description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4379	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_DESC_TT	description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4384	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_GO_REF_LBL	foreign key to entgrouporganisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4385	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_GO_REF_TT	foreign key to entgrouporganisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4386	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFU_Heading	User Preferences	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4387	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_INT_LBL	integer value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4388	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_INT_TT	integer value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4389	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RFU_Intro	user's personal system preferences when logged in to the current company	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4390	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_JSON_TT	this field will accept valid JSON only.  It can be validated with the on screen button before saving.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4391	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4392	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4393	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4394	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4395	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_MWHEN_LBL	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4396	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_MWHEN_TT	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4397	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_NUMBER_LBL	floating number	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4398	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_NUMBER_TT	number with any scale/precision	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4399	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_ORDER_LBL	ordering column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4400	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_ORDER_TT	ordering column	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4401	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4402	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4403	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_TIME_LBL	time of day	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4404	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_TIME_TT	time of day	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4405	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_USR_REF_LBL	foreign key to uausers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4406	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_USR_REF_TT	foreign key to ususers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4407	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_VALUE_LBL	specific reference value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4408	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RFU_VALUE_TT	specific reference value	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4409	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_Inherited_LBL	inherited	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4410	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_Inherited_TT	Only applicable if a process calls other processes. Check here if the scope of the variable has to be available across multiple processes.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4411	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_Inherited_TXT	inherited	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4412	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_InputSource_LBL	input source	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4413	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_InputSource_TT	An input has to have its content explicitly defined from a number of possible sources.  Identify that source here.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4414	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_InputSource_TXT	generic LCI,product,proxy product,composite,overhead	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4417	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_OutputDestination_LBL	output destination	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4418	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_OutputDestination_TT	An output has to be assigned to a destination with a specific record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4419	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_OutputDestination_TXT	product,composite,generic component	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4420	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_PSV_TYPE_LBL	type of data	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4421	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_PSV_TYPE_TT	You must specify what sort of data the variable will store.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4422	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_PSV_TYPE_TXT	integer,real,character	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4423	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_Persistent_LBL	persistent	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4424	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_Persistent_TT	Normally a variable exists only within the step it is defined.  Check here if the scope of the variable has to extend across multiple steps.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4425	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	RG_Persistent_TXT	persistent	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4382	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	1	\N	RFU_EXPIRES_LBL	validity end date	\N	\N	\N	\N	\N	Fecha de finalización de validez	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4383	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	1	\N	RFU_EXPIRES_TT	validity end date	\N	\N	\N	\N	\N	Fecha de finalización de validez	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4434	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ROLES_Heading	Role management	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4435	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ROLES_Intro	create new Roles, assign permissions and users to Roles	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4438	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ROL_ALL_RECORDS	All Roles	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4439	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	ROL_ASSIGNED_ALL_PERMS	Role has been assigned all Permissions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4440	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	ROL_ASSIGNED_ALL_USERS	Role has been assigned to all Users	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4441	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4442	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4443	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_CWHEN_LBL	created timetamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4444	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_CWHEN_TT	created timetamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4445	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4446	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4447	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4448	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4449	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_MWHEN_LBL	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4450	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_MWHEN_TT	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4451	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_NAME_LBL	name of the role, eg. auditor, administrator, manager, 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4452	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_NAME_TT	name of the role, eg. auditor, administrator, manager, 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4453	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ROL_NEW	Enter name of new role	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4454	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ROL_PER_ADD	Add permission to Role	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4455	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ROL_PER_LIST	Permissions assigned to Role	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4458	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_ROL_REF_LBL	inherit permissions from 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4459	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_ROL_REF_TT	inherit permissions from 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4460	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4461	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ROL_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4462	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ROL_USR_ADD	Add user to Role	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4463	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ROL_USR_LIST	Users for selected Role	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4466	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RP_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4467	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RP_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4468	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RP_CWHEN_LBL	created when	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4469	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RP_CWHEN_TT	created timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4470	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RP_PER_REF_LBL	foreign key to uaPermissions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4471	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RP_PER_REF_TT	foreign key to uaPermissions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4472	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RP_ROL_REF_LBL	foreign key to uaRoles	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4473	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RP_ROL_REF_TT	foreign key to uaRoles	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4474	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RP_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4475	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	RP_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4437	2017-04-27 15:20:51	stevensg	2018-01-18 13:03:00	MOSTYNRS	1	1	\N	ROL_ACTIVE_TT	The role can be deactivated while still assigned to a user.  This is typically a temporary measure to disable the use of a particular function.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4456	2017-04-27 15:20:51	stevensg	2018-01-18 13:18:00	MOSTYNRS	1	1	\N	ROL_REVOKE_LBL	revoke	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4457	2017-04-27 15:20:51	stevensg	2018-01-18 13:19:00	MOSTYNRS	1	1	\N	ROL_REVOKE_TT	When checked, this role will REVOKE the permissions assigned to it from the user.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4503	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Real_LBL	R	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4504	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Real_TT	real number variable	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4539	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	SEQ_Heading	Sequential primary keys	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4540	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	SEQ_Intro	with ability to adjust them	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4543	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4544	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4545	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_CLASS_LBL	name of form	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4547	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_CLASS_VSN_LBL	class version number / date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4548	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_CLASS_VSN_TT	class version number / date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4549	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_COMMENT_LBL	comment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4550	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_COMMENT_TT	enter as much feedback detail here as required	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4551	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_COMPLETE_LBL	displayed as a checkbox, marks when developer/designer considered the topic addressed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4552	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_COMPLETE_TT	displayed as a checkbox, marks when developer/designer considered the topic addressed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4553	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_CWHEN_LBL	created when	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4554	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_CWHEN_TT	created when	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4555	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_FROM_LBL	user name of person making comment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4556	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_FROM_TT	user name of person making comment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4557	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4558	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4559	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4560	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4561	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_MWHEN_LBL	modified when	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4562	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_MWHEN_TT	modified when	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4563	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_REPLY_LBL	developers reply to comment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4564	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_REPLY_TT	developers reply to comment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4565	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_RESP_DUE_LBL	requested response date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4566	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_RESP_DUE_TT	requested response date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4567	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_RESP_TYPE_LBL	user can request a type of response	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4568	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_RESP_TYPE_TT	user can request a type of response	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4569	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4570	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4571	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_TOPIC_LBL	thread heading	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4572	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_TOPIC_TT	thread heading	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4573	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_TYPE_LBL	type of comment	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4574	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SF_TYPE_TT	type of comment: BUG, ENHANCEMENT, BEHAVIOUR	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4588	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLE_CODE_LBL	primary grouping category	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4589	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLE_CODE_TT	primary grouping category	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4590	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLE_CWHEN_LBL	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4591	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLE_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4592	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLE_MESSAGE_LBL	message	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4593	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLE_MESSAGE_TT	message	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4594	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLE_SUBCODE_LBL	secondary grouping category	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4595	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLE_SUBCODE_TT	secondary grouping category	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4596	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLV_CODE_LBL	primary grouping category	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4597	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLV_CODE_TT	primary grouping category	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4598	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLV_CWHEN_LBL	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4599	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLV_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4600	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLV_MESSAGE_LBL	message	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4601	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLV_MESSAGE_TT	message	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4602	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLV_SUBCODE_LBL	secondary grouping category	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4603	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SLV_SUBCODE_TT	secondary grouping category	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4614	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SMH_CWHEN_LBL	semaphore created	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4615	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	SMH_CWHEN_TT	creation date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4616	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	SMH_REFS	SMH_PKEYI and SMH_PKEY_C	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4624	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	SQLGEN_Heading	SQL Help	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4625	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	SQLGEN_Intro	generate SQL to fetch columns from related tables	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4644	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_BROWSER_LBL	appName and userAgent info	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4645	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_BROWSER_TT	appName and userAgent info	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4646	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_COUNT_END_LBL	in anticipation of IP v6	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4647	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_COUNT_END_TT	in anticipation of IP v6	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4648	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_DB_REQUESTS_LBL	total number of DB calls	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4649	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_DB_REQUESTS_TT	total number of DB calls	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4650	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_DELETES_LBL	total number of rows deleted from the DB	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4651	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_DELETES_TT	total number of rows deleted from the DB	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4652	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_DEVICE_SIZE_LBL	screen resolution of device	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4653	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_DEVICE_SIZE_TT	screen resolution of device	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4654	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_FETCHES_LBL	total number of rows fetched from the DB	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4655	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_FETCHES_TT	total number of rows fetched from the DB	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4656	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_GL_REF_LBL	foreign key to geoLookup	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4657	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_GL_REF_TT	foreign key to geoLookup	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4658	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_GO_REF_LBL	group organisation short name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4659	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_GO_REF_TT	group organisation short name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4660	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_INIT_CLASS_LBL	initial class that created task	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4661	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_INIT_CLASS_TT	initial class that created task	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4662	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_INSERTS_LBL	total number of rows inserted into the DB	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4663	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_INSERTS_TT	total number of rows inserted into the DB	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4664	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_IP4_LBL	IP address v4 format	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4665	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_IP4_TT	IP address v4 format	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4666	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4667	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4668	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_TYPE_LBL	(S)tartup Task, (R)emote Task	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4669	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_TYPE_TT	(S)tartup Task, (R)emote Task	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4670	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_ULA_REF_LBL	only applies when user is identified with a login screen.  Won't apply to any public facing forms.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4671	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_ULA_REF_TT	only applies when user is identified with a login screen.  Won't apply to any public facing forms.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4672	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_UPDATES_LBL	total number of rows updated in the DB	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4673	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	STS_UPDATES_TT	total number of rows updated in the DB	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4674	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	SUPPLIER_LBL	supplier	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4675	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	SUPPLIER_TT	full name of the supplier	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4676	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	SUPP_EO_NAME_LBL	supplier's name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4677	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	SUPP_EO_NAME_TT	name of the supplier	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4678	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	SUPP_Heading	Suppliers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4679	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	SUPP_Intro	organisations from whom we receive products and eco invoices	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4680	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	SelectFromList_LBL	select from list	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4681	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	SelectFromList_TT	Select the correct line from the list.  You may need to provide text to filter the list first.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4686	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Substance_LBL	nat	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4687	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Substance_TT	substance from/to nature	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4709	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_ABSTRACT_TT	Quick description of topic	Schnelle Beschreibung des Themas	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4710	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4711	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_COMMENT_LBL	comment	Kommentar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4712	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4713	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_DESC_LBL	Description	Beschreibung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4715	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_DURN_MINS_LBL	Duration	Dauer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4717	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_GO_REF_LBL	foreign key to Company	Fremdschlüssel für Unternehmen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4718	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_MBY_LBL	modified by	angepasst von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4719	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_MWHEN_LBL	modified when	Geändert wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4720	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_REQUESTS_LBL	Requests	Anfragen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4722	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4723	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_TITLE_LBL	Title	Titel	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4724	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_TITLE_TT	Title of topic shown to Delegates	Titel des Themas bei Delegierten	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4725	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPF_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4726	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPF_CF_REF_LBL	conference	Konferenz	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4727	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPF_CF_REF_TT	Link to Conference this topic is being assigned to.	Link zur Konferenz wird dieses Thema zugewiesen.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4728	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPF_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4729	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPF_MBY_LBL	last modified by	Zuletzt geändert durch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4730	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPF_MCOUNT_LBL	mod. count	Mod. Graf	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4731	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPF_MWHEN_LBL	last modified	zuletzt bearbeitet	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4732	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPF_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4733	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPF_STATUS_LBL	status	Status	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4735	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPF_TPC_REF_LBL	topic	Thema	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4736	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPF_TPC_REF_TT	Link to the Topic that is being assigned.	Verknüpfen Sie mit dem Thema, das zugewiesen wird.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4737	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPP_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4738	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPP_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4739	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPP_MBY_LBL	last modified by	Zuletzt geändert durch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4740	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPP_MCOUNT_LBL	mod. count	Mod. Graf	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4741	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPP_MWHEN_LBL	last modified	zuletzt bearbeitet	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4742	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPP_PSN_REF_LBL	person	Person	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4744	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPP_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4745	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPP_TPC_REF_LBL	topic	Thema	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4746	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPP_TPC_REF_TT	Reference to the Topic being assigned to this person.	Verweis auf das Thema, das dieser Person zugewiesen wird.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4748	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_ARR_DATE_LBL	date	Datum	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4749	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_ARR_DATE_TT	arrival date	Ankunftsdatum	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4750	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_ARR_POINT_LBL	where	woher	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4751	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_ARR_POINT_TT	arrival point: St. Pancras, Heathrow, etc	Ankunftsort: St. Pancras, Heathrow, etc	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4752	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_ARR_TIME_LBL	time	Zeit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4753	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_ARR_TIME_TT	arrival time	Ankunftszeit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4754	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_CARRIER_LBL	carrier	Träger	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4755	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_CARRIER_TT	airline, Eurostar etc	Fluggesellschaft, Eurostar etc	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4756	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4757	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_COMMENT_LBL	comment	Kommentar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4759	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_CONNECT_HOW_LBL	connection	Verbindung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4761	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4762	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_DEP_FLIGHT_CODE_LBL	Flight number	Flugnummer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4763	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_DEP_FLIGHT_CODE_TT	Flight number	Flugnummer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4764	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_DEP_FLIGHT_TIME_LBL	departure time	Abfahrtszeit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4765	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_DEP_FLIGHT_TIME_TT	departure time	Abfahrtszeit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4766	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_DEP_METHOD_LBL	Plan on how to get from venue to departure point.	Planen Sie, wie Sie vom Veranstaltungsort zum Ausgangspunkt kommen.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4767	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_DEP_METHOD_TT	Plan on how to get from venue to departure point.	Planen Sie, wie Sie vom Veranstaltungsort zum Ausgangspunkt kommen.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4768	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_DEP_POINT_LBL	Which airport or train station	Welcher Flughafen oder Bahnhof	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4769	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_DEP_POINT_TT	Which airport or train station	Welcher Flughafen oder Bahnhof	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4771	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_DEP_VENUE_TT	proposed time to leave venue	Vorgeschlagene Zeit, den Veranstaltungsort zu verlassen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4772	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_DG_REF_LBL	delegate	delegieren	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4747	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_ALL	all periods	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4774	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_EARLY_PLANS_LBL	early plans	Frühe Pläne	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4776	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_FLIGHT_NO_LBL	flight no	Flug Nr	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4777	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_FLIGHT_NO_TT	flight number person is arriving on	Flugnummer Person kommt an	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4782	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_LOCAL_ARR_TIME_LBL	local arrival time	Lokale Ankunftszeit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4783	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_LOCAL_ARR_TIME_TT	used to determine shuttle times	Verwendet, um Shuttle-Zeiten zu bestimmen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4784	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_LOCAL_ARR_WHERE_LBL	local arrival point	Lokaler Ankunftspunkt	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4786	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_MBY_LBL	modified by	angepasst von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4787	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_MUSIC_INSTRUMENT_LBL	instrument that can be played	Instrument, das gespielt werden kann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4788	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_MUSIC_INSTRUMENT_TT	instrument that can be played	Instrument, das gespielt werden kann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4789	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_MUSIC_PLAYER_LBL	can play instrument	Kann Instrument spielen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4790	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_MUSIC_PLAYER_TT	can play instrument	Kann Instrument spielen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4791	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_MWHEN_LBL	travel modified	Reise geändert	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4797	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4799	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_SHUTTLE_TT	use shuttle service	Nutzen Sie den Shuttleservice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4816	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4817	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_CORRECT_LBL	correct response	Richtige Antwort	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4818	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4819	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_FORMAT_LBL	format	Format	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4821	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_MBY_LBL	last modified by	Zuletzt geändert durch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4822	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_MCOUNT_LBL	mod. count	Mod. Graf	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4823	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_MC_OPTIONS_LBL	multiple choice options	Mehrfachauswahlmöglichkeiten	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4824	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_MWHEN_LBL	last modified	zuletzt bearbeitet	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4825	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_ORDER_LBL	order	Auftrag	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4826	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_ORDER_TT	This is used to order the questions.	Hier werden die Fragen bestellt.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4827	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_QUESTION_LBL	question text	Fragetext	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4828	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_RULE_LBL	rule(s)	Regel (en)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4830	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4831	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_TST_REF_LBL	test	Test	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4832	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_TST_REF_TT	Reference to the test being formulated.	Verweis auf den zu formulierenden Test	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4833	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_ARR_REF_LBL	arrangement	Anordnung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4778	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_LAST_FNIGHT	last fortnight	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4779	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_LAST_MONTH	last month	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4835	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4836	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_CF_REF_LBL	course	Kurs	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4838	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_CRITERIA_LBL	criteria	Kriterien	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4839	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_CRITERIA_TT	Describe the criteria, either that preceding test or that to pass the test.	Beschreiben Sie die Kriterien, entweder die vorherige Prüfung oder die, um den Test zu bestehen.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4840	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4841	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_DESC_LBL	description	Beschreibung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4842	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_DESC_TT	Describe the nature and purpose of the Test.	Beschreiben Sie die Art und den Zweck des Tests.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4843	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_DURN_MINS_LBL	duration	Dauer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4844	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_DURN_MINS_TT	Specify the time limit allowed to do this test.	Geben Sie die Zeitspanne an, die für diesen Test zulässig ist.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4845	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_MBY_LBL	last modified by	Zuletzt geändert durch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4846	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_MCOUNT_LBL	mod. count	Mod. Graf	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4847	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_MWHEN_LBL	last modified	zuletzt bearbeitet	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4850	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_RULES_LBL	rules	Regeln	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4851	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_RULES_TT	Encoded programming rules that can be used to automatically determine pass rate.	Kodierte Programmierregeln, mit denen die Passrate automatisch ermittelt werden kann.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4852	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4853	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_TITLE_LBL	title	Titel	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4854	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_TITLE_TT	Name of the test.	Name des Tests.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4855	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTA_ANSWER_LBL	response	Antwort	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4856	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTA_ANSWER_TT	The actual response to the question.	Die eigentliche Antwort auf die Frage.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4857	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTA_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4858	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTA_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4859	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTA_MBY_LBL	last modified by	Zuletzt geändert durch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4860	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTA_MCOUNT_LBL	mod. count	Mod. Graf	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4861	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTA_MWHEN_LBL	last modified	zuletzt bearbeitet	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4863	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTA_TSQ_REF_LBL	question	Frage	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4864	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTA_TSQ_REF_TT	Reference to the question in the test.	Verweis auf die Frage im Test.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4865	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTA_TTK_REF_LBL	test taken	Test genommen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4867	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4868	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4869	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_DG_REF_LBL	attendee	Teilnehmer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4870	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_DG_REF_TT	Reference to the person taking the test, from list of attendees.	Verweis auf die Person, die den Test, aus der Liste der Teilnehmer.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4871	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_END_LBL	end time	Endzeit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4872	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_MBY_LBL	last modified by	Zuletzt geändert durch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4873	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_MCOUNT_LBL	mod. count	Mod. Graf	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4874	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_MINUTES_LBL	duration	Dauer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4876	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_MWHEN_LBL	last modified	zuletzt bearbeitet	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4877	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_PERCENT_LBL	percent	Prozent	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4878	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4879	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_START_LBL	start time	Startzeit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4880	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_STATUS_LBL	status	Status	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4882	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_TST_REF_LBL	test	Test	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4883	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_TST_REF_TT	Reference to the test being taken by attendee is made here.	Die Referenz, die vom Teilnehmer genommen wird, wird hier gemacht.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4885	2017-04-27 15:20:51	stevensg	2017-08-10 09:16:00	STEVENSG	1	42	\N	TabControl_CF_LBL_GTD	Course details\\Pricing\\Terms\\Technical\\ModulesStats	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4884	2017-04-27 15:20:00	stevensg	2017-08-10 09:17:00	STEVENSG	2	42	\N	TabControl_CF_LBL	Event details\\Pricing\\Significant terms\\Technical\\Sessions\\Stats\\New pricing	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4892	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TabControl_EO_LBL	Name and contact information\\Comments\\Technical	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4893	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TabControl_EO_TT	company name and contact details with shipping and billing addresses and other relevant information\\general comments\\record creation and modification details (view only)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4896	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TabControl_FOH_LBL	Financial Invoice\\ecoInvoice\\Technical	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4897	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TabControl_FOH_TT	invoice header information\\ecoInvoice records\\invoice creation and modification details (view only)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4907	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TabControl_PM_LBL	Models\\Output Products	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4908	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TabControl_PM_TT	name and company information for the currently selected calculation model plus all inputs and outputs\\view all products using the calculation model	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4911	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TabControl_RFG_LBL	Name, desc, active, order\\Text & JSON\\Binary data\\Technical	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4912	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TabControl_RFG_TT	classification, value, and other metadata\\large text value and valid JSON\\binary data stored with the record\\record creation and modification data (view only)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4913	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TabControl_RFL_LBL	Name, desc, active, order\\Text & JSON\\Binary data\\Technical	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4914	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TabControl_RFL_TT	classification, value, and other metadata\\large text value and valid JSON\\binary data stored with the record\\record creation and modification data (view only)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4915	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TabControl_RFO_LBL	Name, desc, active, order\\Text & JSON\\Binary data\\Technical	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4916	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TabControl_RFO_TT	classification, value, and other metadata\\large text value and valid JSON\\binary data stored with the record\\record creation and modification data (view only)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4919	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ToInput_LBL	next	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4920	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ToInput_TT	to be used in a subsequent step	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4923	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TransmitElementaryFlows_LBL	transmit elementary flows	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4924	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TransmitElementaryFlows_TT	if checked, this product's elementary flow values will be transmitted along with its ecoCost	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4925	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UGO_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4926	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UGO_CBY_TT	name of user who created this record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4927	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UGO_CWHEN_LBL	creation date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4928	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UGO_CWHEN_TT	creation date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4929	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UGO_GO_REF_LBL	foreign key to entGroupOrganisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4930	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UGO_GO_REF_TT	foreign key to entGroupOrganisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4931	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UGO_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4932	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UGO_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4933	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UGO_USR_REF_LBL	foreign key to uaUsers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4934	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UGO_USR_REF_TT	foreign key to uaUsers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4909	2017-04-27 15:20:51	stevensg	2018-04-30 15:52:00	STEVENSG	2	40	\N	TabControl_PRD_LBL	Product Info\\Internal data\\Technical	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4903	2017-04-27 15:20:51	stevensg	2017-08-10 09:05:00	STEVENSG	1	40	\N	TabControl_OHD_LBL	Entries\\Detailed information	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4917	2017-04-27 15:20:51	stevensg	2017-08-10 09:11:00	STEVENSG	1	40	\N	TabControl_USERS_LBL	Roles\\Group Organisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4905	2017-04-27 15:20:51	stevensg	2017-08-10 09:06:00	STEVENSG	1	40	\N	TabControl_ORH	Acc. Period\\Sales Forecast\\Overheads Distribution	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4894	2017-04-27 15:20:51	stevensg	2017-08-10 09:10:00	STEVENSG	1	40	\N	TabControl_FEEDBACK_LBL	Feedback\\Technical	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4895	2017-04-27 15:20:51	stevensg	2017-08-10 09:10:00	STEVENSG	1	40	\N	TabControl_FEEDBACK_TT	feedback details entered\\record creation and modification details (view only)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4900	2017-04-27 15:20:51	stevensg	2017-08-10 09:10:00	STEVENSG	1	40	\N	TabControl_HELP_LBL	Roles\\Group Organisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4904	2017-04-27 15:20:00	stevensg	2017-08-10 09:11:00	STEVENSG	2	40	\N	TabControl_OHD_TT	list of entries for the selected overhead/dates/product\\full details for each line of the listed entries	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4918	2017-04-27 15:20:51	stevensg	2017-08-10 09:11:00	STEVENSG	1	40	\N	TabControl_USERS_TT	list of system roles to which the user belongs\\list of group organisations that the user is a member of	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4910	2017-04-27 15:20:51	stevensg	2018-04-30 15:52:00	STEVENSG	2	40	\N	TabControl_PRD_TT	name, brand and packaging information for the product\\internal product information\\record audit info	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4898	2017-04-27 15:20:51	stevensg	2018-04-10 16:02:00	STEVENSG	1	40	\N	TabControl_GO_LBL	Name and numbers\\EcoCost registration\\Technical	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4935	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_CONNECT_TIME_LBL	set on opening of task	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4936	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_CONNECT_TIME_TT	set on opening of task	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4937	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_DG_REF_LBL	foreign key to delegates (where it exists)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4938	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_DG_REF_TT	foreign key to delegates (where it exists)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4939	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_FORMS_VISITED_LBL	forms used	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4940	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_FORMS_VISITED_TT	forms used	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4941	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_GO_NAME_LBL	group organisation short name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4942	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_GO_NAME_TT	group organisation short name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4943	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_IP_ADDRESS_LBL	in anticipation of IP v6	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4944	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_IP_ADDRESS_TT	in anticipation of IP v6	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4945	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_LOGIN_LBL	login	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4946	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_LOGIN_TT	time of login	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4947	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_LOGOUT_LBL	logout	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4948	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_LOGOUT_TT	time of logout	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4949	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4950	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4951	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_USR_REF_LBL	foreign key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4952	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	ULA_USR_REF_TT	foreign key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4959	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_ACTIVE_LBL	available for use	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4960	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_ACTIVE_TT	available for use	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4961	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4962	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4963	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_CODE_LBL	unique code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4964	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_CODE_TT	unique code for the unit, eg. kg, m3, m2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4965	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_CWHEN_LBL	created	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4966	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4967	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_DESC_EN_LBL	description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4968	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_DESC_EN_TT	description of measurement in English	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4969	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_GROUP_LBL	measurement group	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4970	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_GROUP_TT	grouping of units of measurement, eg. volume, length, area	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4971	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	UOM_Heading	Units of Measurement	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4972	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4973	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4974	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4975	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4976	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_MWHEN_LBL	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4977	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_MWHEN_TT	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4978	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4979	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOM_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4980	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_ACTIVE_LBL	available for use	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4981	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_ACTIVE_TT	available for use	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4982	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4983	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4984	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_CODE_LBL	unique id	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4985	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_CODE_TT	unique identifier, eg. kg, ml, m2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4986	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_CWHEN_LBL	created	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4987	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_CWHEN_TT	creation timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4988	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_FACTOR_LBL	conversion factor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4989	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_FACTOR_TT	multiplier to convert to base unit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4990	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_FILTER_LBL	filter group	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4991	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_FILTER_TT	filter, eg. metric, imperial, US	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4992	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4993	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4994	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4995	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_MCOUNT_TT	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4996	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_MWHEN_LBL	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4997	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_MWHEN_TT	modification date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4998	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_NAME_EN_LBL	description (english)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4999	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_NAME_EN_TT	description of the unit in English	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5000	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5001	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5002	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_UOM_REF_LBL	foreign key to sysunitofmeasure	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5003	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UOS_UOM_REF_TT	foreign key to sysunitofmeasure	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5004	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_ACTIVE_LBL	is this User-Role relationship currently active?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5005	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_ACTIVE_TT	is this User-Role relationship currently active?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5006	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5007	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_CBY_TT	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5008	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_CWHEN_LBL	created timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5009	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_CWHEN_TT	created timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5010	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_DEFAULT_LBL	does the user get this role by default?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5011	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_DEFAULT_TT	does the user get this role by default?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5012	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_ROL_REF_LBL	foreign key to uaRoles	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5013	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_ROL_REF_TT	foreign key to uaRoles	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5014	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_SEQ_LBL	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5015	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5016	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_USR_REF_LBL	foreign key to uaUsers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5017	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	UR_USR_REF_TT	foreign key to uaUsers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5019	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	USERS_Intro	create new Users, assign roles and group organisations to Users	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5020	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_AC_EXPIRES_LBL	account expiry date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5021	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_AC_EXPIRES_TT	account expiry date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5022	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	USR_ALL_RECORDS	All Users	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5023	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	USR_ASSIGNED_ALL_GROUPORGS	User has been assigned to all Organisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5024	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	USR_ASSIGNED_ALL_ROLES	User has been assigned all Roles	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5025	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_CBY_LBL	created by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5028	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_CWHEN_TT	created timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5029	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_EMAIL_LBL	email address	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5030	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_EMAIL_TT	email address	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5032	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_EXTN_TT	internal phone no/extension	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5033	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	USR_GO_ADD	select organisation to add to user	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5034	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	USR_GO_LIST	Group Organisations for selected user	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5036	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_INITIALS_TT	users initials to include in reports	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5037	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_JOB_TITLE_LBL	job title	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5038	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_JOB_TITLE_TT	job title	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5039	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_MBY_LBL	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5040	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_MBY_TT	modified by	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5041	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_MCOUNT_LBL	modification count	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5044	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_MOBILE_TT	mobile phone number	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5045	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_MWHEN_LBL	modified timestamp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5048	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_NAME_TT	user login name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5050	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_PW_EXPIRES_TT	password expiry date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5052	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_REAL_NAME_TT	user full name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5053	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	USR_ROL_ADD	select role to add to user	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5043	2017-04-27 15:20:51	stevensg	2018-02-08 21:21:00	MOSTYNRS	1	1	\N	USR_MOBILE_LBL	mobile	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5031	2017-04-27 15:20:51	stevensg	2018-02-08 21:21:00	MOSTYNRS	1	1	\N	USR_EXTN_LBL	phone	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5049	2017-04-27 15:20:51	stevensg	2018-02-08 21:21:00	MOSTYNRS	1	1	\N	USR_PW_EXPIRES_LBL	password expires	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5051	2017-04-27 15:20:51	stevensg	2018-02-08 21:21:00	MOSTYNRS	1	1	\N	USR_REAL_NAME_LBL	full name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5047	2017-04-27 15:20:51	stevensg	2018-02-08 21:21:00	MOSTYNRS	1	1	\N	USR_NAME_LBL	login name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5042	2017-04-27 15:20:51	stevensg	2018-02-08 21:22:00	MOSTYNRS	1	1	\N	USR_MCOUNT_TT	number of times record has been modified	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5046	2017-04-27 15:20:51	stevensg	2018-02-08 21:22:00	MOSTYNRS	1	1	\N	USR_MWHEN_TT	timestamp of when record was last modified	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5027	2017-04-27 15:20:51	stevensg	2018-02-08 21:22:00	MOSTYNRS	1	1	\N	USR_CWHEN_LBL	timestamp of when record was created	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5026	2017-04-27 15:20:51	stevensg	2018-02-08 21:23:00	MOSTYNRS	1	1	\N	USR_CBY_TT	person who created this record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5018	2017-04-27 15:20:51	stevensg	2018-04-12 11:40:00	STEVENSG	2	40	\N	USERS_Heading	User management	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5054	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	USR_ROL_LIST	Roles for selected user	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5055	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_SALT_LBL	hash salt	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5056	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_SALT_TT	hash salt for password	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5059	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	1	\N	USR_SEQ_TT	primary key	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5338	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_roles	All roles	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5159	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_COSTCENTRE	has a value so DIVISION, PLANT, BUS_UNIT, CATEGORY and PROJECT must be clear	\N	\N	\N	\N	\N	Tiene un valor así que DIVISION, PLANT, BUS_UNIT, CATEGORY y PROJECT deben ser claros	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5339	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_sequences	All sequences	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5166	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_DIVISION	has a value so DIVISION, PLANT, BUS_UNIT, CATEGORY and COSTCENTRE must be clear	\N	\N	\N	\N	\N	Tiene un valor así que DIVISION, PLANT, BUS_UNIT, CATEGORY y COSTCENTRE deben ser claros	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9954	2018-11-07 12:54:00	STEVENSG	2018-11-07 12:55:00	STEVENSG	1	57	\N	PDF_THANKS_ALL	Thank you to all	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5179	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_ERR	validation check	\N	\N	\N	\N	\N	Verificación de validación	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5180	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_EXCLUSIVE	are mutually exclusive	\N	\N	\N	\N	\N	Son mutuamente excluyentes	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5185	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_INVALID	is invalid	\N	\N	\N	\N	\N	es inválido	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5186	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_LABEL_FORMAT	requires an underscore (_)	\N	\N	\N	\N	\N	Requiere un guión bajo (_)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5188	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_MANDATORY	must be provided	\N	\N	\N	\N	\N	debe ser provisto	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5189	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_MASSEQUALONE	total mass must equal 1	\N	\N	\N	\N	\N	La masa total debe ser igual a 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5190	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_MAX_100	cannot be greater than 100	\N	\N	\N	\N	\N	No puede ser mayor de 100	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5191	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_MISMATCH	mismatch	\N	\N	\N	\N	\N	Incompatibilidad	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5192	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_MISSING	missing	\N	\N	\N	\N	\N	desaparecido	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5194	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_NEGATIVE	cannot be negative	\N	\N	\N	\N	\N	No puede ser negativo	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5196	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_NOT_UNIQUE	is not unique	\N	\N	\N	\N	\N	No es único	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5174	2017-04-27 15:20:00	stevensg	2018-06-19 04:06:00	MOSTYNRS	2	40	\N	VAL_EMAIL_ILLEGAL_CHAR	illegal character in email	\N	\N	\N	\N	\N	Carácter ilegal en el correo electrónico	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5175	2017-04-27 15:20:00	stevensg	2018-06-19 04:06:00	MOSTYNRS	2	40	\N	VAL_EMAIL_INUSE	The email address is already in use	\N	\N	\N	\N	\N	La dirección de correo electrónico ya está en uso	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5176	2017-04-27 15:20:00	stevensg	2018-06-19 04:06:00	MOSTYNRS	2	40	\N	VAL_EMAIL_MISSING	Email address missing	\N	\N	\N	\N	\N	Falta la dirección de correo electrónico	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5178	2017-04-27 15:20:00	stevensg	2018-06-19 04:06:00	MOSTYNRS	2	40	\N	VAL_EMAIL_SERVERNOTFOUND	Invalid email address	\N	\N	\N	\N	\N	Dirección de correo electrónico no válida	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5206	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_PB_ACTUAL	must be one of A/T/Q	\N	\N	\N	\N	\N	Debe ser uno de A / T / Q	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5232	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_COMMENT_INTERNAL_LBL	internal comment	Interner Kommentar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5233	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_COUNTRY_LBL	Country	Land	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5235	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_GO_REF_LBL	foreign key to Company	Fremdschlüssel für Unternehmen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5236	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_GO_REF_TT	foreign key to internal Company record	Fremdschlüssel zum internen Unternehmensrekord	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5240	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_LOCALITY_TT	Local area (part of address)	Ortsbereich (Teil der Adresse)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5241	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_MWHEN_LBL	modified when	Geändert wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5242	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_NAME_LBL	Name	Name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5243	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_NAME_TT	Name of venue	Name des Veranstaltungsortes	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5244	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_PHONE_LBL	Phone	Telefon	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5248	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_ROOM_LBL	Room	Zimmer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5249	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_ROOM_TT	Name of room in building, if applicable	Name des Raumes im Gebäude, falls zutreffend	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5252	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5253	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_STATE_LBL	State	Bundesland	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5254	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_STATE_TT	State, county, canton - part of address	Staat, Landkreis, Kanton - Teil der Adresse	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5256	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_STATUS_TT	venue status - it could be a disaster	Veranstaltungsort - es könnte eine Katastrophe sein	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5258	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_STREET_TT	address - street	Adresse - Straße	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5259	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_TOWN_LBL	Town	Stadt	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5260	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_TOWN_TT	address - town	Adresse - Stadt	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5225	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	3	\N	VAL_UNASSIGNED	not assigned	\N	\N	\N	\N	\N	no asignado	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5296	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	address_LBL	postal address	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5297	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	address_TT	enter a full postal address	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5314	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	dataTypeMismatch	data type specified and data value provided do not concur	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5315	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_all_tab_classes	All table classes	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5316	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_child_nodelete	Cannot be deleted because the record has children associated with it.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5317	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_components	Components	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5319	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_confirm	Are you sure?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5320	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_cust	customers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5321	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_cust_inv	Customer invoices	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5322	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_del_canc	Deletion cancelled	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5323	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_delete	Delete	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5324	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	42	\N	disp_dupArrangements	Duplicate event WITH its arrangements/sessions?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5325	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_flows	Elem. flows	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5327	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_models	Selected models	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5328	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_ohaccs	overhead accounts	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5329	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_orgs	Selected organisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5330	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_other_cat	Other category	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5331	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_periods	accounting periods	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5332	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_permissions	selected Permissions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5333	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_prev_comm	Previous comments	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5334	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_prods	Selected products	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5337	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_respond	Please respond	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5289	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	YESTERDAY	yesterday	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5340	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	42	\N	disp_statusChange	change status	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5341	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_subcats	Subcategories	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5342	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_submit_canc	Submission cancelled	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5344	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_substances	Substances	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5345	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_supp	suppliers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5346	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_supp_inv	Supplier invoices	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5347	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_units	Units	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5348	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_users	All users	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5349	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_values	Selected values	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5350	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	email_LBL	email address	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5351	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	email_TT	enter a valid email address	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5352	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	endOfReport	End of report	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5354	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ibOverWrite_LBL	overwrite existing process	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5355	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ibOverWrite_TT	when checked, Save will overwrite the existing process otherwise a new process will be created	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5356	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icCheckPassword_LBL	confirm new password	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5357	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icCheckPassword_TT	reenter the new password	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5358	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icNewPassword_LBL	new password	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5359	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icNewPassword_TT	enter the new password for this user	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5364	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icReactionString_LBL	formula	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5365	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icReactionString_TT	the chemical reaction used in the calculation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5374	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilChains_TT	list of chained invoices, click to display	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5375	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilCountries_LBL	country	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5376	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilCountries_TT	select a country from the drop list	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5377	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilGroupOrgs_TT	assign and deassign accounts to individual organisations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5386	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilSynonyms_LBL	Synonyms	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5387	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilSynonyms_TT	synonyms with the conversion factor for the currently selected unit of measurement	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5388	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilUserGroups_LBL	select the organisation you wish to log in under	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5389	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	isShop_LBL	is retailer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5390	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	isShop_TT	if this organisation is a retail outlet, setting this will get the system to automatically send pre-purchase ecoCosts	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5470	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_atLeastOneLine	At least one line must exist in the list.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5473	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_daterangeformat	DD/MM/YYYY - DD/MM/YYYY	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5474	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_del_calc	Are you sure you want to delete calculation: 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5475	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_del_desc	Are you sure you want to delete this description?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5476	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_del_detail	Are you sure you want to delete this detail line?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5477	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_del_input	Are you sure you want to delete the input: 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5478	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_del_output	Are you sure you want to delete output: 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5479	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_del_reaction	Are you sure you want to delete the reaction: 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5480	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_del_rule	Are you sure you want to delete the selected rule?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5481	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_del_step	Are you sure you want to delete the step: 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5484	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_enterdates	Please enter the date range separated by a -.   A single date will fetch for that date.   A single date followed or preceded by a - will fetch records starting or ending with that date, respectively.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5485	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_invaliddate	is not a valid date.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5486	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_invaliddaterange	The end date must be equal to or later than the start date.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5487	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_promptnumberofunits	Please enter the number of units required.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5488	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_submit_fininv	Are you sure you want to submit this invoice for eco Invoicing?   It will no longer be editable.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5498	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbAddAction_TT	add a new line to the list	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5499	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbAddCode_TT	insert a new code above selected line	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5502	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbAddInput_TXT	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5503	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbAddLink_LBL		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5500	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbAddDepreciation_LBL	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5504	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbAddLink_TT	add a link this organisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5505	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbAddOverheadAccount_TT	create a new overhead account	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5508	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbAddRow_TT	add a new record to the end of the list	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5509	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbAddRule_TT	insert a new rule above the selected line	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5510	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbAddToInvoice_LBL	add to invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5511	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbAdd_TT	create a new entry	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5512	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbBack_LBL	back	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5513	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbCalculateEcoCost_LBL	calculate ecocost for new batch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5514	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbCalculateEcoCost_TT	select a process, enter the multiplier for the product output and click to calculate the ecocost for the batch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5518	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbCancel_LBL	cancel	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5519	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbCancel_TT	ignore all changes and leave everything as it was	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5522	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbCloneAmend_LBL	copy to amend	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5523	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbCloneNew_LBL	copy to new	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5525	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbClone_TT	duplicate the currently selected process model choosing to create a new version or a completely new model based upon it	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5527	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbDeleteOverheadAccount_TT	delete the selected overhead account (if it has not been assigned)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5529	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbDeleteRow_TT	delete the current record from the list	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5530	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbDelete_TT	Delete current record. A check for dependent records will be done first.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5531	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbDisplayIndicator_LBL	indicators	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5533	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbDropLink_TT	drop the link to this organisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5534	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	42	\N	pbDuplicate_TT	Duplicate the current record to create new event based on existing record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5536	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbEditOrgLink_TT	modify overhead account organisation details	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5537	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbEditPeriod_TT	modify the current forecast and overheads allocations figures	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5538	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbEdit_TT	click here to edit the currently displayed record(s)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5542	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbFeedback_TT	click here to open the feedback form to send to the developers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5543	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbFetch_LBL	fetch	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5550	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbInsert_TT	Create a new record by clicking here.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5552	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbMinusAction_TT	remove the currently selected line from the list	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5553	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbMinusPeriod_TT	delete the currently selected future period	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5554	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbMinusPermission_TT	delete the currently selected permission if not assigned to any roles	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5555	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbMinusRolePermission_TT	delete the role from the list assigned to the currently selected permission 	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5613	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	plural_v	ies	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5506	2017-04-27 15:20:51	stevensg	2017-08-10 14:23:00	STEVENSG	1	40	\N	pbAddProcessToProduct_LBL	+	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5507	2017-04-27 15:20:51	stevensg	2017-08-10 14:23:00	STEVENSG	1	40	\N	pbAddProcessToProduct_TT	link a calculation model with the currently selected product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5528	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbDeleteProcessFromProduct_TT		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5532	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbDropLink_LBL		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5539	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbExit_LBL		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5541	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbFeedback_LBL		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5544	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbGenerateSQL_LBL		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5545	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbGenerateSQL_TT		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5516	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbCancelDepreciation_LBL	cancel	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5540	2017-04-27 15:20:51	stevensg	2018-04-10 16:03:00	STEVENSG	1	40	\N	pbExit_TT	click here to close the EcoCost application	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5556	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbMinusSynonym_TT	delete the currently selected synonym (blocked if the synonym has been used)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5561	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbMoveRowDown_TT	move the current record down one row in the list	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5562	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbMoveRowUp_TT	move the current record up one row in the list	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5566	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbNextOHH_LBL	next	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5567	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbNextOHH_TT	go to next overhead account	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5568	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbNextWizard	next	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5569	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbOK_LBL	ok	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5570	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbOK_TT	you are acknowledging this message	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5571	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbPlusPeriod_TT	create a new accounting period based on the latest period in the list	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5572	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbPlusPermission_TT	create a new permission	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5573	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbPlusRolePermission_TT	assign the currently selected permission to a role	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5574	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbPlusSynonym_TT	create a new synonym for the currently selected unit of measure	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5580	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbPreviousOHH_LBL	previous	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5581	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbPreviousOHH_TT	go to previous overhead account	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5582	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbPreviousWizard	previous	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5583	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbRegister_LBL	send to ecoAccounting	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5584	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbRegister_TT	register your changes with the ecoAccounting system	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5585	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbRemoveRule_TT	remove the selected rule from the list	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5586	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbReturn_LBL	return	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5587	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbReturn_TT	click here to return to the previous screen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5589	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSaveAndContinue_LBL	save	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5590	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSaveAndContinue_TT	save current changes and go to next tab	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5595	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSave_LBL	save	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5596	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSave_TT	any changes you have made in this screen will be saved to the database	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5597	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSearch_LBL	search	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5598	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSelect_LBL	Select	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5599	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSelect_TT	select your chosen organisation above and then click here	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5600	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSend_LBL	send invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5604	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSubmit_LBL	submit for ecoinvoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5610	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	plural_f	s	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5611	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	plural_m	s	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5612	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	plural_s	es	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5558	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbMinusUserGroupOrg_TT		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5559	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbMinusUserRole_LBL		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5560	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbMinusUserRole_TT		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5575	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbPlusUserGroupOrg_TT		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5576	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbPlusUserRole_LBL		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5577	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbPlusUserRole_TT		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5606	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbToClipboard_LBL		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5607	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbToClipboard_TT		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5564	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbNextEntry_LBL	next	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5614	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pmStepPSC	Calculation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5615	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pmStepPSD	Documentation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5616	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pmStepPSI	Input	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5617	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pmStepPSO	Output	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5618	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pmStepPSP	Sub process	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5619	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pmStepPSR	Reaction	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5620	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pmStepPSV	Variable	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5621	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	postcode_LBL	postcode	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5622	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	postcode_TT	enter a valid postcode	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5623	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	3	\N	recordsListed	records listed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5627	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_DeletePSC	delete Calculation record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5628	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_DeletePSD	delete Documentation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5629	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_DeletePSI	delete Input record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5630	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_DeletePSO	delete Output record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5631	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_DeletePSP	delete Process record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5632	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_DeletePSR	delete Reaction record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5633	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_DeletePSV	delete Variable record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5634	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_Discard	Discard changes to this list	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5635	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_DiscardListInStep_e	con('Discard all changes to ',lcListName,' for step: ',lcStepName)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5637	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_InsertPSC	add Calculation record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5638	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_InsertPSD	add Documentation record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5639	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_InsertPSI	add Input record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5640	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_InsertPSO	add Output record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5641	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_InsertPSP	add Process record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5642	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_InsertPSR	add Reaction record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5643	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_InsertPSV	add Variable record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5644	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_MoveMinus2	 to step - 2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5645	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_MoveNext	 to next step	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5646	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_MovePSC	move this Calculation record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5647	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_MovePSD	move this Documentation record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5648	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_MovePSI	move this Input record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5649	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_MovePSO	move this Output record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5650	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_MovePSP	move this Process record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5651	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_MovePSR	move this Reaction record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5652	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_MovePSV	move this Variable record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5653	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_MovePlus2	 to step + 2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5654	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_MovePrev	 to previous step	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5655	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_ProcessSteps	View process details...	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5656	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_ProcessWizard	View process wizard...	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5657	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_Refresh	Refresh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5658	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_addStep	add step	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5663	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_deleteStep	delete step	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5676	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_shiftActionLine+1_	con('shuffle this ',lcWhichAction,' +1 line')	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5677	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_shiftActionLine+2_	con('shuffle this ',lcWhichAction,' +2 line')	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5678	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_shiftActionLine-1_	con('shuffle this ',lcWhichAction,' -1 line')	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5679	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_shiftActionLine-2_	con('shuffle this ',lcWhichAction,' -2 line')	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5680	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_shiftStep+1	shuffle step +1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5681	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_shiftStep+2	shuffle step +2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5682	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_shiftStep-1	shuffle step -1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5683	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	rm_shiftStep-2	shuffle step -2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5688	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_class	select class	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5689	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_component	select component	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5690	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	42	\N	sel_conference	select conference	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5691	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	42	\N	sel_conference_GTD	select course	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5692	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_criteria1	select criteria 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5693	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_criteria2	select criteria2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5694	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_customer	select customer	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5695	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_daterange	select date range	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5696	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_elemflow	select elem. flow	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5697	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_group	select group	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5698	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_org	select organisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5699	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_overhead	select overhead	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5700	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_prefix	select prefix	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5701	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_subcat	select subcategory	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5702	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_substance	select substance	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5703	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	sel_supplier	select supplier	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5704	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	42	\N	sel_variousCriteria	various criteria	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5795	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	word_at	at	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5799	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	word_date	date	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5808	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	word_of	of	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5810	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	word_on	on	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5813	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	word_pane	pane	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5814	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	word_record	record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5825	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_COUNTRY_NAME_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5834	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE3_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5836	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE3_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5844	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_INT_PRODCODE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5853	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_0_LUNCH_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5854	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	AE_FAIL_COUNT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5855	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_START_DATE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5856	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LG_DESC_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5858	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DR_MBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5807	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	word_missing	missing	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5867	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE5_H_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5872	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	TabControl_DIM_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5873	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_TIME_ZONE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5875	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_LONGITUDE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5898	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LG_ACTIVE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5899	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE5_N_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5915	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_MBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5918	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE4_I_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5923	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TST_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5926	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LG_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5931	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	FCY_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5934	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	ULA_LAST_HIT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5935	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LG_ENDONYM_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5937	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_MCOUNT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5944	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DIL_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5948	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbCloneNew_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5949	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5951	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE0_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5955	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPP_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5967	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	FCY_SEATING_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5974	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TST_MCOUNT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5979	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	RFU_JSON_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5981	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PSN_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5982	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTK_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5987	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DR_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5988	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_END_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5993	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE2_TEXT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5996	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_CITY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6012	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DSL_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6023	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_COUNTRY_CODE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6027	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbDeleteProcessFromProduct_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6033	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	HELP_Intro_8	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6036	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_6_DINNER_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6039	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PY_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6049	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_TITLE_CODE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6056	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_BYTES_REQMAXRECD_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6059	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARA_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6071	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_NAME_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6075	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TSQ_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6080	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_CALC_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6090	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	FCY_LOCATION_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6102	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	MB_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6105	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE0_TEXT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6106	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_REGION_NAME_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6109	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_SEQ_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6115	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_LATITUDE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6117	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	MB_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6131	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_REGION_CODE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6148	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TST_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6176	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6179	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DR_MWHEN_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6194	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE5_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6214	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_4_NIGHT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6217	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_0_NIGHT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6228	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DG_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6231	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	TabControl_HELP_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6246	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_START_DATE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6247	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPP_MCOUNT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6250	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE5_TEXT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6251	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_2_NIGHT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6252	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTA_MCOUNT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6260	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TSQ_QUESTION_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6265	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbSubmit_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6266	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DSL_DG_REF_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6269	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_BYTES_REQMAXSENT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6272	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DSL_STATUS_TO_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6275	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_3_DINNER_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6281	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CSN_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6282	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_SEP_DEC_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6283	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_END_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6286	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE5_TEXT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6311	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTK_PERCENT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6323	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTK_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6326	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	USR_USR_REF_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6332	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_SEP_DEC_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6334	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DR_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6339	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6341	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARA_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6342	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_2_DINNER_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6343	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_FMT_DATE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6345	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE2_H_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6370	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DG_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6375	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	RFG_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6379	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE_SP_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6389	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PSN_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6391	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TSQ_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6398	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPC_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6404	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_ORDER_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6417	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_3_NIGHT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6429	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARR_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6440	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	FCY_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6441	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_FILTER_DESC_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6458	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE3_I_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6470	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE8_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6479	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE4_TEXT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6492	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PROD_FAMILY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6509	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	USR_TEAM_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6510	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_3_BFAST_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6511	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	ULA_REQUESTS_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6514	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_1_LUNCH_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6515	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_COUNT_START_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6516	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_MWHEN_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6519	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE_SP_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6520	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE7_TEXT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6523	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE_SP_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6530	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_ORDER_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6532	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_CBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6535	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6545	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PSN_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6550	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_4_BFAST_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6566	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_MBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6571	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SMH_PKEY_I_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6575	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_CODE_OTHER_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6577	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_METRO_CODE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6584	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE7_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6601	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LG_NO_OF_SPEAKERS_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6609	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_2_BFAST_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6618	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_REGION_NAME_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6620	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPP_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6632	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DB_NO_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6640	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	42	\N	pbDuplicate_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6648	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_6_LUNCH_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6663	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbDisplayIndicator_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6664	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_4_DINNER_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6672	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_AGREED_PRICE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6684	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TSQ_MC_OPTIONS_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6687	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CRT_CF_REF_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6688	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_NAME_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6702	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	MB_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6723	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_REGION_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6730	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARR_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6731	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbHelpNext_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6746	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DR_CBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6755	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_1_NIGHT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6756	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_2_DINNER_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6761	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_BYTES_REQTOTRECD_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6764	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	RFG_JSON_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6768	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6773	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DIL_CBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6786	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbAddToInvoice_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6787	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_2_NIGHT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6789	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_ACTIVE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6792	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PY_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6793	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PSN_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6801	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_CF_REF_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6807	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_SCORE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6821	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	42	\N	TabControl_CF_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6825	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE8_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6828	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_1_DINNER_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6834	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_ACTIVE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6835	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LIB_NAME_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6837	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DSL_DG_REF_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6840	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_MWHEN_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6841	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbMinusAction_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6845	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPC_COMMENT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6846	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_MBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6849	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_2_LUNCH_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6852	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LIB_VALUE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6857	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_TOT_EVENTS_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6858	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CFG_SEQ_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6860	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LIB_DESC_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6862	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SMH_PKEY_I_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6867	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DR_CWHEN_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6869	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_3_BFAST_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6870	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_START_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6878	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_2_LUNCH_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6880	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_MBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6895	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_COL_ORDER_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6896	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_GO_REF_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6897	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE4_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6898	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_SEP_THOU_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6903	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE7_N_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6905	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DB_KEY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6907	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SMH_TABLE_PRFX_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6909	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_5_BFAST_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6919	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE2_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6920	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_ISO3_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6927	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SMH_PKEY_C_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6929	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE2_TEXT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6934	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DD_PATH_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6936	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbCloneAmend_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6946	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE7_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6947	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	TabControl_DIM_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6954	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CFG_VALUE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6955	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CSN_MCOUNT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6958	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE3_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6963	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_EXPIRED_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6978	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PSN_SURNAME_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7004	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	MB_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7012	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_1_NIGHT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7020	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE1_TEXT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7042	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE0_TEXT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7049	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PY_DATE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7053	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SMH_PKEY_C_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7059	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_CWHEN_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7061	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_CODE_OTHER_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7064	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARR_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7072	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DSL_CWHEN_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7078	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_MONEY_SYMB_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7083	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_MBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7085	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_5_NIGHT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7088	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	VEN_TIMEZONE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7095	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LIB_KEY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7107	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	AE_FROM_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7111	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_BYTES_REQCURRECD_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7113	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_ISO2_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7125	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_SIGNIFICANT_TERMS_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7128	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_MM_OFFICE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7134	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTA_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7141	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE1_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7144	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	TabControl_UOM_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7148	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	DIM_Intro	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7149	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LG_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7155	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPF_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7157	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_CITY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7158	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SLE_SERVER_IP_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7162	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CFG_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7166	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTK_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7181	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE3_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7192	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	USR_ACTIVE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7196	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE8_TEXT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7198	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE5_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7207	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SMH_OWNER_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7210	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE2_I_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7211	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CSN_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7212	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_6_NIGHT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7185	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbEditDepreciation_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7223	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7226	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LIB_DESC_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7236	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE8_N_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7240	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7248	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE8_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7253	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE4_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7268	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTK_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7269	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_5_DINNER_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7270	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7272	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_GO_REF_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7273	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	FCY_VEN_REF_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7274	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPC_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7277	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LIB_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7278	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_TIME_ZONE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7281	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE2_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7285	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_TOT_EVENTS_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7309	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE5_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7324	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE3_TEXT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7329	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CFG_NO_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7330	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTA_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7335	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbAddRole_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7341	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_BYTES_REQTOTRECD_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7348	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_OTHER_INFO_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7349	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SMH_TABLE_PRFX_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7350	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	VEN_TIMEZONE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7367	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_1_BFAST_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7381	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_CODE_ORIGIN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7385	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DR_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7386	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7390	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CSN_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7402	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE2_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7406	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_CODE_ORIGIN_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7407	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	ULA_COMMENT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7416	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPC_GO_REF_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7419	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE6_H_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7425	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TSQ_MCOUNT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7426	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_IMP_FLAGS_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7435	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	RFG_MBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7441	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_CALC_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7453	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TSQ_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7460	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_IMP_FLAGS_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7463	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_1_LUNCH_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7473	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_OTHER_INFO_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7482	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7486	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_INT_PRODCODE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7492	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_REGION_CODE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7508	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DSL_STATUS_TO_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7511	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DSL_STATUS_FROM_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7515	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_SEQ_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7517	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	DIC_Intro	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7529	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPF_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7534	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PY_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7537	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	ULA_COMMENT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7541	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SLE_SERVER_PORT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7550	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	VEN_WEBSITE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7553	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SLE_VHOST_REF_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7563	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTA_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7588	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_ADMIN_DATE_TO_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7601	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE6_TEXT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7602	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_LANGS_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7603	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_FMT_DATE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7604	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARR_ENDTIME_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7611	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_NAME_LOCAL_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7615	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE1_H_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7627	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE7_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7636	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_5_LUNCH_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7643	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbClone_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7655	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_PROD_CODE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7661	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_BYTES_REQCURRECD_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7677	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE1_N_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7684	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DB_VALUE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7689	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_REGION_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7693	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTK_START_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7712	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PY_COMMENT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7713	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	VEN_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7716	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	FCY_ORDER_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7742	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTK_MCOUNT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7751	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_4_LUNCH_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7781	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TSQ_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7784	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CFG_KEY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7795	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPP_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7799	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbAddAction_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7808	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TST_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7818	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SMH_OWNER_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7820	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	UOM_Intro	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7822	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CSN_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7829	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7834	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TSQ_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7842	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE4_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7846	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPC_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7848	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SLV_VHOST_REF_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7853	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	USR_TEAM_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7856	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARA_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7864	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7868	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARR_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7869	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTK_END_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7875	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_5_DINNER_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7876	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DG_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7877	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	AE_FAIL_STATUS_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7878	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	TabControl_DIC_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7880	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CFG_DESC_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7882	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_SIGNIFICANT_TERMS_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7885	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	FCY_SEATING_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7895	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_LONGITUDE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7898	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_COL_COUNT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7899	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DB_VALUE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7908	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DB_SEQ_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7911	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	SH_Heading	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7912	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE6_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7914	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	VEN_WEBSITE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7915	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_BYTES_REQCURSENT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7924	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPF_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7925	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_LAST_RESPONSE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7935	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TP_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7939	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_CBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7945	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE6_N_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7948	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_CF_REF_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7949	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DIL_CWHEN_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7953	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARR_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7957	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	USR_STARTDATE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7965	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_COMMENT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7970	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	PC_Intro	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7981	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPC_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7984	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE1_TEXT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7999	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbPlusRoleUser_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8005	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TST_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8008	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DB_NO_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8011	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	MB_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8017	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TSQ_CORRECT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8018	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SLV_SERVER_IP_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8024	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	FCY_AREA_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8030	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	TabControl_UOM_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8042	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_RFO_VALUE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8059	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_COUNTRY_NAME_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8062	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SLE_VHOST_REF_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8077	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SLV_SERVER_PORT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8081	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_BYTES_REQMAXSENT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8091	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE6_TEXT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8109	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_3_DINNER_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8117	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARR_COMMENT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8120	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8121	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_BYTES_REQMAXRECD_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8125	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SLE_SERVER_PORT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8142	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE8_I_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8143	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	ULA_REQUESTS_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8152	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbEdit_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8165	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_4_LUNCH_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8169	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARA_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8170	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TP_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8175	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TP_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8177	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE7_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8188	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTK_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8189	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LG_ISO3_ALT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8193	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE0_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8195	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DB_DESC_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8199	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	FCY_AREA_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8223	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CSN_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8227	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE4_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8230	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	AE_GO_REF_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8233	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TP_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8235	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_SEP_THOU_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8239	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE8_TEXT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8241	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE7_TEXT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8246	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_START_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8258	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_IP_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8261	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_1_DINNER_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8262	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_LAST_USED_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8267	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_3_NIGHT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8271	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_FILTER_NAME_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8283	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_SCHEMA_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8302	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_COL_COUNT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8304	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	TabControl_DIC_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8319	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DB_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8320	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DD_METHOD_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8331	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE5_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8337	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_0_BFAST_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8341	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	RFG_TIME_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8346	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbSend_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8347	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE_SP_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8359	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	USR_STARTDATE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8367	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LIB_KEY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8385	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_6_NIGHT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8394	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DIL_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8395	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_BYTES_REQTOTSENT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8397	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CFG_VALUE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8400	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SLV_SERVER_PORT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8403	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	USR_USR_REF_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8405	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_6_BFAST_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8406	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPP_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8412	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	InstructPM2_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8413	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_6_BFAST_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8418	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	AE_FAIL_STATUS_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8419	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DB_DESC_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8422	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8425	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LG_ISO2_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8432	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARA_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8443	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_LAST_USED_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8452	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE6_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8453	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_COL_ORDER_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8461	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_COUNT_START_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8469	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_5_NIGHT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8471	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPF_MCOUNT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8473	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbMinusRoleUser_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8479	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_2_BFAST_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8480	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	RFG_TIME_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8489	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TP_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8502	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8508	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	ULA_LAST_HIT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8509	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8512	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE4_TEXT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8514	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_PROD_CODE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8515	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_NAME_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8519	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTA_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8538	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_ADMIN_DATE_TO_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8541	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_IP_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8565	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbBack_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8567	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE6_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8585	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DD_METHOD_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8586	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_METRO_CODE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8587	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_CWHEN_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8595	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_SEQ_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8596	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_SCORE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8602	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_ACTIVE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8603	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DG_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8610	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SLV_SERVER_IP_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8617	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LIB_NAME_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8633	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PSN_FIRST_NAME_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8637	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SLE_SERVER_IP_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8644	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_4_DINNER_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8647	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LG_ISO3_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8649	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CFG_DESC_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8671	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_LATITUDE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8679	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPF_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8693	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE3_TEXT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8695	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LG_MBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8702	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_LAST_RESPONSE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8705	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TST_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8706	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TTA_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8710	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE0_I_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8713	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_5_BFAST_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8714	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8719	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_1_BFAST_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8728	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE1_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8731	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbDeleteRole_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8735	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	USR_ACTIVE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8738	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8740	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DSL_STATUS_FROM_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8742	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8745	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DR_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8767	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	InstructPM3_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8771	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	AE_FAIL_DIALOGUE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8774	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_5_LUNCH_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8777	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PSN_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8782	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_END_DATE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8785	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LIB_VALUE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8787	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE6_H_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8797	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE3_N_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8803	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	AE_FAIL_COUNT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8804	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DR_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8810	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE6_I_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8814	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE4_N_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8815	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_FILTER_DESC_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8819	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8823	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE8_H_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8827	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_0_DINNER_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8830	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_ARA_REF_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8832	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbSearch_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8834	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DSL_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8842	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_ACTIVE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8845	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DB_KEY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8849	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	SLV_VHOST_REF_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8859	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_ZIP_CODE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8865	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbFetch_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8866	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LG_DESC_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8869	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DSL_SEQ_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8871	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE2_N_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8875	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE5_I_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8886	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	SH_Intro	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8893	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbPlusUserGroupOrg_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8898	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8900	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE7_H_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8902	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_CWHEN_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8922	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE7_I_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8931	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_SEQ_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8932	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	IMT_SCHEMA_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8939	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_ZIP_CODE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8943	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_ACTIVE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8948	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_6_LUNCH_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8950	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_4_NIGHT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8954	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8957	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DSL_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8958	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	DSL_CBY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8971	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CO_SEQ_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8978	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE3_H_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8979	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE2_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8981	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PY_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8986	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPC_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8989	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	DD_PATH_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8995	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPP_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8998	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE8_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9013	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE4_H_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9022	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_END_DATE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9024	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE1_I_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9031	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	VEN_CWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9042	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	VEN_MBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9045	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CFG_KEY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9056	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9057	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_BYTES_REQCURSENT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9062	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbHelpPrevious_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9081	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	LIB_SEQ_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9083	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	TPF_SEQ_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9085	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	CFG_NO_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9103	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PROD_FAMILY_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9133	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_3_LUNCH_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9136	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	AE_FAIL_DIALOGUE_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9139	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_MWHEN_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9141	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_3_LUNCH_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9142	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_FILTER_NAME_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9149	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	AFB_MCOUNT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9175	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_EXPIRED_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9190	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_RATE1_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9198	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	STS_BYTES_REQTOTSENT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9200	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	ARA_MCOUNT_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9215	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PY_MWHEN_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9222	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_4_BFAST_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9232	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_PRICE1_N_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9237	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	1	\N	GL_COUNTRY_CODE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9238	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_CBY_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9242	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	PX_6_DINNER_TT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9244	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CF_TITLE_CODE_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9246	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	19	\N	CFP_COMMENT_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
753	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARA_RATING_TT	Rate your experience of the session where 1 = utterly unacceptable, 2 = poor, 3 = could have been better, 4 = good presentation but it didn't hit the mark for me, 5 = good, 6 = excellent, 7 = outstanding.	Bewerte deine Erfahrung der Session, wo 1 = absolut inakzeptabel, 2 = schlecht, 3 = hätte besser sein können, 4 = gute Präsentation, aber es hat nicht die Markierung für mich getroffen, 5 = gut, 6 = ausgezeichnet, 7 = hervorragend.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
758	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_BOOKING_REQD_TT	If arrangement requires people to sign up for, check this book, otherwise arrangement is open to all attendees.	Wenn Arrangement die Leute dazu verpflichten, sich anzumelden, bitte dieses Buch zu überprüfen, sonst ist die Vereinbarung für alle Teilnehmer offen.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
767	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_DAYNO_TT	Relative day number of multi day Conference.  0-n for each day of conference.  Use 0 (zero) for same day of Conference start date.	Relative Tag Anzahl der mehrtägigen Konferenz. 0-n für jeden Tag der Konferenz. Verwenden Sie 0 (Null) für denselben Tag des Startdatum der Konferenz.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
778	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_MAX_BOOKINGS_TT	If numbers are limited for a specific arrangement, enter the maximum number here.	Wenn Zahlen für eine bestimmte Anordnung begrenzt sind, geben Sie hier die maximale Anzahl ein.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
780	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_MCOUNT_LBL	mod. count	Mod. Graf	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
781	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_MCOUNT_TT	Number of times this record has been modified.	Anzahl der Zeiten, in denen dieser Datensatz geändert wurde.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
784	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_ORDER_TT	Use this when Slot may not sort into desirable order.	Verwenden Sie diese Option, wenn Slot nicht in wünschenswerter Reihenfolge sortieren kann.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
740	2017-04-27 15:20:00	stevensg	2017-05-10 13:09:00	MOSTYNRS	2	19	\N	ARA_ANON_TT	<lbl>anonymous</lbl><tt>When reporting this feedback, click here if you want your name suppressed from internal reports.</tt>	<lbl> anonym </lbl> <tt>Wenn Sie dieses Feedback melden, klicken Sie hier, wenn Sie Ihren Namen aus internen Berichten unterdrücken möchten.</tt>	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1968	2017-04-27 15:20:00	stevensg	2017-05-10 13:44:00	MOSTYNRS	3	48	\N	FORM_BSD	Bank transactions	\N	Banktransaktioner	\N	银行交易	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
789	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_SLOT_TT	Abbreviated textual annotation of when arrangement is scheduled: e.g. AM, PM, EVE.  MUTUALLY EXCLUSIVE with Start time.	Abgekürzte Textanmerkung, wenn die Arrangement geplant ist: zB AM, PM, EVE. MUTUELL EXKLUSIV mit Startzeit.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
791	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	ARR_SPECIFIC_EQUIPT_TT	Any session requirements such as flip charts, A5 paper etc should be described here.  Only describe that which is NOT provided with standard equipment of the room/facility.	Jegliche Sitzungsvoraussetzungen wie Flip Charts, A5 Papier usw. sollten hier beschrieben werden. Beschreiben Sie nur das, was NICHT mit der Standardausrüstung des Raumes ausgestattet ist.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
947	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CFP_NAME_LBL	name of rule	Name der Regel	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
951	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_COMMENT_TT	Internal comment about this event	Interner Kommentar zu diesem Event	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
955	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_CURRENCY_TT	Currency used for pricing this event	Währung für die Preisfindung dieser Veranstaltung verwendet	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
959	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_DATE_TO_LBL	end date	Enddatum	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
960	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_DATE_TO_TT	end date of event	Enddatum der Veranstaltung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
962	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_FEATURE_TT	Any feature or strap line to display in marketing material or on website	Jede Eigenschaft oder Gurtlinie, zum im Marketingmaterial oder auf Web site anzuzeigen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
964	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_FILTER_BRAND_TT	The brand filter is used with the Products file to filter in certain products.  Used when company has products in different currencies.	Der Markenfilter wird mit der Produktdatei verwendet, um in bestimmten Produkten zu filtern. Wird verwendet, wenn Unternehmen Produkte in verschiedenen Währungen haben.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
972	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE0_I_LBL	product code for full price, single accommodation	Produkt-Code für den vollen Preis, Einzelunterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
977	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE2_H_LBL	product code for EB2 price, shared accommodation	Produktcode für EB2 Preis, geteilte Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
981	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE3_I_LBL	product code for EB3 price, single accommodation	Produktcode für EB3 Preis, Einzelunterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
985	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE4_N_LBL	product code for EB4 price, no accommodation	Produktcode für EB4 Preis, keine Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
989	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE6_H_LBL	product code for EB6 price, shared accommodation	Produktcode für EB6 Preis, geteilte Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
994	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_PRICE7_N_LBL	product code for EB7 price, no accommodation	Produktcode für EB7 Preis, keine Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
999	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE0_H_TT	full rate, s H ared occupancy	Volle Rate, s h ared Belegung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1004	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE1_I_LBL	one month before	Einen Monat vorher	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1011	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE4_I_TT	four months before	Vier Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1012	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE5_I_LBL	five months before	Fünf Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1016	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_RATE7_I_LBL	seven months before	Sieben Monate zuvor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1023	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CF_TITLE_TT	Name of conference, course or event	Name der Konferenz, Kurs oder Veranstaltung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1248	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_CBY_LBL	created by	erstellt von	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1254	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_CRITERIA_TT	What criteria needs to be met in order to be awarded this Certificate.	Welche Kriterien müssen erfüllt werden, um dieses Zertifikat zu vergeben.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1266	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CRT_RULES_TT	Encoded programming rules that can be used to automatically assign the Certificate.	Kodierte Programmierregeln, mit denen das Zertifikat automatisch zugewiesen werden kann.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1281	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	CSN_COMMENTS_TT	Any comment about the awarding of this certificate can be recoded here.	Jeder Kommentar zur Vergabe dieses Zertifikats kann hier umgeschrieben werden.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1391	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_AMOUNT_DUE_LBL	amount due	Offener Betrag	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1392	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_AMOUNT_DUE_TT	amount remaining to be paid	Noch zu zahlender Betrag	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1399	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_COMPANY_NAME_TT	name of company, if applicable	Name der Firma, falls zutreffend	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1401	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_COUNTRY_TT	copied from PSN_COUNTRY on registration for statistical integrity	Kopiert von PSN_COUNTRY bei der Registrierung zur statistischen Integrität	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1406	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_EMAIL_TRAVEL_SENT_TT	date and time when travel link was sent	Datum und Uhrzeit, an dem die Reiseverbindung gesendet wurde	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1412	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_GROUP_TT	if travelling with others, enter group name here	Wenn Sie mit anderen reisen, geben Sie hier den Gruppennamen ein	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1415	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_INV_TO_EO_ONLY_LBL	if set to 1, email invoice ONLY to customer (not the delegate)	Wenn auf 1 gesetzt, E-Mail-Rechnung NUR an Kunden (nicht der Delegierte)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1416	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_INV_TO_EO_ONLY_TT	if set to 1, email invoice ONLY to customer (not the delegate)	Wenn auf 1 gesetzt, E-Mail-Rechnung NUR an Kunden (nicht der Delegierte)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1422	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_OCCUPANCY_TT	single, shared, no accommodation	Einzelzimmer, geteilt, keine Unterkunft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1428	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_REG_DATE_TT	date of registration, used to determine which rate	Datum der Registrierung, verwendet, um festzustellen, welcher Satz	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1430	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_ROLE_TT	DG, SPKR, KEYNOTE etc - to distinguish from DG_STATUS for payment	DG, SPKR, KEYNOTE etc - von DG_STATUS zur Zahlung zu unterscheiden	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1438	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DG_STATUS_TT	registered, part paid, paid	Registriert, teil bezahlt, bezahlt	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1452	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DIL_PRIMARY_LBL	when multiple delegates paid for on single invoice, DIL_PRIMARY 1 is assigned to main delegate within the group	Wenn mehrere Delegierte für eine einzelne Rechnung bezahlt werden, wird DIL_PRIMARY 1 dem Hauptdelegierten innerhalb der Gruppe zugeordnet	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1493	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DR_PX_REF_LBL	foreign key to PAX	Fremdschlüssel zu PAX	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1496	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	DR_REQUEST_TT	description of dietary requirements	Beschreibung der diätetischen Anforderungen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1862	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	FCY_CWHEN_LBL	created when	Erstellt wann	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1873	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	FCY_NAME_LBL	room name	Raumname	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1884	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	FCY_STD_EQUIPT_LBL	std equipment	Std Ausrüstung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2544	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_AMOUNT_LBL	amount	Menge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2545	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_AMOUNT_TT	amount for membership this year	Betrag für die Mitgliedschaft in diesem Jahr	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2554	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_PSN_REF_LBL	foreign key to PERSON	Fremdschlüssel für PERSON	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2560	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	MB_TYPE_TT	personal or corporate membership	Persönliche oder korporative Mitgliedschaft	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3793	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_ACTIVE_LBL	active	aktiv	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3797	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_COMPANY_TT	name of company, if applicable	Name der Firma, falls zutreffend	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3799	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_COUNTRY_TT	country	Land	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3804	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_GO_REF_LBL	foreign key to internal organisation	Fremdschlüssel zur internen Organisation	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3810	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_PHOTOID_NO_LBL	<lbl>photo id no.</lbl><tt>Serial number of phot id, to be presented at course to validate person attending.</tt>	<lbl> Photo id nein </lbl> <tt>Seriennummer der Fot-ID, die zur Vorlage der Person vorgestellt werden soll.</tt>	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3813	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PSN_PHOTOID_TYPE_TT	<lbl>photo id type</lbl><tt>passport, drivers licence, ID card  etc</tt>	<lbl> Foto-ID-Typ </lbl> <tt>Pass, Führerschein, Ausweis usw.</tt>	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3941	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PX_0_LUNCH_LBL	lunch	Mittagessen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3945	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PX_DG_REF_TT	Reference to delegate record that links Person to Event.	Verweis auf delegate Datensatz, der Person zu Ereignis verknüpft.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3956	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_CHARGES_TT	paypal charges recorded here (optional)	Paypal Gebühren hier aufgezeichnet (optional)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3961	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	PY_DG_REF_TT	Reference to delegate record that links Person to Event.	Verweis auf delegate Datensatz, der Person zu Ereignis verknüpft.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4708	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_ABSTRACT_LBL	Abstract	Abstrakt	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4714	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_DESC_TT	Description of topic in full	Beschreibung des Themas in vollem Umfang	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4716	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_DURN_MINS_TT	duration in minutes	Dauer in Minuten	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4721	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPC_REQUESTS_TT	Speaker requests for equipment, props, specific room requirements	Sprecheranforderungen für Ausrüstung, Requisiten, spezifische Raumanforderungen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4734	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPF_STATUS_TT	If a topic is assigned and then subsequently withdrawn, instead of deleting the record a status can be used to keep the record and describe the fate of the topic.	Wenn ein Thema zugewiesen und anschließend zurückgezogen wird, kann anstelle des Datensatzes ein Status verwendet werden, um den Datensatz zu behalten und das Schicksal des Themas zu beschreiben.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4743	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TPP_PSN_REF_TT	Reference linking this Person to a particular Topic.	Referenz, die diese Person mit einem bestimmten Thema verbindet.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4758	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_COMMENT_TT	any other comment	Irgendeine andere kommentierung	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4760	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_CONNECT_HOW_TT	how is person connecting from arrival point to venue ( bus, train etc with departure time if relevant )	Wie ist die Person von Ankunftsort zu Veranstaltungsort (Bus, Zug usw. mit Abfahrtszeit, falls relevant)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4770	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_DEP_VENUE_LBL	proposed time to leave venue	Vorgeschlagene Zeit, den Veranstaltungsort zu verlassen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4773	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_DG_REF_TT	foreign key to DELEGATE	Fremdschlüssel zum DELEGATE	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4775	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_EARLY_PLANS_TT	may be arriving some days before and staying elsewhere	Kann einige Tage vorher ankommen und woanders bleiben	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4785	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_LOCAL_ARR_WHERE_TT	used to determine shuttle pick-up point	Verwendet, um Shuttle Pick-up-Punkt zu bestimmen	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4798	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TP_SHUTTLE_LBL	use shuttle service	Nutzen Sie den Shuttleservice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4820	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_FORMAT_TT	The question could be multiple choice, textual response, or whatever.  The response type is specified here.	Die Frage könnte Multiple Choice, Textantwort oder was auch immer sein. Hier wird die Antwortart angegeben.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4829	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TSQ_RULE_TT	Encoded programming rule(s) required to determine correct response.	Kodierte Programmierregel (en) erforderlich, um die richtige Antwort zu bestimmen.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4834	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_ARR_REF_TT	Mutually exclusive against conference.  Specify either the session/lecture/workshop, or the course this test applies to, but not both.	Gegenseitig exklusiv gegen konferenz Geben Sie entweder die Sitzung / Vorlesung / Werkstatt oder den Kurs an, für den dieser Test gilt, aber nicht beides.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4837	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_CF_REF_TT	Identify the course tha this test applies to, assuming test does not apply to a session or workshop within the course.	Identifizieren Sie den Kurs, den dieser Test anwendet, wenn der Test nicht für eine Sitzung oder einen Workshop im Kurs gilt.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4848	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_PASS_COUNT_LBL	pass count	Passzähler	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4849	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TST_PASS_COUNT_TT	How many questions, or what percentage, will set the pass rate.	Wie viele Fragen, oder welcher Prozentsatz, wird die Passrate festlegen.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4862	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTA_SEQ_LBL	record ID	Datensatz-ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4866	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTA_TTK_REF_TT	Reference to the test taken header record.	Verweis auf den getesteten Header-Datensatz.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4875	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_MINUTES_TT	No. of minutes actually taken to complete the test.	Anzahl der Minuten, die tatsächlich durchgeführt wurden, um den Test abzuschließen.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4881	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	TTK_STATUS_TT	As test is taken, a status is maintained to record progress made through test.	Als Test wird ein Status beibehalten, um den durch den Test durchgeführten Fortschritt aufzuzeichnen.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5230	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_BUILDING_LBL	Building	Gebäude	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5231	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_BUILDING_TT	address - building name	Adresse - Name des Gebäudes	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3939	2017-04-27 15:20:00	stevensg	2018-10-22 13:31:00	STEVENSG	2	19	\N	PX_0_BFAST_LBL	breakfast	Frühstück	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5238	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_INSTRUCTIONS_TT	comment or note about venue, published online or to delegates	Kommentar oder Notiz über den Veranstaltungsort, veröffentlicht online oder an Delegierte	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5250	2017-04-27 15:20:00	stevensg	2017-05-03 12:13:00	MOSTYNRS	1	19	\N	VEN_SEARCH_LBL	Upper caseer case copy of VEN_NAME without accented characters for searching	Großbuchstaben Kopie von VEN_NAME ohne akzentuierte Zeichen für die Suche	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9252	2017-05-04 12:18:00	STEVENSG	2017-05-04 12:18:00	STEVENSG	1	1	\N	STS_TABLE_METHOD	table class method name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9253	2017-05-04 12:18:00	STEVENSG	2017-05-04 12:18:00	STEVENSG	1	1	\N	STS_PARAMS_LBL	web service parameters in JSON format	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9254	2017-05-04 12:18:00	STEVENSG	2017-05-04 12:18:00	STEVENSG	1	1	\N	STS_PARAMS_TT	web service parameters in JSON format	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9247	2017-05-04 12:17:00	STEVENSG	2017-05-04 12:17:00	STEVENSG	1	1	\N	STS_WS_NAME_LBL	web service name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9248	2017-05-04 12:17:00	STEVENSG	2017-05-04 12:17:00	STEVENSG	1	1	\N	STS_WS_NAME_TT	web service name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9249	2017-05-04 12:17:00	STEVENSG	2017-05-04 12:17:00	STEVENSG	1	1	\N	STS_TABLE_NAME_LBL	table class name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9250	2017-05-04 12:18:00	STEVENSG	2017-05-04 12:18:00	STEVENSG	1	1	\N	STS_TABLE_NAME_TT	table class name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9251	2017-05-04 12:18:00	STEVENSG	2017-05-04 12:18:00	STEVENSG	1	1	\N	STS_TABLE_METHOD_LBL	table class method name	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7075	2017-04-27 15:34:48	stevensg	2017-09-25 13:19:00	STEVENSG	3	19	\N	AFB_ARA_REF_LBL		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8141	2017-04-27 15:34:48	stevensg	2017-05-10 12:20:00	MOSTYNRS	1	19	\N	AFB_CBY_LBL		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9053	2017-04-27 15:34:48	stevensg	2017-05-10 12:24:00	MOSTYNRS	1	19	\N	AFB_RFO_VALUE_LBL		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
739	2017-04-27 15:20:00	stevensg	2017-05-10 13:23:00	MOSTYNRS	3	19	\N	ARA_ANON_LBL	<lbl>anonymous</lbl><tt>When reporting this feedback, click here if you want your name suppressed from internal reports.</tt>	<lbl> anonym </lbl> <tt>Wenn Sie dieses Feedback melden, klicken Sie hier, wenn Sie Ihren Namen aus internen Berichten unterdrücken möchten.</tt>	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1969	2017-04-27 15:20:00	stevensg	2017-05-10 13:44:00	MOSTYNRS	3	48	\N	FORM_CL	Members	\N	Medlemmar	\N	会员	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2003	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	3	48	\N	FORM_REPORT	Reports	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2005	2017-04-27 15:20:51	stevensg	2017-05-10 13:44:00	MOSTYNRS	1	48	\N	FORM_RFG	Global configuration	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4251	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	1	\N	RFG_EFFECTIVE_LBL	valid from	\N	\N	\N	\N	\N	válida desde	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4253	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	1	\N	RFG_EXPIRES_LBL	valid to	\N	\N	\N	\N	\N	válido hasta	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4290	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	1	\N	RFL_EFFECTIVE_LBL	valid from date	\N	\N	\N	\N	\N	Válido desde la fecha	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4334	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	1	\N	RFO_EFFECTIVE_LBL	valid from date	\N	\N	\N	\N	\N	Válido desde la fecha	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4380	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	1	\N	RFU_EFFECTIVE_LBL	valid from date	\N	\N	\N	\N	\N	Válido desde la fecha	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4381	2017-04-27 15:20:00	stevensg	2017-05-11 16:23:00	STEVENSG	1	1	\N	RFU_EFFECTIVE_TT	valid from date	\N	\N	\N	\N	\N	Válido desde la fecha	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5177	2017-04-27 15:20:00	stevensg	2018-06-19 04:06:00	MOSTYNRS	2	40	\N	VAL_EMAIL_NOT_RECOGNISED	email not recognised	\N	\N	\N	\N	\N	Email no reconocido	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9955	2018-11-07 12:55:00	STEVENSG	2018-11-07 12:55:00	STEVENSG	1	57	\N	PDF_THANKS_ALL_D	Sends a thanks to all in the filtered list.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3596	2017-04-27 15:20:51	stevensg	2017-06-15 14:41:56	STEVENSG	3	1	\N	PRD_SIZE_TT	Enter the size of the packet or product here  e.g. 750ml or 500g	Geben Sie die Größe des Pakets oder Produktes hier zB 750ml oder 500g ein	Ange storleken på paketet eller produkten här, t.ex. 750 ml eller 500 g	\N	输入数据包或产品的大小，例如750ml或500g	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9359	2017-06-16 12:00:00	STEVENSG	2017-06-16 12:01:00	STEVENSG	1	3	\N	MSG_IMPOPENLCA	Import from openLCA Inventory export	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2793	2017-04-27 15:20:51	stevensg	2017-06-19 10:36:00	STEVENSG	1	3	\N	ERR_INSERTLCI	Cannot insert LCI data for product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9361	2017-06-16 15:58:00	STEVENSG	2017-06-19 10:40:00	STEVENSG	2	3	\N	MSG_LCAIDUNKNOWN	Flow UUID/name or ontology not found	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9362	2017-07-05 13:06:00	STEVENSG	2017-07-05 13:06:00	STEVENSG	1	3	\N	MSG_SELFREFERENCE	this record cannot reference itself	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9363	2017-07-18 11:01:00	STEVENSG	2017-07-18 11:15:00	STEVENSG	6	3	,fr,	MSG_MISSINGTOADDRESS	"to" address missing	"An" Adresse fehlt	\N	\N	\N	\N	"To" address missing	\N	"An" Adresse fehlt	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9371	2017-07-28 11:33:00	STEVENSG	2017-07-28 11:34:00	STEVENSG	1	3	\N	MSG_UNKNOWNSOURCE	Source of flows could not be identified	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9372	2017-07-28 11:34:00	STEVENSG	2017-07-28 11:34:00	STEVENSG	1	3	\N	MSG_MIXEDSOURCES	Flows have been taken from more than one source	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9373	2017-07-28 16:58:00	STEVENSG	2017-07-28 16:58:00	STEVENSG	1	3	\N	MSG_INSERTFAILED	unable to insert the record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4906	2017-04-27 15:20:51	stevensg	2017-08-10 09:07:00	STEVENSG	1	40	\N	TabControl_ORH_TT	days in selected accounting period with previous period comparison and period adjustment factor\\production forecast figures by GROUP_METHOD\\proportional distribution of overheads by product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9380	2017-08-16 11:07:00	STEVENSG	2017-08-16 11:07:00	STEVENSG	1	3	\N	MSG_INVALIDUOM	invalid unit of measure	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9360	2017-06-16 12:07:00	STEVENSG	2017-06-16 12:07:00	STEVENSG	1	40	\N	cb_ReportErrors	Report errors, do not abort import	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4899	2017-04-27 15:20:51	stevensg	2018-04-10 16:02:00	STEVENSG	2	40	\N	TabControl_GO_TT	organisation(s) making up this company group\\view, edit and save EcoCost registration details\\creation and modification details (view only)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9391	2017-09-06 12:23:00	STEVENSG	2017-09-06 12:23:00	STEVENSG	1	40	\N	Imports_LBL	import(s)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5557	2017-04-27 15:20:51	stevensg	2017-09-20 15:13:00	STEVENSG	1	40	\N	pbMinusUserGroupOrg_LBL		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9407	2017-09-28 09:12:00	STEVENSG	2017-09-28 09:13:00	STEVENSG	2	40	\N	pbRegisterForSession_LBL	register for session	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9408	2017-09-28 09:12:00	STEVENSG	2017-09-28 09:14:00	STEVENSG	1	40	\N	pbRegisterForSession_TT	register you're intention to attend the selected session	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1566	2017-04-27 15:20:51	stevensg	2017-12-18 15:16:00	STEVENSG	1	3	\N	ECA_REFS	reference to batch output or publication	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9415	2017-12-18 15:16:00	STEVENSG	2017-12-18 15:17:00	STEVENSG	1	3	\N	ERR_NODEL_LAST	last record cannot be removed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9416	2017-12-21 10:29:00	STEVENSG	2017-12-21 10:29:00	STEVENSG	1	48	\N	FORM_CER	Carbon emissions reporting	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1959	2017-04-27 15:20:51	stevensg	2018-04-10 16:02:00	STEVENSG	1	40	\N	FOH_POS_Intro	scan customer EcoCost ID first, followed by sales items	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
942	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	C4StartDate_TT	start date of the period over which the product should be depreciated	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
943	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	C5EndDate_LBL	depreciation period end	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
944	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	C5EndDate_TT	end date of the period over which the product should be depreciated	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
945	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	C6AccountName_LBL	overhead account	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
946	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	C6AccountName_TT	name of the overhead account to which the depreciated product ecocost should be applied	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
939	2017-04-27 15:20:51	stevensg	2017-06-16 12:07:00	STEVENSG	1	40	\N	C3Quantity_LBL	quantity to be depreciated	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
940	2017-04-27 15:20:51	stevensg	2017-12-22 11:15:00	STEVENSG	1	40	\N	C3Quantity_TT	quantity of the received product; must be between 0 and total of product received	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1072	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	CMP_Intro	view and edit composite substances for use in process models	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1555	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	DepreciationAccount_LBL	depreciation account details	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2204	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilCategorisationCodes_TT	These name / value pairs are used by the ecoAccounting module to locate a product.  Enter a name and value here then use the same name and value pair in the Processes form when identifying a product used by the Process.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5593	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSaveProductTemplate_LBL	submit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2217	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilEcoInvoiceD_LBL	ecoInvoice Details,Product code,ecoCost vsn,quantity,Product name,Size,Unit	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2218	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilEcoInvoiceD_TT	detail lines for the selected ecoInvoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2225	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilLinkedProducts_LBL	,Code,Name,Description	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2226	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilLinkedProducts_TT	listing of products that are final outputs for the currently selected process	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2229	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilManualProducts_LBL	,Enter Product Codes	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2230	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilManualProducts_TT	enter product codes here for products which have not yet been entered or received into the system	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2233	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilProducts_LBL	Products received,date,qty	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2234	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	Grid_ilProducts_TT	date of ecoinvoice for the product/quantity of product received	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3344	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	PEERS_Intro	submit statistics for a selected date range to the PEERS gateway service	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4780	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_LAST_QTR	last quarter	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4781	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_LAST_WEEK	last week	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4792	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_OTHER	other period	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4793	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_PRV_LAST_FNIGHT	previous to last fortnight	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4794	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_PRV_LAST_MONTH	previous to last month	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4795	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_PRV_LAST_QTR	previous to last quarter	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4796	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_PRV_LAST_WEEK	previous to last week	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4800	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_THIS_FNIGHT	this fortnight	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4801	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_THIS_MONTH	this month	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4802	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_THIS_QTR	this quarter	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4803	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_THIS_WEEK	this week	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4804	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_TODAY	today	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4805	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	TP_YESTERDAY	yesterday	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5312	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ct_ACL_COMMENT	reason for adjustment figure	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5313	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ct_dateentry	DD/MM/YY	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5318	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_comps	selected composites	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5343	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	disp_submit_success	Submission successful.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5360	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icPOScustomerID_LBL	customer ID	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5362	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icPOSproductID_LBL	product code	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5363	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icPOSproductID_TT	internal product code as obtained from the barcode	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5366	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icTextSearchInput_LBL	search text	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5367	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icTextSearchInput_TT	Text entered here will be used to filter input options according to the input source specified.  Use % as a wild card.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5368	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icTextSearchOutput_LBL	search output	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5369	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	icTextSearchOutput_TT	Text entered here will be used to filter the output options.  Use % as a wild card	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5370	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilCategories_LBL	category	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5371	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilCategories_TT	Provide a category code, used to classify the product within LCA guidelines.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5372	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilCategorisationCodes_LBL	codes	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5373	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilCategorisationCodes_TT	text	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5384	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilSubCategories_LBL	sub category	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5385	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	ilSubCategories_TT	A sub category code forms the other half of a category, used to fully classify the product within LCA guidelines.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5472	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_clear_qty	Changing to a quote will clear all quantities and prices.  Continue?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5482	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_emptyenddate	period end date cannot be empty	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5483	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_emptystartdate	period start date cannot be empty	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5489	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	msg_submit_peers	Are you sure you want to submit statistical data//for the period [%START%] to [%END%] ?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5501	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbAddDepreciation_TT	create a depreciation account for the selected product	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5517	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbCancelDepreciation_TT	cancel the changes to the selected depreciation account details	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5526	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbDeleteDepreciation_TT	delete the selected depreciation account details	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5535	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbEditDepreciation_TT	modify the selected depreciation account details	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5565	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbNextEntry_TT	go to the next line in the list of entries, disabled when the last line is displayed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5578	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbPreviousEntry_LBL	previous	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5579	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbPreviousEntry_TT	go to the previous line in the list of entries, disabled when the first line is displayed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5591	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSaveDepreciation_LBL	save	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5592	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSaveDepreciation_TT	submit the product depreciation details to the ecoaccounting system	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5594	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSaveProductTemplate_TT	submit the product template to the ecoAccounting Module	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5601	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSubmitPEERS_LBL	submit to PEERS	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5602	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSubmitPEERS_TT	click to submit statistical data for the selected date range to the PEERS gateway	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5603	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	pbSubmitQuote_LBL	submit for ecoquote	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5811	2017-04-27 15:20:51	stevensg	2017-04-27 15:20:51	stevensg	0	40	\N	word_outofrange	out of range	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6119	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbSupportTools_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7379	2017-04-27 15:34:48	stevensg	2017-04-27 15:34:48	stevensg	0	40	\N	pbDeleteDepreciation_LBL	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5605	2017-04-27 15:20:51	stevensg	2018-04-10 16:03:00	STEVENSG	1	40	\N	pbSupportTools_TT	symbolising knowledge - taking you to the EcoCost Production Support Tools	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9478	2018-01-08 11:54:00	STEVENSG	2018-02-07 10:41:00	STEVENSG	2	48	\N	FORM_CFG	System configuration	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9489	2018-01-15 14:24:00	STEVENSG	2018-04-12 11:45:00	STEVENSG	4	40	\N	NAVMENU_CONFIG	Configuration	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9470	2018-01-08 11:51:00	STEVENSG	2018-01-30 10:41:00	STEVENSG	4	48	\N	FORM_INVOICING	Invoicing	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9473	2018-01-08 11:52:00	STEVENSG	2018-01-08 11:52:00	STEVENSG	1	48	\N	FORM_OVERHEADS	Overheads	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9475	2018-01-08 11:52:00	STEVENSG	2018-01-08 11:53:00	STEVENSG	1	48	\N	FORM_ECOCOST	ecoCosts	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9486	2018-01-12 15:09:00	STEVENSG	2018-01-12 15:09:00	STEVENSG	1	3	\N	MSG_WARN_SMALLSCREEN	This form is not compatible with this screen size.  Please rotate your device or expand your browser window.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9479	2018-01-08 11:55:00	STEVENSG	2018-02-28 10:21:00	STEVENSG	4	48	\N	FORM_ACCESS	Access permissions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9480	2018-01-08 11:55:00	STEVENSG	2018-01-08 11:55:00	STEVENSG	1	48	\N	FORM_ECOCALC	ecoCost calculations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9481	2018-01-08 14:20:00	STEVENSG	2018-01-08 14:20:00	STEVENSG	1	48	\N	FORM_COH	Carbon category headers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9483	2018-01-08 14:21:00	STEVENSG	2018-01-08 14:21:00	STEVENSG	1	48	\N	FORM_CREP	Carbon reporting	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9487	2018-01-15 11:27:00	STEVENSG	2018-01-15 11:36:00	STEVENSG	2	40	\N	TabControl_Access_LBL	Users\\Roles\\Permissions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9492	2018-01-15 14:27:00	STEVENSG	2018-04-12 11:45:00	STEVENSG	3	40	\N	NAVMENU_DATA	Functions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9472	2018-01-08 11:52:00	STEVENSG	2018-01-26 14:50:00	STEVENSG	2	48	\N	FORM_ORGS	Business setup	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9477	2018-01-08 11:54:00	STEVENSG	2018-01-26 09:39:00	STEVENSG	4	48	\N	FORM_USERINPUT	Send feedback	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9471	2018-01-08 11:51:00	STEVENSG	2018-01-26 09:39:00	STEVENSG	4	48	\N	FORM_BUSCFG	Business configurations	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9474	2018-01-08 11:52:00	STEVENSG	2018-01-26 09:39:00	STEVENSG	3	48	\N	FORM_CARBON	Carbon reporting	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9488	2018-01-15 11:27:00	STEVENSG	2018-01-15 11:32:00	STEVENSG	1	40	\N	TabControl_Access_TT	create and modify user accounts and system access\\create/assign business roles\\create database access permissions	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9491	2018-01-15 14:26:00	STEVENSG	2018-04-12 11:45:00	STEVENSG	4	40	\N	NAVMENU_ORGS	Work in Progress	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9476	2018-01-08 11:53:00	STEVENSG	2018-01-26 14:49:00	STEVENSG	4	48	\N	FORM_GLATTR	Units of Measure, etc.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9493	2018-01-18 11:33:00	MOSTYNRS	2018-01-18 11:33:00	MOSTYNRS	1	40	\N	text_search	text search	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9495	2018-01-18 11:38:00	MOSTYNRS	2018-01-18 11:40:00	MOSTYNRS	1	40	\N	text_search_TT	Text entered here will be searched for broadly.  Use text% to search from beginning, use %text to search from end.  Default is search anywhere.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9494	2018-01-18 11:38:00	MOSTYNRS	2018-01-18 11:40:00	MOSTYNRS	2	40	\N	text_search_LBL	search text	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9496	2018-01-18 11:52:00	MOSTYNRS	2018-01-18 11:53:00	MOSTYNRS	1	3	\N	inconsistent_su	Inconsistent restriction	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9497	2018-01-18 11:56:00	MOSTYNRS	2018-01-18 11:57:00	MOSTYNRS	1	1	\N	PER_SU_LBL	restricted	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9499	2018-01-18 11:56:00	MOSTYNRS	2018-01-18 11:57:00	MOSTYNRS	1	1	\N	ROL_SU_LBL	restricted	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9501	2018-01-18 11:56:00	MOSTYNRS	2018-01-18 11:57:00	MOSTYNRS	1	1	\N	USR_SU_LBL	restricted	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9502	2018-01-18 11:56:00	MOSTYNRS	2018-01-18 11:58:00	MOSTYNRS	1	1	\N	USR_SU_TT	Restricted users are limited to restricted roles and restricted roles are limted to restricted permissions.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9498	2018-01-18 11:56:00	MOSTYNRS	2018-01-18 11:58:00	MOSTYNRS	1	1	\N	PER_SU_TT	Restricted users are limited to restricted roles and restricted roles are limted to restricted permissions.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9500	2018-01-18 11:56:00	MOSTYNRS	2018-01-18 11:58:00	MOSTYNRS	1	1	\N	ROL_SU_TT	Restricted users are limited to restricted roles and restricted roles are limted to restricted permissions.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9503	2018-01-19 14:50:00	MOSTYNRS	2018-01-19 14:50:00	MOSTYNRS	1	40	\N	TabControl_Ref_LBL	Prefs\\Organisation\\Site\\Global	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9504	2018-01-19 14:50:00	MOSTYNRS	2018-01-19 14:52:00	MOSTYNRS	1	40	\N	TabControl_Ref_TT	User preferences\\Company specific values\\Site specific values applicable to all businesses in this installation\\Standard values applicable to every site	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9506	2018-01-26 11:49:00	MOSTYNRS	2018-01-26 11:50:00	MOSTYNRS	2	40	\N	TabControl_Interact_LBL	Group company\\Suppliers\\Customers\\Products\\Invoicing	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9507	2018-01-26 11:49:00	MOSTYNRS	2018-01-26 11:53:00	MOSTYNRS	1	40	\N	TabControl_Interact_TT	Internal group companies\\Organisations from whom we purchase things\\Organisations to whom we sell things\\The items we sell\\Financial invoices	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9508	2018-01-26 15:08:00	STEVENSG	2018-01-26 15:08:00	STEVENSG	1	48	\N	FORM_ECOINV	ecoInvoices	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9509	2018-02-08 14:31:00	MOSTYNRS	2018-02-08 14:31:00	MOSTYNRS	1	3	\N	REC_UPDATED	Record has been updated.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9510	2018-02-08 14:31:00	MOSTYNRS	2018-02-08 14:31:00	MOSTYNRS	1	3	\N	REC_INSERTED	Record has been inserted.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9511	2018-02-08 14:31:00	MOSTYNRS	2018-02-08 14:32:00	MOSTYNRS	1	3	\N	REC_NOCHANGE	The record has not been altered so no changes made.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9512	2018-02-08 14:32:00	MOSTYNRS	2018-02-08 14:32:00	MOSTYNRS	1	3	\N	REC_CANC	Changes have been discarded.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9513	2018-02-08 14:45:00	MOSTYNRS	2018-02-08 14:46:00	MOSTYNRS	1	3	\N	not_authorised	You are not authorised to perform this function.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9514	2018-02-08 15:04:00	MOSTYNRS	2018-02-08 15:05:00	MOSTYNRS	1	3	\N	REC_INSERT	You are inserting a new record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9515	2018-02-08 15:05:00	MOSTYNRS	2018-02-08 15:05:00	MOSTYNRS	1	3	\N	REC_UPDATE	You are editing an existing record.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9516	2018-02-08 20:59:00	MOSTYNRS	2018-02-08 21:00:00	MOSTYNRS	1	3	\N	REC_DELETED	Record has been deleted.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5035	2017-04-27 15:20:51	stevensg	2018-02-08 21:20:00	MOSTYNRS	1	1	\N	USR_INITIALS_LBL	initials	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9517	2018-02-13 08:35:00	MOSTYNRS	2018-02-13 08:36:00	MOSTYNRS	1	40	\N	TabControl_Logs_LBL	Events\\Errors\\Async. email queue	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9518	2018-02-13 08:36:00	MOSTYNRS	2018-02-13 08:38:00	MOSTYNRS	1	40	\N	TabControl_Logs_TT	Log of system events\\Log of system errors\\Asyncronous email queue - messages waiting to be sent via email.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9521	2018-02-28 10:21:00	STEVENSG	2018-02-28 10:22:00	STEVENSG	1	48	\N	FORM_FIC	Import classification	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9519	2018-02-16 12:32:00	STEVENSG	2018-02-16 12:33:00	STEVENSG	2	40	\N	TabControl_ROLES_LBL	Permissions\\Users	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9520	2018-02-16 12:33:00	STEVENSG	2018-02-16 12:36:00	STEVENSG	2	40	\N	TabControl_ROLES_TT	lists of permissions granted to and revoked from the selected role\\users who have or can be granted the selected role	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9534	2018-03-09 12:10:00	MOSTYNRS	2018-03-09 12:11:00	MOSTYNRS	1	40	\N	SCREEN_TOO_SMALL	This form is not compatible with this screen size. Please rotate your device or expand your browser window.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9548	2018-03-14 11:05:00	MOSTYNRS	2018-03-14 12:44:00	MOSTYNRS	2	52	\N	FACT_UPDR_D	Modify the current record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9546	2018-03-14 11:04:00	MOSTYNRS	2018-03-14 12:43:00	MOSTYNRS	2	52	\N	FACT_INSR_D	Create a new record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9505	2018-01-25 15:25:00	STEVENSG	2018-04-12 11:45:00	STEVENSG	2	40	\N	NAVMENU_CASCADE	Select an option:	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9543	2018-03-14 10:53:00	STEVENSG	2018-03-14 10:53:00	STEVENSG	1	40	\N	TabControl_Invoicing_LBL	Financial invoices\\ecoInvoices sent\\ecoInvoices received	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9544	2018-03-14 10:54:00	STEVENSG	2018-03-14 10:55:00	STEVENSG	1	40	\N	TabControl_Invoicing_TT	create and edit customer invoices and submit them for ecoInvoice despatch\\view ecoInvoices despatched to customers\\view ecoInvoices received from suppliers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9555	2018-03-14 11:07:00	MOSTYNRS	2018-03-14 11:07:00	MOSTYNRS	1	52	\N	FACT_ZZZ	ZZZ	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9547	2018-03-14 11:05:00	MOSTYNRS	2018-03-14 12:43:00	MOSTYNRS	2	52	\N	FACT_UPDR	Edit record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9549	2018-03-14 11:05:00	MOSTYNRS	2018-03-14 11:06:00	MOSTYNRS	1	52	\N	FACT_DELR	Delete record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9550	2018-03-14 11:06:00	MOSTYNRS	2018-03-14 11:06:00	MOSTYNRS	1	52	\N	FACT_DELR_D	Permanently remove the current record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9551	2018-03-14 11:06:00	MOSTYNRS	2018-03-14 11:06:00	MOSTYNRS	1	52	\N	FACT_XXX	XXX	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9552	2018-03-14 11:06:00	MOSTYNRS	2018-03-14 11:06:00	MOSTYNRS	2	52	\N	FACT_XXX_D	Apply the XXX action	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9553	2018-03-14 11:07:00	MOSTYNRS	2018-03-14 11:07:00	MOSTYNRS	1	52	\N	FACT_YYY	YYY	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9554	2018-03-14 11:07:00	MOSTYNRS	2018-03-14 11:07:00	MOSTYNRS	1	52	\N	FACT_YYY_D	Apply the YYY action	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9556	2018-03-14 11:07:00	MOSTYNRS	2018-03-14 11:07:00	MOSTYNRS	1	52	\N	FACT_ZZZ_D	Apply the ZZZ action	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9557	2018-03-14 11:08:00	MOSTYNRS	2018-03-14 11:08:00	MOSTYNRS	1	52	\N	FACT_PRINT	Print	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9558	2018-03-14 11:08:00	MOSTYNRS	2018-03-14 11:09:00	MOSTYNRS	1	52	\N	FACT_PRINT_D	Print the current record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9559	2018-03-14 12:10:00	STEVENSG	2018-03-14 12:10:00	STEVENSG	1	40	\N	word_to	to	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9560	2018-03-14 12:42:00	MOSTYNRS	2018-03-14 12:42:00	MOSTYNRS	1	52	\N	FACT_DUP	Duplicate	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9561	2018-03-14 12:42:00	MOSTYNRS	2018-03-14 12:43:00	MOSTYNRS	1	52	\N	FACT_DUP_D	Clone this record and modify	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9545	2018-03-14 11:04:00	MOSTYNRS	2018-03-14 12:43:00	MOSTYNRS	3	52	\N	FACT_INSR	Insert record	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9565	2018-03-15 12:28:00	STEVENSG	2018-03-15 12:28:00	STEVENSG	2	3	\N	MSG_DISALLOWLASTDGFROMINV	you cannot remove the last delegate from an invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9566	2018-03-15 16:29:00	STEVENSG	2018-03-15 16:31:00	STEVENSG	2	3	\N	MSG_DISALLOWDGLINKCHANGE	delegate changes are no longer allowed on invoices	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1802	2017-04-27 15:20:51	stevensg	2018-04-10 16:02:00	STEVENSG	1	1	\N	EO_MEC_ID_TT	Unique code identifying this company within the EcoCost network.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2083	2017-04-27 15:20:51	stevensg	2018-04-10 16:02:00	STEVENSG	1	1	\N	GO_DDN_AP1_LBL	EcoCost Access point 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2085	2017-04-27 15:20:51	stevensg	2018-04-10 16:02:00	STEVENSG	1	1	\N	GO_DDN_AP2_LBL	EcoCost Access point 2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5361	2017-04-27 15:20:51	stevensg	2018-04-10 16:02:00	STEVENSG	1	40	\N	icPOScustomerID_TT	the customer's EcoCost identifier	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9754	2018-04-11 15:06:00	STEVENSG	2018-04-11 15:06:00	STEVENSG	1	48	\N	FORM_MEMBERS	Memberships	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9756	2018-04-12 17:21:00	STEVENSG	2018-04-12 17:22:00	STEVENSG	1	52	\N	FACT_UPDLINK_D	Modify the selected link	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9758	2018-04-12 17:22:00	STEVENSG	2018-04-12 17:22:00	STEVENSG	1	52	\N	FACT_DELLINK_D	Delete the selected link	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9757	2018-04-12 17:22:00	STEVENSG	2018-04-12 17:22:00	STEVENSG	2	52	\N	FACT_DELLINK	Delete	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9755	2018-04-12 17:20:00	STEVENSG	2018-04-12 17:23:00	STEVENSG	2	52	\N	FACT_UPDLINK	Modify	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9765	2018-04-13 10:10:00	STEVENSG	2018-04-13 10:12:00	STEVENSG	2	52	\N	FACT_SPACER		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9766	2018-04-13 10:11:00	STEVENSG	2018-04-13 10:14:00	STEVENSG	2	52	\N	FACT_SPACER_D	---------------------	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9768	2018-04-13 10:57:00	STEVENSG	2018-04-13 10:57:00	STEVENSG	1	52	\N	FACT_PRINTREP	Print	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9769	2018-04-13 10:58:00	STEVENSG	2018-04-13 10:58:00	STEVENSG	1	52	\N	FACT_PRINTREP_D	Print the selected report	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9784	2018-04-17 16:18:00	STEVENSG	2018-04-17 16:18:00	STEVENSG	1	48	\N	FORM_PART	Participants	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9785	2018-04-17 16:18:00	STEVENSG	2018-04-17 16:18:00	STEVENSG	1	48	\N	FORM_EVENT	Events	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9786	2018-04-17 16:19:00	STEVENSG	2018-04-17 16:19:00	STEVENSG	1	48	\N	FORM_SETUP	Nut & Bolts	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9787	2018-04-17 16:19:00	STEVENSG	2018-04-17 16:19:00	STEVENSG	1	48	\N	FORM_VALID	Validity	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9788	2018-04-20 11:52:00	STEVENSG	2018-04-20 11:53:00	STEVENSG	1	42	\N	disp_members	Members	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9789	2018-04-20 12:04:00	STEVENSG	2018-04-20 12:04:00	STEVENSG	1	42	\N	disp_venues	All venues	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9790	2018-04-20 12:48:00	STEVENSG	2018-04-20 12:49:00	STEVENSG	1	42	\N	disp_events	All events	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9791	2018-04-20 14:36:00	STEVENSG	2018-04-20 14:36:00	STEVENSG	1	42	\N	disp_attendees	All attendees	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9792	2018-04-23 09:40:00	STEVENSG	2018-04-23 09:40:00	STEVENSG	1	42	\N	disp_certs	Selected certificates	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9793	2018-04-23 15:20:00	STEVENSG	2018-04-23 15:21:00	STEVENSG	1	52	\N	FACT_MEMB	Record membership	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9794	2018-04-23 15:21:00	STEVENSG	2018-04-23 15:21:00	STEVENSG	0	52	\N	FACT_MEMB_D	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9820	2018-04-26 11:41:00	STEVENSG	2018-04-26 11:41:00	STEVENSG	1	40	\N	ICHACC_Heading	Imported Accounts Data Classification	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9821	2018-04-26 11:43:00	STEVENSG	2018-04-26 11:44:00	STEVENSG	1	40	\N	ICHACC_Intro	create/modify classification rules that will be applied to imported accounts data on processing the imports	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9841	2018-05-14 14:14:00	MOSTYNRS	2018-05-14 14:16:00	MOSTYNRS	2	19	\N	CF_MAX_DELEGATES_LBL	max. delegates	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9842	2018-05-14 14:15:00	MOSTYNRS	2018-05-14 14:16:00	MOSTYNRS	2	19	\N	CF_MAX_SPEAKERS_LBL	max. speakers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9844	2018-05-14 14:16:00	MOSTYNRS	2018-05-14 14:17:00	MOSTYNRS	1	19	\N	CF_MAX_SPEAKERS_TT	Maximum number of speakers that can register online.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9843	2018-05-14 14:16:00	MOSTYNRS	2018-05-14 14:17:00	MOSTYNRS	1	19	\N	CF_MAX_DELEGATES_TT	Maximum number of delegates that register online.  After this the WAITLIST option will appear.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9845	2018-05-21 14:22:00	STEVENSG	2018-05-21 14:22:00	STEVENSG	1	40	\N	word_ignore	ignore	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9846	2018-05-21 14:22:00	STEVENSG	2018-05-21 14:23:00	STEVENSG	2	40	\N	word_rows	rows	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9854	2018-06-13 16:30:00	MOSTYNRS	2018-06-13 16:31:00	MOSTYNRS	1	3	\N	max_opt_exceeded	You have exceeded the maximum allowed.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9855	2018-06-13 16:31:00	MOSTYNRS	2018-06-13 16:31:00	MOSTYNRS	1	3	\N	max_opt_reached	You have reached the maximum number of options allowed.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3601	2017-04-27 15:20:51	stevensg	2018-06-14 15:25:00	STEVENSG	5	1	\N	PRD_UOS_CODE_LBL	unit of measure	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5173	2017-04-27 15:20:00	stevensg	2018-06-19 04:06:00	MOSTYNRS	2	40	\N	VAL_EMAIL_BADFORMAT	Invalid email address format	\N	\N	\N	\N	\N	Formato de dirección de correo electrónico no válido	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5172	2017-04-27 15:20:00	stevensg	2018-06-19 04:06:00	MOSTYNRS	2	40	\N	VAL_EMAILANDPASSWORD_NOT_RECOGNISED	email and password not recognised	\N	\N	\N	\N	\N	Correo electrónico y contraseña no reconocidos	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9886	2018-06-19 09:23:00	MOSTYNRS	2018-06-19 09:24:00	MOSTYNRS	1	40	\N	word_printed	Printed:	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9887	2018-07-04 16:50:00	MOSTYNRS	2018-07-04 16:51:00	MOSTYNRS	2	42	\N	TabControl_ARR_LBL	Session\\Requests & Comments\\Attendees\\Overview\\Technical	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9888	2018-07-04 16:51:00	MOSTYNRS	2018-07-04 16:52:00	MOSTYNRS	1	42	\N	TabControl_ARR_TT	There are various ways to view, manage and arrange sessions.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9889	2018-07-09 12:03:00	STEVENSG	2018-07-09 12:03:00	STEVENSG	1	40	\N	word_show	show	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9890	2018-07-09 12:03:00	STEVENSG	2018-07-09 12:03:00	STEVENSG	1	40	\N	word_hide	hide	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9929	2018-10-17 14:02:00	MOSTYNRS	2018-11-07 12:54:00	STEVENSG	2	57	\N	PDF_THANKS_DG	Thank you to attendee	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9934	2018-10-17 14:03:00	MOSTYNRS	2018-11-07 12:55:00	STEVENSG	2	57	\N	PDF_THANKS_VIP_D	Sends a pdf letter of thanks to special visitor.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9923	2018-08-13 12:24:00	MOSTYNRS	2018-08-13 12:24:00	MOSTYNRS	1	40	\N	ilNow_LBL	Current	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9924	2018-08-13 12:24:00	MOSTYNRS	2018-08-13 12:25:00	MOSTYNRS	1	40	\N	ilNow_TT	You are working on the selected line in this list.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9925	2018-08-13 12:25:00	MOSTYNRS	2018-08-13 12:25:00	MOSTYNRS	1	40	\N	ilPrevious_LBL	Parent	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9926	2018-08-13 12:25:00	MOSTYNRS	2018-08-13 12:25:00	MOSTYNRS	1	40	\N	ilPrevious_TT	These are the superior records in the company structure.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9931	2018-10-17 14:03:00	MOSTYNRS	2018-10-17 14:04:00	MOSTYNRS	1	57	\N	PDF_THANKS_SPK	Thank you to speaker	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9933	2018-10-17 14:03:00	MOSTYNRS	2018-10-17 14:05:00	MOSTYNRS	1	57	\N	PDF_THANKS_VIP	Thank you to special visitor	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9927	2018-09-10 15:28:00	MOSTYNRS	2018-09-10 15:29:00	MOSTYNRS	2	57	\N	NTFY_CHASE_INV	Payment reminder	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9932	2018-10-17 14:03:00	MOSTYNRS	2018-10-17 14:05:00	MOSTYNRS	1	57	\N	PDF_THANKS_SPK_D	Sends a pdf letter of thanks to speaker.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9928	2018-09-10 15:29:00	MOSTYNRS	2018-10-17 14:02:00	MOSTYNRS	3	57	\N	NTFY_CHASE_INV_D	Send email to pay invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9935	2018-10-22 13:41:00	STEVENSG	2018-10-22 13:41:00	STEVENSG	1	52	\N	FACT_IMP_SUPP	Import suppliers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9936	2018-10-22 13:41:00	STEVENSG	2018-10-22 13:42:00	STEVENSG	1	52	\N	FACT_IMP_SUPP_D	Import supplier information from text/xls file	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9937	2018-10-22 15:59:00	STEVENSG	2018-10-22 15:59:00	STEVENSG	1	52	\N	FACT_IMP_CUST	Import customers	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9938	2018-10-22 15:59:00	STEVENSG	2018-10-22 16:00:00	STEVENSG	1	52	\N	FACT_IMP_CUST_D	Import customer records from atext/xls file	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9939	2018-10-23 10:20:00	STEVENSG	2018-10-23 10:20:00	STEVENSG	1	3	\N	MSG_MISSINGCONAME	company name missing	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9940	2018-10-23 10:20:00	STEVENSG	2018-10-23 10:20:00	STEVENSG	1	3	\N	MSG_MISSINGFINACCTID	finacial accounting ID missing	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9943	2018-10-23 12:25:00	MOSTYNRS	2018-10-23 12:25:00	MOSTYNRS	1	19	\N	PY_VAT_LBL	included VAT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9944	2018-10-23 12:25:00	MOSTYNRS	2018-10-23 12:25:00	MOSTYNRS	1	19	\N	PY_VAT_TT	If the amount includes VAT, declare the VAT amount here.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Name: entgrouporganisations_seq; Type: SEQUENCE SET; Schema: infra; Owner: _developer
--

SELECT pg_catalog.setval('infra.entgrouporganisations_seq', 2, true);


--
-- Name: entgrouporgnames_seq; Type: SEQUENCE SET; Schema: infra; Owner: _developer
--

SELECT pg_catalog.setval('infra.entgrouporgnames_seq', 2, true);


--
-- Name: sysasyncemails_seq; Type: SEQUENCE SET; Schema: infra; Owner: _developer
--

SELECT pg_catalog.setval('infra.sysasyncemails_seq', 46, true);


--
-- Name: sysreferenceglobal_seq; Type: SEQUENCE SET; Schema: infra; Owner: _developer
--

SELECT pg_catalog.setval('infra.sysreferenceglobal_seq', 1, true);


--
-- Name: sysreferencelocal_seq; Type: SEQUENCE SET; Schema: infra; Owner: _developer
--

SELECT pg_catalog.setval('infra.sysreferencelocal_seq', 1, false);


--
-- Name: sysreferenceorg_seq; Type: SEQUENCE SET; Schema: infra; Owner: _developer
--

SELECT pg_catalog.setval('infra.sysreferenceorg_seq', 1, false);


--
-- Name: sysreferenceuser_seq; Type: SEQUENCE SET; Schema: infra; Owner: _developer
--

SELECT pg_catalog.setval('infra.sysreferenceuser_seq', 1, true);


--
-- Name: systaskstats_seq; Type: SEQUENCE SET; Schema: infra; Owner: _developer
--

SELECT pg_catalog.setval('infra.systaskstats_seq', 1, false);


--
-- Name: uagrouporglinks_seq; Type: SEQUENCE SET; Schema: infra; Owner: _developer
--

SELECT pg_catalog.setval('infra.uagrouporglinks_seq', 4, true);


--
-- Name: ualogaccess_seq; Type: SEQUENCE SET; Schema: infra; Owner: _developer
--

SELECT pg_catalog.setval('infra.ualogaccess_seq', 1, false);


--
-- Name: uausers_seq; Type: SEQUENCE SET; Schema: infra; Owner: _developer
--

SELECT pg_catalog.setval('infra.uausers_seq', 3, true);


--
-- Name: omgroup_seq; Type: SEQUENCE SET; Schema: translate; Owner: _developer
--

SELECT pg_catalog.setval('translate.omgroup_seq', 57, true);


--
-- Name: omlibgrouplinks_seq; Type: SEQUENCE SET; Schema: translate; Owner: _developer
--

SELECT pg_catalog.setval('translate.omlibgrouplinks_seq', 140, true);


--
-- Name: omlibrary_seq; Type: SEQUENCE SET; Schema: translate; Owner: _developer
--

SELECT pg_catalog.setval('translate.omlibrary_seq', 18, true);


--
-- Name: omstrings_seq; Type: SEQUENCE SET; Schema: translate; Owner: _developer
--

SELECT pg_catalog.setval('translate.omstrings_seq', 9955, true);


--
-- Name: entgrouporganisations entgrouporganisations_pkey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.entgrouporganisations
    ADD CONSTRAINT entgrouporganisations_pkey PRIMARY KEY (go_seq);


--
-- Name: entgrouporgnames entgrouporgnames_pkey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.entgrouporgnames
    ADD CONSTRAINT entgrouporgnames_pkey PRIMARY KEY (gon_seq);


--
-- Name: entgrouporganisations go_mec_ukey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.entgrouporganisations
    ADD CONSTRAINT go_mec_ukey UNIQUE (go_mec_id);


--
-- Name: entgrouporganisations go_name_short_ukey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.entgrouporganisations
    ADD CONSTRAINT go_name_short_ukey UNIQUE (go_name_short);


--
-- Name: entgrouporgnames gon_name_full_uk; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.entgrouporgnames
    ADD CONSTRAINT gon_name_full_uk UNIQUE (gon_name_full);


--
-- Name: entgrouporgnames gon_ukey2; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.entgrouporgnames
    ADD CONSTRAINT gon_ukey2 UNIQUE (gon_type, gon_name_full);


--
-- Name: sysreferenceglobal rfg_ukey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysreferenceglobal
    ADD CONSTRAINT rfg_ukey UNIQUE (rfg_class, rfg_value);


--
-- Name: sysreferencelocal rfl_ukey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysreferencelocal
    ADD CONSTRAINT rfl_ukey UNIQUE (rfl_class, rfl_value);


--
-- Name: sysreferenceorg rfo_ukey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysreferenceorg
    ADD CONSTRAINT rfo_ukey UNIQUE (rfo_go_ref, rfo_class, rfo_value);


--
-- Name: sysreferenceuser rfu_ukey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysreferenceuser
    ADD CONSTRAINT rfu_ukey UNIQUE (rfu_go_ref, rfu_usr_ref, rfu_class, rfu_value);


--
-- Name: sysasyncemails sysasyncemails_pkey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysasyncemails
    ADD CONSTRAINT sysasyncemails_pkey PRIMARY KEY (ae_seq);


--
-- Name: sysreferenceglobal sysreferenceglobal_pkey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysreferenceglobal
    ADD CONSTRAINT sysreferenceglobal_pkey PRIMARY KEY (rfg_seq);


--
-- Name: sysreferencelocal sysreferencelocal_pkey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysreferencelocal
    ADD CONSTRAINT sysreferencelocal_pkey PRIMARY KEY (rfl_seq);


--
-- Name: sysreferenceorg sysreferenceorg_pkey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysreferenceorg
    ADD CONSTRAINT sysreferenceorg_pkey PRIMARY KEY (rfo_seq);


--
-- Name: sysreferenceuser sysreferenceuser_pkey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysreferenceuser
    ADD CONSTRAINT sysreferenceuser_pkey PRIMARY KEY (rfu_seq);


--
-- Name: systaskstats systaskstats_pkey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.systaskstats
    ADD CONSTRAINT systaskstats_pkey PRIMARY KEY (sts_seq);


--
-- Name: uagrouporglinks uagrouporglinks_pkey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.uagrouporglinks
    ADD CONSTRAINT uagrouporglinks_pkey PRIMARY KEY (ugo_seq);


--
-- Name: uagrouporglinks ugo_ukey; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.uagrouporglinks
    ADD CONSTRAINT ugo_ukey UNIQUE (ugo_go_ref, ugo_usr_ref);


--
-- Name: ualogaccess ula_seq; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.ualogaccess
    ADD CONSTRAINT ula_seq PRIMARY KEY (ula_seq);


--
-- Name: uausers usr_seq; Type: CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.uausers
    ADD CONSTRAINT usr_seq PRIMARY KEY (usr_seq);


--
-- Name: omgroup omgroup_pkey; Type: CONSTRAINT; Schema: translate; Owner: _developer
--

ALTER TABLE ONLY translate.omgroup
    ADD CONSTRAINT omgroup_pkey PRIMARY KEY (omg_seq);


--
-- Name: omlibgrouplinks omlibgrouplinks_pkey; Type: CONSTRAINT; Schema: translate; Owner: _developer
--

ALTER TABLE ONLY translate.omlibgrouplinks
    ADD CONSTRAINT omlibgrouplinks_pkey PRIMARY KEY (olg_seq);


--
-- Name: omlibrary omlibrary_pkey; Type: CONSTRAINT; Schema: translate; Owner: _developer
--

ALTER TABLE ONLY translate.omlibrary
    ADD CONSTRAINT omlibrary_pkey PRIMARY KEY (oml_seq);


--
-- Name: omstrings omstrings_pkey; Type: CONSTRAINT; Schema: translate; Owner: _developer
--

ALTER TABLE ONLY translate.omstrings
    ADD CONSTRAINT omstrings_pkey PRIMARY KEY (oms_seq);


--
-- Name: omstrings omstrings_stringid_key; Type: CONSTRAINT; Schema: translate; Owner: _developer
--

ALTER TABLE ONLY translate.omstrings
    ADD CONSTRAINT omstrings_stringid_key UNIQUE (stringid);


--
-- Name: oml_omg_uk; Type: INDEX; Schema: translate; Owner: _developer
--

CREATE UNIQUE INDEX oml_omg_uk ON translate.omlibgrouplinks USING btree (olg_oml_ref, olg_omg_ref);


--
-- Name: sysasyncemails ae_go_ref; Type: FK CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysasyncemails
    ADD CONSTRAINT ae_go_ref FOREIGN KEY (ae_go_ref) REFERENCES infra.entgrouporganisations(go_seq);


--
-- Name: entgrouporganisations go_report_to_go_ref; Type: FK CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.entgrouporganisations
    ADD CONSTRAINT go_report_to_go_ref FOREIGN KEY (go_report_to_go_ref) REFERENCES infra.entgrouporganisations(go_seq);


--
-- Name: entgrouporgnames gon_go_ref; Type: FK CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.entgrouporgnames
    ADD CONSTRAINT gon_go_ref FOREIGN KEY (gon_go_ref) REFERENCES infra.entgrouporganisations(go_seq);


--
-- Name: sysreferenceorg rfo_go_ref; Type: FK CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysreferenceorg
    ADD CONSTRAINT rfo_go_ref FOREIGN KEY (rfo_go_ref) REFERENCES infra.entgrouporganisations(go_seq);


--
-- Name: sysreferenceuser rfu_go_ref; Type: FK CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysreferenceuser
    ADD CONSTRAINT rfu_go_ref FOREIGN KEY (rfu_go_ref) REFERENCES infra.entgrouporganisations(go_seq);


--
-- Name: sysreferenceuser rfu_usr_ref; Type: FK CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.sysreferenceuser
    ADD CONSTRAINT rfu_usr_ref FOREIGN KEY (rfu_usr_ref) REFERENCES infra.uausers(usr_seq);


--
-- Name: systaskstats sts_go_ref; Type: FK CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.systaskstats
    ADD CONSTRAINT sts_go_ref FOREIGN KEY (sts_go_ref) REFERENCES infra.entgrouporganisations(go_seq);


--
-- Name: systaskstats sts_ula_ref; Type: FK CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.systaskstats
    ADD CONSTRAINT sts_ula_ref FOREIGN KEY (sts_ula_ref) REFERENCES infra.ualogaccess(ula_seq);


--
-- Name: uagrouporglinks ugo_go_ref; Type: FK CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.uagrouporglinks
    ADD CONSTRAINT ugo_go_ref FOREIGN KEY (ugo_go_ref) REFERENCES infra.entgrouporganisations(go_seq);


--
-- Name: uagrouporglinks ugo_usr_ref; Type: FK CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.uagrouporglinks
    ADD CONSTRAINT ugo_usr_ref FOREIGN KEY (ugo_usr_ref) REFERENCES infra.uausers(usr_seq);


--
-- Name: ualogaccess ula_usr_ref; Type: FK CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.ualogaccess
    ADD CONSTRAINT ula_usr_ref FOREIGN KEY (ula_usr_ref) REFERENCES infra.uausers(usr_seq);


--
-- Name: uausers usr_usr_ref; Type: FK CONSTRAINT; Schema: infra; Owner: _developer
--

ALTER TABLE ONLY infra.uausers
    ADD CONSTRAINT usr_usr_ref FOREIGN KEY (usr_usr_ref) REFERENCES infra.uausers(usr_seq);


--
-- Name: omlibgrouplinks olg_omg_ref; Type: FK CONSTRAINT; Schema: translate; Owner: _developer
--

ALTER TABLE ONLY translate.omlibgrouplinks
    ADD CONSTRAINT olg_omg_ref FOREIGN KEY (olg_omg_ref) REFERENCES translate.omgroup(omg_seq);


--
-- Name: omlibgrouplinks olg_oml_ref; Type: FK CONSTRAINT; Schema: translate; Owner: _developer
--

ALTER TABLE ONLY translate.omlibgrouplinks
    ADD CONSTRAINT olg_oml_ref FOREIGN KEY (olg_oml_ref) REFERENCES translate.omlibrary(oml_seq) ON DELETE CASCADE;


--
-- Name: omstrings oms_omg_ref; Type: FK CONSTRAINT; Schema: translate; Owner: _developer
--

ALTER TABLE ONLY translate.omstrings
    ADD CONSTRAINT oms_omg_ref FOREIGN KEY (oms_omg_ref) REFERENCES translate.omgroup(omg_seq) ON DELETE CASCADE;


--
-- Name: SCHEMA infra; Type: ACL; Schema: -; Owner: _developer
--

GRANT USAGE ON SCHEMA infra TO regular;


--
-- Name: SCHEMA translate; Type: ACL; Schema: -; Owner: _developer
--

GRANT USAGE ON SCHEMA translate TO regular;


--
-- Name: SEQUENCE sysreferenceorg_seq; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE infra.sysreferenceorg_seq TO regular;


--
-- Name: TABLE sysreferenceorg; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE infra.sysreferenceorg TO regular;


--
-- Name: FUNCTION initinherited(pclass text, pvalue text, pgoref integer); Type: ACL; Schema: infra; Owner: _developer
--

REVOKE ALL ON FUNCTION infra.initinherited(pclass text, pvalue text, pgoref integer) FROM PUBLIC;
GRANT ALL ON FUNCTION infra.initinherited(pclass text, pvalue text, pgoref integer) TO regular;


--
-- Name: SEQUENCE entgrouporganisations_seq; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE infra.entgrouporganisations_seq TO regular;


--
-- Name: TABLE entgrouporganisations; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE infra.entgrouporganisations TO regular;


--
-- Name: SEQUENCE entgrouporgnames_seq; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE infra.entgrouporgnames_seq TO regular;


--
-- Name: TABLE entgrouporgnames; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE infra.entgrouporgnames TO regular;


--
-- Name: SEQUENCE sysasyncemails_seq; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE infra.sysasyncemails_seq TO regular;


--
-- Name: TABLE sysasyncemails; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE infra.sysasyncemails TO regular;


--
-- Name: TABLE syslogerrors; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE infra.syslogerrors TO regular;


--
-- Name: TABLE syslogevents; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE infra.syslogevents TO regular;


--
-- Name: SEQUENCE sysreferenceglobal_seq; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE infra.sysreferenceglobal_seq TO regular;


--
-- Name: TABLE sysreferenceglobal; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE infra.sysreferenceglobal TO regular;


--
-- Name: SEQUENCE sysreferencelocal_seq; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE infra.sysreferencelocal_seq TO regular;


--
-- Name: TABLE sysreferencelocal; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE infra.sysreferencelocal TO regular;


--
-- Name: SEQUENCE sysreferenceuser_seq; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE infra.sysreferenceuser_seq TO regular;


--
-- Name: TABLE sysreferenceuser; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE infra.sysreferenceuser TO regular;


--
-- Name: SEQUENCE systaskstats_seq; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE infra.systaskstats_seq TO regular;


--
-- Name: TABLE systaskstats; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,UPDATE ON TABLE infra.systaskstats TO regular;


--
-- Name: SEQUENCE uagrouporglinks_seq; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE infra.uagrouporglinks_seq TO regular;


--
-- Name: TABLE uagrouporglinks; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE infra.uagrouporglinks TO regular;


--
-- Name: SEQUENCE ualogaccess_seq; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE infra.ualogaccess_seq TO regular;


--
-- Name: TABLE ualogaccess; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE infra.ualogaccess TO regular;


--
-- Name: SEQUENCE uausers_seq; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE infra.uausers_seq TO regular;


--
-- Name: TABLE uausers; Type: ACL; Schema: infra; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE infra.uausers TO regular;


--
-- Name: SEQUENCE omgroup_seq; Type: ACL; Schema: translate; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE translate.omgroup_seq TO regular;


--
-- Name: TABLE omgroup; Type: ACL; Schema: translate; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE translate.omgroup TO regular;


--
-- Name: SEQUENCE omlibgrouplinks_seq; Type: ACL; Schema: translate; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE translate.omlibgrouplinks_seq TO regular;


--
-- Name: TABLE omlibgrouplinks; Type: ACL; Schema: translate; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE translate.omlibgrouplinks TO regular;


--
-- Name: SEQUENCE omlibrary_seq; Type: ACL; Schema: translate; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE translate.omlibrary_seq TO regular;


--
-- Name: TABLE omlibrary; Type: ACL; Schema: translate; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE translate.omlibrary TO regular;


--
-- Name: SEQUENCE omstrings_seq; Type: ACL; Schema: translate; Owner: _developer
--

GRANT SELECT,UPDATE ON SEQUENCE translate.omstrings_seq TO regular;


--
-- Name: TABLE omstrings; Type: ACL; Schema: translate; Owner: _developer
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE translate.omstrings TO regular;


--
-- PostgreSQL database dump complete
--

