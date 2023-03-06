Kernel with Kernel/install-lnx2-multi_v7-kernel.sh



config file creates ok. make stops at error:
HOSTCXX scripts/gcc-plugins/arm_ssp_per_task_plugin.so
scripts/gcc-plugins/arm_ssp_per_task_plugin.c: In function ‘unsigned int arm_pertask_ssp_rtl_execute()’:
scripts/gcc-plugins/arm_ssp_per_task_plugin.c:37:34: error: ‘gen_load_tp_hard’ was not declared in this scope
   37 |                 emit_insn_before(gen_load_tp_hard(current), insn);
      |                                  ^~~~~~~~~~~~~~~~

As per internet search, I added packages libgmp3-dev libmpc-dev ibssl-dev
