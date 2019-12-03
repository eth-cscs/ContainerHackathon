import hickle as hkl
import numpy as np
import matplotlib.pyplot as plt

#x_train = hkl.load('/Users/Severin/Desktop/X_train.hkl') #load X_train produces on jureca
x_train = hkl.load('/p/project/cjjsc42/severin/try3/X_train.hkl') #load X_train produces on jureca
print('Shape of X:')
print(x_train.shape)
print('')

#Print example
#t2_cutout = x_train[100,:,:,0]
#printt2cutout = plt.pcolormesh(t2_cutout[::-1,:], shading='bottom', cmap=plt.cm.jet)
#plt.savefig('t2_cutout')
#Extract Max min values:
maxT2 = np.amax(x_train[:,:,:,0]) # numpy.amax() returns the maximum of an array or maximum along an axis.
print('maxT2: ' + str(maxT2))
minT2 = np.amin(x_train[:,:,:,0])
print('minT2: ' + str(minT2))
meanT2 = np.mean(x_train[:,:,:,0])
print('meanT2: ' + str(meanT2))
stdT2 = np.std(x_train[:,:,:,0])
print('stdT2: ' + str(stdT2))
highCutT2 = meanT2 + 3 * stdT2
print('highCutT2: ' + str(highCutT2))
lowCutT2 = meanT2 - 3 * stdT2
print('lowCutT2: ' + str(lowCutT2))
print('')

maxGP = np.amax(x_train[:,:,:,1])
print('maxGP: ' + str(maxGP))
minGP = np.amin(x_train[:,:,:,1])
print('minGP: ' + str(minGP))
meanGP = np.mean(x_train[:,:,:,1])
print('meanGP: ' + str(meanGP))
stdGP = np.std(x_train[:,:,:,1])
print('stdGP: ' + str(stdGP))
highCutGP = meanGP + 3 * stdGP
print('highCutGP: ' + str(highCutGP))
lowCutGP = meanGP - 3 * stdGP
print('lowCutGP: ' + str(lowCutGP))
print('')

maxGPH = np.amax(x_train[:,:,:,2])
print('maxGPH: ' + str(maxGPH))
minGPH = np.amin(x_train[:,:,:,2])
print('minGPH: ' + str(minGPH))
meanGPH = np.mean(x_train[:,:,:,2])
print('meanGP: ' + str(meanGPH))
stdGPH = np.std(x_train[:,:,:,2])
print('stdGPH: ' + str(stdGPH))
highCutGPH = meanGPH + 3 * stdGPH
print('highCutGPH: ' + str(highCutGPH))
lowCutGPH = meanGPH - 3 * stdGPH
print('lowCutGPH: ' + str(lowCutGPH))
print('')

# Formel zum normalisieren: z = (x-min(x))/(max(x)-min(x))
#x_trainNormalized2 = np.zeros(shape=x_train.shape)
#print('Empty shape:')
#print(x_trainNormalized2.shape)
#x_trainNormalized2[:,:,:,0] = (x_train[:,:,:,0]-minT2)/(maxT2-minT2)
#x_trainNormalized2[:,:,:,1] = (x_train[:,:,:,1]-minGP)/(maxGP-minGP)
#x_trainNormalized2[:,:,:,2] = (x_train[:,:,:,2]-minGPH)/(maxGPH-minGPH)

#print('MaxMin values of normalized dataset:')
#print('T2:')
#print(np.amax(x_trainNormalized2[:,:,:,0]))
#print(np.amin(x_trainNormalized2[:,:,:,0]))
#print('GP:')
#print(np.amax(x_trainNormalized2[:,:,:,1]))
#print(np.amin(x_trainNormalized2[:,:,:,1]))
#print('GPH:')
#print(np.amax(x_trainNormalized2[:,:,:,2]))
#print(np.amin(x_trainNormalized2[:,:,:,2]))
#print(x_trainNormalized2)