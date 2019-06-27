source ~/aws-transfers/bin/activate
rm */.tar.gz
for dir in */
 do runname=`echo $dir|cut -d_ -f3`
 runname=${runname##0}
 date=`echo $dir | cut -d_ -f1`
 date_restructured=${date:2:4}${date:0:2}
 destination_dir=run${runname}_himcandrew0_${date_restructured}
 destination_file=${dir%%/}.tar.gz
 tar -czvf ${destination_file} $dir && aws s3 cp ${destination_file} s3://10x-data-backup/${destination_dir}/raw_data/${destination_file}
 done
 deactivate
