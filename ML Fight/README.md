# ML-Fight
2D combat game based on player behavioural prediction using neural networks.

If you don't want to view the source code or deal with Godot, download the game from [here](https://cptprice7.itch.io/ml-fight). Otherwise, download and install [Godot](https://godotengine.org/), and import this folder into it.

This version has the enemy AI based on my behaviour and playstyle. If you wish to train it according to your playstyle, do the following:
1. Run the game in Godot, press ESC to pause the game, and click on `Toggle ML Data` and turn it on.
2. Play the game until atleast 25,000 lines (datapoints) are saved to `combat_data.txt`, which would take about 20-30 minutes.
3. Run `train.py` as explained below.
4. That's it. If you wish to, you can reset the ML data (delete `combat_data.txt`) or toggle ML data logging in the game pause menu at any time.

You may want to back up the original `model_weights.json` in case you want to use it again.

### Running train.py

Using [uv](https://docs.astral.sh/uv/) (recommended):
```
uv run train.py
```

Using standard Python:
Install `numpy` and `pandas`, then run:
```
python train.py
```

If you have an Nvidia graphics card, CUDA Toolkit (version 13), and CuPy installed, `train.py` will automatically use the GPU. Otherwise, it runs on CPU. You can force CPU mode by passing `--cpu`:
```
python train.py --cpu
```
