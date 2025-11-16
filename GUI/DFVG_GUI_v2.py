import os, sys, time, threading, queue
import tkinter as tk
from tkinter import filedialog, messagebox
from tkinter.scrolledtext import ScrolledText
import ttkbootstrap as tb
from ttkbootstrap.constants import *
#
# 2025.9.18

#=====================================================
APP_TITLE = "DFVG Interactive GUI v1"

# ========= Placeholder functions (replace with real implementation) =========
def run_inst(
    bit_path: str
    ):
    print('-' * 60)
    print(f"📥 Write instruction to FPGA: {bit_path}")
    print('-' * 60)
    time.sleep(1)
    print("✅ Instruction write done")

def run_prefill(
    prompt_text: str,
    prompt_len: int
    ):
    print('-' * 60)
    print(f"📦 [Prefill] Model: {'(default)'} | Prompt Len = {prompt_len}")
    print('-' * 60)
    time.sleep(1)
    print("✅ Prefill done")

def run_decode(
    max_new_tokens: int
    ):
    print('-' * 60)
    print(f"🎲 [Decode] MaxNew = {max_new_tokens}")
    print('-' * 60)
    gen_token_num = 5
    for i in range(gen_token_num):
        time.sleep(0.2)
        print(f"✦ token_{i+1}")
    print("✅ Decode done")

def run_sampling(
    pram_temp=0,
    pram_topk=0,
    pram_topp=0,
    pram_num=0,
    pram_model=0,
    ):
    print('-' * 60)
    print(f"🎯 [Sampling] times = {pram_num}")
    print('-' * 60)
    for i in range(pram_num):
        time.sleep(0.15)
        print(f"🔎 sample_{i+1}")
    print("✅ Sampling done")

# ========= Redirect stdout to textbox =========
class TextboxLogger:
    def __init__(self,
                 widget: ScrolledText,
                 line_queue: queue.Queue
                 ):
        self.widget = widget
        self.queue = line_queue
        self._orig = sys.stdout
        sys.stdout = self

    def write(self, data):
        if data:
            self.queue.put(data)

    def flush(self):
        pass

    def restore(self):
        sys.stdout = self._orig

# ========= Main application =========
class App:
    def __init__(self, root: tb.Window):
        self.root = root
        self.root.title(APP_TITLE)
        # Larger default size for a more “filled” layout
        self.root.geometry("1240x720")
        self.root.minsize(960, 640)
        self._build_header()
        self._build_content()
        self._build_statusbar()
        # Logging redirection
        self.log_queue = queue.Queue()
        self.logger = TextboxLogger(self.log_text, self.log_queue)
        self._poll_log()

    #========================================================
    # Header
    #========================================================
    def _build_header(self):
        header = tb.Frame(self.root, padding=(16, 10))
        header.pack(fill=X)
        tb.Label(
            header,
            text="DFVG: Draft-on-FPGA and Verify-on-GPU ",
            font=("Microsoft YaHei", 15, "bold")
        ).pack(side=LEFT)

        tb.Button(
            header,
            text="About",
            bootstyle=SECONDARY,
            command=self._about,
            width=8
        ).pack(side=RIGHT)
        tb.Button(
            header,
            text="Help",
            bootstyle=SECONDARY,
            command=self._help,
            width=8
        ).pack(side=RIGHT, padx=(0, 8))

    #========================================================
    # Main content
    #========================================================
    def _build_content(self):
        # A horizontal paned window (left config / right logs)
        body = tb.Panedwindow(self.root, orient=HORIZONTAL)
        body.pack(fill=BOTH, expand=YES, padx=16, pady=(0, 12))

        #========================================================================
        # Left: Configuration
        #========================================================================
        left = tb.Labelframe(body, text="Configuration", padding=12, bootstyle=PRIMARY)
        # Let column 1 expand horizontally
        left.columnconfigure(1, weight=1)
        # Allow prompt and token areas to expand vertically
        left.rowconfigure(5, weight=1)
        left.rowconfigure(6, weight=1)
        body.add(left, weight=1)

        #-----------------------------------------------------------------------------------
        # row=0: Model tokenizer
        #-----------------------------------------------------------------------------------
        tb.Label(left, text="Model Tokenizer").grid(row=0, column=0, sticky=E, pady=6, padx=6)
        self.model_var = tk.StringVar(value="huggingface/Qwen3-8B/Tokenizer")
        tb.Entry(left, textvariable=self.model_var).grid(row=0, column=1, sticky=EW, pady=6)
        tb.Button(
            left,
            text="Browse",
            bootstyle=OUTLINE,
            command=self._select_model
        ).grid(row=0, column=2, padx=6, pady=6, sticky=E)

        #-----------------------------------------------------------------------------------
        # row=1: Compiler instruction file
        #-----------------------------------------------------------------------------------
        tb.Label(left, text="Compiler Instruction").grid(row=1, column=0, sticky=E, pady=6, padx=6)
        self.bit_var = tk.StringVar(value="compiler/inst/base/dram_merge_write1.bin")
        tb.Entry(left, textvariable=self.bit_var).grid(row=1, column=1, sticky=EW, pady=6)
        tb.Button(
            left,
            text="Browse",
            bootstyle=OUTLINE,
            command=self._select_bit
        ).grid(row=1, column=2, padx=6, pady=6, sticky=E)

        #-----------------------------------------------------------------------------------
        # row=2: Prefill parameters
        #-----------------------------------------------------------------------------------
        row2 = tb.Frame(left)
        row2.grid(row=2, column=0, columnspan=4, sticky=W, pady=6, padx=(21, 6))

        tb.Label(row2, text="    Prefill addr").pack(side=LEFT, padx=(0, 4))
        self.prefill_addr = tk.IntVar(value=129294176)
        tb.Entry(row2, textvariable=self.prefill_addr, width=10).pack(side=LEFT, padx=(0, 10))

        tb.Label(row2, text=" Input len").pack(side=LEFT, padx=(0, 4))
        self.prefill_len = tk.IntVar(value=64)
        tb.Spinbox(
            row2, from_=1, to=32768,
            textvariable=self.prefill_len, width=7
        ).pack(side=LEFT, padx=(0, 10))

        tb.Label(row2, text="ID rows").pack(side=LEFT, padx=(0, 4))
        self.prefill_id_row = tk.IntVar(value=4)
        tb.Spinbox(
            row2, from_=1, to=32768,
            textvariable=self.prefill_id_row, width=7
        ).pack(side=LEFT, padx=(0, 10))

        tb.Label(row2, text="logits addr").pack(side=LEFT, padx=(0, 4))
        self.prefill_lmhead = tk.IntVar(value=2374)
        tb.Entry(row2, textvariable=self.prefill_lmhead, width=8).pack(side=LEFT, padx=(0, 10))

        #-----------------------------------------------------------------------------------
        # row=3: Decode parameters
        #-----------------------------------------------------------------------------------
        row3 = tb.Frame(left)
        row3.grid(row=3, column=0, columnspan=4, sticky=W, pady=6, padx=(21, 6))

        tb.Label(row3, text="Decode addr").pack(side=LEFT, padx=(0, 4))
        self.decode_addr = tk.IntVar(value=129294176)
        tb.Entry(row3, textvariable=self.decode_addr, width=10).pack(side=LEFT, padx=(0, 10))

        tb.Label(row3, text=" Max new").pack(side=LEFT, padx=(0, 4))
        self.decode_max = tk.IntVar(value=128)
        tb.Spinbox(
            row3, from_=1, to=32768,
            textvariable=self.decode_max, width=7
        ).pack(side=LEFT, padx=(0, 10))

        tb.Label(row3, text=" Current pos").pack(side=LEFT, padx=(0, 4))
        self.decode_cur = tk.IntVar(value=1)
        tb.Spinbox(
            row3, from_=1, to=32768,
            textvariable=self.decode_cur, width=7
        ).pack(side=LEFT, padx=(0, 10))

        tb.Label(row3, text=" Count").pack(side=LEFT, padx=(0, 4))
        self.decode_cnt = tk.IntVar(value=128)
        tb.Spinbox(
            row3, from_=1, to=32768,
            textvariable=self.decode_cnt, width=7
        ).pack(side=LEFT, padx=(0, 10))

        #-----------------------------------------------------------------------------------
        # row=4: Sampling parameters
        #-----------------------------------------------------------------------------------
        row4 = tb.Frame(left)
        row4.grid(row=4, column=0, columnspan=4, sticky=W, pady=6, padx=(48, 6))

        # Temperature
        tb.Label(row4, text="Temperature").pack(side=LEFT, padx=(0, 4))
        self.temperature = tk.DoubleVar(value=0.6)
        tb.Spinbox(
            row4, from_=0.0, to=2.0, increment=0.1,
            textvariable=self.temperature, width=7
        ).pack(side=LEFT, padx=(0, 12))

        # Top-K
        tb.Label(row4, text="Top-K").pack(side=LEFT, padx=(0, 4))
        self.topk = tk.IntVar(value=20)
        tb.Spinbox(
            row4, from_=1, to=100,
            textvariable=self.topk, width=7
        ).pack(side=LEFT, padx=(0, 12))

        # Top-P
        tb.Label(row4, text="Top-P").pack(side=LEFT, padx=(0, 4))
        self.topp = tk.DoubleVar(value=0.95)
        tb.Spinbox(
            row4, from_=0.0, to=1.0, increment=0.05,
            textvariable=self.topp, width=7
        ).pack(side=LEFT, padx=(0, 12))

        # Sample count
        tb.Label(row4, text="Samples").pack(side=LEFT, padx=(0, 4))
        self.sample_count = tk.IntVar(value=1)
        tb.Spinbox(
            row4, from_=1, to=100,
            textvariable=self.sample_count, width=7
        ).pack(side=LEFT, padx=(0, 6))

        #-----------------------------------------------------------------------------------
        # Prompt input area
        #-----------------------------------------------------------------------------------
        tb.Label(left, text="Prompt Input").grid(row=5, column=0, sticky=NE, pady=(10, 0))
        self.prompt_box = ScrolledText(left, wrap="word")
        self.prompt_box.grid(row=5, column=1, columnspan=3, sticky=NSEW, pady=(6, 0))

        #-----------------------------------------------------------------------------------
        # Token output area
        #-----------------------------------------------------------------------------------
        tb.Label(left, text="Token Output").grid(row=6, column=0, sticky=NE, pady=(10, 0))
        self.token_box = ScrolledText(left, wrap="word")
        self.token_box.grid(row=6, column=1, columnspan=3, sticky=NSEW, pady=(6, 0))

        #-----------------------------------------------------------------------------------
        # Action buttons
        #-----------------------------------------------------------------------------------
        tb.Button(
            left,
            text="Send to Prefill",
            bootstyle=INFO,
            command=self._on_prefill
        ).grid(row=7, column=1, sticky=W, pady=8)

        tb.Button(
            left,
            text="Clear Prompt",
            bootstyle=SECONDARY,
            command=lambda: self.prompt_box.delete("1.0", "end")
        ).grid(row=7, column=2, pady=8, sticky=W, padx=(0, 6))

        tb.Button(
            left,
            text="Clear Tokens",
            bootstyle=SECONDARY,
            command=lambda: self.token_box.delete("1.0", "end")
        ).grid(row=7, column=3, pady=8, sticky=W)

        #========================================================================
        # Right: Operations & Logs
        #========================================================================
        right = tb.Labelframe(body, text="Operations & Logs", padding=12, bootstyle=INFO)
        body.add(right, weight=2)
        right.columnconfigure(0, weight=1)
        right.rowconfigure(2, weight=1)  # let log area expand vertically

        #---------------------------------------------------------------------------------------------
        # row0: op buttons
        #---------------------------------------------------------------------------------------------
        ops = tb.Frame(right)
        ops.grid(row=0, column=0, sticky=EW, pady=(0, 6))
        ops.columnconfigure((0, 1, 2, 3), weight=1)

        self.btn_inst = tb.Button(ops, text="① Instruction", bootstyle=PRIMARY, command=self._on_inst)
        self.btn_prefill = tb.Button(ops, text="② Prefill", bootstyle=INFO, command=self._on_prefill)
        self.btn_decode = tb.Button(ops, text="③ Decode", bootstyle=WARNING, command=self._on_decode)
        self.btn_sample = tb.Button(ops, text="④ Sampling", bootstyle=DANGER, command=self._on_sample)

        self.btn_inst.grid(row=0, column=0, sticky=EW, padx=6, pady=6)
        self.btn_prefill.grid(row=0, column=1, sticky=EW, padx=6, pady=6)
        self.btn_decode.grid(row=0, column=2, sticky=EW, padx=6, pady=6)
        self.btn_sample.grid(row=0, column=3, sticky=EW, padx=6, pady=6)

        #---------------------------------------------------------------------------------------------
        # row1: pipeline button
        #---------------------------------------------------------------------------------------------
        self.btn_pipeline = tb.Button(
            right,
            text="🔄 Auto: ①Inst → ②Prefill → ③Decode → ④Sampling",
            bootstyle=SUCCESS,
            command=self._on_pipeline
        )
        self.btn_pipeline.grid(row=1, column=0, sticky=EW, padx=6, pady=(0, 6))

        #---------------------------------------------------------------------------------------------
        # row2: log textbox
        #---------------------------------------------------------------------------------------------
        self.log_text = ScrolledText(right, wrap="word", state="disabled")
        self.log_text.grid(row=2, column=0, sticky=NSEW, padx=0, pady=0)

        #---------------------------------------------------------------------------------------------
        # row3: progress bar
        #---------------------------------------------------------------------------------------------
        self.progress = tb.Progressbar(right, mode="indeterminate", bootstyle=STRIPED)
        self.progress.grid(row=3, column=0, sticky=EW, padx=6, pady=(2, 6))

        #---------------------------------------------------------------------------------------------
        # row4: clear log button
        #---------------------------------------------------------------------------------------------
        btns = tb.Frame(right)
        btns.grid(row=4, column=0, sticky=E)
        tb.Button(
            btns,
            text="Clear Log",
            bootstyle=SECONDARY,
            command=self._clear_output
        ).pack(side=RIGHT, padx=(6, 0))

    #=======================================================
    # Bottom status bar
    #=======================================================
    def _build_statusbar(self):
        bar = tb.Frame(self.root, padding=(16, 6))
        bar.pack(fill=X)
        self.status = tk.StringVar(value="Ready")
        tb.Label(bar, textvariable=self.status, bootstyle=SECONDARY).pack(side=LEFT)

    #=======================================================
    # File dialog for model directory
    #=======================================================
    def _select_model(self):
        path = filedialog.askdirectory(title="Select model directory")
        if path:
            self.model_var.set(path)

    #=======================================================
    # File dialog for compiler instruction file
    #======================================================
    def _select_bit(self):
        path = filedialog.askopenfilename(title="Select instruction file")
        if path:
            self.bit_var.set(path)

    #=======================================================
    # Append log text to the right log window
    #=======================================================
    def _append_log(self, s: str):
        self.log_text.configure(state="normal")
        self.log_text.insert("end", s)
        self.log_text.see("end")
        self.log_text.configure(state="disabled")

    #=======================================================
    # Periodically poll queue for new log lines
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
    # Switch GUI to busy/idle status
    #=======================================================
    def _set_busy(self, busy: bool, msg="Processing..."):
        for w in (self.btn_inst, self.btn_prefill, self.btn_decode, self.btn_sample, self.btn_pipeline):
            w.configure(state=DISABLED if busy else NORMAL)
        if busy:
            self.progress.start(10)
            self.status.set(msg)
        else:
            self.progress.stop()
            self.status.set("Ready")

    #=======================================================
    # Run a function in background thread to avoid blocking GUI
    #=======================================================
    def _run_thread(self, target, *args, busy_msg="Running..."):
        def job():
            try:
                target(*args)
            except Exception as e:
                messagebox.showerror("Error", str(e))
            finally:
                self.root.after(0, lambda: self._set_busy(False))

        self._set_busy(True, busy_msg)
        threading.Thread(target=job, daemon=True).start()

    #====================================================================
    # Button 1: instruction
    #====================================================================
    def _on_inst(self):
        bit_path = (self.bit_var.get() or "").strip()

        # if not bit_path:
        #     messagebox.showwarning("Hint", "Please select an instruction file")
        #     return
        # if not os.path.exists(bit_path):
        #     messagebox.showerror("Error", "Path does not exist")
        #     return

        self._run_thread(
            run_inst,
            bit_path,
            busy_msg="Writing instruction..."
        )

    #====================================================================
    # Button 2: prefill
    #====================================================================
    def _on_prefill(self):
        p_len = int(self.prefill_len.get())
        prompt = self.prompt_box.get("1.0", "end").strip()
        self._run_thread(
            run_prefill,
            prompt,
            p_len,
            busy_msg="Prefill..."
        )

    #====================================================================
    # Button 3: decode
    #====================================================================
    def _on_decode(self):
        max_new_tokens = int(self.decode_max.get())
        self._run_thread(
            run_decode,
            max_new_tokens,
            busy_msg="Decode..."
        )

    #====================================================================
    # Button 4: sampling
    #====================================================================
    def _on_sample(self):
        pram_temp = float(self.temperature.get())
        pram_topk = int(self.topk.get())
        pram_topp = float(self.topp.get())
        pram_num = int(self.sample_count.get())
        pram_model = (self.model_var.get() or "").strip()

        self._run_thread(
            run_sampling,
            pram_temp,
            pram_topk,
            pram_topp,
            pram_num,
            pram_model,
            busy_msg="Sampling..."
        )

    #====================================================================
    # Button 5: auto pipeline
    #====================================================================
    def _on_pipeline(self):
        # Sequential: Instruction -> Prefill -> Decode -> Sampling
        bit = (self.bit_var.get() or "").strip()

        # if not bit or not os.path.exists(bit):
        #     messagebox.showwarning("Hint", "Please select a valid instruction file")
        #     return

        pl = int(self.prefill_len.get())
        model = (self.model_var.get() or "").strip()
        prompt = self.prompt_box.get("1.0", "end").strip()
        mx = int(self.decode_max.get())
        tp = float(self.temperature.get())
        cnt = int(self.sample_count.get())
        tk = int(self.topk.get())
        pp = float(self.topp.get())

        def pipeline():
            try:
                print("=== 🚦 Pipeline start ===")
                run_inst(bit)
                run_prefill(prompt, pl)
                run_decode(mx)
                run_sampling(tp, tk, pp, cnt, model)
                print("=== ✅ Pipeline finished ===")
            except Exception as e:
                messagebox.showerror("Error", str(e))
            finally:
                self.root.after(0, lambda: self._set_busy(False))

        self._set_busy(True, "Running pipeline...")
        threading.Thread(target=pipeline, daemon=True).start()

    #====================================================================
    # Clear log content
    #====================================================================
    def _clear_output(self):
        self.log_text.configure(state="normal")
        self.log_text.delete("1.0", "end")
        self.log_text.configure(state="disabled")

    #====================================================================
    # About dialog
    #====================================================================
    def _about(self):
        messagebox.showinfo(
            "About",
            "ChatOPU Control Panel\n"
            "• ① Flash FPGA\n"
            "• ② Prefill\n"
            "• ③ Decode\n"
            "• ④ Sampling\n\n"
            "Supports one-click pipeline "
            "(Instruction → Prefill → Decode → Sampling)\n"
            "2025.9.18"
        )

    #====================================================================
    # Help dialog
    #====================================================================
    def _help(self):
        msg = (
            "[Usage Guide]\n"
            "1. Left side settings:\n"
            "   • Model path: select your model directory\n"
            "   • FPGA instruction file: select .bit/.bin/.xclbin file\n"
            "   • Prompt length / max new tokens / temperature / sample count: configure as needed\n"
            "   • Prompt input: paste or type text here, click \"Send to Prefill\" to pre-process\n"
            "\n"
            "2. Right side operation buttons:\n"
            "   • ① Instruction: write instruction / bitstream to FPGA\n"
            "   • ② Prefill: pre-compute (e.g., KV cache) based on the prompt\n"
            "   • ③ Decode: generate new tokens according to parameters\n"
            "   • ④ Sampling: sample multiple times for diversity evaluation\n"
            "   • 🔄 Auto: run ① → ② → ③ → ④ in sequence\n"
            "\n"
            "3. Logs:\n"
            "   • The log window shows real-time print() output\n"
            "   • Click \"Clear Log\" to clear\n"
            "\n"
            "4. Shortcut:\n"
            "   • F1 to open this help (you can bind later if needed)\n"
            "\n"
            "5. Tips:\n"
            "   • During tasks, buttons are disabled and the progress bar is active\n"
            "   • To support cancel/abort, you can add an interrupt flag in your backend functions later\n"
        )
        messagebox.showinfo("Help", msg)


#====================================================================
# main()
#====================================================================
def main():
    root = tb.Window(themename="cosmo")
    app = App(root)
    root.protocol("WM_DELETE_WINDOW", lambda: (app.logger.restore(), root.destroy()))
    root.mainloop()

#====================================================================
# Entry
#====================================================================
if __name__ == "__main__":
    main()
