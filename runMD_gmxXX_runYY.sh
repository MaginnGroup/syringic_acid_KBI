#!/bin/bash

GMX=gmx_mpi
module load gromacs/2022.1

HOME=`pwd`

Ns1=5000000   # N° step EQ at Tsys (1 fs) NPT [5 ns]
Ns2=50000000  # N° step PROD at Tsys (1 fs) NPT [50 ns] 

system=TAGXX  # N° ID associated to each system
run=YY        # N° 1-3 for each replicate

cd $HOME/MD/${system}/run_${run}
SYSTEM=`pwd`
printf "_____________________________________________\n     SYSTEM: ${system}   \n_____________________________________________\n"

TOPOL=$SYSTEM/system.top
INIT=$SYSTEM/0_packmol/system.gro

cd $SYSTEM
mkdir 1_run
cd 1_run
########################## MINIMIZATION ########################## 
printf "Minimization \n  "
cp $HOME/mdp/min.mdp min.mdp
gmx_mpi grompp -f min.mdp -c $INIT  -p $TOPOL  -o min.tpr  -maxwarn 10 >> 01_grompp_min.log 2>&1 
gmx_mpi mdrun -v -deffnm min >> 01_run_min.log 2>&1 

########################## EQUILIBRATION ########################## 
TIME=$(( $Ns1/1000000 ))
printf "Equilibration NPT using 1 fs as timestep for $Ns1 steps ($TIME ns)  \n  "
cp $HOME/mdp/eq.mdp eq.mdp
sed -i "s/VALUE_NSTEPS/$Ns1/" eq.mdp
gmx_mpi grompp -f eq.mdp -c min.gro  -p $TOPOL -o eq.tpr -maxwarn 10  >> 02_grompp_eq.log 2>&1 
$GMX mdrun -deffnm eq >> 02_run_eq.log 2>&1 

########################## PRODUCTION ########################## 
TIME=$(( $Ns2/1000000 ))
printf "Production NPT using 1 fs as timestep for $Ns2 steps ($TIME ns) \n  "
cp $HOME/mdp/prd.mdp prd.mdp
sed -i "s/VALUE_NSTEPS/$Ns2/" prd.mdp
gmx_mpi grompp -f prd.mdp -t eq.cpt -c eq.gro -p $TOPOL -o prod.tpr  >> 03_grompp_eqB.log 2>&1 
$GMX mdrun -deffnm prod >> 03_run_eqB.log 2>&1 

cd $SYSTEM
mkdir 2_analysis
cd 2_analysis
########################## ANALYSIS ##########################
# Notation 1: water | 2: solute | 3: hydrotropes
# change NAMETAG with the name of the hydrotrope (e.g. ETG, PD2, etc.)
# Density
echo -e 'Density'  | gmx_mpi energy -f ../1_run/prod.edr -s ../1_run/prod.tpr -o energy.xvg -b 10000 >> 3_energy.log 2>&1
grep "Density" 3_energy.log  >> $HOME/results/density/density_${system}_run${run}.log 2>&1
# RDF between center of mass of each species
gmx_mpi rdf -rmax 4.01 -b 10000 -f ../1_run/prod.xtc -s ../1_run/prod.tpr -ref "resname SAC" -sel "resname NAMETAG" -selrpos whole_res_com -seltype whole_res_com -o $HOME/results/rdf/rdf_23_${system}_run${run}.xvg >> rdf_23.log 2>&1
gmx_mpi rdf -rmax 4.01 -b 10000 -f ../1_run/prod.xtc -s ../1_run/prod.tpr -ref "resname SAC" -sel "resname SOL" -selrpos whole_res_com -seltype whole_res_com -o $HOME/results/rdf/rdf_12_${system}_run${run}.xvg >> rdf_12.log 2>&1
gmx_mpi rdf -rmax 4.01 -b 10000 -f ../1_run/prod.xtc -s ../1_run/prod.tpr -ref "resname SOL" -sel "resname SOL" -selrpos whole_res_com -seltype whole_res_com -o $HOME/results/rdf/rdf_11_${system}_run${run}.xvg >> rdf_11.log 2>&1
gmx_mpi rdf -rmax 4.01 -b 10000 -f ../1_run/prod.xtc -s ../1_run/prod.tpr -ref "resname SOL" -sel "resname NAMETAG" -selrpos whole_res_com -seltype whole_res_com -o $HOME/results/rdf/rdf_13_${system}_run${run}.xvg >> rdf_13.log 2>&1
gmx_mpi rdf -rmax 4.01 -b 10000 -f ../1_run/prod.xtc -s ../1_run/prod.tpr -ref "resname NAMETAG" -sel "resname NAMETAG" -selrpos whole_res_com -seltype whole_res_com -o $HOME/results/rdf/rdf_33_${system}_run${run}.xvg >> rdf_33.log 2>&1
# H-bonds between solute and water and between solute and hydrotropes
echo 6 1 | gmx_mpi hbond -f ../1_run/prod.xtc -s ../1_run/prod.tpr -b 10000 -g hbond.log -hbn hbond.ndx >> hbond_12.log 2>&1
echo 6 5 | gmx_mpi hbond -f ../1_run/prod.xtc -s ../1_run/prod.tpr -b 10000 -g hbond.log -hbn hbond.ndx >> hbond_23.log 2>&1
grep "Average number of hbonds per timeframe" hbond_12.log  >> $HOME/results/hbonds/hbonds_12_${system}_run${run}.log 2>&1
grep "Average number of hbonds per timeframe" hbond_23.log  >> $HOME/results/hbonds/hbonds_23_${system}_run${run}.log 2>&1
# RDF between center of mass of solute and hydrotropes atoms
gmx_mpi rdf -rmax 4.01 -b 10000 -f ../1_run/prod.xtc -s ../1_run/prod.tpr -ref "resname SAC" -selrpos whole_res_com -sel "resname NAMETAG and name O1" -seltype atom -o $HOME/results/rdf_atoms/rdf_SAC_O1_${system}_run${run}.xvg -cn $HOME/results/rdf_atoms/cn_SAC_O1_${system}_run${run}.xvg >> SAC_O1.log 2>&1
gmx_mpi rdf -rmax 4.01 -b 10000 -f ../1_run/prod.xtc -s ../1_run/prod.tpr -ref "resname SAC" -selrpos whole_res_com -sel "resname NAMETAG and name O2" -seltype atom -o $HOME/results/rdf_atoms/rdf_SAC_O2_${system}_run${run}.xvg -cn $HOME/results/rdf_atoms/cn_SAC_O2_${system}_run${run}.xvg >> SAC_O2.log 2>&1
gmx_mpi rdf -rmax 4.01 -b 10000 -f ../1_run/prod.xtc -s ../1_run/prod.tpr -ref "resname SAC" -selrpos whole_res_com -sel "resname NAMETAG and name C2" -seltype atom -o $HOME/results/rdf_atoms/rdf_SAC_C1_${system}_run${run}.xvg -cn $HOME/results/rdf_atoms/cn_SAC_C1_${system}_run${run}.xvg >> SAC_C1.log 2>&1
gmx_mpi rdf -rmax 4.01 -b 10000 -f ../1_run/prod.xtc -s ../1_run/prod.tpr -ref "resname SAC" -selrpos whole_res_com -sel "resname NAMETAG and name C1" -seltype atom -o $HOME/results/rdf_atoms/rdf_SAC_C2_${system}_run${run}.xvg -cn $HOME/results/rdf_atoms/cn_SAC_C2_${system}_run${run}.xvg >> SAC_C2.log 2>&1




