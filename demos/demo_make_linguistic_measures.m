function demo_make_linguistic_measures(option)
    switch option
        case 1
            subexpIDs = [65 66];
            keywords_list = ["cow" "spongebob"];
            output_filename = 'test_exp65-66_cow-spongebob_measures.csv';
            rtr_table = make_linguistic_measures(subexpIDs, keywords_list, output_filename);
    end
end