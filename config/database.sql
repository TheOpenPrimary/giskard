




CREATE DOMAIN gender AS varchar(1)
CHECK(
   VALUE IN (NULL, 'm', 'f')
);

CREATE TABLE fb_users (
    id bigint primary key,
    profile_pic text,
    locale character varying(200),
    timezone varchar(8),
    gender gender,
    email character varying(200),
    first_name character varying(200),
    last_name character varying(200),
    last_msg_time timestamp default now(),
    from_date timestamp without time zone DEFAULT now(),
    last_date timestamp without time zone DEFAULT now(),
    CONSTRAINT users_check
        CHECK (last_date >= from_date)

);


CREATE TABLE tg_users (
    id integer primary key,
    user_name character varying(30),
    first_name character varying(30),
    last_name character varying(30),
    email character varying(30),
    last_msg_time timestamp default now(),
    from_date timestamp without time zone DEFAULT now(),
    last_date timestamp without time zone DEFAULT now(),
    CONSTRAINT users_check
        CHECK (last_date >= from_date)
);



CREATE TABLE states (
    id serial primary key,
    last_msg_id bigint default 0,
    current text,
    expected_input character varying(50),
    expected_size smallint,
    buffer text,
    callback text,
    previous_screen text,
    user_id bigint,
    messenger  character varying(50)
);
