TRUNCATE TABLE SIMULATE_D_TRADE_PERFORMANCE
;

DECLARE
    --PRAGMA AUTONOMOUS_TRANSACTION;
    TYPE RISK_TYPE IS TABLE OF NUMBER;
    V_RISK RISK_TYPE := RISK_TYPE (1, 2, 3, 4);
    
    V_OUTPUT VARCHAR2(100);
    

BEGIN
    FOR I IN 1 .. V_RISK.COUNT
    LOOP
        
        DELETE FROM D_ACCOUNT_SETTING WHERE ACCOUNT_ID IN ('SIM', 'SIM-ALL') AND SETTING_CATEGORY IN ('Risk');
        
        INSERT INTO D_ACCOUNT_SETTING 
        VALUES ('SIM', 'RunGroup2', 'Level', V_RISK(I), '2019-01-01 00:00:00', '2100-12-31 00:00:00', '28-JUN-24', 'Risk');
        
        INSERT INTO D_ACCOUNT_SETTING 
        VALUES ('SIM-ALL', 'RunGroup2', 'Level', V_RISK(I), '2019-01-01 00:00:00', '2100-12-31 00:00:00', '28-JUN-24', 'Risk');
        
        COMMIT;
        
        SELECT SIMULATE_D_ACCOUNT_TRADE('RunGroup2')
        INTO V_OUTPUT
        FROM DUAL;
        
        INSERT INTO SIMULATE_D_TRADE_PERFORMANCE 
        SELECT 'MODEL1', V_RISK(I), A.*
        FROM D_TRADE_PERFORMANCE  A
        WHERE ACCOUNT_ID IN ('SIM', 'SIM-ALL')
        AND PERIOD_GROUP IN ('Month', 'Year', 'All');
    
    
        COMMIT;
    END LOOP;
    
END;
/




with d0
as
(
    select a.account_id, a.period_group, a.period_id, a.run_group_name, a.risk, 
        count(case when b.period_group = 'Day' then 1 end ) days,
        count(case when b.period_group = 'Week' then 1 end ) weeks,
        count(case when b.period_group = 'Month' then 1 end ) months,
        count(case when b.period_group = 'Year' then 1 end ) years
    from SIMULATE_D_TRADE_PERFORMANCE a
    join SIMULATE_D_TRADE_PERFORMANCE b
    on  a.account_id = b.account_id
    and b.first_reporting_day between a.first_reporting_day and a.last_reporting_day
    and a.run_group_name  = b.run_group_name
    and a.risk = b.risk
    group by a.account_id, a.period_group, a.period_id, a.run_group_name, a.risk
)
SELECT a.ACCOUNT_ID, a.RETURN_RATE, ROUND(a.NEW_TRADES/a.POSSIBLE_TRADES,2) FILL_RATE, 
        a.UTILIZED_RATIO, a.CLOSED_WIN_RATIO, a.MAX_DRAWDOWN, 
        round(power(1 + a.return_rate, 1/nullif(b.days, 0)) - 1, 3) average_day_return,
        round(power(1 + a.return_rate, 1/nullif(b.weeks, 0)) - 1, 3) average_week_return,
        round(power(1 + a.return_rate, 1/nullif(b.months, 0)) - 1, 3) average_month_return,
        round(power(1 + a.return_rate, 1/nullif(b.years, 0)) - 1, 3) average_year_return,
        b.days,b.weeks,b.months,b.years,
        A.* 
FROM SIMULATE_D_TRADE_PERFORMANCE A
join d0 b
on a.run_group_name = b.run_group_name
and a.period_group = b.period_group
and a.account_id = b.account_id
and a.period_id = b.period_id
and a.risk = b.risk
WHERE a.PERIOD_GROUP = 'All'
--where period_id = '2019'
--and a.risk = 1
ORDER BY 1, 10, 11;


--------------------------------------------------------
--  DDL for Table SIMULATE_D_TRADE_PERFORMANCE
--------------------------------------------------------
drop table SIMULATE_D_TRADE_PERFORMANCE purge;
  CREATE TABLE "C##TIDB"."SIMULATE_D_TRADE_PERFORMANCE" 
   (	"MODEL_NAME" VARCHAR2(100 BYTE), 
	"RISK" NUMBER, 
	"ACCOUNT_ID" VARCHAR2(100 BYTE), 
	"RUN_GROUP_NAME" VARCHAR2(100 BYTE), 
	"PERIOD_GROUP" VARCHAR2(5 BYTE), 
	"PERIOD_ID" VARCHAR2(141 BYTE), 
	"PERIOD_NAME" VARCHAR2(141 BYTE), 
	"FIRST_REPORTING_DAY" VARCHAR2(100 BYTE), 
	"LAST_REPORTING_DAY" VARCHAR2(100 BYTE), 
	"CASH_PERIOD" NUMBER, 
	"CASH_OVERALL" NUMBER, 
	"UTILIZED_AMOUNT" NUMBER, 
	"UTILIZED_RATIO" NUMBER, 
	"UTILIZED_AMOUNT_LONG" NUMBER, 
	"UTILIZED_AMOUNT_SHORT" NUMBER, 
	"PROFIT_PERIOD" NUMBER, 
	"PROFIT_OVERALL" NUMBER, 
	"COMMISSION_PERIOD" NUMBER, 
	"COMMISSION_OVERALL" NUMBER, 
	"CAPITAL" NUMBER, 
	"CAPITAL_INCREMENT" NUMBER, 
	"RETURN_RATE" NUMBER, 
	"MAX_DRAWDOWN" NUMBER, 
	"MAX_DRAWDOWN_FIRST_DAY" VARCHAR2(150 BYTE), 
	"MAX_DRAWDOWN_LAST_DAY" VARCHAR2(150 BYTE), 
	"MAX_MARKUP" NUMBER, 
	"MAX_MARKUP_FIRST_DAY" VARCHAR2(150 BYTE), 
	"MAX_MARKUP_LAST_DAY" VARCHAR2(150 BYTE), 
	"POSSIBLE_TRADES" NUMBER, 
	"EXCLUDE_TRADES" NUMBER, 
	"PENDING_TRADES" NUMBER, 
	"CANCELED_TRADES" NUMBER, 
	"NEW_TRADES" NUMBER, 
	"TRADES_FILL_RATE" NUMBER, 
	"OPEN_TRADES" NUMBER, 
	"OPEN_PROFIT" NUMBER, 
	"OPEN_TRADES_HOLDING_TIME" NUMBER, 
	"OPEN_WIN_TRADES" NUMBER, 
	"OPEN_LOSS_TRADES" NUMBER, 
	"OPEN_WIN_RATIO" NUMBER, 
	"OPEN_R_PERCENT" NUMBER, 
	"OPEN_R_MULTIPLE" NUMBER, 
	"OPEN_WIN_R_MULTIPLE" NUMBER, 
	"OPEN_LOSS_R_MULTIPLE" NUMBER, 
	"NEW_TRADES_LONG" NUMBER, 
	"OPEN_TRADES_LONG" NUMBER, 
	"OPEN_PROFIT_LONG" NUMBER, 
	"OPEN_TRADES_HOLDING_TIME_LONG" NUMBER, 
	"OPEN_WIN_TRADES_LONG" NUMBER, 
	"OPEN_LOSS_TRADES_LONG" NUMBER, 
	"OPEN_WIN_RATIO_LONG" NUMBER, 
	"OPEN_R_PERCENT_LONG" NUMBER, 
	"OPEN_R_MULTIPLE_LONG" NUMBER, 
	"OPEN_WIN_R_MULTIPLE_LONG" NUMBER, 
	"OPEN_LOSS_R_MULTIPLE_LONG" NUMBER, 
	"NEW_TRADES_SHORT" NUMBER, 
	"OPEN_TRADES_SHORT" NUMBER, 
	"OPEN_PROFIT_SHORT" NUMBER, 
	"OPEN_TRADES_HOLDING_TIME_SHORT" NUMBER, 
	"OPEN_WIN_TRADES_SHORT" NUMBER, 
	"OPEN_LOSS_TRADES_SHORT" NUMBER, 
	"OPEN_WIN_RATIO_SHORT" NUMBER, 
	"OPEN_R_PERCENT_SHORT" NUMBER, 
	"OPEN_R_MULTIPLE_SHORT" NUMBER, 
	"OPEN_WIN_R_MULTIPLE_SHORT" NUMBER, 
	"OPEN_LOSS_R_MULTIPLE_SHORT" NUMBER, 
	"CLOSED_TRADES" NUMBER, 
	"CLOSED_PROFIT" NUMBER, 
	"CLOSED_WIN_PROFIT" NUMBER, 
	"CLOSED_LOSS_PROFIT" NUMBER, 
	"CLOSED_TRADES_HOLDING_TIME" NUMBER, 
	"CLOSED_WIN_TRADES" NUMBER, 
	"CLOSED_LOSS_TRADES" NUMBER, 
	"CLOSED_WIN_RATIO" NUMBER, 
	"CLOSED_R_PERCENT" NUMBER, 
	"CLOSED_R_MULTIPLE" NUMBER, 
	"CLOSED_WIN_R_MULTIPLE" NUMBER, 
	"CLOSED_LOSS_R_MULTIPLE" NUMBER, 
	"CLOSED_WIN_MAX" NUMBER, 
	"CLOSED_LOSS_MAX" NUMBER, 
	"CLOSED_WIN_AVG" NUMBER, 
	"CLOSED_LOSS_AVG" NUMBER, 
	"CLOSED_TRADES_LONG" NUMBER, 
	"CLOSED_PROFIT_LONG" NUMBER, 
	"CLOSED_WIN_PROFIT_LONG" NUMBER, 
	"CLOSED_LOSS_PROFIT_LONG" NUMBER, 
	"CLOSED_TRADES_HOLDING_TIME_LONG" NUMBER, 
	"CLOSED_WIN_TRADES_LONG" NUMBER, 
	"CLOSED_LOSS_TRADES_LONG" NUMBER, 
	"CLOSED_WIN_RATIO_LONG" NUMBER, 
	"CLOSED_R_PERCENT_LONG" NUMBER, 
	"CLOSED_R_MULTIPLE_LONG" NUMBER, 
	"CLOSED_WIN_R_MULTIPLE_LONG" NUMBER, 
	"CLOSED_LOSS_R_MULTIPLE_LONG" NUMBER, 
	"CLOSED_WIN_MAX_LONG" NUMBER, 
	"CLOSED_LOSS_MAX_LONG" NUMBER, 
	"CLOSED_WIN_AVG_LONG" NUMBER, 
	"CLOSED_LOSS_AVG_LONG" NUMBER, 
	"CLOSED_TRADES_SHORT" NUMBER, 
	"CLOSED_PROFIT_SHORT" NUMBER, 
	"CLOSED_WIN_PROFIT_SHORT" NUMBER, 
	"CLOSED_LOSS_PROFIT_SHORT" NUMBER, 
	"CLOSED_TRADES_HOLDING_TIME_SHORT" NUMBER, 
	"CLOSED_WIN_TRADES_SHORT" NUMBER, 
	"CLOSED_LOSS_TRADES_SHORT" NUMBER, 
	"CLOSED_WIN_RATIO_SHORT" NUMBER, 
	"CLOSED_R_PERCENT_SHORT" NUMBER, 
	"CLOSED_R_MULTIPLE_SHORT" NUMBER, 
	"CLOSED_WIN_R_MULTIPLE_SHORT" NUMBER, 
	"CLOSED_LOSS_R_MULTIPLE_SHORT" NUMBER, 
	"CLOSED_WIN_MAX_SHORT" NUMBER, 
	"CLOSED_LOSS_MAX_SHORT" NUMBER, 
	"CLOSED_WIN_AVG_SHORT" NUMBER, 
	"CLOSED_LOSS_AVG_SHORT" NUMBER, 
	"CLOSED_EV" NUMBER, 
	"CLOSED_EV_LONG" NUMBER, 
	"CLOSED_EV_SHORT" NUMBER, 
	"CLOSED_EXPECTATION" NUMBER, 
	"CLOSED_EXPECTATION_LONG" NUMBER, 
	"CLOSED_EXPECTATION_SHORT" NUMBER, 
	"CLOSED_PROFIT_FACTOR" NUMBER, 
	"CLOSED_PROFIT_FACTOR_LONG" NUMBER, 
	"CLOSED_PROFIT_FACTOR_SHORT" NUMBER, 
	"WIN_STREAK_TRADES" NUMBER, 
	"LOSS_STREAK_TRADES" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" ;







--------------------------------------------------------
--  DDL for Table D_ACCOUNT_TRADE
--------------------------------------------------------
DROP TABLE D_ACCOUNT_TRADE PURGE;
  CREATE TABLE "C##TIDB"."D_ACCOUNT_TRADE" 
   (	"ACCOUNT_ID" VARCHAR2(100 BYTE), 
	"RUN_GROUP_NAME" VARCHAR2(100 BYTE), 
	"SYMBOL" VARCHAR2(100 BYTE), 
    RISK NUMBER,
	"TRADE_SHARE" NUMBER, 
	"POSITION_SIZE" NUMBER, 
	"QTY" NUMBER, 
	"TRADE_TYPE" VARCHAR2(100 BYTE), 
	"ENTER_MODEL_TIMESTAMP" VARCHAR2(100 BYTE), 
	"ENTER_MODEL_PRICE" NUMBER, 
	"INITIAL_STOP_LOSS" NUMBER, 
	"TRAILING_STOP_LOSS" NUMBER, 
	"INITIAL_TAKE_PROFIT" NUMBER, 
	"TRAILING_TAKE_PROFIT" NUMBER, 
	"EXIT_MODEL_TIMESTAMP" VARCHAR2(100 BYTE), 
	"EXIT_MODEL_PRICE" NUMBER, 
	"EXIT_TYPE" VARCHAR2(100 BYTE), 
	"ENTER_TRADE_TIMESTAMP" VARCHAR2(100 BYTE), 
	"CANCEL_TRADE_TIMESTAMP" VARCHAR2(100 BYTE), 
	"EXIT_TRADE_TIMESTAMP" VARCHAR2(100 BYTE), 
	"ENTER_TRADE_PRICE" NUMBER, 
	"EXIT_TRADE_PRICE" NUMBER, 
	"PROFIT" NUMBER, 
	"CREATION_DATE" VARCHAR2(100 BYTE), 
	"COMMISSION_ENTER" NUMBER, 
	"COMMISSION_EXIT" NUMBER, 
	"ENTER_PERMID" VARCHAR2(100 BYTE), 
	"EXIT_PERMID" VARCHAR2(100 BYTE), 
	"STOP_ORDER_ID" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" ;

  ALTER TABLE "C##TIDB"."D_ACCOUNT_TRADE" ADD PRIMARY KEY ("ACCOUNT_ID", "SYMBOL", "RUN_GROUP_NAME", "ENTER_MODEL_TIMESTAMP")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS"  ENABLE;






--------------------------------------------------------
--  DDL for Table D_TRADE_PERFORMANCE
--------------------------------------------------------

DROP TABLE D_TRADE_PERFORMANCE PURGE;

  CREATE TABLE "C##TIDB"."D_TRADE_PERFORMANCE" 
   (	"ACCOUNT_ID" VARCHAR2(100 BYTE), 
	"RUN_GROUP_NAME" VARCHAR2(100 BYTE), 
	"PERIOD_GROUP" VARCHAR2(5 BYTE), 
	"PERIOD_ID" VARCHAR2(141 BYTE), 
	"PERIOD_NAME" VARCHAR2(141 BYTE), 
	"FIRST_REPORTING_DAY" VARCHAR2(100 BYTE), 
	"LAST_REPORTING_DAY" VARCHAR2(100 BYTE), 
	"CASH_PERIOD" NUMBER, 
	"CASH_OVERALL" NUMBER, 
	"UTILIZED_AMOUNT" NUMBER, 
	"UTILIZED_RATIO" NUMBER, 
	"UTILIZED_AMOUNT_LONG" NUMBER, 
	"UTILIZED_AMOUNT_SHORT" NUMBER, 
	"PROFIT_PERIOD" NUMBER, 
	"PROFIT_OVERALL" NUMBER, 
	"COMMISSION_PERIOD" NUMBER, 
	"COMMISSION_OVERALL" NUMBER, 
	"CAPITAL" NUMBER, 
	"CAPITAL_INCREMENT" NUMBER, 
	"RETURN_RATE" NUMBER, 
    AVG_DAY_RETURN_RATE NUMBER,
    AVG_WEEK_RETURN_RATE NUMBER,
    AVG_MONTH_RETURN_RATE NUMBER,
    AVG_YEAR_RETURN_RATE NUMBER,
	"MAX_DRAWDOWN" NUMBER, 
	"MAX_DRAWDOWN_FIRST_DAY" VARCHAR2(150 BYTE), 
	"MAX_DRAWDOWN_LAST_DAY" VARCHAR2(150 BYTE), 
	"MAX_MARKUP" NUMBER, 
	"MAX_MARKUP_FIRST_DAY" VARCHAR2(150 BYTE), 
	"MAX_MARKUP_LAST_DAY" VARCHAR2(150 BYTE), 
	"POSSIBLE_TRADES" NUMBER, 
	"EXCLUDE_TRADES" NUMBER, 
    TRADES_EXCLUDE_RATE NUMBER,
	"PENDING_TRADES" NUMBER, 
	"CANCELED_TRADES" NUMBER, 
	"NEW_TRADES" NUMBER, 
	"TRADES_FILL_RATE" NUMBER, 
	"OPEN_TRADES" NUMBER, 
	"OPEN_PROFIT" NUMBER, 
	"OPEN_TRADES_HOLDING_TIME" NUMBER, 
	"OPEN_WIN_TRADES" NUMBER, 
	"OPEN_LOSS_TRADES" NUMBER, 
	"OPEN_WIN_RATIO" NUMBER, 
	"OPEN_R_PERCENT" NUMBER, 
	"OPEN_R_MULTIPLE" NUMBER, 
	"OPEN_WIN_R_MULTIPLE" NUMBER, 
	"OPEN_LOSS_R_MULTIPLE" NUMBER, 
	"NEW_TRADES_LONG" NUMBER, 
	"OPEN_TRADES_LONG" NUMBER, 
	"OPEN_PROFIT_LONG" NUMBER, 
	"OPEN_TRADES_HOLDING_TIME_LONG" NUMBER, 
	"OPEN_WIN_TRADES_LONG" NUMBER, 
	"OPEN_LOSS_TRADES_LONG" NUMBER, 
	"OPEN_WIN_RATIO_LONG" NUMBER, 
	"OPEN_R_PERCENT_LONG" NUMBER, 
	"OPEN_R_MULTIPLE_LONG" NUMBER, 
	"OPEN_WIN_R_MULTIPLE_LONG" NUMBER, 
	"OPEN_LOSS_R_MULTIPLE_LONG" NUMBER, 
	"NEW_TRADES_SHORT" NUMBER, 
	"OPEN_TRADES_SHORT" NUMBER, 
	"OPEN_PROFIT_SHORT" NUMBER, 
	"OPEN_TRADES_HOLDING_TIME_SHORT" NUMBER, 
	"OPEN_WIN_TRADES_SHORT" NUMBER, 
	"OPEN_LOSS_TRADES_SHORT" NUMBER, 
	"OPEN_WIN_RATIO_SHORT" NUMBER, 
	"OPEN_R_PERCENT_SHORT" NUMBER, 
	"OPEN_R_MULTIPLE_SHORT" NUMBER, 
	"OPEN_WIN_R_MULTIPLE_SHORT" NUMBER, 
	"OPEN_LOSS_R_MULTIPLE_SHORT" NUMBER, 
	"CLOSED_TRADES" NUMBER, 
	"CLOSED_PROFIT" NUMBER, 
	"CLOSED_WIN_PROFIT" NUMBER, 
	"CLOSED_LOSS_PROFIT" NUMBER, 
	"CLOSED_TRADES_HOLDING_TIME" NUMBER, 
	"CLOSED_WIN_TRADES" NUMBER, 
	"CLOSED_LOSS_TRADES" NUMBER, 
	"CLOSED_WIN_RATIO" NUMBER, 
	"CLOSED_R_PERCENT" NUMBER, 
	"CLOSED_R_MULTIPLE" NUMBER, 
	"CLOSED_WIN_R_MULTIPLE" NUMBER, 
	"CLOSED_LOSS_R_MULTIPLE" NUMBER, 
	"CLOSED_WIN_MAX" NUMBER, 
	"CLOSED_LOSS_MAX" NUMBER, 
	"CLOSED_WIN_AVG" NUMBER, 
	"CLOSED_LOSS_AVG" NUMBER, 
	"CLOSED_TRADES_LONG" NUMBER, 
	"CLOSED_PROFIT_LONG" NUMBER, 
	"CLOSED_WIN_PROFIT_LONG" NUMBER, 
	"CLOSED_LOSS_PROFIT_LONG" NUMBER, 
	"CLOSED_TRADES_HOLDING_TIME_LONG" NUMBER, 
	"CLOSED_WIN_TRADES_LONG" NUMBER, 
	"CLOSED_LOSS_TRADES_LONG" NUMBER, 
	"CLOSED_WIN_RATIO_LONG" NUMBER, 
	"CLOSED_R_PERCENT_LONG" NUMBER, 
	"CLOSED_R_MULTIPLE_LONG" NUMBER, 
	"CLOSED_WIN_R_MULTIPLE_LONG" NUMBER, 
	"CLOSED_LOSS_R_MULTIPLE_LONG" NUMBER, 
	"CLOSED_WIN_MAX_LONG" NUMBER, 
	"CLOSED_LOSS_MAX_LONG" NUMBER, 
	"CLOSED_WIN_AVG_LONG" NUMBER, 
	"CLOSED_LOSS_AVG_LONG" NUMBER, 
	"CLOSED_TRADES_SHORT" NUMBER, 
	"CLOSED_PROFIT_SHORT" NUMBER, 
	"CLOSED_WIN_PROFIT_SHORT" NUMBER, 
	"CLOSED_LOSS_PROFIT_SHORT" NUMBER, 
	"CLOSED_TRADES_HOLDING_TIME_SHORT" NUMBER, 
	"CLOSED_WIN_TRADES_SHORT" NUMBER, 
	"CLOSED_LOSS_TRADES_SHORT" NUMBER, 
	"CLOSED_WIN_RATIO_SHORT" NUMBER, 
	"CLOSED_R_PERCENT_SHORT" NUMBER, 
	"CLOSED_R_MULTIPLE_SHORT" NUMBER, 
	"CLOSED_WIN_R_MULTIPLE_SHORT" NUMBER, 
	"CLOSED_LOSS_R_MULTIPLE_SHORT" NUMBER, 
	"CLOSED_WIN_MAX_SHORT" NUMBER, 
	"CLOSED_LOSS_MAX_SHORT" NUMBER, 
	"CLOSED_WIN_AVG_SHORT" NUMBER, 
	"CLOSED_LOSS_AVG_SHORT" NUMBER, 
	"CLOSED_EV" NUMBER, 
	"CLOSED_EV_LONG" NUMBER, 
	"CLOSED_EV_SHORT" NUMBER, 
	"CLOSED_EXPECTATION" NUMBER, 
	"CLOSED_EXPECTATION_LONG" NUMBER, 
	"CLOSED_EXPECTATION_SHORT" NUMBER, 
	"CLOSED_PROFIT_FACTOR" NUMBER, 
	"CLOSED_PROFIT_FACTOR_LONG" NUMBER, 
	"CLOSED_PROFIT_FACTOR_SHORT" NUMBER, 
	"WIN_STREAK_TRADES" NUMBER, 
	"LOSS_STREAK_TRADES" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" ;
