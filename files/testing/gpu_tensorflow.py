import tensorflow as tf

print(tf.config.experimental.list_physical_devices())
assert tf.test.is_gpu_available()

x = tf.random.normal(shape=[10_000, 1_000])
y = tf.random.normal(shape=[1_000, 10_000])
z = tf.matmul(x, y)

print(z)
print("TensorFlow GPU test succeeded")