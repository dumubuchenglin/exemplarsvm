function [hg_size,N,Ntruncated,goods] = get_hg_size(pos_set, sbin)
%% Load ids of all images in trainval that contain cls which are
%% not truncated


r = cellfun2(@(x)cat(1,x.objects.bbox),pos_set);
bbs = cat(1,r{:});

x = cellfun2(@(x)cat(1,x.objects.truncated),pos_set); 
truncated = cat(1,x{:});

if sum(truncated==0)==0
  fprintf(1,'WARNING: all examples are truncated\n');
else
  bbs = bbs(truncated==0,:);
end

Ntruncated = sum(truncated==1);
W = bbs(:,3)-bbs(:,1)+1;
H = bbs(:,4)-bbs(:,2)+1;

N=length(W);


[hg_size,aspect_ratio_histogram] = get_bb_stats(H, W, sbin);



aspect_dists = (H./W-hg_size(1)/hg_size(2)).^2;

p = exp(-((aspect_dists-mean(aspect_dists))/ ...
           std(aspect_dists)).^2);
coef = (2*pi)^(-1/2)*std(aspect_dists)^-.5;
p = p.*coef;
goods = find(p>.5);






function [modelsize,aspects] = get_bb_stats(h,w, sbin)
% Following Felzenszwalb's formula

xx = -2:.02:2;
filter = exp(-[-100:100].^2/400);
aspects = hist(log(h./w), xx);
aspects = convn(aspects, filter, 'same');
[peak, I] = max(aspects);
aspect = exp(xx(I));

% pick 20 percentile area
areas = sort(h.*w);

%TJM: make sure we index into first element if not enough are
%present to take the 20 percentile area
area = areas(max(1,floor(length(areas) * 0.2)));
area = max(min(area, 5000), 1000);

area = 4000;

if area==1000
  fprintf(1,'WARNING: esvm_initialize_dt has tiny objects\n');
end

% pick dimensions
w = sqrt(area/aspect);
h = w*aspect;

modelsize = [round(h/sbin) round(w/sbin)];
modelsize = max(modelsize,4);
modelsize = min(modelsize,12);
