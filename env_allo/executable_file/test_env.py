import torch
import platform

print("="*60)
print("系统信息:")
print(f"操作系统: {platform.system()} {platform.version()}")
print(f"Python版本: {platform.python_version()}")
print("="*60)

print("\nCUDA状态检查:")
print(f"PyTorch版本: {torch.__version__}")
print(f"CUDA可用: {torch.cuda.is_available()}")

if torch.cuda.is_available():
    print(f"\nGPU信息:")
    print(f"设备数量: {torch.cuda.device_count()}")

    for i in range(torch.cuda.device_count()):
        print(f"\nGPU {i}:")
        prop = torch.cuda.get_device_properties(i)
        print(f"  名称: {prop.name}")
        print(f"  架构: sm_{prop.major}{prop.minor}")
        print(f"  显存: {prop.total_memory / 1024 ** 3:.2f} GB")
        print(f"  多处理器数量: {prop.multi_processor_count}")

    print(f"\nCUDA版本: {torch.version.cuda}")
    print(f"cuDNN版本: {torch.backends.cudnn.version()}")
else:
    print("\nCUDA不可用,原因可能是:")
    print("1. 没有NVIDIA显卡")
    print("2. 没有安装显卡驱动")
    print("3. PyTorch版本不支持你的显卡")

# 测试GPU计算
print("\n" + "=" * 60)
print("GPU计算测试:")
if torch.cuda.is_available():
    try:
        # 测试基本计算
        a = torch.randn(1000, 1000, device='cuda')
        b = torch.randn(1000, 1000, device='cuda')
        c = torch.matmul(a, b)
        print("✓ 基本矩阵乘法测试通过")

        # 测试半精度计算if torch.cuda.get_device_properties(0).major >= 5:  
        a_half = torch.randn(1000, 1000, device='cuda', dtype=torch.float16)
        b_half = torch.randn(1000, 1000, device='cuda', dtype=torch.float16)
        c_half = torch.matmul(a_half, b_half)
        print("✓ 半精度计算测试通过")

        # 测试内存分配
        large_tensor = torch.randn(1000, 1000, 100, device='cuda')  # 约占用 400MB 显存del large_tensor
        torch.cuda.empty_cache()
        print("✓ 大内存分配测试通过")

    except Exception as e:
        print(f"✗ GPU测试失败: {e}")
else:
    print("跳过GPU测试(CUDA不可用)")