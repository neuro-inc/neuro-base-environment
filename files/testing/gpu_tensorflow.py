import tensorflow as tf
x = tf.random.normal(shape=[10_000, 1_000])
y = tf.random.normal(shape=[1_000, 10_000])
z = tf.matmul(x, y)

print(z)
print("TensorFlow GPU test succeeded")