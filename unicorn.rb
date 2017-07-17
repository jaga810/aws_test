@dir = "/home/ec2-user/app/"

worker_processes 1 # CPUのコア数に揃える
working_directory @dir

timeout 300
listen 8080

pid "#{@dir}tmp/pids/unicorn.pid" #pidを保存するファイル

stderr_path "#{@dir}log/unicorn.stderr.log"
stdout_path "#{@dir}log/unicorn.stdout.log"
