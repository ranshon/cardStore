DROP TABLE rechargeTable;
DROP TABLE orders;
DROP TABLE users;
DROP TABLE balanceTable;


CREATE TABLE users (
user_id     SERIAL PRIMARY KEY,
name   TEXT NOT NULL,
idNo   varchar(25) ,
telNo  varchar(15) NOT NULL UNIQUE
);


CREATE INDEX idx_name_search ON users(name);
CREATE INDEX idx_idNo_search ON users(idNo);
CREATE INDEX idx_telNo_search ON users(telNo);


CREATE TABLE rechargeTable (
recharge_id    SERIAL PRIMARY KEY,
user_id     INTEGER NOT NULL UNIQUE,
money       INTEGER NOT NULL,
rechargetime date default 'now()'
);

CREATE TABLE orders (
order_id    SERIAL PRIMARY KEY,
user_id     INTEGER NOT NULL UNIQUE,
orderMoney  INTEGER NOT NULL,
orderTime date default 'now()'
);

CREATE TABLE balanceTable (
balance_id  SERIAL PRIMARY KEY,
user_id     INTEGER NOT NULL UNIQUE,
balance     INTEGER NOT NULL
)

