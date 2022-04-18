rm deps.zip
rm message.zip
rm dripfeed.zip
dir=`pwd`

zip -r deps.zip ./python/lib/python3.9/site-packages

cd message/
zip -r $dir/message.zip main.py

cd $dir
cd dripfeed/
zip -r $dir/dripfeed.zip main.py
