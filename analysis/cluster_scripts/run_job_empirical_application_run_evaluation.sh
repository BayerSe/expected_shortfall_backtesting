for i in {1..1}
  do msub -N empirical_application_evaluation -q singlenode -l nodes=1:ppn=8 -l walltime=00:03:00:00 job_empirical_application_evaluation.sh
done
