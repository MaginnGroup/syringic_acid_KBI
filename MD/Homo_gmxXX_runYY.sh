#!/bin/bash
module load gromacs/2022.1

HOME=`pwd`

system=TAGXX    # Folder name (it's a number)
run=YY          # Run number


cd $HOME/MD/${system}/run_${run}
SYSTEM=`pwd`
printf "_____________________________________________\n     SYSTEM: ${system}   \n_____________________________________________\n"

########################## INITIAL CONF. ##########################
TOPOL=$SYSTEM/system.top
INIT=$SYSTEM/0_packmol/system.gro

cd $SYSTEM
mkdir 1_run
cd 1_run
########################## MINIMIZATION ########################## 
printf "Minimization in phase 1  \n  "
cp $HOME/mdp/min.mdp min.mdp
gmx_mpi grompp -f min.mdp -c $INIT  -p $TOPOL  -o min.tpr  -maxwarn 10 >> 01_grompp_min.log 2>&1 
gmx_mpi mdrun -v -deffnm min >> 01_run_min.log 2>&1 


########################## EQUILIBRATION ########################## 
printf "Equilibration NPT \n  "

cp $HOME/mdp/eq.mdp eq.mdp
gmx_mpi mdrun -v -deffnm eq >> 02_run_eq.log 2>&1 


########################## PRODUCTION ########################## 
printf "Production NPT \n  "
gmx_mpi grompp -f prd.mdp -t eq.cpt -c eq.gro -p $TOPOL -o prod.tpr  >> 03_grompp_eqB.log 2>&1 
gmx_mpi mdrun -v -deffnm prod >> 03_run_eqB.log 2>&1 


########################## ANALYSIS ##########################
echo -e 'Density'  | gmx_mpi energy -f prod.edr -s prod.tpr -o energy.xvg -b 10000 >> 3_energy.log 2>&1
grep "Density" 3_energy.log  >> $HOME/results/density_${system}_run${run}.log 2>&1


########################## RDF ##########################
# NAMETAG is the name of the residue you want to analyze (hydrotrope)
gmx_mpi rdf -rmax 4.01 -b 10000 -f prod.xtc -s prod.tpr -ref "resname SAC" -sel "resname NAMETAG" -selrpos whole_res_com -seltype whole_res_com -o $HOME/results_rdf/rdf_23_${system}_run${run}.xvg>> rdf_23.log 2>&1
gmx_mpi rdf -rmax 4.01 -b 10000 -f prod.xtc -s prod.tpr -ref "resname SAC" -sel "resname SOL" -selrpos whole_res_com -seltype whole_res_com -o $HOME/results_rdf/rdf_12_${system}_run${run}.xvg >> rdf_12.log 2>&1
gmx_mpi rdf -rmax 4.01 -b 10000 -f prod.xtc -s prod.tpr -ref "resname SOL" -sel "resname SOL" -selrpos whole_res_com -seltype whole_res_com -o $HOME/results_rdf/rdf_11_${system}_run${run}.xvg >> rdf_11.log 2>&1
gmx_mpi rdf -rmax 4.01 -b 10000 -f prod.xtc -s prod.tpr -ref "resname SOL" -sel "resname NAMETAG" -selrpos whole_res_com -seltype whole_res_com -o $HOME/results_rdf/rdf_13_${system}_run${run}.xvg >> rdf_13.log 2>&1
gmx_mpi rdf -rmax 4.01 -b 10000 -f prod.xtc -s prod.tpr -ref "resname NAMETAG" -sel "resname NAMETAG" -selrpos whole_res_com -seltype whole_res_com -o $HOME/results_rdf/rdf_33_${system}_run${run}.xvg >> rdf_33.log 2>&1




