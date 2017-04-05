




CREATE DOMAIN gender AS varchar(1)
CHECK(
   VALUE IN (NULL, 'm', 'f')
);

CREATE TABLE fb_users (
    id bigint primary key,
    uid integer,
    profile_pic text,
    locale character varying(200),
    timezone varchar(8),
    gender gender,
    last_msg_time timestamp default now(),
    CONSTRAINT fk_uid FOREIGN KEY (uid)
    REFERENCES users(id)
    ON DELETE CASCADE
);


CREATE TABLE tg_users (
    id integer primary key,
    uid integer,
    user_name character varying(30),
    CONSTRAINT fk_uid FOREIGN KEY (uid)
    REFERENCES users(id)
    ON DELETE CASCADE
);


CREATE TABLE users (
    id serial primary key,
    first_name character varying(30),
    last_name character varying(30),
    email character varying(30),
    from_date timestamp without time zone DEFAULT now(),
    last_date timestamp without time zone DEFAULT now(),
    CONSTRAINT users_check
        CHECK (last_date >= from_date)
);


CREATE VIEW maxi_users
AS SELECT users.id id, users.first_name first_name, users.last_name last_name, users.email email, users.from_date from_date, users.last_date last_date, tg_users.id tg_id, fb_users.id fb_id
FROM users, fb_users, tg_users
WHERE fb_users.uid = users.id or tg_users.id = users.id;



CREATE TABLE states (
    id serial primary key,
    last_msg_id bigint default 0,
    current text,
    expected_input character varying(50),
    expected_size smallint,
    buffer text,
    callback text,
    previous_screen text,
    uid int,
    messenger  character varying(50),
    CONSTRAINT fk_uid FOREIGN KEY (uid)
    REFERENCES users(id)
    ON DELETE CASCADE
);
