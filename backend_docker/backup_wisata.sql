--
-- PostgreSQL database dump
--

\restrict QdQoEmb85OKNJ99inITrpeoK9vnyJxRrMQ886lJI4L14WWFEGTmh58fyfZvdHHy

-- Dumped from database version 16.14 (Debian 16.14-1.pgdg13+1)
-- Dumped by pg_dump version 16.14 (Debian 16.14-1.pgdg13+1)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: armada_bus; Type: TABLE; Schema: public; Owner: admin_wisata
--

CREATE TABLE public.armada_bus (
    id bigint NOT NULL,
    id_proyek bigint,
    nama_bus character varying(50) NOT NULL,
    lat_titik_kumpul numeric(10,5),
    lon_titik_kumpul numeric(10,5)
);


ALTER TABLE public.armada_bus OWNER TO admin_wisata;

--
-- Name: armada_bus_id_seq; Type: SEQUENCE; Schema: public; Owner: admin_wisata
--

CREATE SEQUENCE public.armada_bus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.armada_bus_id_seq OWNER TO admin_wisata;

--
-- Name: armada_bus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin_wisata
--

ALTER SEQUENCE public.armada_bus_id_seq OWNED BY public.armada_bus.id;


--
-- Name: peserta; Type: TABLE; Schema: public; Owner: admin_wisata
--

CREATE TABLE public.peserta (
    id_peserta character varying(20) NOT NULL,
    nama_lengkap character varying(100) NOT NULL,
    id_bus bigint,
    qr_secret_key character varying(255)
);


ALTER TABLE public.peserta OWNER TO admin_wisata;

--
-- Name: proyek_perjalanan; Type: TABLE; Schema: public; Owner: admin_wisata
--

CREATE TABLE public.proyek_perjalanan (
    id bigint NOT NULL,
    nama_tujuan character varying(100) NOT NULL,
    tanggal_berangkat date
);


ALTER TABLE public.proyek_perjalanan OWNER TO admin_wisata;

--
-- Name: proyek_perjalanan_id_seq; Type: SEQUENCE; Schema: public; Owner: admin_wisata
--

CREATE SEQUENCE public.proyek_perjalanan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.proyek_perjalanan_id_seq OWNER TO admin_wisata;

--
-- Name: proyek_perjalanan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin_wisata
--

ALTER SEQUENCE public.proyek_perjalanan_id_seq OWNED BY public.proyek_perjalanan.id;


--
-- Name: armada_bus id; Type: DEFAULT; Schema: public; Owner: admin_wisata
--

ALTER TABLE ONLY public.armada_bus ALTER COLUMN id SET DEFAULT nextval('public.armada_bus_id_seq'::regclass);


--
-- Name: proyek_perjalanan id; Type: DEFAULT; Schema: public; Owner: admin_wisata
--

ALTER TABLE ONLY public.proyek_perjalanan ALTER COLUMN id SET DEFAULT nextval('public.proyek_perjalanan_id_seq'::regclass);


--
-- Data for Name: armada_bus; Type: TABLE DATA; Schema: public; Owner: admin_wisata
--

COPY public.armada_bus (id, id_proyek, nama_bus, lat_titik_kumpul, lon_titik_kumpul) FROM stdin;
1	1	Vella Autotrans (HIMTEK)	0.00000	0.00000
2	1	Surya Agung (HMTI)	0.00000	0.00000
\.


--
-- Data for Name: peserta; Type: TABLE DATA; Schema: public; Owner: admin_wisata
--

COPY public.peserta (id_peserta, nama_lengkap, id_bus, qr_secret_key) FROM stdin;
EMP-SA01-206	Jovensy Devianto	2	JETVG3XGKRSOFYH6
EMP-SA01-169	Benediktus Adryano Vito	2	DHR5KUTFR6WE43NO
EMP-SA01-177	Anisa Nur Salsabila	2	BJKCFG5RBI7RF7GK
EMP-SA01-050	Adlya Adhwa Prabowo	2	BUX3WIZZMGSJIJTR
EMP-SA01-023	Nadin Neva Mulyani	2	7KPKWLRNBACR4HYG
EMP-SA01-141	Rezki Mepta Kurniawan	2	2SCKPDFNJK5UGC2V
EMP-SA01-164	Rajif Anwar Miftahul Falah	2	3W7DP65MVDKZ3PNH
EMP-SA01-131	Aishafa Dwita Radiasari	2	22KIWR46QTIHMRGN
EMP-SA01-081	Maulidia Sintia Bella	2	UH7WMFHUMLBEU2B3
EMP-SA01-146	Muhammad Afrian Pratama	2	FXJ35LSHTX55T3WI
EMP-SA01-130	Firda Muthmainnah	2	KDV2VQAAYHQBO6Y6
EMP-SA01-159	Haikal Firza Zaidu Dzaka	2	XXU7HIGWWDXEBB5W
EMP-SA01-091	Rahman Fahid	2	U5YP6MTUOUBPQDJJ
EMP-SA01-188	Rachel Wanda Chirstiani	2	ZQEXGDWAT3XZ4JSG
EMP-SA01-158	Selvia Hanif Ardian Putri	2	QX5YMX54KD55RAYT
EMP-SA01-121	Dirly Aldy Tombeng	2	BCRALA4SSUL6VQHE
EMP-VA01-058	Riyan Ardian Syah	1	TP3IIPF76Q4VVAEQ
EMP-VA01-038	Dwiyan Agung Wicaksono	1	6QJYKDEVKFOXVLPW
EMP-VA01-046	Dian Ramadanti	1	7MXFX7AJRSK7QX2T
EMP-VA01-009	Lidia Fitriana	1	INLOTAWNFEVDOLLG
EMP-VA01-068	Aprian Adi Setyawan	1	OXPENIPPJ345NZEP
EMP-VA01-035	Alifia Sindi Ananda	1	UJMNFRMBR34UUJQ6
EMP-VA01-023	Sri Zulfa	1	244EZ3ZYA5RGPXDM
EMP-VA01-054	Yodha Ardiansyah	1	PEFV4KBWWSVSGGFP
EMP-VA01-028	Ahmad Nur Fauzan	1	KI32I5VWEF56XRQN
EMP-VA01-053	Achmad Agim Machfud	1	WTRLKQPDVIFRXZDB
EMP-VA01-003	Cindy Aurelia	1	M65WF6LNVE37DJTK
EMP-VA01-022	Laora Margareth Gogali	1	YQKLG22YRKVM47R2
EMP-VA01-041	Ivan Bagus Zulpani	1	34H5X3OKPK456P3T
EMP-VA01-067	Agung Hanif Izzatulhaq	1	CPJG7FNBOVGVIZ6H
EMP-VA01-016	Rizqi Akbar Hernawan	1	N2E4LA6LYGAD44IU
EMP-VA01-001	Raditya Ramadhan	1	GYBMJCHNDUSALJJI
\.


--
-- Data for Name: proyek_perjalanan; Type: TABLE DATA; Schema: public; Owner: admin_wisata
--

COPY public.proyek_perjalanan (id, nama_tujuan, tanggal_berangkat) FROM stdin;
1	Surabaya - Bali (Collaboration Engineering In Action)	2025-07-07
\.


--
-- Name: armada_bus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin_wisata
--

SELECT pg_catalog.setval('public.armada_bus_id_seq', 2, true);


--
-- Name: proyek_perjalanan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin_wisata
--

SELECT pg_catalog.setval('public.proyek_perjalanan_id_seq', 1, true);


--
-- Name: armada_bus armada_bus_pkey; Type: CONSTRAINT; Schema: public; Owner: admin_wisata
--

ALTER TABLE ONLY public.armada_bus
    ADD CONSTRAINT armada_bus_pkey PRIMARY KEY (id);


--
-- Name: peserta peserta_pkey; Type: CONSTRAINT; Schema: public; Owner: admin_wisata
--

ALTER TABLE ONLY public.peserta
    ADD CONSTRAINT peserta_pkey PRIMARY KEY (id_peserta);


--
-- Name: proyek_perjalanan proyek_perjalanan_pkey; Type: CONSTRAINT; Schema: public; Owner: admin_wisata
--

ALTER TABLE ONLY public.proyek_perjalanan
    ADD CONSTRAINT proyek_perjalanan_pkey PRIMARY KEY (id);


--
-- Name: peserta fk_peserta_bus; Type: FK CONSTRAINT; Schema: public; Owner: admin_wisata
--

ALTER TABLE ONLY public.peserta
    ADD CONSTRAINT fk_peserta_bus FOREIGN KEY (id_bus) REFERENCES public.armada_bus(id);


--
-- PostgreSQL database dump complete
--

\unrestrict QdQoEmb85OKNJ99inITrpeoK9vnyJxRrMQ886lJI4L14WWFEGTmh58fyfZvdHHy

