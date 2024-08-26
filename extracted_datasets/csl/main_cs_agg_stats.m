exp_id = 91; 

data = csvread(sprintf('exp%d_cs_agg_stats.csv', exp_id));
% 8: cs stats (target-distractor)
% 3: frequency
% 4: asso strength 
data_idx = data(:,1)*100 + data(:,2);
figure(1);
histogram(data(:,8),[-1:0.2:1], "Normalization","probability"); 
axis([-1 1 0 0.4]);
file_name = sprintf('cs_agg_stats_hist_exp%d.png',exp_id); 
saveas(gcf,file_name);

histogram(data(:,4),[0:0.1:1],"Normalization","probability"); 
axis([0 1 0 0.4])
file_name = sprintf('cs_individual_attention_hist_exp%d.png',exp_id); 
saveas(gcf,file_name);

histogram(data(:,3),"Normalization","probability"); 
axis([0 10 0 0.4])
file_name = sprintf('cs_freq_hist_exp%d.png',exp_id); 
saveas(gcf,file_name);



