# launch_runs starts a new Vivado interpreter for each run. Carry the make
# worker limit into those interpreters as well as the project launcher.
if {[info exists ::env(VIVADO_MAX_THREADS)]} {
    set_param general.maxThreads $::env(VIVADO_MAX_THREADS)
}
