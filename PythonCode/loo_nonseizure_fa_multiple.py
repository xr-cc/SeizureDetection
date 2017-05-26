import scipy.io
import numpy as np
from sklearn import svm
from sklearn.metrics import accuracy_score
import random
from itertools import groupby
import os

case = '10'
note = "seizure taken from data"
pre_seizure = 10
iter = 100

# load files
features_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'features2.mat')
labels_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'labels2.mat')
nsidx_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'nsidx.mat')

labels = labels_mat['labels']
features = features_mat['features']
nsidx = nsidx_mat['ns_seg_indices']

# nonseizure record indices
ns_start = [i-1 for i in nsidx[0]]
ns_end = [i-1 for i in nsidx[1]]

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
# normalize
feature_inputs = feature_inputs / feature_inputs.max(axis=0)
print feature_inputs.shape

fas = []
fa_mins = []

# meas_note_path = '../Measurements/'
# with open(meas_note_path+"note"+case+".txt", "a") as myfile:
#     myfile.write("["+case+"] leave one seizure out\n")
#     myfile.write("iterations: "+str(iter)+"\n")


for j in range(iter):
    ns_count = 0
    fa_count = 0

    # leave one out
    for i, start_idx in enumerate(ns_start):
        end_idx = ns_end[i]
        split_labels = np.split(label_inputs, [start_idx, end_idx + 1])
        split_features = np.split(feature_inputs, [start_idx, end_idx + 1])
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
        nonseizure_idx_picked = np.random.choice(nonseizures_idx, int(num_seizures * 1
                                                                      ), replace=False)
        idx_picked = list(seizures_idx) + list(nonseizure_idx_picked)
        training_labels_picked = training_labels[idx_picked]
        training_features_picked = training_features[idx_picked]
        num_picked = len(training_labels_picked)
        # randomize
        random_indices = random.sample(range(num_picked), num_picked)
        training_features_picked = training_features_picked[random_indices]
        training_labels_picked = training_labels_picked[random_indices]
        # traing & test
        X_train, X_test = training_features_picked, test_feature
        y_train, y_test = training_labels_picked, test_label
        # training
        clf = svm.SVC(kernel='rbf', gamma=0.1, C=1.0, class_weight={0: 1, 1: 1})  #
        clf.fit(X_train, y_train)
        # testing'
        y_pred = clf.predict(X_test)
        accr = accuracy_score(y_test, y_pred)
        # print "Non-Seizure Record No.", i
        # print "number of test data: ", len(test_label)
        # print y_pred
        fa = [x for x, y in groupby(y_pred) if (sum(1 for i in y) > 6 and x == 1)]
        num_fa = sum(fa)
        ns_count += len(test_label)
        fa_count += num_fa
    # print ns_count
    fas.append(fa_count)
    fa_rate_min = float(fa_count) / ns_count * 60
    fa_mins.append(fa_rate_min)


print "loo_nonseizure_fa(6s)"
print iter,"iterations"
print "total time of non-seizure data: ", ns_count
print "average number of false alarms: ",np.mean(fas)
print "false alarm rate (per minute): ",np.mean(fa_mins)
print "false alarm rate (per hour): ",np.mean(fa_mins)*60
