import tensorflow as tf

print(tf.config.experimental.list_physical_devices())
has_gpu = tf.test.is_gpu_available()
if not has_gpu:
    print("No GPU available, running the matmul on CPU")

x = tf.random.normal(shape=[10_000, 1_000])
y = tf.random.normal(shape=[1_000, 10_000])
z = tf.matmul(x, y)

print(z)
device = "GPU" if has_gpu else "CPU"
print(
    f"TensorFlow version {tf.__version__}: "
    f"{device} availability test succeeded"
)
