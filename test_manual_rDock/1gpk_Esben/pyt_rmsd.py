import pandas as pd

# Read csv file
results = pd.read_csv("log_04_score.log")
# Get the index of minimum value
min_index = results.SCORE.idxmin()
best_rmsd = str(results.RMSD[min_index])
best_rmsd_text = "Best RMSD: %s\n"%best_rmsd
print(best_rmsd_text)
print(results.SCORE)