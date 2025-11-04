  ls
  mkdir terraform; cd terraform
  mkdir compute network database permissions hosting visibility
  ls
  cd network;
  cp ../..
  cd ../..
  cd terraform/network/
  cp ../../root/*tf* .
  ls
  mkdir modules;
  cp ../../modules/vpc  ../../modules/na* .
  ls
  cp -r ../../modules/vpc  ../../modules/na* modules
  ls modules/
  history > commd.txt
  code commd.txt 
  history -n -10 > commd.txt
  history -n 10 > commd.txt
  code commd.txt 
  history -n 15 > commd1.txt
  code commd1
  code commd1.txt
  history > commd.txt ; tail -n 15 > commd1.txt
  history > commd.txt ; tail -n 15 commd.txt > commd1.txt
