##########################
######## variables #######
######## commands  #######
##########################

#list your verilog files in srcPath/sourcefile_order
#the order of the files in that file is important.

srcPath := ./src
#script to add vcs to path variables, so that it can be run:
sourceVcs = source /users/micas/kgoetsch/software/path/add_vcs_to_path
topmodule := tbench_top
#base vcs command that is common between different targets
vcsBaseCommand =  vcs -full64 -sverilog -timescale=1ns/1ps +notimingchecks  -notice -top $(topmodule)
#the arguments specifying output files
vcsFiles = -l ../log/compile \
-o ../out/simv \
-f sourcefile_order

#make the directories for the outputs if they don't exist yet
makedirs = mkdir -p log csrc $(shell realpath linter) linter/csrc linter/log linter/out out

vcsCompileCommand =  $(vcsBaseCommand) -Mdir=../csrc $(cmdcompileargs) $(vcsFiles)
vcsCoverageOptions =  -cm line+cond+fsm+tgl+branch
vcsCoverageCommand = $(vcsBaseCommand) -Mdir=../csrc $(vcsCoverageOptions) $(vcsFiles)

##########################
######### targets ########
##########################

test:
	echo $(vcsCompileCommand)

###########
# general #
###########
no_target:
	echo "give a usefull target"
#removes output to start over clean
clean:
	rm -rf verification_data/*
	rm -rf out/*
	rm -rf log/* inter.vpd csrc/* vc_hdrs.h
	rm -rf linter/out/* linter/log/* vc_hdrs.h linter/csrc/*

clean_linter:
	rm -rf linter/out/* linter/log/* vc_hdrs.h linter/csrc/*

cl: clean_linter

#just a shorthand
all: compile run
ag: compile_gui run

#opens a graphical file explorer on the source folder
browsesource:
	nautilus src &>/dev/null &
editsource:
	/users/micas/kgoetsch/software/atom/atom >/dev/null &


###########
# compile #
###########
#Compiles the source into an executable simulator (out/simv)
compile:
	$(makedirs)
	$(sourceVcs);\
	cd $(srcPath); \
	$(vcsCompileCommand)


#################
#atom vcs linter#
#################
#It can be used with atom vcs linter.
.SILENT: linter
.PHONY: linter
linter:
	$(makedirs)
	$(sourceVcs);\
	cd $(srcPath); \
	pwd; \
	echo "test" ;\
	($(vcsBaseCommand) -j7 -Mdir=../linter/csrc  -l ../linter/log/compile -o ../linter/out/simv -f sourcefile_order 2>&1) || true

.SILENT: install_atom_vcs_linter
install_atom_vcs_linter:
	echo 'Please install linter and linter-ui-default packages through edit, preferences, install. Then exit atom'
	read -p 'Press enter to continue'
	/users/micas/kgoetsch/software/atom/atom
	echo 'Installing atom-vcs-linter'
	mkdir -p ~/.atom/packages && cd ~/.atom/packages && git clone https://github.com/KoenGoe/atom-vcs-linter && cd atom-vcs-linter && /users/micas/kgoetsch/software/atom/resources/app/apm/bin/apm install
	echo 'Done'
	echo 'Note: You probably want systemverilog language package as well.'

############
# coverage #
############

#Generates coverage report by: compiling with coverage options and then running with coverage options
coverage:
	$(makedirs)
	$(sourceVcs);\
	cd $(srcPath); \
	$(vcsCoverageCommand); \
	cd ../out; \
	./simv $(vcsCoverageOptions); \
	urg -dir simv.vdb/ -report coverage_report


#Opens the coverage report in the default html viewer (probably browser)
coverage_show:
	xdg-open out/coverage_report/dashboard.html

#######
# run #
#######
#runs the compiled simulator
run:
	out/simv; \


###############
# wave viewer #
###############
#Shows the waveforms dumped by a similator run in gtkwave
gtkwave:
	gtkwave out/dump.vcd &

###########
### GUI ###
###########
compile_gui:
	$(makedirs)
	$(sourceVcs);\
	cd $(srcPath); \
	$(vcsBaseCommand) -Mdir=../csrc -debug_access+all  $(cmdcompileargs)  $(vcsFiles)

cg: compile_gui

run_gui:
	out/simv -gui -vpd_file /tmp/inter$$(whoami).vpd -dve_opt & \


rg: run_gui

gui: compile_gui run_gui
