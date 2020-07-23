import torch
cuda = torch.device('cuda')
x = torch.randn(10_000, 1_000).to(cuda)
y = torch.randn(1_000, 10_000).to(cuda)
z = torch.matmul(x, y)

print(z)
print("PyTorch GPU test succeeded")
