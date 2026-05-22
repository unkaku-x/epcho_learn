#!/bin/bash
#======================================================
#run for deploy ubuntu24 perceptional environment
#specific module such as ROS2 yolo Nav2
#editor by unkaku
#ues method
# chmod +x setup_env.sh
# ./setup_env.sh
#or
# sudo bash setup_env.sh (but not recommend)
#notice! some steps such as install. need input your key so keep look at bash
# ======================================================

set -e  # 任何命令出错立即停止

# ----------自定义变量----------
CUDA_VERSION="12.8"
CUDA_RUNFILE="cuda_12.8.0_570.86.10_linux.run"
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
    echo "运行命令:sudo reboot"
    exit 0
else
    echo "显卡驱动已安装："
    nvidia-smi | head -5
    echo "continue next steps..."
fi

# =============================================
# 2. CUDA Toolkit 12.8（runfile方式）
# =============================================
step "2.CUDA Toolkit ${CUDA_VERSION} install GPU's pytorch.This can skip"
# install GPU pytorch will automatically install CUDA Toolkit.This can skip
# if [ -d "/usr/local/cuda-${CUDA_VERSION}" ]; then
#     echo "CUDA ${CUDA_VERSION} 似乎已安装,跳过。"
# else
#     echo "下载并安装 CUDA ${CUDA_VERSION} ..."
#     if [ ! -f "$CUDA_RUNFILE" ]; then
#         wget "https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}.0/local_installers/${CUDA_RUNFILE}"
#     fi
#     chmod +x "$CUDA_RUNFILE"
#     sudo ./${CUDA_RUNFILE} --silent --toolkit --override
#     echo "CUDA ${CUDA_VERSION}安装完成"
# fi

# # 配置环境变量
# if ! grep -q "cuda-${CUDA_VERSION}" ~/.bashrc; then
#     echo "配置 CUDA 环境变量到 ~/.bashrc ..."
#     cat >> ~/.bashrc << EOF

# # CUDA ${CUDA_VERSION}
# export PATH=/usr/local/cuda-${CUDA_VERSION}/bin:\$PATH
# export LD_LIBRARY_PATH=/usr/local/cuda-${CUDA_VERSION}/lib64:\$LD_LIBRARY_PATH
# EOF
#     source ~/.bashrc
# fi

# =============================================
# 3. 安装 ROS2 Jazzy
# =============================================
step "3.install ROS2 ${ROS_DISTRO}"
step "因为小鱼安装为交互式脚本,在这个脚本里卡进程,所以推荐你先手动安装好ros2,这里暂时跳过了"
# if [ -d "/opt/ros/${ROS_DISTRO}" ]; then
#     echo "ROS2${ROS_DISTRO}已安装,跳过"
# else
#     echo "使用鱼香ROS一键安装 ROS2 ${ROS_DISTRO} ..."
#     if ! check_cmd ros2; then
#         wget http://fishros.com/install -O fishros && bash fishros
#         echo "鱼香ROS安装完成,请按照屏幕提示完成后续操作"
#         echo "注意:可能需重启终端或source环境"
#     fi
# fi

#确保ROS2环境变量在脚本内生效
if [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
    source /opt/ros/${ROS_DISTRO}/setup.bash
    echo "ROS2环境已加载:$(ros2 --version)"
else
    echo "警告:找不到 ROS2 setup.bash,请确认安装是否成功"
fi

# =============================================
# 4. 安装 vscode（可选）
# =============================================
step "4.安装 VS Code"
if check_cmd code; then
    echo "VS Code 已安装,跳过。"
else
    echo "通过 Snap 安装 VS Code ..."
    sudo snap install --classic code
fi

# =============================================
# 5. Python 虚拟环境 （使用 venv + system-site-packages）
# =============================================
step "5.create Python yolo 虚拟环境"
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
# 6. 深度学习包安装（CPU 还是 GPU 按需）
# =============================================
step "6. 深度学习依赖"

# 6.1 PyTorch（CUDA 12.8 对应 cu128 索引）
echo "安装 PyTorch (CUDA 12.8)..."
if python -c "import torch; print(torch.__version__)" 2>/dev/null; then
    echo "PyTorch 已安装，跳过"
else
    pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128
fi

# 6.2 YOLOv11 及视觉库
echo "安装 ultralytics, opencv, labelimg 等 ..."
pip install ultralytics opencv-python labelimg face_recognition

# 6.3 ROS2 相关 Python 包（如果需要 colcon 编译）
# echo "安装 colcon 和其他 ROS 工具..."
# sudo apt install -y python3-colcon-common-extensions python3-rosdep
# if ! grep -q "source /opt/ros/${ROS_DISTRO}/setup.bash" ~/.bashrc; then
#     echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc
# fi

# # 初始化 rosdep（首次）
# if ! check_cmd rosdep; then
#     sudo rosdep init
#     rosdep update
# fi

# 退出虚拟环境
deactivate

# =============================================
# 7. YOLO ROS 包（可选克隆）
# =============================================
step "7. 克隆 yolo_ros"
if [ -d "$HOME/yolo_ros" ]; then
    echo "yolo_ros 仓库已存在,跳过"
else
    cd ~
    git clone https://github.com/mgonzs13/yolo_ros.git
    echo "已克隆 yolo_ros,你可以后续放入 ROS 工作空间编译"
fi

# =============================================
# 8. 环境别名（方便激活）
# =============================================
step "8.配置快捷命令激活ROS+YOLO环境"
if ! grep -q 'alias yolo=' ~/.bashrc; then
    echo "添加yolo别名到 ~/.bashrc ..."
    #!!echo 'alias yolo="source /opt/ros/jazzy/setup.bash && source ~/ros_yolo_venv/bin/activate"' >> ~/.bashrc
    source ~/.bashrc
    echo "以后在终端输入yolo即可同时加载ROS2和YOLO虚拟环境"
fi

# =============================================
# 9. 环境验证脚本生成
# =============================================
step "9.验证yolo环境配置"
# 获取当前脚本所在的目录（兼容绝对路径和相对路径执行）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_SCRIPT="$SCRIPT_DIR/test_env.py"

if [ ! -f "$TEST_SCRIPT" ]; then
    echo "警告：找不到 $TEST_SCRIPT,请确保 test_env.py 与 setup.sh 在同一目录下。"
    echo "跳过环境验证"
else
    # 因为虚拟环境可能未激活，我们先激活再运行
    source /opt/ros/${ROS_DISTRO}/setup.bash
    source "$VENV_PATH/bin/activate"
    echo "正在运行 $TEST_SCRIPT ..."
    python "$TEST_SCRIPT"
    deactivate
    echo "验证完成。"
fi

# =============================================
# 10. 完成提示
# =============================================
echo ""
echo "========================================="
echo "  环境配置基本完成！请执行以下操作："
echo "  1.重启终端 或 运行: source ~/.bashrc"
echo "  2.后续安装 Nav2: sudo apt install ros-${ROS_DISTRO}-navigation2"
echo "========================================="

# 安装感知部开发过程完整的工具与内容
echo "ROS 工具:rqt,rviz2..."
echo "一般而言ros-jazzy-desktop及小鱼一键安装已经装好了rqt与rviz2 我们验证一下"
sudo apt update
apt list --installed | grep -e "rviz2" -e "rqt"
echo "你会看到带rqt与rviz2的输出"

echo “配置完整rqt功能”
sudo apt install ros-$ROS_DISTRO-rqt-tf-tree
sudo apt install ros-$ROS_DISTRO-rqt ros-$ROS_DISTRO-rqt-common-plugins
rm -rf ~/.config/ros.org/rqt_gui.ini
sudo apt install ros-$ROS_DISTRO-rqt-*
echo “之后可以用rqt和rviz2命令验证”

echo “安装gazebo与nav2”
sudo apt update
sudo apt upgrade
sudo apt install ros-jazzy-ros-gz ros-jazzy-ros-gz-sim ros-jazzy-ros-gz-bridge
sudo apt install ros-jazzy-navigation2 ros-jazzy-nav2-bringup
if ! grep -q "source /opt/ros/${ROS_DISTRO}/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc
fi
source ~/.bashrc
echo "之后输入gz sim验证gazebo安装"