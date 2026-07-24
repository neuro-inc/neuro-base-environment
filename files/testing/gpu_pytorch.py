import torch

print(f"CUDA devices count: {torch.cuda.device_count()}")
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
if device.type == "cpu":
    print("No CUDA available, running the matmul on CPU")

x = torch.randn(10_000, 1_000).to(device)
y = torch.randn(1_000, 10_000).to(device)
z = torch.matmul(x, y)

print(z)
print(
    f"PyTorch version {torch.__version__}: "
    f"{device.type} availability test succeeded"
)
