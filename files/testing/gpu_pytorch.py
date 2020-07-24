import torch

print(f"CUDA devices count: {torch.cuda.device_count()}")
assert torch.cuda.is_available()

cuda = torch.device('cuda')
x = torch.randn(10_000, 1_000).to(cuda)
y = torch.randn(1_000, 10_000).to(cuda)
z = torch.matmul(x, y)

print(z)
print(f"PyTorch version {torch.__version__}: GPU test succeeded")
