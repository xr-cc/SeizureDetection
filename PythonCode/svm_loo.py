import scipy.io
import numpy as np
from sklearn import svm
import math
from sklearn.metrics import accuracy_score
from sklearn.cross_validation import LeaveOneOut
import os

case = '09'
note = 'fixed: with normalization'

# load files
features_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'features.mat')
labels_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'labels.mat')

labels = labels_mat['labels']
features = features_mat['features']

T = len(features[0][0][0]) # 8*18*3*N
# print len(labels[0])

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


iter = 50
accrs = []
fnegs = []
fposs = []
used_seizure_num = 0
used_num = 0
meas_note_path = '../Measurements/'
with open(meas_note_path+"note"+case+".txt", "a") as myfile:
    myfile.write(case+"\n")
    myfile.write('svm_loo\n')
    myfile.write("iteration: "+str(iter)+"\n")

for j in range(iter):
    # balancing data
    seizures_idx = np.where(label_inputs == 1)[0]
    num_seizures = len(seizures_idx)
    used_seizure_num = num_seizures
    nonseizures_idx = [idx for idx in N if (idx not in seizures_idx)]
    # random pick some non-seizure data
    nonseizure_idx_picked = np.random.choice(nonseizures_idx, int(num_seizures*1
                                                                  ),replace=False)
    idx_picked = list(seizures_idx)+list(nonseizure_idx_picked)
    label_inputs_picked = label_inputs[idx_picked]
    feature_inputs_picked = feature_inputs[idx_picked]
    T_picked = len(label_inputs_picked)
    used_num = T_picked
    # print "number of data used: ",T_picked
    # print "number of seizure data: ", num_seizures
    # print "number of non-seizure data: ", len(nonseizure_idx_picked)

    # T_picked = T
    # label_inputs_picked = label_inputs
    # feature_inputs_picked = feature_inputs
    # num_seizures = sum(label_inputs_picked)
    # print "number of data used: ",T_picked
    # print "number of seizure data: ", num_seizures


    # Leave One Out CV
    loo = LeaveOneOut(T_picked)

    avg_accr = 0
    false_neg = 0
    false_pos = 0
    # normalize
    feature_inputs_picked = feature_inputs_picked / feature_inputs_picked.max(axis=0)
    for train_index, test_index in loo:
        # print("TRAIN:", len(train_index), "TEST:", test_index)
        # split
        X_train, X_test = feature_inputs_picked[train_index], feature_inputs_picked[test_index]
        y_train, y_test = label_inputs_picked[train_index], label_inputs_picked[test_index]
        # training
        clf = svm.SVC(kernel='rbf', C=1.0, gamma=0.1, class_weight={0: 1, 1: 1}) #gamma=0.1,
        clf.fit(X_train, y_train)
        # testing'
        y_pred = clf.predict(X_test)
        accr = accuracy_score(y_test, y_pred)
        # print "test:",str(y_test[0])," pred:", str(y_pred[0])
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

# save to measurements directory
meas_path = '../Measurements/chb'+case+'meas'
if not os.path.exists(meas_path):
    os.makedirs(meas_path)
scipy.io.savemat(meas_path+'/SNchb'+case+'svm_loo_'+'_meas.mat',
                 {'accuracy': avg_accrs, 'seizure_accrs': seizure_accrs, 'nonseizure_accrs': nonseizure_accrs})

meas_note_path = '../Measurements/'
with open(meas_note_path+"note"+case+".txt", "a") as myfile:
    myfile.write(note+"\n")
    myfile.write("number of data used: "+str(used_num)+"\n")
    myfile.write("number of seizures: "+str(used_seizure_num)+"\n")
    myfile.write('accuracy: '+ str(avg_accrs)+"\n")
    myfile.write('seizure accuracy: ' + str(seizure_accrs)+"\n")
    myfile.write('nonseizure accuracy: ' + str(nonseizure_accrs)+"\n\n")
