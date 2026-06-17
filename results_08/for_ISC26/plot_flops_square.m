function plot_flops_square(ARCH,PREC)
%
%PLOT_FLOPS_SQUARE(ARCH,PREC,OP)
%
%   ARCH: Architecture Name      (string: "GB200", "H100", etc.)
%   PREC: Precision              (string: "s", "d", "c", or "z")
%   OP  : Operation Name         (string: "gemm","trmm","trsm","trtrmm", etc.)
%
arguments (Input)
    ARCH (1,1) string = "MI300X";
    PREC (1,1) string {mustBeMember(PREC,["s","d","c","z"])} = "z";
end
OP = "gemm";
ARCH = upper(ARCH);
PREC = lower(PREC);
OP   = lower(OP);

%% get CSV
DIR = ARCH + "/";
CSV = dir(DIR + "oz2_results_" + PREC + "*");
CSV_num = length(CSV);
CSV_name = strings(CSV_num,1);
for i=1:CSV_num
    CSV_name(i) = DIR + CSV(i).name;
end

%% get parameters
if contains(CSV_name(1), "NVIDIA")
    VENDER = "NVIDIA";
elseif contains(CSV_name(1), "AMD")
    VENDER = "AMD";
else
    VENDER = "";
end
if strcmp(OP, "trtrmm")
    PARAMs = extractAfter(CSV_name,"time");
    PARAMs = extractBefore(PARAMs,"_nonunit_" + VENDER);
else
    PARAMs = extractAfter(CSV_name,"time_square");
    PARAMs = extractBefore(PARAMs,"_" + VENDER);
end

i = contains(PARAMs,"_nonunit");
PARAMs(i) = replace(PARAMs(i),"_nonunit","");

%% get values from csv
N      = cell(CSV_num,1);
FUNC   = cell(CSV_num,1);
TFLOPS = cell(CSV_num,1);
mnk = [];
for i=1:CSV_num
    data = detectImportOptions(CSV_name(i));

    idx = find(strcmp(data.VariableNames,"m"));
    if i == 1 && any(idx)
        mnk = [mnk, "m"];
    end

    idx = find(strcmp(data.VariableNames,"n"));
    data.SelectedVariableNames = idx;
    N{i} = readmatrix(CSV_name(i),data);
    if i == 1
        mnk = [mnk, "n"];
    end

    idx = find(strcmp(data.VariableNames,"k"));
    if i == 1 && any(idx)
        mnk = [mnk, "k"];
    end

    idx = find(contains(data.VariableNames,"unction"));
    data.SelectedVariableNames = idx;
    FUNC{i} = readmatrix(CSV_name(i),data);

    idx = find(contains(data.VariableNames,"TFLOPS"));
    data.SelectedVariableNames = idx;
    TFLOPS{i} = readmatrix(CSV_name(i),data);
end
XLABEL = join(mnk,"=");

%% plot configuration
FigWidth   = 350;
FigHeight  = 350;
FontSize   = 11;
FontName   = "Yu Gothic UI Semibold";
MarkerSize = 5;
LineWidth  = 1;

SIZE = [1024 2048 4096 8192 16384 32768];

PEAK = 163.4;

if strcmp(PREC,"c")
    NMOD_i8 = 8;
    NMOD_f8 = 6;
    bits = 32;
    cuBLAS_emu      = "BF16x9";
    cuBLAS_emu_NAME = "cuBLAS BF16x9";
elseif strcmp(PREC,"z")
    NMOD_i8 = 15;
    NMOD_f8 = 12;
    bits = 64;
    cuBLAS_emu      = "OS1-7";
    cuBLAS_emu_NAME = "cuBLAS Ozaki-I-7";
end

Oz2_i8 = "OS2-i8-accu-" + NMOD_i8;
Oz2_f8 = "OS2-f8-accu-" + NMOD_f8;
native = upper(PREC) + upper(OP);

Oz2_i8_NAME = "GEMMul8-I8-" + NMOD_i8;
Oz2_f8_NAME = "GEMMul8-F8-" + NMOD_f8;
native_NAME = "native FP" + bits + " " + native;
if strcmp(OP, "trtrmm")
    native_NAME = native_NAME + " (GEMM)";
    cuBLAS_emu_NAME = cuBLAS_emu_NAME + " (GEMM)";
end

%% plot
figs = cell(CSV_num,1);
axs  = cell(CSV_num,1);
yls  = cell(CSV_num,1);
for i=1:CSV_num
    figs{i} = figure('Position',[50,50,FigWidth,FigHeight]);
    tile   = tiledlayout(1,1);
    nexttile;
    hold on;

    tflops_native     = nan(length(SIZE),1);
    tflops_cuBLAS_emu = nan(length(SIZE),1);
    tflops_Oz2_i8     = nan(length(SIZE),1);
    tflops_Oz2_f8     = nan(length(SIZE),1);

    flag_cuBLAS_emu = false;
    flag_native     = false;
    flag_Oz2_i8     = false;
    flag_Oz2_f8     = false;
    flag_SIZE       = false;
    plotSIZE        = [];
    for n = SIZE
        if strcmp(OP, "trtrmm")
            idx = (N{i} == n) & contains(FUNC{i}, "TRTRMM");
        else
            idx = (N{i} == n) & strcmp(FUNC{i}, native);
        end
        if any(idx)
            tflops_native(n == SIZE) = TFLOPS{i}(idx);
            flag_SIZE   = true;
            flag_native = true;
        end

        idx = (N{i} == n) & strcmp(FUNC{i}, cuBLAS_emu);
        if any(idx)
            tflops_cuBLAS_emu(n == SIZE) = TFLOPS{i}(idx);
            flag_SIZE       = true;
            flag_cuBLAS_emu = true;
        end

        idx = (N{i} == n) & strcmp(FUNC{i}, Oz2_i8);
        if any(idx)
            tflops_Oz2_i8(n == SIZE) = TFLOPS{i}(idx);
            flag_SIZE   = true;
            flag_Oz2_i8 = true;
        end

        idx = (N{i} == n) & strcmp(FUNC{i}, Oz2_f8);
        if any(idx)
            tflops_Oz2_f8(n == SIZE) = TFLOPS{i}(idx);
            flag_SIZE   = true;
            flag_Oz2_f8 = true;
        end

        if flag_SIZE
            plotSIZE = [plotSIZE,n];
        end
    end

    x = 1:length(plotSIZE);

    plot(x,ones(size(x)) * PEAK,mark(1,2,6), ...
        'DisplayName',"native FP" + bits + " theoretical", ...
        'MarkerSize',MarkerSize, ...
        'LineWidth',LineWidth);

    if flag_native
        plot(x,tflops_native,mark(3,8,1), ...
            'DisplayName',native_NAME, ...
            'MarkerSize',MarkerSize+4, ...
            'LineWidth',LineWidth);
    end
    if flag_cuBLAS_emu
        plot(x,tflops_cuBLAS_emu,mark(1,3,5), ...
            'DisplayName',cuBLAS_emu_NAME, ...
            'MarkerSize',MarkerSize, ...
            'LineWidth',LineWidth);
    end
    if flag_Oz2_i8
        plot(x,tflops_Oz2_i8,mark(1,4,4), ...
            'DisplayName',Oz2_i8_NAME, ...
            'MarkerSize',MarkerSize, ...
            'LineWidth',LineWidth);
    end
    % if flag_Oz2_f8
    %     plot(x,tflops_Oz2_f8,mark(1,2,6), ...
    %         'DisplayName',Oz2_f8_NAME, ...
    %         'MarkerSize',MarkerSize, ...
    %         'LineWidth',LineWidth);
    % end

    xlim([1 nnz(isfinite(tflops_Oz2_i8))]);
    xticks(x);
    xticklabels("2^{" + log2(plotSIZE) + "}");
    xtickangle(0);
    ylim('padded');
    yls{i} = ylim;
    axis square;
    grid on;
    xlabel("\it" + XLABEL,'Interpreter','tex','FontName',FontName);
    ylabel('TFLOP/s','FontName',FontName);
    tile.TileSpacing = "tight";
    tile.Padding = "compact";
    set(gca,'FontSize',FontSize,'FontName',FontName);

    lgd = legend('Interpreter','tex','FontName',FontName,'IconColumnWidth',15,'NumColumns',1);
    if strcmp(PREC,"c")
        lgd.Location = 'southeast';
    else
        lgd.Location = 'northwest';
    end
    param = replace(PARAMs{i},"_","\_");
    TITLE = native + param;
    title(TITLE,'FontSize',FontSize,'FontName',FontName);

    axs{i} = gca;
end

%% adjust ylim
yl = [inf,0];
for i=1:CSV_num
    yl(1) = min(yl(1),yls{i}(1));
    yl(2) = max(yl(2),yls{i}(2));
end

yl = ylim;
inc = 10;
if yl(2)>200
    inc = 20;
end
if yl(2)>300
    inc = 30;
end

for i=1:CSV_num
    ylim(axs{i},yl);
    yticks(axs{i},0:inc:600);
end

%% save figure
for i=1:CSV_num
    DIR_FIG = DIR + "fig/";
    fid_dir = dir(DIR_FIG);
    if isempty(fid_dir)
        mkdir(DIR_FIG);
    end
    fig_name = lower(DIR_FIG + ARCH + "_" + native + PARAMs{i});
    savefig(figs{i},fig_name);
    exportgraphics(figs{i},fig_name + ".png",'Resolution',600);
end

end

%%
function m = mark(i,j,k)
lines = {"-",":","--",""};
markers = {"", "o", "x", "d", "p", "+", ".", "s", "h", "^", "v", ">", "<"};
colors = {"k", "c", "r", "b", "g", "m"};
m = lines{i} + markers{j} + colors(k);
end
