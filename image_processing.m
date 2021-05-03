function table = image_processing(filename, zoom)
    %Accounting for the scales (from Hemacytometer measurements)
    if zoom == 20
        factor = 400/875;
    elseif zoom == 10
        factor = 600/658;
    else
        factor = 1000/544;        
    end
    %Importing and processing photo
    photo = imread(strcat(filename, '.tif'));
    photo = photo(:, :, 1:3);
    photo = rgb2gray(photo);
    photo = edge(photo, 'zerocross');
    photo = imfill(photo, 'holes');
    photo = bwareafilt(photo, [100, 500]);
    stats = regionprops('table', photo, 'centroid', 'majoraxislength', 'eccentricity', 'orientation');
    %Removing noise and outliers
    toDelete = abs(stats.Orientation) > 30;
    stats(toDelete, :) = [];
    toDelete = stats.Eccentricity < 0.75;
    stats(toDelete, :) = [];
    av = mean(stats.MajorAxisLength);
    stdev = std(stats.MajorAxisLength);
    toDelete = stats.MajorAxisLength > av + 2 * stdev;
    stats(toDelete, :) = [];
    toDelete = stats.MajorAxisLength < av - 2 * stdev;
    stats(toDelete, :) = [];
    %Changing length of streaks to micrometer scale
    stats.MajorAxisLength = stats.MajorAxisLength .* factor;
    centroids = cat(1, stats.Centroid);
    lengths = cat(1, stats.MajorAxisLength);
    %Plotting image of which streaks were used
    fig = figure();
    imshow(photo);
    hold on;
    plot(centroids(:, 1), centroids(:, 2), 'b*');
    saveas(fig, strcat('accounted_for_', filename, '.png'));
    hold off;
    %Changing coordinates to micrometer scale
    stats.Centroid = stats.Centroid .* factor;
    centroids = cat(1, stats.Centroid);
    %Plotting velocity distribution
    fig = figure;
    plot(centroids(:, 2), lengths(:, 1), 'b*');
    saveas(fig, strcat('velocity_profile_', filename, '.png'));
    writetable(stats, strcat('data_', filename, '.xlsx'));
    table = stats;
end