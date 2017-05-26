import scipy.io
import numpy as np
from sklearn import svm
from sklearn.metrics import accuracy_score
from sklearn.metrics import confusion_matrix
from sklearn.metrics import f1_score
import math
import os

case = '09'
ratio = 0.8
note = 'train-test split'

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

# normalize
feature_inputs = feature_inputs / feature_inputs.max(axis=0)
print feature_inputs.shape

iter = 1000
accrs = []
fss = []
seizure_accrs = []
nonseizure_accrs = []
used_seizure_num = 0
used_num = 0

meas_note_path = '../Measurements/'
with open(meas_note_path+"note"+case+".txt", "a") as myfile:
    myfile.write(case+"\n")
    myfile.write('svm_split\n')
    myfile.write("split ratio: "+str(ratio)+"\n")
    myfile.write("iteration: "+str(iter)+"\n")

for j in range(iter):
    # balancing data
    seizures_idx = np.where(label_inputs == 1)[0]
    num_seizures = len(seizures_idx)
    used_seizure_num = num_seizures
    nonseizures_idx = [idx for idx in N if (idx not in seizures_idx)]
    # random pick some non-seizure data
    nonseizure_idx_picked = np.random.choice(nonseizures_idx, int(num_seizures*1),replace=False)

    idx_picked = list(seizures_idx)+list(nonseizure_idx_picked)
    # label_inputs_picked = label_inputs[idx_picked]
    # feature_inputs_picked = feature_inputs[idx_picked]

    # train-test-split
    data_picked_num = len(idx_picked)
    used_num = data_picked_num
    training_size = int(math.floor(ratio*data_picked_num))
    test_size = data_picked_num-training_size
    training_idx = np.random.choice(idx_picked, training_size,replace=False)
    test_idx = [idx for idx in idx_picked if (idx not in training_idx)]
    # print 'number of training data: ', len(training_idx)
    # print 'number of test data: ', len(test_idx)

    training_features = feature_inputs[training_idx] #T*432
    training_labels = label_inputs[training_idx]
    # normalize
    training_features = training_features / training_features.max(axis=0)
    test_features = feature_inputs[test_idx]
    test_labels = label_inputs[test_idx]


    # training
    clf = svm.SVC(kernel='rbf',gamma=0.1, class_weight={0:1,1:1}) #gamma=0.1,
    # clf = svm.SVC()
    clf.fit(training_features, training_labels)


    # testing'
    predicted_labels = clf.predict(test_features)
    # print test_labels
    # print predicted_labels
    # print 'number of seizures in test data: ', sum(test_labels)
    # print 'number of seizures in predicted data: ', sum(predicted_labels)
    accr = accuracy_score(test_labels,predicted_labels)
    conf = confusion_matrix(test_labels, predicted_labels)
    fscore = f1_score(test_labels, predicted_labels)
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
print "Accuracy: ", avg_accrs
print "F-score: ", avg_fss
print "% of Seizure predicted correctly: ", avg_seizure_accrs
print "% of Non-Seizure predicted correctly: ", avg_nonseizure_accrs


# # save to measurements directory
# meas_path = '../Measurements/chb'+case+'meas'
# if not os.path.exists(meas_path):
#     os.makedirs(meas_path)
# scipy.io.savemat(meas_path+'/SNchb'+case+'svm_split_'+str(ratio)+'_meas.mat',
#                  {'accuracy': accr, 'confusion': conf, 'fscore': fscore})


# average iterations
meas_path = '../Measurements/chb'+case+'meas'
if not os.path.exists(meas_path):
    os.makedirs(meas_path)
scipy.io.savemat(meas_path+'/SNchb'+case+'(1000iter)svm_split_'+str(ratio)+'_meas.mat',
                 {'avg1000accuracy': avg_accrs, 'avg1000fscore': avg_fss,
                  'avg1000seizure_accrs': avg_seizure_accrs, 'avg1000nonseizure_accrs': avg_nonseizure_accrs})

meas_note_path = '../Measurements/'
with open(meas_note_path+"note"+case+".txt", "a") as myfile:
    myfile.write(note+"\n")
    myfile.write("number of data used: "+str(used_num)+"\n")
    myfile.write("number of seizures: "+str(used_seizure_num)+"\n")
    myfile.write('accuracy: '+ str(avg_accrs)+"\n")
    myfile.write('fscore: '+str(avg_fss)+"\n")
    myfile.write('seizure accuracy: ' + str(avg_seizure_accrs)+"\n")
    myfile.write('nonseizure accuracy: ' + str(avg_nonseizure_accrs)+"\n\n")