for i in {1..10}
  do msub -N monte_carlo_2 -q singlenode -l nodes=1:ppn=8 -l walltime=03:00:00:00 job_monte_carlo_2.sh
done
