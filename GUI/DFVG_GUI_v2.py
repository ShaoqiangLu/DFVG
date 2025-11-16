
import os, sys, time, threading, queue
import tkinter as tk
from tkinter import filedialog, messagebox
from tkinter.scrolledtext import ScrolledText
import ttkbootstrap as tb
from ttkbootstrap.constants import *
#
# ，2025.9.18

#=====================================================
APP_TITLE = "DFVG 交互界面 v1"

# ========= 占位函数（后续替换成你自己的实现） =========
def run_inst(
    bit_path: str
    ):
    print('-'*60)
    print(f"📥 指令写到FPGA：{bit_path}")
    print('-'*60)
    time.sleep(1); print("✅ 指令写完成")

def run_prefill(
    prompt_text: str, 
    prompt_len: int
    ):
    print('-'*60)
    print(f"📦 [Prefill] 模型：{'(默认)'} | Prompt Len={prompt_len}")
    print('-'*60)
    time.sleep(1); 
    print("✅ Prefill 完成")

def run_decode(
    max_new_tokens: int
    ):
    print('-'*60)
    print(f"🎲 [Decode] MaxNew={max_new_tokens}")
    print('-'*60)
    gen_token_num=5
    for i in range(gen_token_num):
        time.sleep(0.2); print(f"✦ token_{i+1}")
    print("✅ Decode 完成")

def run_sampling(
    pram_temp=0,
    pram_topk=0,
    pram_topp=0,
    pram_num=0,
    pram_model=0,
    ):
    print('-'*60)
    print(f"🎯 [Sampling] 次数={pram_num}")
    print('-'*60)
    for i in range(pram_num):
        time.sleep(0.15); print(f"🔎 sample_{i+1}")
    print("✅ Sampling 完成")

# ========= 输出重定向 =========
class TextboxLogger:
    def __init__(self, 
    widget: ScrolledText, 
    line_queue: queue.Queue
    ):
        self.widget= widget
        self.queue = line_queue
        self._orig = sys.stdout
        sys.stdout = self
    def write(self, data):
        if data: self.queue.put(data)
    def flush(self): pass
    def restore(self): sys.stdout = self._orig

# ========= 主应用 =========
class App:
    def __init__(self, root: tb.Window):
        self.root = root
        self.root.title(APP_TITLE)
        # 更大默认尺寸，便于“填满”
        self.root.geometry("1240x720")
        self.root.minsize(960, 640)
        self._build_header()
        self._build_content()
        self._build_statusbar()
        # 日志重定向
        self.log_queue = queue.Queue()
        self.logger = TextboxLogger(self.log_text, self.log_queue)
        self._poll_log()

    #========================================================
    # 顶部栏（Header）
    #========================================================
    def _build_header(self):
        header = tb.Frame(self.root, padding=(16, 10))
        header.pack(fill=X)
        tb.Label(header, text="DFVG: Draft-on-FPGA and Verify-on-GPU ",
                 font=("Microsoft YaHei", 15, "bold")).pack(side=LEFT)
        tb.Button(header, text="关于", bootstyle=SECONDARY,
                command=self._about, width=8).pack(side=RIGHT)#点击触发command=self._about
        tb.Button(header, text="帮助", bootstyle=SECONDARY,
                command=self._help, width=8).pack(side=RIGHT, padx=(0, 8))#点击触发command=self._help


    #========================================================
    # 主体内容（Content）
    #========================================================
    def _build_content(self):
        #一个水平分割的容器（左配置 / 右日志），可以拖动中间分隔条
        body = tb.Panedwindow(self.root, orient=HORIZONTAL)
        body.pack(fill=BOTH, expand=YES, padx=16, pady=(0, 12))

        #========================================================================
        # 左：配置
        #========================================================================
        left = tb.Labelframe(body, text="配置", padding=12, bootstyle=PRIMARY)
        # 让左侧表单可纵向扩展（Prompt 输入能“填满”）
        left.columnconfigure(1, weight=1)         # 输入控件所在列可横向扩展
        left.rowconfigure(5, weight=1)            # Prompt 输入这一行可纵向扩展
        left.rowconfigure(6, weight=1)            # Token 输出这一行也可纵向扩展（新增）
        body.add(left, weight=1)

        #-----------------------------------------------------------------------------------
        #row=0
        #-----------------------------------------------------------------------------------
        tb.Label(left, text="模型Tokenizer").grid(row=0, column=0, sticky=E, pady=6, padx=6)
        self.model_var = tk.StringVar(value="huggingface/Qwen3-8B/Tokenizer")
        tb.Entry(left, textvariable=self.model_var).grid(row=0, column=1, sticky=EW, pady=6)
        tb.Button(left, text="选择", bootstyle=OUTLINE, command=self._select_model)\
            .grid(row=0, column=2, padx=6, pady=6, sticky=E)

        #-----------------------------------------------------------------------------------
        #row=1
        #-----------------------------------------------------------------------------------
        tb.Label(left, text="编译器的指令").grid(row=1, column=0, sticky=E, pady=6, padx=6)
        self.bit_var = tk.StringVar(value="compiler/inst/base/dram_merge_write1.bin")
        tb.Entry(left, textvariable=self.bit_var).grid(row=1, column=1, sticky=EW, pady=6)
        tb.Button(left, text="选择", bootstyle=OUTLINE, command=self._select_bit)\
            .grid(row=1, column=2, padx=6, pady=6, sticky=E)
            
        #-----------------------------------------------------------------------------------
        # row=2: Prefill 参数
        #-----------------------------------------------------------------------------------
        row2 = tb.Frame(left)
        row2.grid(row=2, column=0, columnspan=4, sticky=W, pady=6, padx=(21, 6))

        tb.Label(row2, text="    Prefill地址").pack(side=LEFT, padx=(0, 4))
        self.prefill_addr = tk.IntVar(value=129294176)
        tb.Entry(row2, textvariable=self.prefill_addr, width=10).pack(side=LEFT, padx=(0, 10))

        tb.Label(row2, text=" 输入长").pack(side=LEFT, padx=(0, 4))
        self.prefill_len = tk.IntVar(value=64)
        tb.Spinbox(row2, from_=1, to=32768, textvariable=self.prefill_len, width=7).pack(side=LEFT, padx=(0, 10))

        tb.Label(row2, text="id行数").pack(side=LEFT, padx=(0, 4))
        self.prefill_id_row = tk.IntVar(value=4)
        tb.Spinbox(row2, from_=1, to=32768, textvariable=self.prefill_id_row, width=7).pack(side=LEFT, padx=(0, 10))

        tb.Label(row2, text="logits").pack(side=LEFT, padx=(0, 4))
        self.prefill_lmhead = tk.IntVar(value=2374)
        tb.Entry(row2, textvariable=self.prefill_lmhead, width=8).pack(side=LEFT, padx=(0, 10))

        #-----------------------------------------------------------------------------------
        # row=3: Decode 参数
        #-----------------------------------------------------------------------------------
        row3 = tb.Frame(left)
        row3.grid(row=3, column=0, columnspan=4, sticky=W, pady=6, padx=(21, 6))

        tb.Label(row3, text="Decode地址").pack(side=LEFT, padx=(0, 4))
        self.decode_addr = tk.IntVar(value=129294176)
        tb.Entry(row3, textvariable=self.decode_addr, width=10).pack(side=LEFT, padx=(0, 10))

        tb.Label(row3, text=" 最大的").pack(side=LEFT, padx=(0, 4))
        self.decode_max = tk.IntVar(value=128)
        tb.Spinbox(row3, from_=1, to=32768, textvariable=self.decode_max, width=7).pack(side=LEFT, padx=(0, 10))

        tb.Label(row3, text="当前的").pack(side=LEFT, padx=(0, 4))
        self.decode_cur = tk.IntVar(value=1)
        tb.Spinbox(row3, from_=1, to=32768, textvariable=self.decode_cur, width=7).pack(side=LEFT, padx=(0, 10))

        tb.Label(row3, text=" 数量").pack(side=LEFT, padx=(0, 4))
        self.decode_cnt = tk.IntVar(value=128)
        tb.Spinbox(row3, from_=1, to=32768, textvariable=self.decode_cnt, width=7).pack(side=LEFT, padx=(0, 10))

        #-----------------------------------------------------------------------------------
        # row=4: 参数行
        #-----------------------------------------------------------------------------------
        row4 = tb.Frame(left)
        row4.grid(row=4, column=0, columnspan=4, sticky=W, pady=6, padx=(48, 6))

        # 温度
        tb.Label(row4, text="采样温度").pack(side=LEFT, padx=(0, 4))
        self.temperature = tk.DoubleVar(value=0.6)
        tb.Spinbox(row4, from_=0.0, to=2.0, increment=0.1,
                textvariable=self.temperature, width=7).pack(side=LEFT, padx=(0, 12))

        # Top-K
        tb.Label(row4, text="Top-K").pack(side=LEFT, padx=(0, 4))
        self.topk = tk.IntVar(value=20)
        tb.Spinbox(row4, from_=1, to=100, textvariable=self.topk, width=7).pack(side=LEFT, padx=(0, 12))

        # Top-P
        tb.Label(row4, text="Top-P").pack(side=LEFT, padx=(0, 4))
        self.topp = tk.DoubleVar(value=0.95)
        tb.Spinbox(row4, from_=0.0, to=1.0, increment=0.05,
                textvariable=self.topp, width=7).pack(side=LEFT, padx=(0, 12))

        # 次数
        tb.Label(row4, text="次数").pack(side=LEFT, padx=(0, 4))
        self.sample_count = tk.IntVar(value=1)
        tb.Spinbox(row4, from_=1, to=100, textvariable=self.sample_count, width=7).pack(side=LEFT, padx=(0, 6))

        #-----------------------------------------------------------------------------------
        # Prompt 输入区域 —— “填满”
        #-----------------------------------------------------------------------------------
        tb.Label(left, text="Prompt 输入").grid(row=5, column=0, sticky=NE, pady=(10, 0))
        self.prompt_box = ScrolledText(left, wrap="word")
        self.prompt_box.grid(row=5, column=1, columnspan=3, sticky=NSEW, pady=(6, 0))  # NSEW 扩展

        #-----------------------------------------------------------------------------------
        # Token 输出区域 —— “填满”
        #-----------------------------------------------------------------------------------
        tb.Label(left, text="Token 输出").grid(row=6, column=0, sticky=NE, pady=(10, 0))
        self.token_box = ScrolledText(left, wrap="word")
        self.token_box.grid(row=6, column=1, columnspan=3, sticky=NSEW, pady=(6, 0))


        #-----------------------------------------------------------------------------------
        # 行为按钮
        #-----------------------------------------------------------------------------------
        tb.Button(left, text="发送到 Prefill", bootstyle=INFO, command=self._on_prefill).grid(row=7, column=1, sticky=W, pady=8)
        tb.Button(left, text="清空Prompt", bootstyle=SECONDARY,command=lambda: self.prompt_box.delete("1.0", "end")).grid(row=7, column=2, pady=8, sticky=W, padx=(0, 6))
        tb.Button(left, text="清空Token ", bootstyle=SECONDARY,command=lambda: self.token_box.delete("1.0", "end")).grid(row=7, column=3, pady=8, sticky=W)


        #========================================================================
        # 右：操作 & 日志
        #========================================================================
        right = tb.Labelframe(body, text="操作与日志", padding=12, bootstyle=INFO)
        body.add(right, weight=2)
        right.columnconfigure(0, weight=1)
        right.rowconfigure(2, weight=1)  # 让日志可纵向扩展

        #---------------------------------------------------------------------------------------------
        # row0
        #---------------------------------------------------------------------------------------------
        ops = tb.Frame(right)
        ops.grid(row=0, column=0, sticky=EW, pady=(0, 6))
        ops.columnconfigure((0, 1, 2, 3), weight=1)
        self.btn_inst    = tb.Button(ops, text="① 指令"   , bootstyle=PRIMARY, command=self._on_inst)
        self.btn_prefill = tb.Button(ops, text="② Prefill", bootstyle=INFO   , command=self._on_prefill)
        self.btn_decode  = tb.Button(ops, text="③ Decode" , bootstyle=WARNING, command=self._on_decode)
        self.btn_sample  = tb.Button(ops, text="④ 采样"   , bootstyle=DANGER , command=self._on_sample)

        self.btn_inst.grid   (row=0, column=0, sticky=EW, padx=6, pady=6)
        self.btn_prefill.grid(row=0, column=1, sticky=EW, padx=6, pady=6)
        self.btn_decode.grid (row=0, column=2, sticky=EW, padx=6, pady=6)
        self.btn_sample.grid (row=0, column=3, sticky=EW, padx=6, pady=6)

        #---------------------------------------------------------------------------------------------
        # row1:一键流程按钮（跨列）
        #---------------------------------------------------------------------------------------------
        self.btn_pipeline = tb.Button(right, text="🔄自动:①指令→②Prefill→③采样→[④Decode→③采样]", 
        bootstyle=SUCCESS, command=self._on_pipeline)
        self.btn_pipeline.grid(row=1, column=0, sticky=EW, padx=6, pady=(0, 6))
        
        #---------------------------------------------------------------------------------------------
        # row2
        #---------------------------------------------------------------------------------------------
        self.log_text = ScrolledText(right, wrap="word", state="disabled")
        self.log_text.grid(row=2, column=0, sticky=NSEW, padx=0, pady=0)

        #---------------------------------------------------------------------------------------------
        # row3
        #---------------------------------------------------------------------------------------------
        self.progress = tb.Progressbar(right, mode="indeterminate", bootstyle=STRIPED)
        self.progress.grid(row=3, column=0, sticky=EW, padx=6, pady=(2, 6))

        #---------------------------------------------------------------------------------------------
        # row4
        #---------------------------------------------------------------------------------------------
        btns = tb.Frame(right)
        btns.grid(row=4, column=0, sticky=E)
        tb.Button(btns, text="清空日志", bootstyle=SECONDARY, command=self._clear_output).pack(side=RIGHT, padx=(6, 0))

    #=======================================================
    #创建底部状态栏
    #=======================================================
    def _build_statusbar(self):
        bar = tb.Frame(self.root, padding=(16, 6))
        bar.pack(fill=X)
        self.status = tk.StringVar(value="就绪")
        tb.Label(bar, textvariable=self.status, bootstyle=SECONDARY).pack(side=LEFT)

    #=======================================================
    # 弹出对话框，模型文件
    #=======================================================
    def _select_model(self):
        path = filedialog.askdirectory(title="选择模型目录")
        if path: self.model_var.set(path)

    #=======================================================
    # 弹出对话框，编译器生成的指令文件
    #======================================================
    def _select_bit(self):
        path = filedialog.askopenfilename(title="选择指令目录"),
        if path: self.bit_var.set(path)

    #=======================================================
    #把日志内容 s 写到右侧的日志窗口
    #=======================================================
    def _append_log(self, s: str):
        self.log_text.configure(state="normal")
        self.log_text.insert("end", s)
        self.log_text.see("end")
        self.log_text.configure(state="disabled")
    
    #=======================================================
    #定时从 queue.Queue（日志队列）里取消息，更新到日志框
    #=======================================================
    def _poll_log(self):
        try:
            while True:
                line = self.log_queue.get_nowait()
                self._append_log(line)
        except queue.Empty:
            pass
        self.root.after(10, self._poll_log)

    #=======================================================
    #切换界面到“忙碌”状态。
    #=======================================================
    def _set_busy(self, busy: bool, msg="处理中..."):
        for w in (self.btn_inst, self.btn_prefill, self.btn_decode, self.btn_sample, self.btn_pipeline):
            w.configure(state=DISABLED if busy else NORMAL)
        if busy:
            self.progress.start(10); self.status.set(msg)
        else:
            self.progress.stop(); self.status.set("就绪")

    #=======================================================
    #后台线程执行某个任务，避免卡死 GUI。
    #=======================================================
    def _run_thread(self, target, *args, busy_msg="运行中..."):
        def job():
            try: target(*args)
            except Exception as e: messagebox.showerror("错误", str(e))
            finally: self.root.after(0, lambda: self._set_busy(False))
        self._set_busy(True, busy_msg)
        threading.Thread(target=job, daemon=True).start()

    #====================================================================
    #用户按钮1，指令
    #====================================================================
    def _on_inst(self):
        bit_path = (self.bit_var.get() or "").strip()

        #if not bit:
        #    messagebox.showwarning("提示", "请选择指令文件"); return
        #if not os.path.exists(bit):
        #    messagebox.showerror("错误", "路径不存在"); return

        self._run_thread(run_inst, 
                        bit_path, 
                        busy_msg="写入中...")
    #====================================================================
    #用户按钮2，预填充
    #====================================================================
    def _on_prefill(self):
        p_len = int(self.prefill_len.get())
        prompt = self.prompt_box.get("1.0", "end").strip()
        self._run_thread(run_prefill, 
                        prompt, 
                        p_len, 
                        busy_msg="Prefill...")

    #====================================================================
    #用户按钮3，解码
    #====================================================================
    def _on_decode(self):
        max_new_tokens = int(self.decode_max.get())
        self._run_thread(run_decode, 
                        max_new_tokens, 
                        busy_msg="Decode...")
    
    #====================================================================
    #用户按钮4，采样
    #====================================================================
    def _on_sample(self):
        pram_temp=float(self.temperature.get())
        pram_topk=int(self.topk.get())
        pram_topp=int(self.topp.get())
        pram_num =int(self.sample_count.get())
        pram_model = (self.model_var.get() or "").strip()
        self._run_thread(run_sampling,
                        pram_temp,
                        pram_topk,
                        pram_topp,
                        pram_num,
                        pram_model,
                        busy_msg="Sampling...")
    
    #====================================================================
    #用户按钮5，自动化
    #====================================================================
    def _on_pipeline(self):
        # 串行执行：烧写 -> Prefill -> Decode -> 采样
        bit = (self.bit_var.get() or "").strip()
        
        #if not bit or not os.path.exists(bit):
        #    messagebox.showwarning("提示", "请先选择有效的比特流文件"); return

        pl = int(self.prefill_len.get())
        model = (self.model_var.get() or "").strip()
        prompt = self.prompt_box.get("1.0", "end").strip()
        mx = int(self.decode_max.get())
        tp = float(self.temperature.get())
        cnt = int(self.sample_count.get())

        def pipeline():
            try:
                print("=== 🚦 一键流程开始 ===")
                run_inst(bit)
                run_prefill( prompt, pl)
                run_decode(mx)
                run_sampling(cnt)
                print("=== ✅ 一键流程完成 ===")
            except Exception as e:
                messagebox.showerror("错误", str(e))
            finally:
                self.root.after(0, lambda: self._set_busy(False))

        self._set_busy(True, "一键流程执行中...")
        threading.Thread(target=pipeline, daemon=True).start()


    #====================================================================
    #清理内容
    #====================================================================
    def _clear_output(self):
        self.log_text.configure(state="normal")
        self.log_text.delete("1.0", "end")
        self.log_text.configure(state="disabled")

    #====================================================================
    #关于
    #====================================================================
    def _about(self):
        messagebox.showinfo("关于", "ChatOPU 控制界面\n"
                                   "• ① 烧写 FPGA\n"
                                   "• ② Prefill\n"
                                   "• ③ Decode\n"
                                   "• ④ 采样\n\n"
                                   "支持一键流程（烧写→Prefill→Decode→采样）\n"
                                   "2025.9.18")
    #====================================================================
    #夯筑
    #====================================================================
    def _help(self):
        msg = (
            "【使用指南】\n"
            "1. 左侧设置：\n"
            "   • 模型路径：选择你的模型目录\n"
            "   • FPGA比特流：选择 .bit/.bin/.xclbin 文件\n"
            "   • Prompt长度 / 最大生成长度 / 温度 / 采样次数：按需设置\n"
            "   • Prompt输入：在此粘贴或编写文本，点击“发送到 Prefill”可直接预处理\n"
            "\n"
            "2. 右侧操作按钮：\n"
            "   • ① 烧写：将比特流烧写到 FPGA\n"
            "   • ② Prefill：基于 Prompt 进行预计算（KV Cache 等）\n"
            "   • ③ Decode：按参数生成新 token\n"
            "   • ④ 采样：按指定次数做采样/多样性评估\n"
            "   • 🔄 一键流程：按顺序执行 ①→②→③→④\n"
            "\n"
            "3. 日志：\n"
            "   • 右侧大窗口实时显示 print() 输出\n"
            "   • 点击“清空输出”可清屏\n"
            "\n"
            "4. 快捷键：\n"
            "   • F1 打开本帮助\n"
            "\n"
            "5. 提示：\n"
            "   • 任务执行期间按钮会禁用，进度条滚动\n"
            "   • 如需“停止/取消”，需要你的底层函数支持中断标志（可后续加入）\n"
        )
        messagebox.showinfo("帮助", msg)


#====================================================================
#主函数
#====================================================================
def main():
    root = tb.Window(themename="cosmo")
    app = App(root)
    root.protocol("WM_DELETE_WINDOW", lambda: (app.logger.restore(), root.destroy()))
    root.mainloop()

#====================================================================
#运行主函数
#====================================================================
if __name__ == "__main__":
    main()
