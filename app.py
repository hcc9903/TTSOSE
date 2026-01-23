import streamlit as st
import pandas as pd
import pdfplumber
import os
import re
from datetime import datetime

# --- 配置与视觉风格 (复古未来极简主义) ---
st.set_page_config(page_title="DEBIT_SYNC // 对账工具", layout="wide")

st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&family=Inter:wght@300;400;700&display=swap');
    
    .stApp {
        background-color: #050505;
        color: #d1d1d1;
        font-family: 'Inter', sans-serif;
    }
    
    /* 标题与文字样式 */
    h1, h2, h3 {
        color: #ffaa00 !important;
        font-family: 'JetBrains Mono', monospace;
        text-transform: uppercase;
        letter-spacing: 2px;
    }
    
    /* 复古卡片 */
    .card {
        background: #0a0a0a;
        padding: 24px;
        border-radius: 4px;
        border: 1px solid #222;
        margin-bottom: 24px;
        transition: border 0.3s ease;
    }
    .card:hover {
        border-color: #444;
    }
    
    /* 按钮：复古显示器质感 */
    div.stButton > button {
        background: transparent;
        color: #ffaa00;
        border: 1px solid #ffaa00;
        border-radius: 2px;
        font-family: 'JetBrains Mono', monospace;
        font-weight: bold;
        padding: 0.5rem 2rem;
        transition: all 0.2s ease;
    }
    div.stButton > button:hover {
        background: #ffaa00;
        color: #000;
        box-shadow: 0 0 15px rgba(255, 170, 0, 0.4);
    }
    
    /* 表格与数据展示 */
    .stDataFrame, .stTable {
        font-family: 'JetBrains Mono', monospace;
        font-size: 0.85rem;
    }
    
    /* 侧边栏与小组件 */
    [data-testid="stSidebar"] {
        background-color: #080808;
        border-right: 1px solid #222;
    }
    
    /* 成功/错误状态：复古信号色 */
    .stAlert {
        border-radius: 2px;
        background-color: #0a0a0a !important;
        border: 1px solid #333 !important;
    }
    </style>
    """, unsafe_allow_html=True)

# --- 核心逻辑函数 ---

# 初始化 Session State
if 'audited_dates' not in st.session_state:
    st.session_state['audited_dates'] = []
if 'last_reconcile_results' not in st.session_state:
    st.session_state['last_reconcile_results'] = None

SUSPICIOUS_KEYWORDS = ["游戏", "内购", "充值", "捐赠", "爱心", "打赏", "直播", "App Store"]

def parse_excel_universal(uploaded_file, type_tag="ICBC"):
    """
    通用 Excel 账单解析逻辑
    """
    try:
        raw_data = pd.read_excel(uploaded_file, header=None).head(40)
        start_row = 0
        for i, row in raw_data.iterrows():
            row_str = " ".join([str(x) for x in row.values if pd.notna(x)])
            if ("时间" in row_str or "日期" in row_str) and ("金额" in row_str or "支出" in row_str):
                start_row = i
                break
        
        df = pd.read_excel(uploaded_file, skiprows=start_row)
        df.columns = [str(c).strip() for c in df.columns]

        # 优先级排序的映射规则
        mapping_rules = [
            ("时间", ["交易时间", "日期", "时间"]),
            ("金额", ["金额", "支出金额", "收入/支出", "交易金额"]),
            ("方向", ["收/支", "方向"]),
            ("摘要", ["摘要", "交易详情"]),
            ("商品", ["商品", "商品名称"]),
            ("商户", ["商户", "商户名称"]),
            ("交易对方", ["交易对方", "交易对象"]),
            ("对方户名", ["对方户名", "对方名称"])
        ]
        
        found_map = {}
        used_cols = set()
        
        for std, targets in mapping_rules:
            for c in df.columns:
                if c in used_cols: continue
                if any(t in c for t in targets):
                    found_map[c] = std
                    used_cols.add(c)
                    break # 该标准列已找到
        
        if "时间" not in found_map.values() or "金额" not in found_map.values():
            st.error(f"{type_tag} 账单识别失败：找不到关键的时间或金额列")
            return None

        # 预先处理好描述（在 rename 之前，使用原始列名防止索引混淆）
        desc_orig_cols = [c for c, std in found_map.items() if std in ["摘要", "商户", "商品"]]
        if desc_orig_cols:
            df["_total_desc"] = df[desc_orig_cols].fillna("").astype(str).agg(" | ".join, axis=1)
        else:
            df["_total_desc"] = "无详细描述"

        # 执行重命名
        df = df.rename(columns=found_map)
        
        def clean_amt(val):
            s = str(val).replace("¥", "").replace(",", "").strip()
            if s.startswith('+'): return float(s[1:])
            if s.startswith('-'): return -float(s[1:])
            try: return float(s)
            except: return 0.0

        if "方向" in df.columns:
            df["金额"] = df.apply(lambda r: clean_amt(r["金额"]) * (-1 if "支" in str(r["方向"]) else 1), axis=1)
        else:
            df["金额"] = df["金额"].apply(clean_amt)
            
        df["日期"] = pd.to_datetime(df["时间"], errors='coerce').dt.date
        df = df.dropna(subset=["日期", "金额"])
        
        # 封装结果列
        res_cols = {
            "日期": df["日期"],
            "描述": df["_total_desc"],
            "金额": df["金额"]
        }
        for col in ["对方户名", "交易对方", "商品"]:
            if col in df.columns:
                res_cols[col] = df[col].astype(str).fillna("-")
            else:
                res_cols[col] = "-"
                
        return pd.DataFrame(res_cols).copy()
    except Exception as e:
        st.error(f"{type_tag} 解析失败: {e}")
        return None

def reconcile_daily(bank_df, wechat_df):
    """
    按日对账算法
    """
    all_dates = sorted(list(set(bank_df["日期"]) | set(wechat_df["日期"])))
    results = []
    
    for d in all_dates:
        # 对比当日全量交易金额 (含正数收入和负数支出)
        b_amounts = sorted([float(x) for x in bank_df[bank_df["日期"] == d]["金额"]])
        w_amounts = sorted([float(x) for x in wechat_df[wechat_df["日期"] == d]["金额"]])
        
        matched = []
        unmatched_bank = []
        unmatched_wechat = list(w_amounts)
        
        for amt in b_amounts:
            if amt in unmatched_wechat:
                unmatched_wechat.remove(amt)
                matched.append(amt)
            else:
                unmatched_bank.append(amt)
                
        status = "✅ 完全匹配" if not unmatched_bank and not unmatched_wechat else "⚠️ 存在差异"
        
        results.append({
            "日期": d,
            "状态": status,
            "银行支笔数": len(b_amounts),
            "微信支笔数": len(w_amounts),
            "匹配总额": sum(matched),
            "银行漏项": unmatched_bank,
            "微信漏项": unmatched_wechat
        })
    
    return pd.DataFrame(results)

# --- UI 界面渲染 ---

st.title("⚖️ 智能 Excel 双账单对账工具 (含审核)")
st.markdown("---")

col1, col2 = st.columns(2)

with col1:
    st.markdown('<div class="card">', unsafe_allow_html=True)
    st.subheader("💳 工行账单 (XLSX)")
    icbc_file = st.file_uploader("上传工行 Excel 账单", type=["xlsx"])
    st.markdown('</div>', unsafe_allow_html=True)

with col2:
    st.markdown('<div class="card">', unsafe_allow_html=True)
    st.subheader("🐧 微信账单 (XLSX)")
    wechat_file = st.file_uploader("上传微信 Excel 账单", type=["xlsx"])
    st.markdown('</div>', unsafe_allow_html=True)

# 核心分析逻辑
if st.button("🔍 开始当日流水比对"):
    if not icbc_file or not wechat_file:
        st.warning("⚠️ 请同时上传工行和微信的 Excel 账单文件。")
    else:
        with st.spinner("正在进行逐日对账..."):
            i_df = parse_excel_universal(icbc_file, "工行")
            w_df = parse_excel_universal(wechat_file, "微信")
            if i_df is not None and w_df is not None:
                report = reconcile_daily(i_df, w_df)
                # 存入缓存
                st.session_state['last_reconcile_results'] = {
                    'report': report,
                    'i_df': i_df,
                    'w_df': w_df
                }

# 渲染对账结果（如果存在）
if st.session_state['last_reconcile_results']:
    results = st.session_state['last_reconcile_results']
    report = results['report'].copy()
    
    # 根据审核状态更新 Report 状态说明
    def update_report_status(row):
        if row['日期'] in st.session_state['audited_dates']:
            return "✅ 审核通过 (人工核实)"
        return row['状态']
    
    report['显示状态'] = report.apply(update_report_status, axis=1)

    # 指标面板
    m1, m2, m3 = st.columns(3)
    m1.metric("对账天数", len(report))
    m2.metric("异常天数", len(report[report['状态'].str.contains("差异") & ~report['日期'].isin(st.session_state['audited_dates'])]))
    m3.metric("匹配支出总额", f"¥{report['匹配总额'].sum():,.2f}")
    
    # 展示报告
    st.markdown("### 🗓️ 每日对账详细报告")
    
    def highlight_status(val):
        if '差异' in str(val): color = '#ff4b4b' 
        else: color = '#10b981'
        return f'color: {color}; font-weight: bold'

    # 使用专门的显示列
    display_df = report[['日期', '显示状态', '银行支笔数', '微信支笔数', '匹配总额']]
    st.dataframe(display_df.style.map(highlight_status, subset=['显示状态']), width="stretch")
    
    # 异常项汇总分析
    st.markdown("### 🚨 异常明细追踪")
    anomalies = report[report["状态"].str.contains("差异")]
    
    if not anomalies.empty:
        for idx, row in anomalies.iterrows():
            d = row['日期']
            is_audited = d in st.session_state['audited_dates']
            
            exp_label = f"日期: {d} 的差异详情 " + ("(✅ 已审核)" if is_audited else "(🔴 待核实)")
            with st.expander(exp_label, expanded=not is_audited):
                # 提示漏掉的金额
                c1, c2 = st.columns(2)
                with c1:
                    if row["银行漏项"]:
                        st.error(f"⚠️ 银行多出支出: {row['银行漏项']}")
                with c2:
                    if row["微信漏项"]:
                        st.warning(f"⚠️ 微信多出支出: {row['微信漏项']}")

                # 展示当日详细对比表
                st.markdown("---")
                col_bank, col_wechat = st.columns(2)
                
                with col_bank:
                    st.write(f"🏦 当日银行流水 ({row['日期']})")
                    day_bank = results['i_df'][results['i_df']['日期'] == d]
                    # 组合展示需要的列
                    st.dataframe(day_bank[['描述', '对方户名', '金额']], height=200, width="stretch")
                
                with col_wechat:
                    st.write(f"🐧 当日微信流水 ({row['日期']})")
                    day_wechat = results['w_df'][results['w_df']['日期'] == d]
                    # 组合展示需要的列
                    st.dataframe(day_wechat[['描述', '交易对方', '商品', '金额']], height=200, width="stretch")
                
                # 审核按钮
                st.markdown("---")
                if not is_audited:
                    if st.button(f"确认当日情况无误，审核通过", key=f"audit_{d}"):
                        st.session_state['audited_dates'].append(d)
                        st.rerun()
                else:
                    st.success("✅ 该日期已通过审核")
    else:
        st.success("所有日期支出完全匹配！")
    
    with st.expander("📝 原始数据预览"):
        t_a, t_b = st.tabs(["工行原始", "微信原始"])
        with t_a: st.dataframe(results['i_df'], width="stretch")
        with t_b: st.dataframe(results['w_df'], width="stretch")

else:
    st.info("👋 欢迎！上传 Excel 账单后点击下方按钮开始按日对位分析。")
    st.markdown("""
    **功能说明：**
    - **当日对齐**：系统自动对比每天的每一笔金额。
    - **异常审核**：对不上的账目可在此手动“审核通过”，通过后在主表中会标记为绿色。
    """)
    
    with st.expander("💡 它是如何工作的？"):
        st.write("""
        1. **隐私安全**：所有文件解析均在本地或内存中完成，数据不会上传到任何其他服务器。
        2. **算法匹配**：我们通过排序后的金额序列进行“Multiset 对比”，精准匹配当日每一笔流水。
        3. **异常预警**：自动列出无法配对的差额，方便您快速补交或核对账目。
        """)
