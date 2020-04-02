for i in {1..10}
  do msub -N empirical_application -q singlenode -l nodes=1:ppn=8 -l walltime=1:00:00:00 job_empirical_application.sh
done
