# Where KITTI data will be saved if you run process_kitti.py
# If you directly download the processed data, change to the path of the data.
## Changed logic: Now this is the path where the processed data lies: X_train,val,test
#DATA_DIR = './kitti_data/'
#data directory for training data 2015 and 2016
#DATA_DIR = '/p/project/cjjsc42/severin/try3'
#data directory for moving objects:
#DATA_DIR = '/p/home/jusers/hussmann1/jureca/movingObjects/se_nw'
#data directory for featuretesting:
##DATA_DIR = './testTry2'
DATA_DIR = '../splits'
# Where model weights and config will be saved if you run kitti_train.py
# If you directly download the trained weights, change to appropriate path.
WEIGHTS_DIR = './model_data_keras2/'
#WEIGHTS_DIR = '/p/project/cjjsc42/bing/ml-severin/model_data_keras2'

# Where results (prediction plots and evaluation file) will be saved.
RESULTS_SAVE_DIR = './kitti_results'

