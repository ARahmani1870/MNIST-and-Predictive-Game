### Running the Notebook

Open `recog.ipynb`. If you have an Nvidia graphics card with CUDA cores, Nvidia CUDA Toolkit (version 13) and CuPy installed, it will automatically train on the GPU. Otherwise, it runs on the CPU. To force CPU mode, set `FORCE_CPU = True` in the first cell.

Using [uv](https://docs.astral.sh/uv/) (recommended):
```
uv run --extra notebooks jupyter notebook
```

Using standard Python:
Install `numpy`, `pandas`, `matplotlib`, and `jupyter`, then start Jupyter Notebook:
```
jupyter notebook
```

Credit to Yann LeCun, Corinna Cortes, and Christopher J.C. Burges for the MNIST dataset.
Downloaded in CSV format from [Digit Recognizer | Kaggle](https://www.kaggle.com/competitions/digit-recognizer/) which is under the [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/) license.
