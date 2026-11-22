# MNIST and Predictive Game

This repository contains two projects using neural networks implemented from scratch:

- [ML Fight](./ML%20Fight/): A 2D Godot combat game where enemy AI learns and predicts player actions using neural networks.
- [MNIST Digit Recogniser](./MNIST%20Digit%20Recogniser/): Multi-layer perceptron implementation training on the MNIST dataset using CPU (NumPy) or GPU (CuPy).

## Quickstart with uv

Using [uv](https://docs.astral.sh/uv/) is recommended so you do not need to manually configure Python environments or install dependencies.

To train the ML Fight model:
```
uv run "ML Fight/train.py"
```

To run the MNIST notebook:
```
uv run --extra notebooks jupyter notebook
```

For GPU training with CUDA support using uv (requires NVIDIA CUDA Toolkit 13):
```
uv run --extra gpu "ML Fight/train.py"
```

For standalone setup and Godot instructions, see the README inside each subfolder.
