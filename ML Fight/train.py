import sys
import os

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir:
    os.chdir(script_dir)

if not os.path.exists('combat_data.txt'):
    print("Error: combat_data.txt not found. Run the game in Godot, press ESC, turn on 'Toggle ML Data', and play to record data first.")
    sys.exit(1)

try:
    if "--cpu" in sys.argv:
        raise ImportError
    import cupy as xp
    if not xp.cuda.is_available():
        raise ImportError
    xp.matmul(xp.zeros((1, 1)), xp.zeros((1, 1)))
except Exception:
    import numpy as xp
import pandas
import json

data = xp.array(pandas.read_csv('combat_data.txt').values)
alldp = data.shape[0]

if alldp < 50:
    print("Error: Not enough combat data to train. Play more matches with 'Toggle ML Data' enabled first.")
    sys.exit(1)

xp.random.shuffle(data)

forTest = int(0.05 * alldp) # 5% set aside for testing
forDev = forTest + int(0.1 * alldp) # 10% set aside for dev

test_data = data[:forTest]
dev_data = data[forTest:forDev]
train = data[forDev:]

# for training
datapoints = train.shape[0]
labels = train[:, -1].astype(int)
pics = (train[:, :-1] / 100.0).T

# for testing
testDatapoints = test_data.shape[0]
testLabels = test_data[:, -1].astype(int)
testPics = (test_data[:, :-1] / 100.0).T

# for dev
devDatapoints = dev_data.shape[0]
devLabels = dev_data[:, -1].astype(int)
devPics = (dev_data[:, :-1] / 100.0).T

# one-hot mapping for training
one_hot = xp.zeros((datapoints, 8), dtype=int)
one_hot[xp.arange(datapoints), labels] = 1
one_hot = one_hot.T

# one-hot mapping for dev
dev_hot = xp.zeros((devDatapoints, 8), dtype=int)
dev_hot[xp.arange(devDatapoints), devLabels] = 1
dev_hot = dev_hot.T

# 10 input parameters, 8 possible predictions
layers = [10, 32, 32, 8]

weights = list()
biases = list()

for i in range(len(layers)):
    weights.append(xp.random.randn(layers[i], layers[i - 1]) * xp.sqrt(1 / layers[i - 1]))
    biases.append(xp.zeros((layers[i], 1)))

def ReLU(arr):
    ret = arr.copy()
    mask = ret < 0
    ret[mask] = 0
    return ret

def ReLU_prime(arr):
    ret = xp.zeros(arr.shape)
    mask = arr > 0
    ret[mask] = 1
    return ret

def softmax(arr):
    ret = arr.copy()
    ret -= xp.max(ret, axis=0, keepdims=True)
    denom = xp.sum(xp.exp(ret), axis=0)
    ret = xp.exp(ret) / denom
    return ret

epochs = 10000
learningRate = 0.1
epsilon = 1e-10 # prevent log(0) domain error
batch_size = 128

# for early stopping

fails = 0
patience = 25
bestLoss = float("inf")
recordWs = list()
recordBs = list()

for i in range(epochs):

    perm = xp.random.permutation(datapoints)
    pics = pics[:, perm]
    one_hot = one_hot[:, perm]

    # mini-batching

    for k in range(0, datapoints, batch_size):
        
        batchPics = pics[:, k:k + batch_size]
        batchHot = one_hot[:, k:k + batch_size]
        currentBatchSize = batchPics.shape[1] # datapoints / batchSize may not be an int

        # forward propagation

        Zs = [batchPics,]
        As = [batchPics,]

        for j in range(1, len(layers)):
            Z = xp.matmul(weights[j], As[j - 1]) + biases[j]
            Zs.append(Z)

            A = ReLU(Z)
            As.append(A)

        As.pop()
        pred = softmax(Zs[-1])
        As.append(pred)

        # backwards propagation

        deltaZ = pred - batchHot

        deltaWs = list()
        deltaBs = list()

        for j in range(len(layers) - 1, 0, -1):
            deltaW = xp.matmul(deltaZ, As[j - 1].T) / currentBatchSize
            deltaWs.append(deltaW)

            deltaB = xp.sum(deltaZ, axis=1, keepdims=True) / currentBatchSize
            deltaBs.append(deltaB)

            if j > 1:
                deltaZ = xp.matmul(weights[j].T, deltaZ) * ReLU_prime(Zs[j - 1])

        deltaWs.reverse()
        deltaBs.reverse()

        # learning

        for j in range(1, len(layers)):
            weights[j] = weights[j] - learningRate * deltaWs[j - 1]
            biases[j] = biases[j] - learningRate * deltaBs[j - 1]

    # early stopping

    Zs = [devPics,]
    As = [devPics,]

    for j in range(1, len(layers)):
        Z = xp.matmul(weights[j], As[j - 1]) + biases[j]
        Zs.append(Z)

        A = ReLU(Z)
        As.append(A)

    As.pop()
    pred = softmax(Zs[-1])
    As.append(pred)

    L = (-1 / devDatapoints) * xp.sum(dev_hot * xp.log(pred + epsilon))
    
    if bestLoss > L:
        bestLoss = L
        fails = 0
        recordWs = [w.copy() for w in weights]
        recordBs = [b.copy() for b in biases]
    else:
        fails += 1

    if fails > patience:
        print("Epochs trained: ", i)
        break
else:
    print(f"Epochs trained: {epochs}")

Zs = [testPics,]
As = [testPics,]

for j in range(1, len(layers)):
    Z = xp.matmul(recordWs[j], As[j - 1]) + recordBs[j]
    Zs.append(Z)

    A = ReLU(Z)
    As.append(A)

As.pop()
pred = softmax(Zs[-1])

predictions = xp.argmax(pred, axis=0)
correct = xp.sum(predictions == testLabels)

print("Accuracy: " + str(round((float(correct) / testDatapoints) * 100, 3)) + "%")

# JSON dump

export_data = {
    "weights": [w.tolist() if hasattr(w, "tolist") else w for w in recordWs],
    "biases": [b.tolist() if hasattr(b, "tolist") else b for b in recordBs]
}

with open("model_weights.json", "w") as f:
    json.dump(export_data, f)
