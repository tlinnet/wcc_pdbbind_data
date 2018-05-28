# wcc_pdbbind_data

Make alias to Docker. Point to the folder where the pdbbind data is.

```bash
alias drd='docker run -ti --rm -p 8888:8888 -v "${HOME}/software/wcc_pdbbind_data":/home/jovyan/work --name rdock $USER/rdock'
```

Then execute

```bash
drd ./00_execute_pdb_list.sh -p 00_5_pdb.txt
```
