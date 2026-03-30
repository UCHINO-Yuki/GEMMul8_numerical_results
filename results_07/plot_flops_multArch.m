function plot_flops_multArch

GPUs = ["GH200", "B200"];
TYPE = ["d",
file_name_i8 = "GH200/oz2_results_i_d_time*";
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