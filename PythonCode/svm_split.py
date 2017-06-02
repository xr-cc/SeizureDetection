"""
Split data into training and testing set.
Use SVM model.
Measure basic performances.
Iterate for (iter) times and average the results.
Parameters to set: case, ratio, iter, multi
"""
import scipy.io
import numpy as np
from sklearn import svm
from sklearn.metrics import accuracy_score
from sklearn.metrics import confusion_matrix
from sklearn.metrics import f1_score
import math

case = '01'
ratio = 0.8  # ratio of training set for train-test-split
iter = 1000
multi = 1  # times of non-seizure data comparing to seizure data

# load files
features_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'features.mat')
labels_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'labels.mat')
labels = labels_mat['labels']
features = features_mat['features']

# flatten data features
T = len(features[0][0][0]) # 8*18*3*N
feature_inputs = []
label_inputs = []
N = range(T)
for i in N:
    feature = features[:,:,:,i]
    a = np.array(feature)
    feature = a.flatten()
    feature_inputs.append(feature)
    label_inputs.append(labels[0][i])
print 'number of data: ', len(label_inputs)
label_inputs = np.array(label_inputs)
feature_inputs = np.array(feature_inputs)

# normalization
feature_inputs = feature_inputs / feature_inputs.max(axis=0)
print feature_inputs.shape

accrs = []
fss = []
seizure_accrs = []
nonseizure_accrs = []
used_seizure_num = 0
used_num = 0

for j in range(iter):
    # balancing data
    seizures_idx = np.where(label_inputs == 1)[0]
    num_seizures = len(seizures_idx)
    nonseizures_idx = [idx for idx in N if (idx not in seizures_idx)]
    # random pick some non-seizure data
    nonseizure_idx_picked = np.random.choice(nonseizures_idx, int(num_seizures*multi),replace=False)
    idx_picked = list(seizures_idx)+list(nonseizure_idx_picked)

    # train-test-split
    data_picked_num = len(idx_picked)
    training_size = int(math.floor(ratio*data_picked_num))
    test_size = data_picked_num-training_size
    training_idx = np.random.choice(idx_picked, training_size,replace=False)
    test_idx = [idx for idx in idx_picked if (idx not in training_idx)]

    training_features = feature_inputs[training_idx] #T*432
    training_labels = label_inputs[training_idx]
    # normalization
    training_features = training_features / training_features.max(axis=0)
    test_features = feature_inputs[test_idx]
    test_labels = label_inputs[test_idx]

    # training
    clf = svm.SVC(kernel='rbf',gamma=0.1, class_weight={0:1,1:1}) #gamma=0.1,
    clf.fit(training_features, training_labels)

    # testing'
    predicted_labels = clf.predict(test_features)
    accr = accuracy_score(test_labels,predicted_labels)  # accuracy score
    conf = confusion_matrix(test_labels, predicted_labels)  # confusion matrix
    fscore = f1_score(test_labels, predicted_labels)  # f-score
    # print "Accuracy: ", accr
    # print "Confusion Matrix: "
    # print conf
    # print "F-score: ", fscore
    accrs.append(accr)
    fss.append(fscore)
    seizure_accrs.append(float(conf[1,1])/(conf[1,1]+conf[1,0]))
    nonseizure_accrs.append(float(conf[0,0])/(conf[0,1]+conf[0,0]))

avg_accrs = np.mean(accrs)
avg_fss = np.mean(fss)
avg_seizure_accrs = np.mean(seizure_accrs)
avg_nonseizure_accrs = np.mean(nonseizure_accrs)

# print results
print "Accuracy: ", avg_accrs
print "F-score: ", avg_fss
print "% of Seizure predicted correctly: ", avg_seizure_accrs
print "% of Non-Seizure predicted correctly: ", avg_nonseizure_accrs
