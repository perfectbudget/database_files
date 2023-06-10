--
-- PostgreSQL database dump
--

-- Dumped from database version 13.1 (Debian 13.1-1.pgdg100+1)
-- Dumped by pg_dump version 15.0

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

ALTER TABLE IF EXISTS ONLY public."Wallet" DROP CONSTRAINT IF EXISTS "Wallet_user_uuid_fkey";
ALTER TABLE IF EXISTS ONLY public."Wallet" DROP CONSTRAINT IF EXISTS "Wallet_type_wallet_id_fkey";
ALTER TABLE IF EXISTS ONLY public."Transaction" DROP CONSTRAINT IF EXISTS "Transaction_wallet_id_fkey";
ALTER TABLE IF EXISTS ONLY public."Transaction" DROP CONSTRAINT IF EXISTS "Transaction_type_fkey";
ALTER TABLE IF EXISTS ONLY public."Transaction" DROP CONSTRAINT IF EXISTS "Transaction_contract_id_fkey";
ALTER TABLE IF EXISTS ONLY public."Transaction" DROP CONSTRAINT IF EXISTS "Transaction_category_id_fkey";
ALTER TABLE IF EXISTS ONLY public."TransactionGoal" DROP CONSTRAINT IF EXISTS "TransactionGoal_goal_id_fkey";
ALTER TABLE IF EXISTS ONLY public."TransactionContract" DROP CONSTRAINT IF EXISTS "TransactionContract_contract_id_fkey";
ALTER TABLE IF EXISTS ONLY public."Goal" DROP CONSTRAINT IF EXISTS "Goal_user_uuid_fkey";
ALTER TABLE IF EXISTS ONLY public."Goal" DROP CONSTRAINT IF EXISTS "Goal_category_id_fkey";
ALTER TABLE IF EXISTS ONLY public."Contract" DROP CONSTRAINT IF EXISTS "Contract_email_lender_fkey";
ALTER TABLE IF EXISTS ONLY public."Category" DROP CONSTRAINT IF EXISTS "Category_type_fkey";
ALTER TABLE IF EXISTS ONLY public."Category" DROP CONSTRAINT IF EXISTS "Category_parrent_id_fkey";
DROP TRIGGER IF EXISTS update_balance ON public."Transaction";
DROP TRIGGER IF EXISTS "set_public_Wallet_updated_at" ON public."Wallet";
DROP TRIGGER IF EXISTS "set_public_User_updated_at" ON public."User";
DROP TRIGGER IF EXISTS "set_public_TypeWallet_updated_at" ON public."TypeWallet";
DROP TRIGGER IF EXISTS "set_public_Transaction_updated_at" ON public."Transaction";
DROP TRIGGER IF EXISTS "set_public_TransactionGoal_updated_at" ON public."TransactionGoal";
DROP TRIGGER IF EXISTS "set_public_TransactionContract_updated_at" ON public."TransactionContract";
DROP TRIGGER IF EXISTS "set_public_Goal_updated_at" ON public."Goal";
DROP TRIGGER IF EXISTS "set_public_Currency_updated_at" ON public."Currency";
DROP TRIGGER IF EXISTS "set_public_Contract_updated_at" ON public."Contract";
DROP TRIGGER IF EXISTS "set_public_Category_updated_at" ON public."Category";
DROP TRIGGER IF EXISTS "notify_hasura_send_mail_invite_INSERT" ON public."Contract";
DROP TRIGGER IF EXISTS create_transaction_contract ON public."TransactionContract";
DROP TRIGGER IF EXISTS create_transaction ON public."Wallet";
DROP TRIGGER IF EXISTS create_accept_contract ON public."Contract";
DROP INDEX IF EXISTS public.idx_event_aggregate_id;
ALTER TABLE IF EXISTS ONLY public.event DROP CONSTRAINT IF EXISTS event_pkey;
ALTER TABLE IF EXISTS ONLY public.event DROP CONSTRAINT IF EXISTS event_aggregate_id_version_key;
ALTER TABLE IF EXISTS ONLY public."Wallet" DROP CONSTRAINT IF EXISTS "Wallet_pkey";
ALTER TABLE IF EXISTS ONLY public."User" DROP CONSTRAINT IF EXISTS "User_pkey";
ALTER TABLE IF EXISTS ONLY public."User" DROP CONSTRAINT IF EXISTS "User_email_key";
ALTER TABLE IF EXISTS ONLY public."TypeWallet" DROP CONSTRAINT IF EXISTS "TypeWallet_pkey";
ALTER TABLE IF EXISTS ONLY public."TypeTransaction" DROP CONSTRAINT IF EXISTS "TypeTransaction_pkey";
ALTER TABLE IF EXISTS ONLY public."Transaction" DROP CONSTRAINT IF EXISTS "Transaction_pkey";
ALTER TABLE IF EXISTS ONLY public."TransactionGoal" DROP CONSTRAINT IF EXISTS "TransactionGoal_pkey";
ALTER TABLE IF EXISTS ONLY public."TransactionContract" DROP CONSTRAINT IF EXISTS "TransactionContract_pkey";
ALTER TABLE IF EXISTS ONLY public."Goal" DROP CONSTRAINT IF EXISTS "Goal_pkey";
ALTER TABLE IF EXISTS ONLY public."Currency" DROP CONSTRAINT IF EXISTS "Currency_pkey";
ALTER TABLE IF EXISTS ONLY public."Contract" DROP CONSTRAINT IF EXISTS "Contract_pkey";
ALTER TABLE IF EXISTS ONLY public."Category" DROP CONSTRAINT IF EXISTS "Category_pkey";
ALTER TABLE IF EXISTS public."Wallet" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."User" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."TypeWallet" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."TransactionGoal" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."TransactionContract" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Transaction" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Goal" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Currency" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Contract" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Category" ALTER COLUMN id DROP DEFAULT;
DROP TABLE IF EXISTS public.event;
DROP SEQUENCE IF EXISTS public."Wallet_id_seq";
DROP TABLE IF EXISTS public."Wallet";
DROP SEQUENCE IF EXISTS public."User_id_seq";
DROP TABLE IF EXISTS public."User";
DROP SEQUENCE IF EXISTS public."TypeWallet_id_seq";
DROP TABLE IF EXISTS public."TypeWallet";
DROP TABLE IF EXISTS public."TypeTransaction";
DROP SEQUENCE IF EXISTS public."Transaction_id_seq";
DROP SEQUENCE IF EXISTS public."TransactionGoal_id_seq";
DROP TABLE IF EXISTS public."TransactionGoal";
DROP SEQUENCE IF EXISTS public."TransactionContract_id_seq";
DROP TABLE IF EXISTS public."TransactionContract";
DROP TABLE IF EXISTS public."Transaction";
DROP SEQUENCE IF EXISTS public."Goal_id_seq";
DROP TABLE IF EXISTS public."Goal";
DROP SEQUENCE IF EXISTS public."Currency_id_seq";
DROP TABLE IF EXISTS public."Currency";
DROP SEQUENCE IF EXISTS public."Contract_id_seq";
DROP TABLE IF EXISTS public."Contract";
DROP SEQUENCE IF EXISTS public."Category_id_seq";
DROP TABLE IF EXISTS public."Category";
DROP FUNCTION IF EXISTS public.update_balance_wallet();
DROP FUNCTION IF EXISTS public.set_current_timestamp_updated_at();
DROP FUNCTION IF EXISTS public.create_transaction_contract_accept();
DROP FUNCTION IF EXISTS public.create_first_transaction();
DROP FUNCTION IF EXISTS public.create_contract_accept();
DROP SCHEMA IF EXISTS public;
--
-- Name: public; Type: SCHEMA; Schema: -; Owner: "perfectbudget.app"
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO "perfectbudget.app";

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: "perfectbudget.app"
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: create_contract_accept(); Type: FUNCTION; Schema: public; Owner: "perfectbudget.app"
--

CREATE FUNCTION public.create_contract_accept() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    /* Declare variables */
    DECLARE uidLender text;
    DECLARE uidBorrower text;
    DECLARE walletIdLoan int;
    DECLARE walletIdBorrow int;

BEGIN
    IF NEW.status = 'Borrowing' THEN
        /* get uidLender*/
        SELECT uuid into uidLender
            FROM "User" t
            WHERE t."email" = NEW.email_lender;
        /* get uidBorrower*/
        SELECT uuid into uidBorrower
            FROM "User" t
            WHERE t."email" = NEW.email_borrower;
        /* get walletIdLoan*/
        SELECT id into walletIdLoan
            FROM "Wallet" t
            WHERE t."user_uuid" = uidLender AND t."is_loan_wallet" = true;
        /* nếu chưa có wallet loan thì tạo cho người cho vay*/
        IF walletIdLoan IS NULL THEN
        INSERT INTO public."Wallet" ("user_uuid","name","type_wallet_id","income_balance","expense_balance","is_loan_wallet")
            VALUES (uidLender,'Lend & Borrow Wallet',1,0,0,true);
        SELECT id into walletIdLoan
            FROM "Wallet" t
            WHERE t."user_uuid" = uidLender AND t."is_loan_wallet" = true;
        END IF;

        /* get walletIdBorrow*/
        SELECT id into walletIdBorrow
            FROM "Wallet" t
            WHERE t."user_uuid" = uidBorrower AND t."is_loan_wallet" = true;
        /* nếu chưa có wallet loan thì tạo cho người vay*/
        IF walletIdBorrow IS NULL THEN
        INSERT INTO public."Wallet" ("user_uuid","name","type_wallet_id","income_balance","expense_balance","is_loan_wallet")
            VALUES (uidBorrower,'Lend & Borrow Wallet',1,0,0,true);
        SELECT id into walletIdBorrow
            FROM "Wallet" t
            WHERE t."user_uuid" = uidBorrower AND t."is_loan_wallet" = true;
        END IF;

        /* tạo transaction trừ tiền người cho vay*/
        INSERT INTO public."Transaction" ("wallet_id","category_id","contract_id","balance","note","type")
            VALUES (walletIdLoan,42,NEW.id,NEW."money",'Lending money','expense');
        /* tạo transaction nhận tiền của người vay*/
        INSERT INTO public."Transaction" ("wallet_id","category_id","contract_id","balance","note","type")
            VALUES (walletIdBorrow,51,NEW.id,NEW."money",'Borrowing money','income');
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.create_contract_accept() OWNER TO "perfectbudget.app";

--
-- Name: create_first_transaction(); Type: FUNCTION; Schema: public; Owner: "perfectbudget.app"
--

CREATE FUNCTION public.create_first_transaction() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    INSERT INTO public."Transaction" ("wallet_id","category_id","balance","note","type") 
        VALUES (NEW.id,7,NEW.income_balance,'Create Wallet','income');
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.create_first_transaction() OWNER TO "perfectbudget.app";

--
-- Name: create_transaction_contract_accept(); Type: FUNCTION; Schema: public; Owner: "perfectbudget.app"
--

CREATE FUNCTION public.create_transaction_contract_accept() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    /* Declare variables */
    DECLARE contractId int;
    DECLARE emailLender text;
    DECLARE emailBorrower text;
    DECLARE uidLender text;
    DECLARE uidBorrower text;
    DECLARE walletIdLoan int;
    DECLARE walletIdBorrow int;

BEGIN

    /* get contract_id*/
    SELECT contract_id into contractId
        FROM "TransactionContract" t
        WHERE t."contract_id" = New.contract_id;
        /* get emailLender*/
    SELECT email_lender into emailLender
        FROM "Contract" t
        WHERE t."id" = contractId;
        /* get emailBorrower*/
    SELECT email_borrower into emailBorrower
        FROM "Contract" t
        WHERE t."id" = contractId;
         /* get uidLender*/
    SELECT uuid into uidLender
        FROM "User" t
        WHERE t."email" = emailLender;
        /* get uidBorrower*/
    SELECT uuid into uidBorrower
        FROM "User" t
        WHERE t."email" = emailBorrower;
      /* get walletIdLoan*/
    SELECT id into walletIdLoan
        FROM "Wallet" t
        WHERE t."user_uuid" = uidLender AND t."is_loan_wallet" = true;
         /* get walletIdBorrow*/
    SELECT id into walletIdBorrow
        FROM "Wallet" t
        WHERE t."user_uuid" = uidBorrower AND t."is_loan_wallet" = true;
    /* tạo transaction trả tiền cho người vay*/
    INSERT INTO public."Transaction" ("wallet_id","category_id","contract_id","balance","note","type")
        VALUES (walletIdBorrow,42,NEW.contract_id,NEW.money_paid,NEW.note,'expense');
    /* tạo transaction nhận tiền cho người cho vay*/
    INSERT INTO public."Transaction" ("wallet_id","category_id","contract_id","balance","note","type")
        VALUES (walletIdLoan,51,NEW.contract_id,NEW.money_paid,NEW.note,'income');
    DELETE FROM "TransactionContract" t WHERE t."id" = NEW.id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.create_transaction_contract_accept() OWNER TO "perfectbudget.app";

--
-- Name: set_current_timestamp_updated_at(); Type: FUNCTION; Schema: public; Owner: "perfectbudget.app"
--

CREATE FUNCTION public.set_current_timestamp_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _new record;
BEGIN
  _new := NEW;
  _new."updated_at" = NOW();
  RETURN _new;
END;
$$;


ALTER FUNCTION public.set_current_timestamp_updated_at() OWNER TO "perfectbudget.app";

--
-- Name: update_balance_wallet(); Type: FUNCTION; Schema: public; Owner: "perfectbudget.app"
--

CREATE FUNCTION public.update_balance_wallet() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    /* Declare variables */
    DECLARE totalIncome double precision;
    DECLARE totalExpense double precision;
    DECLARE totalTransactionIncome int;
    DECLARE totalTransactionExpense int;

    BEGIN
    /* Handle INSERT */
    IF (TG_OP = 'INSERT' AND New."balance" != 0) THEN
    
        -- totalIncome := 0;
    
        -- SELECT COUNT (*) into totalTransactionIncome
        -- FROM "Transaction" t
        -- WHERE t."wallet_id" = New."wallet_id" AND t."type" = 'income';
        
        -- IF(totalTransactionExpense > 0) THEN
        --     SELECT SUM (t."balance") into totalIncome
        --     FROM "Transaction" t
        --     WHERE t."wallet_id" = New."wallet_id" AND t."type" = 'income';
        -- END IF;
        SELECT SUM (t."balance") into totalIncome
        FROM "Transaction" t
        WHERE t."wallet_id" = New."wallet_id" AND t."type" = 'income';
        
        totalExpense := 0;
        
        SELECT COUNT (*) into totalTransactionExpense
        FROM "Transaction" t
        WHERE t."wallet_id" = New."wallet_id" AND t."type" = 'expense';
        
        IF(totalTransactionExpense > 0) THEN
            SELECT SUM (t."balance") into totalExpense
            FROM "Transaction" t
            WHERE t."wallet_id" = New."wallet_id" AND t."type" = 'expense';
        END IF;

        /* Update balance Wallet */
        UPDATE "Wallet"
        SET (income_balance, expense_balance) = (totalIncome, totalExpense)
        WHERE id = New."wallet_id";
    END IF;
    /* End Handle INSERT */

    /* Handle DELETE */
    IF (TG_OP = 'DELETE' AND OLD."balance" != 0) THEN
        totalIncome := 0;
        totalExpense := 0;
        
        SELECT COUNT (*) into totalTransactionExpense
        FROM "Transaction" t
        WHERE t."wallet_id" = OLD."wallet_id" AND t."type" = 'expense';
        
        IF(totalTransactionExpense > 0) THEN
            SELECT SUM (t."balance") into totalExpense
            FROM "Transaction" t
            WHERE t."wallet_id" = OLD."wallet_id" AND t."type" = 'expense';
        END IF;
        
        SELECT COUNT (*) into totalTransactionIncome
        FROM "Transaction" t
        WHERE t."wallet_id" = OLD."wallet_id" AND t."type" = 'income';
        
        IF(totalTransactionIncome > 0) THEN
            SELECT SUM (t.balance) INTO totalIncome
            FROM "Transaction" t
            WHERE t.wallet_id = OLD."wallet_id" AND t."type" = 'income';
        END IF;

        /* Update balance Wallet */
        UPDATE "Wallet"
        SET (income_balance, expense_balance) = (totalIncome, totalExpense)
        WHERE id = OLD."wallet_id";
    END IF;
    /* End Handle DELETE */

    /* Handle UPDATE */
    IF (TG_OP = 'UPDATE') THEN
        /* Update new wallet */
        
        totalIncome := 0;
        totalExpense := 0;
        
        SELECT COUNT (*) into totalTransactionExpense
        FROM "Transaction" t
        WHERE t."wallet_id" = New."wallet_id" AND t."type" = 'expense';
        
        IF(totalTransactionExpense > 0) THEN
            SELECT SUM (t."balance") into totalExpense
            FROM "Transaction" t
            WHERE t."wallet_id" = New."wallet_id" AND t."type" = 'expense';
        END IF;
        
        SELECT COUNT (*) into totalTransactionIncome
        FROM "Transaction" t
        WHERE t."wallet_id" = New."wallet_id" AND t."type" = 'income';
        
        IF(totalTransactionIncome > 0) THEN
            SELECT SUM (t.balance) INTO totalIncome
            FROM "Transaction" t
            WHERE t.wallet_id = NEW."wallet_id" AND t."type" = 'income';
        END IF;
        
        /* Update balance Wallet */
        UPDATE "Wallet"
        SET (income_balance, expense_balance) = (totalIncome, totalExpense)
        WHERE id = NEW."wallet_id";

        IF (OLD."wallet_id" != NEW."wallet_id") THEN
            totalIncome := 0;
            totalExpense := 0;
            
            SELECT COUNT (*) into totalTransactionExpense
            FROM "Transaction" t
            WHERE t."wallet_id" = OLD."wallet_id" AND t."type" = 'expense';
            
            IF(totalTransactionExpense > 0) THEN
                SELECT SUM (t."balance") into totalExpense
                FROM "Transaction" t
                WHERE t."wallet_id" = OLD."wallet_id" AND t."type" = 'expense';
            END IF;
            
            SELECT COUNT (*) into totalTransactionIncome
            FROM "Transaction" t
            WHERE t."wallet_id" = OLD."wallet_id" AND t."type" = 'income';
            
            IF(totalTransactionIncome > 0) THEN
                SELECT SUM (t.balance) INTO totalIncome
                FROM "Transaction" t
                WHERE t.wallet_id = OLD."wallet_id" AND t."type" = 'income';
            END IF;

            /* Update balance Wallet */
            UPDATE "Wallet"
            SET (income_balance, expense_balance) = (totalIncome, totalExpense)
            WHERE id = OLD."wallet_id";
        END IF;
    END IF;
    /* End Handle UPDATE */

    RETURN NULL;
    END;
    $$;


ALTER FUNCTION public.update_balance_wallet() OWNER TO "perfectbudget.app";

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Category; Type: TABLE; Schema: public; Owner: "perfectbudget.app"
--

CREATE TABLE public."Category" (
    id integer NOT NULL,
    name text NOT NULL,
    icon text NOT NULL,
    type text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    parrent_id integer,
    is_default boolean DEFAULT false NOT NULL
);


ALTER TABLE public."Category" OWNER TO "perfectbudget.app";

--
-- Name: Category_id_seq; Type: SEQUENCE; Schema: public; Owner: "perfectbudget.app"
--

CREATE SEQUENCE public."Category_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Category_id_seq" OWNER TO "perfectbudget.app";

--
-- Name: Category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: "perfectbudget.app"
--

ALTER SEQUENCE public."Category_id_seq" OWNED BY public."Category".id;


--
-- Name: Contract; Type: TABLE; Schema: public; Owner: "perfectbudget.app"
--

CREATE TABLE public."Contract" (
    id integer NOT NULL,
    email_lender text NOT NULL,
    email_borrower text NOT NULL,
    money integer NOT NULL,
    interest_rate double precision NOT NULL,
    real_money_to_pay integer NOT NULL,
    is_send_mail boolean NOT NULL,
    is_send_notify boolean NOT NULL,
    status text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    avatar_borrower text NOT NULL,
    name_contract text NOT NULL,
    avatar_lender text
);


ALTER TABLE public."Contract" OWNER TO "perfectbudget.app";

--
-- Name: Contract_id_seq; Type: SEQUENCE; Schema: public; Owner: "perfectbudget.app"
--

CREATE SEQUENCE public."Contract_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Contract_id_seq" OWNER TO "perfectbudget.app";

--
-- Name: Contract_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: "perfectbudget.app"
--

ALTER SEQUENCE public."Contract_id_seq" OWNED BY public."Contract".id;


--
-- Name: Currency; Type: TABLE; Schema: public; Owner: "perfectbudget.app"
--

CREATE TABLE public."Currency" (
    id integer NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    code text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public."Currency" OWNER TO "perfectbudget.app";

--
-- Name: Currency_id_seq; Type: SEQUENCE; Schema: public; Owner: "perfectbudget.app"
--

CREATE SEQUENCE public."Currency_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Currency_id_seq" OWNER TO "perfectbudget.app";

--
-- Name: Currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: "perfectbudget.app"
--

ALTER SEQUENCE public."Currency_id_seq" OWNED BY public."Currency".id;


--
-- Name: Goal; Type: TABLE; Schema: public; Owner: "perfectbudget.app"
--

CREATE TABLE public."Goal" (
    id integer NOT NULL,
    name text NOT NULL,
    days integer NOT NULL,
    time_start timestamp without time zone NOT NULL,
    time_end timestamp without time zone NOT NULL,
    money_saving double precision NOT NULL,
    money_goal double precision NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_uuid text NOT NULL,
    category_id integer NOT NULL
);


ALTER TABLE public."Goal" OWNER TO "perfectbudget.app";

--
-- Name: Goal_id_seq; Type: SEQUENCE; Schema: public; Owner: "perfectbudget.app"
--

CREATE SEQUENCE public."Goal_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Goal_id_seq" OWNER TO "perfectbudget.app";

--
-- Name: Goal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: "perfectbudget.app"
--

ALTER SEQUENCE public."Goal_id_seq" OWNED BY public."Goal".id;


--
-- Name: Transaction; Type: TABLE; Schema: public; Owner: "perfectbudget.app"
--

CREATE TABLE public."Transaction" (
    id integer NOT NULL,
    wallet_id integer NOT NULL,
    category_id integer NOT NULL,
    balance double precision NOT NULL,
    date timestamp without time zone DEFAULT now(),
    note text,
    type text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    photo_url text,
    contract_id integer
);


ALTER TABLE public."Transaction" OWNER TO "perfectbudget.app";

--
-- Name: TransactionContract; Type: TABLE; Schema: public; Owner: "perfectbudget.app"
--

CREATE TABLE public."TransactionContract" (
    id integer NOT NULL,
    contract_id integer NOT NULL,
    money_paid integer NOT NULL,
    pay_date timestamp without time zone NOT NULL,
    note text NOT NULL,
    status text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public."TransactionContract" OWNER TO "perfectbudget.app";

--
-- Name: TransactionContract_id_seq; Type: SEQUENCE; Schema: public; Owner: "perfectbudget.app"
--

CREATE SEQUENCE public."TransactionContract_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."TransactionContract_id_seq" OWNER TO "perfectbudget.app";

--
-- Name: TransactionContract_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: "perfectbudget.app"
--

ALTER SEQUENCE public."TransactionContract_id_seq" OWNED BY public."TransactionContract".id;


--
-- Name: TransactionGoal; Type: TABLE; Schema: public; Owner: "perfectbudget.app"
--

CREATE TABLE public."TransactionGoal" (
    id integer NOT NULL,
    balance double precision NOT NULL,
    date timestamp without time zone DEFAULT now() NOT NULL,
    note text DEFAULT 'Add money'::text NOT NULL,
    goal_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public."TransactionGoal" OWNER TO "perfectbudget.app";

--
-- Name: TransactionGoal_id_seq; Type: SEQUENCE; Schema: public; Owner: "perfectbudget.app"
--

CREATE SEQUENCE public."TransactionGoal_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."TransactionGoal_id_seq" OWNER TO "perfectbudget.app";

--
-- Name: TransactionGoal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: "perfectbudget.app"
--

ALTER SEQUENCE public."TransactionGoal_id_seq" OWNED BY public."TransactionGoal".id;


--
-- Name: Transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: "perfectbudget.app"
--

CREATE SEQUENCE public."Transaction_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Transaction_id_seq" OWNER TO "perfectbudget.app";

--
-- Name: Transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: "perfectbudget.app"
--

ALTER SEQUENCE public."Transaction_id_seq" OWNED BY public."Transaction".id;


--
-- Name: TypeTransaction; Type: TABLE; Schema: public; Owner: "perfectbudget.app"
--

CREATE TABLE public."TypeTransaction" (
    name_type text NOT NULL
);


ALTER TABLE public."TypeTransaction" OWNER TO "perfectbudget.app";

--
-- Name: TypeWallet; Type: TABLE; Schema: public; Owner: "perfectbudget.app"
--

CREATE TABLE public."TypeWallet" (
    id integer NOT NULL,
    name text NOT NULL,
    icon text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public."TypeWallet" OWNER TO "perfectbudget.app";

--
-- Name: TypeWallet_id_seq; Type: SEQUENCE; Schema: public; Owner: "perfectbudget.app"
--

CREATE SEQUENCE public."TypeWallet_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."TypeWallet_id_seq" OWNER TO "perfectbudget.app";

--
-- Name: TypeWallet_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: "perfectbudget.app"
--

ALTER SEQUENCE public."TypeWallet_id_seq" OWNED BY public."TypeWallet".id;


--
-- Name: User; Type: TABLE; Schema: public; Owner: "perfectbudget.app"
--

CREATE TABLE public."User" (
    id integer NOT NULL,
    uuid text NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    avatar text,
    currency_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    currency_symbol text,
    date_premium timestamp without time zone,
    language text DEFAULT 'en'::text NOT NULL
);


ALTER TABLE public."User" OWNER TO "perfectbudget.app";

--
-- Name: User_id_seq; Type: SEQUENCE; Schema: public; Owner: "perfectbudget.app"
--

CREATE SEQUENCE public."User_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."User_id_seq" OWNER TO "perfectbudget.app";

--
-- Name: User_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: "perfectbudget.app"
--

ALTER SEQUENCE public."User_id_seq" OWNED BY public."User".id;


--
-- Name: Wallet; Type: TABLE; Schema: public; Owner: "perfectbudget.app"
--

CREATE TABLE public."Wallet" (
    id integer NOT NULL,
    user_uuid text NOT NULL,
    name text NOT NULL,
    type_wallet_id integer NOT NULL,
    income_balance double precision NOT NULL,
    expense_balance double precision NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_loan_wallet boolean DEFAULT false NOT NULL
);


ALTER TABLE public."Wallet" OWNER TO "perfectbudget.app";

--
-- Name: Wallet_id_seq; Type: SEQUENCE; Schema: public; Owner: "perfectbudget.app"
--

CREATE SEQUENCE public."Wallet_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Wallet_id_seq" OWNER TO "perfectbudget.app";

--
-- Name: Wallet_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: "perfectbudget.app"
--

ALTER SEQUENCE public."Wallet_id_seq" OWNED BY public."Wallet".id;


--
-- Name: event; Type: TABLE; Schema: public; Owner: "perfectbudget.app"
--

CREATE TABLE public.event (
    id character(26) NOT NULL,
    aggregate_id character(26) NOT NULL,
    event_data json NOT NULL,
    version integer,
    CONSTRAINT event_aggregate_id_check CHECK ((char_length(aggregate_id) = 26)),
    CONSTRAINT event_id_check CHECK ((char_length(id) = 26))
);


ALTER TABLE public.event OWNER TO "perfectbudget.app";

--
-- Name: Category id; Type: DEFAULT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Category" ALTER COLUMN id SET DEFAULT nextval('public."Category_id_seq"'::regclass);


--
-- Name: Contract id; Type: DEFAULT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Contract" ALTER COLUMN id SET DEFAULT nextval('public."Contract_id_seq"'::regclass);


--
-- Name: Currency id; Type: DEFAULT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Currency" ALTER COLUMN id SET DEFAULT nextval('public."Currency_id_seq"'::regclass);


--
-- Name: Goal id; Type: DEFAULT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Goal" ALTER COLUMN id SET DEFAULT nextval('public."Goal_id_seq"'::regclass);


--
-- Name: Transaction id; Type: DEFAULT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Transaction" ALTER COLUMN id SET DEFAULT nextval('public."Transaction_id_seq"'::regclass);


--
-- Name: TransactionContract id; Type: DEFAULT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."TransactionContract" ALTER COLUMN id SET DEFAULT nextval('public."TransactionContract_id_seq"'::regclass);


--
-- Name: TransactionGoal id; Type: DEFAULT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."TransactionGoal" ALTER COLUMN id SET DEFAULT nextval('public."TransactionGoal_id_seq"'::regclass);


--
-- Name: TypeWallet id; Type: DEFAULT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."TypeWallet" ALTER COLUMN id SET DEFAULT nextval('public."TypeWallet_id_seq"'::regclass);


--
-- Name: User id; Type: DEFAULT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."User" ALTER COLUMN id SET DEFAULT nextval('public."User_id_seq"'::regclass);


--
-- Name: Wallet id; Type: DEFAULT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Wallet" ALTER COLUMN id SET DEFAULT nextval('public."Wallet_id_seq"'::regclass);


--
-- Data for Name: Category; Type: TABLE DATA; Schema: public; Owner: "perfectbudget.app"
--

INSERT INTO public."Category" VALUES
	(1, 'Comidas y Bebidas', 'https://user-images.githubusercontent.com/79369571/209181024-f8720252-1e99-4565-a242-c420719e6e0d.png', 'expense', '2022-07-27 08:42:38.883437+00', '2022-12-22 16:39:58.617592+00', NULL, false),
	(2, 'Compras', 'https://user-images.githubusercontent.com/79369571/209185658-2b1b88aa-095d-4c14-a3df-dbd4e398cae8.png', 'expense', '2022-07-27 08:43:27.951529+00', '2022-12-22 16:51:02.8307+00', NULL, false),
	(4, 'Transporte', 'https://user-images.githubusercontent.com/79369571/209186107-c884e5b4-625a-4fc4-95d3-9ae114921ab7.png', 'expense', '2022-07-27 08:47:52.914478+00', '2022-12-22 16:52:56.139824+00', NULL, false),
	(5, 'Entretenimiento', 'https://user-images.githubusercontent.com/79369571/209186232-575f786b-2651-467d-8c7c-e95eae97710d.png', 'expense', '2022-07-27 08:48:28.815492+00', '2022-12-22 16:53:45.8708+00', NULL, false),
	(6, 'Gastos Financieros', 'https://user-images.githubusercontent.com/79369571/209186359-9698fddf-1e56-4df9-a1f3-fa0dcdee65b2.png', 'expense', '2022-07-27 08:48:56.59007+00', '2022-12-22 16:54:29.704843+00', NULL, false),
	(8, 'Supermercado', 'https://user-images.githubusercontent.com/79369571/209186714-609732bc-be04-4850-bcfa-f1059d25cd27.png', 'expense', '2022-07-27 08:50:23.783451+00', '2022-12-22 16:56:51.334388+00', 1, false),
	(9, 'Restaurante', 'https://user-images.githubusercontent.com/79369571/209186927-ef0be107-4d90-4709-88f9-c87e71078724.png', 'expense', '2022-07-27 08:51:08.888009+00', '2022-12-22 16:57:48.008898+00', 1, false),
	(10, 'Bar, cafe', 'https://user-images.githubusercontent.com/79369571/209187107-1316c6d8-0738-431e-bb5a-a26e5872cc1b.png', 'expense', '2022-07-27 08:51:39.216291+00', '2022-12-22 16:58:38.157142+00', 1, false),
	(11, 'Ropa', 'https://user-images.githubusercontent.com/79369571/209187318-d59894fc-f099-4b11-9a76-c35c90c3beb5.png', 'expense', '2022-07-27 08:51:56.96187+00', '2022-12-22 16:59:46.062947+00', 2, false),
	(12, 'Cuidado de la Piel', 'https://user-images.githubusercontent.com/79369571/209187407-b5408134-fc82-4960-9e6c-fcb8f8905e75.png', 'expense', '2022-07-27 08:51:57.479477+00', '2022-12-22 17:00:37.580315+00', 2, false),
	(13, 'Hijos', 'https://user-images.githubusercontent.com/79369571/209187583-6f4980eb-74d3-4383-bd13-f155c2cf736e.png', 'expense', '2022-07-27 08:51:57.215559+00', '2022-12-22 17:01:15.757274+00', 2, false),
	(14, 'Mascotas', 'https://user-images.githubusercontent.com/79369571/209187694-6900f850-8346-4700-be59-3792a8509640.png', 'expense', '2022-07-27 08:55:23.541327+00', '2022-12-22 17:02:07.582812+00', 2, false),
	(15, 'Gastos del Hogar', 'https://user-images.githubusercontent.com/79369571/209187880-9850a3b2-de6d-4429-a5f0-91c8222dc6f4.png', 'expense', '2022-07-27 08:56:18.332206+00', '2022-12-22 17:02:51.376135+00', 2, false),
	(16, 'Electrodomesticos', 'https://user-images.githubusercontent.com/79369571/209187969-0412439b-7038-4ffe-a925-338e79b71417.png', 'expense', '2022-07-27 08:57:07.042655+00', '2022-12-22 17:03:42.100992+00', 2, false),
	(17, 'Regalos', 'https://user-images.githubusercontent.com/79369571/209188135-5b330137-6f67-4859-8320-df14acda3262.png', 'expense', '2022-07-27 08:57:23.378515+00', '2022-12-22 17:04:22.729287+00', 2, false),
	(18, 'Medicamentos', 'https://user-images.githubusercontent.com/79369571/209188261-6e5f08a6-39e5-48b9-9ff7-e52fd963fc77.png', 'expense', '2022-07-27 08:57:39.282001+00', '2022-12-22 17:04:59.00421+00', 2, false),
	(19, 'Renta', 'https://user-images.githubusercontent.com/79369571/209188371-80f31d48-7972-489a-b56d-fae442f8c910.png', 'expense', '2022-07-27 08:58:23.265155+00', '2022-12-22 17:05:39.339629+00', 3, false),
	(20, 'Hipoteca', 'https://user-images.githubusercontent.com/79369571/209188261-6e5f08a6-39e5-48b9-9ff7-e52fd963fc77.png', 'expense', '2022-07-27 08:59:29.631503+00', '2022-12-22 17:06:43.309905+00', 3, false),
	(21, 'Energía', 'https://user-images.githubusercontent.com/79369571/209188668-71b9b09f-9c52-4f91-a03c-de0370e883e3.png', 'expense', '2022-07-27 09:00:07.434131+00', '2022-12-22 17:07:30.224549+00', 3, false),
	(22, 'Servicios', 'https://user-images.githubusercontent.com/79369571/209188829-8ed21134-358d-4eeb-a01d-415d50554e2b.png', 'expense', '2022-07-27 09:01:46.653443+00', '2022-12-22 17:08:24.884262+00', 3, false),
	(23, 'Mantenimiento', 'https://user-images.githubusercontent.com/79369571/209188913-e69c9297-33f0-4a62-819b-32521c090afc.png', 'expense', '2022-07-27 09:02:17.995056+00', '2022-12-22 17:10:03.632201+00', 3, false),
	(24, 'Transporte Publico', 'https://user-images.githubusercontent.com/79369571/209189192-f24ef7a8-8517-4097-8a35-923a7ce6c07e.png', 'expense', '2022-07-27 09:02:36.676591+00', '2022-12-22 17:10:36.670326+00', 4, false),
	(25, 'Taxi', 'https://user-images.githubusercontent.com/79369571/209189300-c21c24c8-c532-43b9-b5aa-c6a6f8709c7a.png', 'expense', '2022-07-27 09:02:51.590288+00', '2022-12-22 17:11:14.224581+00', 4, false),
	(26, 'Largas Distancias', 'https://user-images.githubusercontent.com/79369571/209189409-35e0f3a0-3e25-43de-83ee-525a298684ab.png', 'expense', '2022-07-27 09:05:11.417716+00', '2022-12-22 17:11:51.329593+00', 4, false),
	(27, 'Gasolina', 'https://user-images.githubusercontent.com/79369571/209189525-b4a02507-8c0f-4929-9247-5d32184d6829.png', 'expense', '2022-07-27 09:05:43.40648+00', '2022-12-22 17:12:35.446127+00', 4, false),
	(28, 'Parqueo', 'https://user-images.githubusercontent.com/79369571/209189617-09182441-c202-4294-8bf4-6d77e2d9dcac.png', 'expense', '2022-07-27 09:06:08.817457+00', '2022-12-22 17:13:15.444722+00', 4, false),
	(29, 'Mantenimiento de Vehículo', 'https://user-images.githubusercontent.com/79369571/209189712-227d7c56-9070-49e5-b789-14969bcdaf99.png', 'expense', '2022-07-27 09:06:25.471821+00', '2022-12-22 17:13:55.353254+00', 4, false),
	(30, 'Cuidado de Salud, Consultas', 'https://user-images.githubusercontent.com/79369571/209189810-d27ad51f-9c72-40ae-9f60-f51c43bd5f3d.png', 'expense', '2022-07-27 09:07:17.123653+00', '2022-12-22 17:14:38.741892+00', 5, false),
	(31, 'Belleza', 'https://user-images.githubusercontent.com/79369571/209189905-b3466e30-05ed-4634-b073-8993befe40db.png', 'expense', '2022-07-27 09:07:35.335996+00', '2022-12-22 17:15:10.028639+00', 5, false),
	(32, 'Fitness', 'https://user-images.githubusercontent.com/79369571/209189992-8c272a72-2460-4c67-b7e1-f144c15e0fd5.png', 'expense', '2022-07-27 09:08:41.791977+00', '2022-12-22 17:15:42.279022+00', 5, false),
	(33, 'Eventos Diarios', 'https://user-images.githubusercontent.com/79369571/209190075-20cff08a-adf8-4ddd-bbcf-4fa5ee0aed3d.png', 'expense', '2022-07-27 09:09:31.135124+00', '2022-12-22 17:16:16.223615+00', 5, false),
	(34, 'Hobbies', 'https://user-images.githubusercontent.com/79369571/209190172-8416542e-3b38-42c7-992a-645909ac864b.png', 'expense', '2022-07-27 09:09:58.105922+00', '2022-12-22 17:16:50.643574+00', 5, false),
	(35, 'Educación', 'https://user-images.githubusercontent.com/79369571/209190240-f1cdaa0a-63d5-469e-94d7-6584d33fbba3.png', 'expense', '2022-07-27 09:10:28.703353+00', '2022-12-22 17:17:22.98215+00', 5, false),
	(37, 'Vacaciones, trips, hotel', 'https://user-images.githubusercontent.com/79369571/209190417-ff717de4-8151-4581-a750-88fe9064ac3c.png', 'expense', '2022-07-27 09:14:02.911697+00', '2022-12-22 17:18:31.218937+00', 5, false),
	(38, 'Donaciones, regalos', 'https://user-images.githubusercontent.com/79369571/209190515-53e6b3d4-ec51-4e31-91e6-1ab6f143d2aa.png', 'expense', '2022-07-27 09:14:20.487367+00', '2022-12-22 17:19:03.57441+00', 5, false),
	(39, 'Lotería, apuestas', 'https://user-images.githubusercontent.com/79369571/209190608-cabf81b0-1682-4ec4-9d09-60e19828eb09.png', 'expense', '2022-07-27 09:14:34.04989+00', '2022-12-22 17:19:34.710924+00', 5, false),
	(40, 'Impuestos', 'https://user-images.githubusercontent.com/79369571/209190664-d4a6e8ed-1a9f-4db0-9a58-5d8edec1e5c2.png', 'expense', '2022-07-27 09:14:49.230579+00', '2022-12-22 17:20:10.096519+00', 6, false),
	(41, 'Seguros', 'https://user-images.githubusercontent.com/79369571/209190767-399aff6b-cf16-41ba-ac99-e4e3f6406f67.png', 'expense', '2022-07-27 09:15:01.916172+00', '2022-12-22 17:20:44.221643+00', 6, false),
	(42, 'Préstamos', 'https://user-images.githubusercontent.com/79369571/209190857-bf3cc7ed-2369-4570-8006-ea5772bc9785.png', 'expense', '2022-07-27 09:15:18.820369+00', '2022-12-22 17:21:17.729133+00', 6, false),
	(43, 'Multas', 'https://user-images.githubusercontent.com/79369571/209190943-04927fa8-eebf-4f5b-87f4-618bb8de5026.png', 'expense', '2022-07-27 09:15:34.996006+00', '2022-12-22 17:21:49.24565+00', 6, false),
	(44, 'Cargos', 'https://user-images.githubusercontent.com/79369571/209191033-95a833b9-3e91-46db-a53d-d3b5c2847e03.png', 'expense', '2022-07-27 09:15:47.499589+00', '2022-12-22 17:22:20.006644+00', 6, false),
	(46, 'Salario, ingresos', 'https://user-images.githubusercontent.com/79369571/209191151-b8bee117-7fd6-46da-b5b8-0ec1c459af10.png', 'income', '2022-07-27 09:18:51.143753+00', '2022-12-22 17:23:00.228758+00', 7, false),
	(3, 'Gastos de Hogar', 'https://user-images.githubusercontent.com/79369571/209185939-25577674-f2da-435a-a954-36ffb43fc281.png', 'expense', '2022-07-27 08:46:50.067523+00', '2022-12-22 16:52:10.402003+00', NULL, false),
	(7, 'Otros Ingresos', 'https://user-images.githubusercontent.com/79369571/209186481-5737eced-3f3d-456a-86c8-8596326749f4.png', 'income', '2022-07-27 08:49:43.1355+00', '2022-12-22 16:55:23.35234+00', NULL, true),
	(36, 'Suscripciones', 'https://user-images.githubusercontent.com/79369571/209190332-bce4c6ad-22b1-4314-9638-9da4f666d94e.png', 'expense', '2022-07-27 09:13:45.79709+00', '2022-12-22 17:17:57.060944+00', 5, false),
	(47, 'Ventas', 'https://user-images.githubusercontent.com/79369571/209191250-c4bbfb6f-ab5d-465f-a477-d88c4b38f61e.png', 'income', '2022-07-27 09:19:21.206489+00', '2022-12-22 17:23:43.974215+00', 7, false),
	(48, 'Renta de Casas', 'https://user-images.githubusercontent.com/79369571/209191345-3202acbe-65c2-4790-842c-760f063634c9.png', 'income', '2022-07-27 09:19:41.986098+00', '2022-12-22 17:24:15.056646+00', 7, false),
	(49, 'Cheques', 'https://user-images.githubusercontent.com/79369571/209191437-6c833522-7959-44af-9dee-665c152b07ce.png', 'income', '2022-07-27 09:19:56.840396+00', '2022-12-22 17:24:48.371757+00', 7, false),
	(50, 'Lotería, apuestas', 'https://user-images.githubusercontent.com/79369571/209191517-621199d4-9c84-413e-babc-d328d4718b0a.png', 'income', '2022-07-27 09:20:07.668686+00', '2022-12-22 17:25:18.461499+00', 7, false),
	(51, 'Reembolsos', 'https://user-images.githubusercontent.com/79369571/209191611-eaacd4bc-5550-4fcf-a935-c550ff07aa96.png', 'income', '2022-07-27 09:20:34.13342+00', '2022-12-22 17:26:04.950404+00', 7, false),
	(65, 'Gastos', 'https://user-images.githubusercontent.com/79369571/203107837-b07642ef-532f-42be-90a5-a338016ca9ca.png', 'expense', '2022-11-26 16:28:37.929503+00', '2022-11-27 16:23:20.110371+00', NULL, true);


--
-- Data for Name: Contract; Type: TABLE DATA; Schema: public; Owner: "perfectbudget.app"
--

INSERT INTO public."Contract" VALUES
	(69, 'anhdung2881999@gmail.com', 'minhltn1999@gmail.com', 100, 0, 100, true, true, 'Waiting', '2022-11-27 15:57:46.411614+00', '2022-11-27 15:57:46.411614+00', 'https://user-images.githubusercontent.com/79369571/182101394-89e63593-11a1-4aed-8ec5-9638d9c62a81.png', 'vay', 'https://lh3.googleusercontent.com/a/AItbvmmr-jJ0-3J7dtexKzXuMOU_fpluU7M56dcuECqp=s96-c'),
	(70, 'anhdung2881999@gmail.com', 'tiepnk971989@gmail.com', 100, 0, 100, true, true, 'Waiting', '2022-11-28 01:10:30.985865+00', '2022-11-28 01:10:30.985865+00', 'https://user-images.githubusercontent.com/79369571/182101394-89e63593-11a1-4aed-8ec5-9638d9c62a81.png', 'Cho em vay 100$ nhá', 'https://lh3.googleusercontent.com/a/AItbvmmr-jJ0-3J7dtexKzXuMOU_fpluU7M56dcuECqp=s96-c'),
	(71, 'jordan.decot@datblock.io', 'jordan.decot@gmail.com', 8000000, 0.9, 8072000, false, false, 'Waiting', '2022-11-30 20:51:20.403325+00', '2022-11-30 20:51:20.403325+00', 'https://user-images.githubusercontent.com/79369571/182101394-89e63593-11a1-4aed-8ec5-9638d9c62a81.png', 'llubk', 'https://lh3.googleusercontent.com/a/ALm5wu2Fr1fXXR7GX_pMVpLJhi4SBWLArds9Q-sh4RQE=s96-c'),
	(55, 'mamta.viruna@gmail.com', 'ashok.viruna@gmail.com', 5000, 12, 5600, true, false, 'Waiting', '2022-10-16 13:29:24.275676+00', '2022-11-23 15:08:42.554171+00', 'https://lh3.googleusercontent.com/a/ALm5wu39E6CEyVHTvLkeY8bYKhvsQK7eYRbI7QnFkDNlHQ=s96-c', 'ashok', 'https://lh3.googleusercontent.com/a/ALm5wu2aI3tNCLa6xHc07yj41FrooKH3L5hN2h1V0R6_YQ=s96-c'),
	(72, 'hachalu8908@gmail.com', 'wobihache8908@gmail.com', 1000, 10, 1100, true, true, 'Waiting', '2022-12-17 14:08:34.914795+00', '2022-12-17 14:08:34.914795+00', 'https://user-images.githubusercontent.com/79369571/182101394-89e63593-11a1-4aed-8ec5-9638d9c62a81.png', 'wobi', 'https://lh3.googleusercontent.com/a/AEdFTp7rpMmQwe6uyib21v0JjbGBhwB7sz9zBrqIcFMB=s96-c'),
	(59, 'mincho2881989@gmail.com', 'hoangbach1502@gmail.com', 22000000, 0, 22000000, true, true, 'Borrowing', '2022-11-25 14:26:05.546733+00', '2022-11-25 14:27:00.095612+00', 'https://lh3.googleusercontent.com/a-/ACNPEu9qHDpjEYrgHzXaGrKruoqCn_18E27hPRGr59tQGg=s96-c', 'Hoàng bk', NULL);


--
-- Data for Name: Currency; Type: TABLE DATA; Schema: public; Owner: "perfectbudget.app"
--



--
-- Data for Name: TransactionContract; Type: TABLE DATA; Schema: public; Owner: "perfectbudget.app"
--



--
-- Data for Name: TypeTransaction; Type: TABLE DATA; Schema: public; Owner: "perfectbudget.app"
--

INSERT INTO public."TypeTransaction" VALUES
	('income'),
	('expense');


--
-- Data for Name: TypeWallet; Type: TABLE DATA; Schema: public; Owner: "perfectbudget.app"
--

INSERT INTO public."TypeWallet" VALUES
	(1, 'Cuenta Banco', 'https://user-images.githubusercontent.com/79369571/181429324-a3770979-05ed-4dbc-8d1e-acaae2dec950.png', '2022-07-28 05:43:06.153658+00', '2022-07-28 05:43:06.153658+00'),
	(2, 'Efectivo', 'https://user-images.githubusercontent.com/79369571/181429333-194871c1-c007-4f64-8ff2-827c251b2cc4.png', '2022-07-28 05:43:22.139556+00', '2022-07-28 05:43:22.139556+00'),
	(3, 'Tarjeta de Crédito', 'https://user-images.githubusercontent.com/79369571/181429340-977d04ce-960d-4699-b3cc-6a4a5cb76f3d.png', '2022-07-28 05:43:34.88698+00', '2022-07-28 05:43:34.88698+00'),
	(4, 'Tarjeta de Débito', 'https://user-images.githubusercontent.com/79369571/181429348-dcd63b3b-3200-491b-b766-68b88b6507b1.png', '2022-07-28 05:43:48.070968+00', '2022-07-28 05:43:48.070968+00'),
	(5, 'E-Wallet', 'https://user-images.githubusercontent.com/79369571/181429352-6d811830-bbdc-4af0-8b7c-3aab01563ac0.png', '2022-07-28 05:43:59.934979+00', '2022-07-28 05:43:59.934979+00');



--
-- Data for Name: event; Type: TABLE DATA; Schema: public; Owner: "perfectbudget.app"
--



--
-- Name: Category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: "perfectbudget.app"
--

SELECT pg_catalog.setval('public."Category_id_seq"', 71, true);


--
-- Name: Contract_id_seq; Type: SEQUENCE SET; Schema: public; Owner: "perfectbudget.app"
--

SELECT pg_catalog.setval('public."Contract_id_seq"', 72, true);


--
-- Name: Currency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: "perfectbudget.app"
--

SELECT pg_catalog.setval('public."Currency_id_seq"', 1, false);


--
-- Name: Goal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: "perfectbudget.app"
--

SELECT pg_catalog.setval('public."Goal_id_seq"', 54, true);


--
-- Name: TransactionContract_id_seq; Type: SEQUENCE SET; Schema: public; Owner: "perfectbudget.app"
--

SELECT pg_catalog.setval('public."TransactionContract_id_seq"', 46, true);


--
-- Name: TransactionGoal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: "perfectbudget.app"
--

SELECT pg_catalog.setval('public."TransactionGoal_id_seq"', 27, true);


--
-- Name: Transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: "perfectbudget.app"
--

SELECT pg_catalog.setval('public."Transaction_id_seq"', 1907, true);


--
-- Name: TypeWallet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: "perfectbudget.app"
--

SELECT pg_catalog.setval('public."TypeWallet_id_seq"', 5, true);


--
-- Name: User_id_seq; Type: SEQUENCE SET; Schema: public; Owner: "perfectbudget.app"
--

SELECT pg_catalog.setval('public."User_id_seq"', 3673, true);


--
-- Name: Wallet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: "perfectbudget.app"
--

SELECT pg_catalog.setval('public."Wallet_id_seq"', 851, true);


--
-- Name: Category Category_pkey; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Category"
    ADD CONSTRAINT "Category_pkey" PRIMARY KEY (id);


--
-- Name: Contract Contract_pkey; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Contract"
    ADD CONSTRAINT "Contract_pkey" PRIMARY KEY (id);


--
-- Name: Currency Currency_pkey; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Currency"
    ADD CONSTRAINT "Currency_pkey" PRIMARY KEY (id);


--
-- Name: Goal Goal_pkey; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Goal"
    ADD CONSTRAINT "Goal_pkey" PRIMARY KEY (id);


--
-- Name: TransactionContract TransactionContract_pkey; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."TransactionContract"
    ADD CONSTRAINT "TransactionContract_pkey" PRIMARY KEY (id);


--
-- Name: TransactionGoal TransactionGoal_pkey; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."TransactionGoal"
    ADD CONSTRAINT "TransactionGoal_pkey" PRIMARY KEY (id);


--
-- Name: Transaction Transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Transaction"
    ADD CONSTRAINT "Transaction_pkey" PRIMARY KEY (id);


--
-- Name: TypeTransaction TypeTransaction_pkey; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."TypeTransaction"
    ADD CONSTRAINT "TypeTransaction_pkey" PRIMARY KEY (name_type);


--
-- Name: TypeWallet TypeWallet_pkey; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."TypeWallet"
    ADD CONSTRAINT "TypeWallet_pkey" PRIMARY KEY (id);


--
-- Name: User User_email_key; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_email_key" UNIQUE (email);


--
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (uuid);


--
-- Name: Wallet Wallet_pkey; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Wallet"
    ADD CONSTRAINT "Wallet_pkey" PRIMARY KEY (id);


--
-- Name: event event_aggregate_id_version_key; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public.event
    ADD CONSTRAINT event_aggregate_id_version_key UNIQUE (aggregate_id, version);


--
-- Name: event event_pkey; Type: CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public.event
    ADD CONSTRAINT event_pkey PRIMARY KEY (id);


--
-- Name: idx_event_aggregate_id; Type: INDEX; Schema: public; Owner: "perfectbudget.app"
--

CREATE INDEX idx_event_aggregate_id ON public.event USING btree (aggregate_id);


--
-- Name: Contract create_accept_contract; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER create_accept_contract AFTER UPDATE ON public."Contract" FOR EACH ROW EXECUTE FUNCTION public.create_contract_accept();


--
-- Name: Wallet create_transaction; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER create_transaction AFTER INSERT ON public."Wallet" FOR EACH ROW EXECUTE FUNCTION public.create_first_transaction();


--
-- Name: TransactionContract create_transaction_contract; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER create_transaction_contract AFTER UPDATE ON public."TransactionContract" FOR EACH ROW EXECUTE FUNCTION public.create_transaction_contract_accept();


--
-- Name: Contract notify_hasura_send_mail_invite_INSERT; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

--CREATE TRIGGER "notify_hasura_send_mail_invite_INSERT" AFTER INSERT ON public."Contract" FOR EACH ROW EXECUTE FUNCTION hdb_catalog."notify_hasura_send_mail_invite_INSERT"();


--
-- Name: Category set_public_Category_updated_at; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER "set_public_Category_updated_at" BEFORE UPDATE ON public."Category" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER "set_public_Category_updated_at" ON "Category"; Type: COMMENT; Schema: public; Owner: "perfectbudget.app"
--

COMMENT ON TRIGGER "set_public_Category_updated_at" ON public."Category" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: Contract set_public_Contract_updated_at; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER "set_public_Contract_updated_at" BEFORE UPDATE ON public."Contract" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER "set_public_Contract_updated_at" ON "Contract"; Type: COMMENT; Schema: public; Owner: "perfectbudget.app"
--

COMMENT ON TRIGGER "set_public_Contract_updated_at" ON public."Contract" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: Currency set_public_Currency_updated_at; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER "set_public_Currency_updated_at" BEFORE UPDATE ON public."Currency" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER "set_public_Currency_updated_at" ON "Currency"; Type: COMMENT; Schema: public; Owner: "perfectbudget.app"
--

COMMENT ON TRIGGER "set_public_Currency_updated_at" ON public."Currency" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: Goal set_public_Goal_updated_at; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER "set_public_Goal_updated_at" BEFORE UPDATE ON public."Goal" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER "set_public_Goal_updated_at" ON "Goal"; Type: COMMENT; Schema: public; Owner: "perfectbudget.app"
--

COMMENT ON TRIGGER "set_public_Goal_updated_at" ON public."Goal" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: TransactionContract set_public_TransactionContract_updated_at; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER "set_public_TransactionContract_updated_at" BEFORE UPDATE ON public."TransactionContract" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER "set_public_TransactionContract_updated_at" ON "TransactionContract"; Type: COMMENT; Schema: public; Owner: "perfectbudget.app"
--

COMMENT ON TRIGGER "set_public_TransactionContract_updated_at" ON public."TransactionContract" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: TransactionGoal set_public_TransactionGoal_updated_at; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER "set_public_TransactionGoal_updated_at" BEFORE UPDATE ON public."TransactionGoal" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER "set_public_TransactionGoal_updated_at" ON "TransactionGoal"; Type: COMMENT; Schema: public; Owner: "perfectbudget.app"
--

COMMENT ON TRIGGER "set_public_TransactionGoal_updated_at" ON public."TransactionGoal" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: Transaction set_public_Transaction_updated_at; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER "set_public_Transaction_updated_at" BEFORE UPDATE ON public."Transaction" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER "set_public_Transaction_updated_at" ON "Transaction"; Type: COMMENT; Schema: public; Owner: "perfectbudget.app"
--

COMMENT ON TRIGGER "set_public_Transaction_updated_at" ON public."Transaction" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: TypeWallet set_public_TypeWallet_updated_at; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER "set_public_TypeWallet_updated_at" BEFORE UPDATE ON public."TypeWallet" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER "set_public_TypeWallet_updated_at" ON "TypeWallet"; Type: COMMENT; Schema: public; Owner: "perfectbudget.app"
--

COMMENT ON TRIGGER "set_public_TypeWallet_updated_at" ON public."TypeWallet" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: User set_public_User_updated_at; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER "set_public_User_updated_at" BEFORE UPDATE ON public."User" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER "set_public_User_updated_at" ON "User"; Type: COMMENT; Schema: public; Owner: "perfectbudget.app"
--

COMMENT ON TRIGGER "set_public_User_updated_at" ON public."User" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: Wallet set_public_Wallet_updated_at; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER "set_public_Wallet_updated_at" BEFORE UPDATE ON public."Wallet" FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER "set_public_Wallet_updated_at" ON "Wallet"; Type: COMMENT; Schema: public; Owner: "perfectbudget.app"
--

COMMENT ON TRIGGER "set_public_Wallet_updated_at" ON public."Wallet" IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: Transaction update_balance; Type: TRIGGER; Schema: public; Owner: "perfectbudget.app"
--

CREATE TRIGGER update_balance AFTER INSERT OR DELETE OR UPDATE ON public."Transaction" FOR EACH ROW EXECUTE FUNCTION public.update_balance_wallet();


--
-- Name: Category Category_parrent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Category"
    ADD CONSTRAINT "Category_parrent_id_fkey" FOREIGN KEY (parrent_id) REFERENCES public."Category"(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Category Category_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Category"
    ADD CONSTRAINT "Category_type_fkey" FOREIGN KEY (type) REFERENCES public."TypeTransaction"(name_type) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Contract Contract_email_lender_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Contract"
    ADD CONSTRAINT "Contract_email_lender_fkey" FOREIGN KEY (email_lender) REFERENCES public."User"(email) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Goal Goal_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Goal"
    ADD CONSTRAINT "Goal_category_id_fkey" FOREIGN KEY (category_id) REFERENCES public."Category"(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Goal Goal_user_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Goal"
    ADD CONSTRAINT "Goal_user_uuid_fkey" FOREIGN KEY (user_uuid) REFERENCES public."User"(uuid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TransactionContract TransactionContract_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."TransactionContract"
    ADD CONSTRAINT "TransactionContract_contract_id_fkey" FOREIGN KEY (contract_id) REFERENCES public."Contract"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TransactionGoal TransactionGoal_goal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."TransactionGoal"
    ADD CONSTRAINT "TransactionGoal_goal_id_fkey" FOREIGN KEY (goal_id) REFERENCES public."Goal"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Transaction Transaction_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Transaction"
    ADD CONSTRAINT "Transaction_category_id_fkey" FOREIGN KEY (category_id) REFERENCES public."Category"(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Transaction Transaction_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Transaction"
    ADD CONSTRAINT "Transaction_contract_id_fkey" FOREIGN KEY (contract_id) REFERENCES public."Contract"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Transaction Transaction_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Transaction"
    ADD CONSTRAINT "Transaction_type_fkey" FOREIGN KEY (type) REFERENCES public."TypeTransaction"(name_type) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Transaction Transaction_wallet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Transaction"
    ADD CONSTRAINT "Transaction_wallet_id_fkey" FOREIGN KEY (wallet_id) REFERENCES public."Wallet"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Wallet Wallet_type_wallet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Wallet"
    ADD CONSTRAINT "Wallet_type_wallet_id_fkey" FOREIGN KEY (type_wallet_id) REFERENCES public."TypeWallet"(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: Wallet Wallet_user_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: "perfectbudget.app"
--

ALTER TABLE ONLY public."Wallet"
    ADD CONSTRAINT "Wallet_user_uuid_fkey" FOREIGN KEY (user_uuid) REFERENCES public."User"(uuid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: "perfectbudget.app"
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: LANGUAGE plpgsql; Type: ACL; Schema: -; Owner: root
--

GRANT ALL ON LANGUAGE plpgsql TO "perfectbudget.app";


--
-- PostgreSQL database dump complete
--

