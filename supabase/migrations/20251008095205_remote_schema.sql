

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


CREATE SCHEMA IF NOT EXISTS "api";


ALTER SCHEMA "api" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "wrappers" WITH SCHEMA "extensions";






CREATE TYPE "public"."continents" AS ENUM (
    'Africa',
    'Antarctica',
    'Asia',
    'Europe',
    'Oceania',
    'North America',
    'South America'
);


ALTER TYPE "public"."continents" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."archive_task"("task_id_param" "uuid", "archived_by_param" "text" DEFAULT 'system'::"text") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    task_exists BOOLEAN;
BEGIN
    -- Check if task exists and is not already archived
    SELECT EXISTS(
        SELECT 1 FROM archon_tasks
        WHERE id = task_id_param AND archived = FALSE
    ) INTO task_exists;

    IF NOT task_exists THEN
        RETURN FALSE;
    END IF;

    -- Archive the task
    UPDATE archon_tasks
    SET
        archived = TRUE,
        archived_at = NOW(),
        archived_by = archived_by_param,
        updated_at = NOW()
    WHERE id = task_id_param;

    -- Also archive all subtasks
    UPDATE archon_tasks
    SET
        archived = TRUE,
        archived_at = NOW(),
        archived_by = archived_by_param,
        updated_at = NOW()
    WHERE parent_task_id = task_id_param AND archived = FALSE;

    RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."archive_task"("task_id_param" "uuid", "archived_by_param" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."match_archon_code_examples"("query_embedding" "extensions"."vector", "match_count" integer DEFAULT 10, "filter" "jsonb" DEFAULT '{}'::"jsonb", "source_filter" "text" DEFAULT NULL::"text") RETURNS TABLE("id" bigint, "url" character varying, "chunk_number" integer, "content" "text", "summary" "text", "metadata" "jsonb", "source_id" "text", "similarity" double precision)
    LANGUAGE "plpgsql"
    AS $$
#variable_conflict use_column
BEGIN
  RETURN QUERY
  SELECT
    id,
    url,
    chunk_number,
    content,
    summary,
    metadata,
    source_id,
    1 - (archon_code_examples.embedding <=> query_embedding) AS similarity
  FROM archon_code_examples
  WHERE metadata @> filter
    AND (source_filter IS NULL OR source_id = source_filter)
  ORDER BY archon_code_examples.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;


ALTER FUNCTION "public"."match_archon_code_examples"("query_embedding" "extensions"."vector", "match_count" integer, "filter" "jsonb", "source_filter" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."match_archon_crawled_pages"("query_embedding" "extensions"."vector", "match_count" integer DEFAULT 10, "filter" "jsonb" DEFAULT '{}'::"jsonb", "source_filter" "text" DEFAULT NULL::"text") RETURNS TABLE("id" bigint, "url" character varying, "chunk_number" integer, "content" "text", "metadata" "jsonb", "source_id" "text", "similarity" double precision)
    LANGUAGE "plpgsql"
    AS $$
#variable_conflict use_column
BEGIN
  RETURN QUERY
  SELECT
    id,
    url,
    chunk_number,
    content,
    metadata,
    source_id,
    1 - (archon_crawled_pages.embedding <=> query_embedding) AS similarity
  FROM archon_crawled_pages
  WHERE metadata @> filter
    AND (source_filter IS NULL OR source_id = source_filter)
  ORDER BY archon_crawled_pages.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;


ALTER FUNCTION "public"."match_archon_crawled_pages"("query_embedding" "extensions"."vector", "match_count" integer, "filter" "jsonb", "source_filter" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE FOREIGN DATA WRAPPER "cloudflare_d1" HANDLER "extensions"."wasm_fdw_handler" VALIDATOR "extensions"."wasm_fdw_validator";




CREATE SERVER "cloudflare_d1_server" FOREIGN DATA WRAPPER "cloudflare_d1" OPTIONS (
    "account_id" 'ae931e241550e8326149eeda10ada60d',
    "api_token_id" '0769ca25-1f77-43b4-b173-fa10c8154341',
    "api_url" 'https://api.cloudflare.com/client/v4/accounts/<account_id>/d1/database',
    "database_id" '407db161-026a-41ed-b081-dfcbde7dbbe4',
    "fdw_package_checksum" '783232834bb29dbd3ee6b09618c16f8a847286e63d05c54397d56c3e703fad31',
    "fdw_package_name" 'supabase:cfd1-fdw',
    "fdw_package_url" 'https://github.com/supabase/wrappers/releases/download/wasm_cfd1_fdw_v0.1.0/cfd1_fdw.wasm',
    "fdw_package_version" '0.1.0'
);


ALTER SERVER "cloudflare_d1_server" OWNER TO "postgres";


CREATE FOREIGN TABLE "public"."Agents" (
    "uuid" "text",
    "name" "text",
    "version" "text",
    "num_tables" bigint,
    "file_size" bigint,
    "created_at" "text",
    "_attrs" "jsonb"
)
SERVER "cloudflare_d1_server"
OPTIONS (
    "schema" 'public',
    "table" '_meta_databases'
);


ALTER FOREIGN TABLE "public"."Agents" OWNER TO "postgres";


CREATE FOREIGN TABLE "public"."SkogAI" (
    "version" "text",
    "num_tables" bigint,
    "file_size" bigint,
    "created_at" "text",
    "_attrs" "jsonb",
    "name" "text",
    "uuid" "text"
)
SERVER "cloudflare_d1_server"
OPTIONS (
    "schema" 'public',
    "table" '_meta_databases'
);


ALTER FOREIGN TABLE "public"."SkogAI" OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."agent_configs" (
    "id" integer NOT NULL,
    "agent_type" character varying(100) NOT NULL,
    "config" "jsonb" NOT NULL,
    "capabilities" "text"[],
    "active" boolean DEFAULT true,
    "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."agent_configs" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."agent_configs_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."agent_configs_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."agent_configs_id_seq" OWNED BY "public"."agent_configs"."id";



CREATE TABLE IF NOT EXISTS "public"."agent_logs" (
    "id" integer NOT NULL,
    "agent_type" character varying(100) NOT NULL,
    "action" character varying(255) NOT NULL,
    "details" "jsonb",
    "context" "text",
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "session_id" character varying(100),
    "status" character varying(50) DEFAULT 'success'::character varying
);


ALTER TABLE "public"."agent_logs" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."agent_logs_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."agent_logs_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."agent_logs_id_seq" OWNED BY "public"."agent_logs"."id";



CREATE TABLE IF NOT EXISTS "public"."agent_tasks" (
    "id" integer NOT NULL,
    "task_name" character varying(255) NOT NULL,
    "description" "text",
    "assigned_to" character varying(100),
    "priority" character varying(20) DEFAULT 'medium'::character varying,
    "status" character varying(50) DEFAULT 'pending'::character varying,
    "due_date" timestamp without time zone,
    "completed_at" timestamp without time zone,
    "metadata" "jsonb",
    "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."agent_tasks" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."agent_tasks_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."agent_tasks_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."agent_tasks_id_seq" OWNED BY "public"."agent_tasks"."id";



CREATE TABLE IF NOT EXISTS "public"."api_results" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "url" "text" NOT NULL,
    "response_data" "jsonb",
    "status_code" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."api_results" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."artifacts" (
    "id" integer NOT NULL,
    "name" character varying(255) NOT NULL,
    "type" character varying(100) NOT NULL,
    "path" "text",
    "content" "text",
    "metadata" "jsonb",
    "created_by" character varying(100),
    "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."artifacts" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."artifacts_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."artifacts_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."artifacts_id_seq" OWNED BY "public"."artifacts"."id";



CREATE TABLE IF NOT EXISTS "public"."conversation_context" (
    "id" integer NOT NULL,
    "conversation_id" character varying(255) NOT NULL,
    "context" "jsonb" NOT NULL,
    "summary" "text",
    "participants" "text"[],
    "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."conversation_context" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."conversation_context_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."conversation_context_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."conversation_context_id_seq" OWNED BY "public"."conversation_context"."id";



CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" DEFAULT 'New Conversation'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."conversations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."countries" (
    "id" bigint NOT NULL,
    "name" "text",
    "iso2" "text" NOT NULL,
    "iso3" "text",
    "local_name" "text",
    "continent" "public"."continents"
);


ALTER TABLE "public"."countries" OWNER TO "postgres";


COMMENT ON TABLE "public"."countries" IS 'Full list of countries.';



COMMENT ON COLUMN "public"."countries"."name" IS 'Full country name.';



COMMENT ON COLUMN "public"."countries"."iso2" IS 'ISO 3166-1 alpha-2 code.';



COMMENT ON COLUMN "public"."countries"."iso3" IS 'ISO 3166-1 alpha-3 code.';



COMMENT ON COLUMN "public"."countries"."local_name" IS 'Local variation of the name.';



ALTER TABLE "public"."countries" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."countries_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."events" (
    "id" integer NOT NULL,
    "event_type" character varying(100) NOT NULL,
    "source" character varying(100) NOT NULL,
    "target" character varying(100),
    "payload" "jsonb",
    "processed" boolean DEFAULT false,
    "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "processed_at" timestamp without time zone
);


ALTER TABLE "public"."events" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."events_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."events_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."events_id_seq" OWNED BY "public"."events"."id";



CREATE TABLE IF NOT EXISTS "public"."knowledge_base" (
    "id" integer NOT NULL,
    "category" character varying(100) NOT NULL,
    "title" character varying(255) NOT NULL,
    "content" "text" NOT NULL,
    "metadata" "jsonb",
    "tags" "text"[],
    "created_by" character varying(100),
    "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."knowledge_base" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."knowledge_base_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."knowledge_base_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."knowledge_base_id_seq" OWNED BY "public"."knowledge_base"."id";



CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "conversation_id" "uuid" NOT NULL,
    "sender" "text" NOT NULL,
    "content" "text" NOT NULL,
    "agent_id" "text",
    "timestamp" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."metrics" (
    "id" integer NOT NULL,
    "metric_name" character varying(100) NOT NULL,
    "value" numeric,
    "unit" character varying(50),
    "source" character varying(100),
    "tags" "jsonb",
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."metrics" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."metrics_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."metrics_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."metrics_id_seq" OWNED BY "public"."metrics"."id";



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "username" "text",
    "full_name" "text",
    "avatar_url" "text",
    "website" "text",
    CONSTRAINT "username_length" CHECK (("char_length"("username") >= 3))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."request_logs" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "model" "text" DEFAULT ''::"text",
    "messages" "json" DEFAULT '{}'::"json",
    "response" "json" DEFAULT '{}'::"json",
    "end_user" "text" DEFAULT ''::"text",
    "error" "json" DEFAULT '{}'::"json",
    "response_time" real DEFAULT '0'::real,
    "total_cost" real,
    "additional_details" "json" DEFAULT '{}'::"json"
);


ALTER TABLE "public"."request_logs" OWNER TO "postgres";


ALTER TABLE "public"."request_logs" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."request_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."todos" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "task" "text",
    "is_complete" boolean DEFAULT false,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    CONSTRAINT "todos_task_check" CHECK (("char_length"("task") > 3))
);


ALTER TABLE "public"."todos" OWNER TO "postgres";


ALTER TABLE "public"."todos" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."todos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "public"."agent_configs" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."agent_configs_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."agent_logs" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."agent_logs_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."agent_tasks" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."agent_tasks_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."artifacts" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."artifacts_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."conversation_context" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."conversation_context_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."events" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."events_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."knowledge_base" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."knowledge_base_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."metrics" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."metrics_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."agent_configs"
    ADD CONSTRAINT "agent_configs_agent_type_key" UNIQUE ("agent_type");



ALTER TABLE ONLY "public"."agent_configs"
    ADD CONSTRAINT "agent_configs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_logs"
    ADD CONSTRAINT "agent_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_tasks"
    ADD CONSTRAINT "agent_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."api_results"
    ADD CONSTRAINT "api_results_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."artifacts"
    ADD CONSTRAINT "artifacts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversation_context"
    ADD CONSTRAINT "conversation_context_conversation_id_key" UNIQUE ("conversation_id");



ALTER TABLE ONLY "public"."conversation_context"
    ADD CONSTRAINT "conversation_context_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."countries"
    ADD CONSTRAINT "countries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."knowledge_base"
    ADD CONSTRAINT "knowledge_base_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metrics"
    ADD CONSTRAINT "metrics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_username_key" UNIQUE ("username");



ALTER TABLE ONLY "public"."request_logs"
    ADD CONSTRAINT "request_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."todos"
    ADD CONSTRAINT "todos_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_conversations_updated_at" ON "public"."conversations" USING "btree" ("updated_at");



CREATE INDEX "idx_messages_conversation_id" ON "public"."messages" USING "btree" ("conversation_id");



CREATE INDEX "idx_messages_timestamp" ON "public"."messages" USING "btree" ("timestamp");



CREATE OR REPLACE TRIGGER "update_api_results_updated_at" BEFORE UPDATE ON "public"."api_results" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_conversations_updated_at" BEFORE UPDATE ON "public"."conversations" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."todos"
    ADD CONSTRAINT "todos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



CREATE POLICY "Allow all operations on api_results" ON "public"."api_results" USING (true) WITH CHECK (true);



CREATE POLICY "Allow all operations on conversations" ON "public"."conversations" USING (true) WITH CHECK (true);



CREATE POLICY "Allow all operations on messages" ON "public"."messages" USING (true) WITH CHECK (true);



CREATE POLICY "Individuals can create todos." ON "public"."todos" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Individuals can delete their own todos." ON "public"."todos" FOR DELETE USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Individuals can update their own todos." ON "public"."todos" FOR UPDATE USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Individuals can view their own todos. " ON "public"."todos" FOR SELECT USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Public profiles are viewable by everyone." ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Users can insert their own profile." ON "public"."profiles" FOR INSERT WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "Users can update own profile." ON "public"."profiles" FOR UPDATE USING ((( SELECT "auth"."uid"() AS "uid") = "id"));



ALTER TABLE "public"."api_results" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."countries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."todos" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "api" TO "anon";
GRANT USAGE ON SCHEMA "api" TO "authenticated";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

















































































































































































































































































































































































































































































































































































































































































GRANT ALL ON FUNCTION "public"."archive_task"("task_id_param" "uuid", "archived_by_param" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."archive_task"("task_id_param" "uuid", "archived_by_param" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."archive_task"("task_id_param" "uuid", "archived_by_param" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";









GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";










































GRANT ALL ON TABLE "public"."Agents" TO "anon";
GRANT ALL ON TABLE "public"."Agents" TO "authenticated";
GRANT ALL ON TABLE "public"."Agents" TO "service_role";



GRANT ALL ON TABLE "public"."SkogAI" TO "anon";
GRANT ALL ON TABLE "public"."SkogAI" TO "authenticated";
GRANT ALL ON TABLE "public"."SkogAI" TO "service_role";



GRANT ALL ON TABLE "public"."agent_configs" TO "anon";
GRANT ALL ON TABLE "public"."agent_configs" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_configs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."agent_configs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."agent_configs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."agent_configs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."agent_logs" TO "anon";
GRANT ALL ON TABLE "public"."agent_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_logs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."agent_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."agent_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."agent_logs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."agent_tasks" TO "anon";
GRANT ALL ON TABLE "public"."agent_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_tasks" TO "service_role";



GRANT ALL ON SEQUENCE "public"."agent_tasks_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."agent_tasks_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."agent_tasks_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."api_results" TO "anon";
GRANT ALL ON TABLE "public"."api_results" TO "authenticated";
GRANT ALL ON TABLE "public"."api_results" TO "service_role";



GRANT ALL ON TABLE "public"."artifacts" TO "anon";
GRANT ALL ON TABLE "public"."artifacts" TO "authenticated";
GRANT ALL ON TABLE "public"."artifacts" TO "service_role";



GRANT ALL ON SEQUENCE "public"."artifacts_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."artifacts_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."artifacts_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."conversation_context" TO "anon";
GRANT ALL ON TABLE "public"."conversation_context" TO "authenticated";
GRANT ALL ON TABLE "public"."conversation_context" TO "service_role";



GRANT ALL ON SEQUENCE "public"."conversation_context_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."conversation_context_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."conversation_context_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."conversations" TO "anon";
GRANT ALL ON TABLE "public"."conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."conversations" TO "service_role";



GRANT ALL ON TABLE "public"."countries" TO "anon";
GRANT ALL ON TABLE "public"."countries" TO "authenticated";
GRANT ALL ON TABLE "public"."countries" TO "service_role";



GRANT ALL ON SEQUENCE "public"."countries_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."countries_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."countries_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."events" TO "anon";
GRANT ALL ON TABLE "public"."events" TO "authenticated";
GRANT ALL ON TABLE "public"."events" TO "service_role";



GRANT ALL ON SEQUENCE "public"."events_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."events_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."events_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."knowledge_base" TO "anon";
GRANT ALL ON TABLE "public"."knowledge_base" TO "authenticated";
GRANT ALL ON TABLE "public"."knowledge_base" TO "service_role";



GRANT ALL ON SEQUENCE "public"."knowledge_base_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."knowledge_base_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."knowledge_base_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



GRANT ALL ON TABLE "public"."metrics" TO "anon";
GRANT ALL ON TABLE "public"."metrics" TO "authenticated";
GRANT ALL ON TABLE "public"."metrics" TO "service_role";



GRANT ALL ON SEQUENCE "public"."metrics_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."metrics_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."metrics_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."request_logs" TO "anon";
GRANT ALL ON TABLE "public"."request_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."request_logs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."request_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."request_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."request_logs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."todos" TO "anon";
GRANT ALL ON TABLE "public"."todos" TO "authenticated";
GRANT ALL ON TABLE "public"."todos" TO "service_role";



GRANT ALL ON SEQUENCE "public"."todos_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."todos_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."todos_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























RESET ALL;
