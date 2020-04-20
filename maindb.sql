-- Table: public.users

-- DROP TABLE public.users;

CREATE TABLE public.users
(
    user_id         bigint                                         NOT NULL DEFAULT nextval('users_user_id_seq'::regclass),
    username        character varying COLLATE pg_catalog."default" NOT NULL,
    pwd             character varying COLLATE pg_catalog."default" NOT NULL,
    email_id        character varying COLLATE pg_catalog."default" NOT NULL,
    joining_date    date                                           NOT NULL DEFAULT CURRENT_DATE,
    birth_date      date,
    user_name       character varying COLLATE pg_catalog."default" NOT NULL,
    bio             text COLLATE pg_catalog."default",
    fb_handle       character varying COLLATE pg_catalog."default",
    ig_handle       character varying COLLATE pg_catalog."default",
    twitter_handle  character varying COLLATE pg_catalog."default",
    linkedin_handle character varying COLLATE pg_catalog."default",
    github_handle   character varying COLLATE pg_catalog."default",
    profile_photo   character varying COLLATE pg_catalog."default",
    CONSTRAINT "Users_pk" PRIMARY KEY (user_id)
) TABLESPACE pg_default;

ALTER TABLE public.users
    OWNER to postgres;

-- Trigger: add_board

-- DROP TRIGGER add_board ON public.users;

CREATE TRIGGER add_board
    AFTER INSERT
    ON public.users
    FOR EACH ROW
    EXECUTE PROCEDURE public.process_add_board();



-- Table: public.boards

-- DROP TABLE public.boards;

CREATE TABLE public.boards
(
    board_id    bigint                                         NOT NULL DEFAULT nextval('boards_board_id_seq'::regclass),
    board_name  character varying COLLATE pg_catalog."default" NOT NULL,
    description character varying COLLATE pg_catalog."default",
    status      boolean                                        NOT NULL DEFAULT true,
    cover_img   bytea,
    create_date date                                           NOT NULL DEFAULT CURRENT_DATE,
    user_id     bigint                                         NOT NULL,
    CONSTRAINT boards_pkey PRIMARY KEY (board_id),
    CONSTRAINT fk_user_id FOREIGN KEY (user_id)
        REFERENCES public.users (user_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
) TABLESPACE pg_default;

ALTER TABLE public.boards
    OWNER to postgres;

-- Trigger: delete_board_pages

-- DROP TRIGGER delete_board_pages ON public.boards;

CREATE TRIGGER delete_board_pages
    AFTER UPDATE
    ON public.boards
    FOR EACH ROW
    EXECUTE PROCEDURE public.delete_boards();

-- Trigger: log_changer

-- DROP TRIGGER log_changer ON public.boards;

CREATE TRIGGER log_changer
    AFTER UPDATE
    ON public.boards
    FOR EACH ROW
    EXECUTE PROCEDURE public.log_board_changes();



-- Table: public.pages

-- DROP TABLE public.pages;

CREATE TABLE public.pages
(
    page_id     bigint                                         NOT NULL DEFAULT nextval('pages_page_id_seq'::regclass),
    page_name   character varying COLLATE pg_catalog."default" NOT NULL,
    page_data   text COLLATE pg_catalog."default",
    create_date date                                           NOT NULL DEFAULT CURRENT_DATE,
    reminder    timestamp without time zone,
    board_id    bigint                                         NOT NULL,
    status      boolean                                        NOT NULL DEFAULT true,
    CONSTRAINT pages_pkey PRIMARY KEY (page_id),
    CONSTRAINT fk_board_id FOREIGN KEY (board_id)
        REFERENCES public.boards (board_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
) TABLESPACE pg_default;

ALTER TABLE public.pages
    OWNER to postgres;

-- Trigger: add_pages

-- DROP TRIGGER add_pages ON public.pages;

CREATE TRIGGER add_pages
    AFTER INSERT
    ON public.pages
    FOR EACH ROW
    EXECUTE PROCEDURE public.process_add_page();

-- Trigger: log_changer_pages

-- DROP TRIGGER log_changer_pages ON public.pages;

CREATE TRIGGER log_changer_pages
    AFTER UPDATE
    ON public.pages
    FOR EACH ROW
    EXECUTE PROCEDURE public.log_page_changes();



-- Table: public.user_logs

-- DROP TABLE public.user_logs;

CREATE TABLE public.user_logs
(
    log_id   bigint                                         NOT NULL DEFAULT nextval('user_logs_log_id_seq'::regclass),
    user_id  bigint                                         NOT NULL,
    board_id bigint                                         NOT NULL,
    page_id  bigint,
    new_name character varying COLLATE pg_catalog."default",
    old_name character varying COLLATE pg_catalog."default",
    old_data text COLLATE pg_catalog."default",
    new_data text COLLATE pg_catalog."default",
    type     character varying COLLATE pg_catalog."default" NOT NULL,
    content  character varying COLLATE pg_catalog."default" NOT NULL,
    log_date timestamp without time zone                    NOT NULL,
    CONSTRAINT user_logs_pkey PRIMARY KEY (log_id),
    CONSTRAINT fk_board_id FOREIGN KEY (board_id)
        REFERENCES public.boards (board_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_page_id FOREIGN KEY (page_id)
        REFERENCES public.pages (page_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_user_id FOREIGN KEY (user_id)
        REFERENCES public.users (user_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
) TABLESPACE pg_default;

ALTER TABLE public.user_logs
    OWNER to postgres;



-- FUNCTION: public.delete_boards()

-- DROP FUNCTION public.delete_boards();

CREATE
FUNCTION public.delete_boards()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$BEGIN
    IF (TG_OP = 'UPDATE') THEN
        IF NEW.status<>OLD.status THEN
UPDATE pages
SET status = false
WHERE board_id = OLD.board_id;
END IF;
END IF;
RETURN NULL;
END;
$BODY$;

ALTER
FUNCTION public.delete_boards()
    OWNER TO postgres;



-- FUNCTION: public.log_board_changes()

-- DROP FUNCTION public.log_board_changes();

CREATE
FUNCTION public.log_board_changes()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$BEGIN
    IF (TG_OP = 'UPDATE') THEN
        IF NEW.board_name<>OLD.board_name THEN
INSERT INTO user_logs(user_id, board_id, old_name, new_name, log_date, type, content)
VALUES (OLD.user_id, OLD.board_id, OLD.board_name, NEW.board_name, CURRENT_TIMESTAMP, 'UPDATE', 'Board');
END IF;
IF NEW.description<>OLD.description THEN
INSERT INTO user_logs(user_id, board_id, old_data, new_data, log_date, type, content)
VALUES (OLD.user_id, OLD.board_id, OLD.description, NEW.description, CURRENT_TIMESTAMP, 'UPDATE', 'Board');
END IF;
IF NEW.status<>OLD.status THEN
INSERT INTO user_logs(user_id, board_id, log_date, type, content)
VALUES (OLD.user_id, OLD.board_id, CURRENT_TIMESTAMP, 'REMOVED', 'Board');
END IF;
ELSIF (TG_OP = 'INSERT') THEN
INSERT INTO user_logs(user_id, board_id, old_name, new_name, log_date, type, content)
VALUES (OLD.user_id, OLD.board_id, OLD.board_name, NEW.board_name, CURRENT_TIMESTAMP, 'INSERT', 'Board');
END IF;
RETURN NEW;
END;
$BODY$;

ALTER
FUNCTION public.log_board_changes()
    OWNER TO postgres;




-- FUNCTION: public.log_page_changes()

-- DROP FUNCTION public.log_page_changes();

CREATE
FUNCTION public.log_page_changes()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$DECLARE
    userid INTEGER;
BEGIN
SELECT user_id INTO userid
FROM boards
WHERE board_id=OLD.board_id;
IF (TG_OP = 'UPDATE') THEN
        IF NEW.page_name<>OLD.page_name THEN
INSERT INTO user_logs(user_id, board_id, page_id, old_name, new_name, log_date, type, content)
VALUES (userid, OLD.board_id, OLD.page_id, OLD.page_name, NEW.page_name, CURRENT_TIMESTAMP, 'UPDATE', 'Pages');
END IF;
IF NEW.page_data<>OLD.page_data THEN
INSERT INTO user_logs(user_id, board_id, page_id, old_data, new_data, log_date, type, content)
VALUES (userid, OLD.board_id, OLD.page_id, OLD.page_data, NEW.page_data, CURRENT_TIMESTAMP, 'UPDATE', 'Pages');
END IF;
IF NEW.status<>OLD.status THEN
INSERT INTO user_logs(user_id, board_id, page_id, log_date, type, content)
VALUES (userid, OLD.board_id, OLD.page_id, CURRENT_TIMESTAMP, 'REMOVED', 'Pages');
END IF;
ELSE
INSERT INTO user_logs(user_id, board_id, page_id, old_name, new_name, log_date, type, content)
VALUES (userid, OLD.board_id, OLD.page_id, OLD.page_name, NEW.board_name, CURRENT_TIMESTAMP, 'INSERT', 'Pages');
END IF;
RETURN NEW;
END;
$BODY$;

ALTER
FUNCTION public.log_page_changes()
    OWNER TO postgres;



-- FUNCTION: public.process_add_board()

-- DROP FUNCTION public.process_add_board();

CREATE
FUNCTION public.process_add_board()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
INSERT INTO boards(board_name, description, user_id)
VALUES ('Untitle Board', 'Enter description', NEW.user_id);
RETURN NEW;
END;
$BODY$;

ALTER
FUNCTION public.process_add_board()
    OWNER TO postgres;



-- FUNCTION: public.process_add_page()

-- DROP FUNCTION public.process_add_page();

CREATE
FUNCTION public.process_add_page()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$BEGIN
INSERT INTO pages(page_name, data, board_id)
VALUES ('Untitle Page', 'Enter your Text', NEW.board_id);
RETURN NEW;
END;
$BODY$;

ALTER
FUNCTION public.process_add_page()
    OWNER TO postgres;



-- FUNCTION: public.get_active_months(integer)

-- DROP FUNCTION public.get_active_months(integer);

CREATE
OR REPLACE
FUNCTION public.get_active_months(
	userid integer)
    RETURNS TABLE(month_year character varying)
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
    ROWS 1000

AS $BODY$DECLARE
    var_r record;
BEGIN FOR var_r IN ( SELECT log_date FROM user_logs WHERE user_logs.user_id = userid ) LOOP
        month_year := CONCAT(TO_CHAR(var_r.log_date, 'Month'), ' ', TO_CHAR(var_r.log_date, 'YYYY'));
RETURN NEXT;
END LOOP;
END;
$BODY$;

ALTER
FUNCTION public.get_active_months(integer)
    OWNER TO postgres;



-- FUNCTION: public.get_logs(integer)

-- DROP FUNCTION public.get_logs(integer);

CREATE
OR REPLACE
FUNCTION public.get_logs(
	userid integer)
    RETURNS TABLE(log_content character, log_text character varying, date_time character varying, log_date character varying, log_time character varying, month_year character varying)
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
    ROWS 1000

AS $BODY$DECLARE
    var_r record;
p_name varchar;
b_name varchar;
BEGIN FOR var_r IN ( SELECT * FROM user_logs WHERE user_logs.user_id = userid ) LOOP
        log_content := var_r.content;
IF var_r.type = 'UPDATE' THEN
			IF var_r.old_name <> var_r.new_name THEN
				log_text := CONCAT(var_r.content, 'name changed from ', var_r.old_name, 'to ', var_r.new_name);
ELSE
				IF var_r.content = 'Pages' THEN
SELECT pages.page_name INTO p_name
FROM pages
WHERE pages.page_id = var_r.page_id;
log_text := CONCAT(var_r.content, ' named ', p_name, ' was edited');
ELSE
SELECT boards.board_name INTO b_name
FROM boards
WHERE boards.board_id = var_r.board_id;
log_text := CONCAT(var_r.content, ' named ', b_name, ' was edited');
END IF;
END IF;
ELSIF var_r.type = 'INSERT' THEN
			IF var_r.content = 'Pages' THEN
SELECT pages.page_name INTO p_name
FROM pages
WHERE pages.page_id = var_r.page_id;
log_text := CONCAT(var_r.content, ' named ', p_name, ' was created');
ELSE
SELECT boards.board_name INTO b_name
FROM boards
WHERE boards.board_id = var_r.board_id;
log_text := CONCAT(var_r.content, ' named ', b_name, ' was created');
END IF;
ELSE
			IF var_r.content = 'Pages' THEN
SELECT pages.page_name INTO p_name
FROM pages
WHERE pages.page_id = var_r.page_id;
log_text := CONCAT(var_r.content, ' named ', p_name, ' was deleted');
ELSE
SELECT boards.board_name INTO b_name
FROM boards
WHERE boards.board_id = var_r.board_id;
log_text := CONCAT(var_r.content, ' named ', b_name, ' was deleted');
END IF;
END IF;
date_time := var_r.log_date;
log_date := CONCAT(TO_CHAR(var_r.log_date, 'DD'), ' ', TO_CHAR(var_r.log_date, 'MM'));
log_time := TO_CHAR(var_r.log_date, 'HH24:MI:SS');
month_year := CONCAT(TO_CHAR(var_r.log_date, 'Month'), ' ', TO_CHAR(var_r.log_date, 'YYYY'));
RETURN NEXT;
END LOOP;
END;
$BODY$;

ALTER
FUNCTION public.get_logs(integer)
    OWNER TO postgres;



-- FUNCTION: public.user_profile_updates(integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying)

-- DROP FUNCTION public.user_profile_updates(integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying);

CREATE
OR REPLACE
FUNCTION public.user_profile_updates(
	userid integer,
	profilephoto character varying,
	profilename character varying,
	profilebio character varying,
	fbhandle character varying,
	twitterhandle character varying,
	ighandle character varying,
	linkedinhandle character varying,
	githubhandle character varying,
	passwd character varying)
    RETURNS integer
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE

AS $BODY$
DECLARE
	var_r record;
BEGIN
SELECT * INTO var_r
FROM users
WHERE user_id = userid;

IF var_r.profile_photo<>profilephoto THEN
UPDATE users
SET profile_photo = profilephoto
WHERE user_id = userid;
END IF;

IF var_r.user_name<>profilename THEN
UPDATE users
SET user_name = profilename
WHERE user_id = userid;
END IF;

IF var_r.bio<>profilebio THEN
UPDATE users
SET bio = profilebio
WHERE user_id = userid;
END IF;

IF var_r.fb_handle<>fbhandle THEN
UPDATE users
SET fb_handle = fbhandle
WHERE user_id = userid;
END IF;

IF var_r.twitter_handle<>twitterhandle THEN
UPDATE users
SET twitter_handle = twitterhandle
WHERE user_id = userid;
END IF;

IF var_r.ig_handle<>ighandle THEN
UPDATE users
SET ig_handle = ighandle
WHERE user_id = userid;
END IF;

IF var_r.linkedin_handle<>linkedinhandle THEN
UPDATE users
SET linkedin_handle = linkedinhandle
WHERE user_id = userid;
END IF;

IF var_r.github_handle<>githubhandle THEN
UPDATE users
SET github_handle = githubhandle
WHERE user_id = userid;
END IF;

IF var_r.pwd<>'' THEN
UPDATE users
SET pwd = passwd
WHERE user_id = userid;
END IF;

RETURN 1;
END;
$BODY$;

ALTER
FUNCTION public.user_profile_updates(integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying)
    OWNER TO postgres;



-- -- Database: Merken
-- -- DROP DATABASE "Merken";
--
-- CREATE DATABASE "Merken"
--     WITH
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'English_India.1252'
--     LC_CTYPE = 'English_India.1252'
--     TABLESPACE = pg_default
--     CONNECTION LIMIT = -1;
--
--
--
-- -- Table: public.users
-- -- DROP TABLE public.users;
--
-- CREATE TABLE public.users
-- (
--     user_id bigint NOT NULL DEFAULT nextval('users_user_id_seq'::regclass),
--     username character varying COLLATE pg_catalog."default" NOT NULL,
--     pwd character varying COLLATE pg_catalog."default" NOT NULL,
--     email_id character varying COLLATE pg_catalog."default" NOT NULL,
--     profile_pic bytea,
--     joining_date date DEFAULT CURRENT_DATE,
--     birth_date date,
--     name character varying COLLATE pg_catalog."default" NOT NULL,
--     bio text COLLATE pg_catalog."default",
--     fb_handle character varying COLLATE pg_catalog."default",
--     ig_handle character varying COLLATE pg_catalog."default",
--     twitter_handle character varying COLLATE pg_catalog."default",
--     github_handle character varying COLLATE pg_catalog."default",
--     linkedin_handle character varying COLLATE pg_catalog."default",
--     CONSTRAINT users_pkey PRIMARY KEY (user_id)
-- )
--
--     TABLESPACE pg_default;
--
-- ALTER TABLE public.users
--     OWNER to postgres;
--
--
--
-- -- Table: public.boards
-- -- DROP TABLE public.boards;
--
-- CREATE TABLE public.boards
-- (
--     board_id bigint NOT NULL DEFAULT nextval('boards_board_id_seq'::regclass),
--     board_name character varying COLLATE pg_catalog."default" NOT NULL,
--     description character varying COLLATE pg_catalog."default",
--     status boolean NOT NULL DEFAULT true,
--     cover_img bytea,
--     create_date date DEFAULT CURRENT_DATE,
--     user_id bigint NOT NULL,
--     CONSTRAINT boards_pkey PRIMARY KEY (board_id),
--     CONSTRAINT fk_user_id FOREIGN KEY (user_id)
--         REFERENCES public.users (user_id) MATCH SIMPLE
--         ON UPDATE NO ACTION
--         ON DELETE NO ACTION
-- )
--
--     TABLESPACE pg_default;
--
-- ALTER TABLE public.boards
--     OWNER to postgres;
--
--
--
-- -- Table: public.pages
-- -- DROP TABLE public.pages;
--
-- CREATE TABLE public.pages
-- (
--     page_id bigint NOT NULL DEFAULT nextval('pages_page_id_seq'::regclass),
--     page_name character varying COLLATE pg_catalog."default" NOT NULL,
--     page_data text COLLATE pg_catalog."default",
--     create_date date NOT NULL DEFAULT CURRENT_DATE,
--     remainder timestamp without time zone,
--     board_id bigint NOT NULL,
--     status boolean NOT NULL DEFAULT true,
--     CONSTRAINT pages_pkey PRIMARY KEY (page_id),
--     CONSTRAINT fk_board_id FOREIGN KEY (board_id)
--         REFERENCES public.boards (board_id) MATCH SIMPLE
--         ON UPDATE NO ACTION
--         ON DELETE NO ACTION
-- )
--
--     TABLESPACE pg_default;
--
-- ALTER TABLE public.pages
--     OWNER to postgres;
--
--
--
-- -- Table: public.user_logs
-- -- DROP TABLE public.user_logs;
--
-- CREATE TABLE public.user_logs
-- (
--     log_id bigint NOT NULL DEFAULT nextval('user_logs_log_id_seq'::regclass),
--     user_id bigint NOT NULL,
--     board_id bigint NOT NULL,
--     page_id bigint,
--     new_name character varying COLLATE pg_catalog."default",
--     old_name character varying COLLATE pg_catalog."default",
--     old_data text COLLATE pg_catalog."default",
--     new_data text COLLATE pg_catalog."default",
--     type character varying COLLATE pg_catalog."default" NOT NULL,
--     content character varying COLLATE pg_catalog."default" NOT NULL,
--     log_date date NOT NULL,
--     CONSTRAINT user_logs_pkey PRIMARY KEY (log_id),
--     CONSTRAINT fk_board_id FOREIGN KEY (board_id)
--         REFERENCES public.boards (board_id) MATCH SIMPLE
--         ON UPDATE NO ACTION
--         ON DELETE NO ACTION,
--     CONSTRAINT fk_page_id FOREIGN KEY (page_id)
--         REFERENCES public.pages (page_id) MATCH SIMPLE
--         ON UPDATE NO ACTION
--         ON DELETE NO ACTION,
--     CONSTRAINT fk_user_id FOREIGN KEY (user_id)
--         REFERENCES public.users (user_id) MATCH SIMPLE
--         ON UPDATE NO ACTION
--         ON DELETE NO ACTION
-- )
--
--     TABLESPACE pg_default;
--
-- ALTER TABLE public.user_logs
--     OWNER to postgres;
--
--
--
-- -- FUNCTION: public.process_add_page()
-- -- DROP FUNCTION public.process_add_page();
--
-- CREATE FUNCTION public.process_add_page()
--     RETURNS trigger
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE NOT LEAKPROOF
-- AS $BODY$BEGIN
--     INSERT INTO pages(page_name, page_data, board_id) VALUES ('Untitle Page', 'Enter your Text', NEW
--         .board_id);
--     RETURN NEW;
-- END;$BODY$;
--
-- ALTER FUNCTION public.process_add_page()
--     OWNER TO postgres;
--
--
--
-- -- Trigger: add_pages
-- -- DROP TRIGGER add_pages ON public.pages;
--
-- CREATE TRIGGER add_pages
--     AFTER INSERT
--     ON public.boards
--     FOR EACH ROW
-- EXECUTE PROCEDURE public.process_add_page();
--
--
--
-- -- FUNCTION: public.process_add_board()
-- -- DROP FUNCTION public.process_add_board();
--
-- CREATE FUNCTION public.process_add_board()
--     RETURNS trigger
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE NOT LEAKPROOF
-- AS $BODY$BEGIN
--     INSERT INTO boards(board_name, description, user_id) VALUES ('Untitle Board', 'Enter description', NEW.user_id);
--     RETURN NULL;
-- END;$BODY$;
--
-- ALTER FUNCTION public.process_add_board()
--     OWNER TO postgres;
--
--
--
-- -- Trigger: add_board
-- -- DROP TRIGGER add_board ON public.users;
--
-- CREATE TRIGGER add_board
--     AFTER INSERT
--     ON public.users
--     FOR EACH ROW
-- EXECUTE PROCEDURE public.process_add_board();
--
--
--
-- -- FUNCTION: public.log_page_changes()
-- -- DROP FUNCTION public.log_page_changes();
--
-- CREATE FUNCTION public.log_page_changes()
--     RETURNS trigger
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE NOT LEAKPROOF
-- AS $BODY$DECLARE
--     userid INTEGER;
-- BEGIN
--     SELECT user_id INTO userid FROM boards WHERE board_id=OLD.board_id;
--     IF (TG_OP = 'UPDATE') THEN
--         IF NEW.page_name<>OLD.page_name THEN
--             INSERT INTO user_logs(user_id, board_id, page_id, old_name, new_name, log_date, type, content) VALUES(userid, OLD.board_id, OLD.page_id, OLD.page_name, NEW.page_name, CURRENT_TIMESTAMP, 'UPDATE', 'Pages');
--         END IF;
--         IF NEW.page_data<>OLD.page_data THEN
--             INSERT INTO user_logs(user_id, board_id, page_id, old_data, new_data, log_date, type, content) VALUES(userid, OLD.board_id, OLD.page_id, OLD.page_data, NEW.page_data, CURRENT_TIMESTAMP, 'UPDATE', 'Pages');
--         END IF;
--         IF NEW.status<>OLD.status THEN
--             INSERT INTO user_logs(user_id, board_id, page_id, old_status, new_status, log_date, type, content) VALUES(userid, OLD.board_id, OLD.page_id, OLD.status, NEW.status, CURRENT_TIMESTAMP, 'REMOVED', 'Pages');
--         END IF;
-- 	ELSIF (TG_OP = 'INSERT') THEN
--             INSERT INTO user_logs(user_id, board_id, page_id, old_name, new_name, log_date, type, content) VALUES(userid, OLD.board_id, OLD.page_id, OLD.page_name, NEW.board_name, CURRENT_TIMESTAMP, 'INSERT', 'Pages');
--     END IF;
--     RETURN NEW;
-- END;
-- $BODY$;
--
-- ALTER FUNCTION public.log_page_changes()
--     OWNER TO postgres;
--
--
--
-- -- Trigger: log_changer_pages
-- -- DROP TRIGGER log_changer_pages ON public.pages;
--
-- CREATE TRIGGER log_changer_pages
--     AFTER UPDATE
--     ON public.pages
--     FOR EACH ROW
-- EXECUTE PROCEDURE public.log_page_changes();
--
--
--
--
-- -- FUNCTION: public.log_board_changes()
-- -- DROP FUNCTION public.log_board_changes();
--
-- CREATE FUNCTION public.log_board_changes()
--     RETURNS trigger
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE NOT LEAKPROOF
-- AS $BODY$BEGIN
--     IF (TG_OP = 'UPDATE') THEN
--         IF NEW.board_name<>OLD.board_name THEN
--             INSERT INTO user_logs(user_id, board_id, old_name, new_name, log_date, type, content) VALUES(OLD.user_id, OLD.board_id, OLD.board_name, NEW.board_name, CURRENT_DATE, 'UPDATE', 'Board');
--         END IF;
--         IF NEW.description<>OLD.description THEN
--             INSERT INTO user_logs(user_id, board_id, old_data, new_data, log_date, type, content) VALUES(OLD.user_id, OLD.board_id, OLD.description, NEW.description, CURRENT_DATE, 'UPDATE', 'Board');
--         END IF;
--         IF NEW.status<>OLD.status THEN
--             INSERT INTO user_logs(user_id, board_id, old_status, new_status, log_date, type, content) VALUES(OLD.user_id, OLD.board_id, OLD.status, NEW.status, CURRENT_DATE, 'REMOVED', 'Board');
--         END IF;
--     END IF;
-- END;$BODY$;
--
-- ALTER FUNCTION public.log_board_changes()
--     OWNER TO postgres;
--
--
--
-- -- Trigger: log_changer
-- -- DROP TRIGGER log_changer ON public.boards;
--
-- CREATE TRIGGER log_changer
--     AFTER UPDATE
--     ON public.boards
--     FOR EACH ROW
-- EXECUTE PROCEDURE public.log_board_changes();
--
--
--
-- -- Functions:
--
-- CREATE OR REPLACE FUNCTION get_active_months (userid INT)
-- RETURNS TABLE ( month_year VARCHAR ) AS
-- $BODY$
-- DECLARE
--     var_r record;
-- BEGIN
--     FOR var_r IN ( SELECT date FROM user_logs WHERE user_logs.user_id = userid )
--     LOOP
--         month_year := CONCAT(TO_CHAR(var_r, 'Month'), ' ', TO_CHAR(var_r, 'YEAR'));
--     RETURN NEXT;
--     END LOOP;
-- END;
-- $BODY$
-- LANGUAGE 'plpgsql';
--
--
--
--
-- CREATE OR REPLACE FUNCTION get_logs (userid INT)
-- RETURNS TABLE ( log_content CHAR(6), log_text VARCHAR, date_time VARCHAR, log_date VARCHAR, log_time VARCHAR, month_year VARCHAR ) AS
-- $BODY$
-- DECLARE
--     var_r record;
-- 	p_name varchar;
-- 	b_name varchar;
-- BEGIN
--
--     FOR var_r IN ( SELECT * FROM user_logs WHERE user_logs.user_id = userid ) LOOP
--         log_content := var_r.content;
-- 		IF var_r.type = 'UPDATE' THEN
-- 			IF var_r.old_name <> var_r.new_name THEN
-- 				log_text := CONCAT(var_r.content, 'name changed from ', var_r.old_name, 'to ', var_r.new_name);
-- 			ELSE
-- 				IF var_r.content = 'Pages' THEN
-- 					SELECT pages.page_name INTO p_name FROM pages WHERE pages.page_id = var_r.page_id;
-- 					log_text := CONCAT(var_r.content, ' named ', p_name, ' was edited');
-- 				ELSE
-- 					SELECT boards.board_name INTO b_name FROM boards WHERE board.board_id = var_r.board_id;
-- 					log_text := CONCAT(var_r.content, ' named ', b_name, ' was edited');
-- 				END IF;
-- 			END IF;
-- 		ELSIF var_r.type = 'INSERT' THEN
-- 			IF var_r.content = 'Pages' THEN
-- 				SELECT pages.page_name INTO p_name FROM pages WHERE pages.page_id = var_r.page_id;
-- 				log_text := CONCAT(var_r.content, ' named ', p_name, ' was created');
-- 			ELSE
-- 				SELECT boards.board_name INTO b_name FROM boards WHERE board.board_id = var_r.board_id;
-- 				log_text := CONCAT(var_r.content, ' named ', b_name, ' was created');
-- 			END IF;
-- 		ELSE
-- 			IF var_r.content = 'Pages' THEN
-- 				SELECT pages.page_name INTO p_name FROM pages WHERE pages.page_id = var_r.page_id;
-- 				log_text := CONCAT(var_r.content, ' named ', p_name, ' was deleted');
-- 			ELSE
-- 				SELECT boards.board_name INTO b_name FROM boards WHERE board.board_id = var_r.board_id;
-- 				log_text := CONCAT(var_r.content, ' named ', b_name, ' was deleted');
-- 			END IF;
-- 		END IF;
-- 		date_time := var_r.log_date;
-- 		log_date := CONCAT(TO_CHAR(var_r.log_date, 'DD'), ' ', TO_CHAR(var_r.log_date, 'MM'));
-- 		log_time := TO_CHAR(var_r.log_date, 'HH24:MI:SS');
-- 		month_year := CONCAT(TO_CHAR(var_r.log_date, 'Month'), ' ', TO_CHAR(var_r.log_date, 'YEAR'));
--     RETURN NEXT;
--     END LOOP;
-- END;
-- $BODY$
-- LANGUAGE 'plpgsql';
--
--
--
--
-- CREATE OR REPLACE FUNCTION user_profile_updates(userid int, profilephoto varchar, profilename varchar, profilebio varchar, fbhandle varchar, twitterhandle varchar, ighandle varchar, linkedinhandle varchar, githubhandle varchar, passwd varchar)
-- RETURNS INTEGER AS
-- $BODY$
-- DECLARE
-- 	var_r record;
-- BEGIN
-- 		SELECT * INTO var_r FROM users WHERE user_id = userid;
--
-- 		IF var_r.profile_photo<>profilephoto THEN
--             UPDATE users SET profile_photo = profilephoto WHERE user_id = userid;
--         END IF;
--
-- 		IF var_r.user_name<>profilename THEN
--             UPDATE users SET user_name = profilename WHERE user_id = userid;
--         END IF;
--
-- 		IF var_r.bio<>profilebio THEN
--             UPDATE users SET bio = profilebio WHERE user_id = userid;
--         END IF;
--
-- 		IF var_r.fb_handle<>fbhandle THEN
--             UPDATE users SET fb_handle = fbhandle WHERE user_id = userid;
--         END IF;
--
-- 		IF var_r.twitter_handle<>twitterhandle THEN
--             UPDATE users SET twitter_handle = twitterhandle WHERE user_id = userid;
--         END IF;
--
-- 		IF var_r.ig_handle<>ighandle THEN
--             UPDATE users SET ig_handle = ighandle WHERE user_id = userid;
--         END IF;
--
-- 		IF var_r.linkedin_handle<>linkedinhandle THEN
--             UPDATE users SET linkedin_handle = linkedinhandle WHERE user_id = userid;
--         END IF;
--
-- 		IF var_r.github_handle<>githubhandle THEN
--             UPDATE users SET github_handle = githubhandle WHERE user_id = userid;
--         END IF;
--
-- 		IF var_r.pwd<>'' THEN
--             UPDATE users SET pwd = passwd WHERE user_id = userid;
--         END IF;
--
-- 	RETURN 1;
-- END;
-- $BODY$
-- LANGUAGE plpgsql;