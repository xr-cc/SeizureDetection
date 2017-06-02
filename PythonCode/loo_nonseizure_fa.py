"""
Leave one non-seizure record out and calculate false alarm rates (measure specificity).
Parameters to set: case, multi
"""
import scipy.io
import numpy as np
from sklearn import svm
from sklearn.metrics import accuracy_score
import random
from itertools import groupby

case = '01'
multi = 1  # times of non-seizure data comparing to seizure data

# load files
features_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'features2.mat')
labels_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'labels2.mat')
nsidx_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'nsidx.mat')
labels = labels_mat['labels']
features = features_mat['features']
nsidx = nsidx_mat['ns_seg_indices']
# non-seizure record starting and ending indices
ns_start = [i-1 for i in nsidx[0]]
ns_end = [i-1 for i in nsidx[1]]

# flatten data features
feature_length = len(features)*len(features[0])*len(features[0][0])
T = len(labels[0]) # 8*18*3*T
feature_inputs = []
label_inputs = labels[0]
N = range(T)
for i in N:
    feature = features[:,:,:,i]
    a = np.array(feature)
    feature = a.flatten()
    feature_inputs.append(feature)
print 'number of data: ', len(label_inputs)

label_inputs = np.array(label_inputs)
feature_inputs = np.array(feature_inputs)
# normalization
feature_inputs = feature_inputs / feature_inputs.max(axis=0)
print feature_inputs.shape


fa_rate = 0
ns_count = 0  # count number of non-seizure segments
# leave one non-seizure out
for i, start_idx in enumerate(ns_start):
    end_idx = ns_end[i]
    split_labels = np.split(label_inputs, [start_idx, end_idx + 1])
    split_features = np.split(feature_inputs,[start_idx, end_idx + 1])
    test_feature = split_features[1]
    test_label = split_labels[1]
    training_features = np.concatenate((split_features[0], split_features[2]), axis=0)
    training_labels = np.concatenate((split_labels[0], split_labels[2]), axis=0)

    # balancing data
    N = range(len(training_labels))
    seizures_idx = np.where(training_labels == 1)[0]
    num_seizures = len(seizures_idx)
    used_seizure_num = num_seizures
    nonseizures_idx = [idx for idx in N if (idx not in seizures_idx)]
    # random pick some non-seizure data
    nonseizure_idx_picked = np.random.choice(nonseizures_idx, int(num_seizures * multi
                                                                  ), replace=False)
    idx_picked = list(seizures_idx) + list(nonseizure_idx_picked)
    training_labels_picked = training_labels[idx_picked]
    training_features_picked = training_features[idx_picked]
    num_picked = len(training_labels_picked)
    # randomization
    random_indices = random.sample(range(num_picked), num_picked)
    training_features_picked = training_features_picked[random_indices]
    training_labels_picked = training_labels_picked[random_indices]
    # training & test data
    X_train, X_test = training_features_picked, test_feature
    y_train, y_test = training_labels_picked, test_label
    # training
    clf = svm.SVC(kernel='rbf', gamma=0.1, C=1.0, class_weight={0: 1, 1: 1})  #
    clf.fit(X_train, y_train)
    # testing: measure false alarms
    y_pred = clf.predict(X_test)
    print "Non-Seizure Record No.",i
    print "number of test data: ", len(test_label)
    print y_pred
    fa = [x for x, y in groupby(y_pred) if (sum(1 for i in y) > 6 and x==1)]  # indicator of alarms
    num_fa = sum(fa)  # number of alarms
    ns_count += len(test_label)
    fa_rate += num_fa

# print measurements
print "number of false alarms: ", fa_rate
fa_rate = float(fa_rate)/ns_count*60
print "total time of non-seizure data: ", ns_count
print "false alarm rate (per minute): ",fa_rate
print "false alarm rate (per hour): ",fa_rate*60
