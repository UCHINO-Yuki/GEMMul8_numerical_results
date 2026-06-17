function plot_accuracy(ARCH,PREC)
%
%PLOT_FLOPS_SQUARE(ARCH,PREC)
%
%   ARCH: Architecture Name      (string: "GB200", "H100", etc.)
%   PREC: Precision              (string: "c" or "z")
%
% for gemm
arguments (Input)
    ARCH (1,1) string = "GB200";
    PREC (1,1) string {mustBeMember(PREC,["c","z"])} = "c";
end
ARCH = upper(ARCH);
PREC = lower(PREC);

FontSize = 12;

%% get CSV
DIR = "for_ISC26/" + ARCH + "/";
CSV = dir(DIR + "oz2_results_" + PREC + "gemm_accuracy_*");
CSV_name = DIR + CSV.name;

%% get values from csv
data = detectImportOptions(CSV_name);

data.SelectedVariableNames = 1;
PHI = readmatrix(CSV_name,data);
PHI(1) = [];

data.SelectedVariableNames = 4;
K = readmatrix(CSV_name,data);
K(1) = [];

data.SelectedVariableNames = 5;
FUNC = readmatrix(CSV_name,data);
FUNC(1) = [];

data.SelectedVariableNames = 6:length(data.VariableNames);
TABLE = readmatrix(CSV_name,data);
MODULI = TABLE(1,:);
ERROR = TABLE(2:end,:);

if strcmp(PREC,"z")
ERROR = ERROR(:,12 <= MODULI & MODULI <= 18);
MODULI = MODULI(12 <= MODULI & MODULI <= 18);
end

%% plot
phi = 0.5;
idx_phi = (PHI == phi);
k = 65536;
idx_k = (K == k);
FontName   = "Yu Gothic UI Semibold";
MarkerSize = 5;
LineWidth  = 1;

if strcmp(PREC,"c")
    bits = 32;
    cuBLAS_emu      = "BF16x9";
    cuBLAS_emu_NAME = "cuBLAS BF16x9";
elseif strcmp(PREC,"z")
    bits = 64;
    cuBLAS_emu      = "OS1-7";
    cuBLAS_emu_NAME = "cuBLAS Ozaki-I-7";
end

fig = figure('Position',[50,50,250,400]);
t = tiledlayout(1,1);
nexttile; hold on; grid on;

idx_func = FUNC == (upper(PREC) + "GEMM");
idx = idx_func & idx_phi & idx_k;
err = ERROR(idx,:);
plot(MODULI,err,mark(1,2,1), ...
    'DisplayName',"native FP" + bits, ...
    'MarkerSize',MarkerSize+4, ...
    'LineWidth',LineWidth);

idx_func = FUNC == cuBLAS_emu;
idx = idx_func & idx_phi & idx_k;
err = ERROR(idx,:);
plot(MODULI,err,mark(1,1,3), ...
    'DisplayName',cuBLAS_emu_NAME, ...
    'MarkerSize',MarkerSize+4, ...
    'LineWidth',LineWidth);

idx_func = FUNC == ("OS2-i8-accu");
idx = idx_func & idx_phi & idx_k;
err = ERROR(idx,:);
plot(MODULI,err,mark(1,4,4), ...
    'DisplayName',"Ozaki-II", ...
    'MarkerSize',MarkerSize+4, ...
    'LineWidth',LineWidth);

xlim([min(MODULI), max(MODULI)]);
xticks(MODULI);
xtickangle(0);
set(gca,'FontSize',FontSize,'FontName',FontName,'YScale','Log');
ylim('padded');
yticks(10.^(-18:2:10))

lgd = legend('Interpreter','tex','FontName',FontName,'IconColumnWidth',15,'NumColumns',1);
lgd.Layout.Tile = 'north';
t.TileSpacing = "tight";
t.Padding = "compact";
xlabel("Number of moduli");
ylabel("Max. relative error");
set(gca,'FontSize',FontSize,'FontName','Yu Gothic UI Semibold');

savefig(fig,DIR+ARCH+"_accuracy_"+lower(PREC));
exportgraphics(fig,DIR+ARCH+"_accuracy_"+lower(PREC)+".png",'Resolution',600);

end
