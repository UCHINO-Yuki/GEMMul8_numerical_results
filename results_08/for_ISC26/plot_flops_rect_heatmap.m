function plot_flops_rect_heatmap(ARCH,PREC)
%
%PLOT_FLOPS_SQUARE(ARCH,PREC)
%
%   ARCH: Architecture Name      (string: "GB200", "H100", etc.)
%   PREC: Precision              (string: "c" or "z")
%
% for gemm
arguments (Input)
    ARCH (1,1) string = "GB200";
    PREC (1,1) string {mustBeMember(PREC,["d", "c","z"])} = "d";
end
ARCH = upper(ARCH);
PREC = lower(PREC);

FontSize = 12;

%% get CSV
DIR = ARCH + "/";
CSV = dir(DIR + "oz2_results_" + PREC + "gemm_time_n_n_*");
CSV_name = DIR + CSV.name;

%% get values from csv
data = detectImportOptions(CSV_name);

idx = find(strcmp(data.VariableNames,"m"));
data.SelectedVariableNames = idx;
M = readmatrix(CSV_name,data);

idx = find(strcmp(data.VariableNames,"n"));
data.SelectedVariableNames = idx;
N = readmatrix(CSV_name,data);

idx = find(strcmp(data.VariableNames,"k"));
data.SelectedVariableNames = idx;
K = readmatrix(CSV_name,data);

idx = find(contains(data.VariableNames,"unction"));
data.SelectedVariableNames = idx;
FUNC = readmatrix(CSV_name,data);

idx = find(contains(data.VariableNames,"TFLOPS"));
data.SelectedVariableNames = idx;
TFLOPS = readmatrix(CSV_name,data);

%% make plot data
mn_list = flip(unique(M));
mn_list(mn_list>32768) = [];
k_list  = unique(K);
k_list(k_list>32768) = [];
xvalues = string(k_list);
yvalues = string(mn_list);
if strcmp(PREC,"c")
    bits = 32;
    NMOD_i8 = 8;
    cuBLAS_emu      = "BF16x9";
    cuBLAS_emu_NAME = "cuBLAS BF16x9";
else
    bits = 64;
    NMOD_i8 = 15;
    cuBLAS_emu      = "OS1-7";
    cuBLAS_emu_NAME = "cuBLAS Ozaki-I-7";
end

cdata1 = nan(length(mn_list),length(k_list));
idx_func = FUNC == ("OS2-i8-accu-" + NMOD_i8);
for i=1:length(mn_list)
    idx_mn = mn_list(i) == M;
    for j=1:length(k_list)
        idx_k = k_list(j) == K;
        idx = idx_func & idx_mn & idx_k;
        if any(idx)
            cdata1(i,j) = TFLOPS(idx);
        end
    end
end

cdata2 = nan(length(mn_list),length(k_list));
idx_func = FUNC == cuBLAS_emu;
for i=1:length(mn_list)
    idx_mn = mn_list(i) == M;
    for j=1:length(k_list)
        idx_k = k_list(j) == K;
        idx = idx_func & idx_mn & idx_k;
        if any(idx)
            cdata2(i,j) = TFLOPS(idx);
        end
    end
end

cdata3 = nan(length(mn_list),length(k_list));
idx_func = FUNC == (upper(PREC) + "GEMM");
for i=1:length(mn_list)
    idx_mn = mn_list(i) == M;
    for j=1:length(k_list)
        idx_k = k_list(j) == K;
        idx = idx_func & idx_mn & idx_k;
        if any(idx)
            cdata3(i,j) = TFLOPS(idx);
        end
    end
end

round(cdata1./cdata3,1)
round(cdata2./cdata3,1)

clim_common = [min( [min(cdata1(:),[],'omitnan'), min(cdata2(:),[],'omitnan'), min(cdata3(:),[],'omitnan')] ), ...
               max( [max(cdata1(:),[],'omitnan'), max(cdata2(:),[],'omitnan'), max(cdata3(:),[],'omitnan')] )];

%% plot
fig = figure('Position',[50 50 480 270]);
h = heatmap(xvalues,yvalues,cdata1,Colormap=flip(autumn),ColorLimits=clim_common);
% h.ColorbarVisible = 'off';
h.CellLabelFormat = '%0.3g';
h.ColorData
xlabel("\it k");
ylabel("\it m = n");
TITLE = "TFLOP/s of Ozaki-II " + NMOD_i8 + " moduli";
title(TITLE);
set(gca,'FontName','Yu Gothic UI Semibold');
set(gca,'FontSize',FontSize);

savefig(fig, DIR+ARCH+"_heatmap_"+lower(PREC)+"gemm_"+"Ozaki2");
exportgraphics(fig, DIR+ARCH+"_heatmap_"+lower(PREC)+"gemm_"+"Ozaki2"+".png",'Resolution',600);

fig = figure('Position',[450 50 480 270]);
h = heatmap(xvalues,yvalues,cdata2,Colormap=flip(autumn),ColorLimits=clim_common);
% h.ColorbarVisible = 'off';
h.CellLabelFormat = '%0.3g';
h.ColorData
xlabel("\it k");
ylabel("\it m = n");
TITLE = "TFLOP/s of " + cuBLAS_emu_NAME;
title(TITLE);
set(gca,'FontName','Yu Gothic UI Semibold');
set(gca,'FontSize',FontSize);

savefig(fig, DIR+ARCH+"_heatmap_"+lower(PREC)+"gemm_"+cuBLAS_emu);
exportgraphics(fig, DIR+ARCH+"_heatmap_"+lower(PREC)+"gemm_"+cuBLAS_emu+".png",'Resolution',600);

fig = figure('Position',[850 50 480 270]);
h = heatmap(xvalues,yvalues,cdata3,Colormap=flip(autumn),ColorLimits=clim_common);
% h.ColorbarVisible = 'off';
h.CellLabelFormat = '%0.3g';
h.ColorData
xlabel("\it k");
ylabel("\it m = n");
TITLE = "TFLOP/s of native FP" + bits;
title(TITLE);
set(gca,'FontName','Yu Gothic UI Semibold');
set(gca,'FontSize',FontSize);

savefig(fig, DIR+ARCH+"_heatmap_"+lower(PREC)+"gemm_native");
exportgraphics(fig, DIR+ARCH+"_heatmap_"+lower(PREC)+"gemm_native.png",'Resolution',600);
end
