import scipy.io
import numpy as np
from sklearn import svm
import random
from sklearn.metrics import accuracy_score

case = '01'
note = 'gamma=0.1,'
# load files
nonseizure_features_mat = scipy.io.loadmat('../Feature/chb'+case+'segfeature/SNchb'+case+'nonseizure_features.mat')
nonseizure_labels_mat = scipy.io.loadmat('../Feature/chb'+case+'segfeature/SNchb'+case+'nonseizure_labels.mat')
seizure_features_mat = scipy.io.loadmat('../Feature/chb'+case+'segfeature/SNchb'+case+'seizure_features.mat')
seizure_labels_mat = scipy.io.loadmat('../Feature/chb'+case+'segfeature/SNchb'+case+'seizure_labels.mat')
nonseizure_labels = nonseizure_labels_mat['nonseizure_labels'][0]
nonseizure_features = nonseizure_features_mat['nonseizure_features']
seizure_labels = seizure_labels_mat['seizure_labels'][0]
seizure_features = seizure_features_mat['seizure_features']
# get dimensions
num_nonseizures = len(nonseizure_features[0])
t_nonseizures = len(nonseizure_features[0][0][0][0][0])
feature_length = np.prod(nonseizure_features[0][0].shape)/t_nonseizures

ns_features = np.empty((0,feature_length), float)
ns_labels = []
for i in range(num_nonseizures):
    ns_feature_ori = nonseizure_features[0][i]
    ns_label = nonseizure_labels[i]
    # reshape
    ns_feature_array = []
    ns_label_array = ns_label[0]
    for i in range(t_nonseizures):
        feature = ns_feature_ori[:, :, :, i]
        a = np.array(feature)
        feature = a.flatten()
        ns_feature_array.append(feature)
    ns_features = np.append(ns_features, np.array(ns_feature_array), axis=0)
    ns_labels = np.append(ns_labels,ns_label_array,axis=0)

print "number of non-seizures: ", len(nonseizure_features[0])
print "number of non-seizure data points: ", len(ns_labels)

num_seizures = len(seizure_features[0])
t_seizures = len(seizure_features[0][0][0][0][0])
print "number of seizures: ", num_seizures
print "number of data points used in each seizure: ", t_seizures

accrs = []
test_labels_truth = []
test_labels_pred = []

for i in range(num_seizures):
    print i
    s_features = np.empty((0, feature_length), float)
    s_labels = []
    test_feature = []
    test_label = 1
    for j in range(num_seizures):
        s_feature_ori = seizure_features[0][j]
        s_label = seizure_labels[j]
        # reshape
        s_feature_array = []
        s_label_array = s_label[0]
        for k in range(t_seizures):
            feature = s_feature_ori[:, :, :, k]
            a = np.array(feature)
            feature = a.flatten()
            s_feature_array.append(feature)

        if i==j: # test data
            test_feature = s_feature_array
            test_label = s_label_array
        else: # in training set
            s_features = np.append(s_features, np.array(s_feature_array), axis=0)
            s_labels = np.append(s_labels, s_label_array, axis=0)

    features = np.append(ns_features, s_features, axis=0)
    labels = np.append(ns_labels, s_labels, axis=0)
    # normalize
    features = features / features.max(axis=0)
    indices = range(0,len(labels))
    # randomize
    random_indices = random.sample(indices, len(indices))
    features = features[random_indices]
    labels = labels[random_indices]
    # train
    clf = svm.SVC(kernel='rbf', C=1.0, class_weight={0: 0.02245, 1: 1}) #gamma=0.1,
    clf.fit(features, labels)
    pred = clf.predict(test_feature)
    accr = accuracy_score(test_label, pred)
    accrs.append(accr)
    test_labels_truth.append(test_label)
    test_labels_pred.append(pred)

print np.mean(accrs)
print test_labels_truth
print test_labels_pred
