work_dir=$(pwd)
build_dir=$work_dir/build

buildid=$(date +%Y%m%d%H%M%S)
builddate=${buildid:0:8}

ERROR(){
    echo `date` - ERROR, $* | tee -a ${log_dir}/${builddate}.log
}

LOG(){
    echo `date` - INFO, $* | tee -a ${log_dir}/${builddate}.log
}

check_and_apply_board_config() {
if [[ -f $workdir/config/boards/$BOARD.conf ]];then
  source $workdir/config/boards/$BOARD.conf
  echo "boards configure file check done."
else
  echo "boards configure file check failed, please fix."
  exit 2
fi
}
