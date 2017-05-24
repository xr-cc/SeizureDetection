import scipy.io
import numpy as np
from sklearn import svm
from sklearn.metrics import accuracy_score
from sklearn.metrics import confusion_matrix
import random

case = '01'
note = "seizure taken from data"
pre_seizure = 10

# load files
features_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'features2.mat')
labels_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'labels2.mat')
nsidx_mat = scipy.io.loadmat('../Feature/chb'+case+'feature/SNchb'+case+'nsidx.mat')

labels = labels_mat['labels']
features = features_mat['features']
nsidx = nsidx_mat['ns_seg_indices']

# seizure onset indices
diffs = np.diff(labels[0])
onset_indices = [i+1 for i, dif in enumerate(diffs) if dif == 1]
end_indices = [i for i, dif in enumerate(diffs) if dif == 255]
if len(end_indices)<len(onset_indices):
    end_indices.append(len(diffs)-1)
# print onset_indices
# print end_indices
ns_start = [i-1 for i in nsidx[0]]
ns_end = [i-1 for i in nsidx[1]]
# print ns_start
# print ns_end
# print len(labels)

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

meas_note_path = '../Measurements/'
with open(meas_note_path+"note"+case+".txt", "a") as myfile:
    myfile.write("["+case+"] leave one non-seizure out: false alarm\n")

avg_accr = 0
# avg_la = 0
fa_rate = 0
# leave one out
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
    # false positive
    fp = sum(y_pred)-sum(y_test)
    # cm = confusion_matrix(y_test, y_pred)
    # fp = cm[0][1]
    fa_rate += fp
    # true_onset = np.where(y_test==1)[0][0]
    # first_detect = np.where((y_test - 2. * y_pred) == -1)
    # if len(first_detect[0]) == 0:
    #     pred_onset = len(y_pred)
    # else:
    #     pred_onset = first_detect[0][0]
    # latency = pred_onset-true_onset
    avg_accr += accr
    # avg_la += latency
    print start_idx, "-", end_idx
    print "test:       ", y_test
    print "prediction: ", y_pred
    print "false alarm: ",fp
    # print "Latency: ", latency
    with open(meas_note_path + "note" + case + ".txt", "a") as myfile:
        myfile.write("Non-Seizure No."+str(i) + " ("+str(start_idx)+"-"+str(end_idx)+")\n")
        myfile.write("  true labels: " + str(y_test) + "\n")
        myfile.write("  pred labels: " + str(y_pred) + "\n")
        # myfile.write("  latency: " + str(latency) + "\n")


avg_accr = avg_accr /len(ns_start)
print "Accuracy: " ,avg_accr
fa_rate = fa_rate/len(ns_start)
print "False Alarm Rate: ", fa_rate
# avg_la = avg_la/len(onset_indices)
# print "Average Latency: ",avg_la


meas_note_path = '../Measurements/'
with open(meas_note_path+"note"+case+".txt", "a") as myfile:
    myfile.write("number of data used: "+str(num_picked)+"\n")
    myfile.write("number of seizures: "+str(len(onset_indices))+"\n")
    myfile.write('average accuracy: '+ str(avg_accr)+"\n")
    myfile.write('false alarm rate: '+str(fa_rate)+"\n\n")
    # myfile.write('average latency: ' + str(avg_la)+"\n\n")
