
#!/bin/bash

output_dir=$1

./analyze-logs.sh $(kubectl get pods -l job-name=ssquery-single -o name) > $output_dir/analysis.txt
kubectl logs -l job-name=ssquery-single --tail=-1 > $output_dir/ssquery-single-logs.txt
kubectl logs -l job-name=ssquery --tail=-1 >  $output_dir/ssquery-all-logs.txt
cp query-job.yaml $output_dir
cp query-single.yaml $output_dir
