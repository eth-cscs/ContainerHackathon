import hickle as hkl
import numpy as np
from keras import backend as K
from keras.preprocessing.image import Iterator


import inspect
print(inspect.getmembers(hkl,predicate=inspect.ismethod))

# Data generator that creates sequences for input into PredNet.
class SequenceGenerator(Iterator):
    def __init__(self, data_file, source_file, nt,
                 batch_size=8, shuffle=False, seed=None,
                 output_mode='error', sequence_start_mode='all', N_seq=None,
                 data_format=K.image_data_format()):
        self.X = hkl.load(data_file)  # X will be like (n_images, nb_cols, nb_rows, nb_channels)
        self.sources = hkl.load(source_file) # source for each image so when creating sequences can assure that consecutive frames are from same video
        self.nt = nt
        self.batch_size = batch_size
        self.data_format = data_format
        assert sequence_start_mode in {'all', 'unique'}, 'sequence_start_mode must be in {all, unique}'
        self.sequence_start_mode = sequence_start_mode
        assert output_mode in {'error', 'prediction'}, 'output_mode must be in {error, prediction}'
        self.output_mode = output_mode

        if self.data_format == 'channels_first':
            self.X = np.transpose(self.X, (0, 3, 1, 2))
        self.im_shape = self.X[0].shape

        if self.sequence_start_mode == 'all':  # allow for any possible sequence, starting from any frame
            #bing
            #self.possible_starts = np.array([i for i in range(self.X.shape[0] - self.nt) if self.sources[i] == self.sources[i + self.nt - 1]])
            self.possible_starts = np.array([i for i in range(self.X.shape[0] - self.nt)])
        elif self.sequence_start_mode == 'unique':  #create sequences where each unique frame is in at most one sequence
            curr_location = 0
            possible_starts = []
            while curr_location < self.X.shape[0] - self.nt + 1:
                if self.sources[curr_location] == self.sources[curr_location + self.nt - 1]:
                    possible_starts.append(curr_location)
                    curr_location += self.nt
                else:
                    curr_location += 1
            self.possible_starts = possible_starts

        if shuffle:
            self.possible_starts = np.random.permutation(self.possible_starts)
        if N_seq is not None and len(self.possible_starts) > N_seq:  # select a subset of sequences if want to
            self.possible_starts = self.possible_starts[:N_seq]
        self.N_sequences = len(self.possible_starts)
        print("N_sequences",self.N_sequences)
        super(SequenceGenerator, self).__init__(len(self.possible_starts), batch_size, shuffle, seed)

    def __getitem__(self, null):
        return self.next()

    def next(self):
        with self.lock:
            current_index = (self.batch_index * self.batch_size) % self.n
            index_array, current_batch_size = next(self.index_generator), self.batch_size
        batch_x = np.zeros((current_batch_size, self.nt) + self.im_shape, np.float32)
        for i, idx in enumerate(index_array):
            idx = self.possible_starts[idx]
            batch_x[i] = self.preprocess(self.X[idx:idx+self.nt])
        if self.output_mode == 'error':  # model outputs errors, so y should be zeros
            batch_y = np.zeros(current_batch_size, np.float32)
        elif self.output_mode == 'prediction':  # output actual pixels
            batch_y = batch_x
        return batch_x, batch_y

    def preprocess(self, X):
        ### Normalization after extrema cut off: ###
        #cut maxs & mins to mean+3*std & mean-3*std of training set for each parameter
        #x_cut = np.zeros(shape=X.shape)
        #x_cut = X*1 #pass X by value and not by reference
        #x_cut[:,:,:,0][X[:,:,:,0]>311.5]=311.5 #set T2 upper limit
        #x_cut[:,:,:,0][X[:,:,:,0]<258.9]=258.9 #set T2 lower limit
        #x_cut[:,:,:,1][X[:,:,:,1]>104635.2]=104635.2 #set GP upper limit
        #x_cut[:,:,:,1][X[:,:,:,1]<98205.6]=98205.6 #set GP lower limit ###Caution: Drastical cut ###
        #x_cut[:,:,:,2][X[:,:,:,2]>6209.5]=6209.5 #set GPH upper limit ###Caution: Unnecessary as it succeeds max GPH ###
        #x_cut[:,:,:,2][X[:,:,:,2]<5005.8]=5005.8 #set GPH lower limit
        #normalize X based on max and min values(equals upper and lower limits except highCutGPH)
        #x_processed = np.zeros(shape=X.shape)
        #x_processed[:,:,:,0] = (x_cut[:,:,:,0]-258.9)/(311.5-258.9)
        #x_processed[:,:,:,1] = (x_cut[:,:,:,1]-98205.6)/(104635.2-98205.6)
        #x_processed[:,:,:,2] = (x_cut[:,:,:,2]-5005.8)/(6007.097417091836-5005.8) #GPH max stays; see above
        
        ### 'Standard' normalization: (x-min(x))/(max(x)-min(x)) ###
        #x_processed = np.zeros(shape=X.shape)
        #x_processed[:,:,:,0] = (X[:,:,:,0]-235.2141571044922)/(321.46630859375-235.2141571044922)
        #x_processed[:,:,:,1] = (X[:,:,:,1]-93401.125)/(105391.4375-93401.125)
        #x_processed[:,:,:,2] = (X[:,:,:,2]-4836.070232780612)/(6007.097417091836-4836.070232780612)

        ### t2only 'Standard' normalization: (x-min(x))/(max(x)-min(x)) ###
        #x_processed = np.zeros(shape=X.shape)
        #x_processed[:,:,:,0] = (X[:,:,:,0]-235.2141571044922)/(321.46630859375-235.2141571044922)
        #x_processed[:,:,:,1] = (X[:,:,:,1]-235.2141571044922)/(321.46630859375-235.2141571044922)
        #x_processed[:,:,:,2] = (X[:,:,:,2]-235.2141571044922)/(321.46630859375-235.2141571044922)

        ### t2_2MSL_1 'standard' normalization:
        #x_processed = np.zeros(shape=X.shape)
        #x_processed[:,:,:,0] = (X[:,:,:,0]-235.2141571044922)/(321.46630859375-235.2141571044922)
        #x_processed[:,:,:,1] = (X[:,:,:,1]-235.2141571044922)/(321.46630859375-235.2141571044922)
        #x_processed[:,:,:,2] = (X[:,:,:,2]-93401.125)/(105391.4375-93401.125)

        ### t2_1MSL_2 'standard' normalization:
        #x_processed = np.zeros(shape=X.shape)
        #x_processed[:,:,:,0] = (X[:,:,:,0]-235.2141571044922)/(321.46630859375-235.2141571044922)
        #x_processed[:,:,:,1] = (X[:,:,:,1]-93401.125)/(105391.4375-93401.125)
        #x_processed[:,:,:,2] = (X[:,:,:,2]-93401.125)/(105391.4375-93401.125)

        ### t2_2gph500_1 'standard' normalization:
        #x_processed = np.zeros(shape=X.shape)
        #x_processed[:,:,:,0] = (X[:,:,:,0]-235.2141571044922)/(321.46630859375-235.2141571044922)
        #x_processed[:,:,:,1] = (X[:,:,:,1]-235.2141571044922)/(321.46630859375-235.2141571044922)
        #x_processed[:,:,:,2] = (X[:,:,:,2]-4836.070232780612)/(6007.097417091836-4836.070232780612)
        ## t2_1gph500_2 'standard' normalization:   
        #x_processed = np.zeros(shape=X.shape)
        #x_processed[:,:,:,0] = (X[:,:,:,0]-235.2141571044922)/(321.46630859375-235.2141571044922)
        #x_processed[:,:,:,1] = (X[:,:,:,1]-4836.070232780612)/(6007.097417091836-4836.070232780612)
        #x_processed[:,:,:,2] = (X[:,:,:,2]-4836.070232780612)/(6007.097417091836-4836.070232780612)

        ### No standardization for moving Objects test set: Just 0s and 1s
        #x_processed = np.zeros(shape=X.shape)
        #x_processed = X

        ### t2_1 'standard' normalization (got one dimension less, due to just one channel)
        #x_processed = np.zeros(shape=X.shape)
        #x_processed[:,:,:,0] = (X[:,:,:,0]-235.2141571044922)/(321.46630859375-235.2141571044922)
        #x_processed[:,:,:,1] = X[:,:,:,1]
        #x_processed[:,:,:,2] = X[:,:,:,2]

        ### t2_1 'standard' normalization (got one dimension less, due to just one channel)
        x_processed = np.zeros(shape=X.shape)
        x_processed[:,:,:,0] = (X[:,:,:,0]-235.2141571044922)/(321.46630859375-235.2141571044922)
        x_processed[:,:,:,1] = (X[:,:,:,1]-235.2141571044922)/(321.46630859375-235.2141571044922)
        x_processed[:,:,:,2] = X[:,:,:,2]

        ### Standardization: (x-mean)/standard_deviation ###
        #Doesn't work due to some activation functions
        #x_processed = np.zeros(shape=X.shape)
        #x_processed[:,:,:,0] = (X[:,:,:,0]-285.1751264870658)/8.770013367617763
        #x_processed[:,:,:,1] = (X[:,:,:,1]-101420.4382666807)/1071.5999818175521
        #x_processed[:,:,:,2] = (X[:,:,:,2]-5607.662795353248)/200.62593105865764

        ### Standardization+Normalization ###
        # standardize:(x-mean)/standard_deviation
        #x_preprocessed = np.zeros(shape=X.shape)
        #x_preprocessed[:,:,:,0] = (X[:,:,:,0]-285.1751264870658)/8.770013367617763
        #x_preprocessed[:,:,:,1] = (X[:,:,:,1]-101420.4382666807)/1071.5999818175521
        #x_preprocessed[:,:,:,2] = (X[:,:,:,2]-5607.662795353248)/200.62593105865764
        # normalize:(x-min(x))/(max(x)-min(x))
        #x_processed = np.zeros(shape=X.shape)
        #x_processed[:,:,:,0] = (x_preprocessed[:,:,:,0]-np.amin(x_preprocessed[:,:,:,0]))/(np.amax(x_preprocessed[:,:,:,0])-np.amin(x_preprocessed[:,:,:,0]))
        #x_processed[:,:,:,1] = (x_preprocessed[:,:,:,1]-np.amin(x_preprocessed[:,:,:,1]))/(np.amax(x_preprocessed[:,:,:,1])-np.amin(x_preprocessed[:,:,:,1]))
        #x_processed[:,:,:,2] = (x_preprocessed[:,:,:,2]-np.amin(x_preprocessed[:,:,:,2]))/(np.amax(x_preprocessed[:,:,:,2])-np.amin(x_preprocessed[:,:,:,2]))

        return x_processed.astype(np.float32)
        #return X.astype(np.float32) / 255

    def create_all(self):
        X_all = np.zeros((self.N_sequences, self.nt) + self.im_shape, np.float32)
        for i, idx in enumerate(self.possible_starts):
            X_all[i] = self.preprocess(self.X[idx:idx+self.nt])
        return X_all
