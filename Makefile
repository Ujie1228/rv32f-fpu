# ==========================================
# ModelSim Makefile for SystemVerilog
# ==========================================

# 1. 设置你的测试文件顶层模块名 (注意：是模块名 module name，不是文件名)
# 假设你的 FPU 测试顶层模块叫 tb_rv32f_fpu
TB_TOP = tb_rv32f_fpu

# 2. 设置包含所有的 SystemVerilog 源文件
# 这里使用通配符匹配当前目录下所有 .sv 文件
SRC_FILES = *.sv

# ==========================================

# 工具命令
VLIB = vlib
VLOG = vlog
VSIM = vsim

# 默认执行动作
all: clean compile sim

# 创建工作库
lib:
	$(VLIB) work

# 编译所有 SystemVerilog 代码
compile: lib
	$(VLOG) -sv -work work $(SRC_FILES)

# 命令行模式仿真 (不弹窗，直接在 VSCode 终端看打印的 $display 结果)
sim: compile
	$(VSIM) -c -work work -voptargs="+acc" $(TB_TOP) -do "run -all; quit"

# GUI模式仿真 (一键编译并自动打开 ModelSim 波形界面)
gui: compile
	$(VSIM) -work work -voptargs="+acc" $(TB_TOP) -do "add wave -r /*; run -all"

# 清理生成的仿真文件 (使用 CMD 的 rd 和 del 命令)
clean:
	@if exist work rd /s /q work
	@if exist transcript del /q transcript
	@if exist vsim.wlf del /q vsim.wlf