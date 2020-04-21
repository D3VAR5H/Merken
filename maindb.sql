-- Table: users

-- DROP TABLE users;

CREATE TABLE users
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
)

-- FUNCTION: process_add_board()

-- DROP FUNCTION process_add_board();

CREATE
FUNCTION process_add_board()
RETURNS TRIGGER AS 
$BODY$
BEGIN
INSERT INTO boards(board_name, description, user_id)
VALUES ('Untitled Board', 'Enter description', NEW.user_id);
RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

-- Trigger: add_board

-- DROP TRIGGER add_board ON users;

CREATE TRIGGER add_board
    AFTER INSERT
    ON users
    FOR EACH ROW
    EXECUTE PROCEDURE process_add_board();



-- Table: boards

-- DROP TABLE boards;

CREATE TABLE boards
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
        REFERENCES users (user_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

-- FUNCTION: process_add_page()

-- DROP FUNCTION process_add_page();

CREATE
FUNCTION process_add_page()
    RETURNS Trigger
AS $BODY$BEGIN
INSERT INTO pages(page_name, page_data, board_id)
VALUES ('Untitled Page', 'Enter your Text', NEW.board_id);
RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

-- Trigger: add_pages

-- DROP TRIGGER add_pages ON pages;

CREATE TRIGGER add_pages
    AFTER INSERT
    ON boards
    FOR EACH ROW
    EXECUTE PROCEDURE process_add_page();

-- FUNCTION: delete_boards()

-- DROP FUNCTION delete_boards();

CREATE
FUNCTION delete_boards()
RETURNS TRIGGER AS 
$BODY$
BEGIN IF (TG_OP = 'UPDATE') THEN
        IF NEW.status<>OLD.status THEN
UPDATE pages
SET status = false
WHERE board_id = OLD.board_id;
END IF;
END IF;
RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql;

-- Trigger: delete_board_pages

-- DROP TRIGGER delete_board_pages ON boards;

CREATE TRIGGER delete_board_pages
    AFTER UPDATE
    ON boards
    FOR EACH ROW
    EXECUTE PROCEDURE delete_boards();

-- FUNCTION: log_board_changes()

-- DROP FUNCTION log_board_changes();

CREATE
FUNCTION log_board_changes()
RETURNS TRIGGER AS 
$BODY$
DECLARE
	var_r record;
BEGIN IF (TG_OP = 'UPDATE') THEN
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
END IF;
IF (TG_OP = 'INSERT') THEN
INSERT INTO user_logs(user_id, board_id, new_name, new_data, log_date, type, content)
VALUES (NEW.user_id, NEW.board_id, NEW.board_name, NEW.description, CURRENT_TIMESTAMP, 'INSERT', 'Board');
END IF;
RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

-- Trigger: log_changer

-- DROP TRIGGER log_changer ON boards;

CREATE TRIGGER log_changer
    AFTER UPDATE OR INSERT
    ON boards
    FOR EACH ROW
    EXECUTE PROCEDURE log_board_changes();



-- Table: pages

-- DROP TABLE pages;

CREATE TABLE pages
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
        REFERENCES boards (board_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

-- FUNCTION: log_page_changes()

-- DROP FUNCTION log_page_changes();

CREATE
FUNCTION log_page_changes()
RETURNS TRIGGER AS 
$BODY$
DECLARE
    var_r record;
BEGIN
SELECT * INTO var_r
FROM boards
WHERE boards.board_id = NEW.board_id;
IF (TG_OP = 'UPDATE') THEN
    IF NEW.page_name<>OLD.page_name THEN
INSERT INTO user_logs(user_id, board_id, page_id, old_name, new_name, log_date, type, content)
VALUES (var_r.user_id, OLD.board_id, OLD.page_id, OLD.page_name, NEW.page_name, CURRENT_TIMESTAMP, 'UPDATE', 'Pages');
END IF;
IF NEW.page_data<>OLD.page_data THEN
INSERT INTO user_logs(user_id, board_id, page_id, old_data, new_data, log_date, type, content)
VALUES (var_r.user_id, OLD.board_id, OLD.page_id, OLD.page_data, NEW.page_data, CURRENT_TIMESTAMP, 'UPDATE', 'Pages');
END IF;
IF NEW.status<>OLD.status THEN
INSERT INTO user_logs(user_id, board_id, page_id, log_date, type, content)
VALUES (var_r.user_id, OLD.board_id, OLD.page_id, CURRENT_TIMESTAMP, 'REMOVED', 'Pages');
END IF;
END IF;
IF (TG_OP = 'INSERT') THEN
INSERT INTO user_logs(user_id, board_id, page_id, new_name, log_date, type, content)
VALUES (var_r.user_id, NEW.board_id, NEW.page_id, NEW.page_name, CURRENT_TIMESTAMP, 'INSERT', 'Pages');
END IF;
RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

-- Trigger: log_changer_pages

-- DROP TRIGGER log_changer_pages ON pages;

CREATE TRIGGER log_changer_pages
    AFTER UPDATE OR INSERT
    ON pages
    FOR EACH ROW
    EXECUTE PROCEDURE log_page_changes();



-- Table: user_logs

-- DROP TABLE user_logs;

CREATE TABLE user_logs
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
        REFERENCES boards (board_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_page_id FOREIGN KEY (page_id)
        REFERENCES pages (page_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_user_id FOREIGN KEY (user_id)
        REFERENCES users (user_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)



-- FUNCTION: get_active_months(integer)

-- DROP FUNCTION get_active_months(integer);

CREATE
OR REPLACE
FUNCTION get_active_months(userid integer)
RETURNS TABLE(month_year character varying) 
AS 
$BODY$DECLARE
    var_r record;
BEGIN FOR var_r IN ( SELECT log_date FROM user_logs WHERE user_logs.user_id = userid ) LOOP
        month_year := CONCAT(TO_CHAR(var_r.log_date, 'Month'), ' ', TO_CHAR(var_r.log_date, 'YYYY'));
RETURN NEXT;
END LOOP;
END;
$BODY$
LANGUAGE plpgsql;




-- FUNCTION: get_logs(integer)

-- DROP FUNCTION get_logs(integer);

CREATE
OR REPLACE
FUNCTION get_logs(userid integer)
RETURNS TABLE(log_content character, log_text character varying, date_time character varying, log_date character varying, log_time character varying, month_year character varying) AS 
$BODY$
DECLARE
    var_r record;
p_name varchar;
b_name varchar;
BEGIN FOR var_r IN ( SELECT * FROM user_logs WHERE user_logs.user_id = userid ) LOOP
        log_content := var_r.content;
IF var_r.type = 'UPDATE' THEN
			IF var_r.old_name <> var_r.new_name THEN
				IF var_r.content = 'Pages' THEN
				log_text := CONCAT('Page name changed from ', var_r.old_name, 'to ', var_r.new_name);
ELSE
				log_text := CONCAT('Board name changed from ', var_r.old_name, 'to ', var_r.new_name);
END IF;
ELSE
				IF var_r.content = 'Pages' THEN
SELECT pages.page_name INTO p_name
FROM pages
WHERE pages.page_id = var_r.page_id;
log_text := CONCAT('Page named ', p_name, ' was edited');
ELSE
SELECT boards.board_name INTO b_name
FROM boards
WHERE boards.board_id = var_r.board_id;
log_text := CONCAT('Board named ', b_name, ' was edited');
END IF;
END IF;
ELSIF var_r.type = 'INSERT' THEN
			IF var_r.content = 'Pages' THEN
SELECT pages.page_name INTO p_name
FROM pages
WHERE pages.page_id = var_r.page_id;
log_text := CONCAT('Page named ', p_name, ' was created');
ELSE
SELECT boards.board_name INTO b_name
FROM boards
WHERE boards.board_id = var_r.board_id;
log_text := CONCAT('Board named ', b_name, ' was created');
END IF;
ELSE
			IF var_r.content = 'Pages' THEN
SELECT pages.page_name INTO p_name
FROM pages
WHERE pages.page_id = var_r.page_id;
log_text := CONCAT('Page named ', p_name, ' was deleted');
ELSE
SELECT boards.board_name INTO b_name
FROM boards
WHERE boards.board_id = var_r.board_id;
log_text := CONCAT('Board named ', b_name, ' was deleted');
END IF;
END IF;
date_time := var_r.log_date;
log_date := CONCAT(TO_CHAR(var_r.log_date, 'DD'), '/', TO_CHAR(var_r.log_date, 'MM'));
log_time := CONCAT(TO_CHAR(var_r.log_date, 'HH12:MI'), ' ', TO_CHAR(var_r.log_date, 'AM'));
month_year := CONCAT(TO_CHAR(var_r.log_date, 'Month'), ' ', TO_CHAR(var_r.log_date, 'YYYY'));
RETURN NEXT;
END LOOP;
END;
$BODY$
LANGUAGE plpgsql;



-- FUNCTION: user_profile_updates(integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying)

-- DROP FUNCTION user_profile_updates(integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying);

CREATE
OR REPLACE
FUNCTION public.user_profile_updates(
	userid integer,
	profilephoto varchar,
	profilename varchar,
	profilebio varchar,
	fbhandle varchar,
	twitterhandle varchar,
	ighandle varchar,
	linkedinhandle varchar,
	githubhandle varchar,
	passwd varchar)

	RETURNS character varying

AS $BODY$
BEGIN IF profilephoto!='' THEN
UPDATE users
SET profile_photo = profilephoto
WHERE user_id = userid;
END IF;

IF profilebio!='' THEN
UPDATE users
SET bio = profilebio
WHERE user_id = userid;
END IF;

IF profilename!='' THEN
UPDATE users
SET user_name = profilename
WHERE user_id = userid;
END IF;

IF fbhandle!='' THEN
UPDATE users
SET fb_handle = fbhandle
WHERE user_id = userid;
END IF;

IF twitterhandle!='' THEN
UPDATE users
SET twitter_handle = twitterhandle
WHERE user_id = userid;
END IF;

IF ighandle!='' THEN
UPDATE users
SET ig_handle = ighandle
WHERE user_id = userid;
END IF;

IF linkedinhandle!='' THEN
UPDATE users
SET linkedin_handle = linkedinhandle
WHERE user_id = userid;
END IF;

IF githubhandle!='' THEN
UPDATE users
SET github_handle = githubhandle
WHERE user_id = userid;
END IF;

IF passwd!='89e16254ebad5cba72e0aebe1614c7f9b795a7505f2637206ce10a3449a2b8bb23875b089124a8269fc0896494bab580c48ec17ef0c9187c86f9c9f8e4f5c5b7' THEN
UPDATE users
SET pwd = passwd
WHERE user_id = userid;
END IF;
RETURN 1;
END;
$BODY$
LANGUAGE plpgsql;