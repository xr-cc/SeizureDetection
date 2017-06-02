"""
Leave one seizure data point out and measure performances.
Parameters to set: case, pre_seizure, multi
"""
import scipy.io
import numpy as np
from sklearn import svm
from sklearn.metrics import accuracy_score
import random

case = '01'
pre_seizure = 10  # number of data points taken before seizure onset
multi = 1  # times of non-seizure data comparing to seizure data

# load files
features_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'features2.mat')
labels_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'labels2.mat')
labels = labels_mat['labels']
features = features_mat['features']

# locate seizure onset and end indices
diffs = np.diff(labels[0])
onset_indices = [i+1 for i, dif in enumerate(diffs) if dif == 1]
end_indices = [i for i, dif in enumerate(diffs) if dif == 255]
if len(end_indices)<len(onset_indices):
    end_indices.append(len(diffs)-1)

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

avg_accr = 0
avg_la = 0
# leave one out
for i, onset_idx in enumerate(onset_indices):
    end_idx = end_indices[i]
    split_labels = np.split(label_inputs, [onset_idx-pre_seizure, end_idx + 1])
    split_features = np.split(feature_inputs,[onset_idx-pre_seizure, end_idx + 1])
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
    true_onset = np.where(y_test==1)[0][0]
    first_detect = np.where((y_test - 2. * y_pred) == -1)
    if len(first_detect[0]) == 0:
        pred_onset = len(y_pred)
    else:
        pred_onset = first_detect[0][0]
    latency = pred_onset-true_onset
    avg_accr += accr  # data point accuracy
    avg_la += latency  # data point latency
    print "test:       ", y_test
    print "prediction: ", y_pred
    print "Latency: ", latency

avg_accr /= len(onset_indices)
print "Data Point Accuracy: ", avg_accr
avg_la /= len(onset_indices)
print "Data Point Average Latency: ", avg_la
