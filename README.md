# TP Ima3D
## Prérequis
- Installer FIJI + plugins ()
- Creer un environement micromamba cellpose (à l'aide de cellpose.yml)
- Pour utiliser cet environement depuis jupyter notebook de l'environement de base (et ne pas réinstaller jupyter notebook dans tous les env). Il faut ensuite faire un nouveau notebook en lancant le kernel correspondant. 
'code' micromamba activate mon_env
'code' micromamba install ipykernel
'code' python -m ipykernel install --user --name=mon_env --display-name "Python (mon_env)"


## ex1/ Segmentation noyau/cytoplasme avec FIJI
- Image : NFkB_TNF_10-9.tf
- voir PDF/slides
- Macro IJ : NC_measure.ijm

## ex2/ Segmentation Organoïdes 2D+t avec cellpose
- Image : 

## ex3/ Segmentation 2D spheroïde avec cellpose
- Image BT474_z19-(RGB).tif
- Notebook test_cellpose_cell+nuc (lancer dans un environnement micromamba cellpose). Sauvegarde les masques et les ROIs qui peuvent être chargées dans FIJI  

## ex4/ Segmentation 3D spheroïde cellpose + fiji
