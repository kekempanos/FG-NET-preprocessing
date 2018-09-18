% Pre-processing the FG-NET Aging Database
% Lykourgos Kekempanos, 22/02/2016

% convert the file names to contain only uppercase names
%system('fnuppercase.sh')

% Step 1   :   gray scale & face alignment
% dataset and landmark association
images_dir = 'Images';
points_dir = 'Points';

srcImages = dir(fullfile(images_dir, '*.JPG'));  % images directory
Im = cell(1,1002);  % images
Po = cell(1,1002);  % corresponding landmarks
Age = zeros(1,1002); % corresponding age
counter = 0; % num of non-cropped images
im_dimension = zeros(1,1002);

nimgs = [50,50]; % new image size
nimg = zeros(nimgs(1)*nimgs(2),length(srcImages)); % save new images

for i = 1:length(srcImages)
	imgfilename = srcImages(i).name; % images name
	fullimgfilename = fullfile(images_dir,imgfilename);
	[~, basename, ~] = fileparts(imgfilename);
	fullptsfilename = fullfile(points_dir, [basename '.pts']);
    if ~exist(fullptsfilename,'file')
		fprintf(2, 'Image "%s" did not have a corresponding .pts file\n', imgfilename);
        flag = 1;
    end
    
    % store the corresponding age for each image
	Age(i) = str2double(basename(end-1:end));
	
    if isnan(Age(i))
		Age(i) = str2double(basename(end-2:end-1));
    end
    
    % read image
	Im{i} = imread(fullimgfilename);
    
	% image type based on color
    im_dimension(i) = size(Im{i},3);
    
	% convert to grayscale
    [rows, columns, numberOfColorChannels] = size(Im{i});
	
    %check if image is already in gray scale
    if (numberOfColorChannels > 1)
        Im{i} = rgb2gray(Im{i});
    end
	
	% write gray scale image
	imwrite(Im{i}, fullimgfilename);
	
	% image central point
	center = size(Im{i(:)})/2+.5;
	
    % image does not have corresponding .pts file (assuming the alignment is not needed)
    if(flag == 1)
        flag = 0;
		% crop image
		FD = vision.CascadeObjectDetector;
		cimg = imread(fullimgfilename);
		FR = step(FD,cimg);
		%{
		if isempty(FR) || size(FR,1) > 1
			counter = counter + 1;
			continue;
		end
		%}
		cimage = imcrop(cimg,FR);
        r = imresize(cimage, [nimgs(1),nimgs(2)]);
		imwrite(r, fullimgfilename);
        nimg(:,i) = r(:);
        continue;
    end
    
	[FileId, ~] = fopen(fullptsfilename);
	npoints = textscan(FileId,'%s %f',1,'HeaderLines',1);
	points = textscan(FileId,'%f %f', npoints{2}, 'MultipleDelimsAsOne', 2, 'Headerlines', 2, 'CollectOutput', 1);
	fclose(FileId);
	
	Po{i} = points{1};
	
	% eyes direction; from the left to the right eye
    eyes_direction = [Po{i}(37,1)-Po{i}(32,1), Po{i}(37,2)-Po{i}(32,2)];
	
    % the angle equals the arctangent of dright_eye/dleft_eye
	% convert radials to degree
    angle = -atan2d(eyes_direction(2), eyes_direction(1)) + 360*(eyes_direction(1)<0);
	
	% rotate in the opposite direction
	%img = imrotate(Im{i(:)}, -angle);
    img = imrotate(Im{i(:)}, -angle, 'nearest', 'crop');
	
    % normalizing image to [0,1]
    img = mat2gray(img);
    
    % zero-mean (by row)
    %xmean = mean(img, 1);
    %img = bsxfun(@minus, img, xmean);
    
	% crop, resize and store the image
	c = crop_image(img, Po{i}(:,:), angle, center);
    r = imresize(c, [nimgs(1),nimgs(2)]);
    nimg(:,i) = r(:);
	
	imwrite(r,fullimgfilename);
end

% age histogram
histogram(Age);
xlabel('Age');
ylabel('Population');

% aging pie based on human growth curve
figure;
hgc = [length(Age(Age<=2)); length(Age(Age>=3 & Age<=12)); 
        length(Age(Age>=13 & Age<=19));
        length(Age(Age>=20 & Age<=64)); length(Age(Age>=65))];
hgc = hgc./length(Age);
h = pie(hgc);
labels = {'Infancy','Childhood','Adolescence','Adulthood', 'Old age'};
legend(labels,'Location','southoutside','Orientation','horizontal');
hText = findobj(h,'Type','text'); % text object handles
percentValues = get(hText,'String'); % percent values
str = {'(0-2) ';'(3-12) ';'(13-19) ';'(20-64) ';'(>=65) '}; % strings
combinedstrings = strcat(str,percentValues); % strings and percent values
for i=1:5
    hText(i).String = combinedstrings(i);
end

% gray scale vs RGB images
figure;
dims = im_dimension;
ptgim = length(dims(dims==1))/length(dims);
ptcim = length(dims(dims==3))/length(dims);
ims = [ptgim ptcim];
h = pie(ims);
labels = {'Gray Scale','RGB'};
legend(labels,'Location','southoutside','Orientation','horizontal');
colormap([.5 .5 .5; 0 1 .5;]);