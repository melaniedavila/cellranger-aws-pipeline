for dir in "${dirs[@]}"
 do cp config_170302_NS500672_0178_AHYJJ7BGXY.yaml config_${dir}.yaml
 run_number=${dir##*_0};run_number=${run_number%%_*}
  date=${dir##*config_};date=${date%%_*}
  date_to_put="20${date:0:2}-${date:2:2}-${date:4:2}"
sed -i -e "s/170302_NS500672_0178_AHYJJ7BGXY/${dir}/g" config_${dir}.yaml
sed -i -e "s/id: 178/id: ${run_number}/g" config_${dir}.yaml
sed -i -e "s/\"2017-03-02\"/\"${date_to_put}\"/g" config_${dir}.yaml
  done
