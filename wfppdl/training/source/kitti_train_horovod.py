'''
Train PredNet on KITTI sequences. (Geiger et al. 2013, http://www.cvlibs.net/datasets/kitti/)
'''

import os
import numpy as np
np.random.seed(123)
#from six.moves import cPickle

from keras import backend as K
from keras.models import Model
from keras.layers import Input, Dense, Flatten
from keras.layers import LSTM
from keras.layers import TimeDistributed
from keras.callbacks import LearningRateScheduler, ModelCheckpoint
from keras.optimizers import Adam
from prednet import PredNet
from data_utils import SequenceGenerator
from kitti_settings import *
import datetime
import horovod.keras as hvd
import keras
import tensorflow as tf
#Horovod:initialize horovod
hvd.init()
#Horovod: pin GPU to be used for process local rank (one GPU per process)
config = tf.ConfigProto()
config.gpu_options.allow_growth = True
config.gpu_options.visible_device_list = str(hvd.local_rank())
K.set_session(tf.Session(config=config))

print("horovode size", hvd.size())

save_model = True# if weights will be saved
weights_file = os.path.join(WEIGHTS_DIR, 'prednet_kitti_weights.hdf5')  # where weights will be saved
json_file = os.path.join(WEIGHTS_DIR, 'prednet_kitti_model.json')
if not os.path.exists(WEIGHTS_DIR): os.mkdir(WEIGHTS_DIR)
# Data files
train_file = os.path.join(DATA_DIR, 'X_train.hkl')
train_sources = os.path.join(DATA_DIR, 'sources_train.hkl')
val_file = os.path.join(DATA_DIR, 'X_val.hkl')
val_sources = os.path.join(DATA_DIR, 'sources_val.hkl')

# Training parameters
nb_epoch = 10 #original: 150; for all tests so far set to 100; t2onlyMax: 150
batch_size = 15
samples_per_epoch = 500 #original: 500; for all tests so far set to 300; t2onlyMax: 500
N_seq_val = 80  # number of sequences to use for validation ##original: 100; for all tests so far set to 65; t2onlyMax: 80

# Model parameters
n_channels, im_height, im_width = (3, 128, 160) 
input_shape = (n_channels, im_height, im_width) if K.image_data_format() == 'channels_first' else (im_height, im_width, n_channels)
stack_sizes = (n_channels, 48, 96, 192)
R_stack_sizes = stack_sizes
A_filt_sizes = (3, 3, 3)
Ahat_filt_sizes = (3, 3, 3, 3)
R_filt_sizes = (3, 3, 3, 3)
layer_loss_weights = np.array([1., 0., 0., 0.])  # weighting for each layer in final loss; "L_0" model:  [1, 0, 0, 0], "L_all": [1, 0.1, 0.1, 0.1]
layer_loss_weights = np.expand_dims(layer_loss_weights, 1)
nt = 10  # number of timesteps used for sequences in training
time_loss_weights = 1./ (nt - 1) * np.ones((nt,1))  # equally weight all timesteps except the first
time_loss_weights[0] = 0

prednet = PredNet(stack_sizes, R_stack_sizes,
			  A_filt_sizes, Ahat_filt_sizes, R_filt_sizes,
			  output_mode='error', return_sequences=True)
inputs = Input(shape=(nt,) + input_shape)
errors = prednet(inputs)  # errors will be (batch_size, nt, nb_layers)
errors_by_time = TimeDistributed(Dense(1, trainable=False), weights=[layer_loss_weights, np.zeros(1)], trainable=False)(errors)  # calculate weighted error by layer
errors_by_time = Flatten()(errors_by_time)  # will be (batch_size, nt)
final_errors = Dense(1, weights=[time_loss_weights, np.zeros(1)], trainable=False)(errors_by_time)  # weight errors by time
model = Model(inputs=inputs, outputs=final_errors)
#Horovod:ajust learning rate based on number of GPUs
opt = keras.optimizers.Adam(0.01 * hvd.size())
#Horovod: add horovod DistributedOptimizer
opt = hvd.DistributedOptimizer(opt)
#Horovode: use hvd.DistributedOptimizer to compute gradients
model.compile(loss="mean_absolute_error", optimizer=opt, metrics=["accuracy"])



train_generator = SequenceGenerator(train_file, train_sources, nt, batch_size=batch_size, shuffle=True)
val_generator = SequenceGenerator(val_file, val_sources, nt, batch_size=batch_size, N_seq=N_seq_val)

#lr_schedule = lambda epoch: 0.001 if epoch < 75 else 0.0001    # start with lr of 0.001 and then drop to 0.0001 after 75 epochs
callbacks = [hvd.callbacks.BroadcastGlobalVariablesCallback(0),
         #hvd.callbacks.MetricAverageCallback(),
         hvd.callbacks.LearningRateWarmupCallback(warmup_epochs=5,verbose=1)
         ]
#bing: original save_model is True
if hvd.rank() == 0:
    if save_model:
        print("===========The model will be saved =======")
        callbacks.append(ModelCheckpoint(filepath=weights_file, monitor='val_loss', save_best_only=True))

#the start training time
a = datetime.datetime.now()

history = model.fit_generator(generator=train_generator,steps_per_epoch=samples_per_epoch/(batch_size*hvd.size()), epochs=nb_epoch, callbacks=callbacks,
                validation_data=val_generator, validation_steps=N_seq_val/(batch_size*hvd.size()))


b = datetime.datetime.now()

#the training time
t = b-a

stats = list(train_generator.X.shape)
stats.append(t)

print("training time is",stats)

if save_model:
    json_string = model.to_json()
    with open(json_file, "w") as f:
        f.write(json_string)



