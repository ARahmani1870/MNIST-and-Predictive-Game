import cupy as cp
import pandas
import json

data = cp.array(pandas.read_csv('combat_data.txt').values)
cp.random.shuffle(data)

alldp = data.shape[0]
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
one_hot = cp.zeros((datapoints, 8), dtype=int)
one_hot[cp.arange(datapoints), labels] = 1
one_hot = one_hot.T

# one-hot mapping for dev
dev_hot = cp.zeros((devDatapoints, 8), dtype=int)
dev_hot[cp.arange(devDatapoints), devLabels] = 1
dev_hot = dev_hot.T

# 10 input parameters, 8 possible predictions
layers = [10, 32, 32, 8]

weights = list()
biases = list()

for i in range(len(layers)):
    weights.append(cp.random.randn(layers[i], layers[i - 1]) * cp.sqrt(1 / layers[i - 1]))
    biases.append(cp.zeros((layers[i], 1)))

def ReLU(arr):
    ret = arr.copy()
    mask = ret < 0
    ret[mask] = 0
    return ret

def ReLU_prime(arr):
    ret = cp.zeros(arr.shape)
    mask = arr > 0
    ret[mask] = 1
    return ret

def softmax(arr):
    ret = arr.copy()
    ret -= cp.max(ret, axis=0, keepdims=True)
    denom = cp.sum(cp.exp(ret), axis=0)
    ret = cp.exp(ret) / denom
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

    perm = cp.random.permutation(datapoints)
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
            Z = cp.matmul(weights[j], As[j - 1]) + biases[j]
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
            deltaW = cp.matmul(deltaZ, As[j - 1].T) / currentBatchSize
            deltaWs.append(deltaW)

            deltaB = cp.sum(deltaZ, axis=1, keepdims=True) / currentBatchSize
            deltaBs.append(deltaB)

            if j > 1:
                deltaZ = cp.matmul(weights[j].T, deltaZ) * ReLU_prime(Zs[j - 1])

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
        Z = cp.matmul(weights[j], As[j - 1]) + biases[j]
        Zs.append(Z)

        A = ReLU(Z)
        As.append(A)

    As.pop()
    pred = softmax(Zs[-1])
    As.append(pred)

    L = (-1 / devDatapoints) * cp.sum(dev_hot * cp.log(pred + epsilon))
    
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
    Z = cp.matmul(recordWs[j], As[j - 1]) + recordBs[j]
    Zs.append(Z)

    A = ReLU(Z)
    As.append(A)

As.pop()
pred = softmax(Zs[-1])

predictions = cp.argmax(pred, axis=0)
correct = cp.sum(predictions == testLabels)

print("Accuracy: " + str(round((float(correct) / testDatapoints) * 100, 3)) + "%")

# JSON dump

export_data = {
    "weights": [w.tolist() if isinstance(w, cp.ndarray) else None for w in recordWs],
    "biases": [b.tolist() if isinstance(b, cp.ndarray) else None for b in recordBs]
}

with open("model_weights.json", "w") as f:
    json.dump(export_data, f)