#!/bin/bash
rm -f test.txt
rm -f cluster_no.txt
rm -f project_list.txt
gcloud projects list | awk '{print $1}' | tail -n +2 >> project_list.txt
echo "======================="
echo "     Select Project    "
echo "======================="
awk '{print NR,$0}' project_list.txt | tee project_select.txt
read -p "Select Project:" P_Select
projectname=$(sed -sn "$P_Select"p project_select.txt | cut -d ' ' -f2 )
#read -p "Enter No of Node(if you want to temporary down it just enter it 0):" resize
echo "Selected Project:" $projectname
y=$(echo "set")
echo "========================================="
echo " Seting Project" $projectname
echo "========================================="
gcloud config $y project $projectname
cluster_list=$(gcloud container clusters list | awk '{print $1}' | tail -n +2)
for x in $cluster_list
do
echo $x >> test.txt
done
echo "======================="
echo "     Select Cluster    "
echo "======================="
awk '{print NR,$0}' test.txt | tee cluster_no.txt
read -p "Enter Option(for down all Just Enter all):" o
    if [ $o != "all" ]
      then
         cluster=$(sed -sn  "$o"p cluster_no.txt | cut -d ' ' -f2)
         echo "Selected Cluster Name:" $cluster
         pool_list=$(gcloud container  node-pools list --cluster $cluster| awk '{print $1}' | tail -n +2)
         pool_name=$(gcloud container  node-pools describe $pool_list --cluster $cluster | grep compute/v1 | awk -F '/' '{print $11}'|awk -F '-' '{print $2"-"$3"-"$4}')
         gcloud container clusters update $cluster  --enable-autoscaling
         gcloud container node-pools update $(gcloud container node-pools list --cluster $cluster | awk {'print $1'} | tail -n +2) --cluster $cluster --enable-autorepair
         nodes_name=$(gcloud compute instances list | awk '{print $1}'| grep -i $pool_name)
          for z in $nodes_name
          do              
	  echo "==================================================================="
	  echo " Starting Node" $z
	  echo "==================================================================="
          gcloud compute instances start $z
          done
   else
	echo "Selected Cluster Name: ALL cluster are going to down"
   for v in $cluster_list
     do
         gcloud container clusters update $v  --enable-autoscaling
         gcloud container node-pools update $(gcloud container node-pools list --cluster $v | awk {'print $1'} | tail -n +2) --cluster $v  --enable-autorepair
     done  
       node_all=$(gcloud compute instances list | awk '{print $1}' | tail -n +2)
          for z in $node_all
          do
	  echo "==================================================================="
	  echo " Starting Node" $z
	  echo "==================================================================="
           gcloud compute instances start $z
          done
fi
rm -f test.txt
rm -f cluster_no.txt
rm -f project_list.txt
