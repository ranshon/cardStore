


/*
select * from users;

select * from rechargeTable;



UPDATE rechargeTable SET money = 1000 where rechargeTable.user_id = (SELECT users.user_id FROM users WHERE users.telNo = '13188886603');

*/

/*
BEGIN;

insert into users (user_id,name,idNo,telNo)  VALUES ('2','yyy','123','457100') returning user_id;

INSERT INTO rechargeTable (user_id, money) VALUES ('2', 10)returning recharge_id;

COMMIT;
*/


/*

update balanceTable set balance = balance + 1000 where balanceTable.user_id = 1;


insert into balanceTable (user_id,balance) values (1,1000) on conflict(user_id) Do update set balance = balanceTable.balance + 1000 where balanceTable.user_id = 1;

*/


SELECT users.user_id, users.name, users.telNo, SUM(balanceTable.balance) FROM users, balanceTable WHERE users.user_id = balanceTable.user_id GROUP BY users.user_id, users.name, users.telNo LIMIT 10 OFFSET 0;

SELECT users.user_id, users.name, users.telNo, balanceTable.balance FROM users, balanceTable WHERE (users.telNo = '13188886603') AND (users.user_id = balanceTable.user_id)














