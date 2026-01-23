import pandas as pd
import pdfplumber
import re
from datetime import datetime, timedelta
import os

# --- 配置区域 ---
# 建议将账单文件命名为以下名称并放在脚本同级目录，或修改下方路径
ICBC_PDF_PATH = "icbc.pdf"
WECHAT_EXCEL_PATH = "wechat.xlsx"

# 可疑关键字列表
SUSPICIOUS_KEYWORDS = ["游戏", "捐赠", "爱心", "内购", "充值", "娱乐", "直播", "打赏", "代充"]

def parse_icbc_pdf(pdf_path):
    """
    解析工商银行 PDF 账单
    """
    print(f"正在读取工行 PDF: {pdf_path}...")
    data = []
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                table = page.extract_table()
                if table:
                    # 过滤掉表头或空行（工行 PDF 通常第一行是标题）
                    for row in table:
                        if row[0] and "日期" not in row[0]:
                            data.append(row)
        
        # 假设工行表格列顺序：日期, 摘要, 支出, 收入, 余额...
        # 注意：不同版本的工行 PDF 格式可能略有不同
        df = pd.DataFrame(data)
        # 根据实际观察调整列索引，这里做一个通用的推断逻辑
        # 我们寻找包含金额的列
        df.columns = [f"col_{i}" for i in range(len(df.columns))]
        
        # 简单清洗逻辑（需要根据真实文件调整）
        # 转换日期和金额
        return df
    except Exception as e:
        print(f"解析工行 PDF 失败: {e}")
        return None

def parse_wechat_excel(excel_path):
    """
    解析微信支付 Excel 账单
    """
    print(f"正在读取微信 Excel: {excel_path}...")
    try:
        # 微信导出的 Excel 通常前面有几行说明文字，需要跳过
        df = pd.read_excel(excel_path, skiprows=16) # 微信通常 17 行开始是数据
        
        # 统一列名（去除空格等）
        df.columns = [c.strip() for c in df.columns]
        
        # 选出必要的列
        required_cols = ["交易时间", "交易类型", "商户", "商品", "金额(元)", "收/支", "支付方式"]
        df = df[required_cols]
        
        # 过滤出支出且通过工商银行支付的记录
        df = df[df["收/支"] == "支出"]
        df = df[df["支付方式"].str.contains("工商银行", na=False)]
        
        # 处理金额和时间
        df["金额(元)"] = df["金额(元)"].str.replace("¥", "").astype(float)
        df["交易时间"] = pd.to_datetime(df["交易时间"])
        
        return df
    except Exception as e:
        print(f"解析微信 Excel 失败: {e}")
        return None

def identify_risks(wechat_df):
    """
    识别可疑交易
    """
    risks = []
    for _, row in wechat_df.iterrows():
        # 1. 关键字匹配
        content = f"{row['商户']} {row['商品']}"
        matched_keywords = [k for k in SUSPICIOUS_KEYWORDS if k in content]
        
        # 2. 异常时间匹配 (比如凌晨 1点到 5点)
        is_night = 1 <= row["交易时间"].hour <= 5
        
        if matched_keywords or is_night:
            reason = []
            if matched_keywords: reason.append(f"包含敏感词: {', '.join(matched_keywords)}")
            if is_night: reason.append("非正常消费时间(凌晨)")
            
            risks.append({
                "时间": row["交易时间"],
                "商户/商品": content,
                "金额": row["金额(元)"],
                "风险原因": " | ".join(reason)
            })
    
    return pd.DataFrame(risks)

def main():
    if not os.path.exists(ICBC_PDF_PATH) or not os.path.exists(WECHAT_EXCEL_PATH):
        print("错误：未找到账单文件！")
        print(f"请确保以下文件存在：\n1. {os.path.abspath(ICBC_PDF_PATH)}\n2. {os.path.abspath(WECHAT_EXCEL_PATH)}")
        print("\n正在生成演示用的模拟数据并进行逻辑演示...")
        run_demo()
        return

    icbc_df = parse_icbc_pdf(ICBC_PDF_PATH)
    wechat_df = parse_wechat_excel(WECHAT_EXCEL_PATH)
    
    if icbc_df is not None and wechat_df is not None:
        print("\n--- 风险识别报告 ---")
        risks = identify_risks(wechat_df)
        if not risks.empty:
            print(risks.to_string(index=False))
        else:
            print("未发现明显的风险账单。")
        
        # 这里还可以继续实现 icbc_df 和 wechat_df 的金额对账逻辑...
    else:
        print("由于数据解析问题，无法完成对账。")

def run_demo():
    """
    如果没有真实文件，运行一段模拟演示代码
    """
    print("\n[演示模式] 模拟微信账单数据:")
    demo_data = {
        "交易时间": ["2026-01-20 10:30:00", "2026-01-21 02:15:00", "2026-01-22 14:00:00", "2026-01-22 14:05:00"],
        "商户": ["王小二餐馆", "XX游戏公司", "某慈善基金会", "App Store-内购"],
        "商品": ["午餐", "游戏充值", "爱心捐助", "软件订阅"],
        "金额(元)": [25.0, 648.0, 10.0, 128.0],
        "收/支": ["支出"] * 4
    }
    df = pd.DataFrame(demo_data)
    df["交易时间"] = pd.to_datetime(df["交易时间"])
    
    print(df)
    
    print("\n[分析中...] 正在识别可疑账单...")
    risks = identify_risks(df)
    
    if not risks.empty:
        print("\n！！！ 发现以下可疑项 ！！！")
        print(risks.to_string(index=False))
    
    print("\n[建议] 请手动检查上述账单是否为您本人操作。")

if __name__ == "__main__":
    main()
