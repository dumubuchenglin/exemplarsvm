function fg = get_pascal_scene_stream(VOCopts, set_name, cls)
%% Create a scene stream, such that each element fg{i} contains
%these fields: (I, bbox, cls, curid, [objectid], [anno])

basedir = sprintf('%s/models/streams/',VOCopts.localdir);
if ~exist(basedir,'dir')
  mkdir(basedir);
end

streamname = sprintf('%s/%s-%s-%d-%s%s.mat',...
                     basedir,set_name,cls,VOCopts.stream_max_ex,...
                     VOCopts.model_type,VOCopts.must_have_seg_string);

if fileexists(streamname)
  fprintf(1,'Loading %s\n',streamname);
  load(streamname);
  return;
end

%% Load ids of all images in trainval that contain cls
[ids,gt] = textread(sprintf(VOCopts.clsimgsetpath,cls,set_name),...
                  '%s %d');
ids = ids(gt==1);

fg = cell(0,1);

for i = 1:length(ids)
  curid = ids{i};

  recs = PASreadrecord(sprintf(VOCopts.annopath,curid));  
  if must_have_seg && (recs.segmented == 0)
    %SKip over unsegmented images
    continue
  end
  filename = sprintf(VOCopts.imgpath,curid);
  
  fprintf(1,'.');
  
  res.I = filename;

  %Use the entire scene (remember VOC stores imgsize in a strange order)
  res.bbox = [1 1 recs.imgsize(1) recs.imgsize(2)];
  
  res.cls = cls;
  
  %for scenes use a 1 for objectid
  res.objectid = 1;
  
  %anno is the data-set-specific version
  res.anno = recs.objects;
  
  res.filer = sprintf('%s.%d.%s.mat', curid, res.objectid, cls);
  
  fg{end+1} = res;
  
  if length(fg) == MAXLENGTH
    save(streamname,'fg');
    return; 
  end
end

save(streamname, 'fg');