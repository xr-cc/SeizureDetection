"""
Leave one non-seizure record out and calculate false alarm rates (measure specificity).
(used for features generated from get_patient_feature_simultaneously)
Parameters to set: case, pre_seizure, multi
"""
import scipy.io
import numpy as np
from sklearn import svm
from sklearn.metrics import accuracy_score
import random
from itertools import groupby

case = '01'
pre_seizure = 10  # number of data points taken before seizure onset
multi = 1  # times of non-seizure data comparing to seizure data

# load files
features_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'features0.mat')
labels_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'labels0.mat')
nsidx_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'nsidx0.mat')
sidx_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'sidx0.mat')
labels = labels_mat['labels']
features = features_mat['features']
nsidx = nsidx_mat['ns_seg_indices']
sidx = sidx_mat['s_seg_indices']
# nonseizure record indices
ns_start = [i-1 for i in nsidx[0]]
ns_end = [i-1 for i in nsidx[1]]
# seizure record indices
s_start = [i-1 for i in sidx[0]]
s_end = [i-1 for i in sidx[1]]

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

# seizure
seizure_segments_features =  [feature_inputs[(s_start[i]):(s_end[i])+1,:] for i,val in enumerate(s_start)]
seizure_segments_features = np.array(seizure_segments_features)
seizure_segments_features = seizure_segments_features.reshape(-1, seizure_segments_features.shape[-1])
seizure_segments_labels =  [label_inputs[(s_start[i]):(s_end[i])+1] for i,val in enumerate(s_start)]
seizure_segments_labels = np.array(seizure_segments_labels)
seizure_segments_labels = seizure_segments_labels.reshape(np.prod(seizure_segments_labels.shape))
num_seizure_record_data = len(seizure_segments_labels)

# non-seizure
nonseizure_segments_features =  [feature_inputs[(ns_start[i]):(ns_end[i])+1,:] for i,val in enumerate(ns_start)]
nonseizure_segments_features = np.array(nonseizure_segments_features)
nonseizure_segments_features = nonseizure_segments_features.reshape(-1, nonseizure_segments_features.shape[-1])
nonseizure_segments_labels =  [label_inputs[(ns_start[i]):(ns_end[i])+1] for i,val in enumerate(ns_start)]
nonseizure_segments_labels = np.array(nonseizure_segments_labels)
nonseizure_segments_labels = nonseizure_segments_labels.reshape(np.prod(nonseizure_segments_labels.shape))
nonseizure_record_start_indices = []
nonseizure_record_end_indices = []
runner = 0
for i,val in enumerate(ns_start):
    nonseizure_record_start_indices.append(runner)
    runner += (ns_end[i]-ns_start[i])
    nonseizure_record_end_indices.append(runner)
    runner += 1

avg_accr = 0
fa_rate = 0
ns_count = 0
# leave one non--seizure record out
for i, start_idx in enumerate(nonseizure_record_start_indices):
    end_idx = nonseizure_record_end_indices[i]
    split_labels = np.split(nonseizure_segments_labels, [start_idx, end_idx + 1])
    split_features = np.split(nonseizure_segments_features,[start_idx, end_idx + 1])
    test_feature = split_features[1]
    test_label = split_labels[1]
    training_features = np.concatenate((split_features[0], split_features[2]), axis=0)
    training_labels = np.concatenate((split_labels[0], split_labels[2]), axis=0)

    # balancing data
    used_seizure_num = num_seizure_record_data
    nonseizures_idx = range(len(training_labels))
    nonseizure_idx_picked = np.random.choice(nonseizures_idx, int(used_seizure_num * multi
                                                                  ), replace=False)
    training_labels_picked = np.concatenate((seizure_segments_labels, training_labels[nonseizure_idx_picked]),
                                            axis=0)
    training_features_picked = np.concatenate(
        (seizure_segments_features, training_features[nonseizure_idx_picked, :]), axis=0)
    num_picked = len(training_labels_picked)

    # randomize
    random_indices = random.sample(range(num_picked), num_picked)
    training_features_picked = training_features_picked[random_indices]
    training_labels_picked = training_labels_picked[random_indices]
    # train & test
    X_train, X_test = training_features_picked, test_feature
    y_train, y_test = training_labels_picked, test_label
    # training
    clf = svm.SVC(kernel='rbf', gamma=0.1, C=1.0, class_weight={0: 0.5, 1: 1})
    clf.fit(X_train, y_train)
    # testing
    y_pred = clf.predict(X_test)
    accr = accuracy_score(y_test, y_pred)
    print "Non-Seizure Record No.", i
    print y_pred
    fa = [x for x, y in groupby(y_pred) if (sum(1 for i in y) > 6 and x==1)]
    num_fa = sum(fa)
    ns_count += len(test_label)
    if num_fa > 0:
        fa_rate += 1  # count of false alarms

# print results
print "number of false alarms: ", fa_rate
fa_rate = float(fa_rate)/ns_count*60
print "total time of non-seizure data: ", ns_count
print "false alarm rate (per minute): ",fa_rate
print "false alarm rate (per hour): ",fa_rate*60
