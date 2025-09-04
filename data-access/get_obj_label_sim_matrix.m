%%
%  Returns the label-wise semantic similarity matrix for 
%  the desired experiment (as table), if there's one.  
%  
%  Author: Eriz Zhao
%  Modifier: Elton Martinez
%  Last modified: 9/4/2025
%
%
%%

function sem_sim_matrix = get_obj_label_sim_matrix(expID)

    sem_sim_filename = 'obj_labels_sim.csv';
    exp_dir = get_experiment_dir(expID);
    sem_sim_filepath = fullfile(exp_dir,sem_sim_filename);
    
    if ~isfile(sem_sim_filepath)
        fprintf('obj label sim file not found\n')
        sem_sim_matrix = [];
        return
    end
    
    sem_sim_matrix = readtable(sem_sim_filepath,"ReadRowNames",true,"VariableNamingRule","preserve");
end