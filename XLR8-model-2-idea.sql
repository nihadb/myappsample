select  tp, sl, 
    sum(pred_value) trades,
    sum(pred_value * actual_value) / sum(pred_value) win_rate,
    sum(pred_value*tp/sl)
from o_model_predict
where sample_type = 'TEST'
and trade_signal= 'BUY'
and modeling_level = 'L2'
group by tp, sl
order by 2, 1;



with d0
as
(
    select sample_type, symbol, tick_timestamp, 
        max(case when tp = 2 then pred_value end) pred_value_2,
        max(case when tp = 4 then pred_value end) pred_value_4,
        max(case when tp = 5 then pred_value end) pred_value_5,
        max(case when tp = 6 then pred_value end) pred_value_6,
        max(case when tp = 2 then actual_value end) actual_value_2,
        max(case when tp = 4 then actual_value end) actual_value_4,
        max(case when tp = 5 then actual_value end) actual_value_5,
        max(case when tp = 6 then actual_value end) actual_value_6
    from o_model_predict
    where sl = 2
    and tp in (2, 4, 5, 6)
    AND MODELING_LEVEL = 'L2'
    group by sample_type, symbol, tick_timestamp
)
select sample_type, sum(pred_value_2), sum(pred_value_4), sum(pred_value_5), sum(pred_value_6),
        sum(pred_value_4*actual_value_2) / sum(pred_value_4) win_rate_4,
        sum(pred_value_4*actual_value_4) / sum(pred_value_4) win_rate_4_orig,
        sum(pred_value_5*actual_value_2) / sum(pred_value_5) win_rate_5,
        sum(pred_value_5*actual_value_5) / sum(pred_value_5) win_rate_5_orig,
        sum(pred_value_6*actual_value_2) / sum(pred_value_6) win_rate_6,
        sum(pred_value_6*actual_value_6) / sum(pred_value_6) win_rate_6_orig
from d0 a
group by sample_type;


select trade_signal, sl, tp, count(*)
from o_model_predict
where modeling_level = 'L2'
and sample_type = 'TRAIN'
group by trade_signal, sl, tp
order by 1, 2, 3;


SELECT *
FROM O_MODEL_PREDICT A
JOIN O_MODEL_DATA B
ON A.SYMBOL = B.SYMBOL
AND A.TICK_TIMESTAMP = B.TICK_TIMESTAMP
AND B.INTERVAL = '1D'
AND A.MODELING_LEVEL = 'L2'
