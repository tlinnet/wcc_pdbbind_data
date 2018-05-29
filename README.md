# wcc_pdbbind_data

Make alias to Docker. Point to the folder where the pdbbind data is.

```bash
alias drd='docker run -ti --rm -p 8888:8888 -v "${HOME}/software/wcc_pdbbind_data":/home/jovyan/work --name rdock $USER/rdock'
```

## Then write commands for list with 5 PDB

```bash
# Make standard with 3 runs
drd ./00_execute_pdb_list.sh -p 00_5_pdb.txt

# With 5 runs 
drd ./00_execute_pdb_list.sh -p 00_5_pdb.txt n 5

# With 5 runs, and force write -w and force execute -w
drd ./00_execute_pdb_list.sh -p 00_5_pdb.txt -w -e n 5
```

## Then execute commands with GNU parallel

```bash
drd ./commands_run.sh
```

## Get the timings

```bash
drd ./10_get_timings.sh -p 00_all_pdb.txt 
```

## Clean up files

```bash
drd ./11_clean_files.sh -p 00_5_pdb.txt
drd ./11_clean_files.sh -p 00_all_pdb.txt
```
