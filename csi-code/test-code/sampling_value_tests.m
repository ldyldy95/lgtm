%%
% The MIT License (MIT)
% Copyright (c) 2016 Ethan Gaebel <egaebel@vt.edu>
% 
% Permission is hereby granted, free of charge, to any person obtaining a 
% copy of this software and associated documentation files (the "Software"), 
% to deal in the Software without restriction, including without limitation 
% the rights to use, copy, modify, merge, publish, distribute, sublicense, 
% and/or sell copies of the Software, and to permit persons to whom the 
% Software is furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included 
% in all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
% DEALINGS IN THE SOFTWARE.
%

function sampling_value_tests
    clc
    % Get the full path to the currently executing file and change the
    % pwd to the folder this file is contained in...
    [current_directory, ~, ~] = fileparts(mfilename('fullpath'));
    cd(current_directory);
    % Paths for the csitool functions provided
    path('../../../linux-80211n-csitool-supplementary/matlab', path);
    path('..', path);
    path('../../injection-monitor/experimental-data/lgtm-monitor-data', path);
    data_files = {...
            'lgtm-monitor.dat--laptop-1--test-1', ...
            'lgtm-monitor.dat--laptop-1--test-2', ...
            'lgtm-monitor.dat--laptop-1--test-3', ...
            'lgtm-monitor.dat--laptop-1--test-4', ...
            'lgtm-monitor.dat--laptop-1--test-5', ...
            'lgtm-monitor.dat--laptop-2--test-1', ...
            'lgtm-monitor.dat--laptop-2--test-2', ...
            'lgtm-monitor.dat--laptop-2--test-3', ...
            'lgtm-monitor.dat--laptop-2--test-4', ...
            'lgtm-monitor.dat--laptop-2--test-5', ...
    };
    
    % Set physical layer parameters (frequency, subfrequency spacing, and antenna spacing
    antenna_distance = 0.1;
    % frequency = 5 * 10^9;
    % frequency = 5.785 * 10^9;
    frequency = 5.32 * 10^9;
    sub_freq_delta = (40 * 10^6) / 30;
    
    % Loop over data files
    for data_file_index = 1:length(data_files)
        % Extract csi information for all packets
        fprintf('Running on data file: %s\n', data_files{data_file_index})
        csi_trace = read_bf_file(data_files{data_file_index});
        fprintf('Have CSI for %d packets\n', length(csi_trace))
    
        fprintf('Sampling results: \n')
        % Format of each vector is:
        % number of packets, begin index, end index
        % The three main groupings below are:
        %       All the packets
        %        
        %       Uniform sampling of packets
        %        
        %       Last N packets
        sampling_options = {
                [length(csi_trace); 1; length(csi_trace);], ...
                %{
                [750; 1; length(csi_trace);], ...
                [500; 1; length(csi_trace);], ...
                [250; 1; length(csi_trace);], ...
                [100; 1; length(csi_trace);], ...
                [50; 1; length(csi_trace);], ...
                [25; 1; length(csi_trace);], ...
                [10; 1; length(csi_trace);], ...
                [500; (length(csi_trace) - 500); length(csi_trace);], ...
                [250; (length(csi_trace) - 250); length(csi_trace);], ...
                [100; (length(csi_trace) - 100); length(csi_trace);], ...
                [50; (length(csi_trace) - 50); length(csi_trace);], ...
                [25; (length(csi_trace) - 25); length(csi_trace);], ...
                [10; (length(csi_trace) - 10); length(csi_trace);], ...
                [500; 1; 500;], ...
                [250; 1; 250;], ...
                [100; 1; 100;], ...
                [50; 1; 50;], ...
                [25; 1; 25;], ...
                [10; 1; 10;], ...
                %}
        };
        % Sample packets and compute
        for ii = 1:length(sampling_options)
            fprintf('Sampling with:\nnumber of packets = %d\nbegin index = %d\nend_index = %d\n', ...
                    sampling_options{ii}(1), sampling_options{ii}(2), sampling_options{ii}(3))
            % Set the number of packets to consider, by default consider all
            num_packets = sampling_options{ii}(1, 1);
            begin_index = sampling_options{ii}(2, 1);
            end_index = sampling_options{ii}(3, 1);
            
            sampled_csi_trace = csi_sampling(csi_trace, num_packets, begin_index, end_index);
            
            data_name_string = sprintf('%s - %d, %d, %d', data_files{data_file_index}, ...
                    sampling_options{ii}(1, 1), ...
                    sampling_options{ii}(2, 1), ...
                    sampling_options{ii}(3, 1));
            output_top_aoas = spotfi(sampled_csi_trace, frequency, sub_freq_delta, ...
                    antenna_distance, data_name_string);
            fprintf('Top AoAs: \n')
            output_top_aoas
            fprintf('\n\n')
        end

        
        
        continue
        
        
        
        fprintf('Chunk and vote results: \n')
        chunking_options = {
                200, ...
                100, ...
                50, ...
                10, ...
        };
        top_aoas = zeros(0, 2);
        % Chunk & vote tests
        for ii = 1:length(chunking_options)
            % Loop over chunks, running SpotFi on each
            fprintf('Chunking in groups of %d\n', chunking_options{ii})
            for jj = 1:chunking_options{ii}:length(csi_trace)
                % Include the final chunk, even if it's irregularly sized
                if (jj + chunking_options{ii} < length(csi_trace))
                    chunk = csi_trace(jj:(jj + chunking_options{ii} - 1), 1);
                else
                    chunk = csi_trace(jj:length(csi_trace), 1);
                end

                output_top_aoas = spotfi(chunk, frequency, sub_freq_delta, antenna_distance);
                
                % Determine if the top angle of arrival is new or not, and if it's not, its index
                rounded_top_aoa = round(output_top_aoas(1));
                [is_present, index] = ismember(rounded_top_aoa, top_aoas(:, 1));
                % Add angle to list or increment counter
                if is_present
                    top_aoas(index, 2) = top_aoas(index, 2) + 1;
                else
                    top_aoas(size(top_aoas, 1) + 1, 1) = rounded_top_aoa;
                    top_aoas(size(top_aoas, 1), 2) = 1;
                end
            end
            % Find angle of arrival with the maximum votes
            max_index = 1;
            for jj = 2:size(top_aoas, 1)
                if top_aoas(jj, 2) > top_aoas(max_index, 2)
                    max_index = jj;
                end
            end
            fprintf('AoAs and votes: \n')
            top_aoas
            fprintf('AoA selected by vote was: %d\n\n', top_aoas(max_index, 1))
        end
    end
end