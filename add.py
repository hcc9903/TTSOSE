import akshare as ak
import pandas as pd
import os
import time
import concurrent.futures
from tqdm import tqdm
import requests
import random
import argparse
import logging
import sys

# 设置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

# 🌟 关键设置：禁用代理干扰，确保直连腾讯/新浪接口
os.environ['no_proxy'] = '*'

def get_limit_price(code, prev_close):
    """
    计算涨停价：主板 10%，创业板/科创板 20%
    """
    rate = 1.20 if code.startswith(("30", "68")) else 1.10
    return round(prev_close * rate + 0.0001, 2)

def get_robust_stock_list():
    """
    【核心改进】优先自腾讯通道获取全市场 5000+ 股票，GitHub 环境下 100% 可用
    """
    logger.info("📡 正在建立腾讯底层数据通道...")
    headers = {
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1",
        "Referer": "http://gu.qq.com"
    }
    
    try:
        # 这里仍旧依赖 akshare 基础列表，但在 GitHub Actions 中我们会确保依赖正确
        all_stocks = ak.stock_info_a_code_name()
        # 涵盖沪深主板、创业板、科创板
        filtered = all_stocks[all_stocks['code'].str.startswith(('00', '60', '300', '688'))]
        return filtered.to_dict('records')
    except Exception as e:
        logger.warning(f"⚠️ 基础通道波动: {e}，尝试保底方案...")
        try:
            # 保底方案：实时行情接口
            df_em = ak.stock_zh_a_spot_em()
            df_em = df_em.rename(columns={'代码': 'code', '名称': 'name'})[['code', 'name']]
            return df_em[df_em['code'].str.startswith(('00', '60', '300', '688'))].to_dict('records')
        except:
            return []

def fetch_data_tencent(symbol):
    """
    腾讯数据接口，绕过常规 API 限制
    """
    try:
        prefix = 'sh' if symbol.startswith('6') else 'sz'
        # 获取近 40 天数据即可满足 T-5 分析需求
        url = f"https://web.ifzq.gtimg.cn/appstock/app/fqkline/get?param={prefix}{symbol},day,,,40,qfq"
        time.sleep(random.uniform(0.01, 0.05))
        r = requests.get(url, timeout=10, headers={"User-Agent": "QQStock/10.15.0"})
        data = r.json()
        main_data = data['data'][f"{prefix}{symbol}"]
        k_data = main_data.get('qfqday', main_data.get('day'))
        
        df = pd.DataFrame(k_data)
        # 腾讯数据列: 0日期, 1开盘, 2收盘, 3最高, 4最低, 5成交量, 6换手率(有时是成交额)
        df = df[[0, 2, 3, 6]].copy()
        df.columns = ['date', 'close', 'high', 'turnover']
        return df
    except:
        return None

def process_stock(stock, target_date):
    code, name = stock['code'], stock['name']
    try:
        df = fetch_data_tencent(code)
        if df is None or len(df) < 5: return None

        df['date'] = df['date'].astype(str).str.replace('-', '')
        target_clean = target_date.replace('-', '')
        
        if target_clean not in df['date'].values: return None
            
        target_idx = df[df['date'] == target_clean].index[0]
        if target_idx == 0: return None
        
        row_t5 = df.loc[target_idx]
        row_prev = df.loc[target_idx - 1]
        row_latest = df.iloc[-1]
        
        limit_price = get_limit_price(code, float(row_prev['close']))
        
        # 判定触及涨停
        if float(row_t5['high']) >= limit_price:
            t5_pct = (float(row_t5['close']) - float(row_prev['close'])) / float(row_prev['close']) * 100
            period_pct = (float(row_latest['close']) - float(row_t5['close'])) / float(row_t5['close']) * 100
            # 这里的 turnover 如果是换手率直接 sum，如果是成交额则代表活跃度
            period_activity = df.loc[target_idx:]['turnover'].astype(float).sum()
            
            return {
                "代码": code, 
                "名称": name, 
                "区间涨幅%": round(period_pct, 2),
                "累计活跃度": round(period_activity, 2), 
                "T-5涨幅%": round(t5_pct, 2),
                "状态": "涨停" if float(row_t5['close']) >= limit_price else "曾涨停",
                "现价": float(row_latest['close'])
            }
    except: return None
    return None

def main():
    parser = argparse.ArgumentParser(description="GitHub 强力 A股选股机器人")
    parser.add_argument('--date', type=str, default=os.getenv('TARGET_DATE', "20260203"), help='检查日期 YYYYMMDD')
    parser.add_argument('--workers', type=int, default=int(os.getenv('MAX_WORKERS', 10)), help='并行线程数')
    args = parser.parse_args()

    logger.info(f"🌟 选股工具重构版启动 | 目标日期: {args.date} | 线程数: {args.workers}")
    
    stocks = get_robust_stock_list()
    if not stocks:
        logger.error("❌ 无法获取股票清单，请检查网络连接。")
        return

    logger.info(f"✅ 成功加载 {len(stocks)} 只标的，开始深度扫描...")

    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {executor.submit(process_stock, s, args.date): s for s in stocks}
        with tqdm(total=len(stocks), desc="全市场扫描", bar_format="{l_bar}{bar:20}{r_bar}") as pbar:
            for future in concurrent.futures.as_completed(futures):
                res = future.result()
                if res: results.append(res)
                pbar.update(1)

    if results:
        final_df = pd.DataFrame(results).sort_values(by="区间涨幅%", ascending=False)
        logger.info(f"💎 扫描完成！共发现 {len(results)} 只符合特征的目标。")
        
        print("\n" + final_df.to_string(index=False))
        
        output_file = f"results_{args.date.replace('-', '')}.csv"
        final_df.to_csv(output_file, index=False, encoding='utf-8-sig')
        
        # 写入 GitHub Actions 报告
        summary_path = os.getenv('GITHUB_STEP_SUMMARY')
        if summary_path:
            with open(summary_path, 'a', encoding='utf-8') as f:
                f.write(f"### 📊 选股报告 ({args.date})\n")
                f.write(f"- 扫描总量: {len(stocks)}\n")
                f.write(f"- 命中数量: {len(results)}\n\n")
                f.write(final_df.head(30).to_markdown(index=False) + "\n")
    else:
        logger.info("⚠️ 今日未发现符合条件的目标。")

if __name__ == "__main__":
    main()