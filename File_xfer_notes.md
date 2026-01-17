## ucd.brassica

12/29/2025

Asked CW about image files

Transferring raw.data/sequencing

```
gocmd get --progress -f -K --icat  /iplant/home/shared/ucd.brassica/raw.data/sequencing ucd.brassica/raw.data/sequencing
```

## my home directory

```
cd /media/volume/cyverse-data/
gocmd get --progress -f -K --icat /iplant/home/jnmaloof jnmaloof
```

## ucd.tomato

Would like to use ibun to compress some files before moving but have a permissions error

In the meantime, move the raw files

```
cd /media/volume/cyverse-data/ucd.tomato
gocmd get --progress -f -K --icat /iplant/home/shared/ucd.tomato/raw.seq.data raw.seq.data
```

Above not working because another process is already downloading.  Trying iget

```
iget -PrfTK -X restart  /iplant/home/shared/ucd.tomato/raw.seq.data raw.seq.data
```

Works!