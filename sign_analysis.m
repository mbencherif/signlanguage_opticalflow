addpath(genpath('flow_code'));

videos = {'sent1.mov', 'sent2.mov', 'sent3.mov'};

data = struct();

for VI = 1:length(videos)

	input_vid_name = videos{VI};
	output_vid_name = strrep(input_vid_name, '.mov', '.avi');

	data(VI).name = videos{VI};
	flow_magnitude = [];
	flow_angle = [];


	input_vid = VideoReader(['/syllable_analysis/' input_vid_name]);
	output_vid = VideoWriter(output_vid_name);
	open(output_vid)

	subsample_factor = 16;
	prev_frame = [];

	f_idx = 1;

	while hasFrame(input_vid)

		frame_full_res = readFrame(input_vid);
		[rf, cf, ~] = size(frame_full_res);
		frame = imresize(frame_full_res, 1/subsample_factor);

		if ~isempty(prev_frame)
			disp(['### ' num2str(f_idx) ' ###']);
			f_idx = f_idx + 1;
			tic;
			uv = estimate_flow_interface(prev_frame, frame, 'classic+nl-fast');
			toc;
			u = uv(:,:,1);
			v = uv(:,:,2);
			mag = sqrt(u.^2 + v.^2);
			theta = atan2d(-v, u);

			% get max 10%
			n = round(0.1*numel(mag));
			[~, maxI] = sort(mag(:), 'descend');
			mean_mag = mean(mag(maxI(1:n))) * subsample_factor;
			mean_theta = mean(theta(maxI(1:n)));

			% graphics overlay 
			output_frame = insertText(frame_full_res, [10 10], ['Flow Magnitude: ' sprintf('%.0f', mean_mag) 'px']);
			output_frame = insertShape(output_frame, 'FilledRectangle', [10 40 mean_mag*10, 10], 'Color', 'green');
			output_frame = insertText(output_frame, [10 80], ['Flow Angle: ' sprintf('%.0f', mean_theta) '°']);
			output_frame = insertShape(output_frame, 'Line', [60 140 60+30*cosd(mean_theta) 140-30*sind(mean_theta)], 'LineWidth', 2, 'Color', 'green');
			flow_map = imresize(uint8(flowToColor(uv)), 2);
			[r,c,~] = size(flow_map);
			output_frame(rf-r+1:rf, cf-c+1:cf, :) = flow_map;

			writeVideo(output_vid, output_frame);

			flow_magnitude = [flow_magnitude mean_mag*10];
			flow_angle = [flow_angle mean_theta];
		end

		prev_frame = frame;
	end
	close(output_vid)

	data(VI).flow_magnitude = flow_magnitude;
	data(VI).flow_angle = flow_angle;
end