drop table suspect_logregr cascade;
drop table suspect_logregr_summary cascade;
truncate table suspect;
insert into suspect (select id,device_id,ts_millis,'Manually Marked',1 from transaction_info where distancekm>200 and percentage>.75 or mph > 200);


SELECT madlib.logregr_train(
    'transaction_info',                                 -- source table
    'suspect_logregr',                         -- output table
    'marked',                            -- labels
    'ARRAY[1, distancekm, percentage,mph]',       -- features
    NULL,                                       -- grouping columns
    20,                                         -- max number of iteration
    'irls'                                     -- optimizer
    );
     
delete from suspect where reason='Manually Marked';
    
drop view if exists fraud_view;

create view fraud_view as ( SELECT s.id,s.device_id,s.transaction_value,s.ts_millis,'ML Prediction' as reason,s.distancekm,s.percentage,s.account_id, madlib.logregr_predict(coef, ARRAY[1, distancekm, percentage,mph]) as fraud,s.marked,madlib.logregr_predict_prob(coef, ARRAY[1, distancekm, percentage,mph]) as prob FROM transaction_info s, suspect_logregr l ORDER BY marked desc, fraud desc);

