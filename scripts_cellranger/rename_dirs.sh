for dir in `aws s3 ls s3://10x-data-backup | grep andrew0 | grep _17`
 do namebase=${dir%%_1*}
 namedate=${dir##*0_}
 new_dir="run${namebase}_${namedate:2:2}${namedate:4:2}${namedate:0:2}"
 aws s3 cp --recursive s3://10x-data-backup/${dir%%/}  s3://10x-data-backup/${new_dir}
 done