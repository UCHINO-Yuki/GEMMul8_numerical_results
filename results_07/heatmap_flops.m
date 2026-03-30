function heatmap_flops(type_in,GPU_name)

arguments (Input)
    type_in (1,1) string = "c"
    GPU_name (1,1) string = "B200"
end

close all
FontSize = 14;

%% get data
dir_name_i8  = dir(GPU_name + "/oz2_results_i_" + type_in + "_time*");
m_i8 = [];
if ~isempty(dir_name_i8)
    file_name_i8 = GPU_name + "/" + dir_name_i8.name;
    data_i8 = detectImportOptions(file_name_i8);
    data_i8.SelectedVariableNames = 2;
    m_i8 = readmatrix(file_name_i8,data_i8);
    data_i8.SelectedVariableNames = 4;
    k_i8 = readmatrix(file_name_i8,data_i8);
    data_i8.SelectedVariableNames = 5;
    func_i8 = readmatrix(file_name_i8,data_i8);
    data_i8.SelectedVariableNames = 8;
    tflops_i8 = readmatrix(file_name_i8,data_i8);
end
%% plot
m_list = unique(m_i8);
k_list = unique(k_i8);

fig = figure;
fig.Position(3) = length(k_list)*70;
fig.Position(4) = length(k_list)*50;
cdata = nan(max(length(m_list),length(k_list)));
GEMMdata = nan(max(length(m_list),length(k_list)));
for k = k_list'
    if strcmp(type_in,"s") || strcmp(type_in,"c")
        idx = contains(func_i8,"accu-7") & k_i8 == k;
    else
        idx = contains(func_i8,"accu-15") & k_i8 == k;
    end
    if any(idx)
        tflops = tflops_i8(idx);
        cdata(1:length(tflops),k_list == k) = tflops;
    end

    idx = contains(func_i8,"GEMM") & k_i8 == k;
    if any(idx)
        tflops = tflops_i8(idx);
        GEMMdata(1:length(tflops),k_list == k) = tflops;
    end
end

for i=1:size(cdata,1)
    for j=1:size(cdata,2)
        fprintf('%.3g,', cdata(i,j))
    end
    fprintf('\n');
end

fprintf('\n');
for i=1:size(cdata,1)
    for j=1:size(cdata,2)
        fprintf('%5.3g,', cdata(i,j))
    end
    fprintf('\n');
end

fprintf('\n');
for i=1:size(cdata,1)
    for j=1:size(cdata,2)
        fprintf('%5.3g,', cdata(i,j) >= GEMMdata(i,j))
    end
    fprintf('\n');
end

xvalues = string(k_list);
yvalues = string(flip(k_list));
cdata = flip(cdata);
h = heatmap(xvalues,yvalues,cdata,Colormap=flip(autumn));
h.ColorbarVisible = 'off';
h.CellLabelFormat = '%0.3g';
xlabel("\it k");
ylabel("\it m=n");
TITLE = upper(type_in) + "GEMM TFLOP/s";
title(TITLE);
set(gca,'FontName','Yu Gothic UI Semibold');
set(gca,'FontSize',FontSize);

savefig(fig,GPU_name+"/"+GPU_name+"_heatmap_"+type_in);
exportgraphics(fig,GPU_name+"/"+GPU_name+"_heatmap_"+type_in+".png",'Resolution',600);
end
