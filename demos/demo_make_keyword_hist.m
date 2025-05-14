%Description : this function takes an input csv containing counts of words
%per grouping level, and creates histograms displaying the counts of each
%word in rank order and also histograms of keywords - data files for all
%plots are also output
% 
% Input Arguments:
% 
% input csv: input csv file, in the format of cooccurrence files 
% 
% output_dis: output directory where you want histograms to output to 
% 
% keyword_list: a list of keywords which will show up highlighted on the histograms
% 
% word_display_limit: an integer specifying how many words will be displayed per histogram 
%     - the top n most frequent words will be displayed where n = word_display_limit
% 
% group_col: the column or columns you want the histograms grouped b 
%     - if column 1 of the spreadsheet is subject ID, specifying 1 means 
%       that each output histogram will contain the counts for each word 
%       at the subject level
%      - if column 2 is object id, specifying [1 2] means that each histogram 
%          will contain counts for each word for each subject object 
%          - for example, the first plot will show word counts for subject 1 object 1 
% 
% Optional input argument:
% 
% args.global_most_common: whether you want each plot to display the most
% common words overall or by grouping
%              -defaults to 0 (displays most common words per group)
% 
% args.start_word_col: integer, the number of the column containing the first word in the input file
%     - if the first three columns are subID, category, and GroupCount, and the rest of the columns contain
%         the counts for each words, start word_col =4
%     - defaults to 4 if not specified
% 
% 
% 


function demo_make_keyword_hist(option)
    global_dir = "Z:\demo_output_files\make_keyword_hist";

    switch option 
        case 1
            input_csv = fullfile(global_dir,"speech_in_roi_co_ccur_351.csv");
            output_dir = fullfile(global_dir,"demo1");
            keyword_list = ["is", "babyname", "you"];

            group_col = 1; %group by subject
            
            %args 
            args.word_display_limit = 20; % max words on each barchart/histogram

            make_keyword_hist(input_csv, output_dir,keyword_list, group_col, args)
        case 2
            %each plot display most common words overall (instead of most
            %common words for that group only)
            input_csv = fullfile(global_dir,"speech_in_roi_co_ccur_351.csv");
            output_dir = fullfile(global_dir,"demo2");
            %keyword_list = ["is", "babyname", "you"];
            keyword_list = ["i", "you", "they","we", "it","your","their", "them", "me","our"];

            group_col = 1; %group by subject

            args.word_display_limit = 20; % max words on each barchart/histogram
            args.start_word_col = 4;

            args.global_common_words = 1;

            make_keyword_hist(input_csv, output_dir,keyword_list, group_col, args)
        case 3
            input_csv = fullfile(global_dir,"speech_in_roi_co_ccur_351.csv");
            output_dir = fullfile(global_dir,"demo3");
            keyword_list = ["is", "babyname", "you"];

            group_col = [1 2]; %group by subject and object (each row is a histogram)

            args.word_display_limit = 20; % max words on each barchart/histogram

            make_keyword_hist(input_csv, output_dir,keyword_list, group_col, args)
        
        case 4
            input_csv = fullfile(global_dir,"speech_in_roi_co_ccur_351.csv");
            output_dir = fullfile(global_dir,"demo4");
            keyword_list = ["i", "you", "they","we", "it"];%,"your","their", "them", "me","our","he","she","him","her"];

            word_display_limit = 20; % max words on each barchart/histogram

            group_col = [1]; %group by subject and object (each row is a histogram)

            %args.global_most_common = 1;

            make_keyword_hist(input_csv, output_dir,keyword_list, group_col)


        case 5
            input_csv = fullfile(global_dir,"speech_in_roi_co_ccur_351.csv");
            output_dir = fullfile(global_dir,"demo5");
            expID = 351;
            keyword_list = get_object_label(expID,1:get_num_obj(expID));

            group_col = 1; %group by subject
            
            %args 
            args.word_display_limit = 20; % max words on each barchart/histogram

            make_keyword_hist(input_csv, output_dir,keyword_list, group_col, args)

    end
end