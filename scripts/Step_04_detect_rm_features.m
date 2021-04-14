% This script searches each ground track profile in which the ice front was
% detected for a rampart-moat (R-M) structure (again moving from the ocean 
% to the ice shelf). If an R-M structure is found, it gathers various data 
% on the structure that can be used to compute dh_RM and dx_RM.
%
% This script implements Step (v) described in Subsection 2.3 of Becker et 
% al. (2021).
%
% Susan L. Howard, Earth and Space Research, showard@esr.org
% Maya K. Becker, Scripps Institution of Oceanography, mayakbecker@gmail.com
%
% Last update:  April 14, 2021.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


load 'ross_front_crossing_data.mat' % *.mat file created in Step 03

out_filename = 'ross_rm_data.mat';  % output filename


% Set various criteria that a near-front depression must satisfy in order 
% to be classified as representing an R-M structure by the R-M detection
% algorithm

moat_h_lower_limit = 2; % lower limit of the height of the moat--must be 
                        % above sea level
moat_search_dist = 2000; % along-track distance from the detected front over
                         % which to search for a moat
rampart_max_search_dist = 100; % along-track distance from the detected front
                               % over which to search for a higher maximum
                               % than what the algorithm detects as the rampart

                               
%%%%%%%%%%%%%%  end user input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Generate variables for various moat- and rampart-related parameters. Set
% all to NaN; these variables will be populated later on in this script.

moat_h(1:gt_count) = NaN; % height of the moat minimum
moat_index(1:gt_count) = NaN; % index corresponding to the moat minimum
moat_x(1:gt_count) = NaN; % x-coordinate of the moat minimum location
moat_y(1:gt_count) = NaN; % y-coordinate of the moat minimum location
moat_x_dist(1:gt_count) = NaN; % along-track distance (in x) from the moat 
                               % minimum location to the first ATL06 segment
                               % in the ground track profile
moat_x_atc(1:gt_count) = NaN; % along-track x-coordinate of the moat minimum 
                              % location
moat_delta_time(1:gt_count) = NaN; % delta time value of the moat minimum 
                                   % location

rm_flag(1:gt_count) = 0; % whether or not there is a moat/an R-M (0 = no; 1 = yes)

rampart_h(1:gt_count) = NaN; % height of the rampart maximum
rampart_index(1:gt_count) = NaN; % index corresponding to the rampart maximum
rampart_x(1:gt_count) = NaN; % x-coordinate of the rampart maximum location
rampart_y(1:gt_count) = NaN; % y-coordinate of the rampart maximum location
rampart_x_dist(1:gt_count) = NaN; % along-track distance (in x) from the rampart 
                                  % maximum location to the first ATL06
                                  % segment in the ground track profile
rampart_x_atc(1:gt_count) = NaN; % along-track x-coordinate of the rampart 
                                 % maximum location
rampart_delta_time(1:gt_count) = NaN; % delta time value of the rampart maximum 
                                      % location

% Gather all track node values into a single variable (with 1 representing
% the ascending track node and 2 representing the descending track node).
% Do the same for all cycle values.

track_node(1:gt_count) = 0; % whether the track is ascending or descending
cycle_number(1:gt_count) = 0; % cycle of data acquisition

for i = 1:gt_count
    
    if ross_front_crossing_data(i).direction == 'A' % ascending
        track_node(i) = 1;
    elseif ross_front_crossing_data(i).direction == 'D' % descending
        track_node(i) = 2;
    else
        track_node(i) = 0;
    end
    
    cycle_number(i) = convertCharsToStrings(ross_front_crossing_data(i).cycle);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Rampart - Moat Detection 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Run the R-M detection algorithm for each ground track profile, sorting by
% ascending and descending tracks as in Step 03. Search for the moat by
% looking for the minimum height value in the first detected depression 
% that is less than 2 km (along track) from the upper, ice-shelf point in 
% the front jump (Point B).

for i = 1:gt_count
    
    disp(['loop 1 = ' num2str(i)])
    
    h_b = ross_front_crossing_data(i).h_b;
    
    rm_h_loop = h_b;
    index_loc = ross_front_crossing_data(i).index_b;
    x_diff = ross_front_crossing_data(i).x_dist_b;
    index_b = ross_front_crossing_data(i).index_b;
    
    msd_count=(moat_search_dist)/20+1; %we limit moat loop index based on moat search distance
    rsd_count=(rampart_max_search_dist)/20+1; %we limit rampart loop index based on rampart search distance
    
    if ~isnan(h_b)
        
        if ross_front_crossing_data(i).direction == 'D' % descending
            
            for j = 1:msd_count  
                try
                    
                    x_dist_near_front = abs(x_diff - ross_front_crossing_data(i).x_dist(index_b + j));
                    
                    if x_dist_near_front < moat_search_dist
                        
                        rm_h_loop_new = ross_front_crossing_data(i).h_ss(index_b + j);
                        
                        if rm_h_loop_new < rm_h_loop && rm_h_loop_new > moat_h_lower_limit
                            
                            rm_h_loop = rm_h_loop_new;
                            index_loc = index_b + j;
                            
                        else
                            
                            % Break out of this loop if a depression that
                            % satisfies the criteria is detected
                            
                            break
                            
                        end
                        
                    end
                    
                catch
                    
                    disp('short beam')
                    
                end
                
            end   
            
        else % ascending
            
            for j = 1:msd_count 
                
                try
                    
                    x_dist_near_front = abs(x_diff - ross_front_crossing_data(i).x_dist(index_b - j));
                    
                    if x_dist_near_front < moat_search_dist
                        
                        rm_h_loop_new = ross_front_crossing_data(i).h_ss(index_b - j);
                        
                        if rm_h_loop_new < rm_h_loop && rm_h_loop_new > moat_h_lower_limit
                            
                            rm_h_loop = rm_h_loop_new;
                            index_loc = index_b - j;
                        
                        else
                            
                            break
                            
                        end
                        
                    end
                    
                catch
                    
                    disp('short beam')
                    
                end
                
            end
            
        end
        
        moat_h(i) = rm_h_loop;
        moat_index(i) = index_loc;
        
        % If a depression satisfies the criteria described above, take it
        % as a moat and gather and report data about it
        
        if ~isnan(h_b)
            
            moat_x(i) = ross_front_crossing_data(i).x(index_loc);
            moat_y(i) = ross_front_crossing_data(i).y(index_loc);
            moat_x_dist(i) = ross_front_crossing_data(i).x_dist(index_loc);
            moat_x_atc(i) = ross_front_crossing_data(i).x_atc(index_loc);
            moat_delta_time(i) = ross_front_crossing_data(i).delta_time(index_loc);

        end
        
        if rm_h_loop ~= h_b 
            
            rm_flag(i) = 1; % a moat has been detected
            
        else   
            
            rm_flag(i) = 0; % a moat has not been detected
            
        end   
    
    % Keep all moat-related variable values as NaN if h_b is NaN for a 
    % specific ground track profile
        
    else
        
        moat_h(i) = NaN;
        moat_index(i) = NaN;
        moat_x(i) = NaN;
        moat_y(i) = NaN;
        moat_x_dist(i) = NaN;
        moat_x_atc(i) = NaN;
        rm_flag(i) = 0;
        moat_delta_time(i) = NaN;
        
    end
    
end

% If a moat is detected along a ground track profile, make sure that the 
% upper, ice-shelf point in the front jump (Point B) is actually the rampart 
% maximum by searching for the highest point within 100 m of the front

for i = 1:gt_count
    
    disp(['loop 2 = ' num2str(i)])
    
    h_b = ross_front_crossing_data(i).h_b;
    
    rm_h_loop = h_b;
    index_loc = ross_front_crossing_data(i).index_b;
    x_diff = ross_front_crossing_data(i).x_dist_b;
    index_b = ross_front_crossing_data(i).index_b;
    
    if ~isnan(h_b)
        
        if rm_flag(i) == 1 % if a moat has been detected
            
            if ross_front_crossing_data(i).direction == 'D' % descending
                
                for j = 1:rsd_count 
                    
                    x_dist_near_front = abs(x_diff - ross_front_crossing_data(i).x_dist(index_b + j));
                    
                    if x_dist_near_front < rampart_max_search_dist
                                                     
                        rm_h_loop_new = ross_front_crossing_data(i).h_ss(index_b + j);
                        
                        if rm_h_loop_new > rm_h_loop
                            
                            rm_h_loop = rm_h_loop_new;
                            index_loc = index_b + j;
                            
                        end
                        
                    end
                    
                end
                
            else % ascending
                
                for j = 1:rsd_count 
                    
                    x_dist_near_front = abs(x_diff - ross_front_crossing_data(i).x_dist(index_b - j));
                    
                    if x_dist_near_front < rampart_max_search_dist
                                                     
                        rm_h_loop_new = ross_front_crossing_data(i).h_ss(index_b - j);
                        
                        if rm_h_loop_new > rm_h_loop
                            
                            rm_h_loop = rm_h_loop_new;
                            index_loc = index_b - j;
                            
                        end
                        
                    end
                    
                end
                
            end
           
            rampart_h(i) = rm_h_loop;
            rampart_index(i) = index_loc;
            
            % If a high point satisfies the criteria described above, take
            % it as the rampart maximum and gather and report data about it
            
            if ~isnan(h_b)
                
                rampart_x(i) = ross_front_crossing_data(i).x(index_loc);
                rampart_y(i) = ross_front_crossing_data(i).y(index_loc);
                rampart_x_dist(i) = ross_front_crossing_data(i).x_dist(index_loc);
                rampart_x_atc(i) = ross_front_crossing_data(i).x_atc(index_loc);
                rampart_delta_time(i) = ross_front_crossing_data(i).delta_time(index_loc);
                
            end
        
        % Keep all rampart-related variable values as NaN if a moat has not
        % been detected along a specific ground track profile       
            
        else
            
            rampart_h(i) = NaN;
            rampart_index(i) = NaN;
            rampart_x(i) = NaN;
            rampart_y(i) = NaN;
            rampart_x_dist(i) = NaN;
            rampart_x_atc(i) = NaN;
            rampart_delta_time(i) = NaN;
            
        end
    
    % Keep all moat-related variable values as NaN if h_b is NaN for a 
    % specific ground track profile    
        
    else
        
        rampart_h(i) = NaN;
        rampart_index(i) = NaN;
        rampart_x(i) = NaN;
        rampart_y(i) = NaN;
        rampart_x_dist(i) = NaN;
        rampart_x_atc(i) = NaN;
        rampart_delta_time(i) = NaN;
        
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Save relevant R-M parameters to a *.mat file

save(out_filename, '-v7.3', 'moat_h', 'moat_index', 'moat_x', 'moat_y', ... 
    'moat_x_dist', 'moat_x_atc', 'moat_delta_time', 'rm_flag', 'rampart_h', ... 
    'rampart_index', 'rampart_x', 'rampart_y', 'rampart_x_dist', ... 
    'rampart_x_atc', 'rampart_delta_time', 'track_node', 'cycle_number')

