function time = time2sec(time_string)
% TIME2SEC  Convert time to seconds.
% Usage:    time = time2sec(time_string)
% Inputs:   time_string     -time string in form of HH:MM:SS
% Outputs:  time            -time in seconds
    h = hour(time_string,'HH:MM:SS');
    m = minute(time_string,'HH:MM:SS');
    s = second(time_string,'HH:MM:SS');
    time  = h*3600+m*60+s;
end