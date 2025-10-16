function time_window = get_time_window_for_vis(start_time, end_time)
    % helper function, divide var length time into 4 chunks
    chunk_length = (end_time - start_time)/4;
    time_window = [
        start_time,chunk_length+start_time;
        chunk_length+start_time, 2*chunk_length+start_time;
        2*chunk_length+start_time, 3*chunk_length+start_time;
        3*chunk_length+start_time, end_time
    ];
end