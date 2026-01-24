"""
全网视频下载工具 - 主程序
支持平台: YouTube, B站, 抖音, 快手, TikTok等
"""

import os
import sys
import json
import subprocess
import threading
import time
import re
from pathlib import Path
from flask import Flask, render_template, request, jsonify, send_from_directory
from flask_cors import CORS
import uuid

app = Flask(__name__)
CORS(app)

# 工具路径配置
ARIA2C_PATH = r"C:\Program Files\aria2\aria2c.exe"
YT_DLP_PATH = r"D:\yt-dlp\yt-dlp.exe"
FFMPEG_PATH = r"D:\yt-dlp\ffmpeg.exe"
COOKIES_PATH = r"D:\yt-dlp\cookies.txt"

# 代理配置文件路径
PROXY_CONFIG = os.path.join(os.path.dirname(__file__), "proxy.txt")

# 下载任务存储
download_tasks = {}

class DownloadTask:
    """下载任务类"""
    def __init__(self, task_id, url, options):
        self.task_id = task_id
        self.url = url
        self.options = options
        self.status = "pending"  # pending, downloading, paused, completed, failed
        self.progress = 0
        self.speed = "0 KB/s"
        self.eta = "计算中..."
        self.title = "获取中..."
        self.thumbnail = ""
        self.file_size = "未知"
        self.downloaded_size = "0 MB"
        self.error_message = ""
        self.process = None
        self.output_file = ""
        
    def to_dict(self):
        """转换为字典"""
        return {
            "task_id": self.task_id,
            "url": self.url,
            "status": self.status,
            "progress": self.progress,
            "speed": self.speed,
            "eta": self.eta,
            "title": self.title,
            "thumbnail": self.thumbnail,
            "file_size": self.file_size,
            "downloaded_size": self.downloaded_size,
            "error_message": self.error_message,
            "output_file": self.output_file
        }

def get_proxy_config():
    """读取代理配置"""
    if os.path.exists(PROXY_CONFIG):
        try:
            with open(PROXY_CONFIG, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    # 跳过空行和注释
                    if line and not line.startswith('#'):
                        print(f"[代理配置] 使用代理: {line}")
                        return line
        except Exception as e:
            print(f"[代理配置] 读取失败: {e}")
    return None

def preprocess_url(url):
    """预处理链接，修复特殊的平台链接格式"""
    # 针对抖音搜索弹窗链接进行修复
    if 'douyin.com' in url and 'modal_id=' in url:
        match = re.search(r'modal_id=(\d+)', url)
        if match:
            video_id = match.group(1)
            new_url = f"https://www.douyin.com/video/{video_id}"
            print(f"[链接预处理] 检测到抖音搜索链接，已转换为标准视频链接: {new_url}")
            return new_url
    return url

def detect_platform(url):
    """检测视频平台"""
    # 先进行链接预处理
    processed_url = preprocess_url(url)
    
    platforms = {
        'youtube': ['youtube.com', 'youtu.be'],
        'bilibili': ['bilibili.com', 'b23.tv'],
        'douyin': ['douyin.com'],
        'kuaishou': ['kuaishou.com'],
        'tiktok': ['tiktok.com']
    }
    
    for platform, domains in platforms.items():
        for domain in domains:
            if domain in processed_url.lower():
                return platform
    return 'unknown'

def resolve_js_runtime():
    """检测可用的 JS 运行时，用于增强 yt-dlp 的提取能力"""
    # 按照优先级尝试：deno -> node -> qjs
    runtimes = ['deno', 'node', 'qjs']
    for rt in runtimes:
        try:
            # 在 Windows 上使用 where 命令
            cmd = ['where', rt] if os.name == 'nt' else ['which', rt]
            res = subprocess.run(cmd, capture_output=True, text=True)
            if res.returncode == 0:
                rt_path = res.stdout.splitlines()[0].strip()
                if os.path.exists(rt_path):
                    return rt, rt_path
        except:
            continue
    return None, None

def get_video_info(url):
    """获取视频信息 - 引入 VidBee 风格的内核参数"""
    url = preprocess_url(url)
    platform = detect_platform(url)
    is_china_platform = platform in ['douyin', 'bilibili', 'kuaishou']
    
    # 环境设置：修复 Windows 编码问题
    env = os.environ.copy()
    if os.name == 'nt':
        env['PYTHONIOENCODING'] = 'utf-8'
        env['LC_ALL'] = 'C.UTF-8'

    try:
        cmd = [
            YT_DLP_PATH, 
            '--dump-json', 
            '--no-playlist', 
            '--restrict-filenames',
            '--encoding', 'utf-8',  # 强制编码
            '--no-warnings'
        ]
        
        # 加载 JS 运行时 (内核优化)
        rt_name, rt_path = resolve_js_runtime()
        if rt_name:
            cmd.extend(['--js-runtime', f"{rt_name}:{rt_path}"])
            print(f"[内核] 已启用 JS 运行时: {rt_name}")
        
        # 仅非国内平台加载Cookie
        if os.path.exists(COOKIES_PATH) and not is_china_platform:
            cmd.extend(['--cookies', COOKIES_PATH])
        elif not is_china_platform:
            # 内核技能：如果找不到 cookies.txt，尝试从浏览器自动提取 (兼容 Chrome/Edge)
            cmd.extend(['--cookies-from-browser', 'chrome+edge'])
            print(f"[内核] 已开启浏览器 Cookie 自动同步 (Chrome/Edge)")
        
        # 添加代理
        proxy = get_proxy_config()
        if proxy and not is_china_platform:
            cmd.extend(['--proxy', proxy])
        
        # 伪装 UA
        cmd.extend(['--user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'])

        result = subprocess.run(cmd, capture_output=True, text=True, errors='replace', env=env)
        if result.returncode == 0:
            info = json.loads(result.stdout)
            return {
                'title': info.get('title', '未知标题'),
                'thumbnail': info.get('thumbnail', ''),
                'duration': info.get('duration', 0),
                'filesize': info.get('filesize', 0) or info.get('filesize_approx', 0)
            }
        else:
            print(f"[视频信息] 错误码: {result.returncode}")
            if result.stderr:
                print(f"[视频信息] 详请: {result.stderr[:200]}")
    except Exception as e:
        print(f"[视频信息] 获取失败: {e}")
    
    return {
        'title': '未知标题',
        'thumbnail': '',
        'duration': 0,
        'filesize': 0
    }
def parse_progress(line, task):
    """解析下载进度，支持 yt-dlp 原生格式和 aria2c 格式"""
    try:
        # 1. yt-dlp 原生进度格式: [download]  45.2% of 123.45MiB at 1.23MiB/s ETA 00:30
        if '[download]' in line:
            # 提取百分比
            percent_match = re.search(r'(\d+\.?\d*)%', line)
            if percent_match:
                task.progress = float(percent_match.group(1))
            
            # 提取速度
            speed_match = re.search(r'at\s+([\d.]+\s*[KMG]i?B/s)', line)
            if speed_match:
                task.speed = speed_match.group(1)
            elif 'Unknown speed' in line or 'N/A' in line:
                task.speed = "计算中..."
            
            # 提取ETA
            eta_match = re.search(r'ETA\s+([\d:]+|Unknown)', line)
            if eta_match:
                eta_val = eta_match.group(1)
                task.eta = eta_val if eta_val != 'Unknown' else "计算中..."
            
            # 提取文件大小
            size_match = re.search(r'of\s+([~]?[\d.]+\s*[KMG]i?B)', line)
            if size_match:
                task.file_size = size_match.group(1)

        # 2. aria2c 进度格式: [#cbc7a8 50MiB/59MiB(83%) CN:15 DL:2.1MiB ETA:4s]
        elif '[' in line and 'MiB' in line and '(' in line and ')' in line:
            # 提取百分比 (括号内的数字)
            percent_match = re.search(r'\((\d+)%\)', line)
            if percent_match:
                task.progress = float(percent_match.group(1))
            
            # 提取速度 (DL: 后面)
            speed_match = re.search(r'DL:([\d.]+[KMG]?i?B)', line)
            if speed_match:
                task.speed = speed_match.group(1) + "/s"
            
            # 提取ETA (ETA: 后面)
            eta_match = re.search(r'ETA:([\w\d:]+)', line)
            if eta_match:
                task.eta = eta_match.group(1)
                
            # 提取大小 (例如 50MiB/59MiB)
            size_match = re.search(r'/([\d.]+[KMG]i?B)', line)
            if size_match:
                task.file_size = size_match.group(1)
                
    except Exception as e:
        print(f"[进度解析] 失败: {e}, 行内容: {line}")

def download_video_thread(task):
    """下载视频线程 - 注入 VidBee 全速下载技能"""
    try:
        # 环境设置：确保下载过程不乱码
        env = os.environ.copy()
        if os.name == 'nt':
            env['PYTHONIOENCODING'] = 'utf-8'
            env['LC_ALL'] = 'C.UTF-8'

        task.url = preprocess_url(task.url)
        print(f"\n[任务启动] ID: {task.task_id}")
        task.status = "downloading"
        
        info = get_video_info(task.url)
        task.title = info['title']
        task.thumbnail = info['thumbnail']
        if info['filesize'] > 0:
            task.file_size = f"{info['filesize'] / 1024 / 1024:.2f} MB"
        
        output_dir = task.options.get('output_dir', r'D:\yt-dlp')
        os.makedirs(output_dir, exist_ok=True)
        
        output_template = os.path.join(output_dir, '%(title)s.%(ext)s')
        task.output_file = output_dir
        
        # 基础命令 (引入 VidBee 强化参数)
        cmd = [
            YT_DLP_PATH,
            '--newline',
            '--progress',
            '--continue',        # 支持续传
            '--no-mtime',       # 不保留原始修改时间，方便排序
            '--encoding', 'utf-8',
            '-o', output_template,
            '--ffmpeg-location', FFMPEG_PATH,
            '--no-playlist',
            '--restrict-filenames',
            '--windows-filenames'
        ]
        
        # 格式选择逻辑优化
        quality = task.options.get('quality', 'best')
        if quality == 'best':
            cmd.extend(['-f', 'bestvideo+bestaudio/best'])
        else:
            cmd.extend(['-f', f'bestvideo[height<={quality}]+bestaudio/best[height<={quality}]'])
        
        # JS 运行时注入
        rt_name, rt_path = resolve_js_runtime()
        if rt_name:
            cmd.extend(['--js-runtime', f"{rt_name}:{rt_path}"])

        # 平台与 Cookies 策略
        platform = detect_platform(task.url)
        is_china_platform = platform in ['douyin', 'bilibili', 'kuaishou']
        
        if os.path.exists(COOKIES_PATH) and not is_china_platform:
            cmd.extend(['--cookies', COOKIES_PATH])
        elif not is_china_platform:
            # 强化内核：自动从浏览器同步登录状态
            cmd.extend(['--cookies-from-browser', 'chrome+edge'])
            print(f"[内核] 已开启浏览器 Cookie 自动同步 (Chrome/Edge)")
        
        # 代理策略
        proxy = get_proxy_config()
        if proxy and not is_china_platform and task.options.get('use_proxy', False):
            cmd.extend(['--proxy', proxy])

        # 伪装头 (抖音/B站优化)
        if platform == 'douyin':
            cmd.extend(['--add-header', 'Referer:https://www.douyin.com/'])
        elif platform == 'bilibili':
            cmd.extend(['--add-header', 'Referer:https://www.bilibili.com/'])
            
        cmd.extend(['--user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'])
        
        # 全速下载技能：aria2c 深度集成
        if os.path.exists(ARIA2C_PATH):
            cmd.extend(['--external-downloader', ARIA2C_PATH])
            # 引入更激进的多线程和重试逻辑
            cmd.extend(['--external-downloader-args', '-x 16 -s 16 -k 1M --retry-wait=5 --connect-timeout=30'])
            print(f"[内核] 已开启 aria2c 全速加速 (16线程)")
        
        cmd.append(task.url)
        
        task.process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            errors='replace',
            env=env
        )
        
        # 读取输出
        for line in task.process.stdout:
            if task.status == "paused":
                print(f"[任务] 用户暂停")
                task.process.kill()
                break
            
            line_stripped = line.strip()
            if line_stripped:
                print(line_stripped)
            parse_progress(line, task)
            
            # 检测错误
            if 'ERROR' in line or 'error' in line:
                task.error_message = line_stripped
            
            # 检测下载完成
            if '[download] 100%' in line or 'has already been downloaded' in line:
                task.progress = 100
                task.status = "completed"
                task.eta = "完成"
                print(f"[任务] 下载完成!")
        
        # 等待进程结束
        task.process.wait()
        
        if task.status == "downloading":
            if task.process.returncode == 0:
                task.status = "completed"
                task.progress = 100
                task.eta = "完成"
                print(f"[任务] 成功完成")
            else:
                task.status = "failed"
                if not task.error_message:
                    task.error_message = f"下载失败 (退出码: {task.process.returncode})"
                print(f"[任务] 失败: {task.error_message}")
                
    except Exception as e:
        task.status = "failed"
        task.error_message = str(e)
        print(f"下载失败: {e}")

@app.route('/')
def index():
    """主页"""
    return render_template('index.html')

@app.route('/api/download', methods=['POST'])
def start_download():
    """开始下载"""
    data = request.json
    url = data.get('url')
    
    if not url:
        return jsonify({'error': '请提供视频链接'}), 400
    
    # 创建任务
    task_id = str(uuid.uuid4())
    task = DownloadTask(task_id, url, data.get('options', {}))
    download_tasks[task_id] = task
    
    # 启动下载线程
    thread = threading.Thread(target=download_video_thread, args=(task,))
    thread.daemon = True
    thread.start()
    
    return jsonify({'task_id': task_id, 'status': 'started'})

@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    """获取所有任务"""
    tasks = [task.to_dict() for task in download_tasks.values()]
    return jsonify({'tasks': tasks})

@app.route('/api/task/<task_id>', methods=['GET'])
def get_task(task_id):
    """获取单个任务"""
    task = download_tasks.get(task_id)
    if not task:
        return jsonify({'error': '任务不存在'}), 404
    return jsonify(task.to_dict())

@app.route('/api/task/<task_id>/pause', methods=['POST'])
def pause_task(task_id):
    """暂停任务"""
    task = download_tasks.get(task_id)
    if not task:
        return jsonify({'error': '任务不存在'}), 404
    
    if task.status == "downloading":
        task.status = "paused"
        if task.process:
            try:
                task.process.kill()
                print(f"[暂停任务] {task_id}")
            except Exception as e:
                print(f"[暂停失败] {e}")
    
    return jsonify({'status': 'paused'})

@app.route('/api/task/<task_id>/resume', methods=['POST'])
def resume_task(task_id):
    """继续任务"""
    task = download_tasks.get(task_id)
    if not task:
        return jsonify({'error': '任务不存在'}), 404
    
    if task.status == "paused":
        # 重新启动下载
        thread = threading.Thread(target=download_video_thread, args=(task,))
        thread.daemon = True
        thread.start()
    
    return jsonify({'status': 'resumed'})

@app.route('/api/task/<task_id>/cancel', methods=['POST'])
def cancel_task(task_id):
    """取消任务"""
    task = download_tasks.get(task_id)
    if not task:
        return jsonify({'error': '任务不存在'}), 404
    
    print(f"[取消任务] {task_id}, 当前状态: {task.status}")
    
    if task.process:
        try:
            task.process.kill()
            print(f"[取消任务] 进程已终止")
        except Exception as e:
            print(f"[取消失败] {e}")
    
    task.status = "failed"
    task.error_message = "用户取消"
    
    return jsonify({'status': 'cancelled'})

@app.route('/api/detect', methods=['POST'])
def detect_video():
    """检测视频信息"""
    data = request.json
    url = data.get('url')
    
    if not url:
        return jsonify({'error': '请提供视频链接'}), 400
    
    platform = detect_platform(url)
    info = get_video_info(url)
    
    return jsonify({
        'platform': platform,
        'info': info
    })

@app.route('/api/open-folder', methods=['POST'])
def open_folder():
    """打开文件夹"""
    data = request.json
    folder_path = data.get('path', r'D:\yt-dlp')
    
    try:
        # 确保路径存在
        if os.path.exists(folder_path):
            # 在Windows上打开文件夹
            os.startfile(folder_path)
            print(f"[打开文件夹] {folder_path}")
            return jsonify({'status': 'success', 'path': folder_path})
        else:
            return jsonify({'error': '文件夹不存在', 'path': folder_path}), 404
    except Exception as e:
        print(f"[打开文件夹] 失败: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("=" * 60)
    print("全网视频下载工具启动中...")
    print("=" * 60)
    print(f"访问地址: http://localhost:5000")
    print("=" * 60)
    
    # 检查工具是否存在
    tools = {
        'aria2c': ARIA2C_PATH,
        'yt-dlp': YT_DLP_PATH,
        'ffmpeg': FFMPEG_PATH
    }
    
    for name, path in tools.items():
        if os.path.exists(path):
            print(f"✓ {name}: {path}")
        else:
            print(f"✗ {name}: 未找到 ({path})")
    
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)
