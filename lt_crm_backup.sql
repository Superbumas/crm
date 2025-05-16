--
-- PostgreSQL database dump
--

-- Dumped from database version 15.13
-- Dumped by pg_dump version 15.13

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
-- Name: exportformat; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.exportformat AS ENUM (
    'CSV',
    'XLSX',
    'XML'
);


ALTER TYPE public.exportformat OWNER TO postgres;

--
-- Name: integrationtype; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.integrationtype AS ENUM (
    'ECOMMERCE',
    'ACCOUNTING',
    'SHIPPING',
    'INVENTORY',
    'OTHER'
);


ALTER TYPE public.integrationtype OWNER TO postgres;

--
-- Name: invoicestatus; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.invoicestatus AS ENUM (
    'DRAFT',
    'ISSUED',
    'PAID',
    'CANCELLED'
);


ALTER TYPE public.invoicestatus OWNER TO postgres;

--
-- Name: movementreasoncode; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.movementreasoncode AS ENUM (
    'IMPORT',
    'SALE',
    'RETURN',
    'MANUAL_ADJ',
    'shipment'
);


ALTER TYPE public.movementreasoncode OWNER TO postgres;

--
-- Name: orderstatus; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.orderstatus AS ENUM (
    'NEW',
    'PAID',
    'PACKED',
    'SHIPPED',
    'RETURNED',
    'CANCELLED'
);


ALTER TYPE public.orderstatus OWNER TO postgres;

--
-- Name: shipmentstatus; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.shipmentstatus AS ENUM (
    'PENDING',
    'RECEIVED',
    'CANCELLED'
);


ALTER TYPE public.shipmentstatus OWNER TO postgres;

--
-- Name: syncstatus; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.syncstatus AS ENUM (
    'PENDING',
    'IN_PROGRESS',
    'SUCCESS',
    'FAILED',
    'PARTIAL'
);


ALTER TYPE public.syncstatus OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts (
    id integer NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(100) NOT NULL,
    account_type character varying(50) NOT NULL,
    description character varying(255),
    is_active boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.accounts OWNER TO postgres;

--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.accounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_id_seq OWNER TO postgres;

--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO postgres;

--
-- Name: company_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.company_settings (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    address character varying(200),
    city character varying(100),
    postal_code character varying(20),
    country character varying(100),
    phone character varying(20),
    email character varying(120),
    company_code character varying(50),
    vat_code character varying(50),
    bank_name character varying(100),
    bank_account character varying(50),
    bank_swift character varying(20),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.company_settings OWNER TO postgres;

--
-- Name: company_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.company_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.company_settings_id_seq OWNER TO postgres;

--
-- Name: company_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.company_settings_id_seq OWNED BY public.company_settings.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contacts (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    name character varying(100) NOT NULL,
    "position" character varying(100),
    email character varying(120),
    phone character varying(20),
    is_primary boolean,
    notes text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.contacts OWNER TO postgres;

--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.contacts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contacts_id_seq OWNER TO postgres;

--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customers (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(120),
    phone character varying(20),
    company character varying(100),
    address character varying(200),
    city character varying(100),
    country character varying(100),
    status character varying(20),
    source character varying(50),
    notes text,
    assigned_to integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.customers OWNER TO postgres;

--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customers_id_seq OWNER TO postgres;

--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customers_id_seq OWNED BY public.customers.id;


--
-- Name: entries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.entries (
    id integer NOT NULL,
    transaction_id integer NOT NULL,
    account_id integer NOT NULL,
    debit_amount numeric(12,2),
    credit_amount numeric(12,2),
    description character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.entries OWNER TO postgres;

--
-- Name: entries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.entries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entries_id_seq OWNER TO postgres;

--
-- Name: entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.entries_id_seq OWNED BY public.entries.id;


--
-- Name: export_configs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.export_configs (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    format public.exportformat NOT NULL,
    column_map json NOT NULL,
    created_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.export_configs OWNER TO postgres;

--
-- Name: export_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.export_configs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.export_configs_id_seq OWNER TO postgres;

--
-- Name: export_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.export_configs_id_seq OWNED BY public.export_configs.id;


--
-- Name: integration_sync_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integration_sync_logs (
    id integer NOT NULL,
    integration_type public.integrationtype NOT NULL,
    provider_name character varying(50) NOT NULL,
    status public.syncstatus NOT NULL,
    records_processed integer,
    records_created integer,
    records_updated integer,
    records_failed integer,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    entity_type character varying(50),
    error_message text,
    log_data json,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.integration_sync_logs OWNER TO postgres;

--
-- Name: integration_sync_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.integration_sync_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.integration_sync_logs_id_seq OWNER TO postgres;

--
-- Name: integration_sync_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.integration_sync_logs_id_seq OWNED BY public.integration_sync_logs.id;


--
-- Name: invoice_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_items (
    id integer NOT NULL,
    invoice_id integer NOT NULL,
    description character varying(255) NOT NULL,
    quantity integer NOT NULL,
    price numeric(12,2) NOT NULL,
    tax_rate numeric(5,2),
    subtotal numeric(12,2) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    product_id integer
);


ALTER TABLE public.invoice_items OWNER TO postgres;

--
-- Name: invoice_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoice_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.invoice_items_id_seq OWNER TO postgres;

--
-- Name: invoice_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_items_id_seq OWNED BY public.invoice_items.id;


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoices (
    id integer NOT NULL,
    invoice_number character varying(20) NOT NULL,
    order_id integer,
    customer_id integer,
    status public.invoicestatus NOT NULL,
    issue_date date,
    due_date date,
    total_amount numeric(12,2) NOT NULL,
    tax_amount numeric(12,2),
    subtotal_amount numeric(12,2),
    billing_name character varying(100),
    billing_address character varying(200),
    billing_city character varying(100),
    billing_postal_code character varying(20),
    billing_country character varying(100),
    billing_email character varying(120),
    company_code character varying(50),
    vat_code character varying(50),
    notes text,
    payment_details text,
    pdf_url character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.invoices OWNER TO postgres;

--
-- Name: invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.invoices_id_seq OWNER TO postgres;

--
-- Name: invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoices_id_seq OWNED BY public.invoices.id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    id integer NOT NULL,
    order_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    price numeric(12,2) NOT NULL,
    tax_rate numeric(5,2),
    discount_amount numeric(12,2),
    variant_info json,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.order_items OWNER TO postgres;

--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.order_items_id_seq OWNER TO postgres;

--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    order_number character varying(20) NOT NULL,
    customer_id integer,
    status public.orderstatus NOT NULL,
    total_amount numeric(12,2) NOT NULL,
    tax_amount numeric(12,2),
    shipping_amount numeric(12,2),
    discount_amount numeric(12,2),
    shipping_name character varying(100),
    shipping_address character varying(200),
    shipping_city character varying(100),
    shipping_postal_code character varying(20),
    shipping_country character varying(100),
    shipping_phone character varying(20),
    shipping_email character varying(120),
    payment_method character varying(50),
    payment_reference character varying(100),
    shipping_method character varying(50),
    tracking_number character varying(100),
    notes text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    shipped_at timestamp without time zone
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.orders_id_seq OWNER TO postgres;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    id integer NOT NULL,
    sku character varying(50) NOT NULL,
    name character varying(200) NOT NULL,
    description_html text,
    barcode character varying(50),
    quantity integer,
    delivery_days smallint,
    price_final numeric(12,2) NOT NULL,
    price_old numeric(12,2),
    category character varying(100),
    main_image_url character varying(255),
    extra_image_urls json,
    model character varying(100),
    manufacturer character varying(100),
    warranty_months smallint,
    weight_kg numeric(8,3),
    parameters json,
    variants json,
    delivery_options json,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.products OWNER TO postgres;

--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.products_id_seq OWNER TO postgres;

--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: shipment_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shipment_items (
    id integer NOT NULL,
    shipment_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    cost_price numeric(12,2),
    notes character varying(255)
);


ALTER TABLE public.shipment_items OWNER TO postgres;

--
-- Name: shipment_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shipment_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shipment_items_id_seq OWNER TO postgres;

--
-- Name: shipment_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shipment_items_id_seq OWNED BY public.shipment_items.id;


--
-- Name: shipments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shipments (
    id integer NOT NULL,
    shipment_number character varying(50) NOT NULL,
    supplier character varying(100),
    expected_date date,
    arrival_date date,
    status public.shipmentstatus NOT NULL,
    notes text,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.shipments OWNER TO postgres;

--
-- Name: shipments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shipments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shipments_id_seq OWNER TO postgres;

--
-- Name: shipments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shipments_id_seq OWNED BY public.shipments.id;


--
-- Name: stock_movements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stock_movements (
    id integer NOT NULL,
    product_id integer NOT NULL,
    qty_delta integer NOT NULL,
    reason_code public.movementreasoncode NOT NULL,
    note character varying(255),
    channel character varying(50),
    reference_id character varying(50),
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.stock_movements OWNER TO postgres;

--
-- Name: stock_movements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.stock_movements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.stock_movements_id_seq OWNER TO postgres;

--
-- Name: stock_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.stock_movements_id_seq OWNED BY public.stock_movements.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tasks (
    id integer NOT NULL,
    title character varying(100) NOT NULL,
    description text,
    customer_id integer NOT NULL,
    status character varying(20),
    priority character varying(20),
    due_date timestamp without time zone,
    assigned_to integer,
    created_by integer NOT NULL,
    completed_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.tasks OWNER TO postgres;

--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tasks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tasks_id_seq OWNER TO postgres;

--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transactions (
    id integer NOT NULL,
    date date NOT NULL,
    reference_type character varying(50) NOT NULL,
    reference_id character varying(50) NOT NULL,
    description character varying(255),
    total_amount numeric(12,2) NOT NULL,
    is_posted boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.transactions OWNER TO postgres;

--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transactions_id_seq OWNER TO postgres;

--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(64),
    email character varying(120),
    password_hash character varying(128),
    is_active boolean,
    is_admin boolean,
    last_login timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying(100) NOT NULL,
    preferences jsonb
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- Name: company_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_settings ALTER COLUMN id SET DEFAULT nextval('public.company_settings_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: customers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers ALTER COLUMN id SET DEFAULT nextval('public.customers_id_seq'::regclass);


--
-- Name: entries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entries ALTER COLUMN id SET DEFAULT nextval('public.entries_id_seq'::regclass);


--
-- Name: export_configs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.export_configs ALTER COLUMN id SET DEFAULT nextval('public.export_configs_id_seq'::regclass);


--
-- Name: integration_sync_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integration_sync_logs ALTER COLUMN id SET DEFAULT nextval('public.integration_sync_logs_id_seq'::regclass);


--
-- Name: invoice_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_items ALTER COLUMN id SET DEFAULT nextval('public.invoice_items_id_seq'::regclass);


--
-- Name: invoices id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices ALTER COLUMN id SET DEFAULT nextval('public.invoices_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: shipment_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shipment_items ALTER COLUMN id SET DEFAULT nextval('public.shipment_items_id_seq'::regclass);


--
-- Name: shipments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shipments ALTER COLUMN id SET DEFAULT nextval('public.shipments_id_seq'::regclass);


--
-- Name: stock_movements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stock_movements ALTER COLUMN id SET DEFAULT nextval('public.stock_movements_id_seq'::regclass);


--
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- Name: transactions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts (id, code, name, account_type, description, is_active, created_at, updated_at) FROM stdin;
1	1000	Cash	asset	\N	t	2025-05-13 22:57:27.821936	2025-05-13 22:57:27.821939
2	1200	Accounts Receivable	asset	\N	t	2025-05-13 22:57:27.824494	2025-05-13 22:57:27.824498
3	1300	Inventory	asset	\N	t	2025-05-13 22:57:27.827438	2025-05-13 22:57:27.827442
4	2000	Accounts Payable	liability	\N	t	2025-05-13 22:57:27.829281	2025-05-13 22:57:27.829286
5	2200	VAT Payable	liability	\N	t	2025-05-13 22:57:27.831853	2025-05-13 22:57:27.831856
6	3000	Equity	equity	\N	t	2025-05-13 22:57:27.834605	2025-05-13 22:57:27.83461
7	4000	Sales Revenue	revenue	\N	t	2025-05-13 22:57:27.837184	2025-05-13 22:57:27.837188
8	5000	Cost of Goods Sold	expense	\N	t	2025-05-13 22:57:27.840279	2025-05-13 22:57:27.840283
9	6000	Operating Expenses	expense	\N	t	2025-05-13 22:57:27.841999	2025-05-13 22:57:27.842002
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alembic_version (version_num) FROM stdin;
21f64bedab47
\.


--
-- Data for Name: company_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.company_settings (id, name, address, city, postal_code, country, phone, email, company_code, vat_code, bank_name, bank_account, bank_swift, created_at, updated_at) FROM stdin;
1	LT CRM	Gedimino pr. 1	Vilnius	01103	Lietuva	+370 600 00000	info@ltcrm.lt	123456789	LT123456789	SEB bankas	LT123456789012345678	CBVILT2X	2025-05-15 08:17:03.50115	2025-05-15 08:17:03.50115
\.


--
-- Data for Name: contacts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contacts (id, customer_id, name, "position", email, phone, is_primary, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customers (id, name, email, phone, company, address, city, country, status, source, notes, assigned_to, created_at, updated_at) FROM stdin;
1	Jonas Jonaitis	demo@example.lt	+37060012345	UAB Demo Įmonė	Gedimino pr. 1	Vilnius	Lithuania	active	\N	VAT code: LT123456789	\N	2025-05-13 22:57:57.672693	2025-05-13 22:57:57.672696
2	Andrius	wimass@gmail.com	07825794207	\N	6 Ashwell Close	London	Lietuva	active	\N	\N	\N	2025-05-14 20:22:02.967293	2025-05-14 20:22:02.967296
3	Andrius	andrius.stiega@live.com	07825794207	\N	6 Ashwell Close	London	Lietuva	active	\N	\N	\N	2025-05-15 10:20:51.221866	2025-05-15 10:20:51.221868
\.


--
-- Data for Name: entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.entries (id, transaction_id, account_id, debit_amount, credit_amount, description, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: export_configs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.export_configs (id, name, format, column_map, created_by_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: integration_sync_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.integration_sync_logs (id, integration_type, provider_name, status, records_processed, records_created, records_updated, records_failed, started_at, completed_at, entity_type, error_message, log_data, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: invoice_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.invoice_items (id, invoice_id, description, quantity, price, tax_rate, subtotal, created_at, updated_at, product_id) FROM stdin;
1	3	Kajakas - Baidarė, Galaxy Kayaks, Ranger	1	569.00	21.00	569.00	2025-05-14 20:11:23.19496	2025-05-14 20:11:23.194963	72
2	3	Kajakas - Baidarė, Galaxy Kayaks, Tahiti Tandem 2+1	1	969.00	21.00	969.00	2025-05-14 20:11:23.194964	2025-05-14 20:11:23.194964	48
3	4	Kajako, Baidarės transportavimo ratukai C-TUG Railblaza	1	159.00	21.00	159.00	2025-05-14 22:01:13.623172	2025-05-14 22:01:13.623175	75
4	4	NRS Ambient PFD - Universali Gelbėjimosi liemenė M/L	1	99.00	21.00	99.00	2025-05-14 22:01:13.623175	2025-05-14 22:01:13.623175	61
5	9	Džiugas sūris (12 mėn)	1	15.99	0.00	15.99	2025-05-15 11:30:31.293265	2025-05-15 11:30:31.293267	7
6	9	Kajakas - Baidarė, Galaxy Kayaks, Ranger	1	569.00	0.00	569.00	2025-05-15 11:30:31.297754	2025-05-15 11:30:31.297756	72
7	9	Lietuviškas liepų medus	1	8.99	0.00	8.99	2025-05-15 11:30:31.29954	2025-05-15 11:30:31.299541	9
\.


--
-- Data for Name: invoices; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.invoices (id, invoice_number, order_id, customer_id, status, issue_date, due_date, total_amount, tax_amount, subtotal_amount, billing_name, billing_address, billing_city, billing_postal_code, billing_country, billing_email, company_code, vat_code, notes, payment_details, pdf_url, created_at, updated_at) FROM stdin;
2	LT-INV-00001	1	1	ISSUED	2025-05-14	2025-05-28	29.97	5.20	24.77	Jonas Jonaitis	Gedimino pr. 1	Vilnius	01103	Lithuania	demo@example.lt	\N	\N	Sąskaita faktūra sukurta iš užsakymo LT-ORD-001	\N	\N	2025-05-14 19:28:15.106397	2025-05-14 19:30:25.774379
3	LT-INV-00002	2	1	ISSUED	2025-05-14	2025-05-28	1860.98	322.98	1538.00	Jonas Jonaitis	Gedimino pr. 1	Vilnius	01103	Lithuania	demo@example.lt	None	None	Sąskaita faktūra sukurta iš užsakymo LT-ORD-002	None	\N	2025-05-14 19:52:41.937577	2025-05-14 20:11:29.483217
4	LT-INV-00003	3	2	ISSUED	2025-05-14	2025-05-28	312.18	54.18	258.00	Andrius	6 Ashwell Close	London	E6 5RS	Lietuva	wimass@gmail.com	None	None	Sąskaita faktūra sukurta iš užsakymo ORD-00003	None	\N	2025-05-14 20:49:09.113544	2025-05-14 22:01:13.616438
6	LT-INV-00005	7	3	ISSUED	2025-05-15	2025-05-29	30.00	0.00	30.00	Andrius	6 Ashwell Close	London	E6 5RS	Lietuva	andrius.stiega@live.com	\N	\N	Sąskaita faktūra sukurta iš užsakymo ORD-00043	\N	\N	2025-05-15 10:47:34.921421	2025-05-15 10:47:39.380672
8	LT-INV-00006	4	3	ISSUED	2025-05-15	2025-05-29	30.00	0.00	30.00	Andrius	6 Ashwell Close	London	E6 5RS	Lietuva	andrius.stiega@live.com	\N	\N	Sąskaita faktūra sukurta iš užsakymo ORD-00004	\N	\N	2025-05-15 11:21:19.662167	2025-05-15 11:21:34.946318
9	LT-INV-00007	8	3	ISSUED	2025-05-15	2025-05-29	593.98	0.00	593.98	Andrius	6 Ashwell Close	London	E6 5RS	Anglija	andrius.stiega@live.com	\N	\N	Sąskaita faktūra sukurta iš užsakymo ORD-00044	\N	\N	2025-05-15 11:30:31.282559	2025-05-15 11:30:35.745041
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_items (id, order_id, product_id, quantity, price, tax_rate, discount_amount, variant_info, created_at, updated_at) FROM stdin;
1	1	6	2	3.99	21.00	\N	\N	2025-05-13 22:57:57.692811	2025-05-13 22:57:57.692815
2	1	8	3	2.49	21.00	\N	\N	2025-05-13 22:57:57.692816	2025-05-13 22:57:57.692816
3	2	7	1	15.99	21.00	\N	\N	2025-05-13 22:57:57.698271	2025-05-13 22:57:57.698274
4	2	9	1	8.99	21.00	\N	\N	2025-05-13 22:57:57.698275	2025-05-13 22:57:57.698275
5	3	72	1	569.00	\N	\N	\N	2025-05-14 20:22:02.97637	2025-05-14 20:22:02.976373
6	3	64	1	149.00	\N	\N	\N	2025-05-14 20:22:02.976374	2025-05-14 20:22:02.976374
7	4	82	1	30.00	\N	\N	\N	2025-05-15 10:20:51.230308	2025-05-15 10:20:51.23031
10	7	82	1	30.00	\N	\N	\N	2025-05-15 10:35:59.017217	2025-05-15 10:35:59.017219
11	8	7	1	15.99	\N	\N	\N	2025-05-15 11:30:28.112016	2025-05-15 11:30:28.112019
12	8	72	1	569.00	\N	\N	\N	2025-05-15 11:30:28.11202	2025-05-15 11:30:28.11202
13	8	9	1	8.99	\N	\N	\N	2025-05-15 11:30:28.11202	2025-05-15 11:30:28.112021
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orders (id, order_number, customer_id, status, total_amount, tax_amount, shipping_amount, discount_amount, shipping_name, shipping_address, shipping_city, shipping_postal_code, shipping_country, shipping_phone, shipping_email, payment_method, payment_reference, shipping_method, tracking_number, notes, created_at, updated_at, shipped_at) FROM stdin;
1	LT-ORD-001	1	SHIPPED	29.97	5.20	5.99	\N	Jonas Jonaitis	Gedimino pr. 1	Vilnius	01103	Lithuania	+37060012345	demo@example.lt	credit_card	\N	courier	LT1234567890	\N	2025-05-13 22:57:57.685875	2025-05-13 22:57:57.685877	\N
2	LT-ORD-002	1	PAID	24.98	4.33	0.00	\N	Jonas Jonaitis	Gedimino pr. 1	Vilnius	01103	Lithuania	+37060012345	demo@example.lt	bank_transfer	\N	pickup	\N	\N	2025-05-13 22:57:57.690853	2025-05-14 19:52:26.455407	\N
3	ORD-00003	2	NEW	719.00	0.00	1.00	\N	Andrius	6 Ashwell Close	London	E6 5RS	Lietuva	07825794207	wimass@gmail.com	\N	\N	dpd	\N		2025-05-14 20:22:02.973118	2025-05-14 20:22:02.973121	\N
7	ORD-00043	3	SHIPPED	30.00	0.00	0.00	\N	Andrius	6 Ashwell Close	London	E6 5RS	Lietuva	07825794207	andrius.stiega@live.com	credit_card	\N	dpd	A12669519651		2025-05-15 10:35:59.014514	2025-05-15 10:55:08.685614	2025-05-15 10:42:35.181512
4	ORD-00004	3	PAID	30.00	0.00	0.00	\N	Andrius	6 Ashwell Close	London	E6 5RS	Lietuva	07825794207	andrius.stiega@live.com	\N	\N	omniva	\N		2025-05-15 10:20:51.226362	2025-05-15 11:12:35.086603	\N
8	ORD-00044	3	SHIPPED	593.98	0.00	0.00	\N	Andrius	6 Ashwell Close	London	E6 5RS	Anglija	07825794207	andrius.stiega@live.com	\N	\N	omniva	\N		2025-05-15 11:30:28.104687	2025-05-15 11:31:24.478913	2025-05-15 11:31:24.477052
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (id, sku, name, description_html, barcode, quantity, delivery_days, price_final, price_old, category, main_image_url, extra_image_urls, model, manufacturer, warranty_months, weight_kg, parameters, variants, delivery_options, created_at, updated_at) FROM stdin;
78	GKAN-101-10205-0271	Kajako užkelimo priemonė ant stogo	<h3><strong>Galaxy Kajakų Pakrovimo Volelis &ndash; lengvesnis būdas pakrauti kajaką ar baidarę ant automobilio stogo</strong></h3>\n<p><strong>Su Galaxy kajakų voleliu jūsų kajako ar baidarės pakrovimas tampa paprastesnis ir saugesnis.</strong></p>\n<p><strong>Kaip naudoti:</strong></p>\n<ol>\n<li>\n<p>Prisegkite volelį prie galinio automobilio stiklo.</p>\n</li>\n<li>\n<p>Uždėkite kajako priekį ant ritinėlio.</p>\n</li>\n<li>\n<p>Pastumkite kajaką ant automobilio stogo bagažinės.</p>\n</li>\n</ol>\n<p>&Scaron;is volelis ne tik&nbsp;<strong>palengvina pakrovimo procesą</strong>, bet ir&nbsp;<strong>apsaugo automobilio pavir&scaron;ių nuo pažeidimų</strong>. Nereikalauja sunkaus kėlimo ar papildomų įrankių.</p>\n<p>Tinka&nbsp;<strong>visiems automobilių tipams</strong>. Įsigykite ir supaprastinkite kajakų transportavimą!</p>\n<p><strong>Specifikacijos:</strong></p>\n<ul>\n<li>\n<p><strong>Svoris:</strong>&nbsp;1,3 kg</p>\n</li>\n<li>\n<p><strong>Maksimali apkrova:</strong>&nbsp;100 kg</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>Pastaba:</strong>&nbsp;Prekių nuotraukos yra informacinio pobūdžio ir gali skirtis nuo faktinės komplektacijos.</p>	8436618812940	5	2	55.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1732362696772-boat-roller-b.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1732362949960-05c29a69-277b-411c-bd0c-bb236ec21504.f746a14ed193c2b880a26867951e7f55.jpeg.webp | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1732363060215-71JP2I4AOuL._AC_SL1500_.jpg"	Boat Roller	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.551733	2025-05-15 10:29:23.819344
7	LT-SURIS-01	Džiugas sūris (12 mėn)	<p>Ilgai brandintas lietuviškas kietasis sūris.</p>	4750010005678	29	5	15.99	17.99	Pieno produktai	\N	\N	\N	Džiugas	\N	0.500	{"fat_percentage": "40%", "aging": "12 months"}	\N	\N	2025-05-13 22:57:57.663879	2025-05-15 11:31:24.494979
9	LT-MED-01	Lietuviškas liepų medus	<p>Natūralus liepų žiedų medus iš Lietuvos bitynų.</p>	4750010002345	24	4	8.99	\N	Bitininkystės produktai	\N	\N	\N	Lietuvos Bitininkai	\N	0.500	{"type": "liep\\u0173 \\u017eied\\u0173", "region": "Dz\\u016bkija"}	\N	\N	2025-05-13 22:57:57.6671	2025-05-15 11:31:24.521489
8	LT-GIRA-01	Naminio skonio gira	<p>Natūraliai fermentuota gira pagal tradicinį receptą.</p>	4750010009876	100	2	2.49	\N	Gėrimai	\N	\N	\N	Gubernija	\N	1.500	{"volume": "1.5L", "ingredients": "vanduo, rugiai, cukrus, miel\\u0117s"}	\N	\N	2025-05-13 22:57:57.665463	2025-05-13 22:57:57.665464
6	LT-DUONA-01	Juoda ruginė duona	<h3><strong>RAILBLAZA Camera Boom 600 R-Lock &ndash; užfiksuokite kiekvieną akimirką i&scaron; tobuliausio kampo!</strong></h3>\n<p>&nbsp;</p>\n<p><strong>RAILBLAZA Camera Boom 600 R-Lock</strong> &ndash; tai <strong>inovatyvus ir universalus kameros laikiklis</strong>, leidžiantis <strong>lengvai užfiksuoti įspūdingiausias akimirkas</strong> ant vandens. Su <strong>750 mm ilgio reguliuojama strėle ir 4 reguliuojamais jungties ta&scaron;kais</strong>, galėsite nufotografuoti ar nufilmuoti veiksmą i&scaron; <strong>bet kurio kampo</strong>, be papildomos įrangos.</p>	4750010001234	50	3	3.99	\N	Duonos gaminiai	\N	\N	\N	Vilniaus Duona	\N	0.800	{"ingredients": "ruginiai miltai, vanduo, druska, raugas"}	\N	\N	2025-05-13 22:57:57.660715	2025-05-14 21:36:15.428907
42	KR21-MC	Kajakas - Baidarė, Galaxy Kayaks, Fuego	<h2><strong>Atraskite naująjį Fuego kajaką &ndash; komforto ir saugumo garantiją!</strong></h2>\n<p>&nbsp;</p>\n<p>Fuego yra&nbsp;<strong>stabiliausias ir patogiausias</strong>&nbsp;kajakas mūsų asortimente, sukurtas užtikrinti puikią ir saugią plaukimo patirtį. Jo a&scaron;trūs kampai, platus korpusas ir didelė kilio dimensija suteikia neprilygstamą stabilumą, todėl jis puikiai tinka&nbsp;<strong>lengvoms ir vidutinėms sąlygoms</strong>, o ypač pradedantiesiems.</p>\n<p>Kajakas turi&nbsp;<strong>vieną centrinį skyrių</strong>, kuris ne tik suteikia daug vietos daiktams susidėti, bet ir užtikrina daugiau vietos kojoms. Kompakti&scaron;kas dizainas leidžia Fuego&nbsp;<strong>lengvai transportuoti ir sandėliuoti</strong>, todėl tai puikus pasirinkimas miesto gyventojams ar tiems, kurie turi ribotą saugojimo vietą.</p>\n<p>&nbsp;</p>\n<h3><strong>Pilnai sukomplektuotas nuotykiams</strong></h3>\n<p>Fuego kajakas&nbsp;<strong>paruo&scaron;tas naudoti i&scaron; karto</strong>&nbsp;&ndash; jis parduodamas kartu su&nbsp;<strong>sėdyne, irklu ir nauja itin patvaria gelbėjimo virvele</strong>. Galaxy HV serijos&trade; modeliuose yra trijų spalvų&nbsp;<strong>gelbėjimo virvės</strong>:&nbsp;<strong>oranžinė, balta ir juoda</strong>, kad galėtumėte pasirinkti sau tinkamiausią. Priekinė ir galinė laikymo zonos aprūpintos&nbsp;<strong>trijų spalvų tampriais bungee dirželiais</strong>, užtikrinančiais saugų daiktų pritvirtinimą.</p>\n<p>&nbsp;</p>\n<h3><strong>Fuego HV kajako komplektacija:</strong></h3>\n<ul>\n<li>\n<p>Tvirta gelbėjimo virvė&nbsp;(juoda, balta arba oranžinė)</p>\n</li>\n<li>\n<p>Priekinė ir galinė laikymo zonos&nbsp;su bungee dirželiais (juoda, balta arba oranžinė)</p>\n</li>\n<li>\n<p>Identifikacinė plok&scaron;telė</p>\n</li>\n<li>\n<p>Vienas didelis centrinis skyrius&nbsp;su apsauginiu mai&scaron;eliu</p>\n</li>\n<li>\n<p>Keturi drenažo ta&scaron;kai&nbsp;su&nbsp;keturiais skysčio nutekėjimo kam&scaron;čiais</p>\n</li>\n<li>\n<p>Rankenos priekyje, gale ir &scaron;onuose&nbsp;bei&nbsp;du irklų laikikliai</p>\n</li>\n<li>\n<p>Penki formuoti pėdų atramos lygiai&nbsp;ir&nbsp;dvylika D formos tvirtinimo žiedų</p>\n</li>\n<li>\n<p>Auk&scaron;čiausios kokybės patogi sėdynė&nbsp;su&nbsp;integruota galine laikymo vieta</p>\n</li>\n<li>\n<p>Dviejų dalių lengvas aliumininis irklas</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<h3><strong>Specifikacijos:</strong></h3>\n<p>✔&nbsp;<strong>Ilgis:</strong>&nbsp;286 cm<br />✔&nbsp;<strong>Plotis:</strong>&nbsp;77.5 cm<br />✔&nbsp;<strong>Auk&scaron;tis:</strong>&nbsp;38.5 cm<br />✔&nbsp;<strong>Bendras svoris:</strong>&nbsp;26 kg<br />✔&nbsp;<strong>Grynas svoris:</strong>&nbsp;24 kg<br />✔&nbsp;<strong>Maksimali apkrova:</strong>&nbsp;140 kg<br />✔&nbsp;<strong>Rekomenduojamas naudotojo svoris:</strong>&nbsp;iki 105 kg<br />✔&nbsp;<strong>Maksimalus na&scaron;umo svoris:</strong>&nbsp;126 kg</p>\n<p>Pasirinkite&nbsp;<strong>Fuego kajaką</strong>&nbsp;ir mėgaukitės nepriekai&scaron;tinga plaukimo patirtimi! 🚣🔥</p>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/K7YjsrRjcms?si=IzkQNV33h79toEwy" width="640" height="480" data-mce-fragment="1"></iframe></div>\n<h3><strong>Kodėl verta rinktis Galaxy Kayaks?</strong></h3>\n<p>✔&nbsp;Daugiau nei 30 000 parduotų kajakų visoje Europoje<br />✔&nbsp;Daugybė teigiamų klientų atsiliepimų<br />✔&nbsp;Publikuojami žymiausiuose Europos vandens sporto žurnaluose<br />✔&nbsp;CE sertifikatas&nbsp;ir&nbsp;2 metų garantija korpusui</p>\n<p>&nbsp;</p>\n<h3><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></h3>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>\n<p>&nbsp;</p>\n<p>Rekomenduojama gelbėjimosi liemenė (spausti ant teksto):&nbsp;<a href="https://vakasport.lt/nrs-chinook-fishing-pfd-zvejybine-gelbejimosi-liemene" rel="noopener noreferrer nofollow"><strong>NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė</strong></a></p>	8436618810403	2	2	489.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737141379684-A7M03168.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239029445-A7M03169.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239029446-A7M03170.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239029446-A7M03171.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239029446-A7M03172.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239029447-A7M03173.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737141379682-A7M03162.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737141379683-A7M03163.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737141379683-A7M03164.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737141379683-A7M03165.jpg"	Fuego	\N	\N	26.000	\N	\N	\N	2025-05-14 18:59:18.492724	2025-05-15 10:30:58.639204
11	PL2540R	Plūdrumą palaikanti liemenė, 25-40 kg	<p>UNIVERSALI Vaiki&scaron;ka gelbėjimosi liemenė 25-40kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL2540</li>\n<li>Dydis: kūno svoris 25-40kg, krūtinės apimtis 56-70cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Apatiniai tarpkojo dirželiai skirti optimaliam saugumui užtikrinti ir fiksuojami fiksatoriais</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis</li>\n<li>Spalvos &ndash; raudona, žydra, salotinė, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607653	10	2	33.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944325-pludruma-palaikanti-liemene-25-40-kg-45074_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944323-pludruma-palaikanti-liemene-25-40-kg-3bd3d-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944322-pludruma-palaikanti-liemene-25-40-kg-1a229-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944324-pludruma-palaikanti-liemene-25-40-kg-014a5-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.428931	2025-05-14 21:46:07.161719
12	PL2540M	Plūdrumą palaikanti liemenė, 25-40 kg	<p>UNIVERSALI Vaiki&scaron;ka gelbėjimosi liemenė 25-40kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL2540</li>\n<li>Dydis: kūno svoris 25-40kg, krūtinės apimtis 56-70cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Apatiniai tarpkojo dirželiai skirti optimaliam saugumui užtikrinti ir fiksuojami fiksatoriais</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis</li>\n<li>Spalvos &ndash; raudona, žydra, salotinė, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607660	10	2	33.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944326-pludruma-palaikanti-liemene-25-40-kg-f40a9_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944325-pludruma-palaikanti-liemene-25-40-kg-45b0d-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944324-pludruma-palaikanti-liemene-25-40-kg-23ae3-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944325-pludruma-palaikanti-liemene-25-40-kg-39bfc-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.436498	2025-05-14 21:46:07.165398
13	PL2540Z	Plūdrumą palaikanti liemenė, 25-40 kg	<p>UNIVERSALI Vaiki&scaron;ka gelbėjimosi liemenė 25-40kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL2540</li>\n<li>Dydis: kūno svoris 25-40kg, krūtinės apimtis 56-70cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Apatiniai tarpkojo dirželiai skirti optimaliam saugumui užtikrinti ir fiksuojami fiksatoriais</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis</li>\n<li>Spalvos &ndash; raudona, žydra, salotinė, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607677	10	2	33.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944323-pludruma-palaikanti-liemene-25-40-kg-8b90d_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944324-pludruma-palaikanti-liemene-25-40-kg-09b1f-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944326-pludruma-palaikanti-liemene-25-40-kg-e467e-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944326-pludruma-palaikanti-liemene-25-40-kg-e363d-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.438372	2025-05-14 21:46:07.167855
14	PL2540C	Plūdrumą palaikanti liemenė, 25-40 kg	<p>UNIVERSALI Vaiki&scaron;ka gelbėjimosi liemenė 25-40kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL2540</li>\n<li>Dydis: kūno svoris 25-40kg, krūtinės apimtis 56-70cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Apatiniai tarpkojo dirželiai skirti optimaliam saugumui užtikrinti ir fiksuojami fiksatoriais</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis</li>\n<li>Spalvos &ndash; raudona, žydra, salotinė, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607684	10	2	34.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944326-pludruma-palaikanti-liemene-25-40-kg-a1e8c_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944325-pludruma-palaikanti-liemene-25-40-kg-33b35-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944324-pludruma-palaikanti-liemene-25-40-kg-28c66-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962944326-pludruma-palaikanti-liemene-25-40-kg-c2d81-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.440474	2025-05-14 21:46:07.170041
53	A-SP-K-10205-0242	Universali Sėdynė kajakui ar irklentei	<p data-pm-slice="1 1 []">&Scaron;i patogi sėdynė yra patvari ir pagaminta i&scaron; auk&scaron;tos kokybės medžiagų. Ji yra atspari UV spinduliams, o tai rei&scaron;kia ilgesnį sėdynės tarnavimo laiką tiems, kurie dažnai ją naudoja. Tankus neopreno putų sluoksnis yra sukurtas tam, kad toleruotų nuolatinę drėgmę, bet nesumažintų sėdynės komforto.</p>\n<p>Sėdynę lengva prijungti prie daugumos sit-on-top kajakų, baidarų ar irklenčių, naudojant kabliukus, kurie pritvirtinami prie jūsų baidarės ar kajako D formos žiedų. Taip pat yra reguliuojami diržai, kad sėdynę būtų galima pritaikyti pagal jūsų kūno dydį ir pageidavimus.</p>\n<p>&nbsp;</p>\n<p><strong>Techninė informacija</strong></p>\n<p>Medžiaga - tankus putų sluoksnis ir austinis plastikas</p>\n<p>Matmenys:</p>\n<ul>\n<li>\n<p>nugara 50cm x 45cm,</p>\n</li>\n<li>\n<p>sėdynė 30cm x 36cm</p>\n</li>\n<li>\n<p>Svoris: 1,2kg</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>Savybės:</strong></p>\n<ul>\n<li>\n<p>30mm tankus putplastis suteikia patogumą</p>\n</li>\n<li>\n<p>4 reguliuojami diržai, kad galėtumėte prisitaikyti prie savo kūno dydžio ir svorio</p>\n</li>\n<li>\n<p>4 sagtys, kad galėtumėte lengvai prijungti kėdę prie jūsų kajako</p>\n<p>&nbsp;</p>\n</li>\n<li>\n<p>Ilgaamžė ir atspari UV spinduliams</p>\n</li>\n<li>\n<p>Lengvai pritvirtinamas prie daugumos kajakų naudojant D žiedus</p>\n<p>&nbsp;</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</p>\n<p>&nbsp;</p>	8436618811561	5	2	35.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1725436598615-sp-sup-40_setup_big.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727286307643-premium-comfort-seat.jpg"	\N	\N	\N	\N	\N	\N	\N	2025-05-14 18:59:18.512884	2025-05-14 21:46:07.263524
72	KP-KR34-MC	Kajakas - Baidarė, Galaxy Kayaks, Ranger	<h3><strong>Galaxy Kayaks &bdquo;Ranger&ldquo; &ndash; stabilus, kompakti&scaron;kas ir varikliui pritaikytas kajakas tikriems nuotykių ie&scaron;kotojams</strong></h3>\n<p>&nbsp;</p>\n<p>Ie&scaron;kote&nbsp;<strong>stabilaus</strong>,&nbsp;<strong>lengvai transportuojamo</strong>&nbsp;ir&nbsp;<strong>universalios paskirties</strong>&nbsp;kajako su galimybe naudoti variklį?&nbsp;<strong>Galaxy Kayaks &bdquo;Ranger&ldquo;</strong>&nbsp;&ndash; tai būtent tas pasirinkimas, kuris jus nustebins.</p>\n<p>Su vos&nbsp;<strong>200 cm ilgiu</strong>&nbsp;ir&nbsp;<strong>98 cm pločiu</strong>, &bdquo;Ranger&ldquo; pasižymi&nbsp;<strong>trumpa ir plataus korpuso konstrukcija</strong>, kuri užtikrina&nbsp;<strong>auk&scaron;čiausią stabilumą ant vandens</strong>&nbsp;net ir sudėtingesnėmis oro sąlygomis. Tai ypač svarbu, kai planuojate naudoti&nbsp;<strong>pakabinamą variklį</strong>&nbsp;(parduodamas atskirai) ar&nbsp;<strong>gabenti didelį akumuliatorių</strong>&nbsp;&ndash; &scaron;iam tikslui gale integruota speciali dėžė (63,9 &times; 28,4 &times; 50 cm).</p>\n<p>&nbsp;</p>\n<h3><strong>Pagrindinės savybės:</strong></h3>\n<ul>\n<li>\n<p><strong>Itin stabili konstrukcija</strong>&nbsp;&ndash; trumpas ir platus korpusas puikiai laikosi net bangose</p>\n</li>\n<li>\n<p><strong>Pritaikytas varikliui</strong>&nbsp;&ndash; gale integruota talpykla pakabinamam varikliui ir akumuliatoriui</p>\n</li>\n<li>\n<p><strong>Lengva transportuoti</strong>&nbsp;&ndash; tilps tiek ant stogo bagažinės, tiek į didesnio automobilio bagažinę</p>\n</li>\n<li>\n<p><strong>Patogi sėdynė ir irklas komplekte</strong>&nbsp;&ndash; komfortas nuo pirmo plaukimo (<a href="https://vakasport.lt/auksta-sedyne" rel="noopener noreferrer nofollow">auk&scaron;ta sėdynė</a> &ndash; papildomai)</p>\n</li>\n<li>\n<p><strong>Universalus naudojimas</strong>&nbsp;&ndash; tinka tiek žvejybai, tiek poilsiui ar pakrančių tyrinėjimui</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<h3><strong>Idealiai tinka tiems, kurie:</strong></h3>\n<ul>\n<li>\n<p>Nori keliauti&nbsp;<strong>be priekabos ar specialios gabenimo įrangos</strong></p>\n</li>\n<li>\n<p>Vertina&nbsp;<strong>stabilumą ir kontrolę</strong>&nbsp;ant vandens</p>\n</li>\n<li>\n<p>Planuoja naudoti&nbsp;<strong>elektrinį variklį</strong>&nbsp;didesniems atstumams įveikti</p>\n</li>\n<li>\n<p>Ie&scaron;ko&nbsp;<strong>kompakti&scaron;ko</strong>, bet&nbsp;<strong>funkcionalaus kajako</strong>, tinkamo įvairioms sąlygoms</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<h3><strong>Specifikacija:</strong></h3>\n<ul>\n<li>\n<p><strong>Ilgis:</strong>&nbsp;200 cm</p>\n</li>\n<li>\n<p><strong>Plotis:</strong>&nbsp;98 cm</p>\n</li>\n<li>\n<p><strong>Auk&scaron;tis:</strong>&nbsp;38 cm</p>\n</li>\n<li>\n<p><strong>Svoris:</strong>&nbsp;24 kg</p>\n</li>\n<li>\n<p><strong>Rekomenduojamas krovinio svoris:</strong>&nbsp;150 kg</p>\n</li>\n<li>\n<p><strong>Maksimalus naudotojo svoris:</strong>&nbsp;110 kg</p>\n</li>\n<li>\n<p><strong>Akumuliatoriaus dėžės vidiniai matmenys:</strong>&nbsp;63,9 &times; 28,4 &times; 50 cm</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>Kam skirtas Galaxy Ranger?</strong><br />✔ Tiems, kas ie&scaron;ko lengvo, stabilaus ir motorui pritaikyto kajako<br />✔ Pradedantiesiems ir patyrusiems žvejams<br />✔ Žmonėms, norintiems tyrinėti pakrantes, ežerus ar upes<br />✔ Visiems, kuriems svarbus mobilumas, patikimumas ir paprastas naudojimas</p>\n<p>&nbsp;</p>\n<p><strong>Kas įtraukta į kainą?</strong><br />✔️ Patogi sėdynė<br />✔️ Itin ilgas irklas<br />✔️ Integruotas akumuliatoriaus ir variklio laikiklis<br />✔️ FatGrip&trade; tipo rankenos paprastam ne&scaron;imui<br />✔️ Uždaras galinis laikymo skyrius</p>\n<p>Pasiruo&scaron;ę atrasti naujas vandens vietas? Užsisakykite <em>Galaxy Ranger</em>jau &scaron;iandien!</p>\n<p>&nbsp;</p>\n<p>&nbsp;</p>\n<p><strong>Pastaba:</strong>&nbsp;Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</p>\n<h3><strong>SVARBU:</strong></h3>\n<p>Niekada nei&scaron;plaukite be&nbsp;<strong>gelbėjimosi liemenės</strong>&nbsp;ir&nbsp;<strong>tinkamos saugos įrangos</strong>. Pirkdami &bdquo;Galaxy Kayaks&ldquo; ar &bdquo;VAKA Sport&ldquo; gaminius,&nbsp;<strong>sutinkate</strong>, kad plaukimas kajakais, baidarėmis ar valtimis yra&nbsp;<strong>susijęs su rizika</strong>, įskaitant galimus sužalojimus ar mirtį. Jūs&nbsp;<strong>prisiimate atsakomybę</strong>&nbsp;už &scaron;ią riziką.</p>\n<p>Rekomenduojama gelbėjimosi liemenė (spausti ant teksto):&nbsp;<a href="https://vakasport.lt/nrs-chinook-fishing-pfd-zvejybine-gelbejimosi-liemene" rel="noopener noreferrer nofollow"><strong>NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė</strong></a></p>	8436618810281	1	3	569.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740125145929-A7M03400.jpg	"https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=1200,fit=scale-down/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740125145929-A7M03400.jpg | https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=1200,fit=scale-down/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740125145930-A7M03401.jpg | https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=1200,fit=scale-down/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740125145929-A7M03399.jpg | https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=1200,fit=scale-down/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740125145929-A7M03398.jpg | https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=1200,fit=scale-down/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239680734-A7M03402.jpg | https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=1200,fit=scale-down/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239680734-A7M03403.jpg | https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=1200,fit=scale-down/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239680734-A7M03404.jpg"	Ranger	\N	\N	24.000	\N	\N	\N	2025-05-14 18:59:18.543716	2025-05-15 11:31:24.511865
35	PL120140M	Plūdrumą palaikanti liemenė, 120-140 kg	<p>UNIVERSALI Gelbėjimosi liemenė 120-140kg WALLYS</p>\n<ul>\n<li>\n<p>Pagaminta Lietuvoje</p>\n</li>\n<li>\n<p>Atitinka ES standartą&nbsp;</p>\n</li>\n<li>\n<p>EN ISO 12402-5&nbsp;&nbsp;(50N)</p>\n</li>\n<li>\n<p>Plūdrumo liemenė.&nbsp;Mod. PL120140&nbsp;&nbsp;</p>\n</li>\n<li>\n<p>Dydis: kūno svoris 120-140kg, krūtinės apimtis 114-140cm</p>\n</li>\n<li>\n<p>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</p>\n</li>\n<li>\n<p>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</p>\n</li>\n<li>\n<p>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</p>\n</li>\n<li>\n<p>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</p>\n</li>\n<li>\n<p>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p>&nbsp;</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</p>\n<p>&nbsp;</p>	754436608391	10	2	65.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125853-pludruma-palaikanti-liemene-120-140-kg-melyna-39004_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125853-pludruma-palaikanti-liemene-120-140-kg-melyna-47abd-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125853-pludruma-palaikanti-liemene-120-140-kg-melyna-100ab-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125853-pludruma-palaikanti-liemene-120-140-kg-melyna-b42ad-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.480067	2025-05-14 21:46:07.219104
36	PL120140J	Plūdrumą palaikanti liemenė, 120-140 kg	<p>UNIVERSALI Gelbėjimosi liemenė 120-140kg WALLYS</p>\n<ul>\n<li>\n<p>Pagaminta Lietuvoje</p>\n</li>\n<li>\n<p>Atitinka ES standartą&nbsp;</p>\n</li>\n<li>\n<p>EN ISO 12402-5&nbsp;&nbsp;(50N)</p>\n</li>\n<li>\n<p>Plūdrumo liemenė.&nbsp;Mod. PL120140&nbsp;&nbsp;</p>\n</li>\n<li>\n<p>Dydis: kūno svoris 120-140kg, krūtinės apimtis 114-140cm</p>\n</li>\n<li>\n<p>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</p>\n</li>\n<li>\n<p>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</p>\n</li>\n<li>\n<p>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</p>\n</li>\n<li>\n<p>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</p>\n</li>\n<li>\n<p>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p>&nbsp;</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</p>\n<p>&nbsp;</p>	754436608407	10	2	65.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125852-pludruma-palaikanti-liemene-120-140-kg-juoda-9b166_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125853-pludruma-palaikanti-liemene-120-140-kg-juoda-e90fe-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125853-pludruma-palaikanti-liemene-120-140-kg-juoda-c7cea-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125852-pludruma-palaikanti-liemene-120-140-kg-juoda-a3cb2-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.481791	2025-05-14 21:46:07.221787
19	PL3050C	Plūdrumą palaikanti liemenė, 30-50 kg	<p>UNIVERSALI Vaiki&scaron;ka gelbėjimosi liemenė 30-50kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL3050</li>\n<li>Dydis: kūno svoris 30-50kg, krūtinės apimtis 65-84cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, žydra, juoda, raudona, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p><strong>&nbsp;</strong></p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p>&nbsp;</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607721	10	2	34.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326006-pludruma-palaikanti-liemene-30-50-kg-43e5d_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326008-pludruma-palaikanti-liemene-30-50-kg-cea76-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326004-pludruma-palaikanti-liemene-30-50-kg-1cdbf-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326005-pludruma-palaikanti-liemene-30-50-kg-5f170-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.449352	2025-05-14 21:46:07.182092
20	PL4060J	Plūdrumą palaikanti liemenė, 40-60 kg	<p>UNIVERSALI Gelbėjimosi liemenė 40-60kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL4060</li>\n<li>Dydis: kūno svoris 40-60kg, krūtinės apimtis 70-94cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</li>\n</ul>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p>&nbsp;</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607738	10	2	35.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962642358-pludruma-palaikanti-liemene-40-60-kg-b5bf1_reference.webp	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962642357-pludruma-palaikanti-liemene-40-60-kg-45dcd-atsiliepimai_reference.webp | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962642357-pludruma-palaikanti-liemene-40-60-kg-587b9-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962642359-pludruma-palaikanti-liemene-40-60-kg-d4f4f-internetu_reference.webp"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.450918	2025-05-14 21:46:07.184656
21	PL4060M	Plūdrumą palaikanti liemenė, 40-60 kg	<p>UNIVERSALI Gelbėjimosi liemenė 40-60kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL4060</li>\n<li>Dydis: kūno svoris 40-60kg, krūtinės apimtis 70-94cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</li>\n</ul>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p>&nbsp;</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607745	10	2	35.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962642355-pludruma-palaikanti-liemene-40-60-kg-7b521_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962642358-pludruma-palaikanti-liemene-40-60-kg-c0a56-atsiliepimai_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962642356-pludruma-palaikanti-liemene-40-60-kg-9b413-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962642356-pludruma-palaikanti-liemene-40-60-kg-8e53a-internetu_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.453121	2025-05-14 21:46:07.186922
22	PL4060C	Plūdrumą palaikanti liemenė, 40-60 kg	<p>UNIVERSALI Gelbėjimosi liemenė 40-60kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL4060</li>\n<li>Dydis: kūno svoris 40-60kg, krūtinės apimtis 70-94cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</li>\n</ul>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p>&nbsp;</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607752	10	2	35.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962642358-pludruma-palaikanti-liemene-40-60-kg-96597_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962642355-pludruma-palaikanti-liemene-40-60-kg-08a5a-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962642357-pludruma-palaikanti-liemene-40-60-kg-59ccf-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962642354-pludruma-palaikanti-liemene-40-60-kg-6fc6a-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.454978	2025-05-14 21:46:07.18939
23	PL6080J	Plūdrumą palaikanti liemenė, 60-80 kg	<p>UNIVERSALI Gelbėjimosi liemenė 60-80kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL6080</li>\n<li>Dydis: kūno svoris 60-80kg, krūtinės apimtis 84-110cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607769	10	2	43.49	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262845-pludruma-palaikanti-liemene-60-80-kg-c2490_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262844-pludruma-palaikanti-liemene-60-80-kg-7dfb9-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262845-pludruma-palaikanti-liemene-60-80-kg-db220-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262845-pludruma-palaikanti-liemene-60-80-kg-a9835-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.456701	2025-05-14 21:46:07.191656
24	PL6080M	Plūdrumą palaikanti liemenė, 60-80 kg	<p>UNIVERSALI Gelbėjimosi liemenė 60-80kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL6080</li>\n<li>Dydis: kūno svoris 60-80kg, krūtinės apimtis 84-110cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607776	10	2	43.49	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262844-pludruma-palaikanti-liemene-60-80-kg-78fd3_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262844-pludruma-palaikanti-liemene-60-80-kg-53570-atsiliepimai_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262843-pludruma-palaikanti-liemene-60-80-kg-5f372-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262844-pludruma-palaikanti-liemene-60-80-kg-81b1b-internetu_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.458681	2025-05-14 21:46:07.194057
25	PL6080C	Plūdrumą palaikanti liemenė, 60-80 kg	<p>UNIVERSALI Gelbėjimosi liemenė 60-80kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL6080</li>\n<li>Dydis: kūno svoris 60-80kg, krūtinės apimtis 84-110cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607783	10	2	43.49	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262846-pludruma-palaikanti-liemene-60-80-kg-ee8e2_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262845-pludruma-palaikanti-liemene-60-80-kg-bc348-atsiliepimai_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262843-pludruma-palaikanti-liemene-60-80-kg-3c621-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262846-pludruma-palaikanti-liemene-60-80-kg-feaf0-internetu_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.460495	2025-05-14 21:46:07.196087
26	PLF6080CZ	Plūdrumą palaikanti liemenė, 60-80 kg	<p>UNIVERSALI Gelbėjimosi liemenė 60-80kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL6080</li>\n<li>Dydis: kūno svoris 60-80kg, krūtinės apimtis 84-110cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	4060060599094	10	2	45.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262846-pludruma-palaikanti-liemene-60-80-kg-eed72_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262844-pludruma-palaikanti-liemene-60-80-kg-47360-atsiliepimai_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262843-pludruma-palaikanti-liemene-60-80-kg-2cfc0-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746962262844-pludruma-palaikanti-liemene-60-80-kg-a762c-internetu_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.463442	2025-05-14 21:46:07.198774
27	PL80100M	Plūdrumą palaikanti liemenė, 80-100 kg	<p>UNIVERSALI Gelbėjimosi liemenė 80-100kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL80100</li>\n<li>Dydis: kūno svoris 80-100kg, krūtinės apimtis 94-120cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</li>\n</ul>\n<p><u>&nbsp;</u></p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr. OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką. </p>\n<p>&nbsp;</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436608353	10	2	45.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100057-pludruma-palaikanti-liemene-80-100-kg-f13ff_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100055-pludruma-palaikanti-liemene-80-100-kg-5ece0-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100056-pludruma-palaikanti-liemene-80-100-kg-5507d-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100056-pludruma-palaikanti-liemene-80-100-kg-60655-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.46618	2025-05-14 21:46:07.201187
28	PL80100J	Plūdrumą palaikanti liemenė, 80-100 kg	<p>UNIVERSALI Gelbėjimosi liemenė 80-100kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL80100</li>\n<li>Dydis: kūno svoris 80-100kg, krūtinės apimtis 94-120cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</li>\n</ul>\n<p><u>&nbsp;</u></p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr. OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką. </p>\n<p>&nbsp;</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436608360	10	2	45.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100055-pludruma-palaikanti-liemene-80-100-kg-21bcd_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100055-pludruma-palaikanti-liemene-80-100-kg-8bd59-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100057-pludruma-palaikanti-liemene-80-100-kg-e6280-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100055-pludruma-palaikanti-liemene-80-100-kg-9ac20-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.468031	2025-05-14 21:46:07.203607
29	PL80100C	Plūdrumą palaikanti liemenė, 80-100 kg	<p>UNIVERSALI Gelbėjimosi liemenė 80-100kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL80100</li>\n<li>Dydis: kūno svoris 80-100kg, krūtinės apimtis 94-120cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</li>\n</ul>\n<p><u>&nbsp;</u></p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr. OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką. </p>\n<p>&nbsp;</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436608377	10	3	48.49	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100056-pludruma-palaikanti-liemene-80-100-kg-633d6_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100056-pludruma-palaikanti-liemene-80-100-kg-22617-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100057-pludruma-palaikanti-liemene-80-100-kg-bf0a2-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100056-pludruma-palaikanti-liemene-80-100-kg-87f8e-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.469726	2025-05-14 21:46:07.205751
30	PLF80100CZ	Plūdrumą palaikanti liemenė, 80-100 kg	<p>UNIVERSALI Gelbėjimosi liemenė 80-100kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL80100</li>\n<li>Dydis: kūno svoris 80-100kg, krūtinės apimtis 94-120cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</li>\n</ul>\n<p><u>&nbsp;</u></p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr. OOP-2452/EU-007/2021/01</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką. </p>\n<p>&nbsp;</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	4060059167204	10	2	54.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100057-pludruma-palaikanti-liemene-80-100-kg-c5262_reference.webp	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100057-pludruma-palaikanti-liemene-80-100-kg-d76c7-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100055-pludruma-palaikanti-liemene-80-100-kg-31a49-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746961100054-pludruma-palaikanti-liemene-80-100-kg-4aea7-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.471668	2025-05-14 21:46:07.208181
33	PL100120C	Plūdrumą palaikanti liemenė, 100-120 kg	<p>UNIVERSALI Gelbėjimosi liemenė 100-120kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL100120</li>\n<li>Dydis: kūno svoris 100-120kg, krūtinės apimtis 104-130cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; juoda, t.mėlyna, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p>&nbsp;</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos</u>.</p>	754436608377	10	2	65.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459634-pludruma-palaikanti-liemene-100-120-kg-ca8c5_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459634-pludruma-palaikanti-liemene-100-120-kg-f41aa-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459633-pludruma-palaikanti-liemene-100-120-kg-9d5c7-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459634-pludruma-palaikanti-liemene-100-120-kg-aa0ac-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.476518	2025-05-14 21:46:07.214646
34	PLF100120CZ	Plūdrumą palaikanti liemenė, 100-120 kg	<p>UNIVERSALI Gelbėjimosi liemenė 100-120kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL100120</li>\n<li>Dydis: kūno svoris 100-120kg, krūtinės apimtis 104-130cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; juoda, t.mėlyna, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p>&nbsp;</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos</u>.</p>	754436608384	10	2	65.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713608846473-100-120_4.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459632-pludruma-palaikanti-liemene-100-120-kg-0a7cf-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459633-pludruma-palaikanti-liemene-100-120-kg-4e075-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459634-pludruma-palaikanti-liemene-100-120-kg-ba655-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.478005	2025-05-14 21:46:07.216913
37	PLF120140CZ	Plūdrumą palaikanti liemenė, 120-140 kg	<p>UNIVERSALI Gelbėjimosi liemenė 120-140kg WALLYS</p>\n<ul>\n<li>\n<p>Pagaminta Lietuvoje</p>\n</li>\n<li>\n<p>Atitinka ES standartą&nbsp;</p>\n</li>\n<li>\n<p>EN ISO 12402-5&nbsp;&nbsp;(50N)</p>\n</li>\n<li>\n<p>Plūdrumo liemenė.&nbsp;Mod. PL120140&nbsp;&nbsp;</p>\n</li>\n<li>\n<p>Dydis: kūno svoris 120-140kg, krūtinės apimtis 114-140cm</p>\n</li>\n<li>\n<p>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</p>\n</li>\n<li>\n<p>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</p>\n</li>\n<li>\n<p>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</p>\n</li>\n<li>\n<p>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</p>\n</li>\n<li>\n<p>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p>&nbsp;</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</p>\n<p>&nbsp;</p>	754436608414	10	2	69.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125851-pludruma-palaikanti-liemene-120-140-kg-003bc_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125852-pludruma-palaikanti-liemene-120-140-kg-7621f-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125852-pludruma-palaikanti-liemene-120-140-kg-d6664-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125851-pludruma-palaikanti-liemene-120-140-kg-09e46-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.483642	2025-05-14 21:46:07.224374
38	PL120140C	Plūdrumą palaikanti liemenė, 120-140 kg	<p>UNIVERSALI Gelbėjimosi liemenė 120-140kg WALLYS</p>\n<ul>\n<li>\n<p>Pagaminta Lietuvoje</p>\n</li>\n<li>\n<p>Atitinka ES standartą&nbsp;</p>\n</li>\n<li>\n<p>EN ISO 12402-5&nbsp;&nbsp;(50N)</p>\n</li>\n<li>\n<p>Plūdrumo liemenė.&nbsp;Mod. PL120140&nbsp;&nbsp;</p>\n</li>\n<li>\n<p>Dydis: kūno svoris 120-140kg, krūtinės apimtis 114-140cm</p>\n</li>\n<li>\n<p>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</p>\n</li>\n<li>\n<p>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</p>\n</li>\n<li>\n<p>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</p>\n</li>\n<li>\n<p>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</p>\n</li>\n<li>\n<p>Spalvos &ndash; t.mėlyna, juoda, kamufliažinė</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p>&nbsp;</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</p>\n<p>&nbsp;</p>	754436608421	10	2	69.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125852-pludruma-palaikanti-liemene-120-140-kg-b39d4_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125852-pludruma-palaikanti-liemene-120-140-kg-e366d-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125852-pludruma-palaikanti-liemene-120-140-kg-70bfd-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746960125852-pludruma-palaikanti-liemene-120-140-kg-51a82-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.485356	2025-05-14 21:46:07.226526
39	KR23-MS	Žvejybinis Kajakas Galaxy Kayaks, Cruz ULTRA	<p>Pristatome visi&scaron;kai naują "Galaxy Kayaks" kajaką "Cruz Ultra", sukurtą taip, kad atitiktų kiekvieno žvejo poreikius.</p>\n<p>&nbsp;</p>\n<p><a href="https://youtu.be/v2AGdcOo3_U?si=vkbMgPOcRUK-Zl11" rel="noopener noreferrer nofollow">Galaxy Kayaks "Cruz Ultra" </a>- idealus Pasirinkimas Jūsų laisvalaikiui gamtoje ir žvejybai!&nbsp;</p>\n<p>Tobulas pasirinkimas tiek naujokams, tiek patyrusiems žvejams, kurie ie&scaron;ko universalaus ir stabilaus kajako jūros, ežerų, tvenkinių, upių vandens žvejybai. Cruz Ultra i&scaron; Galaxy Kayaks pasižymi &scaron;iomis svarbiausiomis savybėmis:</p>\n<p>✅ Specialiai projektuotas plok&scaron;čias dugnas ir &scaron;laitiniai kra&scaron;tai suteikia maksimalų stabilumą ir sklandų plaukimą.</p>\n<p>✅ Nauja vairavimo sistema valdoma pedalais suteiks didesnį manevringumą vandenyje.</p>\n<p>✅ Priekyje esantys bėgeliai įvairiems priedams, tokiems kaip me&scaron;kerių laikikliai, kameros pakabinimai ar echoloto ekranas.</p>\n<p>✅ Auk&scaron;tas, dviejų auk&scaron;čių, kėdės dizainas suteiks papildomą komfortą ilgesnių žvejybų metu.</p>\n<p>✅ Dar daugiau saugojimo vietų, įskaitant naują stačiakampę centrinę, vandens nepraleidžiančią, daiktų dėtuvę.</p>\n<p>✅ Du fiksuoti ir vienas pasukamas, profesionalus me&scaron;kerių laikiklius.</p>\n<p>✅ Spaciali vieta elektriniui varikliui montuoti (elektrinis variklis ir laikiklis parduodami atskirai).</p>\n<p>Naujos spalvos: Midnight Sorm, Mars, Sage.</p>\n<p>&nbsp;</p>\n<p>Dėl specialiai sukurto plok&scaron;čio dugno ir kampuotų kra&scaron;tų &scaron;is kajakas maksimaliai padidina stabilumą ir leidžia sklandžiai bei lengvai plaukti. Jo smailus priekinis kylis ir V formos laivagalis užtikrina gerą plaukimo greitį, o nauja pedalais valdomo vairo sistema leidžia padidinti manevringumą vandenyje.</p>\n<p>"Cruz Ultra" turi du priekinius bėgelius, kurie puikiai tinka tokiems priedams, kaip me&scaron;kerių laikikliai, kamerų strėlės ir žuvų ie&scaron;kikliui, pritvirtinti. Taip pat įmontuotos papildomos vietos, kad būtų galima lengvai ir be grąžtų sumontuoti populiarius priedus, pavyzdžiui, "Railblaza Starport".</p>\n<p>Į komplektaciją įeina ir auk&scaron;ta, reguliojamo auk&scaron;čio, sėdynė, skirta ilgesnėms žvejyboms, kad būtų patogiau ir galėtumėte geriau matyti.</p>\n<p>&nbsp;</p>\n<p>Standartinėje "Cruz Ultra" komplektacijoje yra daug daiktadėžių. Kajako viduryje yra naujas, vandens nepraleidžiantis, daiktų laikymo liukas, kuris atsidaro į irkluotojo pusę, o tai rei&scaron;kia, kad jį lengviau atidaryti ir uždaryti būnant ant vandens.</p>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/v2AGdcOo3_U?si=ERfMYXci_Mjl-8tp" width="640" height="480" data-mce-fragment="1"></iframe></div>\n<p><strong>Santrauka:</strong></p>\n<ul>\n<li>\n<p>Universalus kajakas žvejybai jūroje ir gėlame vandenyje.</p>\n</li>\n<li>\n<p>Nauja stačiakampė, vandens nepraleidžianti, centrinė daiktadėžė.</p>\n</li>\n<li>\n<p>Nauja pedalais valdoma vairo sistema manevringumui padidinti.</p>\n</li>\n<li>\n<p>Sukurta tiek pradedantiesiems, tiek patyrusiems žvejams.</p>\n</li>\n<li>\n<p>Užtikrina maksimalų stabilumą ir sklandų plaukimą.</p>\n</li>\n<li>\n<p>Du fiksuoti me&scaron;kerių laikikliai ir vienas pasukamas profesionalus me&scaron;kerių laikiklis.</p>\n</li>\n<li>\n<p>Turi priekinius bėgelius priedams tvirtinti.</p>\n</li>\n<li>\n<p>Įmontuotos papildomos vietos, kad būtų galima lengvai sumontuoti populiarius priedus.</p>\n</li>\n<li>\n<p>Į komplektą įeina auk&scaron;ta kėdė užtikrinanti didesnį komfortą. Galima keisti sėdėjimo auk&scaron;tį.</p>\n</li>\n<li>\n<p>Mūsų HV serijos dalis - trijų spalvų gelbėjimo virvės &scaron;onuose ir tamprios virvelės kajako gale, užtikrinančios individualią i&scaron;vaizdą ir didesnį saugumą.</p>\n</li>\n<li>\n<p>Turi daug vietos, įskaitant žvejybos įrankių dėžę ir gyvo masalo &scaron;ulinį.</p>\n</li>\n<li>\n<p>Pilnai sukomplektuota sėdynė ir irklas, paruo&scaron;tas kitam jūsų nuotykiui ant vandens.</p>\n</li>\n<li>\n<p>Galimos įvairios spalvos - nuo visi&scaron;kai matomų iki maskuojančių</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>Specifikacijos:</strong></p>\n<p>Ilgis: 292 cm, plotis: 84 cm, auk&scaron;tis: 36 cm.</p>\n<p>Svoris: 35 kg</p>\n<p>Didžiausias gabenimo svoris: 130 kg</p>\n<p>Rekomenduojama žmonėms, kurių maksimalus svoris: 110 kg</p>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/zzoaL1uT-4k?si=EQW7EXy7FNiuitgY" width="640" height="480" data-mce-fragment="1"></iframe></div>\n<p>Kodėl verta rinktis "Galaxy Kayaks"? Europoje parduota daugiau kaip 30 000 kajakų, yra daugybė klientų atsiliepimų, jie publikuojami kai kuriuose žymiausiuose Europos specializuotuose žurnaluose, todėl galite pasitikėti, kad "Galaxy Kayaks" suteiks geriausią plaukimo kajakais patirtį. Be to, mūsų kajakai yra patvirtinti CE ir joms suteikiama 2 metų garantija kajako korpusui.</p>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>\n<p>&nbsp;</p>\n<p>Rekomenduojama gelbėjimosi liemenė (spausti ant teksto):&nbsp;<a href="https://vakasport.lt/nrs-chinook-fishing-pfd-zvejybine-gelbejimosi-liemene" rel="noopener noreferrer nofollow"><strong>NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė</strong></a></p>	8436618810694	3	2	699.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186991323-A7M03135.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186991323-A7M03135.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186981670-A7M03117.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186981672-A7M03124.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186981672-A7M03125.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186977703-A7M03129.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186977705-A7M03131.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186977705-A7M03132.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186991325-A7M03136.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186991325-A7M03137.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1721073324722-A7M03151.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1721073324723-A7M03152.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1721073324723-A7M03153.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186981670-A7M03118.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186981670-A7M03119.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186981671-A7M03120.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186981671-A7M03122.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186981671-A7M03121.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703186981671-A7M03123.jpg"	Cruz ULTRA	\N	\N	35.000	\N	\N	\N	2025-05-14 18:59:18.48731	2025-05-14 21:46:07.229757
40	KR26-MC	Žvejybinis Kajakas Galaxy Kayaks, Wildcat	<p>Pristatome <strong>"Wildcat" - naujausią "Galaxy Kayaks"</strong> kajakų &scaron;eimos narį! &Scaron;is naujasis modelis - tai puikus stabilumo, patogumo ir efektyvumo derinys. Naudodami fliper pedalų sistemą, galėsite lengvai slysti vandeniu, todėl puikiai tinka tiek pradedantiesiems, tiek pažengusiems.</p>\n<p>&nbsp;</p>\n<p>"Wildcat" yra i&scaron;sipildžiusi žvejo svajonė.</p>\n<p>Vairas su rankinio valdymo sistema užtikrina tikslų manevringumą, todėl lengva plaukti net ir sudėtingiausiuose vandenyse. O su mūsų "Galaxy High Chair" reguliuojama kėde galėsite valandų valandas praleisti ant vandens be jokio diskomforto.</p>\n<p>&nbsp;</p>\n<p>Saugumas visada svarbus, todėl mūsų kajakas "Wildcat" turi patvar gelbėjimo lyną, pagamintas i&scaron; virvės. Prie &scaron;ios virvės žvejai taip pat gali prijungti daiktus ir ji praverčia atliekant tokius manevrus kaip inkaro nuleidimą.</p>\n<p>Bet tai dar ne viskas! Kajake "Wildcat" taip pat yra daug vietos daiktams laikyti, įskaitant priekinį liuką ir galinę daiktadėžę su tampropmis gumomis. Jame yra net 6 bėgeliai priedams tvirtinti, todėl kajaką galima pritaikyti pagal savo poreikius.</p>\n<p>Dėka 5 tvirtų rankenų "Wildcat" gabenti i&scaron; automobilio į vandenį dar niekada nebuvo taip paprasta. 375x89x36 cm dydžio ir galintis gabenti krovinį iki 180 kg, sukurtas taip, kad tarnautų ilgai.</p>\n<p>&nbsp;</p>\n<p>Taigi, jei ie&scaron;kote auk&scaron;tos kokybės, patikimos baidarės ar kajako, kuris pasižymėtų efektyvumu ir patogumu, rinkitės "Wildcat".</p>\n<p>&nbsp;</p>\n<h3><strong>Santrauka:</strong></h3>\n<ul>\n<li>\n<p>Stabilus, patogus ir manevringas kajakas net ir i&scaron;rankaiusiam skoniui.</p>\n</li>\n<li>\n<p>Flipper pedalų sistema, kad būtų lengva plaukti vandeniu.</p>\n</li>\n<li>\n<p>Du stacionarūs me&scaron;kerių laikikliai, du "Railblaza Starports" ir "Railblaza" me&scaron;kerių laikikliklis standartinėje komplektacijije!</p>\n</li>\n<li>\n<p>Vairas su rankinio valdymo sistema tiksliam manevringumui užtikrinti.</p>\n</li>\n<li>\n<p>Gelbėjimo lynas, pagamintas i&scaron; patvarios virvės.</p>\n</li>\n<li>\n<p>"Galaxy High Chair" reguliuojama kėdė, užtikrinanti maksimalų komfortą leidžiant ilgas valandas ant vandens.</p>\n</li>\n<li>\n<p>Didelis vandens nepraleidžiančių daiktadėžių tūris, įskaitant priekinį laikymo liuką ir galinę laikymo erdvę su tampriomis virvėmis.</p>\n</li>\n<li>\n<p>&Scaron;e&scaron;i bėgeliai priedams.</p>\n</li>\n<li>\n<p>Penkios tvirtos ne&scaron;imo rankenos.</p>\n</li>\n<li>\n<p>Galima plauksti su kroviniu sverenčiu iki 180 kg.</p>\n</li>\n<li>\n<p>Spaciali vieta elektriniui varikliui montuoti (elektrinis variklis ir laikiklis parduodami atskirai).</p>\n<p>&nbsp;</p>\n<p>&nbsp;</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<h3><strong>Specifikacijos:</strong></h3>\n<p>Ilgis: 375 cm, plotis: 89 cm, auk&scaron;tis: 36 cm.</p>\n<p>Svoris: 38 kg.</p>\n<p>Didžiausias galimas krovinio svoris: 180 kg.</p>\n<p>Rekomenduojama žmonėms iki 115 kg.</p>\n<p>&nbsp;</p>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>	8436618811004	0	3	1599.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1723562464068-A7M03254.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1723562464067-A7M03252.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1723562464068-A7M03253.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703238641885-A7M03255.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703238641886-A7M03256.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703238641887-A7M03257.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703238641887-A7M03258.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703238641887-A7M03259.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703238641887-A7M03259.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703238641887-A7M03261.jpg"	Wildcat	\N	\N	51.000	\N	\N	\N	2025-05-14 18:59:18.489008	2025-05-14 21:46:07.2326
41	KP-KR22-SG	Kajakas - Baidarė, Galaxy Kayaks, Force	<p>Naujasis <a href="https://youtu.be/wVsTUdmtP5M?si=r8KfwVxpR_6ayW5S" target="_blank" rel="noopener noreferrer nofollow"><strong>Galaxy Force</strong></a> yra universalus žūklės kajakas, tinkantis tiek jūros, tiek gėlo vandens žūklei. "Force" yra mūsų prieinamiausias žūklės kajakas, turintis daug puikių funkcijų ir žūklės priedų jau įtrauktų į standartinę komplektaciją/kainą. Neleiskite apgaunami žemos kainos!</p>\n<p>&Scaron;is kajakas turi viską, ko reikia, kad i&scaron;plauktumėte ir pradėtumėte žvejoti su savo draugais!</p>\n<p>&nbsp;</p>\n<h3>Svarbiausios savybės:</h3>\n<ul>\n<li>\n<p>Dvi vandens nepraleidžiančios daiktų saugojimo dėtuvės ir galinė saugykla su tampriomis virvėmis.</p>\n</li>\n<li>\n<p>Lengva laikyti ir transportuoti.</p>\n</li>\n<li>\n<p>Stabilus dėl plok&scaron;čio dugno ir 78 cm pločio.</p>\n</li>\n<li>\n<p>Keturi fiksuoti me&scaron;kerių laikikliai.</p>\n</li>\n<li>\n<p>Sėdyne ir irklas.</p>\n</li>\n<li>\n<p>Dvi spalvotos tamprios virvės gale ir gelbėjimo lynai &scaron;onuose.</p>\n</li>\n<li>\n<p>Spaciali vieta elektriniui varikliui montuoti (elektrinis variklis ir laikiklis parduodami atskirai).</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>Rinkitės Galaxy Force ir patirkite žūklės malonumą, nei&scaron;leisdami krūvos pinigų! 🎣🚣&zwj;♂️</p>\n<p>&nbsp;</p>\n<p>"Galaxy Force" yra geriausias kajakas žvejybos entuziastams, kurie siekia universalumo ir na&scaron;umo vandenyje. Nesvarbu, ar mėgstate džiguoti, velkiauti, spiningauti, ar naudoti gyvą masalą, &scaron;is kajakas užtikrina visas galimybes. Sukurta tiek jūros, tiek gėlo vandens aplinkai, &scaron;i baidarė pasižymi sklandžiu ir stabiliu plaukimu net ir tada, kai traukiami didžiausi laimikiai.</p>\n<p>&nbsp;</p>\n<p>78 cm plotis ir plok&scaron;čio dugno konstrukcija užtikrina maksimalų stabilumą, o gilus priekinis - sklandų ir greitą plaukimą.</p>\n<p>Su dviem įmontuotais fiksuotais me&scaron;kerių laikikliais ir vienu pasukamu profesionaliu me&scaron;kerių laikikliu "Force" leidžia pritaikyti žvejybos įrangą pagal savo pageidavimus.</p>\n<p>Dvi vandens nepraleidžiančios daiktų saugojimo dėtuvės suteikia galimybę laikyti papildomus įrankius, o galinėje laikymo zonoje su tampriomis virvėmis rasite pakankamai vietos papildomiems priedams.</p>\n<p>Galinėje dalyje suformuota <strong>variklio laikiklio vieta </strong>ir daug vietos papildomoms atramoms bei tvirtinimo elementams, todėl &scaron;į kajaką i&scaron;ties galima pritaikyti pagal savo poreikius.</p>\n<p>Galaxy Force kajakas yra visi&scaron;kai sukomplektuota su sėdyne ir irklu, tad užsidedam gelbėjimosi liemenę ir pirmyn! Didelio matomumo (HV) serija&trade; suteikia papildomo saugumo ant vandens su trimis oranžinės, baltos ir juodos spalvų bungee virvėmis. HV Series&trade; taip pat galima įsigyti įvairių naujų spalvų - nuo visi&scaron;kai matomų iki visi&scaron;kai maskuojančių.</p>\n<p>&nbsp;</p>\n<p><a href="https://youtu.be/wVsTUdmtP5M?si=r8KfwVxpR_6ayW5S" target="_blank" rel="noopener noreferrer nofollow">VIDEO (spausti ant teksto)</a></p>\n<p>&nbsp;</p>\n<h3>Apibendrinant:</h3>\n<ul>\n<li>\n<p>Universalus žvejybinis kajakas, skirta žvejybai ir laisvalaikiui jūroje ir gėlame vandenyje.</p>\n</li>\n<li>\n<p>Stabilus ir greitas plaukimas dėl gilaus priekinio kilio ir galinės konstrukcijos.</p>\n</li>\n<li>\n<p>Individualiai pritaikoma žvejybos įranga su keturiais fiksuotais me&scaron;kerių laikikliais ir vienu pasukamu profesionaliu me&scaron;kerių laikikliu.</p>\n</li>\n<li>\n<p>Didelė laikymo erdvė su dviem nedideliais liukais ir galine laikymo erdve su bungee tampriomis virvėmis.</p>\n</li>\n<li>\n<p>Elektrinio variklio laikiklio vieta.</p>\n<p>&nbsp;</p>\n</li>\n<li>\n<p>Galimos įvairios spalvos - nuo visi&scaron;kai matomų iki visi&scaron;kai maskuojančių.</p>\n</li>\n<li>\n<p>Pilnai sukomplektuota sėdynė ir irklas, paruo&scaron;tas kitam jūsų nuotykiui.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<h3>Specifikacijos:</h3>\n<p>Ilgis: 295 cm, plotis: 78 cm, auk&scaron;tis: 38 cm.</p>\n<p>Svoris: 21 kg</p>\n<p>Rekomenduojamas krovinio svoris iki: 170 kg</p>\n<p>Rekomenduojama žmonėms sveriantiems iki 105 kg</p>\n<p>&nbsp;</p>\n<p>Rinkitės "Galaxy Force", jei norite patirti geriausią plaukimo kajakais patirtį!</p>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>	8436618810601	2	2	549.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1729077052798-A7M09150.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1729077052797-A7M09148.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1729077052797-A7M09149.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1729077052796-A7M09145.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703240662739-A7M09169.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703240662739-A7M09170.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703240662739-A7M09171.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703240662740-A7M09172.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737143543096-2.jpg"	Force	\N	\N	25.000	\N	\N	\N	2025-05-14 18:59:18.490634	2025-05-14 21:46:07.235154
43	KR35-MG	Vaikiškas Kajakas - Baidarė, Galaxy Kayaks, Pinguino	<h3>Galaxy Kayaks "Pinguino" - Puikus Vaikų Kajakas! 🚣&zwj;♂️</h3>\n<p>&nbsp;</p>\n<p>Ar esate tėvai, kurie norėtų, kad jūsų vaikai prleistų daugiau laiko lauke? Kai būti kajake ar gamtoje yra gyvenimo dalis, natūralu dalintis ja su artimaisiais. Ir patikėkite mumis, plaukti kartu su mylimaisiais yra smagu! &bdquo;Pinguino&ldquo; yra naujausias vaikų kajakas i&scaron; &bdquo;Galaxy Kayaks&ldquo;, atne&scaron;antis naują korpuso dizainą ir daugybę funkcijų, palyginti su mūsų ankstesniais modeliais.</p>\n<h2>&nbsp;</h2>\n<p>&nbsp;</p>\n<h3>🌟 Svarbiausios savybės:</h3>\n<p>✅ Atnaujintas korpuso dizainas su daugeliu naujovių.</p>\n<p>✅ Puikiai tinka vaikams pradėti plaukioti.</p>\n<p>✅ Ilgalaikio naudojimo patikimumas i&scaron; &bdquo;Galaxy Kayaks&ldquo;.</p>\n<p>✅ Smagūs ir saugūs kajako nuotykiai su &scaron;eima.</p>\n<p>✅ Naujos spalvos pritrauks vaikų dėmesį.</p>\n<p>🚤 Pasirinkite &bdquo;Pinguino&ldquo; ir leiskite vaikams įsimylėti kajakavimą nuo pat mažumės! Užsisakykite jau dabar ir dalinkitės neeiliniais vandens nuotykiais su visu &scaron;eimos būreliu!</p>\n<p>&nbsp;</p>\n<h3>&nbsp;</h3>\n<h3>🚣&zwj;♂️ Galaxy Pinguino - Kajakas Specialiai Vaikams! 🚣&zwj;♂️</h3>\n<p>Mes su dideliu džiaugsmu pristatome &bdquo;Galaxy Pinguino&ldquo;, specialiai sukurtą vaikams, sveriantiems iki 50 kg. Manome, kad vaikai nusipelno savo asmeninio kajako, todėl &bdquo;Pinguino&ldquo; turi viską, ko jiems reikia smagiai vandens pramogų dienai.</p>\n<p>&bdquo;Galaxy Pinguino&ldquo; matmenys yra 180 cm ilgio ir 62 cm pločio, todėl &scaron;is kajakas yra stabilus ir puikiai tinka vaikams, kurie tik pradeda domėtis kajakavimu.</p>\n<p>&Scaron;is kajakas yra paprastas, tačiau visi&scaron;kai funkcionalus, jame yra sėdynė ir vaik6kas irklas. Jums reikės tik vaiko dydžio gelbėjimo liemenės, ir jūs pasiruo&scaron;ę nuotykiams ant vandens!</p>\n<p>Didžiausia nauda, kurią pastebėjome, kai vaikai kajakuoja vieni, yra ta, kad jų pasitikėjimas auga, jie mokosi naviguoti vandenyje savo erdvėje ir pagal savo kontrolę. Turėdami savo vandens transporto priemonę, jie tikrai įsimyli &scaron;į sportą!</p>\n<p>&nbsp;</p>\n<h3>🔍 Santrauka:</h3>\n<ul>\n<li>\n<p>2 &scaron;oninės rankenos: patogiam kajako perne&scaron;imui.</p>\n</li>\n<li>\n<p>4 D žiedai: lengvam daiktų, tokių kaip sėdynės prisegimui.</p>\n</li>\n<li>\n<p>1 didelė galinė saugyklos zona: lengvam daiktų transportavimui ant kajako.</p>\n</li>\n<li>\n<p>3 padėčių kojų laikikliai: patogiai laikysenai plaukiojant.</p>\n<p>&nbsp;</p>\n</li>\n<li>\n<p>1 vaiki&scaron;kas atlo&scaron;as/sėdynė: palaikyti taisyklingą stuburo padėtį ir skatinti tinkamą irklavimo techniką.</p>\n</li>\n<li>\n<p>1 vaiki&scaron;kas irklas: pagamintas i&scaron; aliuminio ir plastiko, lengvas ir atsparus bet kokioms oro sąlygoms. Matmenys 154 cm.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<h3>📋 Specifikacijos:</h3>\n<ul>\n<li>\n<p>Medžiaga: UV atsparus LLDPE</p>\n</li>\n<li>\n<p>Ilgis: 180 cm Plotis: 62 cm Auk&scaron;tis: 30 cm</p>\n</li>\n<li>\n<p>Svoris: 10 kg</p>\n</li>\n<li>\n<p>Maksimalus krovinio svoris: 50 kg</p>\n<p>&nbsp;</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<h3>🛶 Kaip pasirinkti tinkamą kajaką vaikui:</h3>\n<p>Iki 12 metų, iki 50 kg = &bdquo;Galaxy Pinguino&ldquo;</p>\n<p>Vir&scaron; 12 metų, žūklės kajakas = &bdquo;Rider&ldquo;</p>\n<p>Vir&scaron; 12 metų, poilsiavimo kajakas = &bdquo;Galaxy Fuego&ldquo;</p>\n<p>&Scaron;eimos kajakas = &bdquo;Galaxy Tahiti Tandem&ldquo;</p>\n<p>&nbsp;</p>\n<p>Pasirinkite &bdquo;Galaxy Pinguino&ldquo; ir leiskite vaikams įsimylėti kajakavimą nuo pat mažumės! 🌊</p>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>\n<p>&nbsp;</p>	8436618810229	2	2	259.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703241003972-A7M09380.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703240944061-A7M09367.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703240944060-A7M09366.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1723563108475-A7M09403.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1723563108477-A7M09410.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1723563108477-A7M09409.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703241036614-A7M09405.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703241036614-A7M09406.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1723563108476-A7M09404.jpg"	Pinguino	\N	\N	12.000	\N	\N	\N	2025-05-14 18:59:18.494355	2025-05-14 21:46:07.240298
44	KR34-MS	Žvejybinis Kajakas - Baidarė, Galaxy Kayaks, Ranger	<p>"Galaxy Kayaks" kajakas "Ranger" yra puikus pasirinkimas ie&scaron;kantiems stabilaus, lengvai transportuojamo ir universalaus kajako nuotykiams gamtoje. "Ranger" turi galinę dėžę dideliam akumuliatoriui ir pakabinamam varikliui laikyti, todėl žada, kad su juo galėsite leistis į jaudinančią kelionę.</p>\n<p>&nbsp;</p>\n<h3>Pateikiame penkias svarbiausias savybes:</h3>\n<ul>\n<li>\n<p>Trumpa ir plati konstrukcija, užtikrinanti didesnį stabilumą ant vandens.</p>\n</li>\n<li>\n<p>Galinė talpykla dideliam akumuliatoriui ir pakabinamajam varikliui (63,9*28,4*50cm)</p>\n</li>\n<li>\n<p>Patogi sėdynė ir irklas, kad būtų lengviau plaukti.</p>\n</li>\n<li>\n<p>Sukurtas naudoti su pakabinamu varikliu (parduodamas atskirai).</p>\n</li>\n<li>\n<p>Lengva transportuoti, tinka montuoti ant stogo bagažinės, sunkvežimio gale arba automobilio bagažinėje.</p>\n</li>\n<li>\n<p>Auk&scaron;ta sėdynė (<a href="https://vakasport.lt/auksta-sedyne" target="_blank" rel="noopener noreferrer nofollow">parduodama atskirai</a>).</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>&nbsp;</p>\n<p>Pristatome "Galaxy Kayaks" motorinį kajaką "Ranger" - geriausią jūsų kompanioną, su kuriuo galėsite patirti nuotykių vandenyje. 200 cm ilgio ir 98 cm pločio "Ranger" yra trumpas, bet platus kajakas, pasižymintis stabilumu ir patogumu transportuoti. Sukurta naudoti su pakabinamu kajako varikliu, &scaron;is kajakas perkels jus į jaudinančią kelionę, kurios nepamir&scaron;ite.</p>\n<p>Galaxy Kayaks supranta, kaip svarbu turėti patikimą motorinį kajaką, galintį priimti bet kokį i&scaron;&scaron;ūkį. Todėl "Ranger" įrengėme galinę daiktadėžę, kurioje galima laikyti didelį akumuliatorių ir pakabinamą variklį. Su &scaron;iuo galingu deriniu galite lengvai plaukti per vandenį dideliu greičiu.</p>\n<p>Ranger puikiai tinka tiems, kurie nori tyrinėti gamtą. Jame yra patogi sėdynė ir irklas, todėl juo lengva plaukti net per sudėtingiausius vandenis. Nesvarbu, ar esate pradedantysis, ar patyręs "Ranger" sukurtas taip, kad suteiktų jums kuo geresnę patirtį.</p>\n<p>Viena i&scaron; i&scaron;skirtinių "Ranger" savybių yra jo stabilumas. Trumpa ir plati &scaron;io kajako konstrukcija užtikrina, kad ant vandens i&scaron;liktumėte stabilūs, net ir tada, esant didelėms bangoms. &Scaron;į stabilumą dar labiau sustiprina pridėtas pakabinamas variklis, kuris užtikrina labiau kontroliuojamą ir stabilų plaukimą.</p>\n<p>&nbsp;</p>\n<p>Kai reikia transportuoti, "Ranger" yra lengvas. Dėl trumpo ilgio ir plačios konstrukcijos &scaron;į kajaką lengva transportuoti ant stogo bagažinės, sunkvežimio gale ar net automobilio bagažinėje. Jums nereikės investuoti į priekabą ar rūpintis didesnių kajakų gabenimo įranga.</p>\n<p>Ranger yra universalus kajakas, kurią galima naudoti įvairiai veiklai. Nesvarbu, ar žvejojate, ar tyrinėjate pakrantę, ar tiesiog plaukiojate, &scaron;is kajakas sukurtas taip, kad atitiktų jūsų poreikius. Pridėjus variklį, per trumpą laiką galite įveikti didelius atstumus, todėl turėsite daugiau laiko mėgautis kra&scaron;tovaizdžiu.</p>\n<p>Apibendrinant, jei ie&scaron;kote stabiliaus, lengvai transportuojamo ir universalaus kajako su varikliu, "Galaxy Kayaks" kajakas "Ranger" yra puikus pasirinkimas. Dėl stabilios konstrukcijos, patogios sėdynės ir irklo tikrai patirsite nepamir&scaron;tamų įspūdžių ant vandens. Tad kam laukti? Užsisakykite "Ranger" jau &scaron;iandien ir pradėkite kitą nuotykį!</p>\n<p>&nbsp;</p>\n<h3>Specifikacijos:</h3>\n<p>Ilgis: 200 cm, plotis: 98 cm, auk&scaron;tis: 38 cm.</p>\n<p>Svoris: 19 kg</p>\n<p>Rekomenduojamas krovinio svoris: 150 kg</p>\n<p>Rekomenduojama žmonėms, kurių maksimalus svoris: 110 kg</p>\n<p>Baterijos/akumuliatoriaus dėžės matmenys: 63,9*28,4*50cm</p>\n<p>&nbsp;</p>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>\n<p>&nbsp;</p>	8436618810328	0	5	569.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239573739-A7M03324.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239573740-A7M03325.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239573741-A7M03326.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239573741-A7M03327.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239680734-A7M03402.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239680734-A7M03403.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239680734-A7M03404.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1726078343270-ranger.webp"	Ranger	\N	\N	24.000	\N	\N	\N	2025-05-14 18:59:18.496556	2025-05-14 21:46:07.243118
45	KR27-MC	Žvejybinis Kajakas - Baidarė, Galaxy Kayaks, Supernova Jr	<p>Pristatome <a href="https://youtu.be/hShkaNcLWSM?si=xbO1cIR5NCuFj3U6" rel="noopener noreferrer nofollow"><strong>Supernova Jr </strong></a>pedalais varomą kajaką i&scaron; Galaxy Kayaks, mažesnį, tačiau galingą atitikmenį mūsų garsiam Supernova FX kajakui. Sukurtas atsižvelgiant į žvejų poreikius, &scaron;is kajakas turi pedalais varomą sistemą, kuri be vargo plukdo jus per vandenį ir i&scaron; esmės pakeičia jūsų žvejybos patirtį.</p>\n<p>&nbsp;</p>\n<h3>Pagrindinės savybės:</h3>\n<ul>\n<li>\n<p>"Cyclone" pedalų pavara, kad būtų galima lengvai minti pedalus pirmyn ir atgal</p>\n</li>\n<li>\n<p>Patogį priekinė daiktadėžė, suteikianti prieigą prie įrangos net ir būnant ant vandens.</p>\n</li>\n<li>\n<p>2 bėgeliai įvairiems priedams pritvirtinti, pavyzdžiui me&scaron;kerių laikikliams, Echoloto ekranui ir t.t.</p>\n</li>\n<li>\n<p>Gelbėjimo virvė užtikrinanti papildomą saugumą vandens i&scaron;vykose.</p>\n</li>\n<li>\n<p>Galinė saugykla su tampriomis virvėmis saugiam įrangos laikymui.</p>\n</li>\n<li>\n<p>Vairas su rankinio valdymo sistema tiksliam manevringumui užtikrinti.</p>\n</li>\n<li>\n<p>Spaciali vieta elektriniui varikliui montuoti (elektrinis variklis ir laikiklis parduodami atskirai).</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>Pasiruo&scaron;kite leistis į žvejybinius nuotykius kaip niekad anksčiau su "<strong>Supernova Jr</strong>". &Scaron;ioje baidarėje sumontuota pažangiausia "Cyclone" pedalų pavara, todėl ja galima sklandžiai ir efektyviai minti pedalus tiek pirmyn, tiek atgal, be vargo plaukioti vandeniu ir susitelkti į žvejybą.</p>\n<p>Patogus "Supernova Jr" priekinis liukas leidžia lengvai pasiekti būtiniausius daiktus, kai esate ant vandens. Žvejybos reikmenis, užkandžius ar kitus būtiniausius daiktus laikykite pasiekiamus, nenutraukdami žvejybos ritmo.</p>\n<p>Naudodami du integruotus bėgelius puikiai pritaikykite savo žvejybos įrangą. Pritvirtinkite priedus, pavyzdžiui, "Railblaza Starports", kad galėtumėte pasiimti mėgstamus žvejybos įtaisus, me&scaron;kerių laikiklius ar net fotoaparato laikiklį, taip užtikrindami, kad turėsite viską, ko reikia sėkmingam žvejybos žygiui.</p>\n<p>Vandenyje svarbiausia - saugumas, todėl "Supernova Jr" turi gelbėjimo virvę, kuri suteikia daugiau ramybės. Turėdami &scaron;ią patikimą saugos priemonę, galite drąsiai leistis į kelionę ir mėgautis žvejybos nuotykiais.</p>\n<p>Kiekvienam žvejui labai svarbu efektyviai laikyti įrankius, o "Supernova Jr" tai užtikrina, nes jos galinėje dalyje įrengti lynai. Saugiai pritvirtinkite žvejybos įrankius, asmeninius daiktus ar papildomą įrangą, kad jie būtų tvarkingi ir lengvai pasiekiami žvejybos i&scaron;vykų metu.</p>\n<p>&nbsp;</p>\n<p>Svarbiausia - manevringumas, todėl "Supernova Jr" turi vairą ir rankinio valdymo sistemą, kad būtų galima tiksliai valdyti posūkius. Sklandžiai plaukite į kairę ir į de&scaron;inę, kad galėtumėte lengvai tyrinėti įvairias žvejybos vietas ir prisitaikyti prie besikeičiančių vandens sąlygų.</p>\n<p>"Galaxy Kayaks" kajake "Supernova Jr" su pedalais suderintas kompakti&scaron;kas dizainas, naujovi&scaron;kos funkcijos ir i&scaron;skirtinės eksploatacinės savybės, kad žvejai galėtų patirti nepamir&scaron;tamų žvejybos įspūdžių.</p>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/hShkaNcLWSM?si=3hic6TJ1U3Nm0cqq" width="640" height="480" data-mce-fragment="1"></iframe></div>\n<p>&nbsp;</p>\n<h3>Specifikacijos:</h3>\n<ul>\n<li>\n<p>Ilgis: 320 cm</p>\n</li>\n<li>\n<p>Plotis: 84 cm</p>\n</li>\n<li>\n<p>Auk&scaron;tis: 44 cm</p>\n</li>\n<li>\n<p>Didžiausias vežamas svoris: 194 kg</p>\n</li>\n<li>\n<p>Svoris: 46 kg</p>\n<p>&nbsp;</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>\n<p>&nbsp;</p>\n<p>Rekomenduojama gelbėjimosi liemenė (spausti ant teksto):&nbsp;<a href="https://vakasport.lt/nrs-chinook-fishing-pfd-zvejybine-gelbejimosi-liemene" rel="noopener noreferrer nofollow"><strong>NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė</strong></a></p>\n<p>&nbsp;</p>	8436618811196	1	2	1699.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737142307989-A7M00439.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737142307989-A7M00438.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737142307989-A7M00437.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239875226-A7M00419.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239875226-A7M00420.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239875227-A7M00421.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239875227-A7M00422.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239875227-A7M00423.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239875227-A7M00424.jpg"	Supernova Jr	\N	\N	46.000	\N	\N	\N	2025-05-14 18:59:18.499264	2025-05-14 21:46:07.245606
46	KR32-PB	Kanoja, Galaxy Kayaks,	<h2>Kanoja</h2>\n<p>&nbsp;</p>\n<p>🌊🚣&zwj;♂️ Ie&scaron;kote universalios ir patvarios kanojos kitam nuotykiui ant vandens? Ie&scaron;kokite tik 2-3 vietų baidarės "Galaxy Kayaks". &Scaron;i auk&scaron;čiausios kokybės baidarė yra puikus pasirinkimas visiems, norintiems patogiai ir stilingai tyrinėti gamtą.</p>\n<p>Pagaminta i&scaron; auk&scaron;čiausios kokybės medžiagų, &scaron;i baidarė sukurta taip, kad atlaikytų net sudėtingiausias sąlygas, todėl puikiai tinka viskam - nuo ramaus popietinio pasiplaukiojimo iki įspūdingos ekspedicijos upe. &Scaron;i baidarė yra erdvi ir patogi, joje gali tilpti iki trijų žmonių, todėl ji puikiai tinka &scaron;eimoms, draugams ar pavieniams nuotykių ie&scaron;kotojams, norintiems tyrinėti gamtą.</p>\n<p>🌟 Vienas i&scaron; i&scaron;skirtinių &scaron;ios baidarės bruožų - naujovi&scaron;kas dizainas. Dviejose sėdynėse įrengti patogūs atlo&scaron;ai, todėl galėsite patogiai irkluoti valandų valandas. Vidurinėje sėdynėje taip pat yra patogus daiktadėžė, kurioje rasite pakankamai vietos visiems būtiniausiems įrankiams ir reikmenims.</p>\n<p>Nesvarbu, ar esate patyręs irkluotojas, ar pradedantysis, 2-3 vietų "Galaxy Kayaks" baidarė yra puikus pasirinkimas kitam jūsų nuotykiui vandenyje. Dėl patvarios konstrukcijos, patogaus dizaino ir naujovi&scaron;kų funkcijų &scaron;i baidarė tikrai taps jūsų pasirinkimu visoms vandens pramogoms.</p>\n<p>🛶 Tad kam laukti? Užsisakykite 2-3 vietų baidarę i&scaron; "Galaxy Kayaks" jau &scaron;iandien ir pradėkite stilingai tyrinėti gamtą!</p>\n<p>&nbsp;</p>\n<h3>Kanojos irklas:</h3>\n<p>📏 Ilgis: 152 cm</p>\n<p>⚖️ N.W.: 0,850Kg.</p>\n<p>🛡️ mentės dydis: 520x200mm</p>\n<p>🛠️ Medžiaga: PP mentė, aliuminio kotas</p>\n<p>&nbsp;</p>\n<h3>📏 Kanojos Matmenys:</h3>\n<ul>\n<li>\n<p>Ilgis: 444 cm</p>\n</li>\n<li>\n<p>Plotis: 94 cm</p>\n</li>\n<li>\n<p>Auk&scaron;tis: 46 cm</p>\n</li>\n<li>\n<p>Svoris: 54 kg</p>\n<p>&nbsp;</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>Medžiaga i&scaron; kurios pagaminta kanoja: LLDPE</p>\n<p>Rekomenduojamas krovinio svoris iki: 350KG</p>\n<p>Kanojos sienelių storis: 5mm</p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>\n<p>&nbsp;</p>	8436618811455	2	3	1150.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1711299473766-A7M03375.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1711299473766-A7M03376.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1711299473765-A7M03374.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1711299473766-A7M03377.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1725629431890-canoe-paddle.jpg.png"	Kanoja	\N	\N	54.000	\N	\N	\N	2025-05-14 18:59:18.501107	2025-05-14 21:46:07.247733
47	KR36-SY	Kajakas - Baidarė, Galaxy Kayaks, Reef	<h3>REEF KAJAKAS</h3>\n<p>&nbsp;</p>\n<p>Reef kajakas yra patogus ir saugus pasirinkimas, pasižymintis kompakti&scaron;ku dizainu ir pakankamu saugojimo vietų kiekiu. Su tvirta tinkliu dengta saugojimo vieta ir patogia sėdyne, &scaron;is kajakas pasiruo&scaron;tas jūsų kitam nuotykiui.&nbsp;</p>\n<p>&nbsp;</p>\n<h3>Pagrindinės savybės:</h3>\n<ul>\n<li>\n<p>Stabilus ir patogus dizainas</p>\n</li>\n<li>\n<p>Lengva laikyti ir transportuoti</p>\n</li>\n<li>\n<p>Pilnai įrengtas sėdyne, plok&scaron;teliu ir tinklinės</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<h3>Specifikacijos:</h3>\n<ul>\n<li>\n<p>Dydis: 262*76*29 cm</p>\n</li>\n<li>\n<p>Rekomenduojamas krovinio svoris iki: 130.00 kg</p>\n</li>\n<li>\n<p>Leidžiama keleivių talpa: 1 asmuo</p>\n</li>\n<li>\n<p>Bendras svoris: 18.5 kg / Neto svoris: 17 kg</p>\n</li>\n<li>\n<p>Rekomenduojami naudotojai: Suaugę</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>	8436618814579	0	2	349.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727272950565-https___b2b.galaxykayaks.eu_5894_reef-adult.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703244901815-Reef%20one.webp"	Reef	\N	\N	17.000	\N	\N	\N	2025-05-14 18:59:18.502539	2025-05-14 21:46:07.249735
48	KR25-MS	Kajakas - Baidarė, Galaxy Kayaks, Tahiti Tandem 2+1	<h2 data-pm-slice="1 1 []"><strong>Tahiti Tandem 2/3 vietų žvejybinis kajakas su auk&scaron;tomis sėdynėmis</strong></h2>\n<p><strong>Galaxy Kayaks Tahiti Tandem</strong> &ndash; tai universalus 2&ndash;3 vietų žvejybinis kajakas, sukurtas nuotykiams su &scaron;eima ar draugais. Kajakas turi <strong>vidurinę sėdynę</strong>, tinkamą vaikui ar vienam žmogui, todėl puikiai tinka tiek tandeminiam, tiek solo naudojimui.</p>\n<p>Pagal poreikį galima rinktis <strong>auk&scaron;tas</strong> arba <strong>žemas sėdynes</strong> (parduodamos atskirai). Žema sėdynė užtikrina geresnį stabilumą, o auk&scaron;ta &ndash; daugiau komforto ir matomumo, kas itin svarbu ilgesnėse žvejybose.</p>\n<p>Kajake standarti&scaron;kai įrengti <strong>keturi&nbsp;įleistiniai me&scaron;kerių laikikliai</strong> ir <strong>du pasukami laikikliai</strong>, todėl jis puikiai pritaikytas žvejybai. Be to, <strong>variniai įdėklai</strong> leidžia prie centrinės konsolės prijungti kojų atramos sistemą ir kajaką naudoti kaip <strong>solo pedalų kajaką</strong>.</p>\n<p>Patogumą užtikrina <strong>du vandeniui atsparūs liukai</strong> ir galinė daiktadėžė su elastinėmis virvėmis.</p>\n<hr />\n<h3><strong>Pagrindiniai privalumai:</strong></h3>\n<ul>\n<li>\n<p>Vidurinė sėdynė vaikui arba solo naudojimui</p>\n</li>\n<li>\n<p>Galimybė naudoti auk&scaron;tas arba žemas sėdynes (parduodamos atskirai)</p>\n</li>\n<li>\n<p>4 įleistiniai ir 2 pasukami me&scaron;kerių laikikliai</p>\n</li>\n<li>\n<p>Variniai įdėklai kojų atramos sistemai (parduodami atskirai)</p>\n</li>\n<li>\n<p>Talpi daiktų laikymo erdvė: 2 liukai ir galinė daiktadėžė su elastikais</p>\n</li>\n<li>\n<p>Tvirta, stabili konstrukcija, tinkanti tiek ramiam, tiek aktyviam naudojimui</p>\n</li>\n</ul>\n<hr />\n<h3><strong>Techninės specifikacijos:</strong></h3>\n<ul>\n<li>\n<p><strong>Ilgis:</strong> 370 cm</p>\n</li>\n<li>\n<p><strong>Plotis:</strong> 86 cm</p>\n</li>\n<li>\n<p><strong>Auk&scaron;tis:</strong> 40 cm</p>\n</li>\n<li>\n<p><strong>Svoris:</strong> 41 kg</p>\n</li>\n<li>\n<p><strong>Rekomenduojama apkrova:</strong> 270 kg</p>\n<p>&nbsp;</p>\n</li>\n</ul>\n<hr />\n<h3><strong>Kas įtraukta į kainą?</strong></h3>\n<ul>\n<li>\n<p>Kajako korpusas</p>\n</li>\n<li>\n<p>4 įleistiniai me&scaron;kerių laikikliai</p>\n</li>\n<li>\n<p>2 pasukami me&scaron;kerių laikikliai</p>\n</li>\n<li>\n<p>2 vandeniui atsparūs liukai</p>\n</li>\n<li>\n<p>Galinė daiktadėžė su elastikais</p>\n</li>\n<li>\n<p>2 Auk&scaron;tos sėdynės</p>\n</li>\n</ul>\n<hr />\n<h3><strong>Kodėl verta rinktis Galaxy Kayaks i&scaron; </strong><a href="http://vakasport.lt/" target="_blank" rel="noopener noreferrer nofollow"><strong>VAKASPORT.LT</strong></a><strong>?</strong></h3>\n<ul>\n<li>\n<p>Oficiali Galaxy Kayaks atstovybė Baltijos &scaron;alyse</p>\n</li>\n<li>\n<p>Daugiau nei 30 000 parduotų kajakų visoje Europoje</p>\n</li>\n<li>\n<p>CE sertifikuotas produktas</p>\n</li>\n<li>\n<p>2 metų garantija korpusui</p>\n</li>\n<li>\n<p>Profesionalus aptarnavimas ir pagalba prie&scaron; ir po pirkimo</p>\n</li>\n</ul>\n<hr />\n<p><strong>Tahiti Tandem</strong> &ndash; tai patikimas, universalus ir prakti&scaron;kas pasirinkimas žvejybai ar poilsiui vandenyje.</p>\n<p>&nbsp;</p>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/Nebv94EscWk?si=YHPe2fC83IvfO0-_" width="640" height="480" allowfullscreen="allowfullscreen" data-mce-fragment="1"></iframe></div>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>	8436618810939	0	3	969.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1711302375650-A7M00343.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1711302375649-A7M00341.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1711302375650-A7M00342.jpg"	Tahiti Tandem 2+1	\N	\N	41.000	\N	\N	\N	2025-05-14 18:59:18.5041	2025-05-14 21:46:07.251645
49	KR25-MC	Kajakas - Baidarė, Galaxy Kayaks, Tahiti Tandem 2+1	<h2 data-pm-slice="1 1 []"><strong>Tahiti Tandem 2/3 vietų žvejybinis kajakas su auk&scaron;tomis sėdynėmis</strong></h2>\n<p><strong>Galaxy Kayaks Tahiti Tandem</strong> &ndash; tai universalus 2&ndash;3 vietų žvejybinis kajakas, sukurtas nuotykiams su &scaron;eima ar draugais. Kajakas turi <strong>vidurinę sėdynę</strong>, tinkamą vaikui ar vienam žmogui, todėl puikiai tinka tiek tandeminiam, tiek solo naudojimui.</p>\n<p>Pagal poreikį galima rinktis <strong>auk&scaron;tas</strong> arba <strong>žemas sėdynes</strong> (parduodamos atskirai). Žema sėdynė užtikrina geresnį stabilumą, o auk&scaron;ta &ndash; daugiau komforto ir matomumo, kas itin svarbu ilgesnėse žvejybose.</p>\n<p>Kajake standarti&scaron;kai įrengti <strong>keturi&nbsp;įleistiniai me&scaron;kerių laikikliai</strong> ir <strong>du pasukami laikikliai</strong>, todėl jis puikiai pritaikytas žvejybai. Be to, <strong>variniai įdėklai</strong> leidžia prie centrinės konsolės prijungti kojų atramos sistemą ir kajaką naudoti kaip <strong>solo pedalų kajaką</strong>.</p>\n<p>Patogumą užtikrina <strong>du vandeniui atsparūs liukai</strong> ir galinė daiktadėžė su elastinėmis virvėmis.</p>\n<hr />\n<h3><strong>Pagrindiniai privalumai:</strong></h3>\n<ul>\n<li>\n<p>Vidurinė sėdynė vaikui arba solo naudojimui</p>\n</li>\n<li>\n<p>Galimybė naudoti auk&scaron;tas arba žemas sėdynes (parduodamos atskirai)</p>\n</li>\n<li>\n<p>4 įleistiniai ir 2 pasukami me&scaron;kerių laikikliai</p>\n</li>\n<li>\n<p>Variniai įdėklai kojų atramos sistemai (parduodami atskirai)</p>\n</li>\n<li>\n<p>Talpi daiktų laikymo erdvė: 2 liukai ir galinė daiktadėžė su elastikais</p>\n</li>\n<li>\n<p>Tvirta, stabili konstrukcija, tinkanti tiek ramiam, tiek aktyviam naudojimui</p>\n</li>\n</ul>\n<hr />\n<h3><strong>Techninės specifikacijos:</strong></h3>\n<ul>\n<li>\n<p><strong>Ilgis:</strong> 370 cm</p>\n</li>\n<li>\n<p><strong>Plotis:</strong> 86 cm</p>\n</li>\n<li>\n<p><strong>Auk&scaron;tis:</strong> 40 cm</p>\n</li>\n<li>\n<p><strong>Svoris:</strong> 41 kg</p>\n</li>\n<li>\n<p><strong>Rekomenduojama apkrova:</strong> 270 kg</p>\n<p>&nbsp;</p>\n</li>\n</ul>\n<hr />\n<h3><strong>Kas įtraukta į kainą?</strong></h3>\n<ul>\n<li>\n<p>Kajako korpusas</p>\n</li>\n<li>\n<p>4 įleistiniai me&scaron;kerių laikikliai</p>\n</li>\n<li>\n<p>2 pasukami me&scaron;kerių laikikliai</p>\n</li>\n<li>\n<p>2 vandeniui atsparūs liukai</p>\n</li>\n<li>\n<p>Galinė daiktadėžė su elastikais</p>\n</li>\n<li>\n<p>2 Auk&scaron;tos sėdynės</p>\n</li>\n</ul>\n<hr />\n<h3><strong>Kodėl verta rinktis Galaxy Kayaks i&scaron; </strong><a href="http://vakasport.lt/" target="_blank" rel="noopener noreferrer nofollow"><strong>VAKASPORT.LT</strong></a><strong>?</strong></h3>\n<ul>\n<li>\n<p>Oficiali Galaxy Kayaks atstovybė Baltijos &scaron;alyse</p>\n</li>\n<li>\n<p>Daugiau nei 30 000 parduotų kajakų visoje Europoje</p>\n</li>\n<li>\n<p>CE sertifikuotas produktas</p>\n</li>\n<li>\n<p>2 metų garantija korpusui</p>\n</li>\n<li>\n<p>Profesionalus aptarnavimas ir pagalba prie&scaron; ir po pirkimo</p>\n</li>\n</ul>\n<hr />\n<p><strong>Tahiti Tandem</strong> &ndash; tai patikimas, universalus ir prakti&scaron;kas pasirinkimas žvejybai ar poilsiui vandenyje.</p>\n<p>&nbsp;</p>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/Nebv94EscWk?si=YHPe2fC83IvfO0-_" width="640" height="480" allowfullscreen="allowfullscreen" data-mce-fragment="1"></iframe></div>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>	8436618810885	2	3	799.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1711302418746-A7M00387.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1711302418745-A7M00386.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1711302418745-A7M00386.jpg"	Tahiti Tandem 2+1	\N	\N	41.000	\N	\N	\N	2025-05-14 18:59:18.505525	2025-05-14 21:46:07.253818
50	KR20-MS	Žvejybinis Kajakas - Baidarė, Galaxy Kayaks, Supernova FX	<p>🚀🌊 Pristatome naująją "<strong>Galaxy Supernova FX</strong>" - tai universalumo ir naujovių kupinas kajako komplektas. Galimybės plaukti mūsų pažangiausia Cyclone pedalų pavara, Torqeedo varikliu arba tradiciniu irklu - &scaron;is kajakas užtikrina, kad būsite pasirengę bet kokiai kelionei.</p>\n<p>&nbsp;</p>\n<h3>🌟 Kas naujo &scaron;iame modelyje?</h3>\n<ul>\n<li>\n<p>Torqeedo Ready: Paruo&scaron;tas sklandžiai integracijai su "Torqeedo" variklio įrenginiais, su patogiais įdėklais baidarės gale.</p>\n</li>\n<li>\n<p>Atnaujintas liukas: lengvesnė prieiga su svirties atidarymo sistema, kuri padidina patogumą ir preinamumą būnant ant vandens.</p>\n</li>\n<li>\n<p>Didesnė stačiakampė daiktadėžė: Padidinta liuko dangčio talpa, puikiai tinkanti visiems jūsų daiktams laikyti.</p>\n</li>\n<li>\n<p>Patobulintos vairo manevringumo galimybės: Padidėjęs posūkio kampas suteikia a&scaron;tresnių posūkių ir leidžia geriau valdyti kajaką.</p>\n</li>\n<li>\n<p>Naujai sukurtos EVA dugno gumos: Efektyvi žvejyba atsistojus - stilius ir patogumas.</p>\n</li>\n<li>\n<p>Patobulinta "Vista" sėdynė: Mėgaukitės didesniu komfortu ir galimybe reguliuoti, naudodami patobulintą sėdynę.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>💨 Speciali "Cyclone" pedalų pavara leidžia kajakams "Supernova FX" lengvai judėti pirmyn ir atgal. &Scaron;i varomoji sistema, sukurta taip, kad sklandžiai įsilietų į naująjį korpusą, suteikia galimybę plaukti be rankų, todėl galite sutelkti dėmesį į žvejybą.</p>\n<p>&nbsp;</p>\n<p>⚡ Dar viena įdomi funkcija - "Torqeedo" parengtis, todėl įrengimas tampa lengvas, o prireikus galite pasirinkti papildomą varomąją jėgą - elektrinį variklį.</p>\n<p>🛶 397,5 cm ilgio, 85,5 cm pločio ir 48 cm auk&scaron;čio "Supernova FX" yra erdvus&nbsp; pedalais varomas kajakas, kuriame pirmenybė teikiama stabilumui ir kreiseriniam greičiui, kad jums būtų patogu ir malonu plaukti vandeniu.</p>\n<p>🎣 Kupina funkcijų, "Supernova FX" užtikrina i&scaron;skirtinę žūklės patirtį. Visame kajake strategi&scaron;kai i&scaron;dėstyti &scaron;e&scaron;i bėgeliai, įskaitant didelius abiejuose &scaron;onuose ir mažus priekyje ir gale, todėl turite pakankamai vietos pritaikyti savo įrangą tokiems priedams kaip me&scaron;kerių laikikliai, kamerų strėlės ar žuvų ie&scaron;kikliai.</p>\n<p>📦 Daiktų laikymo vietos yra daug: naujai suprojektuotas galinis liukas, skirtas didesniems akumuliatoriams, ir priekinis liukas su atidarymo svirtimi sistema, kad būtų galima lengvai pasiekti laikomus daiktus.</p>\n<p>🛡️ Siekiant didesnio saugumo ir patvarumo, "Supernova FX" turi keičiamą apsauginę įvorę apačioje ir gelbėjimo virves visoje baidarės dalyje, užtikrinančias ramybę jūsų nuotykių metu.</p>\n<p>&nbsp;</p>\n<p>🔍 Kajako specifikacijos:</p>\n<ul>\n<li>\n<p>Dydis: 397,5 x 85,5 x 48 cm</p>\n</li>\n<li>\n<p>Svoris: 41,5 kg (su sėdyne); 38,9 kg (be sėdynės)</p>\n</li>\n<li>\n<p><strong>Rekomenduojamas maksimalus krovinio svoris: 200kg</strong></p>\n<p>&nbsp;</p>\n</li>\n<li>\n<p>Priekinio liuko dydis: 68,6 x 56 x 8,7 cm</p>\n</li>\n<li>\n<p>Galinio liuko dydis: 41,2 x 34,5 x 4,5 cm</p>\n</li>\n<li>\n<p>Vairo dydis: 297 x 215 x 49 mm</p>\n</li>\n<li>\n<p>Vairo rankenos dydis: 157 x 106 x 80 mm</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>🔧 Cyclone pedalo specifikacijos:</p>\n<ul>\n<li>\n<p>Propelerio santykis: 1:10,5</p>\n</li>\n<li>\n<p>Propelerio dydis: 29,8 cm</p>\n</li>\n<li>\n<p>Krumpliaračių dydis: 18,5 cm</p>\n</li>\n<li>\n<p>Medžiaga: jūrinis aliuminis</p>\n</li>\n<li>\n<p>Svoris: 6,5 kg</p>\n</li>\n<li>\n<p>Auk&scaron;tis: 77 cm (be pedalų), 87,2 cm su pedalais</p>\n</li>\n<li>\n<p>Plotis: 37,4 cm</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>🛶 Kartu su kajaku, komplektacijoje jūs gaunate:</p>\n<ul>\n<li>\n<p>Cyclone pedalų pavaros sistema</p>\n</li>\n<li>\n<p>Perdarytas priekinis liukas</p>\n</li>\n<li>\n<p>Didesnis vairo manevringumas</p>\n</li>\n<li>\n<p>EVA dugno gumos</p>\n</li>\n<li>\n<p>Patobulinta "Vista" sėdynė</p>\n</li>\n<li>\n<p>Didesnis galinis liukas</p>\n<p>&nbsp;</p>\n</li>\n<li>\n<p>Forma patobulinta taip, kad būtų tvirtesni bėgiai</p>\n<p>&nbsp;</p>\n</li>\n<li>\n<p>Gelbėjimo lynas pagamintas i&scaron; patvarios virvės</p>\n</li>\n<li>\n<p>Galinė laikymo vieta su tampriomis virvėmis</p>\n</li>\n<li>\n<p>6 bėgių laikikliai</p>\n</li>\n<li>\n<p>Rankinio vairo valdymo sistema</p>\n</li>\n<li>\n<p>Auk&scaron;ta sėdynė&nbsp;</p>\n</li>\n<li>\n<p>2 x "Railblaza" me&scaron;kerių laikikliai</p>\n</li>\n<li>\n<p>2 x Railblaza MiniPort TracMount</p>\n</li>\n<li>\n<p>Priekinė laikymo vieta su liuko dangčiu</p>\n</li>\n<li>\n<p>11 drenažo ta&scaron;kų</p>\n</li>\n<li>\n<p>11 didelių &scaron;ulinių kam&scaron;čių</p>\n<p>&nbsp;</p>\n</li>\n<li>\n<p>1 profiliuota priekinė rankena</p>\n</li>\n<li>\n<p>1 profiliuota galinė rankena</p>\n</li>\n<li>\n<p>2 x &scaron;oninės rankenos</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>🚣&zwj;♂️ Užtikrinkite papildomą savo įrangos saugumą naudodami papildomus galinėje bagažinėje esančius bungee lynus ir pasirinkite pageidaujamą i&scaron;vaizdą su mūsų Galaxy HV Series&trade;. Nesvarbu, ar tai būtų didesnis saugumas, ar stilius, pasirinkite patys!</p>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>	8436618811240	2	3	1999.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737141971950-4.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239377462-A7M00508.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239377461-A7M00504.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239377461-A7M00505.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239377462-A7M00506.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411661-A7M00535.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411663-A7M00536.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411663-A7M00537.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411664-A7M00538.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411664-A7M00539.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411665-A7M00540.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411665-A7M00541.jpg"	Supernova FX	\N	\N	57.000	\N	\N	\N	2025-05-14 18:59:18.50686	2025-05-14 21:46:07.256006
51	KP-KR20-MS	Žvejybinis Kajakas - Baidarė, Galaxy Kayaks, Supernova FX	<p>🚀🌊 Pristatome naująją "<strong>Galaxy Supernova FX</strong>" - tai universalumo ir naujovių kupinas kajako komplektas. Galimybės plaukti mūsų pažangiausia Cyclone pedalų pavara, Torqeedo varikliu arba tradiciniu irklu - &scaron;is kajakas užtikrina, kad būsite pasirengę bet kokiai kelionei.</p>\n<p>&nbsp;</p>\n<h3>🌟 Kas naujo &scaron;iame modelyje?</h3>\n<ul>\n<li>\n<p>Torqeedo Ready: Paruo&scaron;tas sklandžiai integracijai su "Torqeedo" variklio įrenginiais, su patogiais įdėklais baidarės gale.</p>\n</li>\n<li>\n<p>Atnaujintas liukas: lengvesnė prieiga su svirties atidarymo sistema, kuri padidina patogumą ir preinamumą būnant ant vandens.</p>\n</li>\n<li>\n<p>Didesnė stačiakampė daiktadėžė: Padidinta liuko dangčio talpa, puikiai tinkanti visiems jūsų daiktams laikyti.</p>\n</li>\n<li>\n<p>Patobulintos vairo manevringumo galimybės: Padidėjęs posūkio kampas suteikia a&scaron;tresnių posūkių ir leidžia geriau valdyti kajaką.</p>\n</li>\n<li>\n<p>Naujai sukurtos EVA dugno gumos: Efektyvi žvejyba atsistojus - stilius ir patogumas.</p>\n</li>\n<li>\n<p>Patobulinta "Vista" sėdynė: Mėgaukitės didesniu komfortu ir galimybe reguliuoti, naudodami patobulintą sėdynę.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>💨 Speciali "Cyclone" pedalų pavara leidžia kajakams "Supernova FX" lengvai judėti pirmyn ir atgal. &Scaron;i varomoji sistema, sukurta taip, kad sklandžiai įsilietų į naująjį korpusą, suteikia galimybę plaukti be rankų, todėl galite sutelkti dėmesį į žvejybą.</p>\n<p>&nbsp;</p>\n<p>⚡ Dar viena įdomi funkcija - "Torqeedo" parengtis, todėl įrengimas tampa lengvas, o prireikus galite pasirinkti papildomą varomąją jėgą - elektrinį variklį.</p>\n<p>🛶 397,5 cm ilgio, 85,5 cm pločio ir 48 cm auk&scaron;čio "Supernova FX" yra erdvus&nbsp; pedalais varomas kajakas, kuriame pirmenybė teikiama stabilumui ir kreiseriniam greičiui, kad jums būtų patogu ir malonu plaukti vandeniu.</p>\n<p>🎣 Kupina funkcijų, "Supernova FX" užtikrina i&scaron;skirtinę žūklės patirtį. Visame kajake strategi&scaron;kai i&scaron;dėstyti &scaron;e&scaron;i bėgeliai, įskaitant didelius abiejuose &scaron;onuose ir mažus priekyje ir gale, todėl turite pakankamai vietos pritaikyti savo įrangą tokiems priedams kaip me&scaron;kerių laikikliai, kamerų strėlės ar žuvų ie&scaron;kikliai.</p>\n<p>📦 Daiktų laikymo vietos yra daug: naujai suprojektuotas galinis liukas, skirtas didesniems akumuliatoriams, ir priekinis liukas su atidarymo svirtimi sistema, kad būtų galima lengvai pasiekti laikomus daiktus.</p>\n<p>🛡️ Siekiant didesnio saugumo ir patvarumo, "Supernova FX" turi keičiamą apsauginę įvorę apačioje ir gelbėjimo virves visoje baidarės dalyje, užtikrinančias ramybę jūsų nuotykių metu.</p>\n<p>&nbsp;</p>\n<p>🔍 Kajako specifikacijos:</p>\n<ul>\n<li>\n<p>Dydis: 397,5 x 85,5 x 48 cm</p>\n</li>\n<li>\n<p>Svoris: 41,5 kg (su sėdyne); 38,9 kg (be sėdynės)</p>\n</li>\n<li>\n<p><strong>Rekomenduojamas maksimalus krovinio svoris: 200kg</strong></p>\n<p>&nbsp;</p>\n</li>\n<li>\n<p>Priekinio liuko dydis: 68,6 x 56 x 8,7 cm</p>\n</li>\n<li>\n<p>Galinio liuko dydis: 41,2 x 34,5 x 4,5 cm</p>\n</li>\n<li>\n<p>Vairo dydis: 297 x 215 x 49 mm</p>\n</li>\n<li>\n<p>Vairo rankenos dydis: 157 x 106 x 80 mm</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>🔧 Cyclone pedalo specifikacijos:</p>\n<ul>\n<li>\n<p>Propelerio santykis: 1:10,5</p>\n</li>\n<li>\n<p>Propelerio dydis: 29,8 cm</p>\n</li>\n<li>\n<p>Krumpliaračių dydis: 18,5 cm</p>\n</li>\n<li>\n<p>Medžiaga: jūrinis aliuminis</p>\n</li>\n<li>\n<p>Svoris: 6,5 kg</p>\n</li>\n<li>\n<p>Auk&scaron;tis: 77 cm (be pedalų), 87,2 cm su pedalais</p>\n</li>\n<li>\n<p>Plotis: 37,4 cm</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>🛶 Kartu su kajaku, komplektacijoje jūs gaunate:</p>\n<ul>\n<li>\n<p>Cyclone pedalų pavaros sistema</p>\n</li>\n<li>\n<p>Perdarytas priekinis liukas</p>\n</li>\n<li>\n<p>Didesnis vairo manevringumas</p>\n</li>\n<li>\n<p>EVA dugno gumos</p>\n</li>\n<li>\n<p>Patobulinta "Vista" sėdynė</p>\n</li>\n<li>\n<p>Didesnis galinis liukas</p>\n<p>&nbsp;</p>\n</li>\n<li>\n<p>Forma patobulinta taip, kad būtų tvirtesni bėgiai</p>\n<p>&nbsp;</p>\n</li>\n<li>\n<p>Gelbėjimo lynas pagamintas i&scaron; patvarios virvės</p>\n</li>\n<li>\n<p>Galinė laikymo vieta su tampriomis virvėmis</p>\n</li>\n<li>\n<p>6 bėgių laikikliai</p>\n</li>\n<li>\n<p>Rankinio vairo valdymo sistema</p>\n</li>\n<li>\n<p>Auk&scaron;ta sėdynė&nbsp;</p>\n</li>\n<li>\n<p>2 x "Railblaza" me&scaron;kerių laikikliai</p>\n</li>\n<li>\n<p>2 x Railblaza MiniPort TracMount</p>\n</li>\n<li>\n<p>Priekinė laikymo vieta su liuko dangčiu</p>\n</li>\n<li>\n<p>11 drenažo ta&scaron;kų</p>\n</li>\n<li>\n<p>11 didelių &scaron;ulinių kam&scaron;čių</p>\n<p>&nbsp;</p>\n</li>\n<li>\n<p>1 profiliuota priekinė rankena</p>\n</li>\n<li>\n<p>1 profiliuota galinė rankena</p>\n</li>\n<li>\n<p>2 x &scaron;oninės rankenos</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>🚣&zwj;♂️ Užtikrinkite papildomą savo įrangos saugumą naudodami papildomus galinėje bagažinėje esančius bungee lynus ir pasirinkite pageidaujamą i&scaron;vaizdą su mūsų Galaxy HV Series&trade;. Nesvarbu, ar tai būtų didesnis saugumas, ar stilius, pasirinkite patys!</p>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>	8436618811241	2	3	1999.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737141971950-4.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239377462-A7M00508.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239377461-A7M00504.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239377461-A7M00505.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239377462-A7M00506.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411661-A7M00535.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411663-A7M00536.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411663-A7M00537.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411664-A7M00538.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411664-A7M00539.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411665-A7M00540.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703239411665-A7M00541.jpg"	Supernova FX	\N	\N	57.000	\N	\N	\N	2025-05-14 18:59:18.508285	2025-05-14 21:46:07.258164
17	PL3050Z	Plūdrumą palaikanti liemenė, 30-50 kg	<p>UNIVERSALI Vaiki&scaron;ka gelbėjimosi liemenė 30-50kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL3050</li>\n<li>Dydis: kūno svoris 30-50kg, krūtinės apimtis 65-84cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, žydra, juoda, raudona, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p><strong>&nbsp;</strong></p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p>&nbsp;</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607707	10	2	33.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326005-pludruma-palaikanti-liemene-30-50-kg-34f90_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326005-pludruma-palaikanti-liemene-30-50-kg-5aec7-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326007-pludruma-palaikanti-liemene-30-50-kg-b1dc6-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326007-pludruma-palaikanti-liemene-30-50-kg-aecc8-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.445602	2025-05-14 21:46:07.177259
18	PL3050R	Plūdrumą palaikanti liemenė, 30-50 kg	<p>UNIVERSALI Vaiki&scaron;ka gelbėjimosi liemenė 30-50kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL3050</li>\n<li>Dydis: kūno svoris 30-50kg, krūtinės apimtis 65-84cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, žydra, juoda, raudona, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p><strong>&nbsp;</strong></p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p>&nbsp;</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607714	10	2	33.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326008-pludruma-palaikanti-liemene-30-50-kg-f3bbd_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326006-pludruma-palaikanti-liemene-30-50-kg-10118-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326007-pludruma-palaikanti-liemene-30-50-kg-ce088-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326005-pludruma-palaikanti-liemene-30-50-kg-4b5d4-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.446986	2025-05-14 21:46:07.179193
52	KR09FX-MS	Žvejybinis Kajakas, Galaxy Kayaks, Alboran FX3	<p>🎣🌊 Pradėkite naują kajakų žvejybos erą su "Alboran FX3" - naujausiu "Galaxy Kayaks" pavyzdiniu modeliu. &Scaron;is kajakas sukurtas siekiant i&scaron; naujo pakeisti jūsų žūklės patirtį, joje suderintos naujovės, patogumas ir universalumas tiek pradedantiesiems, tiek patyrusiems žvejams.</p>\n<p>&nbsp;</p>\n<p>🔑 Pagrindinės savybės:</p>\n<ul>\n<li>\n<p>Stabilus, patogus ir auk&scaron;tos kokybės kajakas, skirtas visų lygių žvejams</p>\n</li>\n<li>\n<p>Ultralengva "Ultraline Flipper" varoma sistema, užtikrinanti lengvą slydimą vandeniu</p>\n</li>\n<li>\n<p>Cyclone Pedal Drive galimybė tiems, kurie pageidauja pedalų su varomąja jėga pirmyn ir atgal (rekomenduojama tik auk&scaron;tesniems nei 175 cm ūgio irkluotojams)</p>\n</li>\n<li>\n<p>Centrinis hermeti&scaron;kai užsandarintas laikymo liukas su galimybe naudoti kaip gyvojo masalo &scaron;ulinį, skirtą &scaron;lapioms arba sausoms sistemoms (tereikia pasirinkti, ar naudoti &scaron;liuzo kam&scaron;tį) ir su hermeti&scaron;ku sandarikliu</p>\n</li>\n<li>\n<p>Didesnis vairas su rankinio valdymo sistema tiksliam manevringumui užtikrinti</p>\n</li>\n<li>\n<p>"Galaxy High Chair" kėdutė, užtikrinanti maksimalų komfortą ilgas valandas ant vandens</p>\n</li>\n<li>\n<p>Keturi bėgeliai aksesuarams</p>\n</li>\n<li>\n<p>Penkios tvirtos laikymo rankenos</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>🌟 Alboran FX3 siūlo tris skirtingus varomosios jėgos būdus. Pasirinkite:</p>\n<ul>\n<li>\n<p>"Flipper Drive" greitam slydimui,</p>\n</li>\n<li>\n<p>"Cyclone Pedal" sistemą laisvų rankų judėjimui pirmyn ir atgal</p>\n</li>\n<li>\n<p>arba mėgaukitės laikui nepavaldžiu irklavimu.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>🔧 Torqueedo - paruo&scaron;ta elektrinui varikliui: Laikykitės už skrybėlių, nes "Alboran FX3" yra paruo&scaron;tas "Torqueedo". Galite pridėti elektros energijos pliūpsnį ir pakelti savo kajakų žygius į visi&scaron;kai naują lygį.</p>\n<p>&nbsp;</p>\n<p>🎣 I&scaron;laisvinkite savyje me&scaron;keriotoją: Patirkite neprilygstamą kontrolę su patobulinta "Alboran FX3" vairo sistema - didesne ir geresne nei bet kada anksčiau. Lengvai ir užtikrintai manevruokite bet kokiuose vandenyse.</p>\n<p>&nbsp;</p>\n<p>🛠️ Patogumas ir prakti&scaron;kumas: Alboran FX3 turi tvirtas rankenas, strategi&scaron;kai i&scaron;dėstytas priekyje, gale ir &scaron;onuose, todėl kajaką transportuoti bus paprasta. Patogumas dera su prakti&scaron;kumu!</p>\n<p>&nbsp;</p>\n<p>🔍 Specifikacijos:</p>\n<p>Ilgis: 408 cm, plotis: 80 cm, auk&scaron;tis: 35,5 cm.</p>\n<p>Svoris: 40 kg</p>\n<p>Didžiausias vežimo svoris: 180 kg</p>\n<p>Rekomenduojama žmonėms iki maks: Rekomenduojama: 115 kg</p>\n<p>🛶 Rinkitės "Alboran FX3", jei norite turėti geriausią žūklės kajakais patirtį!</p>\n<p>Pristatymo VIDEO:</p>\n<p><a href="https://www.youtube.com/watch?v=Z5hcZr23lOw">https://www.youtube.com/watch?v=Z5hcZr23lOw</a></p>\n<p>&nbsp;</p>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>	8436618810106	1	3	1899.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838188916-DSC09234.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1711301034690-Alboran-FX3-Comp.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838188915-DSC09228.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838188916-DSC09229.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838188916-DSC09230.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838188916-DSC09231.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838188916-DSC09232.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838188917-DSC09235.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838188917-DSC09237.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838243810-DSC09279.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838243811-DSC09280.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838243811-DSC09281.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838243811-DSC09283.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838243811-DSC09285.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838243811-DSC09286.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838243811-DSC09287.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838243811-DSC09288.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838243812-DSC09290.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838243812-DSC09291.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1712838243812-DSC09292.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1729103483627-462461879_968738191935807_2712163680308177748_n.jpg"	Alboran FX3	\N	\N	48.000	\N	\N	\N	2025-05-14 18:59:18.509936	2025-05-14 21:46:07.260818
54	86086.01.102	Pripučiama baidarė NRS Aster Packraft XL	<h3><strong>Aster Packraft &ndash; Puikus pasirinkimas pradedantiesiems ir savaitgalio nuotykių ie&scaron;kotojams</strong></h3>\n<p>&nbsp;</p>\n<p><strong>Aster Packraft</strong> sukurtas pradedantiesiems ir savaitgalio keliautojams, norintiems drąsiai tyrinėti ramius vandenis. Itin lengva ir patvari konstrukcija leidžia transportuoti vaikus ar papildomą įrangą, todėl &scaron;is plaustas puikiai tiks įvairioms i&scaron;vykoms.</p>\n<h3>Pagrindinės savybės:</h3>\n<ul>\n<li>\n<p><strong>Lengvumas ir patogumas</strong>:</p>\n<ul>\n<li>\n<p>Standartinė grindų konstrukcija sumažina svorį neprarandant patvarumo.</p>\n</li>\n<li>\n<p>Svoris: 2,8 kg (Aster) / 3 kg (Aster XL), todėl jį gali ne&scaron;ti net vaikai.</p>\n</li>\n</ul>\n</li>\n<li>\n<p><strong>Patvarios medžiagos</strong>:</p>\n<ul>\n<li>\n<p>Pagaminta i&scaron; PVC neturinčio nailono, padengto TPU danga i&scaron; vidaus ir i&scaron;orės, kad būtų užtikrintas geresnis oro i&scaron;laikymas ir atsparumas dilimui.</p>\n</li>\n<li>\n<p>TPU danga lengvai taisoma, todėl produkto tarnavimo laikas pailgėja.</p>\n</li>\n</ul>\n</li>\n<li>\n<p><strong>Tvirta konstrukcija</strong>:</p>\n<ul>\n<li>\n<p>Persidengiančios, &scaron;ilumos būdu suvirintos siūlės, papildomai sutvirtintos vidiniu juostavimu, užtikrina tvirtą ir patikimą oro i&scaron;laikymą.</p>\n</li>\n</ul>\n</li>\n<li>\n<p><strong>Komforti&scaron;ka irklavimo pozicija</strong>:</p>\n<ul>\n<li>\n<p>Pripučiama sėdynė ir atlo&scaron;as suteikia ergonomi&scaron;ką irklavimo komfortą.</p>\n</li>\n</ul>\n</li>\n<li>\n<p><strong>Funkcionalumas</strong>:</p>\n<ul>\n<li>\n<p>Keturi itin lengvi nailoniniai D formos žiedai priekyje leidžia patikimai pritvirtinti būtiniausius daiktus.</p>\n</li>\n<li>\n<p>Komplektacija: plaustas, pripūtimo mai&scaron;as, pūtimo vamzdelis ir taisymo rinkinys.</p>\n</li>\n</ul>\n</li>\n<li>\n<p><strong>Pakuotę sudaro:</strong></p>\n<ul>\n<li>\n<p>plaustas (baidarė)</p>\n</li>\n<li>\n<p>pripūtimo mai&scaron;elis,</p>\n</li>\n<li>\n<p>pripūtimo vamzdelis</p>\n</li>\n<li>\n<p>ir remonto rinkinys.</p>\n</li>\n</ul>\n</li>\n</ul>\n<p>&nbsp;</p>\n<h3>Specifikacija:</h3>\n<ul>\n<li>\n<p>Tipas: Pripučiama baidarė</p>\n</li>\n<li>\n<p>Ilgis: 245 cm</p>\n</li>\n<li>\n<p>Svoris: 3 kg</p>\n</li>\n<li>\n<p>Spalva: Mėlyna</p>\n</li>\n<li>\n<p>Keliamoji galia: 124 kg</p>\n</li>\n<li>\n<p>Pagrindinė medžiaga 70D nylon, dual TPU coated (PVC free)</p>\n</li>\n<li>\n<p>Paskirtis: Universlaus naudojimo</p>\n</li>\n<li>\n<p>Kilmės &scaron;alis: JAV</p>\n</li>\n<li>\n<p>Dugno medžiaga: 210D nylon, dual TPU coated (PVC-free)</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>NRS <strong>Aster Packraft XL</strong> pripūstas turi &scaron;iuos matmenis:</p>\n<ul>\n<li>\n<p><strong>I&scaron;oriniai matmenys:</strong></p>\n<ul>\n<li>\n<p><strong>Ilgis:</strong> 245 cm</p>\n</li>\n<li>\n<p><strong>Plotis:</strong> 99 cm</p>\n</li>\n<li>\n<p><strong>Vamzdžio skersmuo:</strong> 28 cm</p>\n</li>\n</ul>\n</li>\n<li>\n<p><strong>Vidiniai matmenys (kokpito):</strong></p>\n<ul>\n<li>\n<p><strong>Ilgis:</strong> 189 cm</p>\n</li>\n<li>\n<p><strong>Plotis:</strong> 43 cm</p>\n<p>&nbsp;</p>\n<p>&nbsp;</p>\n<p>&nbsp;</p>\n<p>Svarbi pastaba:</p>\n</li>\n</ul>\n</li>\n</ul>\n<p>Ilgalaikis saulės spindulių poveikis ar auk&scaron;ta temperatūra gali padidinti oro slėgį pripučiamose sėdynėse, todėl gali atsirasti per didelis pripūtimas, pažeisti siūles ar net sprogti sėdynė. Tokiose situacijose rekomenduojame sumažinti oro slėgį arba visi&scaron;kai i&scaron;leisti orą.</p>\n<p>&nbsp;</p>\n<p><strong>Aster Packraft</strong> &ndash; tai idealus pasirinkimas naujiems nuotykiams su lengvu, patikimu ir patvariu dizainu!</p>	603403481140	1	2	545.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1734266358837-86086_01_Blue_XL_Left_050624_1000x1000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1734266358837-86086_01_Blue_XL_TSB_050724_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1734266358837-86086_01_Blue_XL_Side_050724_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1734266358837-86086_01_Blue_XL_Top_050724_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1734266358837-86086_01_Blue_Reg_Detail_050624_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1734266358837-86086_01_Blue_Reg_Stern_050624_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1734266358836-86086_01_Blue_na_Kit_052224_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1734266358836-86086_01_Blue_na_Packaging_050624_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1734268084160-Screenshot2024-12-15at15.07.32.png"	Packraft	\N	\N	3.000	\N	\N	\N	2025-05-14 18:59:18.514479	2025-05-14 21:46:07.26548
15	PL3050M	Plūdrumą palaikanti liemenė, 30-50 kg	<p>UNIVERSALI Vaiki&scaron;ka gelbėjimosi liemenė 30-50kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL3050</li>\n<li>Dydis: kūno svoris 30-50kg, krūtinės apimtis 65-84cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, žydra, juoda, raudona, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p><strong>&nbsp;</strong></p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p>&nbsp;</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	754436607691	10	2	33.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326005-pludruma-palaikanti-liemene-30-50-kg-39fbc_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326006-pludruma-palaikanti-liemene-30-50-kg-206e7-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326007-pludruma-palaikanti-liemene-30-50-kg-b0aa1-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326007-pludruma-palaikanti-liemene-30-50-kg-98130-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.442182	2025-05-14 21:46:07.172379
16	PL3050J	Plūdrumą palaikanti liemenė, 30-50 kg	<p>UNIVERSALI Vaiki&scaron;ka gelbėjimosi liemenė 30-50kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL3050</li>\n<li>Dydis: kūno svoris 30-50kg, krūtinės apimtis 65-84cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; t.mėlyna, žydra, juoda, raudona, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p><strong>&nbsp;</strong></p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p>&nbsp;</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	4060059167174	10	2	33.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326004-pludruma-palaikanti-liemene-30-50-kg-2bbb9_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326008-pludruma-palaikanti-liemene-30-50-kg-e960d-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326006-pludruma-palaikanti-liemene-30-50-kg-218f0-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746964326006-pludruma-palaikanti-liemene-30-50-kg-401b8-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.443939	2025-05-14 21:46:07.174849
55	86149.01.101	NRS Clipper SUP Irklentė	<h3><strong>Clipper SUP Board &ndash; auk&scaron;čiausios klasės turizmo ir nuotykių irklentė laimėjusi&nbsp;</strong>2025 Metų Geriausio Produkto Apdovanojimą | SUP Kategorijoje <a href="https://www.thepaddlesportshow.com/product-of-the-year-awards-2025-sup-category/" rel="noopener noreferrer nofollow">The Paddle Sports Show parodoje</a></h3>\n<p>&nbsp;</p>\n<p><strong>Clipper SUP Board</strong> &ndash; tai auk&scaron;čiausios kokybės turizmo irklentė, sukurta siekiant suderinti valdymo tikslumą ir manevringumą. Su specialiai suformuota nosies ir galinės dalies konstrukcija, &scaron;i irklentė puikiai tinka tiek sudėtingoms kelionėms prie&scaron; vėją, tiek ramioms upių ekspedicijoms.</p>\n<p><strong>Pagrindinės savybės:</strong></p>\n<ul>\n<li>\n<p><strong>IST&trade; (Integrated Shaping Technology):</strong> Naudoja kelias oro kameras, sukuriant unikalią formą, pritaikytą turizmui.</p>\n</li>\n<li>\n<p><strong>True Balance:</strong> Visa IST serijos technologija ir medžiagos užtikrina neprilygstamą standumą, na&scaron;umą, stabilumą ir ilgaamži&scaron;kumą.</p>\n</li>\n<li>\n<p><strong>Z/Blend Core&trade;:</strong> Inovatyvi konstrukcija su audiniu, o ne mezginiu, dėl ko irklentė yra 20 % standesnė ir 15 % lengvesnė nei ankstesni modeliai.</p>\n</li>\n<li>\n<p><strong>Pagrindinė kamera:</strong> Pripučia iki 20 PSI, užtikrindama didžiausią standumą. &Scaron;oninės kameros pripučiamos iki 5 PSI.</p>\n</li>\n<li>\n<p><strong>V formos korpusas:</strong> Pagerina greitį ir kryptingumą turizmo metu.</p>\n</li>\n<li>\n<p><strong>DropDeck&trade;:</strong> Pagerina stabilumą, nuleidžiant platformą arčiau žemės ir i&scaron;laikant didelį tūrį.</p>\n</li>\n<li>\n<p><strong>EVA putplasčio danga:</strong> Su grioveliais, kurie pagerina sukibimą net esant &scaron;lapiai dangai.</p>\n</li>\n<li>\n<p><strong>IST i&scaron;gaubta konstrukcija:</strong> Trys kameros sukuria i&scaron;gaubtą &scaron;onų formą, leidžiančią vandeniui efektyviau tekėti link peleko ir užtikrinančią tylesnį ir &scaron;varesnį slydimą.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>Papildomi privalumai:</strong></p>\n<ul>\n<li>\n<p>Dvigubos &scaron;oninės sienelės maksimaliai ilgaamži&scaron;kumui.</p>\n</li>\n<li>\n<p><strong>QuickClick&trade;</strong> pelekų sistema pritaikoma individualiai.</p>\n</li>\n<li>\n<p>Nuimami, keičiamieji pelekai i&scaron; nailono ir plastiko &ndash; atlaiko smūgius nesulūždami.</p>\n</li>\n<li>\n<p>Kokybi&scaron;kas <strong>Bravo</strong> pripūtimo/ i&scaron;leidimo vožtuvas užtikrina lengvą irklentės laikymąsi mažoje erdvėje.</p>\n</li>\n<li>\n<p>Priekyje ir gale esančios tvirtinimo vietos leidžia pritvirtinti įrangą ilgesnėms kelionėms.</p>\n</li>\n<li>\n<p>Trys rankenos lengvam transportavimui; centrinė rankena aptraukta neoprenu, kad būtų patogiau.</p>\n</li>\n<li>\n<p>Nerūdijančio plieno D formos žiedas pavadėlio tvirtinimui.</p>\n</li>\n<li>\n<p>Komplektacija: auk&scaron;to slėgio <strong>Super Pump II</strong> (su slėgio matuokliu), vienas turizmo pelekas, vienas žolės pelekas, kelioninis kuprinis ir remonto rinkinys.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>Clipper SUP Board &ndash; auk&scaron;čiausios klasės turizmo ir nuotykių irklentė</strong></p>\n<p><strong>Specifikacija &ndash; 110W dydis:</strong></p>\n<ul>\n<li>\n<p><strong>Paskirtis:</strong> Nuotykių turizmas</p>\n</li>\n<li>\n<p><strong>I&scaron;matavimai:</strong> 3,3 m x 79 cm x 13 cm</p>\n</li>\n<li>\n<p><strong>Supakuoti i&scaron;matavimai:</strong> 73,8 cm x 50,8 cm x 25,4 cm</p>\n</li>\n<li>\n<p><strong>Nosies plotis:</strong> 35,5 cm</p>\n</li>\n<li>\n<p><strong>Galinės dalies plotis:</strong> 54,6 cm</p>\n</li>\n<li>\n<p><strong>Svoris:</strong> 10 kg</p>\n</li>\n<li>\n<p><strong>Tūris:</strong> 246 L</p>\n</li>\n<li>\n<p><strong>Rekomenduojamas irkluotojo svoris:</strong> 45&ndash;97 kg</p>\n</li>\n<li>\n<p><strong>Vožtuvo tipas:</strong> Bravo</p>\n</li>\n<li>\n<p><strong>Medžiaga:</strong> PVC i&scaron;orė, Z/Blend austas poliesterio &scaron;erdis</p>\n</li>\n<li>\n<p><strong>Rankenų skaičius:</strong> 3</p>\n</li>\n<li>\n<p><strong>Garantija:</strong>&nbsp;2 metai mažmeniam pirkėjams, 1 metai komerciniam naudojimui</p>\n</li>\n<li>\n<p><strong>Komplektacija:</strong></p>\n<ul>\n<li>\n<p>Auk&scaron;to slėgio Super Pump II su slėgio matuokliu</p>\n</li>\n<li>\n<p>1 turizmo pelekas</p>\n</li>\n<li>\n<p>1 žolės pelekas</p>\n</li>\n<li>\n<p>Kelioninė kuprinė</p>\n</li>\n<li>\n<p>Remonto rinkinys</p>\n</li>\n</ul>\n</li>\n</ul>\n<p><strong>Clipper SUP Board 110W dydis</strong> yra puikus pasirinkimas ie&scaron;kantiems irklentės, kuri būtų lengva, tvirta ir universali įvairioms kelionėms bei nuotykiams!</p>\n<p>&nbsp;</p>\n<h3><a href="https://youtu.be/VVtwj-CPl9k?si=WSKpZDoYb-z8nR91" rel="noopener noreferrer nofollow">VIDEO&nbsp;(spausti ant teksto)</a></h3>\n<h3><a href="https://youtu.be/PgWGRBpyoTA?si=mMRagdtpWUZ3zjGL" rel="noopener noreferrer nofollow">VIDEO 1 (spausti ant teksto)</a></h3>\n<h3><a href="https://youtu.be/HTab_kr2Re4?si=3NSAyte0h9YIpyic" rel="noopener noreferrer nofollow">VIDOE 2 (spausti ant teksto)</a></h3>\n<p>&nbsp;</p>\n<p><strong>Pastaba:</strong> Ilgas saulės poveikis ar auk&scaron;ta temperatūra gali padidinti irklentės oro slėgį, dėl ko gali atsirasti siūlių pažeidimų ar irklentė gali sprogti. Rekomenduojame esant tokioms sąlygoms sumažinti oro slėgį arba visi&scaron;kai i&scaron;leisti orą.</p>\n<p><strong>Clipper SUP Board</strong> yra rankų darbo, sukurta <strong>Idaho, JAV</strong>. Pasirinkite &scaron;ią irklentę ir mėgaukitės neprilygstamais nuotykiais ant vandens!</p>	603403481096	1	2	749.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727529014512-86149_01_White_110W_TSB_061423_1000x1000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736776900112-raoul-getraud-4538.jpeg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727529014512-86149_01_White_110W_Top_061423_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736776907207-Stand-Up-Paddling-2048x2048.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727529014511-86149_01_White_110W_Bottom_061423_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727529014511-86149_01_White_110W_Side_061423_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727529014511-86149_01_White_110W_LeftRear_061323_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727529014510-86149_01_na_na_Accessories_040224_1000x1000.jpg"	NRS Cliper	\N	\N	10.000	\N	\N	\N	2025-05-14 18:59:18.515942	2025-05-14 21:46:07.267793
31	PL100120M	Plūdrumą palaikanti liemenė, 100-120 kg	<p>UNIVERSALI Gelbėjimosi liemenė 100-120kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL100120</li>\n<li>Dydis: kūno svoris 100-120kg, krūtinės apimtis 104-130cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; juoda, t.mėlyna, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p>&nbsp;</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos</u>.</p>	754436608353	10	2	59.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459633-pludruma-palaikanti-liemene-100-120-kg-4b3cc_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459634-pludruma-palaikanti-liemene-100-120-kg-ea392-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459633-pludruma-palaikanti-liemene-100-120-kg-1b84a-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459634-pludruma-palaikanti-liemene-100-120-kg-f663d-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.473115	2025-05-14 21:46:07.210128
32	PL100120J	Plūdrumą palaikanti liemenė, 100-120 kg	<p>UNIVERSALI Gelbėjimosi liemenė 100-120kg WALLYS</p>\n<ul>\n<li>Pagaminta Lietuvoje</li>\n<li>Atitinka ES standartą</li>\n<li>EN ISO 12402-5 (50N)</li>\n<li>Plūdrumo liemenė. Mod. PL100120</li>\n<li>Dydis: kūno svoris 100-120kg, krūtinės apimtis 104-130cm</li>\n<li>Medžiagos: i&scaron;orė &ndash; tvirtas OXFORD audinys, vidus &ndash; pūsto polietileno įdėklas</li>\n<li>Liemenės apatinėje pamu&scaron;alo dalyje įsiūtas tinklelis, skirtas greitam vandens i&scaron;tekėjimui</li>\n<li>Patogi ki&scaron;enė kairėje liemenės pusėje užsegama lipduku</li>\n<li>Liemenė susegama tvirtomis YKK sagtimis ir užtrauktuku</li>\n<li>Spalvos &ndash; juoda, t.mėlyna, kamufliažinė</li>\n</ul>\n<p>&nbsp;</p>\n<p>Reglamentas (EU) 2016/425</p>\n<p>EN ISO 12402-5:2006+A1:2010 (50N)<br />Saugumo kat. II<br />Sertifikato Nr.<br />OOP-2452/EU-007/2021/01</p>\n<p>&nbsp;</p>\n<p><strong>NAUDOJIMOSI INSTRUKCIJA</strong></p>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<p><strong>PRIEŽIŪRA IR LAIKYMAS</strong></p>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.<br />Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.<br />Liemenė naudojama -30 +50 C<br />Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos</u>.</p>	754436608360	10	2	59.99	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459634-pludruma-palaikanti-liemene-100-120-kg-92441_reference.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459633-pludruma-palaikanti-liemene-100-120-kg-9a0af-internetu_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459633-pludruma-palaikanti-liemene-100-120-kg-72e81-kaina_reference.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1746899459633-pludruma-palaikanti-liemene-100-120-kg-3fc2e-atsiliepimai_reference.jpg"	\N	\N	\N	0.600	\N	\N	\N	2025-05-14 18:59:18.475011	2025-05-14 21:46:07.212577
56	60046.01.101	Transportavimo diržai NRS (4,5m)	<p><strong>NRS Buckle Bumper Strap - 4,5 metrų transportavimo diržai (komplekte 2 vienetai)</strong></p>\n<p>&nbsp;</p>\n<p>Apsaugokite savo valtį, kajaką, irklentę, sunkvežimį, priekabą ar keturratį motociklą, pritvirtindami krovinį su NRS transportavimo diržu. Nuimama guminė apsauga suteikia sagčiai atramos, kad būtų i&scaron;vengta nelaimingų atsitikimų ar sugadinimų. Po gumine apsauga yra ta pati tvirta NRS kum&scaron;telinė sagtis, kuri nuo 1978 m. yra tvirtumo ir patikimumo standartas.</p>\n<ul>\n<li>\n<p>Gimęs upėje, pasiruo&scaron;ęs bet kam - NRS dirželis visame pasaulyje garsėja savo nepaprastu tvirtumu ir naudingumu.</p>\n</li>\n<li>\n<p>2,5 cm pločio polipropileno diržo minimalus trūkimo stipris (MBS) yra 680 kg, jis nei&scaron;sitempia su&scaron;lapęs ir yra apdorotas, kad būtų apsaugotas nuo UV spindulių poveikio.</p>\n</li>\n<li>\n<p>Poliuretano apsauga apjuosia sagtį 360 laipsnių apsauga, netrukdydamas jai veikti.</p>\n</li>\n<li>\n<p>Dvigubos nerūdijančiojo plieno spyruoklės mūsų pritaikytoje kum&scaron;telinėje sagtyje sukuria tvirtą, tolygų užspaudimą, kuris niekada nei&scaron;slysta.</p>\n<p>&nbsp;</p>\n</li>\n<li>\n<p>Apsaugokite diržus nuo ilgalaikių skolininkų (žinote, kas jie tokie) užra&scaron;ydami savo vardą ir kontaktinę informaciją ant austos etiketės po sagtimi.</p>\n</li>\n<li>\n<p>Ant sagties paslėptas butelių atidarytuvas leidžia ne tik saugoti krovinį, bet ir apsirūpinti vandeniu.</p>\n</li>\n<li>\n<p>Visi dydžiai parduodami poromis.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><img title="" src="https://cdn.zyrosite.com/cdn-cgi/image/format=auto,fit=crop,q=80,w=600/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730227972775-Screenshot%202024-10-29%20at%2020.52.37.png" alt="" /></p>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>	603403431770	1	2	35.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730227343117-60046_01_Blue_Metric_ALLTop_012521_1000x1000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730227343118-60046_01_Blue_Metric45_Pair_012521_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730228419537-60028_01_Blue_na_BottomSide_021622_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730228444863-nrsbucklebumper-750x750.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730228454114-nrs-nrs-buckle-bumper-straps.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730229668447-60028_01_Blue_12_Packaging_011420_1000x1000_d73b0e05-827f-42fc-8dba-38a757bd243b_1080x.jpg.webp"	\N	\N	\N	1.000	\N	\N	\N	2025-05-14 18:59:18.517252	2025-05-14 21:46:07.269936
57	50126.01.100	NRS Yak Yak - Ratukai Kajakui ar valčiai gabenti XL	<h3><strong>NRS Yak Yak &ndash; lengvas ir patvarus kajakų vežimėlis su dydžio pasirinkimu</strong></h3>\n<p>Palengvinkite savo&nbsp;<strong>kajako, baidarės ar irklentės</strong>&nbsp;transportavimą su&nbsp;<strong>NRS Yak Yak</strong>&nbsp;vežimėliu! &Scaron;is itin lengvas ir kompakti&scaron;kas ratukų rinkinys padės be vargo nugabenti jūsų vandens transporto priemonę prie vandens telkinio, net jei kelias driekiasi per&nbsp;<strong>smėlį, žvyrą ar kitus sudėtingus pavir&scaron;ius</strong>.</p>\n<hr />\n<h3><strong>✅ Kodėl verta rinktis NRS Yak Yak?</strong></h3>\n<p>✔&nbsp;<strong>Lengvas ir patvarus</strong>&nbsp;&ndash; anoduoto aliuminio rėmas užtikrina tvirtumą ir ilgaamži&scaron;kumą.<br />✔&nbsp;<strong>Pasirinkite tinkamą dydį</strong>&nbsp;&ndash; galimi&nbsp;<strong>Regular (iki 68 kg)</strong>&nbsp;ir&nbsp;<strong>XL modelis (iki 90 kg)</strong>.<br />✔&nbsp;<strong>Smėlį įveikiančios padangos</strong>&nbsp;&ndash; 8 cm pločio ratlankiai (23 cm skersmens) suteikia puikią atramą mink&scaron;tose dangose.<br />✔&nbsp;<strong>30 % lengvesnis už įprastus kajakų vežimėlius</strong>&nbsp;&ndash; mažiau apkrovos jūsų nugarai!<br />✔&nbsp;<strong>Nuimami ratai be guolių</strong>&nbsp;&ndash; paprasta transportuoti ir sandėliuoti, tinka daugumai kajakų liukų.<br />✔&nbsp;<strong>Atraminis stovas</strong>&nbsp;&ndash; stabilus pakrovimas ir patogus naudojimas.<br />✔&nbsp;<strong>Korozijai atspari konstrukcija</strong>&nbsp;&ndash; užtikrina ilgaamži&scaron;kumą net sūriame vandenyje.<br />✔&nbsp;<strong>Amortizuojančios putplasčio pagalvėlės</strong>&nbsp;&ndash; apsaugo jūsų kajaką nuo pažeidimų.<br />✔&nbsp;<strong>Tvirtinimo diržai komplekte</strong>&nbsp;&ndash; 2 vnt. 1,8 m ilgio NRS kilpiniai diržai su patogiomis sagtimis.</p>\n<p>🎥&nbsp;<strong>Vaizdo įra&scaron;as:</strong>&nbsp;<a href="https://youtu.be/vn7DligxoYQ?si=H_EOmDd_i7jfx0a1" rel="noopener">NRS&nbsp;Yak&nbsp;Yak&nbsp;vežimėlis&nbsp;veiksme</a></p>\n<hr />\n<p>&nbsp;</p>\n<h3><strong>📏 Specifikacija:</strong></h3>\n<table><colgroup><col /><col /><col /></colgroup>\n<tbody>\n<tr>\n<th colspan="1" rowspan="1">\n<p>Parametras</p>\n</th>\n<th colspan="1" rowspan="1">\n<p><strong>Regular versija</strong></p>\n</th>\n<th colspan="1" rowspan="1">\n<p><strong>XL versija</strong></p>\n</th>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Maksimali apkrova</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>68 kg</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>90 kg</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Rėmo medžiaga</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Anoduotas aliuminis</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Anoduotas aliuminis</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Ratų skersmuo</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>23 cm</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>23 cm</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Ratų plotis</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>8 cm</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>8 cm</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Ratai</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Nuimami, be guolių</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Nuimami, be guolių</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Svoris</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Itin lengvas</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Itin lengvas</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Atraminis stovas</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Apsauginės pagalvėlės</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Korozijai atsparūs elementai</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Tvirtinimo diržai komplekte</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>2 vnt. (1,8 m)</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>2 vnt. (1,8 m)</p>\n</td>\n</tr>\n</tbody>\n</table>\n<p>&nbsp;</p>\n<p>👉&nbsp;<strong>Pasirinkite tinkamą dydį ir užsisakykite dabar!</strong>&nbsp;🚣&zwj;♂️</p>\n<p>&nbsp;</p>	603403338239	1	2	159.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736451847839-50126_01_062514_1000x1000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736451847840-50126_01_Front_062514_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736451847840-50126_01_Right_062514_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736452220129-Screenshot2025-01-09at21.50.01.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736452730318-Screenshot2025-01-09at21.56.53.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736452935465-Screenshot2025-01-09at22.01.33.png"	\N	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.518586	2025-05-14 21:46:07.272145
58	50125.01.100	NRS Yak Yak - Ratukai Kajakui ar valčiai gabenti	<h3><strong>NRS Yak Yak &ndash; lengvas ir patvarus kajakų vežimėlis su dydžio pasirinkimu</strong></h3>\n<p>Palengvinkite savo&nbsp;<strong>kajako, baidarės ar irklentės</strong>&nbsp;transportavimą su&nbsp;<strong>NRS Yak Yak</strong>&nbsp;vežimėliu! &Scaron;is itin lengvas ir kompakti&scaron;kas ratukų rinkinys padės be vargo nugabenti jūsų vandens transporto priemonę prie vandens telkinio, net jei kelias driekiasi per&nbsp;<strong>smėlį, žvyrą ar kitus sudėtingus pavir&scaron;ius</strong>.</p>\n<hr />\n<h3><strong>✅ Kodėl verta rinktis NRS Yak Yak?</strong></h3>\n<p>✔&nbsp;<strong>Lengvas ir patvarus</strong>&nbsp;&ndash; anoduoto aliuminio rėmas užtikrina tvirtumą ir ilgaamži&scaron;kumą.<br />✔&nbsp;<strong>Pasirinkite tinkamą dydį</strong>&nbsp;&ndash; galimi&nbsp;<strong>Regular (iki 68 kg)</strong>&nbsp;ir&nbsp;<strong>XL modelis (iki 90 kg)</strong>.<br />✔&nbsp;<strong>Smėlį įveikiančios padangos</strong>&nbsp;&ndash; 8 cm pločio ratlankiai (23 cm skersmens) suteikia puikią atramą mink&scaron;tose dangose.<br />✔&nbsp;<strong>30 % lengvesnis už įprastus kajakų vežimėlius</strong>&nbsp;&ndash; mažiau apkrovos jūsų nugarai!<br />✔&nbsp;<strong>Nuimami ratai be guolių</strong>&nbsp;&ndash; paprasta transportuoti ir sandėliuoti, tinka daugumai kajakų liukų.<br />✔&nbsp;<strong>Atraminis stovas</strong>&nbsp;&ndash; stabilus pakrovimas ir patogus naudojimas.<br />✔&nbsp;<strong>Korozijai atspari konstrukcija</strong>&nbsp;&ndash; užtikrina ilgaamži&scaron;kumą net sūriame vandenyje.<br />✔&nbsp;<strong>Amortizuojančios putplasčio pagalvėlės</strong>&nbsp;&ndash; apsaugo jūsų kajaką nuo pažeidimų.<br />✔&nbsp;<strong>Tvirtinimo diržai komplekte</strong>&nbsp;&ndash; 2 vnt. 1,8 m ilgio NRS kilpiniai diržai su patogiomis sagtimis.</p>\n<p>🎥&nbsp;<strong>Vaizdo įra&scaron;as:</strong>&nbsp;<a href="https://youtu.be/vn7DligxoYQ?si=H_EOmDd_i7jfx0a1" rel="noopener">NRS&nbsp;Yak&nbsp;Yak&nbsp;vežimėlis&nbsp;veiksme</a></p>\n<hr />\n<p>&nbsp;</p>\n<h3><strong>📏 Specifikacija:</strong></h3>\n<table><colgroup><col /><col /><col /></colgroup>\n<tbody>\n<tr>\n<th colspan="1" rowspan="1">\n<p>Parametras</p>\n</th>\n<th colspan="1" rowspan="1">\n<p><strong>Regular versija</strong></p>\n</th>\n<th colspan="1" rowspan="1">\n<p><strong>XL versija</strong></p>\n</th>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Maksimali apkrova</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>68 kg</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>90 kg</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Rėmo medžiaga</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Anoduotas aliuminis</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Anoduotas aliuminis</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Ratų skersmuo</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>23 cm</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>23 cm</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Ratų plotis</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>8 cm</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>8 cm</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Ratai</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Nuimami, be guolių</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Nuimami, be guolių</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Svoris</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Itin lengvas</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Itin lengvas</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Atraminis stovas</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Apsauginės pagalvėlės</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Korozijai atsparūs elementai</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Tvirtinimo diržai komplekte</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>2 vnt. (1,8 m)</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>2 vnt. (1,8 m)</p>\n</td>\n</tr>\n</tbody>\n</table>\n<p>&nbsp;</p>\n<p>👉&nbsp;<strong>Pasirinkite tinkamą dydį ir užsisakykite dabar!</strong>&nbsp;🚣&zwj;♂️</p>\n<p>&nbsp;</p>	603403338222	1	2	129.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1729105283023-50125_01_Left_Blue_062414_1000x1000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1729105283023-50125_01_Front_Blue_062414_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1729105283024-50125_01_Right_Blue_062414_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736452220129-Screenshot2025-01-09at21.50.01.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736452730318-Screenshot2025-01-09at21.56.53.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736452935465-Screenshot2025-01-09at22.01.33.png"	\N	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.519905	2025-05-14 21:46:07.274204
59	50126.01.100-1	NRS Yak Yak - Ratukai Kajakui transportuoti XL	<h3><strong>NRS Yak Yak &ndash; lengvas ir patvarus kajakų vežimėlis su dydžio pasirinkimu</strong></h3>\n<p>Palengvinkite savo&nbsp;<strong>kajako, baidarės ar irklentės</strong>&nbsp;transportavimą su&nbsp;<strong>NRS Yak Yak</strong>&nbsp;vežimėliu! &Scaron;is itin lengvas ir kompakti&scaron;kas ratukų rinkinys padės be vargo nugabenti jūsų vandens transporto priemonę prie vandens telkinio, net jei kelias driekiasi per&nbsp;<strong>smėlį, žvyrą ar kitus sudėtingus pavir&scaron;ius</strong>.</p>\n<hr />\n<h3><strong>✅ Kodėl verta rinktis NRS Yak Yak?</strong></h3>\n<p>✔&nbsp;<strong>Lengvas ir patvarus</strong>&nbsp;&ndash; anoduoto aliuminio rėmas užtikrina tvirtumą ir ilgaamži&scaron;kumą.<br />✔&nbsp;<strong>Pasirinkite tinkamą dydį</strong>&nbsp;&ndash; galimi&nbsp;<strong>Regular (iki 68 kg)</strong>&nbsp;ir&nbsp;<strong>XL modelis (iki 90 kg)</strong>.<br />✔&nbsp;<strong>Smėlį įveikiančios padangos</strong>&nbsp;&ndash; 8 cm pločio ratlankiai (23 cm skersmens) suteikia puikią atramą mink&scaron;tose dangose.<br />✔&nbsp;<strong>30 % lengvesnis už įprastus kajakų vežimėlius</strong>&nbsp;&ndash; mažiau apkrovos jūsų nugarai!<br />✔&nbsp;<strong>Nuimami ratai be guolių</strong>&nbsp;&ndash; paprasta transportuoti ir sandėliuoti, tinka daugumai kajakų liukų.<br />✔&nbsp;<strong>Atraminis stovas</strong>&nbsp;&ndash; stabilus pakrovimas ir patogus naudojimas.<br />✔&nbsp;<strong>Korozijai atspari konstrukcija</strong>&nbsp;&ndash; užtikrina ilgaamži&scaron;kumą net sūriame vandenyje.<br />✔&nbsp;<strong>Amortizuojančios putplasčio pagalvėlės</strong>&nbsp;&ndash; apsaugo jūsų kajaką nuo pažeidimų.<br />✔&nbsp;<strong>Tvirtinimo diržai komplekte</strong>&nbsp;&ndash; 2 vnt. 1,8 m ilgio NRS kilpiniai diržai su patogiomis sagtimis.</p>\n<p>🎥&nbsp;<strong>Vaizdo įra&scaron;as:</strong>&nbsp;<a href="https://youtu.be/vn7DligxoYQ?si=H_EOmDd_i7jfx0a1" rel="noopener">NRS&nbsp;Yak&nbsp;Yak&nbsp;vežimėlis&nbsp;veiksme</a></p>\n<hr />\n<p>&nbsp;</p>\n<h3><strong>📏 Specifikacija:</strong></h3>\n<table><colgroup><col /><col /><col /></colgroup>\n<tbody>\n<tr>\n<th colspan="1" rowspan="1">\n<p>Parametras</p>\n</th>\n<th colspan="1" rowspan="1">\n<p><strong>Regular versija</strong></p>\n</th>\n<th colspan="1" rowspan="1">\n<p><strong>XL versija</strong></p>\n</th>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Maksimali apkrova</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>68 kg</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>90 kg</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Rėmo medžiaga</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Anoduotas aliuminis</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Anoduotas aliuminis</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Ratų skersmuo</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>23 cm</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>23 cm</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Ratų plotis</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>8 cm</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>8 cm</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Ratai</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Nuimami, be guolių</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Nuimami, be guolių</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Svoris</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Itin lengvas</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Itin lengvas</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Atraminis stovas</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Apsauginės pagalvėlės</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Korozijai atsparūs elementai</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Tvirtinimo diržai komplekte</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>2 vnt. (1,8 m)</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>2 vnt. (1,8 m)</p>\n</td>\n</tr>\n</tbody>\n</table>\n<p>&nbsp;</p>\n<p>👉&nbsp;<strong>Pasirinkite tinkamą dydį ir užsisakykite dabar!</strong>&nbsp;🚣&zwj;♂️</p>\n<p>&nbsp;</p>	603403338238	1	2	159.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736451847839-50126_01_062514_1000x1000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736451847840-50126_01_Front_062514_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736451847840-50126_01_Right_062514_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736452220129-Screenshot2025-01-09at21.50.01.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736452730318-Screenshot2025-01-09at21.56.53.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736452935465-Screenshot2025-01-09at22.01.33.png"	\N	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.521241	2025-05-14 21:46:07.276662
60	50125.01.100-1	NRS Yak Yak - Ratukai Kajakui transportuoti	<h3><strong>NRS Yak Yak &ndash; lengvas ir patvarus kajakų vežimėlis su dydžio pasirinkimu</strong></h3>\n<p>Palengvinkite savo&nbsp;<strong>kajako, baidarės ar irklentės</strong>&nbsp;transportavimą su&nbsp;<strong>NRS Yak Yak</strong>&nbsp;vežimėliu! &Scaron;is itin lengvas ir kompakti&scaron;kas ratukų rinkinys padės be vargo nugabenti jūsų vandens transporto priemonę prie vandens telkinio, net jei kelias driekiasi per&nbsp;<strong>smėlį, žvyrą ar kitus sudėtingus pavir&scaron;ius</strong>.</p>\n<hr />\n<h3><strong>✅ Kodėl verta rinktis NRS Yak Yak?</strong></h3>\n<p>✔&nbsp;<strong>Lengvas ir patvarus</strong>&nbsp;&ndash; anoduoto aliuminio rėmas užtikrina tvirtumą ir ilgaamži&scaron;kumą.<br />✔&nbsp;<strong>Pasirinkite tinkamą dydį</strong>&nbsp;&ndash; galimi&nbsp;<strong>Regular (iki 68 kg)</strong>&nbsp;ir&nbsp;<strong>XL modelis (iki 90 kg)</strong>.<br />✔&nbsp;<strong>Smėlį įveikiančios padangos</strong>&nbsp;&ndash; 8 cm pločio ratlankiai (23 cm skersmens) suteikia puikią atramą mink&scaron;tose dangose.<br />✔&nbsp;<strong>30 % lengvesnis už įprastus kajakų vežimėlius</strong>&nbsp;&ndash; mažiau apkrovos jūsų nugarai!<br />✔&nbsp;<strong>Nuimami ratai be guolių</strong>&nbsp;&ndash; paprasta transportuoti ir sandėliuoti, tinka daugumai kajakų liukų.<br />✔&nbsp;<strong>Atraminis stovas</strong>&nbsp;&ndash; stabilus pakrovimas ir patogus naudojimas.<br />✔&nbsp;<strong>Korozijai atspari konstrukcija</strong>&nbsp;&ndash; užtikrina ilgaamži&scaron;kumą net sūriame vandenyje.<br />✔&nbsp;<strong>Amortizuojančios putplasčio pagalvėlės</strong>&nbsp;&ndash; apsaugo jūsų kajaką nuo pažeidimų.<br />✔&nbsp;<strong>Tvirtinimo diržai komplekte</strong>&nbsp;&ndash; 2 vnt. 1,8 m ilgio NRS kilpiniai diržai su patogiomis sagtimis.</p>\n<p>🎥&nbsp;<strong>Vaizdo įra&scaron;as:</strong>&nbsp;<a href="https://youtu.be/vn7DligxoYQ?si=H_EOmDd_i7jfx0a1" rel="noopener">NRS&nbsp;Yak&nbsp;Yak&nbsp;vežimėlis&nbsp;veiksme</a></p>\n<hr />\n<p>&nbsp;</p>\n<h3><strong>📏 Specifikacija:</strong></h3>\n<table><colgroup><col /><col /><col /></colgroup>\n<tbody>\n<tr>\n<th colspan="1" rowspan="1">\n<p>Parametras</p>\n</th>\n<th colspan="1" rowspan="1">\n<p><strong>Regular versija</strong></p>\n</th>\n<th colspan="1" rowspan="1">\n<p><strong>XL versija</strong></p>\n</th>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Maksimali apkrova</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>68 kg</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>90 kg</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Rėmo medžiaga</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Anoduotas aliuminis</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Anoduotas aliuminis</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Ratų skersmuo</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>23 cm</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>23 cm</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Ratų plotis</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>8 cm</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>8 cm</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Ratai</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Nuimami, be guolių</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Nuimami, be guolių</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Svoris</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Itin lengvas</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Itin lengvas</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Atraminis stovas</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Apsauginės pagalvėlės</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Korozijai atsparūs elementai</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>Taip</p>\n</td>\n</tr>\n<tr>\n<td colspan="1" rowspan="1">\n<p><strong>Tvirtinimo diržai komplekte</strong></p>\n</td>\n<td colspan="1" rowspan="1">\n<p>2 vnt. (1,8 m)</p>\n</td>\n<td colspan="1" rowspan="1">\n<p>2 vnt. (1,8 m)</p>\n</td>\n</tr>\n</tbody>\n</table>\n<p>&nbsp;</p>\n<p>👉&nbsp;<strong>Pasirinkite tinkamą dydį ir užsisakykite dabar!</strong>&nbsp;🚣&zwj;♂️</p>\n<p>&nbsp;</p>	603403338221	1	2	129.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1729105283023-50125_01_Left_Blue_062414_1000x1000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1729105283023-50125_01_Front_Blue_062414_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1729105283024-50125_01_Right_Blue_062414_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736452220129-Screenshot2025-01-09at21.50.01.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736452730318-Screenshot2025-01-09at21.56.53.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1736452935465-Screenshot2025-01-09at22.01.33.png"	\N	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.522602	2025-05-14 21:46:07.279009
61	40139.01.101	NRS Ambient PFD - Universali Gelbėjimosi liemenė M/L	<h2>NRS Ambient PFD - Universali Gelbėjimosi liemenė</h2>\n<p>&nbsp;</p>\n<p>&Scaron;iuolaiki&scaron;kas klasikinio dizaino &bdquo;NRS Ambient PFD&ldquo; suderina paprastumą ir patogumą su saugumu ir apsauga. Patogus priekinis užtrauktukas ir laisvė plaukti ar irkluoti - nerasite patogesnės pramoginės liemenės už &bdquo;Ambient&ldquo;.</p>\n<ul>\n<li>\n<p>Mūsų naujovi&scaron;ka &bdquo;Orbit Fit&ldquo; sistema pagerina bendrą komfortą, padidina judesių amplitudę.</p>\n</li>\n<li>\n<p>Dviejose i&scaron;plečiamose, užtrauktuku užsegamose ki&scaron;enėse telpa būtiniausi daiktai, reikalingi vandenyje.</p>\n</li>\n<li>\n<p>Turi 3M&reg; &scaron;viesą atspindinčius akcentus, petne&scaron;ų laikiklius ir keturis tvirtinimo ta&scaron;kus priekyje ir nugaroje peiliui, žibintams, stroboskopams ir kt.</p>\n</li>\n<li>\n<p>Vienodas flotacijos pasiskirstymas priekyje ir nugaroje sukuria optimalią ploną, vidutinio profilio striukę.</p>\n</li>\n<li>\n<p>YKK&reg; užtrauktukas ir reguliuojamos peties, &scaron;ono ir juosmens dalys užtikrina gelbėjimosi liemenės saugumą ir individualų pritaikymą.</p>\n</li>\n<li>\n<p>Nustatant dydžius atsižvelgiama į tinkamą plūdrumo kiekį, reikalingą atskiriems kūno tipams, todėl gelbėjimosi liemenė geriau priglunda ir yra patogesnė visiems.</p>\n</li>\n<li>\n<p>&bdquo;Orbit Fit&ldquo; sistema yra sudaryta i&scaron; kelių lengvų, pagal tikslias specifikacijas i&scaron;pjautų uždaro tipo putplasčio gabalėlių, kad būtų sukurta unikali, lanksti, i&scaron; anksto i&scaron;lenkta forma, kuri lengvai prisitaiko prie jūsų kūno.</p>\n</li>\n<li>\n<p>Tvarioje konstrukcijoje perdirbto ripstopo nailono apvalkalas derinamas su perdirbto nailono vidumi, kuris apsaugo PVC neturinčias &bdquo;Ethafoam&ldquo; tarpines.</p>\n</li>\n<li>\n<p>4 krypčių elastingas dvigubo mezgimo poliesterio pamu&scaron;alas yra patogus prie odos ir padeda suvaldyti drėgmę.</p>\n</li>\n<li>\n<p>Silikonu dengtas vidinis juosmuo padeda i&scaron;laikyti liemenę vietoje plaukiojant.</p>\n</li>\n<li>\n<p>&Scaron;i liemenė sertifikuotas pagal EN ISO 12402-5 standartą.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><img title="" src="https://cdn.zyrosite.com/cdn-cgi/image/format=auto,fit=crop,q=80,w=600/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730211409097-Screenshot%202024-10-29%20at%2016.16.37.png" alt="" /></p>	603403487548	1	2	99.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730210561620-40117_01_Forest_na_Front_020124_1000x1000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730210561616-40117_01_Forest_na_Back_020124_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730210561620-40117_01_Forest_na_Side_020624_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730211486143-Screenshot2024-10-29at16.17.43.png"	\N	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.523936	2025-05-14 21:46:07.281892
62	40050.04.100	NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė XS/M	<h2>NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė</h2>\n<p>&nbsp;</p>\n<p>Mūsų populiariausios žvejybinės gelbėjimosi liemenės "NRS Chinook Fishing PFD" evoliucija priklauso nuo to, kaip mūsų dizaineriai įsiklauso į žvejų visame pasaulyje atsiliepimus. Ir mes tai darome! Dėl pakeistos ki&scaron;enių konstrukcijos "Chinook" leidžia saugiau ir efektyviau mėgautis nuotykiais vandenyje.</p>\n<p>&nbsp;</p>\n<p><strong>NRS Chinook PFD </strong>yra vidutinio profilio gelbėjimosi liemenė, sertifikuota pagal EN ISO 12402-5 standartą.</p>\n<ul>\n<li>\n<p>Priekyje užtrauktuku užsegamas įėjimas, kad būtų galima greitai užsidėti, ir &scaron;e&scaron;i reguliavimo ta&scaron;kai, kad liemenė būtų pritaikyta individualiai.</p>\n</li>\n<li>\n<p>PlushFit&trade; putplastis ir auk&scaron;tas nugaros atlo&scaron;o dizainas kartu sukuria itin patogią liemenę bet kokio tipo plausto, kajako, valties ar baidarės sėdynei.</p>\n</li>\n<li>\n<p>Tinklelis apatinėje nugaros dalyje užtikrina papildomą ventiliaciją &scaron;iltomis dienomis.</p>\n</li>\n<li>\n<p>Dviejose didelėse "clamshell" ki&scaron;enėse, skirtose žvejybos reikmenų dėžutėms, yra atnaujintas vidinis skyrius, atliepiantis i&scaron;rankausių žvejų poreikius.</p>\n</li>\n<li>\n<p>I&scaron;orinėje ki&scaron;enėje, esančioje de&scaron;inėje me&scaron;keriotojo pusėje, galima lengvai laikyti daiktus.</p>\n</li>\n<li>\n<p>Penktoji, įrankių laikiklio ki&scaron;enė suteikia greitą prieigą prie replių, virvės kirpimo žirklių ar kitų žvejybos įtaisų ir yra tvirtinama kabliuku ir kilpa.</p>\n</li>\n<li>\n<p>Taip pat yra me&scaron;kerės laikiklis, stroboskopo tvirtinimo vieta, &scaron;viesą atspindintys akcentai ir peilio tvirtinimo skirtukas.</p>\n</li>\n</ul>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/k5EBd8ZBevo?si=xNbPo48TvDeyXLYJ" width="640" height="480" data-mce-fragment="1"></iframe></div>\n<p>&nbsp;</p>\n<h3>TINKAMO DYDŽIO GELBĖJIMOSI LIEMENĖ!</h3>\n<p>Labai svarbu, kad gelbėjimosi liemenė jums tiktų! Ji turi tvirtai, bet patogiai gaubti kūną, bet neslysti. Tai i&scaron; tikrųjų yra svarbiau nei etiketėje nurodytas tikslus svoris. Vaikai niekada neturėtų dėvėti gelbėjimosi liemenių, kad į jas &bdquo;įaugtų&ldquo;.</p>\n<p>Matuodamiesi gelbėjimosi liemenę įsitikinkite, kad visi užtrauktukai ir sagtys yra tinkamai užsegti ir sureguliuoti. Įsitikinkite, kad gelbėjimosi liemenė neslysta link smakro, kai rankos i&scaron;keltos į vir&scaron;ų (patikrinkite tai papra&scaron;ydami, kad kas nors padėtų &scaron;velniai pakelti gelbėjimosi liemenės pečius). Gelbėjimosi liemenė turi tvirtai priglusti prie kūno, o tarp gelbėjimosi liemenės ir pečių neturi būti oro tarpo.</p>\n<p>&nbsp;</p>\n<h3>Pasitikrinkite:</h3>\n<p>Tarp gelbėjimosi liemenės ir pečių nėra oro.</p>\n<p>Tvirtai priglunda prie kūno.</p>\n<p>Uždaras užtrauktukas.</p>\n<p>Užsegamos sagtys ir reguliuojami dirželiai užsekti.</p>\n<p>&nbsp;</p>\n<h3>NAUDOJIMOSI INSTRUKCIJA</h3>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<h3>&nbsp;</h3>\n<h3><strong>PRIEŽIŪRA IR LAIKYMAS</strong></h3>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.</p>\n<p>Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.</p>\n<p>Liemenė naudojama -30 +50 C</p>\n<p>Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</p>	603403468288	1	8	129.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146534-40050_04_Bark_na_Front_091123_2000x2000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146528-40050_04_Bark_na_Back_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146535-40050_04_Charcoal_na_Front_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146534-40050_04_Charcoal_na_Back_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717134619-Screenshot%202024-04-21%20at%2019.31.10.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717134619-Screenshot%202024-04-21%20at%2019.31.28.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528742-40050_04_Charcoal_Model_Back_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528742-40050_04_Charcoal_Model_DeckedOut_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_Front_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_OutsidePocket_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_RightPocket_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_Side_041522_1000x1000.jpg"	NRS Chinook Fishing PFD	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.525269	2025-05-14 21:46:07.284084
63	40050.04.101	NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė L/XL	<h2>NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė</h2>\n<p>&nbsp;</p>\n<p>Mūsų populiariausios žvejybinės gelbėjimosi liemenės "NRS Chinook Fishing PFD" evoliucija priklauso nuo to, kaip mūsų dizaineriai įsiklauso į žvejų visame pasaulyje atsiliepimus. Ir mes tai darome! Dėl pakeistos ki&scaron;enių konstrukcijos "Chinook" leidžia saugiau ir efektyviau mėgautis nuotykiais vandenyje.</p>\n<p>&nbsp;</p>\n<p><strong>NRS Chinook PFD </strong>yra vidutinio profilio gelbėjimosi liemenė, sertifikuota pagal EN ISO 12402-5 standartą.</p>\n<ul>\n<li>\n<p>Priekyje užtrauktuku užsegamas įėjimas, kad būtų galima greitai užsidėti, ir &scaron;e&scaron;i reguliavimo ta&scaron;kai, kad liemenė būtų pritaikyta individualiai.</p>\n</li>\n<li>\n<p>PlushFit&trade; putplastis ir auk&scaron;tas nugaros atlo&scaron;o dizainas kartu sukuria itin patogią liemenę bet kokio tipo plausto, kajako, valties ar baidarės sėdynei.</p>\n</li>\n<li>\n<p>Tinklelis apatinėje nugaros dalyje užtikrina papildomą ventiliaciją &scaron;iltomis dienomis.</p>\n</li>\n<li>\n<p>Dviejose didelėse "clamshell" ki&scaron;enėse, skirtose žvejybos reikmenų dėžutėms, yra atnaujintas vidinis skyrius, atliepiantis i&scaron;rankausių žvejų poreikius.</p>\n</li>\n<li>\n<p>I&scaron;orinėje ki&scaron;enėje, esančioje de&scaron;inėje me&scaron;keriotojo pusėje, galima lengvai laikyti daiktus.</p>\n</li>\n<li>\n<p>Penktoji, įrankių laikiklio ki&scaron;enė suteikia greitą prieigą prie replių, virvės kirpimo žirklių ar kitų žvejybos įtaisų ir yra tvirtinama kabliuku ir kilpa.</p>\n</li>\n<li>\n<p>Taip pat yra me&scaron;kerės laikiklis, stroboskopo tvirtinimo vieta, &scaron;viesą atspindintys akcentai ir peilio tvirtinimo skirtukas.</p>\n</li>\n</ul>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/k5EBd8ZBevo?si=xNbPo48TvDeyXLYJ" width="640" height="480" data-mce-fragment="1"></iframe></div>\n<p>&nbsp;</p>\n<h3>TINKAMO DYDŽIO GELBĖJIMOSI LIEMENĖ!</h3>\n<p>Labai svarbu, kad gelbėjimosi liemenė jums tiktų! Ji turi tvirtai, bet patogiai gaubti kūną, bet neslysti. Tai i&scaron; tikrųjų yra svarbiau nei etiketėje nurodytas tikslus svoris. Vaikai niekada neturėtų dėvėti gelbėjimosi liemenių, kad į jas &bdquo;įaugtų&ldquo;.</p>\n<p>Matuodamiesi gelbėjimosi liemenę įsitikinkite, kad visi užtrauktukai ir sagtys yra tinkamai užsegti ir sureguliuoti. Įsitikinkite, kad gelbėjimosi liemenė neslysta link smakro, kai rankos i&scaron;keltos į vir&scaron;ų (patikrinkite tai papra&scaron;ydami, kad kas nors padėtų &scaron;velniai pakelti gelbėjimosi liemenės pečius). Gelbėjimosi liemenė turi tvirtai priglusti prie kūno, o tarp gelbėjimosi liemenės ir pečių neturi būti oro tarpo.</p>\n<p>&nbsp;</p>\n<h3>Pasitikrinkite:</h3>\n<p>Tarp gelbėjimosi liemenės ir pečių nėra oro.</p>\n<p>Tvirtai priglunda prie kūno.</p>\n<p>Uždaras užtrauktukas.</p>\n<p>Užsegamos sagtys ir reguliuojami dirželiai užsekti.</p>\n<p>&nbsp;</p>\n<h3>NAUDOJIMOSI INSTRUKCIJA</h3>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<h3>&nbsp;</h3>\n<h3><strong>PRIEŽIŪRA IR LAIKYMAS</strong></h3>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.</p>\n<p>Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.</p>\n<p>Liemenė naudojama -30 +50 C</p>\n<p>Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</p>	603403468295	1	2	139.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146534-40050_04_Bark_na_Front_091123_2000x2000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146528-40050_04_Bark_na_Back_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146535-40050_04_Charcoal_na_Front_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146534-40050_04_Charcoal_na_Back_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717134619-Screenshot%202024-04-21%20at%2019.31.10.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717134619-Screenshot%202024-04-21%20at%2019.31.28.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528742-40050_04_Charcoal_Model_Back_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528742-40050_04_Charcoal_Model_DeckedOut_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_Front_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_OutsidePocket_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_RightPocket_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_Side_041522_1000x1000.jpg"	NRS Chinook Fishing PFD	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.5266	2025-05-14 21:46:07.286579
64	40050.04.102	NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė XL/XXL	<h2>NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė</h2>\n<p>&nbsp;</p>\n<p>Mūsų populiariausios žvejybinės gelbėjimosi liemenės "NRS Chinook Fishing PFD" evoliucija priklauso nuo to, kaip mūsų dizaineriai įsiklauso į žvejų visame pasaulyje atsiliepimus. Ir mes tai darome! Dėl pakeistos ki&scaron;enių konstrukcijos "Chinook" leidžia saugiau ir efektyviau mėgautis nuotykiais vandenyje.</p>\n<p>&nbsp;</p>\n<p><strong>NRS Chinook PFD </strong>yra vidutinio profilio gelbėjimosi liemenė, sertifikuota pagal EN ISO 12402-5 standartą.</p>\n<ul>\n<li>\n<p>Priekyje užtrauktuku užsegamas įėjimas, kad būtų galima greitai užsidėti, ir &scaron;e&scaron;i reguliavimo ta&scaron;kai, kad liemenė būtų pritaikyta individualiai.</p>\n</li>\n<li>\n<p>PlushFit&trade; putplastis ir auk&scaron;tas nugaros atlo&scaron;o dizainas kartu sukuria itin patogią liemenę bet kokio tipo plausto, kajako, valties ar baidarės sėdynei.</p>\n</li>\n<li>\n<p>Tinklelis apatinėje nugaros dalyje užtikrina papildomą ventiliaciją &scaron;iltomis dienomis.</p>\n</li>\n<li>\n<p>Dviejose didelėse "clamshell" ki&scaron;enėse, skirtose žvejybos reikmenų dėžutėms, yra atnaujintas vidinis skyrius, atliepiantis i&scaron;rankausių žvejų poreikius.</p>\n</li>\n<li>\n<p>I&scaron;orinėje ki&scaron;enėje, esančioje de&scaron;inėje me&scaron;keriotojo pusėje, galima lengvai laikyti daiktus.</p>\n</li>\n<li>\n<p>Penktoji, įrankių laikiklio ki&scaron;enė suteikia greitą prieigą prie replių, virvės kirpimo žirklių ar kitų žvejybos įtaisų ir yra tvirtinama kabliuku ir kilpa.</p>\n</li>\n<li>\n<p>Taip pat yra me&scaron;kerės laikiklis, stroboskopo tvirtinimo vieta, &scaron;viesą atspindintys akcentai ir peilio tvirtinimo skirtukas.</p>\n</li>\n</ul>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/k5EBd8ZBevo?si=xNbPo48TvDeyXLYJ" width="640" height="480" data-mce-fragment="1"></iframe></div>\n<p>&nbsp;</p>\n<h3>TINKAMO DYDŽIO GELBĖJIMOSI LIEMENĖ!</h3>\n<p>Labai svarbu, kad gelbėjimosi liemenė jums tiktų! Ji turi tvirtai, bet patogiai gaubti kūną, bet neslysti. Tai i&scaron; tikrųjų yra svarbiau nei etiketėje nurodytas tikslus svoris. Vaikai niekada neturėtų dėvėti gelbėjimosi liemenių, kad į jas &bdquo;įaugtų&ldquo;.</p>\n<p>Matuodamiesi gelbėjimosi liemenę įsitikinkite, kad visi užtrauktukai ir sagtys yra tinkamai užsegti ir sureguliuoti. Įsitikinkite, kad gelbėjimosi liemenė neslysta link smakro, kai rankos i&scaron;keltos į vir&scaron;ų (patikrinkite tai papra&scaron;ydami, kad kas nors padėtų &scaron;velniai pakelti gelbėjimosi liemenės pečius). Gelbėjimosi liemenė turi tvirtai priglusti prie kūno, o tarp gelbėjimosi liemenės ir pečių neturi būti oro tarpo.</p>\n<p>&nbsp;</p>\n<h3>Pasitikrinkite:</h3>\n<p>Tarp gelbėjimosi liemenės ir pečių nėra oro.</p>\n<p>Tvirtai priglunda prie kūno.</p>\n<p>Uždaras užtrauktukas.</p>\n<p>Užsegamos sagtys ir reguliuojami dirželiai užsekti.</p>\n<p>&nbsp;</p>\n<h3>NAUDOJIMOSI INSTRUKCIJA</h3>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<h3>&nbsp;</h3>\n<h3><strong>PRIEŽIŪRA IR LAIKYMAS</strong></h3>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.</p>\n<p>Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.</p>\n<p>Liemenė naudojama -30 +50 C</p>\n<p>Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</p>	603403468301	1	2	149.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146534-40050_04_Bark_na_Front_091123_2000x2000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146528-40050_04_Bark_na_Back_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146535-40050_04_Charcoal_na_Front_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146534-40050_04_Charcoal_na_Back_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717134619-Screenshot%202024-04-21%20at%2019.31.10.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717134619-Screenshot%202024-04-21%20at%2019.31.28.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528742-40050_04_Charcoal_Model_Back_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528742-40050_04_Charcoal_Model_DeckedOut_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_Front_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_OutsidePocket_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_RightPocket_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_Side_041522_1000x1000.jpg"	NRS Chinook Fishing PFD	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.528795	2025-05-14 21:46:07.28902
65	40050.04.103	NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė XS/M	<h2>NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė</h2>\n<p>&nbsp;</p>\n<p>Mūsų populiariausios žvejybinės gelbėjimosi liemenės "NRS Chinook Fishing PFD" evoliucija priklauso nuo to, kaip mūsų dizaineriai įsiklauso į žvejų visame pasaulyje atsiliepimus. Ir mes tai darome! Dėl pakeistos ki&scaron;enių konstrukcijos "Chinook" leidžia saugiau ir efektyviau mėgautis nuotykiais vandenyje.</p>\n<p>&nbsp;</p>\n<p><strong>NRS Chinook PFD </strong>yra vidutinio profilio gelbėjimosi liemenė, sertifikuota pagal EN ISO 12402-5 standartą.</p>\n<ul>\n<li>\n<p>Priekyje užtrauktuku užsegamas įėjimas, kad būtų galima greitai užsidėti, ir &scaron;e&scaron;i reguliavimo ta&scaron;kai, kad liemenė būtų pritaikyta individualiai.</p>\n</li>\n<li>\n<p>PlushFit&trade; putplastis ir auk&scaron;tas nugaros atlo&scaron;o dizainas kartu sukuria itin patogią liemenę bet kokio tipo plausto, kajako, valties ar baidarės sėdynei.</p>\n</li>\n<li>\n<p>Tinklelis apatinėje nugaros dalyje užtikrina papildomą ventiliaciją &scaron;iltomis dienomis.</p>\n</li>\n<li>\n<p>Dviejose didelėse "clamshell" ki&scaron;enėse, skirtose žvejybos reikmenų dėžutėms, yra atnaujintas vidinis skyrius, atliepiantis i&scaron;rankausių žvejų poreikius.</p>\n</li>\n<li>\n<p>I&scaron;orinėje ki&scaron;enėje, esančioje de&scaron;inėje me&scaron;keriotojo pusėje, galima lengvai laikyti daiktus.</p>\n</li>\n<li>\n<p>Penktoji, įrankių laikiklio ki&scaron;enė suteikia greitą prieigą prie replių, virvės kirpimo žirklių ar kitų žvejybos įtaisų ir yra tvirtinama kabliuku ir kilpa.</p>\n</li>\n<li>\n<p>Taip pat yra me&scaron;kerės laikiklis, stroboskopo tvirtinimo vieta, &scaron;viesą atspindintys akcentai ir peilio tvirtinimo skirtukas.</p>\n</li>\n</ul>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/k5EBd8ZBevo?si=xNbPo48TvDeyXLYJ" width="640" height="480" data-mce-fragment="1"></iframe></div>\n<p>&nbsp;</p>\n<h3>TINKAMO DYDŽIO GELBĖJIMOSI LIEMENĖ!</h3>\n<p>Labai svarbu, kad gelbėjimosi liemenė jums tiktų! Ji turi tvirtai, bet patogiai gaubti kūną, bet neslysti. Tai i&scaron; tikrųjų yra svarbiau nei etiketėje nurodytas tikslus svoris. Vaikai niekada neturėtų dėvėti gelbėjimosi liemenių, kad į jas &bdquo;įaugtų&ldquo;.</p>\n<p>Matuodamiesi gelbėjimosi liemenę įsitikinkite, kad visi užtrauktukai ir sagtys yra tinkamai užsegti ir sureguliuoti. Įsitikinkite, kad gelbėjimosi liemenė neslysta link smakro, kai rankos i&scaron;keltos į vir&scaron;ų (patikrinkite tai papra&scaron;ydami, kad kas nors padėtų &scaron;velniai pakelti gelbėjimosi liemenės pečius). Gelbėjimosi liemenė turi tvirtai priglusti prie kūno, o tarp gelbėjimosi liemenės ir pečių neturi būti oro tarpo.</p>\n<p>&nbsp;</p>\n<h3>Pasitikrinkite:</h3>\n<p>Tarp gelbėjimosi liemenės ir pečių nėra oro.</p>\n<p>Tvirtai priglunda prie kūno.</p>\n<p>Uždaras užtrauktukas.</p>\n<p>Užsegamos sagtys ir reguliuojami dirželiai užsekti.</p>\n<p>&nbsp;</p>\n<h3>NAUDOJIMOSI INSTRUKCIJA</h3>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<h3>&nbsp;</h3>\n<h3><strong>PRIEŽIŪRA IR LAIKYMAS</strong></h3>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.</p>\n<p>Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.</p>\n<p>Liemenė naudojama -30 +50 C</p>\n<p>Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</p>	603403468318	1	2	129.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146534-40050_04_Bark_na_Front_091123_2000x2000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146528-40050_04_Bark_na_Back_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146535-40050_04_Charcoal_na_Front_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146534-40050_04_Charcoal_na_Back_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717134619-Screenshot%202024-04-21%20at%2019.31.10.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717134619-Screenshot%202024-04-21%20at%2019.31.28.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528742-40050_04_Charcoal_Model_Back_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528742-40050_04_Charcoal_Model_DeckedOut_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_Front_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_OutsidePocket_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_RightPocket_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_Side_041522_1000x1000.jpg"	NRS Chinook Fishing PFD	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.531646	2025-05-14 21:46:07.291247
66	40050.04.104	NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė L/XL	<h2>NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė</h2>\n<p>&nbsp;</p>\n<p>Mūsų populiariausios žvejybinės gelbėjimosi liemenės "NRS Chinook Fishing PFD" evoliucija priklauso nuo to, kaip mūsų dizaineriai įsiklauso į žvejų visame pasaulyje atsiliepimus. Ir mes tai darome! Dėl pakeistos ki&scaron;enių konstrukcijos "Chinook" leidžia saugiau ir efektyviau mėgautis nuotykiais vandenyje.</p>\n<p>&nbsp;</p>\n<p><strong>NRS Chinook PFD </strong>yra vidutinio profilio gelbėjimosi liemenė, sertifikuota pagal EN ISO 12402-5 standartą.</p>\n<ul>\n<li>\n<p>Priekyje užtrauktuku užsegamas įėjimas, kad būtų galima greitai užsidėti, ir &scaron;e&scaron;i reguliavimo ta&scaron;kai, kad liemenė būtų pritaikyta individualiai.</p>\n</li>\n<li>\n<p>PlushFit&trade; putplastis ir auk&scaron;tas nugaros atlo&scaron;o dizainas kartu sukuria itin patogią liemenę bet kokio tipo plausto, kajako, valties ar baidarės sėdynei.</p>\n</li>\n<li>\n<p>Tinklelis apatinėje nugaros dalyje užtikrina papildomą ventiliaciją &scaron;iltomis dienomis.</p>\n</li>\n<li>\n<p>Dviejose didelėse "clamshell" ki&scaron;enėse, skirtose žvejybos reikmenų dėžutėms, yra atnaujintas vidinis skyrius, atliepiantis i&scaron;rankausių žvejų poreikius.</p>\n</li>\n<li>\n<p>I&scaron;orinėje ki&scaron;enėje, esančioje de&scaron;inėje me&scaron;keriotojo pusėje, galima lengvai laikyti daiktus.</p>\n</li>\n<li>\n<p>Penktoji, įrankių laikiklio ki&scaron;enė suteikia greitą prieigą prie replių, virvės kirpimo žirklių ar kitų žvejybos įtaisų ir yra tvirtinama kabliuku ir kilpa.</p>\n</li>\n<li>\n<p>Taip pat yra me&scaron;kerės laikiklis, stroboskopo tvirtinimo vieta, &scaron;viesą atspindintys akcentai ir peilio tvirtinimo skirtukas.</p>\n</li>\n</ul>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/k5EBd8ZBevo?si=xNbPo48TvDeyXLYJ" width="640" height="480" data-mce-fragment="1"></iframe></div>\n<p>&nbsp;</p>\n<h3>TINKAMO DYDŽIO GELBĖJIMOSI LIEMENĖ!</h3>\n<p>Labai svarbu, kad gelbėjimosi liemenė jums tiktų! Ji turi tvirtai, bet patogiai gaubti kūną, bet neslysti. Tai i&scaron; tikrųjų yra svarbiau nei etiketėje nurodytas tikslus svoris. Vaikai niekada neturėtų dėvėti gelbėjimosi liemenių, kad į jas &bdquo;įaugtų&ldquo;.</p>\n<p>Matuodamiesi gelbėjimosi liemenę įsitikinkite, kad visi užtrauktukai ir sagtys yra tinkamai užsegti ir sureguliuoti. Įsitikinkite, kad gelbėjimosi liemenė neslysta link smakro, kai rankos i&scaron;keltos į vir&scaron;ų (patikrinkite tai papra&scaron;ydami, kad kas nors padėtų &scaron;velniai pakelti gelbėjimosi liemenės pečius). Gelbėjimosi liemenė turi tvirtai priglusti prie kūno, o tarp gelbėjimosi liemenės ir pečių neturi būti oro tarpo.</p>\n<p>&nbsp;</p>\n<h3>Pasitikrinkite:</h3>\n<p>Tarp gelbėjimosi liemenės ir pečių nėra oro.</p>\n<p>Tvirtai priglunda prie kūno.</p>\n<p>Uždaras užtrauktukas.</p>\n<p>Užsegamos sagtys ir reguliuojami dirželiai užsekti.</p>\n<p>&nbsp;</p>\n<h3>NAUDOJIMOSI INSTRUKCIJA</h3>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<h3>&nbsp;</h3>\n<h3><strong>PRIEŽIŪRA IR LAIKYMAS</strong></h3>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.</p>\n<p>Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.</p>\n<p>Liemenė naudojama -30 +50 C</p>\n<p>Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</p>	603403468325	1	2	139.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146534-40050_04_Bark_na_Front_091123_2000x2000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146528-40050_04_Bark_na_Back_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146535-40050_04_Charcoal_na_Front_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146534-40050_04_Charcoal_na_Back_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717134619-Screenshot%202024-04-21%20at%2019.31.10.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717134619-Screenshot%202024-04-21%20at%2019.31.28.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528742-40050_04_Charcoal_Model_Back_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528742-40050_04_Charcoal_Model_DeckedOut_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_Front_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_OutsidePocket_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_RightPocket_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_Side_041522_1000x1000.jpg"	NRS Chinook Fishing PFD	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.533771	2025-05-14 21:46:07.294789
67	40050.04.105	NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė XL/XXL	<h2>NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė</h2>\n<p>&nbsp;</p>\n<p>Mūsų populiariausios žvejybinės gelbėjimosi liemenės "NRS Chinook Fishing PFD" evoliucija priklauso nuo to, kaip mūsų dizaineriai įsiklauso į žvejų visame pasaulyje atsiliepimus. Ir mes tai darome! Dėl pakeistos ki&scaron;enių konstrukcijos "Chinook" leidžia saugiau ir efektyviau mėgautis nuotykiais vandenyje.</p>\n<p>&nbsp;</p>\n<p><strong>NRS Chinook PFD </strong>yra vidutinio profilio gelbėjimosi liemenė, sertifikuota pagal EN ISO 12402-5 standartą.</p>\n<ul>\n<li>\n<p>Priekyje užtrauktuku užsegamas įėjimas, kad būtų galima greitai užsidėti, ir &scaron;e&scaron;i reguliavimo ta&scaron;kai, kad liemenė būtų pritaikyta individualiai.</p>\n</li>\n<li>\n<p>PlushFit&trade; putplastis ir auk&scaron;tas nugaros atlo&scaron;o dizainas kartu sukuria itin patogią liemenę bet kokio tipo plausto, kajako, valties ar baidarės sėdynei.</p>\n</li>\n<li>\n<p>Tinklelis apatinėje nugaros dalyje užtikrina papildomą ventiliaciją &scaron;iltomis dienomis.</p>\n</li>\n<li>\n<p>Dviejose didelėse "clamshell" ki&scaron;enėse, skirtose žvejybos reikmenų dėžutėms, yra atnaujintas vidinis skyrius, atliepiantis i&scaron;rankausių žvejų poreikius.</p>\n</li>\n<li>\n<p>I&scaron;orinėje ki&scaron;enėje, esančioje de&scaron;inėje me&scaron;keriotojo pusėje, galima lengvai laikyti daiktus.</p>\n</li>\n<li>\n<p>Penktoji, įrankių laikiklio ki&scaron;enė suteikia greitą prieigą prie replių, virvės kirpimo žirklių ar kitų žvejybos įtaisų ir yra tvirtinama kabliuku ir kilpa.</p>\n</li>\n<li>\n<p>Taip pat yra me&scaron;kerės laikiklis, stroboskopo tvirtinimo vieta, &scaron;viesą atspindintys akcentai ir peilio tvirtinimo skirtukas.</p>\n</li>\n</ul>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/k5EBd8ZBevo?si=xNbPo48TvDeyXLYJ" width="640" height="480" data-mce-fragment="1"></iframe></div>\n<p>&nbsp;</p>\n<h3>TINKAMO DYDŽIO GELBĖJIMOSI LIEMENĖ!</h3>\n<p>Labai svarbu, kad gelbėjimosi liemenė jums tiktų! Ji turi tvirtai, bet patogiai gaubti kūną, bet neslysti. Tai i&scaron; tikrųjų yra svarbiau nei etiketėje nurodytas tikslus svoris. Vaikai niekada neturėtų dėvėti gelbėjimosi liemenių, kad į jas &bdquo;įaugtų&ldquo;.</p>\n<p>Matuodamiesi gelbėjimosi liemenę įsitikinkite, kad visi užtrauktukai ir sagtys yra tinkamai užsegti ir sureguliuoti. Įsitikinkite, kad gelbėjimosi liemenė neslysta link smakro, kai rankos i&scaron;keltos į vir&scaron;ų (patikrinkite tai papra&scaron;ydami, kad kas nors padėtų &scaron;velniai pakelti gelbėjimosi liemenės pečius). Gelbėjimosi liemenė turi tvirtai priglusti prie kūno, o tarp gelbėjimosi liemenės ir pečių neturi būti oro tarpo.</p>\n<p>&nbsp;</p>\n<h3>Pasitikrinkite:</h3>\n<p>Tarp gelbėjimosi liemenės ir pečių nėra oro.</p>\n<p>Tvirtai priglunda prie kūno.</p>\n<p>Uždaras užtrauktukas.</p>\n<p>Užsegamos sagtys ir reguliuojami dirželiai užsekti.</p>\n<p>&nbsp;</p>\n<h3>NAUDOJIMOSI INSTRUKCIJA</h3>\n<p>Liemenė turi būti pasirenkama pagal žmogaus svorį. Užsidėjus liemenę, užsegamas užtrauktukas (jeigu toksi yra), susegami visi diržai. Diržų apimtis reguliuojama sagčių pagalba. Diržai privalo būti įtempti, kad liemenė priglustų tvirtai prie kūno.</p>\n<h3>&nbsp;</h3>\n<h3><strong>PRIEŽIŪRA IR LAIKYMAS</strong></h3>\n<p>Panaudojus liemenę ją i&scaron;skalauti ir džiovinti gerai vėdinamoje patalpoje tačiau ne prie atviros liepsnos at kar&scaron;tų įtaisų.</p>\n<p>Kasmet patikrinti ar liemenė atitinka plūdrumo savybes.</p>\n<p>Liemenė naudojama -30 +50 C</p>\n<p>Laikantis priežiūros taisyklių, liemenė gali būti eksploatuojama 5 metus. Plūdrumo liemenė tinkama dėvėti vidaus pakrančių vandenyse, naudoti valtyse, kanojose, baidarėse ir kitose vandens transporto priemonėse, esant netoli būtinai pagalbai.</p>\n<p>Plūdrumo liemenė negali būti naudojama su laive esančiais saugos diržais. Prie&scaron; naudojimą pasitreniruokite. I&scaron;mokykite vaiką plūduriuoti naudojant &scaron;ią priemonę. Plūdrumo liemenė gali pilnai neatlikti savo funkcijų dėvint ją su neper&scaron;lampamais drabužiais. Nenaudokite kaip pagalvės, nesėdėkite ant liemenės. Tiems, kurie gali plaukti ir pagalba arti. Liemenė tik sumažina skendimo riziką.</p>\n<p>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</p>	603403468332	1	2	149.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146534-40050_04_Bark_na_Front_091123_2000x2000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146528-40050_04_Bark_na_Back_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146535-40050_04_Charcoal_na_Front_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717146534-40050_04_Charcoal_na_Back_122222_2000x2000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717134619-Screenshot%202024-04-21%20at%2019.31.10.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1713717134619-Screenshot%202024-04-21%20at%2019.31.28.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528742-40050_04_Charcoal_Model_Back_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528742-40050_04_Charcoal_Model_DeckedOut_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_Front_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_OutsidePocket_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_RightPocket_041522_1000x1000.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737984528743-40050_04_Charcoal_Model_Side_041522_1000x1000.jpg"	NRS Chinook Fishing PFD	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.535776	2025-05-14 21:46:07.297406
68	KR-HKT	Universalūs ratukai Kajakui ar baidarei gabenti	<h3>Universalūs ratukai Kajakui tempti</h3>\n<p>&nbsp;</p>\n<p>Tinka visiems Kajakų modeliams, bet rekomenduojama lengvesniems vienviečiams kajakams<strong> iki 40 kg.</strong></p>\n<p>Kajakų vežimėlis/ratukai leidžia labai lengvai keliauti nuo automobilio iki vandens. Ir nesvarbu kokia kelio danga!</p>\n<p>&nbsp;</p>\n<p>Su "H" baidarių/kajakų vežimėliu kelionė nuo automobilio iki vandens bus itin paprasta. Tai ekonomi&scaron;kiausias mūsų kajakų vežimėlis, skirtas naudoti per lengvesnių kajakų dugno skyles.</p>\n<p>&Scaron;io vežimėlio rėmas pagamintas i&scaron; aliuminio ir gali i&scaron;laikyti <strong>40 kg svorį</strong>. H vežimėlis yra nuimamas ir turi reguliuojamą sraigtinį tvirtinimą, kuris leidžia vežimėlio rėmą pritaikyti prie daugumos kajakų dugno skylių.</p>\n<p>&Scaron;is vežimėlis turi 26 cm pneumatinius ratus, kuriuose naudojama "Tuff-Tire" technologija, t. y. jie suprojektuoti taip, kad niekada nesubliūk&scaron;ta.</p>\n<p>Vežimėlyje yra dvi apsauginės putplasčio pagalvėlės, skirtos kajako korpusui apsaugoti. Skirtingai nei baidarių vežimėlis su diržais, &scaron;iame vežimėlyje yra atraminė &scaron;liuzo kam&scaron;čio sistema.</p>\n<p>&Scaron;is vežimėlis yra lengvas ir gali lengvai įveikti lygias vietoves.</p>\n<p>&nbsp;</p>\n<h2>Specifikacijos</h2>\n<ul>\n<li>\n<p>Medžiaga: aliuminis, putplastis ir tvirtų padangų ratai</p>\n</li>\n<li>\n<p>Reguliuojasi pagal dugno kam&scaron;čio skyles nuo 24,8 cm iki 43,7 cm.</p>\n</li>\n<li>\n<p>I&scaron;matavimai: vamzdžio skersmuo 2,5 cm x 2,3 cm</p>\n<p>&nbsp;</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>Savybės:&nbsp;</p>\n<p>&nbsp;</p>\n<ul>\n<li>\n<p>2 Tuff-Tire ratai</p>\n</li>\n<li>\n<p>Dugno kam&scaron;čio atramos sistema</p>\n</li>\n<li>\n<p>Lengvas aliuminis</p>\n</li>\n<li>\n<p>Didžiausia apkrova 40 kg</p>\n</li>\n<li>\n<p>1 pločio reguliatorius</p>\n</li>\n<li>\n<p>2 putplasčio apsauginės pagalvėlės</p>\n</li>\n</ul>	8436618811653	5	2	60.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fimages%2F170305923162022-3114795827.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703319679598-Copia%20de%20Galaxy-H-Trolley-4.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703319679598-Copia%20de%20Galaxy-H-Trolley-3.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703319679597-Copia%20de%20Galaxy-H-Trolley-2.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fimages%2F170305923162022-3114795827.jpg"	\N	\N	\N	4.000	\N	\N	\N	2025-05-14 18:59:18.537602	2025-05-14 21:46:07.300062
69	KR-HKT1	Universalūs ratukai Kajakui ar baidarei transportuoti	<h3>Universalūs ratukai Kajakui tempti</h3>\n<p>&nbsp;</p>\n<p>Tinka visiems Kajakų modeliams, bet rekomenduojama lengvesniems vienviečiams kajakams<strong> iki 40 kg.</strong></p>\n<p>Kajakų vežimėlis/ratukai leidžia labai lengvai keliauti nuo automobilio iki vandens. Ir nesvarbu kokia kelio danga!</p>\n<p>&nbsp;</p>\n<p>Su "H" baidarių/kajakų vežimėliu kelionė nuo automobilio iki vandens bus itin paprasta. Tai ekonomi&scaron;kiausias mūsų kajakų vežimėlis, skirtas naudoti per lengvesnių kajakų dugno skyles.</p>\n<p>&Scaron;io vežimėlio rėmas pagamintas i&scaron; aliuminio ir gali i&scaron;laikyti <strong>40 kg svorį</strong>. H vežimėlis yra nuimamas ir turi reguliuojamą sraigtinį tvirtinimą, kuris leidžia vežimėlio rėmą pritaikyti prie daugumos kajakų dugno skylių.</p>\n<p>&Scaron;is vežimėlis turi 26 cm pneumatinius ratus, kuriuose naudojama "Tuff-Tire" technologija, t. y. jie suprojektuoti taip, kad niekada nesubliūk&scaron;ta.</p>\n<p>Vežimėlyje yra dvi apsauginės putplasčio pagalvėlės, skirtos kajako korpusui apsaugoti. Skirtingai nei baidarių vežimėlis su diržais, &scaron;iame vežimėlyje yra atraminė &scaron;liuzo kam&scaron;čio sistema.</p>\n<p>&Scaron;is vežimėlis yra lengvas ir gali lengvai įveikti lygias vietoves.</p>\n<p>&nbsp;</p>\n<h2>Specifikacijos</h2>\n<ul>\n<li>\n<p>Medžiaga: aliuminis, putplastis ir tvirtų padangų ratai</p>\n</li>\n<li>\n<p>Reguliuojasi pagal dugno kam&scaron;čio skyles nuo 24,8 cm iki 43,7 cm.</p>\n</li>\n<li>\n<p>I&scaron;matavimai: vamzdžio skersmuo 2,5 cm x 2,3 cm</p>\n<p>&nbsp;</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>Savybės:&nbsp;</p>\n<p>&nbsp;</p>\n<ul>\n<li>\n<p>2 Tuff-Tire ratai</p>\n</li>\n<li>\n<p>Dugno kam&scaron;čio atramos sistema</p>\n</li>\n<li>\n<p>Lengvas aliuminis</p>\n</li>\n<li>\n<p>Didžiausia apkrova 40 kg</p>\n</li>\n<li>\n<p>1 pločio reguliatorius</p>\n</li>\n<li>\n<p>2 putplasčio apsauginės pagalvėlės</p>\n</li>\n</ul>	8436618811652	5	2	60.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fimages%2F170305923162022-3114795827.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703319679598-Copia%20de%20Galaxy-H-Trolley-4.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703319679598-Copia%20de%20Galaxy-H-Trolley-3.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703319679597-Copia%20de%20Galaxy-H-Trolley-2.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fimages%2F170305923162022-3114795827.jpg"	\N	\N	\N	4.000	\N	\N	\N	2025-05-14 18:59:18.539421	2025-05-14 21:46:07.302722
70	GKA-202-80799-0015	Transportavimo diržai Galaxy Kayaks (3,5m)	<p>Galaxt Kayaks Diržai skirti tvirtinti įrangai prie stogo bagažinės skersinių kelionių metu. Parduodama poromis.<br /><br />Naudojant &scaron;iuos transportavimo diržus lengva gabenti irklentes, kajakus ar baidares. Apsaugota sagtis saugo jūsų automobilio dažus ir stiklus nuo pažeidimu.</p>\n<p>&nbsp;</p>\n<p>Vienpusės sagtys priveržimui. Du 25 mm pločio ir 350 cm ilgio diržai.<br /><br />Austinio diržo sudėtis: 100.0% Polipropenas (PP); Struktūra: 50.0% Cinkas, 50.0% Aliuminis; Porolonas: 100.0% Etilenvinilacetatas (EVA)</p>\n<p>&nbsp;</p>\n<p>VIDEO:</p>\n<p>https://www.youtube.com/watch?list=TLGGZ_ZXEZalQGkyMDAxMjAyNQ&amp;v=nqy6h_Es7pc&amp;embeds_referring_euri=https%3A%2F%2Fvakasport.lt%2F&amp;source_ve_path=Mjg2NjY</p>	8436618813107	10	2	30.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1724153451337-new-galaxy-straps.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1724153451337-new-galaxy-straps1.jpeg"	\N	\N	\N	1.000	\N	\N	\N	2025-05-14 18:59:18.54094	2025-05-14 21:46:07.304846
71	GKA-202-80799-0015-1	Transportavimo diržai (3,5m)	<p>Galaxt Kayaks Diržai skirti tvirtinti įrangai prie stogo bagažinės skersinių kelionių metu. Parduodama poromis.<br /><br />Naudojant &scaron;iuos transportavimo diržus lengva gabenti irklentes, kajakus ar baidares. Apsaugota sagtis saugo jūsų automobilio dažus ir stiklus nuo pažeidimu.</p>\n<p>&nbsp;</p>\n<p>Vienpusės sagtys priveržimui. Du 25 mm pločio ir 350 cm ilgio diržai.<br /><br />Austinio diržo sudėtis: 100.0% Polipropenas (PP); Struktūra: 50.0% Cinkas, 50.0% Aliuminis; Porolonas: 100.0% Etilenvinilacetatas (EVA)</p>\n<p>&nbsp;</p>\n<p>VIDEO:</p>\n<p>https://www.youtube.com/watch?list=TLGGZ_ZXEZalQGkyMDAxMjAyNQ&amp;v=nqy6h_Es7pc&amp;embeds_referring_euri=https%3A%2F%2Fvakasport.lt%2F&amp;source_ve_path=Mjg2NjY</p>	8436618813106	10	2	30.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1724153451337-new-galaxy-straps.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1724153451337-new-galaxy-straps1.jpeg"	\N	\N	\N	1.000	\N	\N	\N	2025-05-14 18:59:18.542266	2025-05-14 21:46:07.30722
73	KP-KR34-SC	Motorinis Kajakas - Galaxy Kayaks, Strike	<p>Galaxy Strike &ndash; kompakti&scaron;kas motorinis kajakas dideliems nuotykiams!</p>\n<p>Pristatome <strong>Galaxy Strike</strong> &ndash; stabilų, lengvai transportuojamą ir universalų motorinį kajaką, sukurtą tikriems nuotykių ie&scaron;kotojams. Su <strong>200 cm ilgio</strong> ir <strong>100 cm pločio</strong> korpusu Strike siūlo puikų manevringumo ir stabilumo balansą tiek ramiuose, tiek sudėtinguose vandenyse.</p>\n<p><strong>Pagrindiniai privalumai</strong></p>\n<ul>\n<li>\n<p><strong>Kompakti&scaron;kas ir platus korpusas</strong> &ndash; užtikrina i&scaron;skirtinį stabilumą net ir audringomis sąlygomis.</p>\n</li>\n<li>\n<p><strong>Integruota 360&ordm; pasisukanti sėdynė</strong> &ndash; <a href="https://vakasport.lt/pasukama-auksta-kede-su-360o-sukimosi-funkcija" rel="noopener noreferrer nofollow">(pasirinktinai)</a> užtikrina komfortą ir puikų matomumą žvejybos ar poilsio metu.</p>\n</li>\n<li>\n<p><strong>Suderinamas su priekiniais ir galiniais varikliais</strong> &ndash; užtikrina lankstumą ir lengvą valdymą (variklis parduodamas atskirai).</p>\n</li>\n<li>\n<p><strong>Prie korpuso pritvirtinti ratukai</strong> &ndash; palengvina transportavimą iki vandens telkinio.</p>\n</li>\n<li>\n<p><strong>Papildomos funkcijos</strong> &ndash; galinis daiktadėžės skyrius akumuliatoriui, lengvai užsegami dirželiai, itin ilgas irklas, priekinis laikymo liukas.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>Techninės specifikacijos</strong></p>\n<ul>\n<li>\n<p><strong>Ilgis:</strong> 200 cm</p>\n</li>\n<li>\n<p><strong>Plotis:</strong> 100 cm</p>\n</li>\n<li>\n<p><strong>Auk&scaron;tis:</strong> 45 cm</p>\n</li>\n<li>\n<p><strong>Svoris:</strong> 29 kg</p>\n</li>\n<li>\n<p><strong>Keliamoji galia:</strong> 250 kg</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p>🎣 <strong>Kam skirtas Galaxy Strike?</strong></p>\n<p>✔ Žvejams, ie&scaron;kantiems stabilios ir tvirtos platformos.<br />✔ Keliautojams, vertinantiems kompakti&scaron;kumą ir paprastą transportavimą.<br />✔ Tiems, kurie nori naudoti elektrinį ar pakabinamąjį variklį.<br />✔ Nuotykių mėgėjams, siekiantiems komforto ir valdymo laisvės.</p>\n<p>&nbsp;</p>\n<p><strong>Kas įtraukta į kainą?</strong></p>\n<p>✔️ Itin ilgas irklas<br />✔️ Prie korpuso pritvirtinti transportavimo ratukai<br />✔️ Galinis laikymo skyrius su dirželiais akumuliatoriui arba įrangai<br />✔️ Priekinis laikymo liukas</p>\n<p>&nbsp;</p>\n<p><strong>Papildomai rekomenduojama:</strong></p>\n<ul>\n<li>\n<p>360&ordm; kampu besisukanti auk&scaron;ta sėdynė (<a href="https://vakasport.lt/pasukama-auksta-kede-su-360o-sukimosi-funkcija" rel="noopener noreferrer nofollow">pasirinktinai</a>)</p>\n</li>\n<li>\n<p>12V elektrinis variklis</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>Pasiruo&scaron;ę nuotykiams? Užsisakykite Galaxy Strike jau &scaron;iandien ir leiskitės į naujas vandens ekspedicijas!</strong></p>\n<p>&nbsp;</p>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/pcYu0F03uqQ?si=kKeVbQt9d1_R8qMR" width="640" height="480" data-mce-fragment="1"></iframe></div>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>\n<p>&nbsp;</p>\n<p>Rekomenduojama gelbėjimosi liemenė (spausti ant teksto):&nbsp;<a href="https://vakasport.lt/nrs-chinook-fishing-pfd-zvejybine-gelbejimosi-liemene" rel="noopener noreferrer nofollow"><strong>NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė</strong></a></p>	8436618814708	2	3	849.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737140343684-DSC05850.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737140343684-DSC05849.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1737140343683-DSC05848.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727287237393-DSC05785.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727287237393-DSC05786.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727287271121-DSC05867.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727287271123-DSC05868.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727287271124-DSC05869.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727287271125-DSC05870.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727287271125-DSC05871.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727287271126-DSC05872.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727287271126-DSC05873.jpg"	Stike	\N	\N	29.000	\N	\N	\N	2025-05-14 18:59:18.545278	2025-05-14 21:46:07.312049
74	KP-KR24-SG	Kajakas 2+1 - Galaxy Kayaks, Blaze XL	<h2>🚣&zwj;♂️ Patirkite nuotykius su Galaxy Blaze XL Sit-on-Top Kajaku! 🌊🛶</h2>\n<p>&nbsp;</p>\n<p>Galaxy Blaze XL" laisvalaikio kajakas vienam ar dviem žmonėms. Jis yra ilgesnių matmenų, todėl sklandžiai slysta vandeniu, o mėgstantiems žvejoti joje įrengti du nedideli fiksuoti me&scaron;kerių laikikliai. Kajake yra įmontuoti variniai įdėklai, kad būtų galima lengvai ir be grąžtų sumontuoti populiarius priedus, be to, kajakas turi i&scaron;lietas priekines ir galines rankenas, kad ją būtų lengva ne&scaron;ti ir transportuoti.</p>\n<p>&nbsp;</p>\n<h3>Pagrindinės savybės:</h3>\n<ul>\n<li>\n<p>Kajako viduryje i&scaron;lieta sėdynė - galite pasiimti su savimi ir vaikus</p>\n</li>\n<li>\n<p>Du įmontuoti me&scaron;kerių laikikliai žvejybai</p>\n</li>\n<li>\n<p>Specialios vietos leis lengvai ir be gręžimo pritvirtinti įvairius priedus</p>\n</li>\n<li>\n<p>Profiliuotos priekinės ir galinės rankenomis, kad būtų lengva transportuoti</p>\n</li>\n<li>\n<p>Trys oranžinės, baltos ir juodos spalvų tamprios virvės kajako gale, kad lengvai pritvirtintumėte bet kokį krovinį</p>\n</li>\n<li>\n<p>Gelbėjimo virvės kajako &scaron;onuose, užtikrinančios didesnį matomumą ir saugumą ant vandens</p>\n</li>\n<li>\n<p>Kajakas yra visi&scaron;kai sukomplektuotas su sėdyne ir irklu, o norint leistis į kitą nuotykį tereikia gelbėjimosi liemenės.</p>\n<p>&nbsp;</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<h3>Specifikacijos:</h3>\n<ul>\n<li>\n<p>Ilgis: 305 cm, plotis: 80 cm, auk&scaron;tis: 40 cm.</p>\n</li>\n<li>\n<p>Svoris: 23 kg</p>\n</li>\n<li>\n<p>Didžiausias vežimo svoris: 150 kg</p>\n</li>\n<li>\n<p>Rekomenduojama žmonėms iki maks: 110 kg</p>\n</li>\n</ul>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/sNEF-bNF0E8?si=eUdJ1buLcamu6DnY" width="640" height="480" data-mce-fragment="1"></iframe></div>\n<p>Rinkitės "Blaze XL", jei norite patirti geriausią plaukimo baidarėmis patirtį!</p>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>\n<p>&nbsp;</p>\n<p><strong>SVARBU:</strong></p>\n<p>Niekada nei&scaron;plaukite be gelbėjimosi liemenės ir tinkamos saugos įrangos. Pirkdami &bdquo;Galaxy Kayaks &amp; VAKA Sport&ldquo; gaminį sutinkate, kad plaukimas baidarėmis, kajakaisar valtimis yra susijęs su tam tikra rizika, įskaitant, bet neapsiribojant, sunkių sužalojimų ar mirties rizika. Jūs parei&scaron;kiate, kad supratote ir prisiimate visą atsakomybę už susijusią riziką.</p>\n<p>&nbsp;</p>\n<p>Rekomenduojama gelbėjimosi liemenė (spausti ant teksto):&nbsp;<a href="https://vakasport.lt/nrs-chinook-fishing-pfd-zvejybine-gelbejimosi-liemene" rel="noopener noreferrer nofollow"><strong>NRS Chinook Fishing PFD - Žvejybinė Gelbėjimosi liemenė</strong></a></p>	8436618810847	2	3	569.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1738667952945-A7M09232.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1738667952943-A7M09230.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1738667952944-A7M09231.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703240148232-A7M09185.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703240148233-A7M09186.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703240148233-A7M09187.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703240148234-A7M09188.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703240148234-A7M09189.jpg"	Blaze XL	\N	\N	23.000	\N	\N	\N	2025-05-14 18:59:18.546609	2025-05-14 21:46:07.314305
75	50-0001-71	Kajako, Baidarės transportavimo ratukai C-TUG Railblaza	<h3><strong>C-TUG Kajako Vežimėlis | C-TUG Kayak Cart</strong></h3>\n<h4>&nbsp;</h4>\n<p><strong>Lengvai transportuokite savo kajaką su C-TUG vežimėliu!</strong><br />Pamir&scaron;kite varginantį kajako tempimą &ndash; <strong>C-TUG Kajako vežimėlis</strong>sukurtas tam, kad jūsų nuotykiai būtų dar patogesni. &Scaron;is tvirtas vežimėlis pagamintas i&scaron; nerūdijančių inžinerinių polimerų, todėl tarnaus ilgai net ir intensyviai naudojant.</p>\n<p>&nbsp;</p>\n<p><strong>Pagrindinės savybės:</strong></p>\n<ul>\n<li>\n<p><strong>Jokio tempimo vargo:</strong> Lengvai nugabenkite savo kajaką iki vandens ir atgal.</p>\n</li>\n<li>\n<p><strong>Greitas surinkimas:</strong> Jokių įrankių &ndash; vežimėlis surenkamas ir i&scaron;ardomas vos per kelias sekundes.</p>\n</li>\n<li>\n<p><strong>Nepraduriami ratai:</strong> Auk&scaron;tos sukibimo gumos danga užtikrina stabilų transportavimą bet kokiu reljefu.</p>\n</li>\n<li>\n<p><strong>Mink&scaron;tos pagalvėlės:</strong> Gumuotos korpuso pagalvėlės apsaugo kajaką nuo pažeidimų.</p>\n</li>\n<li>\n<p><strong>Lengvas, bet patvarus:</strong> Sveria vos 5,5 kg, bet gali gabenti iki 120 kg svorį.</p>\n</li>\n<li>\n<p><strong>Tvirta konstrukcija:</strong> Nerūdijančio plieno a&scaron;ys ir sustiprintos kompozitinės medžiagos užtikrina ilgaamži&scaron;kumą.</p>\n</li>\n<li>\n<p><strong>Reguliuojama atraminė kojelė:</strong> Paprastesniam pakrovimui ir i&scaron;krovimui.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>Techninės specifikacijos:</strong></p>\n<ul>\n<li>\n<p><strong>Matmenys:</strong> Ilgis 63 cm x plotis 32 cm x auk&scaron;tis 18 cm</p>\n</li>\n<li>\n<p><strong>Svoris:</strong> 5,5 kg&nbsp;</p>\n</li>\n<li>\n<p><strong>Ratų tipas:</strong> Nepraduriami ratai su auk&scaron;tos sukibimo gumos danga</p>\n</li>\n<li>\n<p><strong>Keliamoji galia:</strong> Iki 120 kg</p>\n</li>\n<li>\n<p><strong>Medžiagos:</strong> UV stabilizuoti ABS, acetalinis ir nailono plastikas, Santopreno elastomeras</p>\n</li>\n<li>\n<p><strong>Komplektacija:</strong></p>\n<ul>\n<li>\n<p>2 x Nepraduriami ratai</p>\n</li>\n<li>\n<p>2 x Termi&scaron;kai sujungtos korpuso pagalvėlės</p>\n</li>\n<li>\n<p>2 x Nerūdijančio plieno a&scaron;ys</p>\n</li>\n<li>\n<p>1 x Diržas su tvirta sagtimi (2,7 m)</p>\n</li>\n<li>\n<p>1 x Reguliuojama atraminė kojelė</p>\n</li>\n</ul>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>Privalumai:</strong></p>\n<ul>\n<li>\n<p>Tinka visų tipų kajakams ir vandens transporto priemonėms.</p>\n</li>\n<li>\n<p>Surenkamas ir i&scaron;ardomas per kelias sekundes be jokių įrankių.</p>\n</li>\n<li>\n<p>Kompakti&scaron;kas &ndash; lengvai telpa į kajako liuką.</p>\n</li>\n<li>\n<p>Nepraduriami ratai užtikrina patikimą transportavimą bet kokiu pavir&scaron;iumi.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>Pasiruo&scaron;kite nuotykiams be rūpesčių &ndash; su C-TUG Kajako Vežimėliu jūsų transportavimas taps lengvas ir patogus!</strong></p>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/THMoLRyXjSo?si=3hVPOzrfjDKpKWWB" width="640" height="480" data-mce-fragment="1"></iframe></div>	9421026831927	5	2	159.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fimages%2F170305923162023-3484816155.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739997523398-50-0001-71-C-TugCanoeKayakCart-NB.png | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703318720483-CTUG5_Full.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739997342194-HobieOutback2019-1.JPG | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703318720482-50-0001-71_C-Tug_Lifestlye_Beach.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739997342194-NorthStarCanoes-1.JPG"	C-TUG	\N	\N	6.000	\N	\N	\N	2025-05-14 18:59:18.547852	2025-05-14 21:46:07.31683
76	50-0010-71	Kajako, Baidarės transportavimo ratukai Railblaza C-TUG R su Kiwi ratais	<h3><strong>Transportavimo ratukai Railblaza C-TUG R su Kiwi ratais</strong></h3>\n<h4>&nbsp;</h4>\n<p><strong>Lengvesnis kajako transportavimas su C-TUG R vežimėliu!</strong><br />Patirkite naują transportavimo lygį su <strong>C-TUG R vežimėliu</strong> &ndash; patobulinta populiaraus C-Tug modelio versija, skirta dar platesniam kajakų korpusų asortimentui. Dėl reguliuojamų korpuso bėgelių ir nepraduriamų <strong>Kiwi ratų</strong>, &scaron;is vežimėlis užtikrina maksimalų patogumą transportuojant kajaką įvairiomis sąlygomis.</p>\n<p><strong>✅ Pagrindinės savybės:</strong></p>\n<ul>\n<li>\n<p><strong>Reguliuojami korpuso bėgeliai:</strong> Prisitaiko prie įvairių kajako formų ir sumažina traukimo apkrovą.</p>\n</li>\n<li>\n<p><strong>Nepraduriami Kiwi ratai:</strong> Auk&scaron;tos sukibimo gumos danga užtikrina stabilumą ant visų pavir&scaron;ių.</p>\n</li>\n<li>\n<p><strong>Lengvas surinkimas:</strong> Nereikia jokių įrankių &ndash; vežimėlis surenkamas ir i&scaron;ardomas vos per kelias sekundes.</p>\n</li>\n<li>\n<p><strong>Kompakti&scaron;kas dizainas:</strong> Lengvai telpa į daugumos kajakų liukus, todėl jį patogu transportuoti kartu.</p>\n</li>\n<li>\n<p><strong>Tvirta konstrukcija:</strong> Pagamintas i&scaron; UV stabilizuotų inžinerinių polimerų ir nerūdijančio plieno a&scaron;ių.</p>\n</li>\n<li>\n<p><strong>Atraminė kojelė:</strong> Užtikrina stabilumą kraunant kajaką ant vežimėlio.</p>\n</li>\n<li>\n<p><strong>Didelė keliamoji galia:</strong> Iki 100 kg statinio svorio.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>📏 Techninės specifikacijos:</strong></p>\n<ul>\n<li>\n<p><strong>Matmenys:</strong> Ilgis 60 cm x plotis 32 cm x auk&scaron;tis 30 cm</p>\n</li>\n<li>\n<p><strong>Svoris:</strong> 4 kg (8,8 lbs)</p>\n</li>\n<li>\n<p><strong>Ratų tipas:</strong> Nepraduriami Kiwi ratai su auk&scaron;tos sukibimo gumos danga</p>\n</li>\n<li>\n<p><strong>Medžiagos:</strong> UV stabilizuoti ABS, Acetal ir nailono plastikai, Santopreno elastomeras</p>\n</li>\n<li>\n<p><strong>Keliamoji galia:</strong> Iki 100 kg statinio apkrovos</p>\n</li>\n<li>\n<p><strong>Komplektacija:</strong></p>\n<ul>\n<li>\n<p>2 x korpuso bėgeliai (C-TUG Rails)</p>\n</li>\n<li>\n<p>2 x vežimėlio pagrindo sijų komplektai (C-TUG Rail Bases)</p>\n</li>\n<li>\n<p>2 x Kiwi ratai</p>\n</li>\n<li>\n<p>1 x atraminė kojelė</p>\n</li>\n<li>\n<p>1 x 1,2 m diržas su tvirta sagtimi</p>\n</li>\n<li>\n<p>Nerūdijančio plieno tvirtinimo detalės</p>\n</li>\n</ul>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>🟢 Naudojimo privalumai:</strong></p>\n<ul>\n<li>\n<p>Tinka daugumai kajakų ir kitų vandens transporto priemonių.</p>\n</li>\n<li>\n<p>Dėl reguliuojamų bėgelių transportavimas tampa lengvesnis, nes sumažinama traukimo apkrova.</p>\n</li>\n<li>\n<p>Kompakti&scaron;kas dizainas leidžia vežimėlį patogiai laikyti kajako liuke.</p>\n</li>\n<li>\n<p>Atraminė kojelė palengvina kajako pakrovimą ir i&scaron;krovimą be papildomos pagalbos.</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/THMoLRyXjSo?si=3hVPOzrfjDKpKWWB" width="640" height="480" data-mce-fragment="1"></iframe></div>	9421026835246	5	2	159.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739997986132-50-0010-71-C-TUGRkiwiwheels-NB.png	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739997986129-50-0010-71_C-TUG-R_HobiePA_Lanch_1x1.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739997986130-50-0010-71_C-TUG-R_HobiePA_Loading_1x1.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739997986131-50-0010-71_C-TUG-R_HobiePA_stowed_1x1.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739997986131-50-0010-71_C-TUG-R_Hobie-Outback_Ready-For-Launch-1x1.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739997986131-50-0010-71_C-TUG-R_Hobie-Pro-Angler_close_1x1.jpg"	C-TUG	\N	\N	5.000	\N	\N	\N	2025-05-14 18:59:18.549136	2025-05-14 21:46:07.318844
77	LAZY-04-10205-0267	Lazy H - Vežimėlis Kajakui transportuoti	<h3><strong>Lazy H Kajako Vežimėlis &ndash; Patogus ir Universalus Sprendimas</strong></h3>\n<p>&nbsp;</p>\n<p><strong>Lazy H Kajako Vežimėlis</strong>&nbsp;&ndash; tai naujausias&nbsp;<strong>Lazy-Boys</strong>&nbsp;kajakų transportavimo vežimėlis, skirtas&nbsp;<strong>sit-on-top</strong>&nbsp;tipo kajakams. &Scaron;is vežimėlis įsistato tiesiai į&nbsp;<strong>kajako drenažo angas (scupper plugs)</strong>, užtikrindamas stabilų ir patikimą transportavimą.</p>\n<p>Kaip ir garsusis&nbsp;<strong>Lazy-Boys Kayak Cart</strong>,&nbsp;<strong>Lazy H</strong>&nbsp;naudoja&nbsp;<strong>pripučiamus visų tipų pavir&scaron;iams pritaikytus ratus</strong>, kurie&nbsp;<strong>nesminga į smėlį</strong>&nbsp;net transportuojant sunkų kajaką paplūdimyje.</p>\n<p>&nbsp;</p>\n<h3><strong>Lengvas, Kompakti&scaron;kas ir Patogus</strong></h3>\n<p>Lazy H vežimėlis susideda i&scaron;&nbsp;<strong>trijų nuimamų dalių</strong>, pagamintų i&scaron;&nbsp;<strong>jonizuoto metalinio mėlyno aliuminio</strong>. Dėl &scaron;ios konstrukcijos jį lengva i&scaron;ardyti ir patogiai laikyti &ndash; jis&nbsp;<strong>telpa kajako korpuso viduje</strong>, todėl nereikia papildomos vietos transportuojant.</p>\n<p>Reguliuojama sistema leidžia&nbsp;<strong>pritaikyti vežimėlį daugumai sit-on-top kajakų</strong>. Plotis gali būti padidintas arba sumažintas, kad atitiktų skirtingų modelių&nbsp;<strong>drenažo angų atstumą</strong>. Be to, įsistatančios dalys turi&nbsp;<strong>guminę apsaugą</strong>, kuri ne tik saugo&nbsp;<strong>kajako drenažo angas nuo pažeidimų</strong>, bet ir užtikrina geresnį sukibimą, todėl vežimėlis tvirčiau laikosi.</p>\n<p>&nbsp;</p>\n<h3><strong>Tinka Visų Tipų Pavir&scaron;iams</strong></h3>\n<p>&Scaron;is vežimėlis gali būti naudojamas ant įvairių pavir&scaron;ių, įskaitant:<br />✔&nbsp;<strong>Asfaltą ir &scaron;aligatvius</strong><br />✔&nbsp;<strong>Paplūdimius ir smėlį</strong><br />✔&nbsp;<strong>Akmenuotas pakrantes ir nelygius pavir&scaron;ius</strong></p>\n<p><strong>Pripučiami ratai</strong>&nbsp;yra pagaminti i&scaron; itin patvarios gumos ir&nbsp;<strong>gali atlaikyti iki 55 kg apkrovą kiekviename rate</strong>. Siekiant maksimalios i&scaron;tvermės, rekomenduojama juos pripūsti&nbsp;<strong>2-4 PSI slėgiu</strong>.</p>\n<p>&nbsp;</p>\n<h3><strong>Universalus ir Tvirtas Dizainas</strong></h3>\n<p><strong>Lazy H Kajako Vežimėlis</strong>&nbsp;yra tinkamas&nbsp;<strong>įvairiems sit-on-top</strong>&nbsp;vandens transporto priemonių modeliams, įskaitant:<br />✔&nbsp;<strong>Žvejybinius kajakus</strong><br />✔&nbsp;<strong>Poilsinius kajakus</strong></p>\n<p>Dėl savo tvirtos konstrukcijos vežimėlis gali atlaikyti&nbsp;<strong>iki 90 kg svorį</strong>, o&nbsp;<strong>unikali metalinė mėlyna apdaila</strong>&nbsp;i&scaron;skiria jį i&scaron; kitų rinkoje esančių modelių.</p>\n<h3><strong>Specifikacijos</strong></h3>\n<p>✔&nbsp;<strong>Komplektacija:</strong></p>\n<ul>\n<li>\n<p>2 vienetai:&nbsp;<strong>46 cm x 2 cm x 1.7 cm</strong></p>\n</li>\n<li>\n<p>1 vienetas:&nbsp;<strong>86.5 cm x 2 cm x 1.7 cm</strong></p>\n</li>\n</ul>\n<p>✔&nbsp;<strong>Medžiaga:</strong>&nbsp;<strong>Jonizuotas metalinis mėlynas aliuminis &amp; guma</strong><br />✔&nbsp;<strong>Maksimali apkrova:</strong>&nbsp;<strong>90 kg</strong><br />✔&nbsp;<strong>Pakuotės svoris:</strong>&nbsp;<strong>6 kg</strong><br />✔&nbsp;<strong>Pakuotės dydis:</strong>&nbsp;<strong>90 cm x 40 cm x 20 cm</strong></p>\n<p><strong>Lazy H Kajako Vežimėlis</strong>&nbsp;&ndash; tai patikimas, lengvai transportuojamas ir universalus sprendimas kiekvienam kajako entuziastui!</p>\n<div data-youtube-video=""><iframe src="https://www.youtube-nocookie.com/embed/ZWJLsKjLGD8?si=vjpu64hyS3qkKMyb" width="640" height="480" data-mce-fragment="1"></iframe></div>	8436618811905	5	2	169.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803074-lazy-h-kayak-cart-by-lazy-boys.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803076-lazy-h-kayak-cart-by-lazy-boys5.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803078-lazy-h-kayak-cart-by-lazy-boys22.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803075-lazy-h-kayak-cart-by-lazy-boys1.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803075-lazy-h-kayak-cart-by-lazy-boys2.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803075-lazy-h-kayak-cart-by-lazy-boys0.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803075-lazy-h-kayak-cart-by-lazy-boys4.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803078-lazy-h-kayak-cart-by-lazy-boys33.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803075-lazy-h-kayak-cart-by-lazy-boys3.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803077-lazy-h-kayak-cart-by-lazy-boys9.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803076-lazy-h-kayak-cart-by-lazy-boys6.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803077-lazy-h-kayak-cart-by-lazy-boys7.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1739217803077-lazy-h-kayak-cart-by-lazy-boys8.jpg"	Lazy Boys	\N	\N	4.000	\N	\N	\N	2025-05-14 18:59:18.550432	2025-05-14 21:46:07.321491
79	KT01	Kajako, valties transportavimo vežimėlis	<h2><strong>Kajako transportavimo vežimėlis </strong></h2>\n<p><strong>Patikima ir ekonomi&scaron;ka alternatyva</strong> žinomam C-Tug vežimėliui. &Scaron;is <strong>universalus kajako vežimėlis</strong> puikiai tinka daugumai rinkoje esančių vienviečių ir dviviečių kajakų.</p>\n<hr />\n<h3><strong>Pagrindiniai privalumai:</strong></h3>\n<ul>\n<li>\n<p><strong>Lengva, bet patvari kompozitinė konstrukcija</strong> &ndash; vežimėlis sveria nedaug, bet atlaiko iki <strong>120 kg</strong></p>\n</li>\n<li>\n<p><strong>Sulankstomas dizainas</strong> &ndash; visas vežimėlis telpa į daugumos kajakų liukus, todėl nereikia papildomos vietos transportavimui</p>\n</li>\n<li>\n<p><strong>Greitas surinkimas / i&scaron;ardymas</strong> &ndash; viskas atliekama per mažiau nei minutę</p>\n</li>\n<li>\n<p><strong>Tvirti ratai</strong> &ndash; puikiai rieda net per smėlį, žvyrą ar žolę</p>\n</li>\n<li>\n<p><strong>Guminiai laikikliai</strong> &ndash; saugo kajako korpusą ir padidina sukibimą</p>\n</li>\n<li>\n<p>Tinka <strong>žvejybiniams, rekreaciniams ir touring tipo kajakams</strong></p>\n</li>\n</ul>\n<hr />\n<h3><strong>Techninės specifikacijos:</strong></h3>\n<ul>\n<li>\n<p><strong>Maksimali apkrova:</strong> 120 kg</p>\n</li>\n<li>\n<p><strong>Konstrukcija:</strong> Kompozitinis plastikas + nerūdijančio plieno tvirtinimai</p>\n</li>\n<li>\n<p><strong>Surinkimo/laikymo laikas:</strong> &lt;1 minutė</p>\n</li>\n<li>\n<p><strong>Tinka laikyti kajako liuke</strong></p>\n</li>\n</ul>\n<hr />\n<h3><strong>Kas tai per modelis?</strong></h3>\n<p>Tai <strong>funkcionalumu Railblaza C-Tug vežimėlį primenantis modelis</strong>, tačiau tai nėra originalus Railblaza produktas. Ie&scaron;kantiems patikimo sprendimo už prieinamesnę kainą &ndash; tai puikus pasirinkimas.</p>\n<hr />\n<h3><strong>Kam skirtas &scaron;is vežimėlis?</strong></h3>\n<ul>\n<li>\n<p>Tiems, kurie dažnai keliauja vieni ir nori greitai pasistatyti ar patraukti kajaką</p>\n</li>\n<li>\n<p>Naudotojams, ie&scaron;kantiems <strong>kompakti&scaron;ko sprendimo</strong>, kurį galima laikyti <strong>kajako viduje</strong></p>\n</li>\n<li>\n<p>Vandens sporto entuziastams, kuriems reikia <strong>mobilumo ir greito naudojimo sprendimo</strong></p>\n</li>\n</ul>\n<hr />\n<h3><strong>Svarbu žinoti:</strong></h3>\n<p>&Scaron;is modelis <strong>nėra sertifikuotas originalus Railblaza C-Tug</strong> vežimėlis. Tai rinkoje populiarios konstrukcijos pagrindu pagaminta alternatyva, užtikrinanti daugumą svarbiausių funkcinių savybių už geresnę kainą.</p>	9421026831926	5	2	99.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1745994080870-h4f3ec827aeb14916aadcbdf35bc1bbee9.jpg.webp	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1745994080869-h1e5cd9ef05f14199bf5f00d4bcd2f4496.jpg.webp | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1745994221408-hb6ea962d7558403ab0821333d7a1c61a9.jpg.webp | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1745994080870-hd5d2f6c7837e41cba75584a42eb8a6f2d.jpg.webp | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1745994221408-h82ea0f09da194ec8a58d4ad27f77c1825.jpg.webp | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1745994161415-h935f822ff1944ce987ad2fcc34efe8e3e.jpg.webp | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1745994221407-h5ae23684491a48e6800ee6d1ad502547z.jpg.webp | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1745994080869-h1e5cd9ef05f14199bf5f00d4bcd2f4496.jpg.webp"	\N	\N	\N	5.000	\N	\N	\N	2025-05-14 18:59:18.553013	2025-05-14 21:46:07.3269
80	02-4132-11	RAILBLAZA Camera Boom 600 R-Lock	<h3><strong>RAILBLAZA Camera Boom 600 R-Lock &ndash; užfiksuokite kiekvieną akimirką i&scaron; tobuliausio kampo!</strong></h3>\n<p>&nbsp;</p>\n<p><strong>RAILBLAZA Camera Boom 600 R-Lock</strong> &ndash; tai <strong>inovatyvus ir universalus kameros laikiklis</strong>, leidžiantis <strong>lengvai užfiksuoti įspūdingiausias akimirkas</strong> ant vandens. Su <strong>750 mm ilgio reguliuojama strėle ir 4 reguliuojamais jungties ta&scaron;kais</strong>, galėsite nufotografuoti ar nufilmuoti veiksmą i&scaron; <strong>bet kurio kampo</strong>, be papildomos įrangos.</p>\n<p>Nesvarbu, ar gaudote įspūdingą laimikį, ar plaukiate ant bangos &ndash; <strong>Camera Boom 600 R-Lock</strong> užtikrins, kad viskas būtų <strong>užfiksuota stilingai ir kokybi&scaron;kai</strong>.</p>\n<p>&nbsp;</p>\n<h3><strong>Pagrindinės savybės:</strong></h3>\n<p>📸 <strong>Užfiksuokite veiksmą kaip niekada anksčiau</strong> &ndash; tobulas pasirinkimas tiek pradedantiesiems, tiek profesionaliems fotografams.<br />🔄 <strong>Reguliuojamas kampas</strong> &ndash; 750 mm ilgio strėlė ir <strong>4 judančios jungtys</strong> leidžia nustatyti bet kokį norimą kampą.<br />🛠️ <strong>Nuimama vir&scaron;utinė platforma</strong> &ndash; vir&scaron;utinę kameros tvirtinimo dalį galite lengvai nuimti ir naudoti kitur.<br />🎥 <strong>Suderinama su GoPro ir kitomis kameromis</strong> &ndash; vir&scaron;utinėje platformoje esantis varžtas tinka daugumai kamerų modelių.<br />🌊 <strong>Atspari UV spinduliams</strong> &ndash; pagaminta i&scaron; <strong>UV stabilizuoto stiklo pluo&scaron;tu sustiprinto plastiko</strong>, užtikrinančio ilgaamži&scaron;kumą.<br />⚓ <strong>Lengvas montavimas</strong> &ndash; laikiklis tinka bet kuriam <strong>RAILBLAZA StarPort</strong> ir nereikalauja papildomų įrankių.</p>\n<p>&nbsp;</p>\n<h3><strong>Techninės specifikacijos:</strong></h3>\n<ul>\n<li>\n<p><strong>Ilgis:</strong> 750 mm</p>\n</li>\n<li>\n<p><strong>Medžiaga:</strong> UV stabilizuotas stiklo pluo&scaron;tu sustiprintas plastikas</p>\n</li>\n<li>\n<p><strong>Svoris:</strong>&nbsp;0,4 kg</p>\n</li>\n<li>\n<p><strong>Auk&scaron;tis:</strong> 85 cm&nbsp;</p>\n</li>\n<li>\n<p><strong>Plotis:</strong> 11 cm&nbsp;</p>\n</li>\n<li>\n<p><strong>Ilgis:</strong> 6 cm&nbsp;</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<h3><strong>Komplektacija:</strong></h3>\n<p>✔ <strong>1 x Camera Boom 600 R-Lock laikiklis</strong></p>\n<p><strong>Pastaba:</strong> <strong>Pagrindas parduodamas atskirai.</strong></p>\n<p>&nbsp;</p>\n<h3><strong>Privalumai:</strong></h3>\n<p>✅ Lengvai užfiksuokite kvapą gniaužiančius veiksmų kadrus.<br />✅ 750 mm auk&scaron;tis leidžia nufotografuoti i&scaron; vir&scaron;aus.<br />✅ Universalus ir reguliuojamas laikiklis, tinkantis įvairiems kampams.<br />✅ Nuimama vir&scaron;utinė platforma užtikrina nevaržomą vaizdą.<br />✅ Suderinama su <strong>GoPro</strong> kameromis ir dauguma kitų modelių.</p>\n<p>&nbsp;</p>\n<p><strong>Būkite pasiruo&scaron;ę kitam nuotykiui ant vandens su RAILBLAZA Camera Boom 600 R-Lock &ndash; jūsų geriausioms akimirkoms įamžinti!</strong> 🌊📸</p>	9421026833648	5	2	59.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740215593587-02-4132-11-CameraBoom600R-Lock-NB.png	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740215593586-02-4132-11_600.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740215593587-Holton-Walker-Assassin-Paddle-Railblaza-Camera-Boom-600-Cratewell-scaled.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740215593587-Camera-Boom-600-R-Lock-3259__FillWzYwMCw2MDBd.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740215593587-Camera-Boom-600-R-Lock-3262__FillWzYwMCw2MDBd.jpeg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740215593587-Camera-Boom-600-R-Lock-3475__FillWzYwMCw2MDBd.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740216397576-laikiklis-kamero-railblaza-r-600-1-1.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1740216397576-laikiklis-kamero-railblaza-r-600-3.jpg"	\N	\N	\N	3.000	\N	\N	\N	2025-05-14 18:59:18.554406	2025-05-14 21:46:07.329569
81	50009.02.100	Saitas irklentei NRS COIL SUP LEASH (3,5m)	<h3>NRS SUP Board Leash</h3>\n<p>&nbsp;</p>\n<p>&bdquo;NRS SUP Board Leash&ldquo; turi tvirtai suvyniotą virvę, kuri netrukdo jums, kai jos nereikia. Puikiai tinka plaukioti stovint ant irklentės.</p>\n<ul>\n<li>\n<p>Lengvas suvyniotas pavadėlis i&scaron;sitempia, kad suteiktų visi&scaron;ką judėjimo laisvę, o kai esate veiksmo vietoje, netrukdo jums.</p>\n</li>\n<li>\n<p>Atsipalaidavusi ritė yra tik 51 cm ilgio, bet i&scaron;sitempia iki 350 cm.</p>\n</li>\n<li>\n<p>Dvi eilutės suktukai neleidžia pavadėliui susipainioti.</p>\n</li>\n<li>\n<p>5 cm pločio pamink&scaron;tintas blauzdos dirželis užtikrina patogumą visą dieną. Užsegamas kabliuku ir kilpa.</p>\n</li>\n<li>\n<p>Pridedamas dirželis leidžia lengvai pritvirtinti pavadėlio ki&scaron;tuką prie standžios SUP lentos (Irklentės).</p>\n<p>&nbsp;</p>\n</li>\n</ul>\n<p>&nbsp;</p>\n<p><strong>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</strong></p>	603403206286	1	2	60.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730309335297-50009_02_16001_011813_1000x1000.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1730309335296-15009_01_na_12_Packaging_041719_1000x1000.jpg"	\N	\N	\N	1.000	\N	\N	\N	2025-05-14 18:59:18.555648	2025-05-14 21:46:07.331571
82	A-10b	Dviejų dalių Irklas	<p><strong>Galaxy Kayak dviejų dalių Irklas</strong></p>\n<p>Dviejų dalių irklas yra lengvas ir reguliuojamas taip, kad atitiktų naudotojų pageidavimus. &Scaron;is aliuminio irklas padengtas juoda guma. Ties rankų laikymo vieta padengtas neslystančia danga kuri suteikia puikų rankos-irklo sukibimą.</p>\n<p>Guminė rankena yra &scaron;iek tiek ovalo formos vienoje pusėje, kad geriau prisitaikytų prie jūsų delno formos ir duotų geresnį sukibimą. Irklo mentys yra &scaron;velniai i&scaron;lenkti, kad padidėtų trintis stumiant vandenį.</p>\n<p>Irklo centre yra lengva mygtuko paspaudimo sistema, skirta pritvirtinti arba nuimti abi dalis, pakeisti menčių kampą, pailginti ar patrumpinti irklą.</p>\n<p><u><strong>Specifikacija:</strong></u></p>\n<p>Medžiaga: aliuminis ir HDPE</p>\n<p>I&scaron;matavimai: 210cm x 3cm, mentė: 17cm x 45cm</p>\n<p>Svoris: 93,2 g</p>\n<p>&nbsp;</p>\n<p><u>*Prekių nuotraukos yra informacinio &ndash; iliustracinio pobūdžio ir gali skirtis nuo apra&scaron;yme pateiktos komplektacijos.</u></p>	8436618811578	7	2	30.00	\N	\N	https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fimages%2F17030592316166-3115131768.jpg	"https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703318196986-Galaxy%20Kayaks%20Black%20Paddle%20COVER%20IMAGE.jpg | https://cdn.zyrosite.com/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1703318196987-Galaxy%20Kayaks%20Black%20Paddle%20Side%202.jpg"	\N	\N	\N	2.000	\N	\N	\N	2025-05-14 18:59:18.556951	2025-05-15 10:42:35.206372
\.


--
-- Data for Name: shipment_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shipment_items (id, shipment_id, product_id, quantity, cost_price, notes) FROM stdin;
1	1	82	3	10.00	
2	1	78	1	\N	
3	1	42	1	\N	
4	2	48	4	400.00	
5	3	40	2	497.00	1x Midnight Storm, 1 x Sage
\.


--
-- Data for Name: shipments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shipments (id, shipment_number, supplier, expected_date, arrival_date, status, notes, user_id, created_at, updated_at) FROM stdin;
1	SHIP-0001	Kinija	2025-05-14	2025-05-15	RECEIVED		2	2025-05-14 21:12:42.445641	2025-05-15 10:12:33.262248
2	SHIP-0002	Kinija	2025-05-15	\N	PENDING		2	2025-05-15 10:50:18.528937	2025-05-15 10:50:18.528941
3	SHIP-0003	Kinija	2023-12-15	\N	PENDING		2	2025-05-15 11:57:34.704196	2025-05-15 11:57:34.704199
4	asd		2025-05-15	\N	PENDING		2	2025-05-15 19:04:38.039982	2025-05-15 19:04:38.039985
\.


--
-- Data for Name: stock_movements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stock_movements (id, product_id, qty_delta, reason_code, note, channel, reference_id, user_id, created_at, updated_at) FROM stdin;
1	11	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.244796	2025-05-14 20:38:42.244799
2	12	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.250549	2025-05-14 20:38:42.250551
3	13	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.253231	2025-05-14 20:38:42.253232
4	14	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.255923	2025-05-14 20:38:42.255924
5	15	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.259012	2025-05-14 20:38:42.259014
6	16	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.261948	2025-05-14 20:38:42.261949
7	17	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.265099	2025-05-14 20:38:42.265101
8	18	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.267734	2025-05-14 20:38:42.267736
9	19	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.270444	2025-05-14 20:38:42.270445
10	20	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.273211	2025-05-14 20:38:42.273212
11	21	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.275518	2025-05-14 20:38:42.275519
12	22	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.278251	2025-05-14 20:38:42.278253
13	23	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.281171	2025-05-14 20:38:42.281173
14	24	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.283818	2025-05-14 20:38:42.283819
15	25	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.286823	2025-05-14 20:38:42.286824
16	26	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.289178	2025-05-14 20:38:42.28918
17	27	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.291838	2025-05-14 20:38:42.291839
18	28	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.294313	2025-05-14 20:38:42.294315
19	29	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.296992	2025-05-14 20:38:42.296994
20	30	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.300462	2025-05-14 20:38:42.300463
21	31	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.303196	2025-05-14 20:38:42.303197
22	32	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.30562	2025-05-14 20:38:42.305622
23	33	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.308372	2025-05-14 20:38:42.308374
24	34	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.310818	2025-05-14 20:38:42.31082
25	35	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.313882	2025-05-14 20:38:42.313883
26	36	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.316734	2025-05-14 20:38:42.316736
27	37	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.319162	2025-05-14 20:38:42.319164
28	38	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.32188	2025-05-14 20:38:42.321882
29	39	3	IMPORT	Import update: 0 → 3	web	\N	2	2025-05-14 20:38:42.325071	2025-05-14 20:38:42.325073
30	41	2	IMPORT	Import update: 0 → 2	web	\N	2	2025-05-14 20:38:42.330662	2025-05-14 20:38:42.330664
31	42	2	IMPORT	Import update: 0 → 2	web	\N	2	2025-05-14 20:38:42.333812	2025-05-14 20:38:42.333814
32	43	2	IMPORT	Import update: 0 → 2	web	\N	2	2025-05-14 20:38:42.336586	2025-05-14 20:38:42.336587
33	45	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.34118	2025-05-14 20:38:42.341181
34	46	2	IMPORT	Import update: 0 → 2	web	\N	2	2025-05-14 20:38:42.344604	2025-05-14 20:38:42.344605
35	49	2	IMPORT	Import update: 0 → 2	web	\N	2	2025-05-14 20:38:42.351372	2025-05-14 20:38:42.351374
36	50	2	IMPORT	Import update: 0 → 2	web	\N	2	2025-05-14 20:38:42.353794	2025-05-14 20:38:42.353795
37	51	2	IMPORT	Import update: 0 → 2	web	\N	2	2025-05-14 20:38:42.356273	2025-05-14 20:38:42.356274
38	52	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.358305	2025-05-14 20:38:42.358306
39	53	5	IMPORT	Import update: 0 → 5	web	\N	2	2025-05-14 20:38:42.361228	2025-05-14 20:38:42.36123
40	54	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.3638	2025-05-14 20:38:42.363802
41	55	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.365669	2025-05-14 20:38:42.36567
42	56	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.367759	2025-05-14 20:38:42.367761
43	57	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.369746	2025-05-14 20:38:42.369747
44	58	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.371725	2025-05-14 20:38:42.371726
45	59	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.373513	2025-05-14 20:38:42.373514
46	60	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.375275	2025-05-14 20:38:42.375276
47	61	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.377442	2025-05-14 20:38:42.377443
48	62	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.379114	2025-05-14 20:38:42.379115
49	63	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.380808	2025-05-14 20:38:42.380809
50	64	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.38244	2025-05-14 20:38:42.382441
51	65	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.384139	2025-05-14 20:38:42.38414
52	66	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.385769	2025-05-14 20:38:42.38577
53	67	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.387386	2025-05-14 20:38:42.387387
54	68	5	IMPORT	Import update: 0 → 5	web	\N	2	2025-05-14 20:38:42.388973	2025-05-14 20:38:42.388974
55	69	5	IMPORT	Import update: 0 → 5	web	\N	2	2025-05-14 20:38:42.390611	2025-05-14 20:38:42.390612
56	70	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.392596	2025-05-14 20:38:42.392598
57	71	10	IMPORT	Import update: 0 → 10	web	\N	2	2025-05-14 20:38:42.395482	2025-05-14 20:38:42.395484
58	72	2	IMPORT	Import update: 0 → 2	web	\N	2	2025-05-14 20:38:42.397686	2025-05-14 20:38:42.397687
59	73	2	IMPORT	Import update: 0 → 2	web	\N	2	2025-05-14 20:38:42.399434	2025-05-14 20:38:42.399435
60	74	2	IMPORT	Import update: 0 → 2	web	\N	2	2025-05-14 20:38:42.401068	2025-05-14 20:38:42.401069
61	75	5	IMPORT	Import update: 0 → 5	web	\N	2	2025-05-14 20:38:42.403183	2025-05-14 20:38:42.403184
62	76	5	IMPORT	Import update: 0 → 5	web	\N	2	2025-05-14 20:38:42.404849	2025-05-14 20:38:42.40485
63	77	5	IMPORT	Import update: 0 → 5	web	\N	2	2025-05-14 20:38:42.406453	2025-05-14 20:38:42.406454
64	78	5	IMPORT	Import update: 0 → 5	web	\N	2	2025-05-14 20:38:42.408162	2025-05-14 20:38:42.408163
65	79	5	IMPORT	Import update: 0 → 5	web	\N	2	2025-05-14 20:38:42.409937	2025-05-14 20:38:42.409938
66	80	5	IMPORT	Import update: 0 → 5	web	\N	2	2025-05-14 20:38:42.411613	2025-05-14 20:38:42.411614
67	81	1	IMPORT	Import update: 0 → 1	web	\N	2	2025-05-14 20:38:42.413197	2025-05-14 20:38:42.413198
68	82	5	IMPORT	Import update: 0 → 5	web	\N	2	2025-05-14 20:38:42.415245	2025-05-14 20:38:42.415246
69	82	3	shipment	Shipment arrival: SHIP-0001	\N	1	2	2025-05-15 10:12:33.246128	2025-05-15 10:12:33.246128
70	78	1	shipment	Shipment arrival: SHIP-0001	\N	1	2	2025-05-15 10:12:33.255601	2025-05-15 10:12:33.255601
71	42	1	shipment	Shipment arrival: SHIP-0001	\N	1	2	2025-05-15 10:12:33.26	2025-05-15 10:12:33.26
72	78	-1	SALE	Užsakymas TST-78 išsiųstas	order	TST-78	\N	2025-05-15 10:29:23.820763	2025-05-15 10:29:23.820765
73	42	-1	SALE	Užsakymas TST-42 išsiųstas	order	6	\N	2025-05-15 10:30:58.6414	2025-05-15 10:30:58.641403
74	82	-1	SALE	Užsakymas ORD-00043 išsiųstas	order	7	\N	2025-05-15 10:42:35.209157	2025-05-15 10:42:35.20916
75	7	-1	SALE	Užsakymas ORD-00044 išsiųstas	order	8	\N	2025-05-15 11:31:24.497553	2025-05-15 11:31:24.497557
76	72	-1	SALE	Užsakymas ORD-00044 išsiųstas	order	8	\N	2025-05-15 11:31:24.514203	2025-05-15 11:31:24.514206
77	9	-1	SALE	Užsakymas ORD-00044 išsiųstas	order	8	\N	2025-05-15 11:31:24.52209	2025-05-15 11:31:24.522091
\.


--
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tasks (id, title, description, customer_id, status, priority, due_date, assigned_to, created_by, completed_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transactions (id, date, reference_type, reference_id, description, total_amount, is_posted, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, email, password_hash, is_active, is_admin, last_login, created_at, updated_at, name, preferences) FROM stdin;
1	admin	admin@example.com	pbkdf2:sha256:260000$lRFZvmC85sZde49s$2964a597d18698d46f9ece4ea02f641513f0863673bfc2a1b747e791377565bd	f	t	\N	2025-05-13 22:57:20.842954	2025-05-15 09:59:27.101671	admin	\N
2	andrius	wimass@gmail.com	pbkdf2:sha256:260000$bEcqBzWJb9ABaECa$72af2a477f3a0ae49ff3ec423467841ba77af12885247f19fa0e6997d2b254cb	t	t	\N	2025-05-14 11:58:58.108833	2025-05-15 12:57:51.948205	andrius	{"product_columns": ["sku", "name", "category", "barcode", "price_final", "quantity", "model"]}
\.


--
-- Name: accounts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.accounts_id_seq', 9, true);


--
-- Name: company_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.company_settings_id_seq', 1, true);


--
-- Name: contacts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.contacts_id_seq', 1, false);


--
-- Name: customers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customers_id_seq', 3, true);


--
-- Name: entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.entries_id_seq', 1, false);


--
-- Name: export_configs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.export_configs_id_seq', 1, false);


--
-- Name: integration_sync_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.integration_sync_logs_id_seq', 1, false);


--
-- Name: invoice_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.invoice_items_id_seq', 7, true);


--
-- Name: invoices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.invoices_id_seq', 9, true);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_items_id_seq', 13, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orders_id_seq', 8, true);


--
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.products_id_seq', 88, true);


--
-- Name: shipment_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.shipment_items_id_seq', 6, true);


--
-- Name: shipments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.shipments_id_seq', 4, true);


--
-- Name: stock_movements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.stock_movements_id_seq', 77, true);


--
-- Name: tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tasks_id_seq', 1, false);


--
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transactions_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: company_settings company_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_settings
    ADD CONSTRAINT company_settings_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: entries entries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT entries_pkey PRIMARY KEY (id);


--
-- Name: export_configs export_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.export_configs
    ADD CONSTRAINT export_configs_pkey PRIMARY KEY (id);


--
-- Name: integration_sync_logs integration_sync_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integration_sync_logs
    ADD CONSTRAINT integration_sync_logs_pkey PRIMARY KEY (id);


--
-- Name: invoice_items invoice_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: shipment_items shipment_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shipment_items
    ADD CONSTRAINT shipment_items_pkey PRIMARY KEY (id);


--
-- Name: shipments shipments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_pkey PRIMARY KEY (id);


--
-- Name: shipments shipments_shipment_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_shipment_number_key UNIQUE (shipment_number);


--
-- Name: stock_movements stock_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: ix_accounts_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_accounts_code ON public.accounts USING btree (code);


--
-- Name: ix_customers_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_customers_email ON public.customers USING btree (email);


--
-- Name: ix_invoices_invoice_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_invoices_invoice_number ON public.invoices USING btree (invoice_number);


--
-- Name: ix_orders_order_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_orders_order_number ON public.orders USING btree (order_number);


--
-- Name: ix_products_sku; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_products_sku ON public.products USING btree (sku);


--
-- Name: ix_transactions_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_transactions_date ON public.transactions USING btree (date);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_username ON public.users USING btree (username);


--
-- Name: contacts contacts_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: customers customers_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id);


--
-- Name: entries entries_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT entries_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: entries entries_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT entries_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id);


--
-- Name: export_configs export_configs_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.export_configs
    ADD CONSTRAINT export_configs_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: integration_sync_logs integration_sync_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integration_sync_logs
    ADD CONSTRAINT integration_sync_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: invoice_items invoice_items_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(id);


--
-- Name: invoice_items invoice_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: invoices invoices_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: invoices invoices_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: orders orders_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: shipment_items shipment_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shipment_items
    ADD CONSTRAINT shipment_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: shipment_items shipment_items_shipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shipment_items
    ADD CONSTRAINT shipment_items_shipment_id_fkey FOREIGN KEY (shipment_id) REFERENCES public.shipments(id);


--
-- Name: shipments shipments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: stock_movements stock_movements_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: stock_movements stock_movements_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: tasks tasks_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id);


--
-- Name: tasks tasks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: tasks tasks_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- PostgreSQL database dump complete
--

