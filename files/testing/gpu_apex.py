import torch
import torch.nn
import torch.nn.functional as F
from apex import amp
from apex.fp16_utils import FP16_Optimizer

D_in, D_out = 100, 200
model = torch.nn.Linear(D_in, D_out).cuda()

optimizer = torch.optim.SGD(model.parameters(), lr=1e-3)
model, optimizer = amp.initialize(model, optimizer, opt_level="O1")
loss_fn = torch.nn.MSELoss(reduction="sum")
learning_rate = 1e-4
optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate)

model, optimizer = amp.initialize(model, optimizer, opt_level="O1")

N = 64
x = torch.randn(N, D_in, dtype=torch.half).cuda()
y = torch.randn(N, D_out, dtype=torch.half).cuda()
y_pred = model(x)
loss = loss_fn(y_pred, y)

with amp.scale_loss(loss, optimizer) as scaled_loss:
    scaled_loss.backward()
