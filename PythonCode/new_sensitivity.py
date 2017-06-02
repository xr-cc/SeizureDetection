"""
Leave one seizure record out and measure sensitivity and latency based on 6s-alarm-pattern.
(meaning that 6 consecutive ones in output denote a triggered seizure alarm.)
(used for features generated from get_patient_feature_simultaneously)
Parameters to set: case, pre_seizure, multi
"""
import scipy.io
import numpy as np
from sklearn import svm
import random

case = '01'
pre_seizure = 10  # number of data points taken before seizure onset
multi = 1  # times of non-seizure data comparing to seizure data
pattern = np.array([1, 1, 1, 1, 1, 1]) # detect 6 consecutive ones => a triggered seizure alarm

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
# seizure onset and end indices
diffs = np.diff(seizure_segments_labels)
onset_indices = [i+1 for i, dif in enumerate(diffs) if dif == 1]
end_indices = [i for i, dif in enumerate(diffs) if dif == 255]
if len(end_indices)<len(onset_indices):
    end_indices.append(len(diffs))
seizure_record_indices = [i+1 for i, dif in enumerate(diffs) if dif == 255]
seizure_record_indices = [0]+seizure_record_indices

# non-seizure
nonseizure_segments_features =  [feature_inputs[(ns_start[i]):(ns_end[i])+1,:] for i,val in enumerate(ns_start)]
nonseizure_segments_features = np.array(nonseizure_segments_features)
nonseizure_segments_features = nonseizure_segments_features.reshape(-1, nonseizure_segments_features.shape[-1])
nonseizure_segments_labels =  [label_inputs[(ns_start[i]):(ns_end[i])+1] for i,val in enumerate(ns_start)]
nonseizure_segments_labels = np.array(nonseizure_segments_labels)
nonseizure_segments_labels = nonseizure_segments_labels.reshape(np.prod(nonseizure_segments_labels.shape))

avg_accr = 0
avg_la = 0
valid_count = 0
# leave one seizure record out
for i, record_start_idx in enumerate(seizure_record_indices):
    end_idx = end_indices[i]
    split_labels = np.split(seizure_segments_labels, [record_start_idx, end_idx + 1])
    split_features = np.split(seizure_segments_features,[record_start_idx, end_idx + 1])
    test_feature = split_features[1]
    test_label = split_labels[1]
    training_features = np.concatenate((split_features[0], split_features[2]), axis=0)
    training_labels = np.concatenate((split_labels[0], split_labels[2]), axis=0)
    num_seizure_record_data = len(training_labels)

    # balancing data
    used_seizure_num = num_seizure_record_data
    nonseizures_idx = range(len(nonseizure_segments_labels))
    # random pick some non-seizure data
    nonseizure_idx_picked = np.random.choice(nonseizures_idx, int(used_seizure_num * multi
                                                                  ), replace=False)
    training_labels_picked = np.concatenate((training_labels,nonseizure_segments_labels[nonseizure_idx_picked]),axis=0)
    training_features_picked = np.concatenate((training_features,nonseizure_segments_features[nonseizure_idx_picked,:]),axis=0)
    num_picked = len(training_labels_picked)

    # shuffle training data
    random_indices = random.sample(range(num_picked), num_picked)
    training_features_picked = training_features_picked[random_indices]
    training_labels_picked = training_labels_picked[random_indices]
    # train & test
    X_train, X_test = training_features_picked, test_feature
    y_train, y_test = training_labels_picked, test_label
    # training
    clf = svm.SVC(kernel='rbf', gamma=0.1, C=1.0, class_weight={0: 0.5, 1: 1})  #
    clf.fit(X_train, y_train)
    # testing'
    y_pred = clf.predict(X_test)
    pred_seizures = [i + len(pattern)-1 for i,x in enumerate(y_pred) if np.array_equal(pattern,y_pred[i:i + len(pattern)])]
    true_seizure_onset = np.where(y_test==1)[0][0]
    pred_seizures_valid = [ pred_s for pred_s in pred_seizures if pred_s>=true_seizure_onset]

    if len(pred_seizures_valid)==0:
        accr = 0
    else:
        pred_seizure_onset = pred_seizures_valid[0]
        latency = pred_seizure_onset - true_seizure_onset
        accr = 1
        avg_la += latency  # latency
        valid_count += 1
        print "Latency: ", latency
    avg_accr += accr  # sensitivity
    print "Accuracy: ", accr
    print "test:      ", y_test
    print "prediction: ", y_pred

avg_accr /= float(len(s_start))
print "Average Accuracy (Sensitivity): " ,avg_accr
if valid_count == 0:
    avg_la = 0
else:
    avg_la = avg_la / valid_count
print "Average Latency: ",avg_la

