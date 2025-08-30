
SET default_tablespace = '';

SET default_with_oids = false;

CREATE TABLE public.pacs_album_access_items (
    id uuid NOT NULL,
    item_id uuid NOT NULL,
    album_id uuid,
    smart_album_id uuid,
    permission integer NOT NULL
);


ALTER TABLE public.pacs_album_access_items OWNER TO dgc;

--
-- TOC entry 207 (class 1259 OID 141271)
-- Name: pacs_albums; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_albums (
    id uuid NOT NULL,
    partition_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    comment text,
    status integer NOT NULL
);


ALTER TABLE public.pacs_albums OWNER TO dgc;

--
-- TOC entry 240 (class 1259 OID 174058)
-- Name: pacs_compressions; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_compressions (
    id uuid NOT NULL,
    partition_id uuid NOT NULL,
    active integer NOT NULL,
    mode integer NOT NULL,
    start integer,
    stop integer,
    transfer character varying(64) NOT NULL,
    updatecnt integer NOT NULL
);


ALTER TABLE public.pacs_compressions OWNER TO dgc;

--
-- TOC entry 227 (class 1259 OID 141601)
-- Name: pacs_dicom_access; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_dicom_access (
    id uuid NOT NULL,
    user_id uuid,
    role_id uuid,
    active integer NOT NULL,
    inherit integer NOT NULL,
    mode integer NOT NULL
);


ALTER TABLE public.pacs_dicom_access OWNER TO dgc;

--
-- TOC entry 228 (class 1259 OID 141618)
-- Name: pacs_dicom_access_items; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_dicom_access_items (
    id uuid NOT NULL,
    access_id uuid NOT NULL,
    client_id uuid NOT NULL,
    permission integer NOT NULL
);


ALTER TABLE public.pacs_dicom_access_items OWNER TO dgc;

--
-- TOC entry 225 (class 1259 OID 141553)
-- Name: pacs_dicom_aes; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_dicom_aes (
    id uuid NOT NULL,
    site_id uuid NOT NULL,
    status integer NOT NULL,
    ae character varying(255) NOT NULL,
    comment character varying(255),
    type integer NOT NULL
);


ALTER TABLE public.pacs_dicom_aes OWNER TO dgc;

--
-- TOC entry 226 (class 1259 OID 141567)
-- Name: pacs_dicom_clients; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_dicom_clients (
    id uuid NOT NULL,
    ae_id uuid NOT NULL,
    status integer NOT NULL,
    ae character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    ip character varying(255) NOT NULL,
    port integer NOT NULL,
    rights integer NOT NULL,
    type integer NOT NULL,
    target_type integer NOT NULL,
    target_partition uuid,
    target_album uuid,
    target_smart_album uuid,
    target_dicom uuid,
    target_name character varying(255),
    target_id uuid,
    comment character varying(255),
    code_page character varying(255)
);


ALTER TABLE public.pacs_dicom_clients OWNER TO dgc;

--
-- TOC entry 221 (class 1259 OID 141485)
-- Name: pacs_download_images; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_download_images (
    id uuid NOT NULL,
    series_id uuid NOT NULL,
    num integer NOT NULL,
    path text NOT NULL,
    type integer NOT NULL,
    rescnt integer NOT NULL,
    result integer NOT NULL
);


ALTER TABLE public.pacs_download_images OWNER TO dgc;

--
-- TOC entry 220 (class 1259 OID 141480)
-- Name: pacs_download_series; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_download_series (
    id uuid NOT NULL,
    series_id uuid NOT NULL,
    date timestamp(0) without time zone NOT NULL,
    completed integer NOT NULL,
    result integer NOT NULL,
    expected integer NOT NULL,
    session_id character varying(256)
);


ALTER TABLE public.pacs_download_series OWNER TO dgc;

--
-- TOC entry 233 (class 1259 OID 141698)
-- Name: pacs_image_links; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_image_links (
    id uuid NOT NULL,
    series_link_id uuid NOT NULL,
    image_id uuid NOT NULL
);


ALTER TABLE public.pacs_image_links OWNER TO dgc;

--
-- TOC entry 212 (class 1259 OID 141349)
-- Name: pacs_images; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_images (
    id uuid NOT NULL,
    series_id uuid NOT NULL,
    uid character varying(255) NOT NULL,
    charset character varying(255),
    instnum integer,
    sopclass character varying(255),
    acqnum integer,
    imgmedia integer NOT NULL,
    imgpath text,
    streammedia integer NOT NULL,
    streampath text,
    iconmedia integer NOT NULL,
    iconpath text,
    width integer,
    height integer,
    depth double precision,
    cstatus integer,
    cupd integer,
    status uuid NOT NULL,
    crdate timestamp(0) without time zone NOT NULL,
    oid character varying(255),
    oname character varying(255),
    oip character varying(255)
);


ALTER TABLE public.pacs_images OWNER TO dgc;

--
-- TOC entry 200 (class 1259 OID 141174)
-- Name: pacs_media; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_media (
    id uuid NOT NULL,
    site_id uuid,
    volume_id uuid,
    type integer NOT NULL,
    num integer NOT NULL,
    path text NOT NULL,
    maxfill real NOT NULL,
    status integer NOT NULL
);


ALTER TABLE public.pacs_media OWNER TO dgc;

--
-- TOC entry 197 (class 1259 OID 141145)
-- Name: pacs_organizations; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_organizations (
    id uuid NOT NULL,
    name character varying(255)
);


ALTER TABLE public.pacs_organizations OWNER TO dgc;

--
-- TOC entry 222 (class 1259 OID 141498)
-- Name: pacs_partition_access; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_partition_access (
    id uuid NOT NULL,
    user_id uuid,
    role_id uuid,
    active integer NOT NULL,
    inherit integer NOT NULL,
    mode integer NOT NULL
);


ALTER TABLE public.pacs_partition_access OWNER TO dgc;

--
-- TOC entry 223 (class 1259 OID 141515)
-- Name: pacs_partition_access_items; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_partition_access_items (
    id uuid NOT NULL,
    access_id uuid NOT NULL,
    partition_id uuid NOT NULL,
    mode integer NOT NULL,
    permission integer NOT NULL
);


ALTER TABLE public.pacs_partition_access_items OWNER TO dgc;

--
-- TOC entry 219 (class 1259 OID 141465)
-- Name: pacs_partition_limits; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_partition_limits (
    id uuid NOT NULL,
    user_id uuid,
    partition_id uuid NOT NULL
);


ALTER TABLE public.pacs_partition_limits OWNER TO dgc;

--
-- TOC entry 206 (class 1259 OID 141253)
-- Name: pacs_partitions; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_partitions (
    id uuid NOT NULL,
    site_id uuid NOT NULL,
    volume_id uuid,
    name character varying(255) NOT NULL,
    comment text,
    status integer NOT NULL,
    parameters text NOT NULL,
    conflict integer NOT NULL
);


ALTER TABLE public.pacs_partitions OWNER TO dgc;

--
-- TOC entry 230 (class 1259 OID 141647)
-- Name: pacs_patient_links; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_patient_links (
    id uuid NOT NULL,
    album_id uuid NOT NULL,
    patient_id uuid NOT NULL,
    all_studies integer NOT NULL,
    stcnt integer NOT NULL,
    srcnt integer NOT NULL,
    imcnt integer NOT NULL
);


ALTER TABLE public.pacs_patient_links OWNER TO dgc;

--
-- TOC entry 209 (class 1259 OID 141297)
-- Name: pacs_patients; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_patients (
    id uuid NOT NULL,
    partition_id uuid NOT NULL,
    pid character varying(255),
    name character varying(255),
    ideogram character varying(255),
    phonetic character varying(255),
    charset character varying(255),
    birthdate character varying(255),
    birthtime character varying(255),
    sex character varying(255),
    stcnt integer NOT NULL,
    srcnt integer NOT NULL,
    imcnt integer NOT NULL,
    status uuid NOT NULL,
    crdate timestamp(0) without time zone NOT NULL,
    oid character varying(255),
    oname character varying(255),
    oip character varying(255)
);


ALTER TABLE public.pacs_patients OWNER TO dgc;

--
-- TOC entry 229 (class 1259 OID 141634)
-- Name: pacs_preference_items; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_preference_items (
    id uuid NOT NULL,
    set_id uuid NOT NULL,
    ptype character varying(255) NOT NULL,
    pversion character varying(255) NOT NULL,
    status integer NOT NULL,
    name character varying(255) NOT NULL,
    comment character varying(255),
    shortcut bigint,
    param text NOT NULL
);


ALTER TABLE public.pacs_preference_items OWNER TO dgc;

--
-- TOC entry 213 (class 1259 OID 141363)
-- Name: pacs_preference_sets; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_preference_sets (
    id uuid NOT NULL,
    site_id uuid,
    name character varying(255) NOT NULL,
    comment character varying(255),
    status integer NOT NULL,
    for_user integer NOT NULL
);


ALTER TABLE public.pacs_preference_sets OWNER TO dgc;

--
-- TOC entry 234 (class 1259 OID 165715)
-- Name: pacs_report_templates; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_report_templates (
    id uuid NOT NULL,
    site_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    status integer NOT NULL,
    filters text,
    version character varying(255) NOT NULL,
    media integer NOT NULL
);


ALTER TABLE public.pacs_report_templates OWNER TO dgc;

--
-- TOC entry 235 (class 1259 OID 165729)
-- Name: pacs_reports; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_reports (
    id uuid NOT NULL,
    study_id uuid NOT NULL,
    template_id uuid NOT NULL,
    uid uuid NOT NULL,
    readdoc character varying(255),
    readinst character varying(255),
    verifdoc character varying(255),
    verifinst character varying(255),
    createdate character varying(19) NOT NULL,
    modifdate character varying(19),
    verifdate character varying(19),
    media integer,
    path text,
    importdate character varying(19) NOT NULL,
    status integer NOT NULL,
    updatecnt integer NOT NULL
);


ALTER TABLE public.pacs_reports OWNER TO dgc;

--
-- TOC entry 217 (class 1259 OID 141422)
-- Name: pacs_role_has_role_items; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_role_has_role_items (
    id uuid NOT NULL,
    role_id uuid,
    user_id uuid,
    item_id uuid NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.pacs_role_has_role_items OWNER TO dgc;

--
-- TOC entry 215 (class 1259 OID 141399)
-- Name: pacs_role_items; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_role_items (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    type integer NOT NULL
);


ALTER TABLE public.pacs_role_items OWNER TO dgc;

--
-- TOC entry 218 (class 1259 OID 141443)
-- Name: pacs_role_membership; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_role_membership (
    id uuid NOT NULL,
    role_id uuid,
    user_id uuid,
    parent_id uuid NOT NULL
);


ALTER TABLE public.pacs_role_membership OWNER TO dgc;

--
-- TOC entry 216 (class 1259 OID 141404)
-- Name: pacs_roles; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_roles (
    id uuid NOT NULL,
    site_id uuid NOT NULL,
    name character varying(255),
    active integer NOT NULL,
    inherit integer NOT NULL,
    description text,
    inherit_pref integer NOT NULL,
    pref_id uuid
);


ALTER TABLE public.pacs_roles OWNER TO dgc;

--
-- TOC entry 237 (class 1259 OID 174012)
-- Name: pacs_routing_locations; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_routing_locations (
    id uuid NOT NULL,
    site_id uuid NOT NULL,
    name character varying(64) NOT NULL,
    type integer NOT NULL,
    url character varying(255) NOT NULL,
    login character varying(64) NOT NULL,
    password character varying(255) NOT NULL,
    organization character varying(64),
    siteid character varying(64),
    sitename character varying(64)
);


ALTER TABLE public.pacs_routing_locations OWNER TO dgc;

--
-- TOC entry 239 (class 1259 OID 174035)
-- Name: pacs_routing_rules; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_routing_rules (
    id uuid NOT NULL,
    routing_id uuid NOT NULL,
    active integer NOT NULL,
    name character varying(64) NOT NULL,
    type integer NOT NULL,
    from_id character varying(64) NOT NULL,
    from_name character varying(64),
    dest_id character varying(64) NOT NULL,
    dest_name character varying(64),
    filters text,
    from_loc uuid,
    dest_loc uuid,
    from_type integer,
    dest_type integer
);


ALTER TABLE public.pacs_routing_rules OWNER TO dgc;

--
-- TOC entry 238 (class 1259 OID 174025)
-- Name: pacs_routings; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_routings (
    id uuid NOT NULL,
    partition_id uuid NOT NULL,
    active integer NOT NULL,
    cretry integer NOT NULL,
    cgiveup integer NOT NULL,
    fretry integer NOT NULL,
    fgiveup integer NOT NULL,
    updatecnt integer NOT NULL
);

ALTER TABLE public.pacs_routings OWNER TO dgc;

CREATE TABLE public.pacs_auto_routing (
    id uuid NOT NULL,
    site_id uuid NOT NULL,
    partition_id uuid NOT NULL,
    image_id uuid NOT NULL,
    series_id uuid NOT NULL,
    loc_id uuid,
    dest_id uuid NOT NULL,
    dest_type integer NOT NULL,
    status integer NOT NULL,
    firsttry integer,
    nexttry integer,
    crdate timestamp(0) without time zone NOT NULL
);

ALTER TABLE public.pacs_auto_routing OWNER TO dgc;




--
-- TOC entry 211 (class 1259 OID 141335)
-- Name: pacs_series; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_series (
    id uuid NOT NULL,
    study_id uuid NOT NULL,
    uid character varying(255) NOT NULL,
    charset character varying(255),
    seriesdate character varying(255),
    seriestime character varying(255),
    modality character varying(255),
    bodypart text,
    srnum character varying(255),
    description character varying(255),
    comment text,
    station text,
    iconmedia integer,
    iconpath text,
    propmedia integer,
    proppath text,
    imcnt integer NOT NULL,
    status uuid NOT NULL,
    crdate timestamp(0) without time zone NOT NULL,
    oid character varying(255),
    oname character varying(255),
    oip character varying(255)
);


ALTER TABLE public.pacs_series OWNER TO dgc;

--
-- TOC entry 232 (class 1259 OID 141682)
-- Name: pacs_series_links; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_series_links (
    id uuid NOT NULL,
    study_link_id uuid NOT NULL,
    series_id uuid NOT NULL,
    all_images integer NOT NULL,
    imcnt integer NOT NULL
);


ALTER TABLE public.pacs_series_links OWNER TO dgc;

--
-- TOC entry 198 (class 1259 OID 141150)
-- Name: pacs_sites; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_sites (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    name character varying(255)
);


ALTER TABLE public.pacs_sites OWNER TO dgc;

--
-- TOC entry 208 (class 1259 OID 141284)
-- Name: pacs_smart_albums; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_smart_albums (
    id uuid NOT NULL,
    partition_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    comment text,
    status integer NOT NULL,
    criteria text NOT NULL
);


ALTER TABLE public.pacs_smart_albums OWNER TO dgc;

--
-- TOC entry 210 (class 1259 OID 141311)
-- Name: pacs_studies; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_studies (
    id uuid NOT NULL,
    partition_id uuid NOT NULL,
    patient_id uuid NOT NULL,
    uid character varying(255) NOT NULL,
    charset character varying(255),
    studydate character varying(255),
    studytime character varying(255),
    modalities character varying(255),
    bodyparts text,
    accnum character varying(255),
    studyid character varying(255),
    description character varying(255),
    age character varying(255),
    institution character varying(255),
    comment text,
    stations text,
    srcnt integer NOT NULL,
    imcnt integer NOT NULL,
    rptcnt integer NOT NULL,
    status uuid NOT NULL,
    conflict_id uuid,
    crdate timestamp(0) without time zone NOT NULL,
    oid character varying(255),
    oname character varying(255),
    oip character varying(255)
);


ALTER TABLE public.pacs_studies OWNER TO dgc;

--
-- TOC entry 231 (class 1259 OID 141663)
-- Name: pacs_study_links; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_study_links (
    id uuid NOT NULL,
    patient_link_id uuid NOT NULL,
    study_id uuid NOT NULL,
    all_series integer NOT NULL,
    modalities character varying(255),
    bodyparts text,
    stations text,
    srcnt integer NOT NULL,
    imcnt integer NOT NULL,
    rptcnt integer NOT NULL
);


ALTER TABLE public.pacs_study_links OWNER TO dgc;

--
-- TOC entry 214 (class 1259 OID 141376)
-- Name: pacs_users; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_users (
    id uuid NOT NULL,
    site_id uuid NOT NULL,
    login character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    active integer NOT NULL,
    login_attempt integer NOT NULL,
    inherit integer NOT NULL,
    superuser integer NOT NULL,
    inherit_pref integer NOT NULL,
    shared_pref_id uuid,
    pref_id uuid,
    family_name character varying(255),
    first_name character varying(255),
    prefix character varying(255),
    suffix character varying(255),
    organization character varying(255),
    address1 character varying(255),
    address2 character varying(255),
    city character varying(255),
    zip character varying(255),
    country character varying(255),
    email character varying(255),
    fax character varying(255),
    phone character varying(255)
);


ALTER TABLE public.pacs_users OWNER TO dgc;

--
-- TOC entry 199 (class 1259 OID 141160)
-- Name: pacs_volumes; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.pacs_volumes (
    id uuid NOT NULL,
    site_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text
);


ALTER TABLE public.pacs_volumes OWNER TO dgc;

--
-- TOC entry 236 (class 1259 OID 173907)
-- Name: preference_items; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.preference_items (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    ptype character varying(255) NOT NULL,
    pversion character varying(255) NOT NULL,
    status integer NOT NULL,
    name character varying(255) NOT NULL,
    comment character varying(255),
    shortcut bigint,
    param text NOT NULL
);


ALTER TABLE public.preference_items OWNER TO dgc;





CREATE TABLE public.pacs_history
(
    id uuid NOT NULL,
    date timestamp without time zone NOT NULL,
    type integer NOT NULL,
    ip character varying(64),
    origin_type integer NOT NULL,
    origin_id uuid NOT NULL,
    origin_name character varying(64) NOT NULL,
    sub_origin_id uuid,
    sub_origin_name character varying(64),
    from_site_id uuid NOT NULL,
    from_type integer,
    from_id uuid,
    from_name character varying(64),
    sub_from_id uuid,
    sub_from_name character varying(64),
    to_site_id uuid,
    to_site_name character varying(64),
    to_type integer,
    to_id uuid,
    to_name character varying(64),
    sub_to_id uuid,
    sub_to_name character varying(64),
    pseq uuid,
    pid character varying(64),
    stseq uuid,
    stuid character varying(64),
    srseq uuid,
    sruid character varying(64),
    imseq uuid,
    imuid character varying(64),
    session character varying(256),
    param text NOT NULL
);


ALTER TABLE public.pacs_history OWNER to dgc;



--
-- TOC entry 196 (class 1259 OID 141140)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: dgc
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


ALTER TABLE public.schema_migrations OWNER TO dgc;



ALTER TABLE ONLY public.pacs_history
    ADD CONSTRAINT pacs_history_pkey PRIMARY KEY (id);

CREATE INDEX pacs_history_origin_name_index ON public.pacs_history USING btree (origin_name);
CREATE INDEX pacs_history_origin_id_index ON public.pacs_history USING btree (origin_id);
CREATE INDEX pacs_history_sub_origin_name_index ON public.pacs_history USING btree (sub_origin_name);
CREATE INDEX pacs_history_sub_origin_id_index ON public.pacs_history USING btree (sub_origin_id);
CREATE INDEX pacs_history_from_site_id_index ON public.pacs_history USING btree (from_site_id);

--
-- TOC entry 3524 (class 0 OID 141531)
-- Dependencies: 224
-- Data for Name: pacs_album_access_items; Type: TABLE DATA; Schema: public; Owner: dgc
--

--
-- TOC entry 3260 (class 2606 OID 141535)
-- Name: pacs_album_access_items pacs_album_access_items_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_album_access_items
    ADD CONSTRAINT pacs_album_access_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3214 (class 2606 OID 141278)
-- Name: pacs_albums pacs_albums_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_albums
    ADD CONSTRAINT pacs_albums_pkey PRIMARY KEY (id);

CREATE INDEX pacs_albums_partition_id_index ON public.pacs_albums USING btree (partition_id);


--
-- TOC entry 3305 (class 2606 OID 174062)
-- Name: pacs_compressions pacs_compressions_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_compressions
    ADD CONSTRAINT pacs_compressions_pkey PRIMARY KEY (id);


--
-- TOC entry 3273 (class 2606 OID 141622)
-- Name: pacs_dicom_access_items pacs_dicom_access_items_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_access_items
    ADD CONSTRAINT pacs_dicom_access_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3268 (class 2606 OID 141605)
-- Name: pacs_dicom_access pacs_dicom_access_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_access
    ADD CONSTRAINT pacs_dicom_access_pkey PRIMARY KEY (id);


--
-- TOC entry 3262 (class 2606 OID 141560)
-- Name: pacs_dicom_aes pacs_dicom_aes_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_aes
    ADD CONSTRAINT pacs_dicom_aes_pkey PRIMARY KEY (id);


--
-- TOC entry 3266 (class 2606 OID 141574)
-- Name: pacs_dicom_clients pacs_dicom_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_clients
    ADD CONSTRAINT pacs_dicom_clients_pkey PRIMARY KEY (id);


--
-- TOC entry 3249 (class 2606 OID 141492)
-- Name: pacs_download_images pacs_download_images_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_download_images
    ADD CONSTRAINT pacs_download_images_pkey PRIMARY KEY (id);


--
-- TOC entry 3247 (class 2606 OID 141484)
-- Name: pacs_download_series pacs_download_series_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_download_series
    ADD CONSTRAINT pacs_download_series_pkey PRIMARY KEY (id);

CREATE INDEX pacs_download_series_date_index ON public.pacs_download_series USING btree (date);

--
-- TOC entry 3286 (class 2606 OID 141702)
-- Name: pacs_image_links pacs_image_links_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_image_links
    ADD CONSTRAINT pacs_image_links_pkey PRIMARY KEY (id);


--
-- TOC entry 3227 (class 2606 OID 141356)
-- Name: pacs_images pacs_images_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_images
    ADD CONSTRAINT pacs_images_pkey PRIMARY KEY (id);


--
-- TOC entry 3198 (class 2606 OID 141181)
-- Name: pacs_media pacs_media_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_media
    ADD CONSTRAINT pacs_media_pkey PRIMARY KEY (id);


--
-- TOC entry 3191 (class 2606 OID 141149)
-- Name: pacs_organizations pacs_organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_organizations
    ADD CONSTRAINT pacs_organizations_pkey PRIMARY KEY (id);

CREATE INDEX pacs_organizations_name_index ON public.pacs_organizations USING btree (name);

--
-- TOC entry 3256 (class 2606 OID 141519)
-- Name: pacs_partition_access_items pacs_partition_access_items_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_partition_access_items
    ADD CONSTRAINT pacs_partition_access_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3251 (class 2606 OID 141502)
-- Name: pacs_partition_access pacs_partition_access_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_partition_access
    ADD CONSTRAINT pacs_partition_access_pkey PRIMARY KEY (id);


--
-- TOC entry 3245 (class 2606 OID 141469)
-- Name: pacs_partition_limits pacs_partition_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_partition_limits
    ADD CONSTRAINT pacs_partition_limits_pkey PRIMARY KEY (id);


--
-- TOC entry 3212 (class 2606 OID 141260)
-- Name: pacs_partitions pacs_partitions_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_partitions
    ADD CONSTRAINT pacs_partitions_pkey PRIMARY KEY (id);

CREATE INDEX pacs_partitions_site_id_index ON public.pacs_partitions USING btree (site_id);
CREATE INDEX pacs_partitions_volume_id_index ON public.pacs_partitions USING btree (volume_id);

--
-- TOC entry 3278 (class 2606 OID 141651)
-- Name: pacs_patient_links pacs_patient_links_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_patient_links
    ADD CONSTRAINT pacs_patient_links_pkey PRIMARY KEY (id);


--
-- TOC entry 3219 (class 2606 OID 141304)
-- Name: pacs_patients pacs_patients_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_patients
    ADD CONSTRAINT pacs_patients_pkey PRIMARY KEY (id);


--
-- TOC entry 3275 (class 2606 OID 141641)
-- Name: pacs_preference_items pacs_preference_items_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_preference_items
    ADD CONSTRAINT pacs_preference_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3230 (class 2606 OID 141370)
-- Name: pacs_preference_sets pacs_preference_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_preference_sets
    ADD CONSTRAINT pacs_preference_sets_pkey PRIMARY KEY (id);


--
-- TOC entry 3290 (class 2606 OID 165719)
-- Name: pacs_report_templates pacs_report_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_report_templates
    ADD CONSTRAINT pacs_report_templates_pkey PRIMARY KEY (id);


--
-- TOC entry 3294 (class 2606 OID 165736)
-- Name: pacs_reports pacs_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_reports
    ADD CONSTRAINT pacs_reports_pkey PRIMARY KEY (id);


--
-- TOC entry 3238 (class 2606 OID 141426)
-- Name: pacs_role_has_role_items pacs_role_has_role_items_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_role_has_role_items
    ADD CONSTRAINT pacs_role_has_role_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3234 (class 2606 OID 141403)
-- Name: pacs_role_items pacs_role_items_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_role_items
    ADD CONSTRAINT pacs_role_items_pkey PRIMARY KEY (id);

CREATE INDEX pacs_role_items_name_index ON public.pacs_role_items USING btree (name);


--
-- TOC entry 3241 (class 2606 OID 141447)
-- Name: pacs_role_membership pacs_role_membership_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_role_membership
    ADD CONSTRAINT pacs_role_membership_pkey PRIMARY KEY (id);


--
-- TOC entry 3236 (class 2606 OID 141411)
-- Name: pacs_roles pacs_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_roles
    ADD CONSTRAINT pacs_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 3299 (class 2606 OID 174019)
-- Name: pacs_routing_locations pacs_routing_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_routing_locations
    ADD CONSTRAINT pacs_routing_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 3303 (class 2606 OID 174042)
-- Name: pacs_routing_rules pacs_routing_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_routing_rules
    ADD CONSTRAINT pacs_routing_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 3301 (class 2606 OID 174029)
-- Name: pacs_routings pacs_routings_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_routings
    ADD CONSTRAINT pacs_routings_pkey PRIMARY KEY (id);


--
-- TOC entry 3283 (class 2606 OID 141686)
-- Name: pacs_series_links pacs_series_links_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_series_links
    ADD CONSTRAINT pacs_series_links_pkey PRIMARY KEY (id);


--
-- TOC entry 3224 (class 2606 OID 141342)
-- Name: pacs_series pacs_series_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_series
    ADD CONSTRAINT pacs_series_pkey PRIMARY KEY (id);


ALTER TABLE ONLY public.pacs_auto_routing
    ADD CONSTRAINT pacs_auto_routing_pkey PRIMARY KEY (id);

--
-- TOC entry 3193 (class 2606 OID 141154)
-- Name: pacs_sites pacs_sites_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_sites
    ADD CONSTRAINT pacs_sites_pkey PRIMARY KEY (id);

CREATE INDEX pacs_sites_organization_id_index ON public.pacs_sites USING btree (organization_id);
CREATE INDEX pacs_sites_name_index ON public.pacs_sites USING btree (name);

--
-- TOC entry 3216 (class 2606 OID 141291)
-- Name: pacs_smart_albums pacs_smart_albums_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_smart_albums
    ADD CONSTRAINT pacs_smart_albums_pkey PRIMARY KEY (id);

CREATE INDEX pacs_smart_albums_partition_id_index ON public.pacs_smart_albums USING btree (partition_id);

--
-- TOC entry 3222 (class 2606 OID 141318)
-- Name: pacs_studies pacs_studies_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_studies
    ADD CONSTRAINT pacs_studies_pkey PRIMARY KEY (id);


--
-- TOC entry 3281 (class 2606 OID 141670)
-- Name: pacs_study_links pacs_study_links_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_study_links
    ADD CONSTRAINT pacs_study_links_pkey PRIMARY KEY (id);


--
-- TOC entry 3232 (class 2606 OID 141383)
-- Name: pacs_users pacs_users_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_users
    ADD CONSTRAINT pacs_users_pkey PRIMARY KEY (id);


CREATE UNIQUE INDEX pacs_users_site_id_login_index ON public.pacs_users USING btree (site_id, login);

CREATE INDEX pacs_users_site_id_index ON public.pacs_users USING btree (site_id);
CREATE INDEX pacs_users_login_index ON public.pacs_users USING btree (login);
CREATE INDEX pacs_users_password_index ON public.pacs_users USING btree (password);
CREATE INDEX pacs_users_shared_pref_id_index ON public.pacs_users USING btree (shared_pref_id);
CREATE INDEX pacs_users_pref_id_index ON public.pacs_users USING btree (pref_id);


--
-- TOC entry 3195 (class 2606 OID 141167)
-- Name: pacs_volumes pacs_volumes_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_volumes
    ADD CONSTRAINT pacs_volumes_pkey PRIMARY KEY (id);


--
-- TOC entry 3297 (class 2606 OID 173914)
-- Name: preference_items preference_items_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.preference_items
    ADD CONSTRAINT preference_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3189 (class 2606 OID 141144)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 3291 (class 1259 OID 165742)
-- Name: fki_pacs_report_study_id_fkey; Type: INDEX; Schema: public; Owner: dgc
--

CREATE INDEX fki_pacs_report_study_id_fkey ON public.pacs_reports USING btree (study_id);


--
-- TOC entry 3292 (class 1259 OID 165748)
-- Name: fki_pacs_report_template_id_fkey; Type: INDEX; Schema: public; Owner: dgc
--

CREATE INDEX fki_pacs_report_template_id_fkey ON public.pacs_reports USING btree (template_id);


--
-- TOC entry 3288 (class 1259 OID 165728)
-- Name: fki_pacs_report_templates_site_id_fkey; Type: INDEX; Schema: public; Owner: dgc
--

CREATE INDEX fki_pacs_report_templates_site_id_fkey ON public.pacs_report_templates USING btree (site_id);


--
-- TOC entry 3257 (class 1259 OID 141551)
-- Name: pacs_album_access_items_item_id_album_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_album_access_items_item_id_album_id_index ON public.pacs_album_access_items USING btree (item_id, album_id);

CREATE INDEX pacs_album_access_items_item_id_index ON public.pacs_album_access_items USING btree (item_id);
CREATE INDEX pacs_album_access_items_album_id_index ON public.pacs_album_access_items USING btree (album_id);
CREATE INDEX pacs_album_access_items_smart_album_id_index ON public.pacs_album_access_items USING btree (smart_album_id);


--
-- TOC entry 3258 (class 1259 OID 141552)
-- Name: pacs_album_access_items_item_id_smart_album_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_album_access_items_item_id_smart_album_id_index ON public.pacs_album_access_items USING btree (item_id, smart_album_id);


--
-- TOC entry 3271 (class 1259 OID 141633)
-- Name: pacs_dicom_access_items_access_id_client_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_dicom_access_items_access_id_client_id_index ON public.pacs_dicom_access_items USING btree (access_id, client_id);

CREATE INDEX pacs_dicom_access_items_access_id_index ON public.pacs_dicom_access_items USING btree (access_id);
CREATE INDEX pacs_dicom_access_items_client_id_index ON public.pacs_dicom_access_items USING btree (client_id);

--
-- TOC entry 3269 (class 1259 OID 141617)
-- Name: pacs_dicom_access_role_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_dicom_access_role_id_index ON public.pacs_dicom_access USING btree (role_id);


--
-- TOC entry 3270 (class 1259 OID 141616)
-- Name: pacs_dicom_access_user_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_dicom_access_user_id_index ON public.pacs_dicom_access USING btree (user_id);


--
-- TOC entry 3263 (class 1259 OID 141566)
-- Name: pacs_dicom_aes_site_id_ae_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_dicom_aes_site_id_ae_index ON public.pacs_dicom_aes USING btree (site_id, ae);
CREATE INDEX pacs_dicom_aes_site_id_index ON public.pacs_dicom_aes USING btree (site_id);
CREATE INDEX pacs_dicom_aes_ae_index ON public.pacs_dicom_aes USING btree (ae);

--
-- TOC entry 3264 (class 1259 OID 141600)
-- Name: pacs_dicom_clients_ae_id_ae_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_dicom_clients_ae_id_ae_index ON public.pacs_dicom_clients USING btree (ae_id, ae);
CREATE INDEX pacs_dicom_clients_ae_id_index ON public.pacs_dicom_clients USING btree (ae_id);
CREATE INDEX pacs_dicom_clients_ae_index ON public.pacs_dicom_clients USING btree (ae);
CREATE INDEX pacs_dicom_clients_target_partition_index ON public.pacs_dicom_clients USING btree (target_partition);
CREATE INDEX pacs_dicom_clients_target_album_index ON public.pacs_dicom_clients USING btree (target_album);
CREATE INDEX pacs_dicom_clients_target_smart_album_index ON public.pacs_dicom_clients USING btree (target_smart_album);
CREATE INDEX pacs_dicom_clients_target_dicom_index ON public.pacs_dicom_clients USING btree (target_dicom);


--
-- TOC entry 3287 (class 1259 OID 141713)
-- Name: pacs_image_links_series_link_id_image_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_image_links_series_link_id_image_id_index ON public.pacs_image_links USING btree (series_link_id, image_id);

CREATE INDEX pacs_image_links_series_link_id_index ON public.pacs_image_links USING btree (series_link_id);
CREATE INDEX pacs_image_links_image_id_index ON public.pacs_image_links USING btree (image_id);


--
-- TOC entry 3228 (class 1259 OID 141362)
-- Name: pacs_images_series_id_uid_status_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_images_series_id_uid_status_index ON public.pacs_images USING btree (series_id, uid, status);

CREATE INDEX pacs_images_series_id_index ON public.pacs_images USING btree (series_id);
CREATE INDEX pacs_images_uid_index ON public.pacs_images USING btree (uid);
CREATE INDEX pacs_images_status_index ON public.pacs_images USING btree (status);

--
-- TOC entry 3199 (class 1259 OID 141193)
-- Name: pacs_media_site_id_type_num_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_media_site_id_type_num_index ON public.pacs_media USING btree (site_id, type, num);

CREATE INDEX pacs_media_site_id_index ON public.pacs_media USING btree (site_id);
CREATE INDEX pacs_media_volume_id_index ON public.pacs_media USING btree (volume_id);


--
-- TOC entry 3200 (class 1259 OID 141192)
-- Name: pacs_media_volume_id_type_num_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_media_volume_id_type_num_index ON public.pacs_media USING btree (volume_id, type, num);


--
-- TOC entry 3254 (class 1259 OID 141530)
-- Name: pacs_partition_access_items_access_id_partition_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_partition_access_items_access_id_partition_id_index ON public.pacs_partition_access_items USING btree (access_id, partition_id);

CREATE INDEX pacs_partition_access_items_access_id_index ON public.pacs_partition_access_items USING btree (access_id);
CREATE INDEX pacs_partition_access_items_partition_id_index ON public.pacs_partition_access_items USING btree (partition_id);


--
-- TOC entry 3252 (class 1259 OID 141514)
-- Name: pacs_partition_access_role_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_partition_access_role_id_index ON public.pacs_partition_access USING btree (role_id);


--
-- TOC entry 3253 (class 1259 OID 141513)
-- Name: pacs_partition_access_user_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_partition_access_user_id_index ON public.pacs_partition_access USING btree (user_id);


--
-- TOC entry 3276 (class 1259 OID 141662)
-- Name: pacs_patient_links_album_id_patient_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_patient_links_album_id_patient_id_index ON public.pacs_patient_links USING btree (album_id, patient_id);

CREATE INDEX pacs_patient_links_album_id_index ON public.pacs_patient_links USING btree (album_id);
CREATE INDEX pacs_patient_links_patient_id_index ON public.pacs_patient_links USING btree (patient_id);

--
-- TOC entry 3217 (class 1259 OID 141310)
-- Name: pacs_patients_partition_id_pid_name_ideogram_phonetic_birthdate; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_patients_partition_id_pid_name_ideogram_phonetic_birthdate ON public.pacs_patients USING btree (partition_id, pid, name, ideogram, phonetic, birthdate, birthtime, sex, status);

CREATE INDEX pacs_patients_partition_id_index ON public.pacs_patients USING btree (partition_id);
CREATE INDEX pacs_patients_pid_index ON public.pacs_patients USING btree (pid);
CREATE INDEX pacs_patients_name_index ON public.pacs_patients USING btree (name);
CREATE INDEX pacs_patients_ideogram_index ON public.pacs_patients USING btree (ideogram);
CREATE INDEX pacs_patients_phonetic_index ON public.pacs_patients USING btree (phonetic);
CREATE INDEX pacs_patients_birthdate_index ON public.pacs_patients USING btree (birthdate);
CREATE INDEX pacs_patients_sex_index ON public.pacs_patients USING btree (sex);
CREATE INDEX pacs_patients_status_index ON public.pacs_patients USING btree (status);
CREATE INDEX pacs_patients_crdate_index ON public.pacs_patients USING btree (crdate);

--
-- TOC entry 3239 (class 1259 OID 141442)
-- Name: pacs_role_has_role_items_role_id_user_id_item_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_role_has_role_items_role_id_user_id_item_id_index ON public.pacs_role_has_role_items USING btree (role_id, user_id, item_id);

CREATE INDEX pacs_role_has_role_items_role_id_index ON public.pacs_role_has_role_items USING btree (role_id);
CREATE INDEX pacs_role_has_role_items_user_id_index ON public.pacs_role_has_role_items USING btree (user_id);
CREATE INDEX pacs_role_has_role_items_item_id_index ON public.pacs_role_has_role_items USING btree (item_id);


--
-- TOC entry 3242 (class 1259 OID 141463)
-- Name: pacs_role_membership_role_id_parent_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_role_membership_role_id_parent_id_index ON public.pacs_role_membership USING btree (role_id, parent_id);


--
-- TOC entry 3243 (class 1259 OID 141464)
-- Name: pacs_role_membership_user_id_parent_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_role_membership_user_id_parent_id_index ON public.pacs_role_membership USING btree (user_id, parent_id);

CREATE INDEX pacs_role_membership_role_id_index ON public.pacs_role_membership USING btree (role_id);
CREATE INDEX pacs_role_membership_user_id_index ON public.pacs_role_membership USING btree (user_id);
CREATE INDEX pacs_role_membership_parent_id_index ON public.pacs_role_membership USING btree (parent_id);

--
-- TOC entry 3284 (class 1259 OID 141697)
-- Name: pacs_series_links_study_link_id_series_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_series_links_study_link_id_series_id_index ON public.pacs_series_links USING btree (study_link_id, series_id);

CREATE INDEX pacs_series_links_study_link_id_index ON public.pacs_series_links USING btree (study_link_id);
CREATE INDEX pacs_series_links_series_id_index ON public.pacs_series_links USING btree (series_id);


--
-- TOC entry 3225 (class 1259 OID 141348)
-- Name: pacs_series_study_id_uid_status_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_series_study_id_uid_status_index ON public.pacs_series USING btree (study_id, uid, status);

CREATE INDEX pacs_series_study_id_index ON public.pacs_series USING btree (study_id);
CREATE INDEX pacs_series_uid_index ON public.pacs_series USING btree (uid);
-- CREATE INDEX pacs_series_seriesdate_index ON public.pacs_series USING btree (seriesdate);
-- CREATE INDEX pacs_series_modality_index ON public.pacs_series USING btree (modality);
-- CREATE INDEX pacs_series_bodypart_index ON public.pacs_series USING btree (bodypart);
-- CREATE INDEX pacs_series_srnum_index ON public.pacs_series USING btree (srnum);
CREATE INDEX pacs_series_status_index ON public.pacs_series USING btree (status);
CREATE INDEX pacs_series_station_index ON public.pacs_series USING btree (station);
-- CREATE INDEX pacs_series_comment_index ON public.pacs_series USING btree (comment);
-- CREATE INDEX pacs_series_crdate_index ON public.pacs_series USING btree (crdate);


--
-- TOC entry 3220 (class 1259 OID 141334)
-- Name: pacs_studies_partition_id_uid_status_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_studies_partition_id_uid_status_index ON public.pacs_studies USING btree (partition_id, uid, status);

CREATE INDEX pacs_studies_partition_id_index ON public.pacs_studies USING btree (partition_id);
CREATE INDEX pacs_studies_patient_id_index ON public.pacs_studies USING btree (patient_id);
CREATE INDEX pacs_studies_uid_index ON public.pacs_studies USING btree (uid);
CREATE INDEX pacs_studies_comment_index ON public.pacs_studies USING btree (comment);
CREATE INDEX pacs_studies_modalities_index ON public.pacs_studies USING btree (modalities);
CREATE INDEX pacs_studies_institution_index ON public.pacs_studies USING btree (institution);
CREATE INDEX pacs_studies_accnum_index ON public.pacs_studies USING btree (accnum);
CREATE INDEX pacs_studies_stations_index ON public.pacs_studies USING btree (stations);
CREATE INDEX pacs_studies_studydate_index ON public.pacs_studies USING btree (studydate);
CREATE INDEX pacs_studies_studyid_index ON public.pacs_studies USING btree (studyid);
CREATE INDEX pacs_studies_status_index ON public.pacs_studies USING btree (status);
CREATE INDEX pacs_studies_conflict_id_index ON public.pacs_studies USING btree (conflict_id);
CREATE INDEX pacs_studies_crdate_index ON public.pacs_studies USING btree (crdate);

--
-- TOC entry 3279 (class 1259 OID 141681)
-- Name: pacs_study_links_patient_link_id_study_id_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_study_links_patient_link_id_study_id_index ON public.pacs_study_links USING btree (patient_link_id, study_id);

CREATE INDEX pacs_study_links_patient_link_id_index ON public.pacs_study_links USING btree (patient_link_id);
CREATE INDEX pacs_study_links_study_id_index ON public.pacs_study_links USING btree (study_id);
CREATE INDEX pacs_study_links_all_series_index ON public.pacs_study_links USING btree (all_series);
CREATE INDEX pacs_study_links_modalities_index ON public.pacs_study_links USING btree (modalities);
CREATE INDEX pacs_study_links_bodyparts_index ON public.pacs_study_links USING btree (bodyparts);
CREATE INDEX pacs_study_links_stations_index ON public.pacs_study_links USING btree (stations);


--
-- TOC entry 3196 (class 1259 OID 141173)
-- Name: pacs_volumes_site_id_name_index; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX pacs_volumes_site_id_name_index ON public.pacs_volumes USING btree (site_id, name);

CREATE INDEX pacs_volumes_site_id_index ON public.pacs_volumes USING btree (site_id);

--
-- TOC entry 3295 (class 1259 OID 165749)
-- Name: report_uniquereport; Type: INDEX; Schema: public; Owner: dgc
--

CREATE UNIQUE INDEX report_uniquereport ON public.pacs_reports USING btree (study_id, uid);
CREATE INDEX pacs_report_uid_index ON public.pacs_reports USING btree (uid);

--
-- TOC entry 3374 (class 2606 OID 174063)
-- Name: pacs_compressions fk_pacs_compressions_partitions1; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_compressions
    ADD CONSTRAINT fk_pacs_compressions_partitions1 FOREIGN KEY (partition_id) REFERENCES public.pacs_partitions(id);

CREATE UNIQUE INDEX pacs_compressions_partition_id_index ON public.pacs_compressions USING btree (partition_id);

--
-- TOC entry 3369 (class 2606 OID 174020)
-- Name: pacs_routing_locations fk_pacs_routing_locations_sites1; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_routing_locations
    ADD CONSTRAINT fk_pacs_routing_locations_sites1 FOREIGN KEY (site_id) REFERENCES public.pacs_sites(id);


--
-- TOC entry 3372 (class 2606 OID 174048)
-- Name: pacs_routing_rules fk_pacs_routing_rules_location2; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_routing_rules
    ADD CONSTRAINT fk_pacs_routing_rules_location2 FOREIGN KEY (dest_loc) REFERENCES public.pacs_routing_locations(id);


--
-- TOC entry 3371 (class 2606 OID 174043)
-- Name: pacs_routing_rules fk_pacs_routing_rules_locations1; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_routing_rules
    ADD CONSTRAINT fk_pacs_routing_rules_locations1 FOREIGN KEY (from_loc) REFERENCES public.pacs_routing_locations(id);


--
-- TOC entry 3373 (class 2606 OID 174053)
-- Name: pacs_routing_rules fk_pacs_routing_rules_routings1; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_routing_rules
    ADD CONSTRAINT fk_pacs_routing_rules_routings1 FOREIGN KEY (routing_id) REFERENCES public.pacs_routings(id);


CREATE INDEX pacs_routing_rules_routing_id_index ON public.pacs_routing_rules USING btree (routing_id);
CREATE INDEX pacs_routing_rules_from_loc_index ON public.pacs_routing_rules USING btree (from_loc);
CREATE INDEX pacs_routing_rules_dest_locindex ON public.pacs_routing_rules USING btree (dest_loc);


--
-- TOC entry 3370 (class 2606 OID 174030)
-- Name: pacs_routings fk_pacs_routings_partitions1; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_routings
    ADD CONSTRAINT fk_pacs_routings_partitions1 FOREIGN KEY (partition_id) REFERENCES public.pacs_partitions(id);

CREATE UNIQUE INDEX pacs_routings_partition_id_index ON public.pacs_routings USING btree (partition_id);

--
-- TOC entry 3345 (class 2606 OID 141541)
-- Name: pacs_album_access_items pacs_album_access_items_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_album_access_items
    ADD CONSTRAINT pacs_album_access_items_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.pacs_albums(id);


--
-- TOC entry 3344 (class 2606 OID 141536)
-- Name: pacs_album_access_items pacs_album_access_items_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_album_access_items
    ADD CONSTRAINT pacs_album_access_items_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.pacs_partition_access_items(id);


--
-- TOC entry 3346 (class 2606 OID 141546)
-- Name: pacs_album_access_items pacs_album_access_items_smart_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_album_access_items
    ADD CONSTRAINT pacs_album_access_items_smart_album_id_fkey FOREIGN KEY (smart_album_id) REFERENCES public.pacs_smart_albums(id);


--
-- TOC entry 3317 (class 2606 OID 141279)
-- Name: pacs_albums pacs_albums_partition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_albums
    ADD CONSTRAINT pacs_albums_partition_id_fkey FOREIGN KEY (partition_id) REFERENCES public.pacs_partitions(id);


--
-- TOC entry 3355 (class 2606 OID 141623)
-- Name: pacs_dicom_access_items pacs_dicom_access_items_access_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_access_items
    ADD CONSTRAINT pacs_dicom_access_items_access_id_fkey FOREIGN KEY (access_id) REFERENCES public.pacs_dicom_access(id);


--
-- TOC entry 3356 (class 2606 OID 141628)
-- Name: pacs_dicom_access_items pacs_dicom_access_items_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_access_items
    ADD CONSTRAINT pacs_dicom_access_items_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.pacs_dicom_clients(id);


--
-- TOC entry 3354 (class 2606 OID 141611)
-- Name: pacs_dicom_access pacs_dicom_access_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_access
    ADD CONSTRAINT pacs_dicom_access_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.pacs_roles(id);


--
-- TOC entry 3353 (class 2606 OID 141606)
-- Name: pacs_dicom_access pacs_dicom_access_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_access
    ADD CONSTRAINT pacs_dicom_access_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.pacs_users(id);


--
-- TOC entry 3347 (class 2606 OID 141561)
-- Name: pacs_dicom_aes pacs_dicom_aes_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_aes
    ADD CONSTRAINT pacs_dicom_aes_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.pacs_sites(id);


--
-- TOC entry 3348 (class 2606 OID 141575)
-- Name: pacs_dicom_clients pacs_dicom_clients_ae_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_clients
    ADD CONSTRAINT pacs_dicom_clients_ae_id_fkey FOREIGN KEY (ae_id) REFERENCES public.pacs_dicom_aes(id);


--
-- TOC entry 3350 (class 2606 OID 141585)
-- Name: pacs_dicom_clients pacs_dicom_clients_target_album_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_clients
    ADD CONSTRAINT pacs_dicom_clients_target_album_fkey FOREIGN KEY (target_album) REFERENCES public.pacs_albums(id);


--
-- TOC entry 3352 (class 2606 OID 141595)
-- Name: pacs_dicom_clients pacs_dicom_clients_target_dicom_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_clients
    ADD CONSTRAINT pacs_dicom_clients_target_dicom_fkey FOREIGN KEY (target_dicom) REFERENCES public.pacs_dicom_clients(id);


--
-- TOC entry 3349 (class 2606 OID 141580)
-- Name: pacs_dicom_clients pacs_dicom_clients_target_partition_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_clients
    ADD CONSTRAINT pacs_dicom_clients_target_partition_fkey FOREIGN KEY (target_partition) REFERENCES public.pacs_partitions(id);


--
-- TOC entry 3351 (class 2606 OID 141590)
-- Name: pacs_dicom_clients pacs_dicom_clients_target_smart_album_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_dicom_clients
    ADD CONSTRAINT pacs_dicom_clients_target_smart_album_fkey FOREIGN KEY (target_smart_album) REFERENCES public.pacs_smart_albums(id);


--
-- TOC entry 3339 (class 2606 OID 141493)
-- Name: pacs_download_images pacs_download_images_series_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_download_images
    ADD CONSTRAINT pacs_download_images_series_id_fkey FOREIGN KEY (series_id) REFERENCES public.pacs_download_series(id);


CREATE INDEX pacs_download_images_series_id_index ON public.pacs_download_images USING btree (series_id);
CREATE INDEX pacs_download_images_num_index ON public.pacs_download_images USING btree (num);

--
-- TOC entry 3365 (class 2606 OID 141708)
-- Name: pacs_image_links pacs_image_links_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_image_links
    ADD CONSTRAINT pacs_image_links_image_id_fkey FOREIGN KEY (image_id) REFERENCES public.pacs_images(id);


--
-- TOC entry 3364 (class 2606 OID 141703)
-- Name: pacs_image_links pacs_image_links_series_link_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_image_links
    ADD CONSTRAINT pacs_image_links_series_link_id_fkey FOREIGN KEY (series_link_id) REFERENCES public.pacs_series_links(id);


--
-- TOC entry 3324 (class 2606 OID 141357)
-- Name: pacs_images pacs_images_series_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_images
    ADD CONSTRAINT pacs_images_series_id_fkey FOREIGN KEY (series_id) REFERENCES public.pacs_series(id);


--
-- TOC entry 3308 (class 2606 OID 141182)
-- Name: pacs_media pacs_media_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_media
    ADD CONSTRAINT pacs_media_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.pacs_sites(id);


--
-- TOC entry 3309 (class 2606 OID 141187)
-- Name: pacs_media pacs_media_volume_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_media
    ADD CONSTRAINT pacs_media_volume_id_fkey FOREIGN KEY (volume_id) REFERENCES public.pacs_volumes(id);


--
-- TOC entry 3342 (class 2606 OID 141520)
-- Name: pacs_partition_access_items pacs_partition_access_items_access_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_partition_access_items
    ADD CONSTRAINT pacs_partition_access_items_access_id_fkey FOREIGN KEY (access_id) REFERENCES public.pacs_partition_access(id);


--
-- TOC entry 3343 (class 2606 OID 141525)
-- Name: pacs_partition_access_items pacs_partition_access_items_partition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_partition_access_items
    ADD CONSTRAINT pacs_partition_access_items_partition_id_fkey FOREIGN KEY (partition_id) REFERENCES public.pacs_partitions(id);


--
-- TOC entry 3341 (class 2606 OID 141508)
-- Name: pacs_partition_access pacs_partition_access_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_partition_access
    ADD CONSTRAINT pacs_partition_access_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.pacs_roles(id);


--
-- TOC entry 3340 (class 2606 OID 141503)
-- Name: pacs_partition_access pacs_partition_access_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_partition_access
    ADD CONSTRAINT pacs_partition_access_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.pacs_users(id);


--
-- TOC entry 3338 (class 2606 OID 141475)
-- Name: pacs_partition_limits pacs_partition_limits_partition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_partition_limits
    ADD CONSTRAINT pacs_partition_limits_partition_id_fkey FOREIGN KEY (partition_id) REFERENCES public.pacs_partitions(id);


--
-- TOC entry 3337 (class 2606 OID 141470)
-- Name: pacs_partition_limits pacs_partition_limits_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_partition_limits
    ADD CONSTRAINT pacs_partition_limits_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.pacs_users(id);


CREATE INDEX pacs_partition_limits_user_id_index ON public.pacs_partition_limits USING btree (user_id);
CREATE INDEX pacs_partition_limits_partition_id_index ON public.pacs_partition_limits USING btree (partition_id);

--
-- TOC entry 3315 (class 2606 OID 141261)
-- Name: pacs_partitions pacs_partitions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_partitions
    ADD CONSTRAINT pacs_partitions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.pacs_sites(id);


--
-- TOC entry 3316 (class 2606 OID 141266)
-- Name: pacs_partitions pacs_partitions_volume_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_partitions
    ADD CONSTRAINT pacs_partitions_volume_id_fkey FOREIGN KEY (volume_id) REFERENCES public.pacs_volumes(id);


--
-- TOC entry 3358 (class 2606 OID 141652)
-- Name: pacs_patient_links pacs_patient_links_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_patient_links
    ADD CONSTRAINT pacs_patient_links_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.pacs_albums(id);


--
-- TOC entry 3359 (class 2606 OID 141657)
-- Name: pacs_patient_links pacs_patient_links_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_patient_links
    ADD CONSTRAINT pacs_patient_links_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.pacs_patients(id);


--
-- TOC entry 3319 (class 2606 OID 141305)
-- Name: pacs_patients pacs_patients_partition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_patients
    ADD CONSTRAINT pacs_patients_partition_id_fkey FOREIGN KEY (partition_id) REFERENCES public.pacs_partitions(id);


--
-- TOC entry 3357 (class 2606 OID 141642)
-- Name: pacs_preference_items pacs_preference_items_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_preference_items
    ADD CONSTRAINT pacs_preference_items_set_id_fkey FOREIGN KEY (set_id) REFERENCES public.pacs_preference_sets(id);

CREATE INDEX pacs_preference_items_set_id_index ON public.pacs_preference_items USING btree (set_id);
CREATE INDEX pacs_preference_items_settypeversion_index ON public.pacs_preference_items USING btree (set_id, ptype, pversion);

--
-- TOC entry 3325 (class 2606 OID 141371)
-- Name: pacs_preference_sets pacs_preference_sets_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_preference_sets
    ADD CONSTRAINT pacs_preference_sets_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.pacs_sites(id);


CREATE INDEX pacs_preference_sets_site_id_index ON public.pacs_preference_sets USING btree (site_id);
CREATE INDEX pacs_preference_sets_for_user_index ON public.pacs_preference_sets USING btree (for_user);


--
-- TOC entry 3367 (class 2606 OID 165737)
-- Name: pacs_reports pacs_report_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_reports
    ADD CONSTRAINT pacs_report_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.pacs_studies(id);


--
-- TOC entry 3368 (class 2606 OID 165743)
-- Name: pacs_reports pacs_report_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_reports
    ADD CONSTRAINT pacs_report_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.pacs_report_templates(id);


--
-- TOC entry 3366 (class 2606 OID 165723)
-- Name: pacs_report_templates pacs_report_templates_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_report_templates
    ADD CONSTRAINT pacs_report_templates_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.pacs_sites(id);


--
-- TOC entry 3333 (class 2606 OID 141437)
-- Name: pacs_role_has_role_items pacs_role_has_role_items_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_role_has_role_items
    ADD CONSTRAINT pacs_role_has_role_items_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.pacs_role_items(id);


--
-- TOC entry 3331 (class 2606 OID 141427)
-- Name: pacs_role_has_role_items pacs_role_has_role_items_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_role_has_role_items
    ADD CONSTRAINT pacs_role_has_role_items_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.pacs_roles(id);


--
-- TOC entry 3332 (class 2606 OID 141432)
-- Name: pacs_role_has_role_items pacs_role_has_role_items_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_role_has_role_items
    ADD CONSTRAINT pacs_role_has_role_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.pacs_users(id);


--
-- TOC entry 3336 (class 2606 OID 141458)
-- Name: pacs_role_membership pacs_role_membership_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_role_membership
    ADD CONSTRAINT pacs_role_membership_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.pacs_roles(id);


--
-- TOC entry 3334 (class 2606 OID 141448)
-- Name: pacs_role_membership pacs_role_membership_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_role_membership
    ADD CONSTRAINT pacs_role_membership_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.pacs_roles(id);


--
-- TOC entry 3335 (class 2606 OID 141453)
-- Name: pacs_role_membership pacs_role_membership_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_role_membership
    ADD CONSTRAINT pacs_role_membership_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.pacs_users(id);


--
-- TOC entry 3330 (class 2606 OID 141417)
-- Name: pacs_roles pacs_roles_pref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_roles
    ADD CONSTRAINT pacs_roles_pref_id_fkey FOREIGN KEY (pref_id) REFERENCES public.pacs_preference_sets(id);


--
-- TOC entry 3329 (class 2606 OID 141412)
-- Name: pacs_roles pacs_roles_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_roles
    ADD CONSTRAINT pacs_roles_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.pacs_sites(id);


CREATE INDEX pacs_roles_site_id_index ON public.pacs_roles USING btree (site_id);
CREATE INDEX pacs_roles_pref_id_index ON public.pacs_roles USING btree (pref_id);

--
-- TOC entry 3363 (class 2606 OID 141692)
-- Name: pacs_series_links pacs_series_links_series_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_series_links
    ADD CONSTRAINT pacs_series_links_series_id_fkey FOREIGN KEY (series_id) REFERENCES public.pacs_series(id);


--
-- TOC entry 3362 (class 2606 OID 141687)
-- Name: pacs_series_links pacs_series_links_study_link_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_series_links
    ADD CONSTRAINT pacs_series_links_study_link_id_fkey FOREIGN KEY (study_link_id) REFERENCES public.pacs_study_links(id);


--
-- TOC entry 3323 (class 2606 OID 141343)
-- Name: pacs_series pacs_series_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_series
    ADD CONSTRAINT pacs_series_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.pacs_studies(id);




--
-- TOC entry 3306 (class 2606 OID 141155)
-- Name: pacs_sites pacs_sites_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_sites
    ADD CONSTRAINT pacs_sites_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.pacs_organizations(id);


--
-- TOC entry 3318 (class 2606 OID 141292)
-- Name: pacs_smart_albums pacs_smart_albums_partition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_smart_albums
    ADD CONSTRAINT pacs_smart_albums_partition_id_fkey FOREIGN KEY (partition_id) REFERENCES public.pacs_partitions(id);


--
-- TOC entry 3322 (class 2606 OID 141329)
-- Name: pacs_studies pacs_studies_conflict_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_studies
    ADD CONSTRAINT pacs_studies_conflict_id_fkey FOREIGN KEY (conflict_id) REFERENCES public.pacs_studies(id);


--
-- TOC entry 3320 (class 2606 OID 141319)
-- Name: pacs_studies pacs_studies_partition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_studies
    ADD CONSTRAINT pacs_studies_partition_id_fkey FOREIGN KEY (partition_id) REFERENCES public.pacs_partitions(id);


--
-- TOC entry 3321 (class 2606 OID 141324)
-- Name: pacs_studies pacs_studies_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_studies
    ADD CONSTRAINT pacs_studies_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.pacs_patients(id);


--
-- TOC entry 3360 (class 2606 OID 141671)
-- Name: pacs_study_links pacs_study_links_patient_link_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_study_links
    ADD CONSTRAINT pacs_study_links_patient_link_id_fkey FOREIGN KEY (patient_link_id) REFERENCES public.pacs_patient_links(id);


--
-- TOC entry 3361 (class 2606 OID 141676)
-- Name: pacs_study_links pacs_study_links_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_study_links
    ADD CONSTRAINT pacs_study_links_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.pacs_studies(id);


--
-- TOC entry 3328 (class 2606 OID 141394)
-- Name: pacs_users pacs_users_pref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_users
    ADD CONSTRAINT pacs_users_pref_id_fkey FOREIGN KEY (pref_id) REFERENCES public.pacs_preference_sets(id);


--
-- TOC entry 3327 (class 2606 OID 141389)
-- Name: pacs_users pacs_users_shared_pref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_users
    ADD CONSTRAINT pacs_users_shared_pref_id_fkey FOREIGN KEY (shared_pref_id) REFERENCES public.pacs_preference_sets(id);


--
-- TOC entry 3326 (class 2606 OID 141384)
-- Name: pacs_users pacs_users_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_users
    ADD CONSTRAINT pacs_users_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.pacs_sites(id);


--
-- TOC entry 3307 (class 2606 OID 141168)
-- Name: pacs_volumes pacs_volumes_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dgc
--

ALTER TABLE ONLY public.pacs_volumes
    ADD CONSTRAINT pacs_volumes_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.pacs_sites(id);



ALTER TABLE ONLY public.pacs_auto_routing
    ADD CONSTRAINT pacs_auto_routing_partition_id_fkey FOREIGN KEY (partition_id) REFERENCES public.pacs_partitions(id);

ALTER TABLE ONLY public.pacs_auto_routing
    ADD CONSTRAINT pacs_auto_routing_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.pacs_sites(id);

ALTER TABLE ONLY public.pacs_auto_routing
    ADD CONSTRAINT pacs_auto_routing_image_id_fkey FOREIGN KEY (image_id) REFERENCES public.pacs_images(id);

ALTER TABLE ONLY public.pacs_auto_routing
    ADD CONSTRAINT pacs_auto_routing_series_id_fkey FOREIGN KEY (series_id) REFERENCES public.pacs_series(id);

ALTER TABLE ONLY public.pacs_auto_routing
    ADD CONSTRAINT pacs_auto_routing_loc_id_fkey FOREIGN KEY (loc_id) REFERENCES public.pacs_routing_locations(id);


CREATE INDEX pacs_auto_routing_series_id_index ON public.pacs_auto_routing USING btree (series_id);
CREATE INDEX pacs_auto_routing_image_id_index ON public.pacs_auto_routing USING btree (image_id);
CREATE INDEX pacs_auto_routing_partition_id_index ON public.pacs_auto_routing USING btree (partition_id);
CREATE INDEX pacs_auto_routing_loc_id_index ON public.pacs_auto_routing USING btree (loc_id);
CREATE INDEX pacs_auto_routing_site_id_index ON public.pacs_auto_routing USING btree (site_id);

-- Completed on 2021-04-29 13:00:32 CEST

--
-- dgcQL database dump complete
--


INSERT INTO public.pacs_role_items(id, name, type) VALUES ('75f39d00-4c46-4b2a-9428-be26d7639700', 'ADMIN', 1);
INSERT INTO public.pacs_role_items(id, name, type) VALUES ('75f39d00-4c46-4b2a-9428-be26d7639701', 'MODIFY_ENTITIES', 1);
INSERT INTO public.pacs_role_items(id, name, type) VALUES ('75f39d00-4c46-4b2a-9428-be26d7639702', 'DELETE_ENTITIES', 1);
INSERT INTO public.pacs_role_items(id, name, type) VALUES ('75f39d00-4c46-4b2a-9428-be26d7639703', 'MODIFY_SHARED_PREF', 1);
INSERT INTO public.pacs_role_items(id, name, type) VALUES ('75f39d00-4c46-4b2a-9428-be26d7639704', 'IMPORT_IMAGES', 1);
INSERT INTO public.pacs_role_items(id, name, type) VALUES ('75f39d00-4c46-4b2a-9428-be26d7639705', 'REPORT_CREATE', 1);
INSERT INTO public.pacs_role_items(id, name, type) VALUES ('75f39d00-4c46-4b2a-9428-be26d7639706', 'REPORT_READ', 1);
INSERT INTO public.pacs_role_items(id, name, type) VALUES ('75f39d00-4c46-4b2a-9428-be26d7639707', 'REPORT_VERIFY', 1);
INSERT INTO public.pacs_role_items(id, name, type) VALUES ('75f39d00-4c46-4b2a-9428-be26d7639708', 'ANNOT_READ', 1);
INSERT INTO public.pacs_role_items(id, name, type) VALUES ('75f39d00-4c46-4b2a-9428-be26d7639709', 'ANNOT_MODIFY', 1);

INSERT INTO public.pacs_organizations(id, name) VALUES ('95cad9c9-c682-4bcc-a066-72cdc2a5b1b0', 'DigitalCore');
INSERT INTO public.pacs_sites(id, organization_id, name) VALUES ('22a4f7af-e2e9-4e0e-ae3d-3e648713497c', '95cad9c9-c682-4bcc-a066-72cdc2a5b1b0', 'MY SITE');

INSERT INTO public.pacs_volumes(id, site_id, name, description) VALUES ('4786307d-157e-4d0b-9ae6-9120a6a7b1eb', '22a4f7af-e2e9-4e0e-ae3d-3e648713497c', 'Volume1', '');
INSERT INTO public.pacs_partitions(id, site_id, volume_id, name, comment, status, parameters, conflict) VALUES ('ab827b22-a4b9-44a4-96d8-28c6d2a29884', '22a4f7af-e2e9-4e0e-ae3d-3e648713497c', '4786307d-157e-4d0b-9ae6-9120a6a7b1eb', 'Radiologists', NULL, 1, '{"pvi":1,"std":1,"owm":1,"pidm":0,"defpid":"Default","cm":2,"rqr":0,"rql":500,"cc":126}',0);
INSERT INTO public.pacs_compressions(id, partition_id, active, mode, start, stop, transfer, updatecnt) VALUES ('6fdd71ba-faeb-4c51-a866-a1edf9180b14', 'ab827b22-a4b9-44a4-96d8-28c6d2a29884', 0, 2, 1, 5, '', 1);
INSERT INTO public.pacs_routings(id, partition_id, active, cretry, cgiveup, fretry, fgiveup, updatecnt) VALUES ('b955a9d2-c145-407f-b43d-3265d735be3a', 'ab827b22-a4b9-44a4-96d8-28c6d2a29884', 0, 30, 1, 30, 1, 0);
INSERT INTO public.pacs_report_templates(id, site_id, name, status, filters, version, media) VALUES('7a1e774a-986f-4452-aef2-2c575f7fbb48', '22a4f7af-e2e9-4e0e-ae3d-3e648713497c', 'Default', 1, NULL, '0.0.0.1', -1);


