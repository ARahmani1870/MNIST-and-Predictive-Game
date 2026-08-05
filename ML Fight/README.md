# ML-Fight
2D combat game based on player behavioural prediction using neural networks.

If you don't want to view the source code or deal with Godot, download the game from [here](https://cptprice7.itch.io/ml-fight). Otherwise, download and install [Godot](https://godotengine.org/), and import this folder into it.

This version has the enemy AI based on my behaviour and playstyle. If you wish to train it according to your playstyle, do the following:
1. Run the game in Godot, press ESC to pause the game, and click on `Toggle ML Data` and turn it on.
2. Play the game until atleast 25,000 lines (datapoints) are saved to `combat_data.csv`, which would take about 20-30 minutes.
3. Run one of `cpu_recog.py` or `gpu_recog.py` as explained below.
4. That's it. If you wish to, you can reset the ML data (delete `combat_data.csv`) or toggle ML data logging in the game pause menu at any time.

You may want to back up the original `model_weights.json` in case you want to use it again.

You will need to have Python installed and set up with the `numpy`, `pandas` and `json` modules. If you also have an Nvidia graphics card with CUDA cores, CuPy and Nvidia CUDA Toolkit installed and set up, run `gpu_recog.py`. If you don't have all of this, run `cpu_recog.py`.