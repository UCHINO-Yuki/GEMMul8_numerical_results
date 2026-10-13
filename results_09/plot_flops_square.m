function plot_flops_square(ARCH,PREC)

arguments (Input)
    ARCH (1,1) string = "GB200";
    PREC (1,1) string = "d";
end
ARCH = upper(ARCH);

if strcmp(ARCH,"RTX5080")
    DRIVER = "Driver 615.71.09";
    HOST = "GCC 11.5";
    TOOLKIT= "CUDA Toolkit 13.4.2";
else
    DRIVER = "Driver 580.178.04";
    HOST = "GCC 13.3";
    TOOLKIT= "CUDA Toolkit 13.4.2";
end

%% get CSV
DIR = ARCH + "/";
if strcmp(ARCH,"RTX5080")
    if strcmp(PREC,"d")
        FILEMAME = "oz2_results_" + PREC + "gemm_time_square_n_n_8589934592bytes*";
    else
        FILEMAME = "oz2_results_" + PREC + "gemm_time_square_n_n_8589934592*";
    end
else
    if strcmp(PREC,"d")
        FILEMAME = "oz2_results_" + PREC + "gemm_time_square_n_n_*";
    else
        FILEMAME = "oz2_results_" + PREC + "gemm_time_square_n_n_128*";
    end
end
CSV = dir(DIR + FILEMAME);
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

PARAMs = extractAfter(CSV_name,"time_square");
PARAMs = extractBefore(PARAMs,"_" + VENDER);

i = contains(PARAMs,"_nonunit");
PARAMs(i) = replace(PARAMs(i),"_nonunit","");

%% get values from csv
N      = cell(CSV_num,1);
K      = cell(CSV_num,1);
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
    data.SelectedVariableNames = idx;
    K{i} = readmatrix(CSV_name(i),data);
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
FigHeight  = 450;
FontSize   = 11;
FontName   = "Yu Gothic UI Semibold";
MarkerSize = 5;
LineWidth  = 1.5;

if strcmp(ARCH,"RTX5080")
    if strcmp(PREC,"d")
        SIZE = [1024 2048 4096 8192 16384];
    else
        SIZE = [1024 2048 4096 8192];
    end
else
    SIZE = [1024 2048 4096 8192 16384 32768];
end

if strcmp(PREC,"d")
    NMOD_i8 = 13;
    NMOD_f8 = 9;
else
    NMOD_i8 = 14;
    NMOD_f8 = 10;
end
cuBLAS_emu      = "cublas_FP64emu-55";
cuBLAS_emu_NAME = "cuBLAS emu. (55-bit)";

Oz2_i8 = "OS2-i8-fast-" + NMOD_i8;
Oz2_f8 = "OS2-f8-fast-" + NMOD_f8;
if strcmp(PREC,"d")
    inc_i8 = 2;
    inc_f8 = 3;
else
    inc_i8 = 3;
    inc_f8 = 2;
end
Oz2_i8_2 = "OS2-i8-fast-" + (NMOD_i8+inc_i8);
Oz2_f8_2 = "OS2-f8-fast-" + (NMOD_f8+inc_f8);
native = upper(PREC) + "GEMM";

Oz2_i8_NAME = "GEMMul8 I8 " + NMOD_i8 + "-" + (NMOD_i8+inc_i8);
Oz2_f8_NAME = "GEMMul8 F8 " + NMOD_f8 + "-" + (NMOD_f8+inc_f8);
native_NAME = "native FP64 " + native;

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
    tflops_Oz2_i8_2   = nan(length(SIZE),1);
    tflops_Oz2_f8     = nan(length(SIZE),1);
    tflops_Oz2_f8_2   = nan(length(SIZE),1);

    flag_cuBLAS_emu = false;
    flag_native     = false;
    flag_Oz2_i8     = false;
    flag_Oz2_f8     = false;
    flag_Oz2_i8_2   = false;
    flag_Oz2_f8_2   = false;
    flag_SIZE       = false;
    plotSIZE        = [];
    for n = SIZE
        idx = (N{i} == n) & (K{i} == n) & strcmp(FUNC{i}, native);
        if any(idx)
            tflops_native(n == SIZE) = TFLOPS{i}(idx);
            flag_SIZE   = true;
            flag_native = true;
        end

        idx = (N{i} == n) & (K{i} == n) & strcmp(FUNC{i}, cuBLAS_emu);
        if any(idx)
            tflops_cuBLAS_emu(n == SIZE) = TFLOPS{i}(idx);
            flag_SIZE       = true;
            flag_cuBLAS_emu = true;
        end

        idx = (N{i} == n) & (K{i} == n) & strcmp(FUNC{i}, Oz2_i8);
        if any(idx)
            tflops_Oz2_i8(n == SIZE) = TFLOPS{i}(idx);
            flag_SIZE   = true;
            flag_Oz2_i8 = true;
        end

        idx = (N{i} == n) & (K{i} == n) & strcmp(FUNC{i}, Oz2_f8);
        if any(idx)
            tflops_Oz2_f8(n == SIZE) = TFLOPS{i}(idx);
            flag_SIZE   = true;
            flag_Oz2_f8 = true;
        end

        idx = (N{i} == n) & (K{i} == n) & strcmp(FUNC{i}, Oz2_i8_2);
        if any(idx)
            tflops_Oz2_i8_2(n == SIZE) = TFLOPS{i}(idx);
            flag_SIZE   = true;
            flag_Oz2_i8_2 = true;
        end

        idx = (N{i} == n) & (K{i} == n) & strcmp(FUNC{i}, Oz2_f8_2);
        if any(idx)
            tflops_Oz2_f8_2(n == SIZE) = TFLOPS{i}(idx);
            flag_SIZE   = true;
            flag_Oz2_f8_2 = true;
        end

        if flag_SIZE
            plotSIZE = [plotSIZE,n];
        end
    end

    x = 1:length(plotSIZE);
    if flag_Oz2_i8
        % plot(x,tflops_Oz2_i8,mark(1,4,4), ...
        %     'DisplayName',Oz2_i8_NAME, ...
        %     'MarkerSize',MarkerSize, ...
        %     'LineWidth',LineWidth);
        x2 = [x, fliplr(x)];
        inBetween = [tflops_Oz2_i8', fliplr(tflops_Oz2_i8_2')];
        fill(x2,inBetween,'b','DisplayName',Oz2_i8_NAME);
    end
    if flag_Oz2_f8
        % plot(x,tflops_Oz2_f8,mark(1,2,6), ...
        %     'DisplayName',Oz2_f8_NAME, ...
        %     'MarkerSize',MarkerSize, ...
        %     'LineWidth',LineWidth);
        x2 = [x, fliplr(x)];
        inBetween = [tflops_Oz2_f8', fliplr(tflops_Oz2_f8_2')];
        fill(x2,inBetween,'m','DisplayName',Oz2_f8_NAME);
    end
    if flag_cuBLAS_emu
        plot(x,tflops_cuBLAS_emu,mark(1,3,5), ...
            'DisplayName',cuBLAS_emu_NAME, ...
            'MarkerSize',MarkerSize+4, ...
            'LineWidth',LineWidth);
    end
    if flag_native
        plot(x,tflops_native,mark(3,8,1), ...
            'DisplayName',native_NAME, ...
            'MarkerSize',MarkerSize+4, ...
            'LineWidth',LineWidth);
    end

    xlim([1 length(plotSIZE)]);
    xticks(x);
    xticklabels("2^{" + log2(plotSIZE) + "}");
    xtickangle(0);
    ylim('padded');
    yls{i} = ylim;

    grid on;
    xlabel("\it" + XLABEL,'Interpreter','tex','FontName',FontName);
    ylabel('TFLOP/s','FontName',FontName);
    tile.TileSpacing = "none";
    tile.Padding = "compact";
    set(gca,'FontSize',FontSize,'FontName',FontName);
    title(tile, {ARCH + ", " + HOST, TOOLKIT + ", " + DRIVER},'FontName',FontName,'FontSize',FontSize)

    lgd = legend('Interpreter','tex','FontName',FontName,'IconColumnWidth',20,'NumColumns',1);
    lgd.Layout.Tile = 'north';

    axs{i} = gca;
end

%% adjust ylim
yl = [inf,0];
for i=1:CSV_num
    yl(1) = min(yl(1),yls{i}(1));
    yl(2) = max(yl(2),yls{i}(2));
end

yl = ylim;
inc = 5;
if yl(2)>100
    inc = 10;
end
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
    DIR_FIG = DIR;
    fig_name = DIR_FIG + ARCH + "_throughput_" + native;
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
