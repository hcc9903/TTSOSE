// ========================================
// 全局变量
// ========================================

let tasks = {};
let updateInterval = null;

// ========================================
// 工具函数
// ========================================

/**
 * 显示Toast通知
 */
function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;

    container.appendChild(toast);

    setTimeout(() => {
        toast.style.animation = 'toastIn 0.3s ease reverse';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

/**
 * 检测视频平台
 */
function detectPlatform(url) {
    const platforms = {
        'youtube': { domains: ['youtube.com', 'youtu.be'], icon: '📺' },
        'bilibili': { domains: ['bilibili.com', 'b23.tv'], icon: '🎬' },
        'douyin': { domains: ['douyin.com'], icon: '🎵' },
        'kuaishou': { domains: ['kuaishou.com'], icon: '🎪' },
        'tiktok': { domains: ['tiktok.com'], icon: '🌍' }
    };

    for (const [platform, config] of Object.entries(platforms)) {
        for (const domain of config.domains) {
            if (url.toLowerCase().includes(domain)) {
                return { platform, icon: config.icon };
            }
        }
    }

    return { platform: 'unknown', icon: '🎥' };
}

/**
 * 格式化文件大小
 */
function formatFileSize(bytes) {
    if (!bytes || bytes === 0) return '未知';
    const units = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return `${(bytes / Math.pow(1024, i)).toFixed(2)} ${units[i]}`;
}

/**
 * 格式化时间
 */
function formatTime(seconds) {
    if (!seconds || seconds === 0) return '未知';
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = Math.floor(seconds % 60);

    if (h > 0) return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    return `${m}:${s.toString().padStart(2, '0')}`;
}

/**
 * 获取状态文本
 */
function getStatusText(status) {
    const statusMap = {
        'pending': '等待中',
        'downloading': '下载中',
        'paused': '已暂停',
        'completed': '已完成',
        'failed': '失败'
    };
    return statusMap[status] || status;
}

/**
 * 获取状态图标
 */
function getStatusIcon(status) {
    const iconMap = {
        'pending': '⏳',
        'downloading': '⬇️',
        'paused': '⏸️',
        'completed': '✅',
        'failed': '❌'
    };
    return iconMap[status] || '❓';
}

// ========================================
// API 调用
// ========================================

/**
 * 开始下载
 */
async function startDownload(url, options) {
    try {
        const response = await fetch('/api/download', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ url, options })
        });

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || '下载失败');
        }

        const data = await response.json();
        return data;
    } catch (error) {
        throw error;
    }
}

/**
 * 获取所有任务
 */
async function fetchTasks() {
    try {
        const response = await fetch('/api/tasks');
        const data = await response.json();
        return data.tasks || [];
    } catch (error) {
        console.error('获取任务失败:', error);
        return [];
    }
}

/**
 * 暂停任务
 */
async function pauseTask(taskId) {
    try {
        const response = await fetch(`/api/task/${taskId}/pause`, {
            method: 'POST'
        });
        return await response.json();
    } catch (error) {
        console.error('暂停任务失败:', error);
    }
}

/**
 * 继续任务
 */
async function resumeTask(taskId) {
    try {
        const response = await fetch(`/api/task/${taskId}/resume`, {
            method: 'POST'
        });
        return await response.json();
    } catch (error) {
        console.error('继续任务失败:', error);
    }
}

/**
 * 取消任务
 */
async function cancelTask(taskId) {
    try {
        const response = await fetch(`/api/task/${taskId}/cancel`, {
            method: 'POST'
        });
        return await response.json();
    } catch (error) {
        console.error('取消任务失败:', error);
    }
}

// ========================================
// UI 更新
// ========================================

/**
 * 创建任务卡片
 */
function createTaskCard(task) {
    const card = document.createElement('div');
    card.className = 'task-card';
    card.id = `task-${task.task_id}`;

    const thumbnail = task.thumbnail || 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="120" height="68" viewBox="0 0 120 68"%3E%3Crect fill="%23334155" width="120" height="68"/%3E%3Ctext x="50%25" y="50%25" dominant-baseline="middle" text-anchor="middle" fill="%2364748b" font-size="24"%3E🎬%3C/text%3E%3C/svg%3E';

    card.innerHTML = `
        <div class="task-header">
            <img src="${thumbnail}" alt="缩略图" class="task-thumbnail" onerror="this.src='data:image/svg+xml,%3Csvg xmlns=\\'http://www.w3.org/2000/svg\\' width=\\'120\\' height=\\'68\\' viewBox=\\'0 0 120 68\\'%3E%3Crect fill=\\'%23334155\\' width=\\'120\\' height=\\'68\\'/%3E%3Ctext x=\\'50%25\\' y=\\'50%25\\' dominant-baseline=\\'middle\\' text-anchor=\\'middle\\' fill=\\'%2364748b\\' font-size=\\'24\\'%3E🎬%3C/text%3E%3C/svg%3E'">
            <div class="task-info">
                <div class="task-title" title="${task.title}">${task.title}</div>
                <div class="task-meta">
                    <span class="task-status ${task.status}">
                        ${getStatusIcon(task.status)} ${getStatusText(task.status)}
                    </span>
                    <span>${task.file_size}</span>
                </div>
            </div>
        </div>
        
        <div class="task-progress">
            <div class="progress-bar-container">
                <div class="progress-bar" style="width: ${task.progress}%"></div>
            </div>
            <div class="progress-info">
                <span class="progress-percent">${task.progress.toFixed(1)}%</span>
                <div class="progress-details">
                    <span>速度: ${task.speed}</span>
                    <span>剩余: ${task.eta}</span>
                </div>
            </div>
        </div>
        
        <div class="task-actions" data-status="${task.status}">
            ${task.status === 'downloading' ? `
                <button class="action-btn" onclick="handlePause('${task.task_id}')">⏸️ 暂停</button>
            ` : ''}
            ${task.status === 'paused' ? `
                <button class="action-btn" onclick="handleResume('${task.task_id}')">▶️ 继续</button>
            ` : ''}
            ${task.status !== 'completed' && task.status !== 'failed' ? `
                <button class="action-btn danger" onclick="handleCancel('${task.task_id}')">❌ 取消</button>
            ` : ''}
            ${task.status === 'completed' ? `
                <button class="action-btn" onclick="openFolder('${task.output_file}')">📁 打开文件夹</button>
            ` : ''}
        </div>
        
        ${task.error_message ? `
            <div style="margin-top: 12px; padding: 12px; background: rgba(239, 68, 68, 0.1); border-radius: 8px; color: #ef4444; font-size: 0.85rem;">
                ⚠️ ${task.error_message}
            </div>
        ` : ''}
    `;

    return card;
}

/**
 * 更新任务列表
 */
function updateTaskList(taskList) {
    const container = document.getElementById('taskList');
    const emptyState = document.getElementById('emptyState');
    const taskCount = document.getElementById('taskCount');

    if (taskList.length === 0) {
        emptyState.style.display = 'block';
        taskCount.textContent = '0 个任务';
        const cards = container.querySelectorAll('.task-card');
        cards.forEach(card => card.remove());
        return;
    }

    emptyState.style.display = 'none';
    taskCount.textContent = `${taskList.length} 个任务`;

    // 追踪当前处理中的 ID，用于后续清理
    const currentTaskIds = new Set(taskList.map(t => t.task_id));

    taskList.forEach(task => {
        let card = document.getElementById(`task-${task.task_id}`);

        if (!card) {
            // 如果卡片不存在，则创建新卡片
            card = createTaskCard(task);
            container.appendChild(card);
        } else {
            // 如果卡片已存在，仅更新变动的部分，防止“跳动”

            // 1. 更新状态文字和颜色类
            const statusEl = card.querySelector('.task-status');
            if (statusEl) {
                statusEl.className = `task-status ${task.status}`;
                statusEl.innerHTML = `${getStatusIcon(task.status)} ${getStatusText(task.status)}`;
            }

            // 2. 更新进度条
            const progressBar = card.querySelector('.progress-bar');
            if (progressBar) {
                progressBar.style.width = `${task.progress}%`;
            }

            // 3. 更新进度百分比
            const progressPercent = card.querySelector('.progress-percent');
            if (progressPercent) {
                progressPercent.textContent = `${task.progress.toFixed(1)}%`;
            }

            // 4. 更新详细信息 (速度、剩余时间)
            const detailsSpan = card.querySelector('.progress-details');
            if (detailsSpan) {
                detailsSpan.innerHTML = `<span>速度: ${task.speed}</span><span>剩余: ${task.eta}</span>`;
            }

            // 5. 更新操作按钮区域 (如果状态变了)
            const actionsDiv = card.querySelector('.task-actions');
            if (actionsDiv) {
                const oldStatus = actionsDiv.getAttribute('data-status');
                if (oldStatus !== task.status) {
                    actionsDiv.setAttribute('data-status', task.status);
                    actionsDiv.innerHTML = `
                        ${task.status === 'downloading' ? `<button class="action-btn" onclick="handlePause('${task.task_id}')">⏸️ 暂停</button>` : ''}
                        ${task.status === 'paused' ? `<button class="action-btn" onclick="handleResume('${task.task_id}')">▶️ 继续</button>` : ''}
                        ${task.status !== 'completed' && task.status !== 'failed' ? `<button class="action-btn danger" onclick="handleCancel('${task.task_id}')">❌ 取消</button>` : ''}
                        ${task.status === 'completed' ? `<button class="action-btn" onclick="openFolder('${task.output_file}')">📁 打开文件夹</button>` : ''}
                    `;
                }
            }
        }
    });

    // 删除已经不存在的任务
    const allCards = container.querySelectorAll('.task-card');
    allCards.forEach(card => {
        const taskId = card.id.replace('task-', '');
        if (!currentTaskIds.has(taskId)) {
            card.remove();
        }
    });
}

/**
 * 定期更新任务状态
 */
async function updateTasks() {
    const taskList = await fetchTasks();
    updateTaskList(taskList);
}

// ========================================
// 事件处理
// ========================================

/**
 * 处理下载按钮点击
 */
async function handleDownload() {
    const urlInput = document.getElementById('videoUrl');
    const qualitySelect = document.getElementById('qualitySelect');
    const outputDir = document.getElementById('outputDir');
    const proxyToggle = document.getElementById('proxyToggle');
    const downloadBtn = document.getElementById('downloadBtn');

    const url = urlInput.value.trim();

    if (!url) {
        showToast('请输入视频链接', 'error');
        return;
    }

    // 验证URL
    try {
        new URL(url);
    } catch {
        showToast('请输入有效的URL', 'error');
        return;
    }

    // 显示加载状态
    downloadBtn.classList.add('loading');
    downloadBtn.disabled = true;

    try {
        const options = {
            quality: qualitySelect.value,
            output_dir: outputDir.value || './downloads',
            use_proxy: proxyToggle.checked
        };

        const result = await startDownload(url, options);

        showToast('下载任务已创建', 'success');
        urlInput.value = '';

        // 立即更新任务列表
        setTimeout(updateTasks, 500);

    } catch (error) {
        showToast(error.message || '下载失败', 'error');
    } finally {
        downloadBtn.classList.remove('loading');
        downloadBtn.disabled = false;
    }
}

/**
 * 处理暂停
 */
async function handlePause(taskId) {
    await pauseTask(taskId);
    showToast('任务已暂停', 'info');
    updateTasks();
}

/**
 * 处理继续
 */
async function handleResume(taskId) {
    await resumeTask(taskId);
    showToast('任务已继续', 'info');
    updateTasks();
}

/**
 * 处理取消
 */
async function handleCancel(taskId) {
    if (confirm('确定要取消这个下载任务吗?')) {
        await cancelTask(taskId);
        showToast('任务已取消', 'info');
        updateTasks();
    }
}

/**
 * 打开文件夹
 */
async function openFolder(folderPath) {
    try {
        const response = await fetch('/api/open-folder', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ path: folderPath })
        });

        if (response.ok) {
            showToast('文件夹已打开', 'success');
        } else {
            const error = await response.json();
            showToast(error.error || '打开文件夹失败', 'error');
        }
    } catch (error) {
        console.error('打开文件夹失败:', error);
        showToast('打开文件夹失败', 'error');
    }
}

/**
 * 处理URL输入变化
 */
function handleUrlChange() {
    const urlInput = document.getElementById('videoUrl');
    const platformIndicator = document.getElementById('platformIndicator');
    const url = urlInput.value.trim();

    if (url) {
        const { icon } = detectPlatform(url);
        platformIndicator.textContent = icon;
        platformIndicator.classList.add('show');
    } else {
        platformIndicator.classList.remove('show');
    }
}

// ========================================
// 初始化
// ========================================

document.addEventListener('DOMContentLoaded', () => {
    // 绑定事件
    const downloadBtn = document.getElementById('downloadBtn');
    const urlInput = document.getElementById('videoUrl');

    downloadBtn.addEventListener('click', handleDownload);

    urlInput.addEventListener('input', handleUrlChange);
    urlInput.addEventListener('paste', () => {
        setTimeout(handleUrlChange, 100);
    });

    // 回车键下载
    urlInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            handleDownload();
        }
    });

    // 设置默认值
    const proxyToggle = document.getElementById('proxyToggle');
    const outputDir = document.getElementById('outputDir');

    // 代理默认开启
    proxyToggle.checked = true;

    // 默认下载路径
    outputDir.value = 'D:\\yt-dlp';

    // 初始加载任务
    updateTasks();

    // 定期更新任务状态 (每2秒)
    updateInterval = setInterval(updateTasks, 2000);

    console.log('全网视频下载工具已就绪 ✨');
});

// 页面卸载时清理
window.addEventListener('beforeunload', () => {
    if (updateInterval) {
        clearInterval(updateInterval);
    }
});
