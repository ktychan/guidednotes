set_tex_cmds( '--shell-escape %O %S' );
$pdf_mode = 4;  # 4 is lualatex, 5 is xelatex
$dvi_mode = 0;
$postscript_mode = 0;
$do_cd = 1;

$pdf_previewer = "open -a Skim";

$out_dir = "build";
$aux_dir = "build/aux";
