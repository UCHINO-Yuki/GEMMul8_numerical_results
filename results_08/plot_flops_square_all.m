function plot_flops_square_all(ARCH)
%
%PLOT_FLOPS_SQUARE_ALL(ARCH)
%
%   ARCH: Architecture Name      (string: "GB200", "H100", etc.)
%
arguments (Input)
    ARCH (1,1) string = "GB200";
end
ARCH = upper(ARCH);

OP_list = [];
% OP_list = [OP_list, "gemm"];
% OP_list = [OP_list, "symm"];
% OP_list = [OP_list, "syrk"];
% OP_list = [OP_list, "syr2k"];
% OP_list = [OP_list, "syrkx"];
% OP_list = [OP_list, "hemm"];
% OP_list = [OP_list, "herk"];
% OP_list = [OP_list, "her2k"];
% OP_list = [OP_list, "herkx"];
% OP_list = [OP_list, "trmm"];
% OP_list = [OP_list, "trsm"];
OP_list = [OP_list, "trtrmm"];

PREC_list = ["s","d","c","z"];

for OP = OP_list
    for PREC = PREC_list
        if contains(OP,"he")
            if strcmp(PREC,"s") || strcmp(PREC,"d")
                continue;
            end
        end
        disp("... " + PREC + OP);
        plot_flops_square(ARCH,PREC,OP)
    end
    close all
end

end