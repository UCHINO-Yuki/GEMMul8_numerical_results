function plot_accuracy(ARCH, PREC)

arguments (Input)
    ARCH (1,1) string = "GB200"
    PREC (1,1) string = "d";
end

close all
clc

FontSize = 8;
type_in = PREC;

%% get data
dir_name = dir(ARCH + "/oz2_results_" + type_in + "gemm_accuracy*");
file_name = ARCH + "/" + dir_name.name;
data = detectImportOptions(file_name);

idx = 1;
data.SelectedVariableNames = idx;
data_phi = readmatrix(file_name,data);
data_phi = data_phi(2:end,:);

idx = 4;
data.SelectedVariableNames = idx;
data_k = readmatrix(file_name,data);
data_k = data_k(2:end,:);

idx = 5;
data.SelectedVariableNames = idx;
data_func = readmatrix(file_name,data);
data_func = data_func(2:end,:);

data.SelectedVariableNames = idx+1:length(data.VariableNames);
data_err = readmatrix(file_name,data);
data_moduli = data_err(1,:);
data_err = data_err(2:end,:);

%% plot
yl_min = inf;
yl_max = 0;
phi = [-1, 1, 4, 8];
fig = figure('Position',[50,50,650,300]);
t = tiledlayout(1,length(phi));
for tid = 1:length(phi)
    nexttile; hold on; grid on;

    for k = [max(data_k)]

        idx = strcmp(data_func,upper(PREC)+"GEMM") & data_k == k & data_phi == phi(tid);
        err = data_err(idx,:);
        plot(data_moduli, err, mark(1,1,1), 'DisplayName', "native FP64 " + upper(PREC)+"GEMM", 'MarkerSize',5, 'LineWidth',1.5);
        err_1 = err ./ 5;
        err_2 = err .* 5;

        idx = contains(data_func,"cublas_FP64emu-55") & data_k == k & data_phi == phi(tid);
        err = data_err(idx,:);
        plot(data_moduli, err, mark(1,1,5), 'DisplayName', "cuBLAS emulation (55-bit)", 'MarkerSize',5, 'LineWidth',1.5);
        err_3 = err ./ 5;
        err_4 = err .* 5;

        idx = contains(data_func,"OS2-i8-fast") & data_k == k & data_phi == phi(tid);
        err = data_err(idx,:);
        plot(data_moduli, err, mark(1,1,3), 'DisplayName', "GEMMul8 INT8", 'MarkerSize',5, 'LineWidth',1.5);
        err_i8 = err;

        idx = contains(data_func,"OS2-f8-fast") & data_k == k & data_phi == phi(tid);
        err = data_err(idx,:);
        plot(data_moduli, err, mark(1,1,4), 'DisplayName', "GEMMul8 FP8", 'MarkerSize',5, 'LineWidth',1.5);
        err_f8 = err;

        xlim([min(data_moduli), max(data_moduli)]);
        xticks(data_moduli);

    end

    if phi(tid)<0
        title("Std. normal", 'Interpreter','tex');
    else
        title("{\it\phi = " + phi(tid) + "}", 'Interpreter','tex');
    end
    set(gca,'FontSize',FontSize,'FontName','Yu Gothic UI Semibold','YScale','Log');
    ylim('padded');
    yl_tmp = ylim;
    yl_min = min(yl_min, yl_tmp(1));
    yl_max = max(yl_max, yl_tmp(2));
end

for tid = 1:length(phi)
    nexttile(tid);
    ylim([yl_min, yl_max]);
    yticks(10.^(-20:4:20));
    if tid > 1
        yticklabels([]);
    end
end

lgd = legend('Interpreter','tex','FontName','Yu Gothic UI Semibold','IconColumnWidth',15,'NumColumns',4);
lgd.Layout.Tile = 'north';
t.TileSpacing = "tight";
t.Padding = "compact";
xlabel(t,"Number of moduli",'FontName','Yu Gothic UI Semibold');
ylabel(t,"Max. relative error",'FontName','Yu Gothic UI Semibold');
title(t,"\itk = " + max(data_k),'FontName','Yu Gothic UI Semibold')
set(gca,'FontSize',FontSize,'FontName','Yu Gothic UI Semibold');

savefig(fig,ARCH+"/"+lower(ARCH)+"_accuracy_"+type_in+"gemm");
exportgraphics(fig,ARCH+"/"+lower(ARCH)+"_accuracy_"+type_in+"gemm"+".png",'Resolution',600);
end

%%
function m = mark(i,j,k)
lines = {"-",":","--",""};
markers = {"", "o", "x", "d", "p", "+", ".", "s", "h", "^", "v", ">", "<"};
colors = {"k", "c", "r", "b", "g", "m"};
m = lines{i} + markers{j} + colors(k);
end
