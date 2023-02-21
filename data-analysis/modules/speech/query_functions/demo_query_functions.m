function demo_query_functions(option)
    switch option
%         case 1-8 demonstrate various usages of query_csv() function
%         Parameters: (word_list, expID_list,filename,window,cam)
%           Default window = 0 (querying words that co-occur in same utterance)
%           Default camera = 7 (kid’s egocentric view)
%         Return: query_word_table type table
%         Output: .csv file
        case 1
            % basic usage: querying single word from single experiment
            word_list = ["car"];
            expID_list = [12];
            filename = "car_exp12.csv";

            query_word_table = query_csv(word_list, expID_list,filename);
        
        case 2
            % basic usage: querying single word from multiple experiments
            word_list = ["car"];
            expID_list = [12,15];
            filename = "car_exp12_exp15.csv";

            query_word_table = query_csv(word_list, expID_list,filename);

        case 3
            % basic usage: querying single word from multiple experiments,
            % obtaining source video path to parent's egocentric view
            word_list = ["car"];
            expID_list = [12,15];
            filename = "car_exp12_exp15.csv";

            % camera for source video is default at 7, which is the kid's
            % egocentric view
            cam = 8;

            query_word_table = query_csv(word_list, expID_list,filename,cam);

        case 4
            % querying synonyms occurring within same utterance from
            % multiple experiments
            word_list = ["bunny", "rabbit"];
            expID_list = [12,15];
            filename = "bunny-rabbit_exp12_exp15.csv";

            query_word_table = query_csv(word_list, expID_list,filename);

        case 5
            % querying synonyms where the first word occurs within two seconds earlier than the second word
            % and querying from multiple experiments
            word_list = ["bunny", "rabbit"];
            expID_list = [12,15];
            filename = "bunny-rabbit_2s_exp12_exp15.csv";

            % window needs to non-negative
            window = 2;

            query_word_table = query_csv(word_list, expID_list,filename,window);

        case 6
            % querying synonyms where the first word occurs within two seconds earlier than the second word
            % and querying from multiple experiments
            word_list = ["bunny", "rabbit"];
            expID_list = [12,15];
            filename = "bunny-rabbit_2s_exp12_exp15.csv";

            % window needs to non-negative
            window = 2;

            query_word_table = query_csv(word_list, expID_list,filename,window);

        case 7
            % querying Verb - Noun pairs occurring within same utterance
            % and querying from multiple experiments
            word_list = ["drive","car"];
            expID_list = [12,15];
            filename = "drive-car_exp12_exp15.csv";

            query_word_table = query_csv(word_list, expID_list,filename);

        case 8
            % querying Verb - Noun pairs occurring within 3 seconds apart
            % (noun occurs after verb within 3 seconds of verb's onset)
            % and querying from multiple experiments
            word_list = ["drive","car"];
            expID_list = [12,15];
            filename = "drive-car_3s_exp12_exp15.csv";

            window = 3;

            query_word_table = query_csv(word_list, expID_list,filename,window);


%         Case 9-13 demonstrate various usages of query_frame_collage() function
%         Parameters: (query_word_table,row,column,cam,filename,args)
%           Default camera = 7 (kid’s egocentric view)
%           Default args.whence = ‘’ (none)
%           Default args.interval = [0 0] (none)
%         Output: .png files of frame collage

        case 9
            % Step 1: generate query_word_table, which contains query
            % instances, before generating frame collage (image tile) of instances
            word_list = ["drive","car"];
            expID_list = [12,15];
            filename = "drive-car_2s_exp12_exp15.csv";
            window = 2;
            query_word_table = query_csv(word_list, expID_list,filename,window);

            % Step 2: generate frame collage of query words
            % Basic usage: display frames of onset of query words,
            % when multiple words were queried, this function will only
            % display the onset of the first query word

            % set the number of rows of the output collage
            row = 4;
            % set the number of columns of the output collage
            column = 4;
            % choose which camera view to display
            cam = 7;
            filename = "drive-car_2s_exp12_exp15.png";
            query_frame_collage(query_word_table,row,column,cam,filename)

       case 10
            % Step 1: generate query_word_table, which contains query
            % instances, before generating frame collage (image tile) of instances
            word_list = ["car"];
            expID_list = [12,15];
            filename = "car_exp12_exp15.csv";
            query_word_table = query_csv(word_list, expID_list,filename);

            % Step 2: generate frame collage (image tile) of query words
            % Basic usage: display frames of onset of query words,
            % when frames can't fit in one collage, overflowing frames
            % will be displayed in additional collages

            % set the number of rows of the output collage
            row = 4;
            % set the number of columns of the output collage
            column = 4;
            % choose which camera view to display
            cam = 7;
            filename = "car_exp12_exp15.png";
            query_frame_collage(query_word_table,row,column,cam,filename)

       case 11
            % Step 1: generate query_word_table, which contains query
            % instances, before generating frame collage (image tile) of instances
            word_list = ["car"];
            expID_list = [12,15];
            filename = "car_exp12_exp15.csv";
            query_word_table = query_csv(word_list, expID_list,filename);

            % Step 2: generate frame collage (image tile) of query words
            % Usage: displays frames 5 seconds before original onset

            % set the number of rows of the output collage
            row = 4;
            % set the number of columns of the output collage
            column = 4;
            % choose which camera view to display
            cam = 7;
            filename = "car_exp12_exp15.png";

            % Change query instances timestamps based on onset,
            % updated new onsets will be 5 seconds earlier than original
            % onset

            % Notes: for new onsets that are not within trials, we will
            % skip those onsets and use an empty black frame to indicate
            % the skipped frame
            args.whence = 'start';
            args.interval = [-5 0];
            query_frame_collage(query_word_table,row,column,cam,filename,args);

       case 12
            % Step 1: generate query_word_table, which contains query
            % instances, before generating frame collage (image tile) of instances
            word_list = ["car"];
            expID_list = [12,15];
            filename = "car_exp12_exp15.csv";
            query_word_table = query_csv(word_list, expID_list,filename);

            % Step 2: generate frame collage (image tile) of query words
            % Usage: displays frames 5 seconds after original offset

            % set the number of rows of the output collage
            row = 4;
            % set the number of columns of the output collage
            column = 4;
            % choose which camera view to display
            cam = 7;
            filename = "car_exp12_exp15.png";

            % Change query instances timestamps based on offset,
            % updated new offsets will be 5 seconds after original
            % offset

            % Notes: for new offsets that are not within trials, we will
            % skip those offsets and use an empty black frame to indicate
            % the skipped frame
            args.whence = 'end';
            args.interval = [0 5];
            query_frame_collage(query_word_table,row,column,cam,filename,args);

       case 13
            % Step 1: generate query_word_table, which contains query
            % instances, before generating frame collage (image tile) of instances
            word_list = ["car"];
            expID_list = [12,15];
            filename = "car_exp12_exp15.csv";
            query_word_table = query_csv(word_list, expID_list,filename);

            % Step 2: generate frame collage (image tile) of query words
            % Usage: displays frames 5 seconds before original onset

            % set the number of rows of the output collage
            row = 4;
            % set the number of columns of the output collage
            column = 4;
            % choose which camera view to display
            cam = 7;
            filename = "car_exp12_exp15.png";

            % Change query instances timestamps based on onset and offset,
            % updated new onsets will be 5 seconds earlier than original
            % onset; updated new offsets will be 5 seconds later than original
            % offset.

            % Notes: for new offsets that are not within trials, we will
            % skip those offsets and use an empty black frame to indicate
            % the skipped frame
            args.whence = 'startend';
            args.interval = [-5 5];
            query_frame_collage(query_word_table,row,column,cam,filename,args);       
    end
end