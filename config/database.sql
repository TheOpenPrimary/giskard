




CREATE DOMAIN gender AS varchar(1)
CHECK(
   VALUE IN (NULL, 'm', 'f')
);

CREATE TABLE fb_users (
    id bigint primary key,
    usr_id integer not null,
    profile_pic text,
    locale character varying(30),
    timezone varchar(8),
    gender gender,
        first_name character varying(30),
        last_name character varying(30),
        email character varying(30),
        from_date timestamp without time zone DEFAULT now(),
        last_date timestamp without time zone DEFAULT now(),
        PRIMARY KEY (id),
        CONSTRAINT users_check
            CHECK (last_date >= from_date)

);


CREATE TABLE tg_users (
    id integer primary key,
    usr_id integer not null,
    user_name character varying(30),
    foreign key (usr_id)
        references users(id)
        on delete Cascade
        on update cascade
);


CREATE TABLE categories(
    id serial PRIMARY KEY,
    name VARCHAR(20),
    parent integer,
    foreign key (parent)
        references categories(id)
        on delete set null
        on update cascade
);


CREATE TABLE images(
    id serial PRIMARY KEY,
    url VARCHAR(200),
    category integer,
    foreign key (category)
            references categories(id)
            on delete Cascade
            on update cascade
);






CREATE TABLE messages(
usr_id integer not null,
msg varchar(300),
img_id integer,
date timestamp DEFAULT current_timestamp,
primary key (usr_id, date),
foreign key (usr_id)
        references users(id)
        on delete Cascade
        on update cascade,
foreign key (img_id)
        references images(id)
        on delete Cascade
        on update cascade
);


CREATE TABLE feedback(
id serial PRIMARY KEY,
usr_id integer not null,
useful boolean,
msg text
);
-- TODO
-- delimiter //
-- CREATE trigger updateLastDate
-- after insert on doleances
-- begin
-- for each row
-- update users set last_date = now() where id = new.usr_id;
-- end;//
-- delimiter ;
