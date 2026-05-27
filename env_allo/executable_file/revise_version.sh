#!/bin/bash
#======================================================
# run for deploy ubuntu24 perceptional environment
# specific module such as ROS2 yolo Nav2
# editor by unkaku
# ues method
# chmod +x setup_env.sh
# ./setup_env.sh
#======================================================

set -e  # 任何命令出错立即停止

# ----------自定义变量----------
CUDA_VERSION="12.8"
CONDA_ENV_NAME="yolo_learn"
ROS_DISTRO="jazzy"
VENV_PATH="$HOME/ros_yolo_venv"
WORKSPACE_DIR="$HOME/yolo_ws"
# ---------------------------------------------

echo "========================================="
echo "  开始配置 ROS2 + YOLO 感知环境"
echo "  当前系统：$(lsb_release -ds)"
echo "========================================="
echo ""

# -------- 辅助函数 --------
check_cmd() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}
step() {
    echo -e "\n>>> 步骤：$1"
}
# -------------------------

# =============================================
# 0. 系统基础更新
# =============================================
step "0.系统更新与基础工具"
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git vim build-essential gedit

# =============================================
# 1. 显卡驱动检查与安装
# =============================================
step "1.install显卡驱动"
if ! check_cmd nvidia-smi; then
    echo "nvidia-smi不可用,尝试安装推荐驱动..."
    sudo ubuntu-drivers autoinstall
    echo "驱动安装完成,请重启系统后再次运行本脚本"
    echo "运行命令: sudo reboot"
    exit 0
else
    echo "显卡驱动已安装："
    nvidia-smi | head -5
    echo "continue next steps..."
fi

# =============================================
# 2. 检查 ROS2 Jazzy 环境
# =============================================
step "2.加载 ROS2 ${ROS_DISTRO} 环境"
# 确保ROS2环境变量在脚本内生效
if [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
    source /opt/ros/${ROS_DISTRO}/setup.bash
    echo "ROS2环境已加载: $(ros2 --version)"
else
    echo "警告: 找不到 ROS2 setup.bash, 请确认是否已手动安装 ROS2 Jazzy"
fi

# =============================================
# 3. 安装 vscode（可选）
# =============================================
step "3.安装 VS Code"
if check_cmd code; then
    echo "VS Code 已安装,跳过。"
else
    echo "通过 Snap 安装 VS Code ..."
    sudo snap install --classic code
fi

# =============================================
# 4. Python 虚拟环境 （使用 venv + system-site-packages）
# =============================================
step "4.create Python yolo 虚拟环境"
if [ ! -d "$VENV_PATH" ]; then
    echo "创建 Python 虚拟环境 (带系统包) ..."
    sudo apt install -y python3-venv python3-pip
    python3 -m venv "$VENV_PATH" --system-site-packages
    echo "虚拟环境创建于：$VENV_PATH"
else
    echo "虚拟环境已存在，跳过。"
fi

# 激活虚拟环境
source "$VENV_PATH/bin/activate"
pip install --upgrade pip

# =============================================
# 5. 深度学习包安装（GPU版）
# =============================================
step "5. 深度学习依赖"
echo "安装 PyTorch (CUDA 12.4 源, 兼容 CUDA 12.8)..."
if python -c "import torch; print(torch.__version__)" 2>/dev/null; then
    echo "PyTorch 已安装，跳过"
else
    # 修正为 cu124 避免 404 报错
    pip install torch torchvision --index-url https://download.pytorch.org/whl/cu124
fi

echo "安装 ultralytics, opencv, labelme 等 ..."
# 将 labelimg 替换为兼容 Python 3.12 的 labelme
pip install ultralytics opencv-python labelme face_recognition

# 退出虚拟环境
deactivate

# =============================================
# 6. YOLO ROS 包（可选克隆）
# =============================================
step "6. 克隆 yolo_ros"
if [ -d "$HOME/yolo_ros" ]; then
    echo "yolo_ros 仓库已存在,跳过"
else
    cd ~
    git clone GitHub - mgonzs13/yolo_ros: Ultralytics YOLOv8, YOLOv9, YOLOv10, YOLOv11, YOLOv12 for ROS 2
    echo "已克隆 yolo_ros,后续可放入 ROS 工作空间编译"
fi

# =============================================
# 7. 环境别名（方便激活）
# =============================================
step "7.配置快捷命令激活ROS+YOLO环境"
if ! grep -q 'alias yolo=' ~/.bashrc; then
    echo "添加yolo别名到 ~/.bashrc ..."
    echo 'alias yolo="source /opt/ros/jazzy/setup.bash && source ~/ros_yolo_venv/bin/activate"' >> ~/.bashrc
    echo "以后在终端输入yolo即可同时加载ROS2和YOLO虚拟环境"
fi

# =============================================
# 8. 环境验证脚本生成
# =============================================
step "8.验证yolo环境配置"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_SCRIPT="$SCRIPT_DIR/test_env.py"

if [ ! -f "$TEST_SCRIPT" ]; then
    echo "警告：找不到 $TEST_SCRIPT, 请确保它与 setup.sh 在同一目录下。"
    echo "跳过环境验证"
else
    source /opt/ros/${ROS_DISTRO}/setup.bash
    source "$VENV_PATH/bin/activate"
    echo "正在运行 $TEST_SCRIPT ..."
    python "$TEST_SCRIPT"
    deactivate
    echo "验证完成。"
fi

# =============================================
# 9. 安装其余感知部开发工具与 Gazebo/Nav2
# =============================================
step "9.安装 rqt, rviz2, Gazebo 与 Nav2"
sudo apt update

# 增加 || true 防止未查找到时触发 set -e 导致脚本中断
apt list --installed | grep -e "rviz2" -e "rqt" || true

echo "配置完整rqt功能..."
sudo apt install -y ros-${ROS_DISTRO}-rqt-tf-tree
sudo apt install -y ros-${ROS_DISTRO}-rqt ros-${ROS_DISTRO}-rqt-common-plugins
rm -rf ~/.config/ros.org/rqt_gui.ini
sudo apt install -y ros-${ROS_DISTRO}-rqt-*

echo "安装gazebo与nav2..."
sudo apt install -y ros-${ROS_DISTRO}-ros-gz ros-${ROS_DISTRO}-ros-gz-sim ros-${ROS_DISTRO}-ros-gz-bridge
sudo apt install -y ros-${ROS_DISTRO}-navigation2 ros-${ROS_DISTRO}-nav2-bringup

if ! grep -q "source /opt/ros/${ROS_DISTRO}/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc
fi

# =============================================
# 10. 完成提示
# =============================================
echo ""
echo "========================================="
echo "  环境配置基本完成！请执行以下操作："
echo "  1. 运行: source ~/.bashrc (或重启终端)"
echo "  2. 输入 gz sim 验证gazebo安装"
echo "========================================="