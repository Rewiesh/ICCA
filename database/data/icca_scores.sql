merge into icca_scores tgt
using (
    select 0.000001 as fault_perc, 0.1 as score from dual union all
    select 0.000001, 0.2 from dual union all
    select 0.000002, 0.3 from dual union all
    select 0.000002, 0.4 from dual union all
    select 0.000003, 0.5 from dual union all
    select 0.000004, 0.6 from dual union all
    select 0.000006, 0.7 from dual union all
    select 0.000008, 0.8 from dual union all
    select 0.000011, 0.9 from dual union all
    select 0.000014, 1.0 from dual union all
    select 0.000020, 1.1 from dual union all
    select 0.000027, 1.2 from dual union all
    select 0.000037, 1.3 from dual union all
    select 0.000051, 1.4 from dual union all
    select 0.000070, 1.5 from dual union all
    select 0.000095, 1.6 from dual union all
    select 0.000131, 1.7 from dual union all
    select 0.000179, 1.8 from dual union all
    select 0.000245, 1.9 from dual union all
    select 0.000336, 2.0 from dual union all
    select 0.000461, 2.1 from dual union all
    select 0.000631, 2.2 from dual union all
    select 0.000865, 2.3 from dual union all
    select 0.001185, 2.4 from dual union all
    select 0.001624, 2.5 from dual union all
    select 0.002226, 2.6 from dual union all
    select 0.003050, 2.7 from dual union all
    select 0.004180, 2.8 from dual union all
    select 0.005728, 2.9 from dual union all
    select 0.007850, 3.0 from dual union all
    select 0.010757, 3.1 from dual union all
    select 0.014741, 3.2 from dual union all
    select 0.020201, 3.3 from dual union all
    select 0.027683, 3.4 from dual union all
    select 0.037936, 3.5 from dual union all
    select 0.051986, 3.6 from dual union all
    select 0.071240, 3.7 from dual union all
    select 0.097626, 3.8 from dual union all
    select 0.133784, 3.9 from dual union all
    select 0.183333, 4.0 from dual union all
    select 0.251234, 4.1 from dual union all
    select 0.344284, 4.2 from dual union all
    select 0.471796, 4.3 from dual union all
    select 0.646536, 4.4 from dual union all
    select 0.885994, 4.5 from dual union all
    select 1.214139, 4.6 from dual union all
    select 1.663821, 4.7 from dual union all
    select 2.280051, 4.8 from dual union all
    select 3.124514, 4.9 from dual union all
    select 4.281741, 5.0 from dual union all
    select 5.867571, 5.1 from dual union all
    select 8.040746, 5.2 from dual union all
    select 11.018800, 5.3 from dual union all
    select 15.099836, 5.4 from dual union all
    select 20.692368, 5.5 from dual union all
    select 28.356208, 5.6 from dual union all
    select 38.858508, 5.7 from dual union all
    select 53.250548, 5.8 from dual union all
    select 72.972973, 5.9 from dual union all
    select 100.000000, 6.0 from dual union all
    select 108.000000, 6.1 from dual union all
    select 116.640000, 6.2 from dual union all
    select 125.971200, 6.3 from dual union all
    select 136.048896, 6.4 from dual union all
    select 146.932808, 6.5 from dual union all
    select 158.687432, 6.6 from dual union all
    select 171.382427, 6.7 from dual union all
    select 185.093021, 6.8 from dual union all
    select 199.900463, 6.9 from dual union all
    select 215.892500, 7.0 from dual union all
    select 233.163900, 7.1 from dual union all
    select 251.817012, 7.2 from dual union all
    select 271.962373, 7.3 from dual union all
    select 293.719362, 7.4 from dual union all
    select 317.216911, 7.5 from dual union all
    select 342.594264, 7.6 from dual union all
    select 370.001805, 7.7 from dual union all
    select 399.601950, 7.8 from dual union all
    select 431.570106, 7.9 from dual union all
    select 466.095714, 8.0 from dual union all
    select 503.383372, 8.1 from dual union all
    select 543.654041, 8.2 from dual union all
    select 587.146365, 8.3 from dual union all
    select 634.118074, 8.4 from dual union all
    select 684.847520, 8.5 from dual union all
    select 739.635321, 8.6 from dual union all
    select 798.806147, 8.7 from dual union all
    select 862.710639, 8.8 from dual union all
    select 931.727490, 8.9 from dual union all
    select 1006.265689, 9.0 from dual union all
    select 1086.766944, 9.1 from dual union all
    select 1173.708300, 9.2 from dual union all
    select 1267.604964, 9.3 from dual union all
    select 1369.013361, 9.4 from dual union all
    select 1478.534429, 9.5 from dual union all
    select 1596.817184, 9.6 from dual union all
    select 1724.562558, 9.7 from dual union all
    select 1862.527563, 9.8 from dual union all
    select 2011.529768, 9.9 from dual union all
    select 2172.452150, 10.0 from dual
) src
on (tgt.score = src.score)
when matched then
    update set tgt.fault_perc = src.fault_perc
when not matched then
    insert (fault_perc, score)
    values (src.fault_perc, src.score);
