"""
Leave one data point out and measure basic performances.
Iterate for (iter) times and average the results.
Parameters to set: case, iter, multi
"""
import scipy.io
import numpy as np
from sklearn import svm
from sklearn.metrics import accuracy_score
from sklearn.cross_validation import LeaveOneOut

case = '01'
iter = 50
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

accrs = []
fnegs = []
fposs = []
used_seizure_num = 0
used_num = 0

# balancing data
seizures_idx = np.where(label_inputs == 1)[0]
num_seizures = len(seizures_idx)
nonseizures_idx = [idx for idx in N if (idx not in seizures_idx)]
print "number of seizure data: ", num_seizures
for j in range(iter):
    # randomly pick some non-seizure data
    nonseizure_idx_picked = np.random.choice(nonseizures_idx, int(num_seizures*multi
                                                                  ),replace=False)
    idx_picked = list(seizures_idx)+list(nonseizure_idx_picked)
    label_inputs_picked = label_inputs[idx_picked]
    feature_inputs_picked = feature_inputs[idx_picked]
    T_picked = len(label_inputs_picked)
    # normalization
    feature_inputs_picked = feature_inputs_picked / feature_inputs_picked.max(axis=0)

    avg_accr = 0
    false_neg = 0
    false_pos = 0
    loo = LeaveOneOut(T_picked)  # Leave One Out CV

    for train_index, test_index in loo:
        # split
        X_train, X_test = feature_inputs_picked[train_index], feature_inputs_picked[test_index]
        y_train, y_test = label_inputs_picked[train_index], label_inputs_picked[test_index]
        # training
        clf = svm.SVC(kernel='rbf',gamma=0.1, C=1.0, class_weight={0: 1, 1: 1}) #
        clf.fit(X_train, y_train)
        # testing'
        y_pred = clf.predict(X_test)
        accr = accuracy_score(y_test, y_pred)
        avg_accr += accr
        # seizure
        if y_test==1 and accr==0:
            false_neg += 1
            # "should be SEIZURE but not "
        if y_pred==1 and accr==0:
            false_pos += 1
            # "predict to be SEIZURE but not "

    avg_accr = avg_accr/T_picked
    accrs.append(avg_accr)
    fnegs.append(1-float(false_neg)/num_seizures)
    fposs.append(1-float(false_pos)/num_seizures)
    # print avg_accr
    # print "False Negative: ", false_neg
    # print "False Positive: ", false_pos

avg_accrs = np.mean(accrs)
seizure_accrs = np.mean(fnegs)
nonseizure_accrs = np.mean(fposs)
print "Average Accuracy: ", avg_accrs
print "Seizure correctly predicted: ", seizure_accrs
print "Nonseizure correctly predicted: ", nonseizure_accrs

